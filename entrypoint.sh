#!/bin/bash

/entrypoint.py "$GITHUB_OUTPUT" "$@"

echo "hello=1" >> "$GITHUB_OUTPUT"

cat -v "$GITHUB_OUTPUT"

exit 0

