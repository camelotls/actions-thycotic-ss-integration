#!/bin/bash

echo "Query SS"

/entrypoint.py "$@" >> "$GITHUB_OUTPUT"
