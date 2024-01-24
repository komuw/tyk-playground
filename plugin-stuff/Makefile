
export TYK_VERSION := v5.2.4

# Builds the Go plugin
build: up-gateway go-build restart-gateway

go-build:
	printf "\n\t machine with internet commands\n\n"
	cd ./go/src ; \
	gotv 1.19 mod init github.com/komuw/exampleplugin ; \
	gotv 1.19 get -d github.com/TykTechnologies/tyk@`git ls-remote https://github.com/TykTechnologies/tyk.git refs/tags/${TYK_VERSION} | awk '{print $$1;}'` ; \
	gotv 1.19 mod tidy ; \
	gotv 1.19 mod vendor
	printf "\n\t machine with NO internet commands\n\n"
	docker-compose run --rm tyk-plugin-compiler CustomGoPlugin.so
	mv -f ./go/src/CustomGoPlugin*.so ./tyk/middleware/

up-gateway:
	docker-compose up --detach tyk-gateway tyk-redis

restart-gateway:
	docker-compose restart tyk-gateway

