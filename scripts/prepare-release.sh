#!/bin/bash

# Release Preparation Script
# Automates the release process for ello.AI

set -e

echo "🚀 ello.AI Release Preparation"
echo "============================="
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

# Check if version is provided
if [ -z "$1" ]; then
    print_error "Usage: $0 <version> [--dry-run]"
    echo "Example: $0 v0.1.1"
    echo "         $0 v0.2.0 --dry-run"
    exit 1
fi

VERSION="$1"
DRY_RUN=""

if [ "$2" = "--dry-run" ]; then
    DRY_RUN="--dry-run"
    print_warning "DRY RUN MODE: No changes will be made"
fi

# Validate version format
if [[ ! $VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?$ ]]; then
    print_error "Invalid version format. Use semantic versioning (e.g., v1.0.0, v1.0.0-beta)"
    exit 1
fi

echo "📋 Release Checklist for $VERSION"
echo "================================="
echo ""

# Check git status
print_status "Checking git status..."
if [ -n "$(git status --porcelain)" ]; then
    print_warning "Working directory has uncommitted changes."
    if [ -z "$DRY_RUN" ]; then
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Aborted by user"
            exit 1
        fi
    fi
fi

# Check if we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    print_warning "Not on main branch (currently on: $CURRENT_BRANCH)"
    if [ -z "$DRY_RUN" ]; then
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Aborted by user"
            exit 1
        fi
    fi
fi

# Update version in pubspec.yaml
print_status "Updating version in pubspec.yaml..."
VERSION_NUMBER=${VERSION#v}  # Remove 'v' prefix
if [ -z "$DRY_RUN" ]; then
    sed -i.bak "s/^version: .*/version: $VERSION_NUMBER/" pubspec.yaml
    print_success "Updated pubspec.yaml to version $VERSION_NUMBER"
else
    print_status "Would update pubspec.yaml to version $VERSION_NUMBER"
fi

# Run tests
print_status "Running pre-release checks..."
if command -v flutter &> /dev/null; then
    if [ -z "$DRY_RUN" ]; then
        flutter pub get
        flutter analyze --fatal-infos --fatal-warnings
        flutter test
        print_success "All tests passed"
    else
        print_status "Would run: flutter pub get && flutter analyze && flutter test"
    fi
else
    print_warning "Flutter not found, skipping tests"
fi

# Test desktop builds
print_status "Testing desktop builds..."
if [ -f "scripts/test-desktop-builds.sh" ]; then
    if [ -z "$DRY_RUN" ]; then
        ./scripts/test-desktop-builds.sh
        print_success "Desktop build tests completed"
    else
        print_status "Would run: ./scripts/test-desktop-builds.sh"
    fi
else
    print_warning "Desktop build test script not found"
fi

# Update CHANGELOG.md
print_status "Checking CHANGELOG.md..."
if [ -f "CHANGELOG.md" ]; then
    if grep -q "## \[$VERSION_NUMBER\]" CHANGELOG.md; then
        print_success "CHANGELOG.md already contains section for $VERSION"
    else
        print_warning "CHANGELOG.md missing section for $VERSION"
        print_status "Please add release notes to CHANGELOG.md before continuing"
        if [ -z "$DRY_RUN" ]; then
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_error "Aborted by user"
                exit 1
            fi
        fi
    fi
else
    print_warning "CHANGELOG.md not found"
fi

# Create git tag
print_status "Creating git tag $VERSION..."
if git tag | grep -q "^$VERSION$"; then
    print_warning "Tag $VERSION already exists"
    if [ -z "$DRY_RUN" ]; then
        read -p "Delete and recreate? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git tag -d "$VERSION"
            print_status "Deleted existing tag $VERSION"
        else
            print_error "Aborted by user"
            exit 1
        fi
    fi
fi

if [ -z "$DRY_RUN" ]; then
    # Extract release notes for tag message
    TAG_MESSAGE="ello.AI $VERSION Release"
    if [ -f "CHANGELOG.md" ] && grep -q "## \[$VERSION_NUMBER\]" CHANGELOG.md; then
        # Extract the section for this version (first 10 lines)
        RELEASE_NOTES=$(awk "/^## \[${VERSION_NUMBER}\]/{flag=1; next} /^## \[/{flag=0} flag {print} flag && NR>10{exit}" CHANGELOG.md | head -10)
        if [ -n "$RELEASE_NOTES" ]; then
            TAG_MESSAGE="$TAG_MESSAGE

$RELEASE_NOTES"
        fi
    fi
    
    git tag -a "$VERSION" -m "$TAG_MESSAGE"
    print_success "Created tag $VERSION"
else
    print_status "Would create tag: $VERSION"
fi

# Commit version changes
if [ -z "$DRY_RUN" ] && [ -f "pubspec.yaml.bak" ]; then
    if ! cmp -s pubspec.yaml pubspec.yaml.bak; then
        git add pubspec.yaml
        git commit -m "chore: bump version to $VERSION_NUMBER"
        print_success "Committed version bump"
    fi
    rm pubspec.yaml.bak
fi

echo ""
print_success "🎉 Release preparation completed!"
echo ""
print_status "📋 Next steps:"
echo "  1. Push changes and tag: git push origin main --follow-tags"
echo "  2. GitHub Actions will automatically:"
echo "     - Build all platforms"
echo "     - Create GitHub release"
echo "     - Upload release artifacts"
echo "     - Deploy web app"
echo "  3. Update download links if needed"
echo "  4. Announce the release"
echo ""

if [ -n "$DRY_RUN" ]; then
    print_warning "This was a dry run. No changes were made."
fi

print_status "Release $VERSION is ready! 🚀"