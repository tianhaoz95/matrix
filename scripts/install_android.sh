#!/bin/bash

# Matrix Android Installation Script
# This script builds and installs both Matrix HQ and Matrix Agent onto a connected device.

# Exit on error
set -e

# Check if adb is installed
if ! command -v adb &> /dev/null
then
    echo "Error: adb is not installed. Please install Android Platform Tools."
    exit 1
fi

# Check for connected devices
DEVICE_COUNT=$(adb devices | grep -v "List of devices" | grep "device" | wc -l)
if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo "Error: No Android devices connected. Please connect a device or start an emulator."
    exit 1
fi

echo "Found $DEVICE_COUNT device(s) connected."

# Function to build and install a Flutter app
build_and_install() {
    local APP_DIR=$1
    local APP_NAME=$2
    
    echo ""
    echo "=================================================="
    echo " Processing: $APP_NAME"
    echo " Path: $APP_DIR"
    echo "=================================================="
    
    # Navigate to app directory
    pushd "$APP_DIR" > /dev/null
    
    # Get dependencies
    echo "Fetching dependencies for $APP_NAME..."
    flutter pub get
    
    # Build APK
    echo "Building Release APK for $APP_NAME..."
    # Note: Using --split-per-abi can make the install faster if only one architecture is needed,
    # but for a general script, a standard fat APK or universal one is safer.
    flutter build apk --release
    
    # Find the APK
    local APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
    
    if [ ! -f "$APK_PATH" ]; then
        # Fallback to check if it's named differently or in a subfolder (usually it's standard)
        APK_PATH=$(find build/app/outputs/flutter-apk -name "*.apk" | head -n 1)
    fi
    
    if [ -n "$APK_PATH" ] && [ -f "$APK_PATH" ]; then
        echo "Successfully built APK at $APK_PATH"
        echo "Installing $APP_NAME onto device..."
        # -r: replace existing application
        # -d: allow version code downgrade (optional, but useful for dev)
        # -g: grant all runtime permissions
        adb install -r -g "$APK_PATH"
        echo "Done: $APP_NAME is now installed."
    else
        echo "Error: Could not find APK for $APP_NAME"
        exit 1
    fi
    
    popd > /dev/null
}

# Ensure we are running from the project root
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_PATH")"
cd "$PROJECT_ROOT"

# Install HQ
build_and_install "hq" "Matrix Headquarters (HQ)"

# Install Agent
build_and_install "agent" "Matrix Agent Client"

echo ""
echo "=================================================="
echo " All Matrix applications installed successfully!"
echo "=================================================="
