#!/bin/bash

# Build macOS DMG package for ello.AI
# Usage: ./build-macos-dmg.sh [--sign "Developer ID"]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build/macos/Build/Products/Release"
APP_NAME="ello_ai"
DMG_NAME="ello.AI"
VERSION=$(grep "version:" "$PROJECT_ROOT/pubspec.yaml" | cut -d' ' -f2 | cut -d'+' -f1)

# Parse arguments
SIGN_IDENTITY=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --sign)
      SIGN_IDENTITY="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

echo "Building macOS DMG for ello.AI v$VERSION"

# Ensure the Flutter app is built
if [ ! -d "$BUILD_DIR/$APP_NAME.app" ]; then
  echo "App bundle not found. Building Flutter app..."
  cd "$PROJECT_ROOT"
  flutter build macos --release
fi

# Create temporary DMG directory
TEMP_DIR=$(mktemp -d)
DMG_TEMP_DIR="$TEMP_DIR/$DMG_NAME"
mkdir -p "$DMG_TEMP_DIR"

# Copy app bundle
cp -R "$BUILD_DIR/$APP_NAME.app" "$DMG_TEMP_DIR/ello.AI.app"

# Create Applications symlink
ln -s /Applications "$DMG_TEMP_DIR/Applications"

# Sign the app if identity provided
if [ -n "$SIGN_IDENTITY" ]; then
  echo "Signing app bundle with identity: $SIGN_IDENTITY"
  codesign --force --deep --sign "$SIGN_IDENTITY" \
    --options runtime \
    "$DMG_TEMP_DIR/ello.AI.app"
  
  # Verify signature
  codesign --verify --verbose "$DMG_TEMP_DIR/ello.AI.app"
  spctl --assess --verbose "$DMG_TEMP_DIR/ello.AI.app"
fi

# Create DMG
OUTPUT_DMG="$PROJECT_ROOT/build/ello.AI-$VERSION-macos-universal.dmg"
echo "Creating DMG: $OUTPUT_DMG"

# Remove existing DMG
rm -f "$OUTPUT_DMG"

# Check if create-dmg is available
if command -v create-dmg &> /dev/null; then
  # Use create-dmg for better DMG creation
  create-dmg \
    --volname "ello.AI" \
    --volicon "$PROJECT_ROOT/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png" \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "ello.AI.app" 150 200 \
    --app-drop-link 450 200 \
    --hdiutil-quiet \
    "$OUTPUT_DMG" \
    "$DMG_TEMP_DIR"
else
  # Fallback to hdiutil
  echo "create-dmg not found, using hdiutil..."
  hdiutil create -volname "ello.AI" \
    -srcfolder "$DMG_TEMP_DIR" \
    -ov -format UDZO \
    "$OUTPUT_DMG"
fi

# Sign the DMG if identity provided
if [ -n "$SIGN_IDENTITY" ]; then
  echo "Signing DMG..."
  codesign --force --sign "$SIGN_IDENTITY" "$OUTPUT_DMG"
  
  # Notarize if credentials are available
  if [ -n "$APPLE_ID_EMAIL" ] && [ -n "$APPLE_ID_PASSWORD" ] && [ -n "$APPLE_TEAM_ID" ]; then
    echo "Submitting for notarization..."
    xcrun notarytool submit "$OUTPUT_DMG" \
      --apple-id "$APPLE_ID_EMAIL" \
      --password "$APPLE_ID_PASSWORD" \
      --team-id "$APPLE_TEAM_ID" \
      --wait
    
    echo "Stapling notarization..."
    xcrun stapler staple "$OUTPUT_DMG"
  fi
fi

# Cleanup
rm -rf "$TEMP_DIR"

echo "DMG created successfully: $OUTPUT_DMG"
echo "Size: $(du -h "$OUTPUT_DMG" | cut -f1)"

# Verify DMG
echo "Verifying DMG..."
hdiutil verify "$OUTPUT_DMG"

echo "Build complete!"