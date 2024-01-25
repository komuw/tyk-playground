#!/usr/bin/env bash
set -eo pipefail
shopt -s nullglob
set -x

export TYK_VERSION=v5.2.2
export OUR_GO_PROXY=/tmp/myGoProxy
export OUR_GO_VERSION=1.19.1

PLUGIN_DIR=${1:-NotSet}
if [ "$PLUGIN_DIR" == "NotSet"  ]; then
    printf "\n\n PLUGIN_DIR should not be empty\n"
    exit
fi

printf "\n\n PLUGIN_DIR=${PLUGIN_DIR} \n TYK_VERSION=${TYK_VERSION} \n OUR_GO_PROXY=${OUR_GO_PROXY} \n OUR_GO_VERSION=${OUR_GO_VERSION} \n\n"

# update GOPROXY to have all the required modules for tyk gateway at the given tag.
set_tyk_modules(){
	rm -rf "/tmp/${TYK_VERSION}.zip"
	rm -rf "/tmp/${TYK_VERSION}"
	wget --no-check-certificate -nc --output-document="/tmp/${TYK_VERSION}.zip" "https://github.com/TykTechnologies/tyk/archive/refs/tags/${TYK_VERSION}.zip"
	unzip "/tmp/${TYK_VERSION}.zip" -d "/tmp/"
	rm -rf "/tmp/${TYK_VERSION}.zip"
	mv /tmp/tyk-* "/tmp/${TYK_VERSION}"
	cd "/tmp/${TYK_VERSION}"
	pwd
	unset GOPROXY
	unset GOPATH
	export GOPROXY='https://proxy.golang.org,direct'
	export GOPATH=${OUR_GO_PROXY}
	gotv ${OUR_GO_VERSION} mod download
	gotv ${OUR_GO_VERSION} mod tidy
}
set_tyk_modules


# update GOPROXY to have all the required modules for the plugin.
set_plugin_modules(){
	cd ${PLUGIN_DIR}
    {
	    gotv ${OUR_GO_VERSION} mod init github.com/example/plugin
    } || {
        echo -n '' # already a module
    }
	gotv ${OUR_GO_VERSION} get -d github.com/TykTechnologies/tyk@`git ls-remote https://github.com/TykTechnologies/tyk.git refs/tags/${TYK_VERSION} | awk '{print $1;}'`
	unset GOPROXY
	unset GOPATH
	export GOPROXY='https://proxy.golang.org,direct'
	export GOPATH=${OUR_GO_PROXY}
	gotv ${OUR_GO_VERSION} mod download
	gotv ${OUR_GO_VERSION} mod tidy
	tree ${OUR_GO_PROXY}/pkg/mod/cache/download
	unset GOPROXY
	unset GOPATH
}
set_plugin_modules

build_plugin(){
    cd ${PLUGIN_DIR}
    docker \
      run \
      --env GO_USE_PROXY=1 \
      --volume ${PLUGIN_DIR}:/plugin-source \
      --volume ${OUR_GO_PROXY}:/tmp/myGoProxy \
      komuw/tyk-plugin-compiler:v5.2.2 CustomGoPlugin.so
}
build_plugin
