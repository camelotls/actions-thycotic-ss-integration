#!/bin/bash

echo "Query SS"

/entrypoint.py "$1" "$2" "$3" "$4" "$5" >> "$GITHUB_OUTPUT"

cat "$GITHUB_OUTPUT"
