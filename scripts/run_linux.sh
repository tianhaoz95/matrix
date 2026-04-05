#!/bin/bash

# Matrix Linux Run Script
# Usage: ./scripts/run_linux.sh [hq|agent] [local|production]

# Exit on error
set -e

APP_TYPE=$1
ENV_TYPE=${2:-local}

if [[ "$APP_TYPE" != "hq" && "$APP_TYPE" != "agent" ]]; then
    echo "Error: Invalid app type. Use 'hq' or 'agent'."
    echo "Usage: ./scripts/run_linux.sh [hq|agent] [local|production]"
    exit 1
fi

if [[ "$ENV_TYPE" != "local" && "$ENV_TYPE" != "production" ]]; then
    echo "Error: Invalid environment type. Use 'local' or 'production'."
    exit 1
fi

# Ensure we are running from the project root
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_PATH")"
cd "$PROJECT_ROOT"

# Setup environment file
if [ -f ".env.$ENV_TYPE" ]; then
    echo "Using .env.$ENV_TYPE configuration..."
    ENV_FILE=".env.$ENV_TYPE"
else
    echo "Warning: .env.$ENV_TYPE not found. Using root .env file."
    ENV_FILE=".env"
fi

echo "Starting Matrix ${APP_TYPE^^} ($ENV_TYPE) on Linux..."

cd "$APP_TYPE"
flutter run -d linux --dart-define-from-file="../$ENV_FILE"
