#!/bin/bash
set -eo pipefail
shopt -s nullglob

TMPDIR=/tmp
SCRIPTNAME=$0
GOPROXY="https://proxy.golang.org,direct"

usage(){
    # 1. In the machine that has internet, run;
    #      offline-plugin-build.sh download plugin_name /path/to/plugin/source/code /tmp/myGoProxy v5.2.2
    # 2. In the machine that has NO internet, download the plugin compiler.
    # 3. Copy the directory '/tmp/$OUR_GO_PROXY' to the machine that has no internet.
    # 4. In the machine that has NO internet, run the command output by the 'download' command above
    #
    printf "\n\tUsage:\n\t$SCRIPTNAME [download|build] plugin_name /path/to/plugin/source/code /path/to/download/to v<gateway version>\n"
    exit 1
}

# update GOPROXY to have all the required modules for the plugin.
get_plugin_modules(){
  # create go.mod if it doesn't already exist
  if [[ ! -f "$PLUGIN_DIR/go.mod" ]]; then
    docker container run --rm \
      --volume $PLUGIN_DIR:/plugin-source \
      --tty \
      --workdir /plugin-source \
      --entrypoint go \
      tykio/tyk-plugin-compiler:$TYK_VERSION \
      mod init $PLUGIN_NAME
  fi
  [[ -f $PLUGIN_DIR/go.mod ]] || exit
  # populate $OUR_GO_PROXY with the gateway source
  GIT_HASH=$(git ls-remote https://github.com/TykTechnologies/tyk.git refs/tags/${TYK_VERSION} | awk '{print  $1;}')
  docker container run --rm\
    --env GOPROXY=$GOPROXY \
    --env GOPATH=$OUR_GO_PROXY \
    --volume $PLUGIN_DIR:/plugin-source \
    --tty \
    --volume $OUR_GO_PROXY:$OUR_GO_PROXY \
    --workdir /plugin-source \
    --entrypoint go \
    tykio/tyk-plugin-compiler:$TYK_VERSION \
    get -d github.com/TykTechnologies/tyk@$GIT_HASH
  # download the dependencies for the plugin
  docker container run --rm \
    --env GOPROXY=$GOPROXY \
    --env GOPATH=$OUR_GO_PROXY \
    --volume $PLUGIN_DIR:/plugin-source \
    --volume $OUR_GO_PROXY:$OUR_GO_PROXY \
    --workdir /plugin-source \
    --entrypoint go \
    tykio/tyk-plugin-compiler:$TYK_VERSION \
    mod download
  docker container run --rm \
    --env $GOPROXY \
    --env GOPATH=$OUR_GO_PROXY \
    --volume $PLUGIN_DIR:/plugin-source \
    --volume $OUR_GO_PROXY:$OUR_GO_PROXY \
    --workdir /plugin-source \
    --entrypoint go \
    tykio/tyk-plugin-compiler:$TYK_VERSION \
    mod tidy
}

# update GOPROXY to have all the required modules for tyk gateway at the given tag.
get_tyk_modules(){
  if [[ -d "$TMPDIR/${TYK_VERSION}" ]]; then
    rm -f "$TMPDIR/${TYK_VERSION}.zip"
    rm -rf "$TMPDIR/${TYK_VERSION}"
  fi
  # download the source for $TYK_VERSION
  if wget --no-check-certificate -nc --output-document="$TMPDIR/${TYK_VERSION}.zip" "https://github.com/TykTechnologies/tyk/archive/refs/tags/${TYK_VERSION}.zip"; then
    unzip "$TMPDIR/${TYK_VERSION}.zip" -d "$TMPDIR/"
    rm -f "$TMPDIR/${TYK_VERSION}.zip"
    mv $TMPDIR/tyk-* "$TMPDIR/${TYK_VERSION}"
    # go mod download
    docker container run --rm \
      --env GOPROXY=$GOPROXY \
      --env GOPATH=$OUR_GO_PROXY \
      --volume $TMPDIR/$TYK_VERSION:$TMPDIR/$TYK_VERSION \
      --tty \
      --volume $OUR_GO_PROXY:$OUR_GO_PROXY \
      --workdir $TMPDIR/$TYK_VERSION \
      --entrypoint go \
      tykio/tyk-plugin-compiler:$TYK_VERSION \
      mod download
    # go mod tidy
    docker container run --rm \
      --env GOPROXY=$GOPROXY \
      --env GOPATH=$OUR_GO_PROXY \
      --volume $TMPDIR/$TYK_VERSION:$TMPDIR/$TYK_VERSION \
      --tty \
      --volume $OUR_GO_PROXY:$OUR_GO_PROXY \
      --workdir $TMPDIR/$TYK_VERSION \
      --entrypoint go \
      tykio/tyk-plugin-compiler:$TYK_VERSION \
      mod tidy
    # pull github.com/cespare/xxhash@v1.1.0 because golang won't do it itself
    docker container run --rm \
      --env GOPROXY=$GOPROXY \
      --env GOPATH=$OUR_GO_PROXY \
      --volume $TMPDIR/$TYK_VERSION:$TMPDIR/$TYK_VERSION \
      --tty \
      --volume $OUR_GO_PROXY:$OUR_GO_PROXY \
      --workdir $TMPDIR/$TYK_VERSION \
      --entrypoint go \
      tykio/tyk-plugin-compiler:$TYK_VERSION \
      mod download github.com/cespare/xxhash@v1.1.0
  else
    echo "[FATAL]Unable to download the $TYK_VERSION source"
    exit 1
  fi
}

correct_ownership() {
  # Because we've been using the plugin compiler the files and directories that have been created
  # will be owned by root.
  # Set the ownership to the current EUID
  pwd
  ls -al
  docker container run --rm \
    --volume $PLUGIN_DIR:/plugin-source \
    --volume $OUR_GO_PROXY:$OUR_GO_PROXY \
    --workdir / \
    --entrypoint chown \
    tykio/tyk-plugin-compiler:$TYK_VERSION \
    -R $(id -u):$(id -g) /plugin-source/go.mod /plugin-source/go.sum $OUR_GO_PROXY
  docker container run --rm \
    --volume $PLUGIN_DIR:/plugin-source \
    --volume $OUR_GO_PROXY:$OUR_GO_PROXY \
    --workdir / \
    --entrypoint chmod \
    tykio/tyk-plugin-compiler:$TYK_VERSION \
    -R u+w /plugin-source/go.mod /plugin-source/go.sum $OUR_GO_PROXY
}

# This should be run in the machine with no internet.
build_plugin(){
  docker container \
    run \
    --env GOPROXY="file:///tmp/myGoProxy/pkg/mod/cache/download" \
    --volume ${PLUGIN_DIR}:/plugin-source \
    --volume ${OUR_GO_PROXY}:/tmp/myGoProxy \
    tykio/tyk-plugin-compiler:$TYK_VERSION \
    $PLUGIN_NAME $(date +%s)
}

COMMAND=${1:-NotSet}
if [ "$COMMAND" == "NotSet"  ]; then
    printf "\n\n Parameter 1 [download|build] should not be empty\n"
    usage
fi

PLUGIN_NAME=${2:-NotSet}
if [ "$PLUGIN_NAME" == "NotSet"  ]; then
    printf "\n\n Parameter 2 PLUGIN_NAME should not be empty\n"
    usage
fi

PLUGIN_DIR=${3:-NotSet}
if [ "$PLUGIN_DIR" == "NotSet"  ]; then
    printf "\n\n Parameter 3 PLUGIN_DIR the plugins source code directory should not be empty\n"
    usage
fi

OUR_GO_PROXY=${4:-NotSet}
if [ "$OUR_GO_PROXY" == "NotSet"  ]; then
    printf "\n\n Parameter 4 OUR_GO_PROXY should not be empty\n"
    usage
fi

TYK_VERSION=${5:-NotSet}
if [ "$TYK_VERSION" == "NotSet"  ]; then
    printf "\n\n Parameter 5 TYK_VERSION should not be empty\n"
    usage
fi

printf "\n\n PLUGIN_DIR=${PLUGIN_DIR} \n TYK_VERSION=${TYK_VERSION} \n OUR_GO_PROXY=${OUR_GO_PROXY} \n\n"

if [[ "$COMMAND" == 'download' ]]; then

  # This should be run on the machine with internet
  get_plugin_modules
  get_tyk_modules
  correct_ownership
  echo "Now copy the directory $OUR_GO_PROXY to the build machine and run the following command there"
  echo $SCRIPTNAME build $PLUGIN_NAME $PLUGIN_DIR $OUR_GO_PROXY $TYK_VERSION

elif [[ "$COMMAND" == 'build' ]]; then
  # This should be run in the machine with no internet.
  if [[ -d $OUR_GO_PROXY ]]; then
    build_plugin
  else
    echo "[FATAL]Directory $OUR_GO_PROXY does not exist. Was it copied from the machine with internet connection?"
    exit 1
  fi
else
  usage
fi
