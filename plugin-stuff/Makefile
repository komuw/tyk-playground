
export TYK_VERSION := v5.2.4
export OUR_GO_PROXY := /tmp/myGoProxy

# Note the Go version must match the one use in plugin-compiler
# `gotv` is https://github.com/go101/gotv


# Builds the Go plugin
build: prep-proxy up-gateway tyk_modules plugin_modules build_plugin restart-gateway

prep-proxy:
	sudo rm -rf ${OUR_GO_PROXY}
	mkdir -p ${OUR_GO_PROXY}

up-gateway:
	docker ps -aq | xargs docker rm -f;docker volume ls -q | xargs docker volume rm -f | echo -n ''
	docker-compose up --detach tyk-gateway tyk-redis

# update GOPROXY to have all the required modules for tyk gateway at the given tag.
tyk_modules:
	rm -rf "/tmp/${TYK_VERSION}.zip"
	rm -rf "/tmp/${TYK_VERSION}"
	wget --no-check-certificate -nc --output-document="/tmp/${TYK_VERSION}.zip" "https://github.com/TykTechnologies/tyk/archive/refs/tags/${TYK_VERSION}.zip"
	unzip "/tmp/${TYK_VERSION}.zip" -d "/tmp/"
	rm -rf "/tmp/${TYK_VERSION}.zip"
	mv /tmp/tyk-* "/tmp/${TYK_VERSION}"
	cd "/tmp/${TYK_VERSION}"; \
	pwd; \
	unset GOPROXY ; \
	unset GOPATH ; \
	export GOPROXY='https://proxy.golang.org,direct' ; \
	export GOPATH=${OUR_GO_PROXY} ; \
	gotv 1.19.13 mod download ; \
	gotv 1.19.13 mod tidy

# update GOPROXY to have all the required modules for the plugin.
plugin_modules:
	cd ./go/src ; \
	gotv 1.19.13 mod init github.com/komuw/exampleplugin ; \
	gotv 1.19.13 get -d github.com/TykTechnologies/tyk@`git ls-remote https://github.com/TykTechnologies/tyk.git refs/tags/${TYK_VERSION} | awk '{print $$1;}'` ; \
	unset GOPROXY ; \
	unset GOPATH ; \
	export GOPROXY='https://proxy.golang.org,direct' ; \
	export GOPATH=${OUR_GO_PROXY} ; \
	gotv 1.19.13 mod download ; \
	gotv 1.19.13 mod tidy ; \
	tree ${OUR_GO_PROXY}/pkg/mod/cache/download ; \
	unset GOPROXY ; \
	unset GOPATH

build_plugin:
	docker-compose \
	build \
	tyk-plugin-compiler
	#
	docker-compose run --rm tyk-plugin-compiler CustomGoPlugin.so
	cp ./go/src/CustomGoPlugin*.so ./tyk/middleware/

restart-gateway:
	sleep 3;docker-compose restart tyk-gateway;sleep 3

