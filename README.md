# Thycotic (Delinea) Secret Server docker action

This action is a wrapper against Thycotic (Delinea) Secret Server API for retrieving secret values.

## Inputs

### url
**Required**; the url of the secret server e.g. `https://ORG.secretservercloud.eu`

### username
**Required**; username for authenticating to the secret server

### password
**Required**; password for authenticating to the secret server

### get_secrets

A new-line-separated list of secrets in one of the below formats

```text
<ALIAS>:<SECRET_ID>:<SECRET_FIELD>
```
```text
<ALIAS>:<SECRET_FOLDER>:<SECRET_NAME:<SECRET_FIELD>
```

In all cases, the user whose credentials are used to authenticate to the Secret Server
must have access to the requested keys.
<br>
Aliases **must be unique** as they form the action's outputs and can be used by subsequent workflow steps.

Example:

```yaml
get_secrets: |-
    DATABASE_PASSWORD:12345:password
    DATABASE_USERNAME:12345:username
    APP_SERVER_SSH_KEY:67890:private-key
    CANARY_PASSWORD:cartoon_character_credentials:tweety:password
```

the above example retrieves:
- two separate fields from the same secret
- the contents of a private key file stored as an attachment
- a password for a secret using a folder and secret name lookup instead of the secret ID

```text
{{ steps.my_action_id.outputs.DATABASE_PASSWORD }}
```

`get_secrets` is compatible with single-line fields, multi-line fields, and files/attachments alike.

### delimiter

The above example is using the default delimiter `:` for the fields of each get_secrets line.<br>
If required, the `delimiter` parameter can be used to provide an alternative delimiter.
For example, this could be needed if the default delimiter `:` appears in secret names.
**NB** No matter the choice of delimiter, care must be taken so the chosen one is used consistently
across all `get_secrets` lines.

```yaml
get_secrets: |-
    DATABASE_PASSWORD:;:12345:;:password
    DATABASE_USERNAME:;:12345:;:username
delimiter: ":;:"
```

### update_secret_id

Secret id to update.<br>
An update will take place only if `update_secrete_field` is provided as well.

### update_secret_field

The field of the secret to update.

### update_secret_value

Value to set the field to.<br>
**NB** It is possible for the value of the field to be cleared if the secret template allows this.


## Outputs

The action does not contain predefined output identifiers.
The outputs are produced based on the chosen aliases (see Example Usage)

## Example Usage

```yaml
steps:
  - name: "Get secrets from the secret server"
    id: secrets
    uses: camelotls/actions-thycotic-ss-integration@v8
    with:
      url: https://ORG.secretservercloud.eu
      username: ${{ secrets.SECRET_SERVER_USERNAME }}
      password: ${{ secrets.SECRET_SERVER_PASSWORD }}
      get_secrets: |
        PROD_API_KEY::123::password
        DB_PASSWORD::456::password
        SSH_KEY::789::private-key
        PROD_ENCRYPTION_KEY::production_credentials::encryption_key::apikey
      delimiter: "::"
  - name: "Setup ssh-agent"
    uses: webfactory/ssh-agent@v0.9.0
    with:
      ssh-private-key: ${{ steps.secrets.outputs.SSH_KEY }}
  - name: "Connect to the database"
    run: |
      db_connect \
        --username ${{ vars.DB_USERNAME }} \
        --password ${{ steps.secrets.outputs.DB_PASSWORD }}
  - name: "Deploy production application server"
    run: |
      deploy \
        --api_key ${{ steps.secrets.outputs.PROD_API_KEY }} \
        --enc_key ${{ steps.secrets.outputs.PROD_ENCRYPTION_KEY }}
  - name: "Update database password"
    uses: camelotls/actions-thycotic-ss-integration@v8
    with:
      url: https://ORG.secretservercloud.eu
      username: ${{ secrets.SECRET_SERVER_USERNAME }}
      password: ${{ secrets.SECRET_SERVER_PASSWORD }}
      update_secret_id: 456
      update_secret_field: password
      update_secret_value: H0pefullyAg00d0n3!
```
