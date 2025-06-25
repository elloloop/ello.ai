#!/bin/bash

# Desktop Build Testing Script
# Tests Flutter desktop builds on all target platforms for release verification

set -e  # Exit on any error

echo "🖥️  Testing Flutter Desktop Builds"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed. Please install Flutter first."
    exit 1
fi

print_status "Flutter version:"
flutter --version | head -1

echo ""
print_status "Preparing dependencies..."
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

echo ""
print_status "=== Testing Desktop Platform Builds ==="

# Test Linux build
echo ""
print_status "🐧 Testing Linux desktop build..."
if flutter build linux --release --no-pub > /dev/null 2>&1; then
    print_success "Linux desktop build successful"
    if [ -d "build/linux/x64/release/bundle" ]; then
        BUILD_SIZE=$(du -sh build/linux/x64/release/bundle | cut -f1)
        print_status "Build artifact: build/linux/x64/release/bundle (${BUILD_SIZE})"
    fi
else
    print_error "Linux desktop build failed"
    echo "Run 'flutter build linux --release' for detailed error information"
fi

# Test Windows build (if on Windows or with Windows toolchain)
echo ""
print_status "🪟 Testing Windows desktop build..."
if flutter build windows --release --no-pub > /dev/null 2>&1; then
    print_success "Windows desktop build successful"
    if [ -d "build/windows/runner/Release" ]; then
        BUILD_SIZE=$(du -sh build/windows/runner/Release | cut -f1)
        print_status "Build artifact: build/windows/runner/Release (${BUILD_SIZE})"
    fi
else
    print_warning "Windows desktop build failed (this is expected on non-Windows platforms)"
    print_status "To test Windows builds, run on Windows with Visual Studio installed:"
    print_status "  flutter build windows --release"
fi

# Test macOS build (if on macOS)
echo ""
print_status "🍎 Testing macOS desktop build..."
if flutter build macos --release --no-pub > /dev/null 2>&1; then
    print_success "macOS desktop build successful"
    if [ -d "build/macos/Build/Products/Release" ]; then
        print_status "Build artifact: build/macos/Build/Products/Release/ello_ai.app"
        if [ -d "build/macos/Build/Products/Release/ello_ai.app" ]; then
            BUILD_SIZE=$(du -sh build/macos/Build/Products/Release/ello_ai.app | cut -f1)
            print_status "App bundle size: ${BUILD_SIZE}"
        fi
    fi
else
    print_warning "macOS desktop build failed (this is expected on non-macOS platforms)"
    print_status "To test macOS builds, run on macOS with Xcode installed:"
    print_status "  flutter build macos --release"
fi

echo ""
print_status "=== Additional Platform Builds ==="

# Test Web build for completeness
echo ""
print_status "🌐 Testing web build..."
if flutter build web --release --no-pub > /dev/null 2>&1; then
    print_success "Web build successful"
    if [ -d "build/web" ]; then
        BUILD_SIZE=$(du -sh build/web | cut -f1)
        print_status "Build artifact: build/web (${BUILD_SIZE})"
    fi
else
    print_error "Web build failed"
fi

echo ""
print_status "=== Build Summary ==="
echo ""

# Check for build artifacts
artifacts_found=0

if [ -d "build/linux/x64/release/bundle" ]; then
    print_success "✅ Linux desktop build available"
    artifacts_found=$((artifacts_found + 1))
fi

if [ -d "build/windows/runner/Release" ]; then
    print_success "✅ Windows desktop build available"
    artifacts_found=$((artifacts_found + 1))
else
    print_status "⚠️  Windows desktop build not available (requires Windows platform)"
fi

if [ -d "build/macos/Build/Products/Release/ello_ai.app" ]; then
    print_success "✅ macOS desktop build available"
    artifacts_found=$((artifacts_found + 1))
else
    print_status "⚠️  macOS desktop build not available (requires macOS platform)"
fi

if [ -d "build/web" ]; then
    print_success "✅ Web build available"
    artifacts_found=$((artifacts_found + 1))
fi

echo ""
if [ $artifacts_found -gt 0 ]; then
    print_success "🎉 Desktop build testing completed successfully!"
    print_status "Found $artifacts_found build artifact(s) ready for distribution"
    echo ""
    print_status "📋 Platform-specific build instructions:"
    echo ""
    echo "  🐧 Linux:   flutter build linux --release"
    echo "  🪟 Windows: flutter build windows --release  (requires Windows + VS)"
    echo "  🍎 macOS:   flutter build macos --release    (requires macOS + Xcode)"
    echo "  🌐 Web:     flutter build web --release"
    echo ""
    print_status "For complete cross-platform testing, run this script on each target platform."
else
    print_warning "No build artifacts found. Check Flutter installation and platform requirements."
fi

echo ""
print_status "Desktop build testing complete!"