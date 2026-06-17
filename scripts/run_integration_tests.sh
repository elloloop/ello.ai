#!/bin/bash

# Simple test runner for integration tests
# This script can be used to run the integration tests independently

set -e

echo "🧪 Running Integration Tests"
echo "============================"

# Check if Flutter is available
if command -v flutter &> /dev/null; then
    echo "✅ Flutter found: $(flutter --version | head -1)"
    
    echo ""
    echo "📋 Running all tests..."
    flutter test test/integration/ --verbose
    
    echo ""
    echo "🎯 Running headless chat test specifically..."
    flutter test test/integration/headless_chat_test.dart --verbose
    
    echo ""
    echo "✅ Integration tests completed successfully!"
else
    echo "❌ Flutter not found. Please install Flutter to run tests."
    echo "   See: https://flutter.dev/docs/get-started/install"
    exit 1
fi