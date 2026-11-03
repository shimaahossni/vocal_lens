#!/bin/sh

# Fail this script if any subcommand fails.
set -e

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

echo "=== Xcode Cloud: Starting Flutter Post-Clone Setup ==="

# Navigate to the repository root.
# This script lives inside ios/ci_scripts/ so we go two levels up.
REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$REPO_ROOT"
echo "Repository root: $(pwd)"

# Install Flutter SDK using git clone (pinned to 3.22.3 matching project development version)
FLUTTER_DIR="$HOME/flutter"
if [ ! -d "$FLUTTER_DIR" ]; then
    echo "Cloning Flutter 3.22.3..."
    git clone https://github.com/flutter/flutter.git --depth 1 -b 3.22.3 "$FLUTTER_DIR"
else
    echo "Flutter already exists at $FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

echo "Flutter version:"
flutter --version

# Pre-cache iOS engine artifacts
echo "Pre-caching iOS engine artifacts..."
flutter precache --ios

# Fetch Flutter dependencies
echo "Fetching Flutter dependencies..."
flutter pub get

# Generate iOS ephemeral files and build configurations without performing full compile
echo "Generating Flutter iOS build configurations..."
if [ -n "$CI_BUILD_NUMBER" ]; then
    echo "Using Xcode Cloud build number: $CI_BUILD_NUMBER"
    flutter build ios --config-only --no-codesign --build-number="$CI_BUILD_NUMBER"
else
    flutter build ios --config-only --no-codesign
fi

# Ensure CocoaPods is installed
if ! command -v pod > /dev/null 2>&1; then
    echo "CocoaPods not found. Installing via Homebrew..."
    HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods
fi

# Update CocoaPods repo to get latest pod specs (fixes stale MLKit specs)
echo "Updating CocoaPods repo..."
pod repo update --silent || echo "pod repo update failed, continuing..."

# Install iOS CocoaPods dependencies
echo "Installing CocoaPods dependencies..."
cd ios
pod install --repo-update

# Patch MLKit frameworks that are missing a platform load command.
# Xcode 16+ dropped -ld_classic support, so we inject the iOS build version
# directly into the binary with vtool to suppress linker warnings/errors.
echo "Patching MLKit framework platform load commands..."
PODS_DIR="${REPO_ROOT}/ios/Pods"
find "$PODS_DIR" -name "*.framework" -type d | while read FW_PATH; do
    FW_NAME=$(basename "$FW_PATH" .framework)
    BINARY="$FW_PATH/$FW_NAME"
    if [ -f "$BINARY" ]; then
        # Check if it already has a platform load command
        if ! vtool -show-build "$BINARY" 2>/dev/null | grep -q "platform"; then
            echo "  Patching: $FW_NAME"
            # Patch arm64 slice (device)
            vtool -arch arm64 \
                  -set-build-version ios 15.0 15.0 \
                  -replace -output "$BINARY" "$BINARY" 2>/dev/null || true
            # Patch x86_64 slice (simulator) if present
            vtool -arch x86_64 \
                  -set-build-version iossimulator 15.0 15.0 \
                  -replace -output "$BINARY" "$BINARY" 2>/dev/null || true
        fi
    fi
done

echo "=== Xcode Cloud: Flutter Post-Clone Setup Complete ==="
exit 0
