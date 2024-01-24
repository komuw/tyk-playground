### What?
If you would like to build a Tyk plugin in a machine that does not have internet access.      
This repo uses Go v1.19 and Tyk version v5.2.2, but the idea is applicable across versions.       

We create a new plugin-compiler docker image in `plugin-stuff/plugin_compiler_Dockerfile`. This is based on https://github.com/TykTechnologies/tyk/tree/master/ci/images/plugin-compiler but updated to allow a custom `GOPROXY`. The idea in here could be transferred over to the main Tyk plugin compiler.         

This features a custom plugin compiler is updated so that building plugins does not require internet access.            

### Usage:
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

