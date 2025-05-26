#!/bin/bash

# Usage: ./manage-secret.sh -n my-secret -ns my-namespace -f .env

# Default values
ENV_FILE=".env"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -n) SECRET_NAME="$2"; shift ;;
        -ns) NAMESPACE="$2"; shift ;;
        -f) ENV_FILE="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Check required args
if [[ -z "$SECRET_NAME" || -z "$NAMESPACE" ]]; then
    echo "Error: --name and --namespace are required."
    exit 1
fi

# Check if env file exists
if [[ ! -f "$ENV_FILE" ]]; then
    echo "Error: .env file not found at $ENV_FILE"
    exit 1
fi

# Delete the existing secret
echo "Deleting secret $SECRET_NAME in namespace $NAMESPACE..."
kubectl delete secret "$SECRET_NAME" -n "$NAMESPACE" --ignore-not-found

# Build --from-literal args from env file
FROM_LITERALS=""
while IFS='=' read -r key value || [[ -n "$key" ]]; do
    # Skip empty lines or comments
    [[ -z "$key" || "$key" == \#* ]] && continue
    FROM_LITERALS+="--from-literal=${key}=${value} "
done < "$ENV_FILE"

# Create the new secret
echo "Creating secret $SECRET_NAME in namespace $NAMESPACE..."
eval kubectl create secret generic "$SECRET_NAME" $FROM_LITERALS -n "$NAMESPACE"

