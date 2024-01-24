#!/usr/bin/env bash
if test "$BASH" = "" || "$BASH" -uc "a=();true \"\${a[@]}\"" 2>/dev/null; then
    # Bash 4.4, Zsh
    set -euo pipefail
else
    # Bash 4.3 and older chokes on empty arrays with set -u.
    set -eo pipefail
fi
shopt -s nullglob
set -x

curl http://localhost:8080/hello

echo "create api: "
sleep 2
curl -v \
  -H "x-tyk-authorization: changeMe" \
  -H "Content-Type: application/json" \
  -X POST \
  -d '{
    "name": "my_first_api",
    "slug": "my_first_api",
    "api_id": "my_first_api",
    "use_keyless": true,
    "custom_middleware": {
		"pre": [
        {
          "name": "AddFooBarHeader",
          "path": "/opt/tyk-gateway/middleware/CustomGoPlugin.so",
          "require_session": false
			  }
      ],
		"post": [
        {
          "name": "AddFooBarHeader",
          "path": "/opt/tyk-gateway/middleware/CustomGoPlugin.so",
          "require_session": false
        }
		  ],
		"driver": "goplugin"
	},
    "auth": {
      "auth_header_name": ""
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
}' http://localhost:8080/tyk/apis

echo "reload: "
sleep 2
curl -H "x-tyk-authorization: changeMe" http://localhost:8080/tyk/reload/group

echo "call api: "
sleep 2
curl -vkL http://localhost:8080/my_first_api
