#!/bin/bash

/entrypoint.py "$@" >> "$GITHUB_OUTPUT"

cat "$GITHUB_OUTPUT"

exit 0
