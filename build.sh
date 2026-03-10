#!/bin/bash

# Exit on error
set -e

APP_ARG=$1
VERSION_ARG=$2

APP_NAME=""
APPS_JSON_FILE=""
FRAPPE_BRANCH="version-15" # Default

# Determine App
if [ -n "$APP_ARG" ]; then
    case $APP_ARG in
        crm)
            APP_NAME="crm"
            APPS_JSON_FILE="crm.json"
            FRAPPE_BRANCH="version-16"
            ;;
        *)
            echo "Unknown app: $APP_ARG"
            echo "Supported apps: crm"
            exit 1
            ;;
    esac
else
    echo "Select app to build:"
    echo "1) CRM"
    # Add more options here in the future
    read -p "Enter choice [1]: " choice
    choice=${choice:-1}

    case $choice in
        1)
            APP_NAME="crm"
            APPS_JSON_FILE="crm.json"
            FRAPPE_BRANCH="version-16"
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
fi

# Determine Version
if [ -n "$VERSION_ARG" ]; then
    VERSION="$VERSION_ARG"
else
    read -p "Enter version tag (e.g., v16.10.1-rc1): " VERSION
fi

if [ -z "$VERSION" ]; then
    echo "Version is required. Exiting."
    exit 1
fi

if [ ! -f "$APPS_JSON_FILE" ]; then
    echo "Error: $APPS_JSON_FILE not found."
    exit 1
fi

# Encode apps.json to base64
APPS_JSON_BASE64=$(base64 -w 0 "$APPS_JSON_FILE")

IMAGE_NAME="ghcr.io/aquiveal/${APP_NAME}:${VERSION}"

echo "Building docker image: $IMAGE_NAME"
echo "Using apps file: $APPS_JSON_FILE"
echo "Frappe branch: $FRAPPE_BRANCH"

# Build the image
docker build --no-cache \
  --build-arg=FRAPPE_PATH=https://github.com/frappe/frappe \
  --build-arg=FRAPPE_BRANCH="$FRAPPE_BRANCH" \
  --build-arg=APPS_JSON_BASE64="$APPS_JSON_BASE64" \
  --tag="$IMAGE_NAME" \
  --file=images/layered/Containerfile .

echo "Build complete: $IMAGE_NAME"

echo "Pushing image: $IMAGE_NAME"
docker push "$IMAGE_NAME"
echo "Push complete"
