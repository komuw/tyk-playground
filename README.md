Tyk has some very good documentation available at: https://tyk.io/docs/      
It also has a very supportive community at: https://community.tyk.io/     

Here's a page showing the differences between the three main Tyk tiers/plans: https://tyk.io/docs/apim/      
The three plans are:              
 1. Open Source   - free                     
 2. Self-Managed  - where you pay for support, and optionally pay for addition products like Tyk Developer Portal(discussed futher below)                        
 2. Cloud         - on the cloud, saves you the hustle of devops.                

The Tyk Developer Portal(documentation: https://tyk.io/docs/tyk-developer-portal/)                  
 - This is a product that is only available to paid users.                  
 - You usually/only need this, if your company is going to give the general public access to           
   your API's for them to build applications.                 
   For example, The Financial Times(https://developer.ft.com/portal) is a company that uses Tyk developer portal.                
   Anyone in the world can go and signup and create applications that use the Financial Times API.                       
 - If your APIs are used only by your employees/devs, then you may not need the portal.                        

I'm now going to focus on the open-soure(ie free) Tyk gateway:    
Here's a page showing an overview of some of the features available in the tyk-gateway: https://tyk.io/docs/apim/open-source/#:~:text=Open%20Source%20API%20Gateway%20Features    


You can configure the tyk-gateway(eg, create API's) via either;            
(a) the [tyk-dashboard](https://tyk.io/docs/tyk-dashboard/)                     
    and/or       
(b) making API calls to the [tyk-gateway API](https://tyk.io/docs/tyk-gateway-api/)       

In the [examples](#examples) section below, I'm going to use the [tyk-gateway API](https://tyk.io/docs/tyk-gateway-api/) to configure the tyk-gateway.    
But the [tyk-dashboard](https://tyk.io/docs/tyk-dashboard/) does offer similar functionality in a much nicer interface.    

Let's talk about some tyk-gateway features before going through [examples](#examples).   

### features.
1. Authentication & Authorization
   see docs: https://tyk.io/docs/basic-config-and-security/security/authentication-authorization/
  Tyk supports the following methods of auth & authz;
    - Basic Authentication
    - Bearer Tokens
    - HMAC Signatures
    - JSON Web Tokens
    - Multiple Auth
    - OAuth 2.0
    - Open (Keyless) - ie, No authentication
    - OpenID Connect
    - Using plugins (which can be written in Python, Go, javascript etc)
    - Physical Key Expiry and Deletion
  For example, here's a description of how to enable Basic authentication via the dashboard; https://tyk.io/docs/basic-config-and-security/security/authentication-authorization/basic-auth/        
  I will show an example of using bearer token for authentication in the [examples](#examples) section.

2. Rate-limiting, Throttling etc.
   see docs: https://tyk.io/docs/basic-config-and-security/control-limit-traffic/
   Here's how you would setup ratelimiting via the dashboard; https://tyk.io/docs/basic-config-and-security/control-limit-traffic/rate-limiting/

3. Caching.
   see docs: https://tyk.io/docs/basic-config-and-security/reduce-latency/caching/

4. Service discovery
   see docs: https://tyk.io/docs/planning-for-production/ensure-high-availability/service-discovery/
             https://cs.github.com/TykTechnologies/tyk/blob/ae78504252e2ebf2fd17eb3e6d1ba172efea87e5/swagger.yml?q=use_discovery_service#L2662-L2686
             https://cs.github.com/TykTechnologies/tyk/blob/ae78504252e2ebf2fd17eb3e6d1ba172efea87e5/config/config.go?q=type+config+struct#L515-L516

5. Circuit breaker.
   see docs: https://tyk.io/docs/planning-for-production/ensure-high-availability/circuit-breakers/
             https://cs.github.com/TykTechnologies/tyk/blob/ae78504252e2ebf2fd17eb3e6d1ba172efea87e5/swagger.yml?q=use_discovery_service#L2065-L2086
             https://cs.github.com/TykTechnologies/tyk/blob/ae78504252e2ebf2fd17eb3e6d1ba172efea87e5/config/config.go?q=type+config+struct#L515-L516

6. Load balancing.
   see docs: https://tyk.io/docs/planning-for-production/ensure-high-availability/load-balancing/

7. Health check, liveness & uptime
   see docs: https://tyk.io/docs/planning-for-production/ensure-high-availability/health-check/
             https://tyk.io/docs/planning-for-production/ensure-high-availability/uptime-tests/

8. API versioning.
   see docs: https://tyk.io/docs/getting-started/key-concepts/versioning/

9. API imports.
   see docs: https://tyk.io/docs/getting-started/import-apis/
   You can import Swagger/OpenAPI json definitions of your APIs to the tyk gateway. 

10. Plugins.
   see docs: https://tyk.io/docs/plugins/
   you can use either Go, Python, JS, Lua or GRPC to write your plugins; https://tyk.io/docs/plugins/supported-languages/
   Those plugins have access to both the request and the response; https://tyk.io/docs/concepts/middleware-execution-order/
   Here is an example plugin written in python; https://github.com/TykTechnologies/tyk-plugin-demo-python/blob/master/middleware.py
   
   Plugins are for advanced uses. Most of the things you want to do in the gateway can be done on the tyk-dashboard without using a plugin.
   For example, you can add/remove HTTP headers from requests/responses using the tyk-dashboard(no plugins needed), see: https://tyk.io/docs/advanced-configuration/transform-traffic/response-headers/

11. Analytics.
    see docs: https://tyk.io/docs/tyk-dashboard-analytics/

12. Access control.
    You can use Role Based Access Control(RBAC) or 
    Tyk also suppors using Open Policy Agent (OPA)
    see docs: https://tyk.io/docs/tyk-dashboard/rbac/
              https://tyk.io/docs/tyk-dashboard/open-policy-agent/

13. Proxy.
    see docs: https://tyk.io/docs/key-concepts/tcp-proxy/
              https://tyk.io/docs/key-concepts/grpc-proxy/

14. You can also enable HTTP2
      https://tyk.io/docs/tyk-oss-gateway/configuration/#http_server_optionsenable_http2


## examples:
Let's go through some examples. This examples do not cover all the various things that the tyk-gateway can do, for a more comprehensive take see the [tyk documentation](https://tyk.io/docs/)      
In this examples, we will:     
1. Create an API
2. Add authentication to the API.
3. Enable rate-limiting for that api.
4. Enable load balancing.
5. Add API versioning.
6. Add uptime tests.  

0. pre-requisite:     
- We are using tyk running inside docker, see the `docker-compose.yml` file in this repo.   
- The tyk configuration we are going to use is very minimal. see the `my_tyk.conf` file in this repo.   
  To see the full array of options that you can configure tyk gateway with, see; https://tyk.io/docs/tyk-oss-gateway/configuration/      
- `git clone git@github.com:komuw/tyk-playground.git` 
- `cd tyk-playground`
- `docker-compose up`
- The gateway should be up and running, to confirm; run;
- `curl http://localhost:7391/hello` which should output something like;
```bash
HTTP/1.1 200 OK
Content-Type: application/json
Date: Tue, 11 Jan 2022 14:23:31 GMT
Content-Length: 156

{
    "status": "pass",
    "version": "v4.0.0",
    "description": "Tyk GW",
    "details": {
        "redis": {
            "status": "pass",
            "componentType": "datastore",
            "time": "2022-01-11T14:23:28Z"
        }
    }
}
```
- NB: the port `7391` is the same port number declared as the `listen_port` value in `my_tyk.conf`


1. Create an API:
- see the [documentation](https://tyk.io/docs/getting-started/create-api/)
- run the command;
```sh
    curl -v \
      -H "x-tyk-authorization: changeMe" \
      -H "Content-Type: application/json" \
      -X POST \
      -d '{
        "name": "my_first_api",
        "slug": "my_first_api",
        "api_id": "my_first_api",
        "auth": {
          "auth_header_name": "X-example.com-API-KEY"
        },
        "version_data": {
          "not_versioned": true,
          "versions": {
            "Default": {
              "name": "Default",
              "use_extended_paths": true
            }
          }
        },
        "proxy": {
          "listen_path": "/my_first_api",
          "target_url": "http://example.com",
          "strip_listen_path": true
        },
        "active": true
    }' http://localhost:7391/tyk/apis
```

    # NB:
    # - do not add a suffix slash to the listen_path. ie do not use `"/my_first_api/"`
    #   This will enable requests to both `http://localhost:7391/my_first_api/` and `http://localhost:7391/my_first_api`
    #   to go to `http://example.com`

    # reload:
    curl -H "x-tyk-authorization: changeMe" http://localhost:7391/tyk/reload/group

    # check if created:
    curl -vkL -H "x-tyk-authorization: changeMe" http://localhost:7391/tyk/apis

    # We need to now create an access key for the above API.
    curl -X POST \
      -H "x-tyk-authorization: changeMe" \
      -H "Content-Type: application/json" \
      -d '{
        "access_rights": {
          "my_first_api": {
            "api_id": "my_first_api",
            "api_name": "my_first_api",
            "versions": ["Default"]
          }
        }
      }' http://localhost:7391/tyk/keys/create

     # reload:
     curl -H "x-tyk-authorization: changeMe" http://localhost:7391/tyk/reload/group

     # check if key was created
     curl -vkL -H "x-tyk-authorization: changeMe" http://localhost:7391/tyk/keys
     # you can also check the attributes of each key.
     curl -vkL -H "x-tyk-authorization: changeMe" http://localhost:7391/tyk/keys/9c63ac7767d6451fafd9c47ec16bc60d
      # where `9c63ac7767d6451fafd9c47ec16bc60d` is the key_id

    # call our API.
      # The following rightly fails with error: `Authorization field missing`
      curl -vkL http://localhost:7391/my_first_api 
      # The following works. Where, `9c63ac7767d6451fafd9c47ec16bc60d` is the value of the key created in (b) above.
      # The value of that key(`9c63ac7767d6451fafd9c47ec16bc60d`) can also be got by running the command;
      # curl -vkL -H "x-tyk-authorization: changeMe" http://localhost:7391/tyk/keys
      curl -vkL -H "X-example.com-API-KEY: 9c63ac7767d6451fafd9c47ec16bc60d" http://localhost:7391/my_first_api


2. Add auth to that API.(use bearer token auth)
3. Add rate-limiting
    curl -X PUT \
          -H "x-tyk-authorization: changeMe" \
          -H "Content-Type: application/json" \
          -d '{
            "allowance": 1,
            "rate": 1,
            "per": 30,
            "access_rights": {
              "my_first_api": {
                "api_id": "my_first_api",
                "api_name": "my_first_api",
                "versions": ["Default"]
              }
            }
          }' http://localhost:7391/tyk/keys/9c63ac7767d6451fafd9c47ec16bc60d

    # NB:
    # - we are using HTTP PUT(`-X PUT`) instead of HTTP POST(`-X POST`) so as to update the key instead of creating a new one.
    # - the uri we call is `/tyk/keys/<key_id>`
    # - `allowance` & `rate` should be set to the same value.
    # - in the example above, we are setting a rate limit of 1 request per 30 seconds.

     # reload:
     curl -H "x-tyk-authorization: changeMe" http://localhost:7391/tyk/reload/group

     # check if key was updated
     curl -vkL -H "x-tyk-authorization: changeMe" http://localhost:7391/tyk/keys/9c63ac7767d6451fafd9c47ec16bc60d | jq | grep -i "allowance" -B 2 -A 2

     # call our API.
     # The following should succeed.
     curl -vkL -H "X-example.com-API-KEY: 9c63ac7767d6451fafd9c47ec16bc60d" http://localhost:7391/my_first_api
     # However the following, should fail with error: `Rate limit exceeded`
     for i in {1..5}
     do
       printf "calling our API for the $i time."
       curl -H "X-example.com-API-KEY: 9c63ac7767d6451fafd9c47ec16bc60d" http://localhost:7391/my_first_api
       sleep 2
     done


4. Add caching.
5. enable load balancing
    # Tyk supports native round-robin load-balancing in its proxy. This means that Tyk will rotate requests through a list of target hosts as requests come in. 
    # docs: https://tyk.io/docs/planning-for-production/ensure-high-availability/load-balancing/

    curl -v \
      -H "x-tyk-authorization: changeMe" \
      -H "Content-Type: application/json" \
      -X PUT \
      -d '{
        "name": "my_first_api",
        "slug": "my_first_api",
        "api_id": "my_first_api",
        "auth": {
          "auth_header_name": "X-example.com-API-KEY"
        },
        "version_data": {
          "not_versioned": true,
          "versions": {
            "Default": {
              "name": "Default",
              "use_extended_paths": true
            }
          }
        },
        "proxy": {
          "listen_path": "/my_first_api",
          "target_list": [
            "http://httpbin.org/get",
            "http://example.com",
            "http://httpbin.org/anything"
          ],
          "strip_listen_path": true,
          "enable_load_balancing": true
        },
        "active": true
    }' http://localhost:7391/tyk/apis/my_first_api

    # NB:
    # - we are using HTTP PUT(`-X PUT`) instead of HTTP POST(`-X POST`) so as to update the key instead of creating a new one.
    # - the uri we call is `/tyk/apis/<api_id>`
    # - we have replaced `target_url` with `target_list`.
    #   Tyk will load balance requests to the members in `target_list`
  
    # reload:
    curl -H "x-tyk-authorization: changeMe" http://localhost:7391/tyk/reload/group

    # call our API 
    curl -H "X-example.com-API-KEY: 9c63ac7767d6451fafd9c47ec16bc60d" http://localhost:7391/my_first_api | less

   

6. Add health-checking & uptime tests
   # docs: https://tyk.io/docs/planning-for-production/ensure-high-availability/uptime-tests/

    curl -v \
        -H "x-tyk-authorization: changeMe" \
        -H "Content-Type: application/json" \
        -X PUT \
        -d '{
        "name": "my_first_api",
        "slug": "my_first_api",
        "api_id": "my_first_api",
        "auth": {
            "auth_header_name": "X-example.com-API-KEY"
        },
        "version_data": {
            "not_versioned": true,
            "versions": {
            "Default": {
                "name": "Default",
                "use_extended_paths": true
            }
            }
        },
        "uptime_tests": {
            "check_list": [
                    {"url": "http://httpbin.org", "method": "GET"},
                    {"url": "http://example.com", "method": "GET"}
            ]
        },
        "proxy": {
            "listen_path": "/my_first_api",
            "check_host_against_uptime_tests": true,
            "target_list": [
            "http://httpbin.org/get",
            "http://example.com",
            "http://httpbin.org/anything"
            ],
            "strip_listen_path": true,
            "enable_load_balancing": true
        },
        "active": true
      }' http://localhost:7391/tyk/apis/my_first_api


    # NB:
    # - you need to have initially enabled uptime-checking in your `tyk.conf`(in our case it is the file called `my_tyk.conf`)
    #     see the `uptime_tests` section inside of `my_tyk.conf` 
    #   see: https://tyk.io/docs/planning-for-production/ensure-high-availability/uptime-tests/#initial-configuration

    # reload:
    curl -H "x-tyk-authorization: changeMe" http://localhost:7391/tyk/reload/group

    # call our API 
    curl -H "X-example.com-API-KEY: 9c63ac7767d6451fafd9c47ec16bc60d" http://localhost:7391/my_first_api
     
     # If uptime checks failed, calling our api would fail with error: `all hosts are down`
     # And the tyk gateway will have logs like;
       level=warning msg="[HOST CHECKER] [HOST DOWN]: http://non-existent-domain-12345.com"
       level=warning msg="[HOST CHECKER] [HOST DOWN]: http://another-non-existent-domain-12345.com"  


7. Add api versioning 
    docs: https://tyk.io/docs/getting-started/key-concepts/versioning/

    curl -v \
      -H "x-tyk-authorization: changeMe" \
      -H "Content-Type: application/json" \
      -X POST \
      -d '{
        "name": "my_first_api",
        "slug": "my_first_api",
        "api_id": "my_first_api",
        "auth": {
          "auth_header_name": "X-example.com-API-KEY"
        },
        "definition": {
            "location": "header",
            "key": "x-api-version"
        },
        "version_data": {
          "not_versioned": false,
          "versions": {
            "version-1": {
              "name": "version-1",
              "use_extended_paths": true
            }
          }
        },
        "proxy": {
          "listen_path": "/my_first_api",
          "target_url": "http://example.com",
          "strip_listen_path": true
        },
        "active": true
    }' http://localhost:7391/tyk/apis

    # NB:
    # - we have set `version_data.not_versioned` to `false` to enable versioning.
    # - we have set `definition.location` to `header` showing that we expect a HTTP header whose name will be `x-api-version`

    # reload:
    curl -H "x-tyk-authorization: changeMe" http://localhost:7391/tyk/reload/group

    # call our API 
    curl -H "X-example.com-API-KEY: 9c63ac7767d6451fafd9c47ec16bc60d" http://localhost:7391/my_first_api
      # the above fails with error: `Version information not found`
    curl -H "X-example.com-API-KEY: 9c63ac7767d6451fafd9c47ec16bc60d" -H "x-api-version: v1" http://localhost:7391/my_first_api
      # the above fails with error: `This API version does not seem to exist`
    curl -H "X-example.com-API-KEY: 9c63ac7767d6451fafd9c47ec16bc60d" -H "x-api-version: version-1" http://localhost:7391/my_first_api
      # the above fails with error: `Access to this API has been disallowed`
    
    # We need to update the key, to give it access to this versioned api.
    curl -X PUT \
          -H "x-tyk-authorization: changeMe" \
          -H "Content-Type: application/json" \
          -d '{
            "allowance": 1,
            "rate": 1,
            "per": 30,
            "access_rights": {
              "my_first_api": {
                "api_id": "my_first_api",
                "api_name": "my_first_api",
                "versions": ["Default", "version-1"]
              }
            }
          }' http://localhost:7391/tyk/keys/9c63ac7767d6451fafd9c47ec16bc60d
    
    # reload:
    curl -H "x-tyk-authorization: changeMe" http://localhost:7391/tyk/reload/group

    # call our API
    curl -H "X-example.com-API-KEY: 9c63ac7767d6451fafd9c47ec16bc60d" -H "x-api-version: version-1" http://localhost:7391/my_first_api
      # this succeeds.
