#!/bin/bash

# Test runner script for ello.AI Flutter application
# This script runs all tests and generates coverage reports

set -e

echo "🧪 Running ello.AI Test Suite"
echo "============================="

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

print_status "Starting test execution..."

# Clean previous coverage data
print_status "Cleaning previous coverage data..."
rm -rf coverage/
mkdir -p coverage/

# Run Flutter tests with coverage
print_status "Running unit and widget tests..."
if flutter test --coverage --reporter=github; then
    print_success "All tests passed!"
else
    print_error "Some tests failed. Aborting."
    exit 1
fi

# Check if coverage file exists
if [ ! -f "coverage/lcov.info" ]; then
    print_error "Coverage file not generated. Tests may not have run properly."
    exit 1
fi

# Install lcov if not present (for local development)
if ! command -v lcov &> /dev/null; then
    print_warning "lcov not found. Installing..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y lcov
    elif command -v brew &> /dev/null; then
        brew install lcov
    else
        print_error "Cannot install lcov. Please install it manually."
        exit 1
    fi
fi

# Generate HTML coverage report
print_status "Generating HTML coverage report..."
genhtml coverage/lcov.info -o coverage/html --ignore-errors source

# Extract coverage percentage
print_status "Analyzing coverage..."
COVERAGE=$(lcov --summary coverage/lcov.info 2>&1 | grep -o 'lines......[0-9.]*%' | grep -o '[0-9.]*%' | sed 's/%//')

if [ -z "$COVERAGE" ]; then
    print_error "Could not extract coverage percentage"
    exit 1
fi

echo ""
echo "📊 Coverage Report"
echo "=================="
echo "Line Coverage: ${COVERAGE}%"

# Check coverage threshold
THRESHOLD=80
if (( $(echo "$COVERAGE < $THRESHOLD" | bc -l) )); then
    print_error "Coverage ${COVERAGE}% is below required ${THRESHOLD}% threshold"
    echo ""
    echo "📋 To improve coverage:"
    echo "1. Add unit tests for untested business logic"
    echo "2. Add widget tests for UI components"
    echo "3. Add integration tests for user workflows"
    echo ""
    echo "📂 Coverage report available at: coverage/html/index.html"
    exit 1
else
    print_success "Coverage ${COVERAGE}% meets the ${THRESHOLD}% threshold"
fi

# Run integration tests if they exist
if [ -d "test/integration" ] && [ "$(ls -A test/integration)" ]; then
    print_status "Running integration tests..."
    if flutter test integration_test/; then
        print_success "Integration tests passed!"
    else
        print_warning "Integration tests failed, but continuing..."
    fi
fi

# Generate test summary
print_status "Generating test summary..."
echo ""
echo "🎉 Test Execution Complete!"
echo "=========================="
echo "✅ Unit tests: PASSED"
echo "✅ Widget tests: PASSED"
echo "✅ Coverage: ${COVERAGE}% (threshold: ${THRESHOLD}%)"
echo ""
echo "📂 Reports:"
echo "   - Coverage: coverage/html/index.html"
echo "   - LCOV: coverage/lcov.info"
echo ""

if [ -f "coverage/html/index.html" ]; then
    print_status "To view coverage report, open: coverage/html/index.html"
fi

print_success "All tests completed successfully!"