#!/bin/bash
set -e
/ss_wrapper.py --gh_out "$GITHUB_OUTPUT" --url "$1" --user "$2" --pwd "$3" --get_secrets "$4"
exit 0
