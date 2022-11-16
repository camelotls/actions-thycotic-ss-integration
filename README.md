# Thycotic Secret Server docker action

This action is a wrapper against Thycotic Secret Server API.

## Inputs

## `json_in`

**Required** Thycotic Secret Server input params.
`json_in` example:
```
{
  "params": {
    "api_url": "https://ORG.secretservercloud.eu",
    "api_username": "${{ secrets.THYCOTIC_APPLICATION_USER }}",
    "api_password": "${{ secrets.THYCOTIC_APPLICATION_USER_PASSWORD }}",
    "api_method": "get_secret_field",
    "secret_id": "1234",
    "secret_field": "password"
  }
}
```
The api_method:`get_secret_field` supports file attachments. To return the file's contents of a thycotic secret, add the `"is_file":true` to the json_in params.

Note, that thefile content returned in base64 encoded form, so take care to decode before using

#### Example:
```
{
  "params": {
    "api_url": "https://ORG.secretservercloud.eu",
    "api_username": "${{ secrets.THYCOTIC_APPLICATION_USER }}",
    "api_password": "${{ secrets.THYCOTIC_APPLICATION_USER_PASSWORD }}",
    "api_method": "get_secret_field",
    "secret_id": "1234",
    "secret_field": "file-secret",
    "is_file":true
  }
}
```

## Outputs

## `json_out`

Thycotic Secret Server json response.

## API documentation
Please refer to the Thycotic Secret Server API before using this action.

## Example usage
```yaml
  - name: Get secret field
    id: get_secret_field
    uses: camelotls/actions-thycotic-ss-integration@v3
    with:
    json_in: |
      {
        "params": {
          "api_url": "https://ORG.secretservercloud.eu",
          "api_username": "${{ secrets.THYCOTIC_APPLICATION_USER }}",
          "api_password": "${{ secrets.THYCOTIC_APPLICATION_USER_PASSWORD }}",
          "api_method": "get_secret_field",
          "secret_id": "1234",
          "secret_field": "password"
        }
      }
  - name: Print get_secret_field response
    run: |
      echo "Response is: "
      echo ${{ steps.get_secret_field.outputs.json_out }}
      
  - name: Get secret
    id: get_secret
    uses: camelotls/actions-thycotic-ss-integration@v2
    with:
    json_in: |
    {
      "params": {
        "api_url": "https://ORG.secretservercloud.eu",
        "api_username": "${{ secrets.THYCOTIC_APPLICATION_USER }}",
        "api_password": "${{ secrets.THYCOTIC_APPLICATION_USER_PASSWORD }}",
        "api_method": "get_secret",
        "secret_id": "1234"
      }
    }
  - name: Print get_secret response
    run: |
      echo "Response is: "
      echo ${{ steps.get_secret.outputs.json_out }} | jq .

  - name: Create folder
    id: create_folder
    uses: camelotls/actions-thycotic-ss-integration@v3
    with:
    json_in: |
      {
        "params": {
          "api_url": "https://ORG.secretservercloud.eu",
          "api_username": "${{ secrets.THYCOTIC_APPLICATION_USER }}",
          "api_password": "${{ secrets.THYCOTIC_APPLICATION_USER_PASSWORD }}",
          "api_method": "create_folder",
          "payload": {
              "folderName": "testfolder",
              "folderTypeId": 1,
              "parentFolderId": 1234
          }
        }
      }
  - name: Print create_folder response
    run: |
      echo "Response is: "
      echo ${{ steps.create_folder.outputs.json_out }} | jq .
 
  - name: Search for secret id
    id: search_secret_id
    uses: camelotls/actions-thycotic-ss-integration@v3
    with:
    json_in: |
      {
        "params": {
          "api_url": "https://camelotglobal.secretservercloud.eu",
          "api_username": "${{ secrets.THYCOTIC_APPLICATION_USER }}",
          "api_password": "${{ secrets.THYCOTIC_APPLICATION_USER_PASSWORD }}",
          "api_method": "search_secret_id",
          "secret_folder": "cluster_name",
          "secret_name": "admin.conf",
          "secret_field": "password"
        }
      }
  - name: Print search_secret_id  response
    run: |
      echo "Response is: "
      echo ${{ steps.search_secret_id.outputs.json_out }} | jq .

  - name: Get bulk secrets from Thycotic
    id: get_test_secrets
    uses: camelotls/actions-thycotic-ss-integration@v3
    with:
      json_in: |
        {
          "params": {
            "api_url": "https://camelotglobal.secretservercloud.eu",
            "api_username": "${{ secrets.THYCOTIC_APPLICATION_USER }}",
            "api_password": "${{ secrets.THYCOTIC_APPLICATION_USER_PASSWORD }}",
            "api_method": "get_secrets",
            "query_secrets": {
              "my_secret1": "1111",
              "my_secret2": "2222",
              "my_secret3": "3333"
             }
          }
        }

  - name: Test outputs
    run: |
      echo "Let's get a value of \"Password\" field for my_secret1:"
      echo ${{ steps.get_test_secrets.outputs.json_out }} | jq '.my_secret1' | jq '.items[] | select(.fieldName == "Password") | .itemValue' | jq -r .  
```
