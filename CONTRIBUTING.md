# Contributing to ello.AI

Thank you for your interest in contributing to ello.AI! This guide will help you get started with development and building the application locally.

## Prerequisites

- Flutter 3.22.0+ (stable channel)
- Dart 3.2.0+
- Git

### Platform-Specific Requirements

#### macOS Development
- macOS 10.15+ (Catalina or later)
- Xcode 14.0+ with Command Line Tools
- Valid Apple Developer account for code signing (optional for local builds)

#### Windows Development
- Windows 10 build 17763+ or Windows 11
- Visual Studio 2022 with C++ build tools
- Windows 10 SDK (latest version recommended)

#### Linux Development
- Ubuntu 18.04+ or equivalent Linux distribution
- Build essentials: `sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev`

## Getting Started

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/your-username/ello.ai.git
   cd ello.ai
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate protobuf files**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Verify setup**
   ```bash
   flutter doctor -v
   flutter analyze
   dart format --set-exit-if-changed .
   flutter test
   ```

## Local Development

### Running the Application

```bash
# Desktop platforms
flutter run -d macos        # macOS
flutter run -d windows      # Windows
flutter run -d linux        # Linux

# Other platforms
flutter run -d chrome       # Web
flutter run                 # Default device
```

### Pre-Push Validation

Before pushing changes, run the validation script:

```bash
./scripts/pre-push-check.sh
```

This runs the same checks as the CI pipeline locally.

## Local Packaging

### macOS - DMG Distribution

1. **Build the app**
   ```bash
   flutter build macos --release
   ```

2. **Create DMG (requires macOS)**
   ```bash
   # Install create-dmg if not already installed
   brew install create-dmg
   
   # Create unsigned DMG for testing
   ./scripts/build-macos-dmg.sh
   ```

3. **Code Signing (Apple Developer Account required)**
   ```bash
   # Sign the app bundle
   codesign --force --deep --sign "Developer ID Application: Your Name" \
     build/macos/Build/Products/Release/ello_ai.app
   
   # Create signed DMG
   ./scripts/build-macos-dmg.sh --sign "Developer ID Application: Your Name"
   ```

### Windows - MSIX Package

1. **Build the app**
   ```bash
   flutter build windows --release
   ```

2. **Create MSIX package**
   ```bash
   # Install required tools
   # - Windows SDK (includes MakeAppx.exe)
   # - Optional: Visual Studio 2022
   
   # Build MSIX package
   ./scripts/build-windows-msix.sh
   ```

3. **Code Signing (Certificate required)**
   ```bash
   # Sign with certificate
   signtool sign /f your-certificate.pfx /p password /fd sha256 \
     /tr http://timestamp.digicert.com /td sha256 \
     build/windows/runner/Release/ello_ai.msix
   ```

### Linux - AppImage

1. **Build the app**
   ```bash
   flutter build linux --release
   ```

2. **Create AppImage**
   ```bash
   # Install required tools
   sudo apt-get install fuse libfuse2
   
   # Download AppImageTool if not available
   wget -c https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
   chmod +x appimagetool-x86_64.AppImage
   
   # Build AppImage
   ./scripts/build-linux-appimage.sh
   ```

## Code Signing Setup

### macOS Code Signing

1. **Generate certificates** (Apple Developer account required)
   - Developer ID Application certificate
   - Developer ID Installer certificate

2. **Store secrets in environment** (for CI/CD)
   ```bash
   # Certificate (base64 encoded .p12 file)
   MACOS_CERTIFICATE_BASE64
   MACOS_CERTIFICATE_PASSWORD
   
   # Apple ID for notarization
   APPLE_ID_EMAIL
   APPLE_ID_PASSWORD  # App-specific password
   APPLE_TEAM_ID
   ```

### Windows Code Signing

1. **Obtain code signing certificate**
   - Extended Validation (EV) certificate recommended
   - Standard code signing certificate also supported

2. **Store secrets in environment** (for CI/CD)
   ```bash
   # Certificate (base64 encoded .pfx file)
   WINDOWS_CERTIFICATE_BASE64
   WINDOWS_CERTIFICATE_PASSWORD
   ```

### Linux Code Signing

Linux AppImages can be signed using GPG:

```bash
# Generate GPG key
gpg --full-generate-key

# Sign AppImage
gpg --armor --detach-sig ello_ai-x86_64.AppImage
```

## CI/CD Integration

The project uses GitHub Actions for continuous integration:

- **Pull Request Checks**: Runs on every PR
  - Flutter analysis and formatting
  - Unit and widget tests
  - Build verification
  - Security scanning

- **Release Builds**: Runs on push to `main`
  - Builds signed packages for all platforms
  - Creates GitHub Release draft with artifacts
  - Uploads to appropriate distribution channels

### Required GitHub Secrets

Add these secrets to your GitHub repository settings:

```
# macOS
MACOS_CERTIFICATE_BASE64
MACOS_CERTIFICATE_PASSWORD
APPLE_ID_EMAIL
APPLE_ID_PASSWORD
APPLE_TEAM_ID

# Windows
WINDOWS_CERTIFICATE_BASE64
WINDOWS_CERTIFICATE_PASSWORD

# Linux (optional)
GPG_PRIVATE_KEY
GPG_PASSPHRASE
```

## Project Structure

```
ello.ai/
├── lib/                    # Flutter/Dart source code
├── test/                   # Unit and widget tests
├── integration_test/       # Integration tests
├── macos/                  # macOS platform-specific code
├── windows/                # Windows platform-specific code
├── linux/                  # Linux platform-specific code
├── web/                    # Web platform-specific code
├── android/                # Android platform-specific code
├── ios/                    # iOS platform-specific code
├── scripts/                # Build and utility scripts
├── .github/workflows/      # CI/CD workflows
└── docs/                   # Documentation
```

## Development Guidelines

### Code Style

- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart format` for consistent formatting
- Run `flutter analyze` to catch potential issues

### Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/) format:

```
feat(desktop): add macOS DMG packaging
fix(ui): resolve chat input focus issue
docs: update contributing guidelines
```

### Pull Request Process

1. Create a feature branch from `main`
2. Make your changes with appropriate tests
3. Run pre-push validation script
4. Open a pull request with clear description
5. Address any CI failures or review feedback
6. Squash commits when merging

## Platform-Specific Notes

### macOS
- Universal binaries (Intel + Apple Silicon) are generated by default
- Gatekeeper requires notarization for distribution outside Mac App Store
- DMG files provide better user experience than ZIP archives

### Windows
- MSIX is the modern packaging format for Windows 10+
- Classic MSI installers can be created but MSIX is recommended
- Windows Defender may flag unsigned executables

### Linux
- AppImage provides portable distribution across distros
- Traditional .deb/.rpm packages can be created for specific distros
- Flatpak and Snap packages are also viable distribution methods

## Troubleshooting

### Common Issues

1. **Build failures on desktop platforms**
   - Ensure platform-specific dependencies are installed
   - Check Flutter doctor output for missing requirements

2. **Code signing failures**
   - Verify certificate validity and permissions
   - Check keychain access on macOS
   - Ensure certificate matches the app bundle ID

3. **Permission issues on Linux**
   - AppImage may require FUSE for mounting
   - Set executable permissions on generated files

### Getting Help

- Check existing [Issues](https://github.com/elloloop/ello.ai/issues)
- Review [Discussions](https://github.com/elloloop/ello.ai/discussions)
- Join our community Discord (link in README)

## License

By contributing to ello.AI, you agree that your contributions will be licensed under the MIT License.