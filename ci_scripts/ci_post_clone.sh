#!/bin/sh

# Fail this script if any subcommand fails.
set -e

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

echo "=== Xcode Cloud: Starting Flutter Post-Clone Setup ==="

# Navigate to the repository root.
# $CI_PRIMARY_REPOSITORY_PATH is provided by Xcode Cloud.
REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/.." && pwd)}"
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
flutter build ios --config-only --no-codesign

# Ensure CocoaPods is installed
if ! command -v pod > /dev/null 2>&1; then
    echo "CocoaPods not found. Installing via Homebrew..."
    HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods
fi

# Install iOS CocoaPods dependencies
echo "Installing CocoaPods dependencies..."
cd ios
pod install

echo "=== Xcode Cloud: Flutter Post-Clone Setup Complete ==="
exit 0
