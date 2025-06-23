#!/bin/bash

# Verify Pipeline Configuration Script
# This script helps verify that the CI/CD pipeline is properly configured

set -e

echo "🔍 Verifying Pipeline Configuration..."
echo "======================================"

# Check if we're in the right directory
if [ ! -f ".github/workflows/pr-checks.yml" ]; then
    echo "❌ Error: Not in the repository root or missing workflow file"
    exit 1
fi

echo "✅ Found workflow file: .github/workflows/pr-checks.yml"

# Check for CODEOWNERS file
if [ -f "CODEOWNERS" ]; then
    echo "✅ Found CODEOWNERS file"
else
    echo "⚠️  Warning: CODEOWNERS file not found"
fi

# Check Flutter configuration
echo ""
echo "🔧 Checking Flutter Configuration..."
if command -v flutter &> /dev/null; then
    echo "✅ Flutter is installed"
    flutter --version | head -1
    
    # Check if we can run basic Flutter commands
    if [ -f "pubspec.yaml" ]; then
        echo "✅ Found pubspec.yaml"
        echo "📦 Getting Flutter dependencies..."
        flutter pub get > /dev/null 2>&1
        echo "✅ Flutter dependencies installed"
    else
        echo "❌ Error: pubspec.yaml not found"
        exit 1
    fi
else
    echo "❌ Error: Flutter not installed or not in PATH"
    exit 1
fi

# Check Go configuration
echo ""
echo "🔧 Checking Go Configuration..."
if command -v go &> /dev/null; then
    echo "✅ Go is installed"
    go version
    
    if [ -f "server/go.mod" ]; then
        echo "✅ Found server/go.mod"
        echo "📦 Getting Go dependencies..."
        cd server
        go mod download > /dev/null 2>&1
        echo "✅ Go dependencies installed"
        cd ..
    else
        echo "⚠️  Warning: server/go.mod not found"
    fi
else
    echo "❌ Error: Go not installed or not in PATH"
    exit 1
fi

# Check for protobuf files
echo ""
echo "🔧 Checking Protobuf Configuration..."
if [ -d "protos" ]; then
    echo "✅ Found protos directory"
    if [ -f "protos/chat.proto" ]; then
        echo "✅ Found chat.proto"
    fi
    if [ -f "protos/llm_gateway/llm_service.proto" ]; then
        echo "✅ Found llm_service.proto"
    fi
else
    echo "⚠️  Warning: protos directory not found"
fi

# Check if we can run the pipeline steps locally
echo ""
echo "🧪 Testing Pipeline Steps Locally..."

# Test Flutter analyze
echo "📱 Testing Flutter analyze..."
if flutter analyze --fatal-infos --fatal-warnings > /dev/null 2>&1; then
    echo "✅ Flutter analyze passed"
else
    echo "⚠️  Warning: Flutter analyze found issues (run 'flutter analyze' for details)"
fi

# Test Flutter format
echo "🎨 Testing Flutter format..."
if dart format --set-exit-if-changed . > /dev/null 2>&1; then
    echo "✅ Flutter format check passed"
else
    echo "⚠️  Warning: Flutter format issues found (run 'dart format .' to fix)"
fi

# Test Go format
echo "🔧 Testing Go format..."
cd server
if [ "$(gofmt -s -l . | wc -l)" -eq 0 ]; then
    echo "✅ Go format check passed"
else
    echo "⚠️  Warning: Go format issues found (run 'gofmt -s -w .' to fix)"
fi
cd ..

# Test builds
echo ""
echo "🏗️  Testing Builds..."

# Test Flutter web build
echo "🌐 Testing Flutter web build..."
if flutter build web --no-pub > /dev/null 2>&1; then
    echo "✅ Flutter web build passed"
else
    echo "❌ Error: Flutter web build failed"
fi

# Test Flutter Android build
echo "📱 Testing Flutter Android build..."
if flutter build apk --debug --no-pub > /dev/null 2>&1; then
    echo "✅ Flutter Android build passed"
else
    echo "❌ Error: Flutter Android build failed"
fi

# Test Go build
echo "🔧 Testing Go build..."
cd server
if go build -v . > /dev/null 2>&1; then
    echo "✅ Go build passed"
else
    echo "❌ Error: Go build failed"
fi
cd ..

echo ""
echo "🎉 Pipeline Verification Complete!"
echo "=================================="
echo ""
echo "📋 Next Steps:"
echo "1. Push these changes to GitHub"
echo "2. Go to Settings > Branches in your repository"
echo "3. Add branch protection rule for 'main' branch"
echo "4. Configure required status checks:"
echo "   - Flutter Lint & Test"
echo "   - Go Lint & Test"
echo "   - Build Verification"
echo "   - PR Status Summary"
echo "5. Test with a pull request"
echo ""
echo "📖 See BRANCH_PROTECTION_SETUP.md for detailed instructions" 