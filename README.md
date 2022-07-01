# Thycotic Secret Server docker action

This action is a wrapper against Thycotic Secret Server API.

## Inputs

## `json_in`

**Required** Thycotic Secret Server input params.

## Outputs

## `json_out`

Thycotic Secret Server json response.

## API documentation
Please refer to the Thycotic Secret Server API before using this action.

## Example usage
```yaml
  - name: Get secret field
    id: get_secret_field
    uses: camelotls/actions-thycotic-ss-integration@v1
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
    uses: camelotls/actions-thycotic-ss-integration@v1
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
    uses: camelotls/actions-thycotic-ss-integration@v1
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
```