#!/bin/bash

# Build Linux AppImage for ello.AI
# Usage: ./build-linux-appimage.sh [--sign]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build/linux/x64/release/bundle"
APP_NAME="ello_ai"
VERSION=$(grep "version:" "$PROJECT_ROOT/pubspec.yaml" | cut -d' ' -f2 | cut -d'+' -f1)

# Parse arguments
SIGN_APPIMAGE=false
while [[ $# -gt 0 ]]; do
  case $1 in
    --sign)
      SIGN_APPIMAGE=true
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

echo "Building Linux AppImage for ello.AI v$VERSION"

# Ensure the Flutter app is built
if [ ! -f "$BUILD_DIR/$APP_NAME" ]; then
  echo "Executable not found. Building Flutter app..."
  cd "$PROJECT_ROOT"
  flutter build linux --release
fi

# Create AppDir structure
APPDIR="$PROJECT_ROOT/build/ello.AI.AppDir"
rm -rf "$APPDIR"
mkdir -p "$APPDIR"

# Copy built files
echo "Copying application files..."
cp -r "$BUILD_DIR"/* "$APPDIR/"

# Create usr structure for AppImage
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/lib"
mkdir -p "$APPDIR/usr/share/applications"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$APPDIR/usr/share/pixmaps"

# Move executable to usr/bin
mv "$APPDIR/$APP_NAME" "$APPDIR/usr/bin/"

# Move libraries to usr/lib if they exist
if [ -d "$APPDIR/lib" ]; then
  mv "$APPDIR/lib"/* "$APPDIR/usr/lib/" 2>/dev/null || true
  rmdir "$APPDIR/lib" 2>/dev/null || true
fi

# Create desktop file
cat > "$APPDIR/ello.AI.desktop" << EOF
[Desktop Entry]
Type=Application
Name=ello.AI
Comment=A sleek, modern AI chat assistant for every platform
Exec=ello_ai
Icon=ello_ai
Categories=Office;Utility;Chat;
Terminal=false
StartupWMClass=ello_ai
StartupNotify=true
EOF

# Copy desktop file to usr/share/applications
cp "$APPDIR/ello.AI.desktop" "$APPDIR/usr/share/applications/"

# Create AppRun script
cat > "$APPDIR/AppRun" << 'EOF'
#!/bin/bash

# AppRun script for ello.AI AppImage

HERE="$(dirname "$(readlink -f "${0}")")"

# Set up environment
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"
export PATH="${HERE}/usr/bin:${PATH}"

# Set up Flutter environment
export FLUTTER_ROOT="${HERE}/usr/lib/flutter"
export XDG_DATA_DIRS="${HERE}/usr/share:${XDG_DATA_DIRS}"

# Run the application
exec "${HERE}/usr/bin/ello_ai" "$@"
EOF

chmod +x "$APPDIR/AppRun"

# Create icon (placeholder - should be replaced with actual icon)
cat > "$APPDIR/ello_ai.png" << 'EOF'
# This is a placeholder - replace with actual 256x256 PNG icon
EOF

# Copy icon to appropriate locations
cp "$APPDIR/ello_ai.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/"
cp "$APPDIR/ello_ai.png" "$APPDIR/usr/share/pixmaps/"

# Create .DirIcon (used by some file managers)
cp "$APPDIR/ello_ai.png" "$APPDIR/.DirIcon"

# Download appimagetool if not present
APPIMAGETOOL="$PROJECT_ROOT/build/appimagetool-x86_64.AppImage"
if [ ! -f "$APPIMAGETOOL" ]; then
  echo "Downloading appimagetool..."
  wget -c "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" \
    -O "$APPIMAGETOOL"
  chmod +x "$APPIMAGETOOL"
fi

# Build AppImage
OUTPUT_APPIMAGE="$PROJECT_ROOT/build/ello.AI-$VERSION-linux-x86_64.AppImage"
echo "Creating AppImage: $OUTPUT_APPIMAGE"

# Remove existing AppImage
rm -f "$OUTPUT_APPIMAGE"

# Set ARCH environment variable for appimagetool
export ARCH=x86_64

# Create AppImage
"$APPIMAGETOOL" "$APPDIR" "$OUTPUT_APPIMAGE"

# Make AppImage executable
chmod +x "$OUTPUT_APPIMAGE"

# Sign the AppImage if requested and GPG key is available
if [ "$SIGN_APPIMAGE" = true ]; then
  if command -v gpg &> /dev/null && [ -n "$GPG_PRIVATE_KEY" ]; then
    echo "Signing AppImage with GPG..."
    
    # Import GPG key if provided as base64
    if [ -n "$GPG_PRIVATE_KEY" ]; then
      echo "$GPG_PRIVATE_KEY" | base64 -d | gpg --import --batch --yes
    fi
    
    # Create detached signature
    gpg --armor --detach-sig --batch --yes \
      ${GPG_PASSPHRASE:+--pinentry-mode loopback --passphrase "$GPG_PASSPHRASE"} \
      "$OUTPUT_APPIMAGE"
    
    echo "Signature created: $OUTPUT_APPIMAGE.asc"
  else
    echo "Warning: GPG not available or GPG_PRIVATE_KEY not set. AppImage is unsigned."
  fi
fi

# Cleanup
rm -rf "$APPDIR"

echo "AppImage created successfully: $OUTPUT_APPIMAGE"
echo "Size: $(du -h "$OUTPUT_APPIMAGE" | cut -f1)"

# Verify AppImage
echo "Verifying AppImage..."
if "$OUTPUT_APPIMAGE" --appimage-help &> /dev/null; then
  echo "AppImage verification successful"
else
  echo "Warning: AppImage verification failed"
fi

echo "Build complete!"
echo ""
echo "To test the AppImage:"
echo "  chmod +x \"$OUTPUT_APPIMAGE\""
echo "  \"$OUTPUT_APPIMAGE\""
echo ""
echo "To extract and inspect:"
echo "  \"$OUTPUT_APPIMAGE\" --appimage-extract"