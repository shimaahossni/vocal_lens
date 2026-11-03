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

# ── Install Flutter SDK ────────────────────────────────────────────────────────
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

# ── Pre-cache iOS engine artifacts ────────────────────────────────────────────
echo "Pre-caching iOS engine artifacts..."
flutter precache --ios

# ── Fetch Flutter dependencies ────────────────────────────────────────────────
echo "Fetching Flutter dependencies..."
flutter pub get

# ── Generate iOS build configurations ─────────────────────────────────────────
echo "Generating Flutter iOS build configurations..."
if [ -n "$CI_BUILD_NUMBER" ]; then
    echo "Using Xcode Cloud build number: $CI_BUILD_NUMBER"
    flutter build ios --config-only --no-codesign --build-number="$CI_BUILD_NUMBER"
else
    flutter build ios --config-only --no-codesign
fi

# Ensure AppFrameworkInfo.plist explicitly specifies MinimumOSVersion (fixes ITMS-90530, ITMS-90360, ITMS-90208)
PLIST_FILE="${REPO_ROOT}/ios/Flutter/AppFrameworkInfo.plist"
if [ -f "$PLIST_FILE" ]; then
    /usr/libexec/PlistBuddy -c "Set :MinimumOSVersion 15.0" "$PLIST_FILE" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :MinimumOSVersion string 15.0" "$PLIST_FILE" 2>/dev/null || true
    echo "Configured MinimumOSVersion 15.0 in $PLIST_FILE"
fi

# ── Ensure CocoaPods is installed ─────────────────────────────────────────────
if ! command -v pod > /dev/null 2>&1; then
    echo "CocoaPods not found. Installing via Homebrew..."
    HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods
fi

# ── Install iOS CocoaPods dependencies ────────────────────────────────────────
# --repo-update ensures fresh pod specs (avoids stale MLKit specs).
# The Podfile post_install hook will also patch MLKit platform load commands.
echo "Installing CocoaPods dependencies..."
cd ios
pod install --repo-update

# ── Patch frameworks missing platform load commands (Xcode 16+ fix) ───────────
# Xcode 16 dropped the -ld_classic linker. The new linker (ld_prime) treats
# "no platform load command" as a hard error for pre-built frameworks like
# MLKitTextRecognitionCommon 3.0.0.
# Strategy:
#   1. Remove existing code signature (vtool invalidates it).
#   2. Inject iOS build-version using xcrun vtool.
#   3. Ad-hoc re-sign so Xcode can read the binary.
#      (Xcode Cloud overwrites this with the distribution cert during archiving.)
echo ""
echo "=== Patching frameworks missing platform load commands ==="
PODS_DIR="${REPO_ROOT}/ios/Pods"
PATCHED=0

if [ -d "$PODS_DIR" ]; then
    # Use a temp file to avoid subshell scoping issues with while+pipe on sh
    TMPFILE=$(mktemp)
    find "$PODS_DIR" -name "*.framework" -type d 2>/dev/null > "$TMPFILE"

    while IFS= read -r FW_PATH; do
        FW_NAME=$(basename "$FW_PATH" .framework)
        BINARY="$FW_PATH/$FW_NAME"

        # Skip if binary doesn't exist or isn't a Mach-O file
        [ -f "$BINARY" ] || continue
        file "$BINARY" 2>/dev/null | grep -q "Mach-O" || continue

        # Check if a platform load command is already present
        if xcrun vtool -show-build "$BINARY" 2>/dev/null | grep -qi "PLATFORM"; then
            continue
        fi

        echo "  Patching: $FW_NAME"

        # Step 1: Remove the existing code signature before modifying the binary
        xcrun codesign --remove-signature "$BINARY" 2>/dev/null || true

        # Step 2: Inject iOS platform version into arm64 slice (physical device)
        xcrun vtool \
            -arch arm64 \
            -set-build-version ios 15.0 15.0 \
            -replace \
            -output "$BINARY" \
            "$BINARY" 2>/dev/null || true

        # Step 3: Ad-hoc re-sign so the binary is valid until Xcode Cloud
        #         replaces it with the distribution certificate during archiving
        xcrun codesign -f -s - "$BINARY" 2>/dev/null || true

        echo "    ✅ Patched: $FW_NAME"
        PATCHED=$((PATCHED + 1))
    done < "$TMPFILE"

    rm -f "$TMPFILE"
    echo "=== Patching complete — $PATCHED framework(s) patched ==="
else
    echo "WARNING: Pods directory not found at $PODS_DIR"
fi

echo ""
echo "=== Xcode Cloud: Flutter Post-Clone Setup Complete ==="
exit 0
