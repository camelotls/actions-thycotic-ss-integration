#!/usr/bin/python3

import sys
from delinea.secrets.server import (
    SecretServer,
    PasswordGrantAuthorizer,
    ServerSecret,
)
from requests import Response

# url, username, password are required
if len(sys.argv) < 4:
    print("incorrect arguments; url, username, and password must be set")
    sys.exit(1)

OUTPUT = sys.argv[1]
URL = sys.argv[2]
USERNAME = sys.argv[3]
PASSWORD = sys.argv[4]
GET_SECRETS = sys.argv[5:12]

def get_secret_field(secret_id: int, secret_field: str):
    try:
        secret_server = SecretServer(URL, authorizer=AUTHORIZER)
        secret = secret_server.get_secret(int(secret_id))
        server_secret = ServerSecret(**secret)

        if secret_field in server_secret.fields:
            value = server_secret.fields[secret_field].value
            if type(value) is str:
                return value
            elif type(value) is Response:
                return value.text
            else:
                return str(value)
        else:
            print(f"Unknown field {secret_field} for secret {secret_id}")
            return None
    except Exception as e:
        print(f"Error fetching secret {secret_id}: {str(e)}")
        return None

try:
    AUTHORIZER = PasswordGrantAuthorizer(URL, USERNAME, PASSWORD)
    with open(OUTPUT, "w") as _output:
        for index, s in enumerate(GET_SECRETS):
            if s.strip() == "":
                continue
            _res = s.split("/")
            if len(_res) != 2:
                print(f"invalid get_secret argument {s}")
                sys.exit(1)
            _secret_id, _secret_field = _res
            _fs = get_secret_field(int(_res[0]), _res[1])
            if _fs is None:
                print(f"Can't retrieve {s}")
                sys.exit(1)
            if _fs is not None:
                # use repr to keep newlines
                _output.write("ss_field_" + str(index + 1) + "=::add-mask::" + _fs + "\n")
                _output.flush()

except Exception as _e:
    print(f"Fatal error: {str(_e)}")
    sys.exit(1)