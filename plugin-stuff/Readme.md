```sh
docker build \
  --build-arg GO_VERSION=1.19 \
  --build-arg GITHUB_TAG=v5.2.4 \
  -t internal/plugin-compiler \
  -f plugin_compiler_Dockerfile .

docker run \
  -it \
  -e GO_USE_VENDOR=1 \
  -v /home/komuw/Downloads/cool/go/src:/plugin-source \
  internal/plugin-compiler CustomGoPlugin.so

cd /path/to/tyk-repository
git checkout v5.2.4
gotv 1.19 build -trimpath -tags=goplugin . # Note the Go version must match the one use in plugin-compiler
./tyk plugin load -f /home/komuw/Downloads/cool/go/src/CustomGoPlugin*.so -s MyPluginPre
```
