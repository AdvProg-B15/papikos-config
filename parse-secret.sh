#!/bin/bash

# Usage: ./parse-secret <secret-name> <namespace>

eval kubectl get secret $1 -n $2 -o yaml | \
yq -r '.data | to_entries[] | "\(.key)=\(.value | @base64d)"'

