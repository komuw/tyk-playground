Tyk has some very good documentation available at: https://tyk.io/docs/      
It also has a very supportive community at: https://community.tyk.io/     

Here's a page showing the differences between the three main Tyk tiers/plans: https://tyk.io/docs/apim/      
The three plans are:              
 1. Open Source   - free                     
 2. Self-Managed  - where you pay for support, and optionally pay for addition products like Tyk Developer Portal(discussed futher below)                        
 2. Cloud         - on the cloud, saves you the hustle of devops.                

The Tyk Developer Portal(documentation: https://tyk.io/docs/tyk-developer-portal/)                  
 - This is a product that is available to paid users.                  
 - You usually/only need this, if your company is going to give the general public access to           
   your API's for them to build applications.                 
   For example, The Financial Times(https://developer.ft.com/portal) is a company that uses Tyk developer portal.                
   Anyone in the world can go and signup and create applications that use the Financial Times API.                       
 - If your APIs are used only by your employees/devs, then you may not need the portal.                        

I'm now going to focus on the open-soure(ie free) Tyk gateway:    
Here's a [page showing an overview](https://tyk.io/docs/apim/open-source/#:~:text=Open%20Source%20API%20Gateway%20Features) of some of the features available in the tyk-gateway.    


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
  Tyk supports the following methods of auth & authz; (Basic Authentication, Bearer Tokens, HMAC Signatures, JSON Web Tokens, Multiple Auth, OAuth 2.0, Open (Keyless- ie, No authentication), OpenID Connect, Using plugins (which can be written in Python, Go, javascript etc), Physical Key Expiry and Deletion)    
  For example, here's a description of how to enable Basic authentication via the dashboard; https://tyk.io/docs/basic-config-and-security/security/authentication-authorization/basic-auth/        
  I will show an example of using bearer token for authentication in the [examples](#examples) section.

2. Rate-limiting, Throttling etc.        
   see docs: https://tyk.io/docs/basic-config-and-security/control-limit-traffic/     
   Here's how you would setup ratelimiting via the dashboard; https://tyk.io/docs/basic-config-and-security/control-limit-traffic/rate-limiting/

3. Caching.        
   see docs: https://tyk.io/docs/basic-config-and-security/reduce-latency/caching/

4. Service discovery        
   see docs: https://tyk.io/docs/planning-for-production/ensure-high-availability/service-discovery/

5. Circuit breaker.        
   see docs: https://tyk.io/docs/planning-for-production/ensure-high-availability/circuit-breakers/

6. Load balancing.        
   see docs: https://tyk.io/docs/planning-for-production/ensure-high-availability/load-balancing/

7. Health check, liveness & uptime.        
   see docs: https://tyk.io/docs/planning-for-production/ensure-high-availability/health-check/        
             https://tyk.io/docs/planning-for-production/ensure-high-availability/uptime-tests/

8. API versioning.        
   see docs: https://tyk.io/docs/getting-started/key-concepts/versioning/

9. API imports.        
   see docs: https://tyk.io/docs/getting-started/import-apis/        
   You can import Swagger/OpenAPI json definitions of your APIs to the tyk gateway. 

10. Plugins.        
   see docs: https://tyk.io/docs/plugins/        
   You can use either Go, Python, JS, Lua or GRPC to write your plugins; https://tyk.io/docs/plugins/supported-languages/        
   Those plugins have access to both the request and the response; https://tyk.io/docs/concepts/middleware-execution-order/        
   Here is an example plugin written in python; https://github.com/TykTechnologies/tyk-plugin-demo-python/blob/master/middleware.py         

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

15. Tyk has many more features. Please consult the [documentation](https://tyk.io/docs/)       
         
         

# examples:
Let's go through some examples. This examples do not cover all the various things that the tyk-gateway can do; for a more comprehensive take, see the [tyk documentation](https://tyk.io/docs/)      
In this examples, we will:     
1. Create an API
2. Add authentication to the API.
3. Add rate-limiting for that API.
4. Add load balancing.
5. Add API versioning.

### 0. pre-requisite:     
- We are using tyk running inside docker, see the `docker-compose.yml` file in this repo.   
- The tyk configuration we are going to use is very minimal. see the `my_tyk.conf` file in this repo.   
  To see the full array of options that you can configure tyk gateway with, see; https://tyk.io/docs/tyk-oss-gateway/configuration/     
- run the commands
```sh   
git clone git@github.com:komuw/tyk-playground.git
cd tyk-playground
docker-compose up
```
- The gateway should now be up and running. To confirm, run;
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


### 1. Create an API:
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
- If it succeds, you should see a response like;
```sh
HTTP/1.1 200 OK
{
    "key": "my_first_api",
    "status": "ok",
    "action": "added"
}
```
- In the above example;     
    - We have created an API called `my_first_api`
    - The upstream application that we are proxying to is `http://example.com`
    - The uri on the tyk-gateway that we need to call(send requests to) is `/my_first_api`
    - In order to access that uri, we will have to send a HTTP header called `X-example.com-API-KEY`. What value should we use for that header? We'll find out in [Add authentication to the API](2-Add-authentication-to-the-API) below.
- NB:    
    - Do not add a suffix slash to the listen_path. ie do not use `"/my_first_api/"`       
      This will enable requests to both `http://localhost:7391/my_first_api/` and `http://localhost:7391/my_first_api` to go to `http://example.com`
    - The value `changeMe` is the same as the `secret` value in `my_tyk.conf`
- After adding the API, we need to reload the gateway. We can do so by sending the request;
```sh
curl -H "x-tyk-authorization: changeMe" http://localhost:7391/tyk/reload/group
```
- If it succeds, you should see a response like;
```sh
HTTP/1.1 200 OK
{
    "status": "ok",
    "message": ""
}
```
- You can also check for the list of APIs, using the command;
```sh
curl -vkL -H "x-tyk-authorization: changeMe" http://localhost:7391/tyk/apis
```

### 2. Add authentication to the API:
- In order to be able to access the uri `/my_first_api` which "maps" to the upstream `http://example.com`, we need to pass in the header `X-example.com-API-KEY`.    
  We thus need to create the value for which we'll pass in that http header.    
  We'll do so by creating an API Key and give it access right to the API created in step 1(above).
- run the command;
```sh
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
- If it succeds, you should get a response like;
```sh
HTTP/1.1 200 OK
{
    "key": "a22dccb024354c3fa608a28fa621436a",
    "status": "ok",
    "action": "added"
}
```
- Keep note of the value of the `key`(ie `a22dccb024354c3fa608a28fa621436a`) in the response
- NB:
    - the `api_id` and `api_name` should match the ones in step 1(above).
- After adding the Key, we need to reload the gateway. We can do so by sending the request;
```sh
curl -H "x-tyk-authorization: changeMe" http://localhost:7391/tyk/reload/group
```
- Now that we have created an access/api key, we are ready to call(send requests to) our API.
- You can try sending a request like;
```sh
curl -vkL http://localhost:7391/my_first_api 
```
- But that will return an error like;
```sh
HTTP/1.1 401 Unauthorized
{
    "error": "Authorization field missing"
}
```
- This is the tyk-gateway doing its job; protecting APIs from unauthorized(unwanted) access.
- Instead, if you send a command like;
```sh
curl -vkL -H "X-example.com-API-KEY: a22dccb024354c3fa608a28fa621436a" http://localhost:7391/my_first_api
```
- You will get a response like;
```sh
HTTP/1.1 200 OK
<!doctype html>
<html>
<head>
    <title>Example Domain</title>
<div>
    <h1>Example Domain</h1>
    <p>This domain is for use in illustrative examples in documents. You may use this
    domain in literature without prior coordination or asking for permission.</p>
    <p><a href="https://www.iana.org/domains/example">More information...</a></p>
</div>
</body>
</html>
```
- As you can see, even though we sent the request to our gateway(`http://localhost:7391/my_first_api`), the gateway did send the request upstream(`http://example.com`) and we got the expected response.
- NB:      
    - The value `a22dccb024354c3fa608a28fa621436a` that we pass into the `X-example.com-API-KEY` http header is the value we got when we created the API key.    
      If you forget the value, you can always get it back by running the command
```sh
curl -vkL -H "x-tyk-authorization: changeMe" http://localhost:7391/tyk/keys
```

### 3. Add rate-limiting for that API:
- Let's say we want to only allow 1 request per minute(60seconds), we can do so by running the command;
```sh
curl -X PUT \
  -H "x-tyk-authorization: changeMe" \
  -H "Content-Type: application/json" \
  -d '{
    "allowance": 1,
    "rate": 1,
    "per": 60,
    "access_rights": {
      "my_first_api": {
        "api_id": "my_first_api",
        "api_name": "my_first_api",
        "versions": ["Default"]
      }
    }
  }' http://localhost:7391/tyk/keys/a22dccb024354c3fa608a28fa621436a
```
- If it succeds you should get a http status 200 response code.
- NB:     
    - we are using HTTP PUT(`-X PUT`) instead of HTTP POST(`-X POST`) so as to update the key instead of creating a new one.
    - the uri we call is `/tyk/keys/<key_id>`
    - `allowance` & `rate` should be set to the same value.
    - in the example above, we are setting a rate limit of 1 request per 60 seconds.
    - The value `a22dccb024354c3fa608a28fa621436a` that we pass into the `X-example.com-API-KEY` http header is the value we got when we created the API key.    
      If you forget the value, you can always get it back by running the command
```sh
curl -vkL -H "x-tyk-authorization: changeMe" http://localhost:7391/tyk/keys
```
- After updating the Key, we need to reload the gateway. We can do so by sending the request;
```sh
curl -H "x-tyk-authorization: changeMe" http://localhost:7391/tyk/reload/group
```
- Call our api and it should succed;
```sh
curl -vkL -H "X-example.com-API-KEY: a22dccb024354c3fa608a28fa621436a" http://localhost:7391/my_first_api
```
- However the following, should fail with error: `Rate limit exceeded`
```sh
for i in {1..5}
do
  printf "\n\t calling our API for the $i time.\n"
  curl -H "X-example.com-API-KEY: a22dccb024354c3fa608a28fa621436a" http://localhost:7391/my_first_api
  sleep 2
done
```
- Let's undo that change so that we can be able to continue with the other examples without rate limit errors. run the command;
```sh
# set a rate of 1000 requests per minute
curl -X PUT \
  -H "x-tyk-authorization: changeMe" \
  -H "Content-Type: application/json" \
  -d '{
    "allowance": 1000,
    "rate": 1000,
    "per": 60,
    "access_rights": {
      "my_first_api": {
        "api_id": "my_first_api",
        "api_name": "my_first_api",
        "versions": ["Default"]
      }
    }
  }' http://localhost:7391/tyk/keys/a22dccb024354c3fa608a28fa621436a

# reload the gateway
curl -H "x-tyk-authorization: changeMe" http://localhost:7391/tyk/reload/group
```

### 4. Add load balancing:
- Tyk supports native round-robin load-balancing in its proxy.        
  This means that Tyk will rotate requests through a list of target hosts as requests come in.      
  See the [documentation](https://tyk.io/docs/planning-for-production/ensure-high-availability/load-balancing/)
- Let's say we have three upstreams that we would like to load balance our requests to; `example.com`, `httpbin.org/get` & `example.net`.
- We can do so by sending the command;
```sh
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
        "http://example.com",
        "http://httpbin.org/get",
        "http://example.net"
      ],
      "strip_listen_path": true,
      "enable_load_balancing": true
    },
    "active": true
}' http://localhost:7391/tyk/apis/my_first_api
```
- NB:
     - we are using HTTP PUT(`-X PUT`) instead of HTTP POST(`-X POST`) so as to update the key instead of creating a new one.
     - the uri we call is `/tyk/apis/<api_id>`
     - we have replaced `target_url` with `target_list`.
       Tyk will load balance requests to the members in `target_list`
- Reload the gateway;
```sh
curl -H "x-tyk-authorization: changeMe" http://localhost:7391/tyk/reload/group
```
- Send a number of requests to our api;
```sh
for i in {1..5}
do
  printf "\n\t calling our API for the $i time.\n"
  curl -H "X-example.com-API-KEY: a22dccb024354c3fa608a28fa621436a" http://localhost:7391/my_first_api
  sleep 2
done
```
- You will see that some requests are sent to `example.com`, others to `http://httpbin.org/get` and also `example.net`

### 5. Add API versioning:
- See [documentation](https://tyk.io/docs/getting-started/key-concepts/versioning/)
- We can add versiong to our API by sending the request;
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
```
- NB:      
     - we have set `version_data.not_versioned` to `false` to enable versioning.
     - we have set `definition.location` to `header` showing that we expect a HTTP header whose name will be `x-api-version`
- reload the gateway.
```sh
curl -H "x-tyk-authorization: changeMe" http://localhost:7391/tyk/reload/group
```
- If you call the api as per usual;
```sh
curl -H "X-example.com-API-KEY: a22dccb024354c3fa608a28fa621436a" http://localhost:7391/my_first_api
```
- You get the response;
```sh
HTTP/1.1 403 Forbidden
{
    "error": "Version information not found"
}
```
- If you pass in the correct version http header;
```sh
curl -H "X-example.com-API-KEY: a22dccb024354c3fa608a28fa621436a" -H "x-api-version: version-1" http://localhost:7391/my_first_api
```
- You get the response;
```sh
HTTP/1.1 403 Forbidden
{
    "error": "Access to this API has been disallowed"
}
```
- This is because, the `X-example.com-API-KEY` we are using does not have access right to this versioned API.
- We need to update the API key to give it access rights to this version.
```sh
curl -X PUT \
  -H "x-tyk-authorization: changeMe" \
  -H "Content-Type: application/json" \
  -d '{
    "allowance": 1,
    "rate": 1,
    "per": 60,
    "access_rights": {
      "my_first_api": {
        "api_id": "my_first_api",
        "api_name": "my_first_api",
        "versions": ["Default", "version-1"]
      }
    }
  }' http://localhost:7391/tyk/keys/a22dccb024354c3fa608a28fa621436a
```
- reload the gateway.
```sh
curl -H "x-tyk-authorization: changeMe" http://localhost:7391/tyk/reload/group
```
- Now you can call the api and it will succed.
```sh
curl -H "X-example.com-API-KEY: a22dccb024354c3fa608a28fa621436a" -H "x-api-version: version-1" http://localhost:7391/my_first_api
```
