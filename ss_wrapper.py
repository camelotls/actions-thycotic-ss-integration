#!/usr/bin/python3
import os
import sys
import getopt
import requests
import json

from delinea.secrets.server import (
    SecretServer,
    PasswordGrantAuthorizer,
    ServerSecret,
)
from requests import Response


# these default to the env variables but can be overridden by the command line arguments
SS_URL = os.getenv("SS_URL", None)
SS_USERNAME = os.getenv("SS_USERNAME", None)
SS_PASSWORD = os.getenv("SS_PASSWORD", None)
GITHUB_OUTPUT = ""
GET_SECRETS = ""
UPDATE_SECRET_ID = ""
UPDATE_SECRET_FIELD = ""
UPDATE_SECRET_VALUE = ""
DELIMITER = ":"

def _read_args():
    global SS_URL, SS_USERNAME, SS_PASSWORD, GITHUB_OUTPUT
    global GET_SECRETS, UPDATE_SECRET_ID, UPDATE_SECRET_FIELD, UPDATE_SECRET_VALUE, DELIMITER
    long_args = ["gh_out=", "url=", "user=", "pwd=", "get_secrets=",
                 "update_secret_id=", "update_secret_field=", "update_secret_value=", "delimiter="]
    try:
        opts, args = getopt.getopt(sys.argv[1:], "", long_args)
    except getopt.GetoptError as e:
        print(e)
        sys.exit(2)
    for o, a in opts:
        if o == "--url":
            SS_URL = a
        elif o == "--user":
            SS_USERNAME = a
        elif o == "--pwd":
            SS_PASSWORD = a
        elif o == "--gh_out":
            GITHUB_OUTPUT = a
        elif o == "--get_secrets":
            GET_SECRETS = a
        elif o == "--update_secret_id":
            UPDATE_SECRET_ID = a
        elif o == "--update_secret_field":
            UPDATE_SECRET_FIELD = a
        elif o == "--update_secret_value":
            UPDATE_SECRET_VALUE = a
        elif o == "--delimiter":
            DELIMITER = a

def _github_action_update_secret_field():
    if UPDATE_SECRET_VALUE == "":
        print(f"WARNING: updating secret {UPDATE_SECRET_ID} field {UPDATE_SECRET_FIELD} with an empty string")
    if not update_secret_field(UPDATE_SECRET_ID, UPDATE_SECRET_FIELD, UPDATE_SECRET_VALUE):
        print(f"error updating secret {UPDATE_SECRET_ID} field {UPDATE_SECRET_FIELD}")
        sys.exit(1)

def _github_action_get_secrets():
    with open(GITHUB_OUTPUT, "w") as _output:
        for s in GET_SECRETS.split("\n"):
            if s.strip() == "":
                continue
            _res = s.split(DELIMITER)
            if len(_res) == 3:
                _alias, _secret_id, _secret_field = _res
                _value, _msg = get_secret_field(int(_secret_id), _secret_field)
            elif len(_res) == 4:
                _alias, _secret_folder, _secret_name, _secret_field = _res
                _value, _msg = get_secret_field_by_folder_and_name(_secret_folder, _secret_name, _secret_field)
            else:
                print(f"invalid get_secrets entry {s}")
                sys.exit(1)
            if _value is None:
                print(f"Can't retrieve secret with {s}, {_msg}")
                sys.exit(1)
            lines = _value.splitlines()
            if len(lines) == 1:
                print("::add-mask::" + _value.replace("\"", "\\\"").replace("'", "'\\''"))
                _output.write(_alias + "=" + _value.replace("\"", "\\\"").replace("'", "'\\''") + "\n")
            else:
                # multi-line outputs need to be specified in a different format
                # we also need to mask the lines one by one
                _output.write(_alias + "<<EOFEOFEOF\n")
                for l in lines:
                    print("::add-mask::" + l.replace("\"", "\\\"").replace("'", "'\\''"))
                    _output.write(l.replace("\"", "\\\"").replace("'", "'\\''") + "\n")
                _output.write("EOFEOFEOF\n")
            _output.flush()

def _get(uri):
    headers = {
        "Authorization": "Bearer " + token(),
        "Content-Type": "application/json"
    }
    return requests.get(SS_URL + uri, headers=headers)

def _post(uri, payload):
    headers = {
        "Authorization": "Bearer " + token(),
        "Content-Type": "application/json"
    }
    return requests.post(SS_URL + uri, headers=headers, data=payload)

def token():
    return get_access_token()

def get_access_token():
    return AUTHORIZER.get_access_token()

def get_secret_field(secret_id: int, secret_field: str):
    try:
        secret = SECRET_SERVER.get_secret(int(secret_id))
        server_secret = ServerSecret(**secret)

        if secret_field in server_secret.fields:
            value = server_secret.fields[secret_field].value
            if type(value) is str:
                return value, ""
            elif type(value) is Response:
                return value.text, ""
            else:
                return str(value), ""
        else:
            return None, "Unknown field"
    except Exception as e:
        print(f"Error getting secret {secret_id}: {str(e)}")
        return None

def get_secret_field_by_folder_and_name(secret_folder: str, secret_name: str, secret_field: str):
    try:
        res = json.loads(SECRET_SERVER.lookup_folders(query_params={"filter.searchText": secret_folder}))
        if "records" not in res:
            return None, "unexpected secret server response"
        elif len(res["records"]) == 0:
            return None, "no folder matches"
        elif len(res["records"]) > 1:
            return None, "multiple folder matches: " + str(res["records"])
        folder_id = res["records"][0]["id"]

        res = json.loads(SECRET_SERVER.search_secrets(query_params={
            "filter.folderId": folder_id,
            "filter.searchText": secret_name,
            "filter.isExactMatch": True,
            "filter.includeSubFolders": True
        }))
        if "records" not in res:
            return None, "unexpected secret server response"
        elif len(res["records"]) == 0:
            return None, "no secret matches"
        elif len(res["records"]) > 1:
            return None, "multiple secret matches: " + str(res["records"])
        secret_id = res["records"][0]["id"]

        return get_secret_field(secret_id, secret_field)

    except Exception as e:
        print(f"Error getting secret by folder {secret_folder} and name {secret_name}: {str(e)}")
        return None

def get_folders():
    resp = _get("/api/v1/folders/lookup")
    return resp.json() if resp is not None and resp.status_code == 200 else {}

def get_folder_stub():
    resp = _get("/api/v1/folders/stub")
    return resp.json() if resp is not None and resp.status_code == 200 else {}

def get_secret_templates():
    resp = _get("/api/v1/templates")
    return resp.json() if resp is not None and resp.status_code == 200 else {}

def update_secret_field(secret_id, secret_field, secret_value):
    headers = {
        "Authorization": "Bearer " + token(),
        "Content-Type": "application/json"
    }
    payload = {
        "value": secret_value
    }
    url = "{}/api/v1/secrets/{}/fields/{}".format(SS_URL, secret_id, secret_field)
    resp = requests.put(url, headers=headers, json=payload)
    return resp.status_code == 200

def create_folder():
    # existed in the original implementation, it's not used anywhere, and arguably it should not be implemented
    pass

def create_secret():
    # existed in the original implementation, it's not used anywhere, and arguably it should not be implemented
    pass

if __name__ == "__main__":
    _read_args()

if all([SS_URL, SS_USERNAME, SS_PASSWORD]):
    AUTHORIZER = PasswordGrantAuthorizer(SS_URL, SS_USERNAME, SS_PASSWORD)
    SECRET_SERVER = SecretServer(SS_URL, authorizer=AUTHORIZER)
else:
    print("Secret server url, username, and password must be set")
    sys.exit(2)

if GITHUB_OUTPUT != "":
    try:
        if GET_SECRETS != "":
            _github_action_get_secrets()
        if UPDATE_SECRET_ID != "" and UPDATE_SECRET_FIELD != "":
            _github_action_update_secret_field()
    except Exception as _e:
        print(f"Fatal error: {str(_e)}")
        sys.exit(1)
