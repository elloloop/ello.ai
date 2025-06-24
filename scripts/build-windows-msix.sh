#!/bin/bash

# Build Windows MSIX package for ello.AI
# Usage: ./build-windows-msix.sh [--sign]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build/windows/x64/runner/Release"
APP_NAME="ello_ai"
VERSION=$(grep "version:" "$PROJECT_ROOT/pubspec.yaml" | cut -d' ' -f2 | cut -d'+' -f1)

# Parse arguments
SIGN_PACKAGE=false
while [[ $# -gt 0 ]]; do
  case $1 in
    --sign)
      SIGN_PACKAGE=true
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

echo "Building Windows MSIX for ello.AI v$VERSION"

# Ensure the Flutter app is built
if [ ! -f "$BUILD_DIR/$APP_NAME.exe" ]; then
  echo "Executable not found. Building Flutter app..."
  cd "$PROJECT_ROOT"
  flutter build windows --release
fi

# Create MSIX packaging directory
PACKAGE_DIR="$PROJECT_ROOT/build/msix-package"
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"

# Copy built files
echo "Copying application files..."
cp -r "$BUILD_DIR"/* "$PACKAGE_DIR/"

# Create AppxManifest.xml
cat > "$PACKAGE_DIR/AppxManifest.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<Package xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10"
         xmlns:uap="http://schemas.microsoft.com/appx/manifest/uap/windows10"
         xmlns:rescap="http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities">
  <Identity Name="ElloLoop.elloAI"
            Version="$VERSION.0"
            Publisher="CN=ElloLoop"
            ProcessorArchitecture="x64" />
  
  <Properties>
    <DisplayName>ello.AI</DisplayName>
    <PublisherDisplayName>ElloLoop</PublisherDisplayName>
    <Description>A sleek, modern AI chat assistant for every platform.</Description>
    <Logo>Assets\StoreLogo.png</Logo>
  </Properties>
  
  <Dependencies>
    <TargetDeviceFamily Name="Windows.Desktop" MinVersion="10.0.17763.0" MaxVersionTested="10.0.22000.0" />
  </Dependencies>
  
  <Capabilities>
    <Capability Name="internetClient" />
    <rescap:Capability Name="runFullTrust" />
  </Capabilities>
  
  <Applications>
    <Application Id="elloAI" Executable="$APP_NAME.exe" EntryPoint="Windows.FullTrustApplication">
      <uap:VisualElements DisplayName="ello.AI"
                          Description="A sleek, modern AI chat assistant for every platform."
                          BackgroundColor="transparent"
                          Square150x150Logo="Assets\Square150x150Logo.png"
                          Square44x44Logo="Assets\Square44x44Logo.png">
        <uap:DefaultTile Wide310x150Logo="Assets\Wide310x150Logo.png" 
                         Square310x310Logo="Assets\LargeTile.png"
                         Square71x71Logo="Assets\SmallTile.png">
        </uap:DefaultTile>
      </uap:VisualElements>
    </Application>
  </Applications>
</Package>
EOF

# Create Assets directory and placeholder images
ASSETS_DIR="$PACKAGE_DIR/Assets"
mkdir -p "$ASSETS_DIR"

# Create placeholder asset files (these should be replaced with actual icons)
cat > "$ASSETS_DIR/StoreLogo.png" << 'EOF'
# This is a placeholder - replace with actual 50x50 store logo
EOF

cat > "$ASSETS_DIR/Square150x150Logo.png" << 'EOF'
# This is a placeholder - replace with actual 150x150 logo
EOF

cat > "$ASSETS_DIR/Square44x44Logo.png" << 'EOF'
# This is a placeholder - replace with actual 44x44 logo
EOF

cat > "$ASSETS_DIR/Wide310x150Logo.png" << 'EOF'
# This is a placeholder - replace with actual 310x150 logo
EOF

cat > "$ASSETS_DIR/LargeTile.png" << 'EOF'
# This is a placeholder - replace with actual 310x310 logo
EOF

cat > "$ASSETS_DIR/SmallTile.png" << 'EOF'
# This is a placeholder - replace with actual 71x71 logo
EOF

# Build MSIX package
OUTPUT_MSIX="$PROJECT_ROOT/build/ello.AI-$VERSION-windows-x64.msix"
echo "Creating MSIX package: $OUTPUT_MSIX"

# Remove existing MSIX
rm -f "$OUTPUT_MSIX"

# Use makeappx if available (from Windows SDK)
if command -v makeappx &> /dev/null; then
  makeappx pack /d "$PACKAGE_DIR" /p "$OUTPUT_MSIX" /overwrite
elif command -v makeappx.exe &> /dev/null; then
  makeappx.exe pack /d "$PACKAGE_DIR" /p "$OUTPUT_MSIX" /overwrite
else
  echo "Error: makeappx not found. Please install Windows SDK."
  echo "Alternatively, you can use Visual Studio to create the MSIX package."
  exit 1
fi

# Sign the MSIX if requested and certificate is available
if [ "$SIGN_PACKAGE" = true ]; then
  if [ -n "$WINDOWS_CERTIFICATE_PATH" ] && [ -n "$WINDOWS_CERTIFICATE_PASSWORD" ]; then
    echo "Signing MSIX package..."
    if command -v signtool &> /dev/null; then
      signtool sign /f "$WINDOWS_CERTIFICATE_PATH" \
        /p "$WINDOWS_CERTIFICATE_PASSWORD" \
        /fd sha256 \
        /tr http://timestamp.digicert.com \
        /td sha256 \
        "$OUTPUT_MSIX"
    elif command -v signtool.exe &> /dev/null; then
      signtool.exe sign /f "$WINDOWS_CERTIFICATE_PATH" \
        /p "$WINDOWS_CERTIFICATE_PASSWORD" \
        /fd sha256 \
        /tr http://timestamp.digicert.com \
        /td sha256 \
        "$OUTPUT_MSIX"
    else
      echo "Warning: signtool not found. MSIX package is unsigned."
    fi
  else
    echo "Warning: Certificate path or password not provided. MSIX package is unsigned."
  fi
fi

echo "MSIX package created successfully: $OUTPUT_MSIX"
echo "Size: $(du -h "$OUTPUT_MSIX" | cut -f1)"

echo "Build complete!"
echo ""
echo "To install locally (unsigned), run:"
echo "  Add-AppxPackage -Path \"$OUTPUT_MSIX\""
echo ""
echo "Note: You may need to enable sideloading in Windows Settings > Update & Security > For developers"