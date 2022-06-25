#!/bin/bash

echo "Query SS"

THYCOTIC_SERVER_URL="https://camelotglobal.secretservercloud.eu"

# Parse json_in params
API_USERNAME=$(echo "$1" | jq -r .params.api_username)
API_PASSWORD=$(echo "$1" | jq -r .params.api_password)
API_METHOD=$(echo "$1" | jq -r .params.api_method)

# Get bearer token
AUTH_CODE=$(curl -s -o auth_response.txt -w "%{http_code}" -H "Content-Type: application/x-www-form-urlencoded" -d "username=$API_USERNAME&domain=sso&password=$API_PASSWORD&grant_type=password" "$THYCOTIC_SERVER_URL/oauth2/token")
# Handle status code
if [[ $AUTH_CODE != "200" ]]
then
  # Auth failed
  echo "Auth failed: $AUTH_CODE"
  cat auth_response.txt && rm auth_response.txt
  exit 1
else
  # Auth successful
  export TOKEN="$(jq -r '.access_token' auth_response.txt)" && rm auth_response.txt
fi

# API wrappers here
case "$API_METHOD" in

  # https://camelotglobal.secretservercloud.eu/RestApiDocs.ashx?doc=token-help#operation/FoldersService_Get
  get_folders)
    URI="$THYCOTIC_SERVER_URL/api/v1/folders/lookup"
    # Handle status code
    RESPONSE_CODE=$(curl -s -o response.txt -w "%{http_code}" -XGET -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" "$URI")
    if [[ $RESPONSE_CODE != "200" ]]
    then
      # Request failed
      echo "Request failed: $RESPONSE_CODE"
      cat response.txt && rm response.txt && exit 1
    else
      # Request successful
      echo "Successful request: $RESPONSE_CODE"
      # Return result as output param
      echo "::set-output name=json_out::'$(cat response.txt | jq -c .)'"
      rm response.txt && exit 0
    fi
    ;;

  # https://camelotglobal.secretservercloud.eu/RestApiDocs.ashx?doc=token-help#operation/FoldersService_Stub
  get_folder_stub)
    URI="$THYCOTIC_SERVER_URL/api/v1/folders/stub"
    # Handle status code
    RESPONSE_CODE=$(curl -s -o response.txt -w "%{http_code}" -XGET -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" "$URI")
    if [[ $RESPONSE_CODE != "200" ]]
    then
      # Request failed
      echo "Request failed: $RESPONSE_CODE"
      cat response.txt && rm response.txt && exit 1
    else
      # Request successful
      echo "Successful request: $RESPONSE_CODE"
      # Return result as output param
      echo "::set-output name=json_out::'$(cat response.txt | jq -c .)'"
      rm response.txt && exit 0
    fi
    ;;

  # https://camelotglobal.secretservercloud.eu/RestApiDocs.ashx?doc=token-help#operation/FoldersService_Create
  create_folder)
    URI="$THYCOTIC_SERVER_URL/api/v1/folders"
    # Create payload file
    echo "$1" | jq -r .params.payload > payload.json
    # Handle status code
    RESPONSE_CODE=$(curl -s -o response.txt -w "%{http_code}" -XPOST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d @payload.json "$URI")
    if [[ $RESPONSE_CODE != "200" ]]
    then
      # Request failed
      cat response.txt && rm response.txt && exit 1
    else
      # Request successful
      echo "Successful request: $RESPONSE_CODE"
      # Return result as output param
      echo "::set-output name=json_out::'$(cat response.txt | jq -c .)'"
      rm response.txt && exit 0
    fi
    ;;

  # https://camelotglobal.secretservercloud.eu/RestApiDocs.ashx?doc=token-help#operation/SecretsService_GetField
  get_secret_field)
    SECRET_ID=$(echo "$1" | jq -r .params.secret_id)
    SECRET_FIELD=$(echo "$1" | jq -r .params.secret_field)
    URI="$THYCOTIC_SERVER_URL/api/v1/secrets/${SECRET_ID}/fields/$SECRET_FIELD"
    # Handle status code
    RESPONSE_CODE=$(curl -s -o response.txt -w "%{http_code}" -XGET -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" "$URI")
    if [[ $RESPONSE_CODE != "200" ]]
    then
      # Request failed
      echo "Request failed: $RESPONSE_CODE"
      cat response.txt && rm response.txt && exit 1
    else
      # Request successful
      echo "Successful request: $RESPONSE_CODE"
      # Return result as output param
      echo "::set-output name=json_out::'$(cat response.txt | jq -c .)'"
      rm response.txt && exit 0
    fi
    ;;

  # https://camelotglobal.secretservercloud.eu/RestApiDocs.ashx?doc=token-help#operation/SecretsService_PutField
  update_secret_field)
    SECRET_ID=$(echo "$1" | jq -r .params.secret_id)
    SECRET_FIELD=$(echo "$1" | jq -r .params.secret_field)
    URI="$THYCOTIC_SERVER_URL/api/v1/secrets/${SECRET_ID}/fields/$SECRET_FIELD"
    # Create payload file
    echo "$1" | jq -r .params.payload > payload.json
    # Handle status code
    RESPONSE_CODE=$(curl -s -o response.txt -w "%{http_code}" -XPUT -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" "$URI")
    if [[ $RESPONSE_CODE != "200" ]]
    then
      # Request failed
      echo "Request failed: $RESPONSE_CODE"
      cat response.txt && rm response.txt && exit 1
    else
      # Request successful
      echo "Successful request: $RESPONSE_CODE"
      # Return result as output param
      echo "::set-output name=json_out::'$(cat response.txt | jq -c .)'"
      rm response.txt && exit 0
    fi
    ;;

  # https://camelotglobal.secretservercloud.eu/RestApiDocs.ashx?doc=token-help#operation/SecretsService_GetSecretV2
  get_secret)
    SECRET_ID=$(echo "$1" | jq -r .params.secret_id)
    URI="$THYCOTIC_SERVER_URL/api/v2/secrets/${SECRET_ID}"
    # Handle status code
    RESPONSE_CODE=$(curl -s -o response.txt -w "%{http_code}" -XGET -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" "$URI")
    if [[ $RESPONSE_CODE != "200" ]]
    then
      # Request failed
      echo "Request failed: $RESPONSE_CODE"
      cat response.txt && rm response.txt && exit 1
    else
      # Request successful
      echo "Successful request: $RESPONSE_CODE"
      # Return result as output param
      echo "::set-output name=json_out::'$(cat response.txt | jq -c .)'"
      rm response.txt && exit 0
    fi
    ;;

  # https://camelotglobal.secretservercloud.eu/RestApiDocs.ashx?doc=token-help#operation/SecretTemplatesService_GetTemplates
  get_secret_templates)
    URI="$THYCOTIC_SERVER_URL/api/v1/templates"
    # Handle status code
    RESPONSE_CODE=$(curl -s -o response.txt -w "%{http_code}" -XGET -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" "$URI")
    if [[ $RESPONSE_CODE != "200" ]]
    then
      # Request failed
      echo "Request failed: $RESPONSE_CODE"
      cat response.txt && rm response.txt && exit 1
    else
      # Request successful
      echo "Successful request: $RESPONSE_CODE"
      # Return result as output param
      echo "::set-output name=json_out::'$(cat response.txt | jq -c .)'"
      rm response.txt && exit 0
    fi
    ;;

  # https://camelotglobal.secretservercloud.eu/RestApiDocs.ashx?doc=token-help#operation/SecretsService_CreateSecret
  create_secret)
    URI="$THYCOTIC_SERVER_URL/api/v1/secrets"
    # Create payload file
    echo "$1" | jq -r .params.payload > payload.json
    # Handle status code
    RESPONSE_CODE=$(curl -s -o response.txt -w "%{http_code}" -XPOST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d @payload.json "$URI")
    if [[ $RESPONSE_CODE != "200" ]]
    then
      # Request failed
      cat response.txt && rm response.txt && exit 1
    else
      # Request successful
      echo "Successful request: $RESPONSE_CODE"
      # Return result as output param
      echo "::set-output name=json_out::'$(cat response.txt | jq -c .)'"
      rm response.txt && exit 0
    fi
    ;;

  *)
    echo "{ \"msg\": \"API_METHOD undefined or unknown\", \"code:\" \"502\" }" > response.txt
    echo "::set-output name=json_out::$(cat response.txt)"
    rm response.txt && exit 1
    ;;

esac
