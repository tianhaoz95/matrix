#!/bin/bash

# Script to launch local Appwrite instance for Matrix development

# Use physical path to avoid symlink issues with Docker mounts
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
APPWRITE_DIR="$PROJECT_ROOT/appwrite"

# Automatically detect the Docker socket path from the active context
DOCKER_SOCKET=$(docker context inspect --format '{{.Endpoints.docker.Host}}' | sed 's|unix://||')

# Fallback if detection fails or is non-unix
if [ -z "$DOCKER_SOCKET" ] || [[ "$DOCKER_SOCKET" != /* ]]; then
    DOCKER_SOCKET="/var/run/docker.sock"
fi

echo "Using Docker socket: $DOCKER_SOCKET"

if [ ! -f "$APPWRITE_DIR/docker-compose.yml" ]; then
    echo "--------------------------------------------------------"
    echo "Appwrite configuration not found in $APPWRITE_DIR."
    echo "Starting the official Appwrite installer..."
    echo "--------------------------------------------------------"
    
    mkdir -p "$APPWRITE_DIR"
    
    docker run -it --rm \
        --volume "$DOCKER_SOCKET":/var/run/docker.sock \
        --volume "$APPWRITE_DIR":/usr/src/code/appwrite:rw \
        --entrypoint="install" \
        appwrite/appwrite:latest
else
    echo "Appwrite installation found in $APPWRITE_DIR. Launching services..."
    cd "$APPWRITE_DIR" && docker compose up -d
    echo "--------------------------------------------------------"
    echo "Appwrite is running!"
    echo "Console: http://localhost"
    echo "Endpoint: http://localhost/v1"
    echo "--------------------------------------------------------"
fi
