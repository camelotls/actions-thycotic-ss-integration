#!/bin/bash

echo "Query SS"

# Parse json_in params
THYCOTIC_SERVER_URL=$(echo "$1" | jq -r .params.api_url)
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
      # Mask output secret
      echo "::add-mask::$(cat response.txt | jq -r .)"
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
    RESPONSE_CODE=$(curl -s -o response.txt -w "%{http_code}" -XPUT -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d @payload.json "$URI")
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
      # Iterate over items and get itemValue and mask it
      cat response.txt | jq -c .items | jq -r .[].itemValue | while read SECRET_FIELD
      do
        echo "::add-mask::$SECRET_FIELD"
      done
      # Return result as output param
      echo "::set-output name=json_out::'$(cat response.txt | jq -c .)'"
      rm response.txt && exit 0
    fi
    ;;

   get_secrets)
      # Get QUERY_SECRETS as a map of secret_key: secret_id
      # e.g.:
      #{
      #  "my_secret1": "1127",
      #  "my_secret2": "1128",
      #  "my_secret3": "1129"
      #}
      echo "{" >> secrets.json
      QUERY_SECRETS=$(echo "$1" | jq -r .params.query_secrets)
      # Iterate over each secret and query via secret_id using Thycotic URL
      echo "$QUERY_SECRETS" | jq 'keys' | jq -r .[] | while read SECRET_KEY
      do
        SECRET_ID=$(echo $QUERY_SECRETS | jq -r '.'$SECRET_KEY'')
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
          # Iterate over items and get itemValue and mask it
          cat response.txt | jq -c .items | jq -r .[].itemValue | while read SECRET_FIELD
          do
            echo "::add-mask::$SECRET_FIELD"
          done
          # Write result into file
          echo "\"$SECRET_KEY\":$(cat response.txt)," >> secrets.json
          rm response.txt
        fi
      done
      # Remove last comma
      sed -i '$ s/.$//' secrets.json
      # Write the end of json file
      echo "}" >> secrets.json
      echo "::set-output name=json_out::'$(cat secrets.json | jq -c)'"
      rm secrets.json && exit 0
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

  search_secret_id)
    # Folder name to search for
    SECRET_FOLDER=$(echo "$1" | jq -r .params.secret_folder)
    # Secret name to search for
    SECRET_NAME=$(echo "$1" | jq -r .params.secret_name)
    URI_FOLDERS="$THYCOTIC_SERVER_URL/api/v1/folders?filter.searchText=${SECRET_FOLDER}"
    # Get folder id
    RESPONSE_CODE_FOLDER=$(curl -s -o response.txt -w "%{http_code}" -XGET -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" "$URI_FOLDERS")
    if [[ $RESPONSE_CODE_FOLDER != "200" ]]
    then
      # Request failed
      echo "Failed to find folder $SECRET_FOLDER"
      cat response.txt && rm response.txt && exit 1
    else
      # Request successful
      echo "Successful request: $RESPONSE_CODE_FOLDER"
      # Store folder id
      SECRET_FOLDER_ID=$(cat response.txt | jq '.records[0].id')
      URI_SECRETS="$THYCOTIC_SERVER_URL/api/v1/secrets?filter.folderId=${SECRET_FOLDER_ID}&filter.searchtext=${SECRET_NAME}&filter.isExactMatch=true"
      RESPONSE_CODE_SECRET=$(curl -s -o response_secret.txt -w "%{http_code}" -XGET -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" "$URI_SECRETS")
      if [[ $RESPONSE_CODE_SECRET != "200" ]]
      then
        # Request failed
        echo "Failed to find secret $SECRET_NAME in folder $SECRET_FOLDER"
        cat response_secret.txt && rm response_secret.txt && exit 1
      else
        # Return result as output param
        echo "::set-output name=json_out::$(cat response_secret.txt | jq -r '.records[0].id')"
      rm response.txt && rm response_secret.txt && exit 0
      fi
    fi
    ;;

  *)
    echo "{ \"msg\": \"API_METHOD undefined or unknown\", \"code:\" \"502\" }" > response.txt
    echo "::set-output name=json_out::$(cat response.txt)"
    rm response.txt && exit 1
    ;;

esac
