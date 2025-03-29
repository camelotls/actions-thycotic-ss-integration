#!/bin/bash

echo "Query SS"

res=$(/entrypoint.py "$1" "$2" "$3" "$4" "$5")

echo "$res" >> "$GITHUB_ENV"
