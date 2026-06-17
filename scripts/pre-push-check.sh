#!/bin/bash

# Pre-push check script
# Run this script before pushing to ensure your code will pass CI/CD pipeline

set -e  # Exit on any error

echo "🚀 Running pre-push checks..."
echo "=============================="

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

# Check if Go is installed
if ! command -v go &> /dev/null; then
    print_error "Go is not installed. Please install Go first."
    exit 1
fi

echo ""
print_status "Step 1: Flutter Dependencies"
flutter pub get
print_success "Flutter dependencies installed"

echo ""
print_status "Step 2: Generate Protobuf Files"
flutter pub run build_runner build --delete-conflicting-outputs
print_success "Protobuf files generated"

echo ""
print_status "Step 3: Flutter Code Analysis"
if flutter analyze --fatal-infos --fatal-warnings; then
    print_success "Flutter analysis passed"
else
    print_error "Flutter analysis failed. Fix the issues above."
    exit 1
fi

echo ""
print_status "Step 4: Flutter Code Formatting"
if dart format --set-exit-if-changed .; then
    print_success "Flutter code formatting is correct"
else
    print_error "Flutter code needs formatting. Run: dart format ."
    exit 1
fi

echo ""
print_status "Step 5: Flutter Tests"
if flutter test; then
    print_success "Flutter tests passed"
else
    print_error "Flutter tests failed. Fix the failing tests."
    exit 1
fi

echo ""
print_status "Step 6: Go Dependencies (Server)"
cd server
if go mod download && go mod verify; then
    print_success "Go dependencies verified"
else
    print_error "Go dependencies verification failed"
    exit 1
fi

echo ""
print_status "Step 7: Go Code Formatting"
if [ "$(gofmt -s -l . | wc -l)" -gt 0 ]; then
    print_error "Go code needs formatting. Files that need formatting:"
    gofmt -s -l .
    echo "Run: gofmt -s -w ."
    exit 1
else
    print_success "Go code formatting is correct"
fi

echo ""
print_status "Step 8: Go Vet"
if go vet ./...; then
    print_success "Go vet passed"
else
    print_error "Go vet failed. Fix the issues above."
    exit 1
fi

echo ""
print_status "Step 9: Go Tests"
if ls *_test.go 1> /dev/null 2>&1; then
    if go test -v ./...; then
        print_success "Go tests passed"
    else
        print_error "Go tests failed. Fix the failing tests."
        exit 1
    fi
else
    print_warning "No Go test files found (*_test.go)"
fi

echo ""
print_status "Step 10: Build Verification"
cd ..

print_status "Building Flutter web..."
if flutter build web --no-pub > /dev/null 2>&1; then
    print_success "Flutter web build successful"
else
    print_error "Flutter web build failed"
    exit 1
fi

print_status "Building Flutter Android APK..."
if flutter build apk --debug --no-pub > /dev/null 2>&1; then
    print_success "Flutter Android APK build successful"
else
    print_warning "Flutter Android APK build failed (this might be OK if Android SDK is not configured)"
fi

print_status "Building Go server..."
cd server
if go build -v . > /dev/null 2>&1; then
    print_success "Go server build successful"
else
    print_error "Go server build failed"
    exit 1
fi

cd ..

echo ""
echo "=============================="
print_success "🎉 All pre-push checks passed!"
echo "=============================="
echo ""
print_status "Your code is ready to be pushed and should pass the CI/CD pipeline."
print_status "You can now safely run: git push"
echo ""
print_status "💡 For release preparation, also run:"
print_status "   ./scripts/test-desktop-builds.sh  # Test desktop builds"
print_status "   ./scripts/prepare-release.sh v<version>  # Prepare release"
echo ""

# Optional: Ask if user wants to push now
read -p "Do you want to push your changes now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Pushing changes..."
    git push
    print_success "Changes pushed successfully!"
else
    print_status "Push skipped. You can push manually when ready."
fi