#!/bin/bash

# ello.AI Desktop MVP Launcher Script
# This script helps launch the ello.AI desktop app with appropriate settings

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🤖 ello.AI Desktop MVP${NC}"
echo -e "${BLUE}=====================${NC}"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed or not in PATH${NC}"
    echo "Please install Flutter: https://docs.flutter.dev/get-started/install"
    exit 1
fi

# Check Flutter project
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Not in a Flutter project directory${NC}"
    echo "Please run this script from the ello.ai root directory"
    exit 1
fi

# Get dependencies if needed
if [ ! -d ".dart_tool" ]; then
    echo -e "${YELLOW}📦 Installing dependencies...${NC}"
    flutter pub get
fi

# Determine platform
PLATFORM=""
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    PLATFORM="windows"
else
    echo -e "${RED}❌ Unsupported platform: $OSTYPE${NC}"
    exit 1
fi

echo -e "${GREEN}🖥️  Detected platform: $PLATFORM${NC}"

# Check if we should run in debug or release mode
MODE=${1:-"debug"}

if [ "$MODE" = "debug" ]; then
    echo -e "${YELLOW}🐛 Launching in debug mode...${NC}"
    echo "Features available:"
    echo "  • Debug settings panel"
    echo "  • Hot reload"
    echo "  • Mock MCP server mode"
    echo "  • Connection testing tools"
    echo ""
    echo -e "${BLUE}Starting ello.AI...${NC}"
    flutter run -d $PLATFORM
elif [ "$MODE" = "release" ]; then
    echo -e "${GREEN}🚀 Launching in release mode...${NC}"
    
    # Check if release build exists
    RELEASE_DIR=""
    case $PLATFORM in
        "linux")
            RELEASE_DIR="build/linux/x64/release/bundle"
            ;;
        "windows")
            RELEASE_DIR="build/windows/runner/Release"
            ;;
        "macos")
            RELEASE_DIR="build/macos/Build/Products/Release"
            ;;
    esac
    
    if [ ! -d "$RELEASE_DIR" ]; then
        echo -e "${YELLOW}📦 Release build not found. Building...${NC}"
        flutter build $PLATFORM --release
    fi
    
    echo -e "${BLUE}Starting ello.AI (Release)...${NC}"
    flutter run -d $PLATFORM --release
else
    echo -e "${RED}❌ Invalid mode: $MODE${NC}"
    echo "Usage: $0 [debug|release]"
    exit 1
fi