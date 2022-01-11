We will:
1. create an API.
    docs: https://tyk.io/docs/getting-started/create-api/

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
