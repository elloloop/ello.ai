#!/bin/bash

# Desktop MVP Build Script for ello.AI
# This script helps build the Flutter desktop app for different platforms

set -e

echo "🚀 ello.AI Desktop MVP Build Script"
echo "=================================="

# Check if flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    echo "Please install Flutter: https://docs.flutter.dev/get-started/install"
    exit 1
fi

# Check Flutter version
echo "📋 Checking Flutter version..."
flutter --version

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Generate protobuf files if needed
if [ -d "protos" ]; then
    echo "🔧 Checking protobuf generation..."
    if command -v protoc &> /dev/null && command -v dart &> /dev/null; then
        echo "Generating protobuf files..."
        flutter packages pub run build_runner build
    else
        echo "⚠️  protoc or dart not found. Assuming protobuf files are already generated."
    fi
fi

# Run tests
echo "🧪 Running tests..."
flutter test

# Analyze code
echo "🔍 Analyzing code..."
flutter analyze

# Build for specified platform or all platforms
PLATFORM=${1:-"all"}

build_linux() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "🐧 Building for Linux..."
        flutter build linux --release
        echo "✅ Linux build completed: build/linux/x64/release/bundle/"
    else
        echo "⚠️  Linux build requires a Linux host"
    fi
}

build_windows() {
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        echo "🪟 Building for Windows..."
        flutter build windows --release
        echo "✅ Windows build completed: build/windows/runner/Release/"
    else
        echo "⚠️  Windows build requires a Windows host"
    fi
}

build_macos() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "🍎 Building for macOS..."
        flutter build macos --release
        echo "✅ macOS build completed: build/macos/Build/Products/Release/"
    else
        echo "⚠️  macOS build requires a macOS host"
    fi
}

case $PLATFORM in
    "linux")
        build_linux
        ;;
    "windows")
        build_windows
        ;;
    "macos")
        build_macos
        ;;
    "all")
        echo "🏗️  Building for all available platforms on this host..."
        build_linux
        build_windows
        build_macos
        ;;
    *)
        echo "❌ Unknown platform: $PLATFORM"
        echo "Usage: $0 [linux|windows|macos|all]"
        exit 1
        ;;
esac

echo ""
echo "🎉 Desktop MVP build process completed!"
echo ""
echo "📁 Build artifacts:"
echo "   Linux:   build/linux/x64/release/bundle/"
echo "   Windows: build/windows/runner/Release/"
echo "   macOS:   build/macos/Build/Products/Release/"
echo ""
echo "🚀 Your Flutter Desktop MVP is ready to run!"