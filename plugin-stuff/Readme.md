### What?
If you would like to build a Tyk plugin in a machine that does not have internet access.      
This repo uses Go v1.19 and Tyk version v5.2.2, but the idea is applicable across versions.       

We create a new plugin-compiler docker image in `plugin-stuff/plugin_compiler_Dockerfile`. This is based on https://github.com/TykTechnologies/tyk/tree/master/ci/images/plugin-compiler but updated to allow a custom `GOPROXY`. The idea in here could be transferred over to the main Tyk plugin compiler.         

This features a custom plugin compiler is updated so that building plugins does not require internet access.            

#### Usage from this repo:
Run;
```sh
make build
bash start.sh
```
Then run;
```sh
curl -vkL http://localhost:8080/my_first_api
```
The response from that `curl` command should have a HTTP header `Omar: IsComing` which is set by `plugin-stuff/go/src/CustomGoPlugin.go`     

#### Usage from a customer perspective
1. In the machine that has internet, make sure that your Go version is compatible with the one from plugin compiler, ie Go version 1.19. Then run;
```sh
bash customer.sh /path/to/directory/with/plugin/code /tmp/myGoProxy
```
2. In the machine that has NO internet, download the custom plugin compiler.
```sh
docker pull komuw/tyk-plugin-compiler:v5.2.2
```
3. Copy the directory `/tmp/myGoProxy` to the machine that has no internet.
4. In the machine that has NO internet, run;
```sh
cd /path/to/directory/with/plugin/code

docker \
  run \
  --env GO_USE_PROXY=1 \
  --volume /path/to/directory/with/plugin/code:/plugin-source \
  --volume /tmp/myGoProxy:/tmp/myGoProxy \
  komuw/tyk-plugin-compiler:v5.2.2 CustomGoPlugin.so
```
