#!/bin/bash

# Pre-push validation script for ello.AI
# Runs the same checks as the CI pipeline locally

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🚀 Running pre-push validation for ello.AI"
echo "================================================"

cd "$PROJECT_ROOT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
  echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
  echo -e "${RED}❌ $1${NC}"
}

# Check if Flutter is available
print_status "Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
  print_error "Flutter is not installed or not in PATH"
  echo "Please install Flutter 3.22.0+ and add it to your PATH"
  exit 1
fi

FLUTTER_VERSION=$(flutter --version | head -n1 | cut -d' ' -f2)
print_success "Flutter $FLUTTER_VERSION found"

# Check if Go is installed (optional for Flutter-only changes)
if ! command -v go &> /dev/null; then
    print_warning "Go is not installed. Server checks will be skipped."
    GO_AVAILABLE=false
else
    GO_AVAILABLE=true
fi

# Flutter doctor
print_status "Running Flutter doctor..."
flutter doctor -v

# Get dependencies
print_status "Getting Flutter dependencies..."
flutter pub get

# Generate protobuf files
print_status "Generating protobuf files..."
if ! flutter pub run build_runner build --delete-conflicting-outputs; then
  print_error "Failed to generate protobuf files"
  exit 1
fi
print_success "Protobuf files generated"

# Run Flutter analyze
print_status "Running Flutter analysis..."
if ! flutter analyze --fatal-infos --fatal-warnings; then
  print_error "Flutter analysis failed"
  print_warning "Please fix all analysis issues before pushing"
  exit 1
fi
print_success "Flutter analysis passed"

# Check formatting
print_status "Checking Dart formatting..."
if ! dart format --set-exit-if-changed .; then
  print_error "Code formatting issues found"
  print_warning "Run 'dart format .' to fix formatting"
  exit 1
fi
print_success "Code formatting is correct"

# Run tests
print_status "Running Flutter tests..."
if ! flutter test --reporter=github; then
  print_error "Tests failed"
  exit 1
fi
print_success "All tests passed"

# Go server checks (if Go is available)
if [ "$GO_AVAILABLE" = true ] && [ -d "server" ]; then
  print_status "Running Go server checks..."
  
  cd server
  
  print_status "Go dependencies verification..."
  if go mod download && go mod verify; then
    print_success "Go dependencies verified"
  else
    print_error "Go dependencies verification failed"
    exit 1
  fi
  
  print_status "Go code formatting check..."
  if [ "$(gofmt -s -l . | wc -l)" -gt 0 ]; then
    print_error "Go code needs formatting. Files that need formatting:"
    gofmt -s -l .
    echo "Run: gofmt -s -w ."
    exit 1
  else
    print_success "Go code formatting is correct"
  fi
  
  print_status "Go vet check..."
  if go vet ./...; then
    print_success "Go vet passed"
  else
    print_error "Go vet failed. Fix the issues above."
    exit 1
  fi
  
  print_status "Go tests..."
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
  
  print_status "Go server build test..."
  if go build -v . > /dev/null 2>&1; then
    print_success "Go server build successful"
  else
    print_error "Go server build failed"
    exit 1
  fi
  
  cd "$PROJECT_ROOT"
fi

# Build verification
print_status "Verifying build (Web)..."
if ! flutter build web --no-pub; then
  print_error "Web build failed"
  exit 1
fi
print_success "Web build successful"

# Check for desktop build capabilities
print_status "Checking desktop build capabilities..."

# macOS build check
if [[ "$OSTYPE" == "darwin"* ]]; then
  print_status "Verifying macOS build..."
  if flutter build macos --release --no-pub; then
    print_success "macOS build successful"
  else
    print_warning "macOS build failed (non-critical for PR)"
  fi
fi

# Windows build check
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
  print_status "Verifying Windows build..."
  if flutter build windows --release --no-pub; then
    print_success "Windows build successful"
  else
    print_warning "Windows build failed (non-critical for PR)"
  fi
fi

# Linux build check
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  print_status "Verifying Linux build..."
  # Check for required dependencies
  if command -v pkg-config &> /dev/null && pkg-config --exists gtk+-3.0; then
    if flutter build linux --release --no-pub; then
      print_success "Linux build successful"
    else
      print_warning "Linux build failed (non-critical for PR)"
    fi
  else
    print_warning "Linux desktop dependencies not found (install libgtk-3-dev)"
  fi
fi

# Android build verification (optional)
print_status "Android APK build test..."
if flutter build apk --debug --no-pub > /dev/null 2>&1; then
  print_success "Android APK build successful"
else
  print_warning "Android APK build failed (this might be OK if Android SDK is not configured)"
fi

# Check for common issues
print_status "Checking for common issues..."

# Check for TODO/FIXME comments in critical files
TODO_COUNT=$(find lib -name "*.dart" -exec grep -l "TODO\|FIXME" {} \; 2>/dev/null | wc -l)
if [ "$TODO_COUNT" -gt 0 ]; then
  print_warning "Found $TODO_COUNT files with TODO/FIXME comments"
  find lib -name "*.dart" -exec grep -l "TODO\|FIXME" {} \; 2>/dev/null
fi

# Check for debug print statements
DEBUG_PRINTS=$(find lib -name "*.dart" -exec grep -l "print(" {} \; 2>/dev/null | wc -l)
if [ "$DEBUG_PRINTS" -gt 0 ]; then
  print_warning "Found $DEBUG_PRINTS files with debug print statements"
  find lib -name "*.dart" -exec grep -l "print(" {} \; 2>/dev/null
fi

# Check for hardcoded values that should be configuration
HARDCODED_URLS=$(find lib -name "*.dart" -exec grep -l "http://\|https://" {} \; 2>/dev/null | wc -l)
if [ "$HARDCODED_URLS" -gt 0 ]; then
  print_warning "Found $HARDCODED_URLS files with hardcoded URLs (consider using configuration)"
fi

# Git status
print_status "Checking Git status..."
if [ -n "$(git status --porcelain)" ]; then
  print_warning "Working directory has uncommitted changes:"
  git status --short
  echo ""
  print_warning "Consider committing or stashing changes before pushing"
fi

# Check commit message (if available)
if [ -n "$1" ]; then
  print_status "Checking commit message format..."
  COMMIT_MSG="$1"
  if [[ ! "$COMMIT_MSG" =~ ^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?: .+ ]]; then
    print_warning "Commit message doesn't follow Conventional Commits format"
    echo "Expected format: type(scope): description"
    echo "Types: feat, fix, docs, style, refactor, test, chore"
  else
    print_success "Commit message format is correct"
  fi
fi

echo ""
echo "================================================"
print_success "Pre-push validation completed successfully! 🎉"
echo ""
echo "Your changes are ready to be pushed."
echo "The CI pipeline will run similar checks on the remote repository."

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