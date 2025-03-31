#!/bin/bash
set -e
/ss_wrapper.py --gh_out "$GITHUB_OUTPUT" --url "$1" --user "$2" --pwd "$3" --get_secrets "$4" \
  --update_secret_id "$5" --update_secret_field "$6" --update_secret_value "$7" --delimiter "$8"
exit 0
