# Desktop MVP Development Guide

This guide helps you build and run the ello.AI Desktop MVP.

## Quick Start

### Prerequisites

- Flutter 3.22.0 or newer
- Dart SDK 3.2.0 or newer
- Platform-specific requirements:
  - **Linux**: GTK development libraries
  - **Windows**: Visual Studio 2019 or newer
  - **macOS**: Xcode 12.0 or newer

### Getting Started

1. Clone the repository:
```bash
git clone https://github.com/elloloop/ello.ai.git
cd ello.ai
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app in debug mode:
```bash
# For Linux
flutter run -d linux

# For Windows  
flutter run -d windows

# For macOS
flutter run -d macos
```

### Building for Production

Use the provided build script:

```bash
# Build for current platform
./scripts/build_desktop.sh

# Build for specific platform
./scripts/build_desktop.sh linux
./scripts/build_desktop.sh windows  
./scripts/build_desktop.sh macos
```

Or use Flutter commands directly:

```bash
# Linux
flutter build linux --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release
```

## Desktop MVP Features

✅ **Chat Interface**: Clean Material 3 chat UI
✅ **MCP Integration**: Connect to any Model Context Protocol server
✅ **Mock Mode**: Built-in fallback for offline development
✅ **Debug Settings**: Comprehensive debugging tools
✅ **Connection Management**: Automatic retry and fallback logic
✅ **Model Selection**: Support for multiple AI models
✅ **Cross-Platform**: Runs on Linux, Windows, and macOS

## MCP Server Configuration

The app can connect to MCP servers via gRPC:

### Local Development
- Host: `localhost`
- Port: `50051` (default)
- Secure: `false`

### Production/Cloud Run
- Host: `your-server.run.app`
- Port: `443`
- Secure: `true` (automatic for Cloud Run)

### Debug Settings

In debug mode, click the debug icon to access:
- gRPC connection settings
- Mock/real client toggle
- Connection testing tools
- Automatic fallback configuration

## Testing

Run the test suite:

```bash
# Unit and widget tests
flutter test

# Integration tests
flutter test test/integration_test.dart

# Analyze code
flutter analyze
```

## Troubleshooting

### Common Issues

1. **gRPC Connection Failed**
   - Enable Mock Mode in debug settings
   - Check server host/port configuration
   - Verify TLS settings for Cloud Run

2. **Build Errors**
   - Run `flutter clean && flutter pub get`
   - Ensure platform-specific tools are installed
   - Check Flutter doctor: `flutter doctor`

3. **Generated Files Missing**
   - Run `flutter packages pub run build_runner build`
   - Verify protoc is installed for protobuf generation

### Platform-Specific Setup

#### Linux
```bash
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev
```

#### Windows
- Install Visual Studio 2019 or newer with C++ tools
- Enable Windows desktop development workload

#### macOS
- Install Xcode from Mac App Store
- Accept Xcode license: `sudo xcodebuild -license accept`

## Architecture

The Desktop MVP follows a clean architecture:

- **UI Layer**: Flutter widgets with Material 3 theming
- **State Management**: Riverpod providers for reactive state
- **Business Logic**: Service classes for chat and connection handling
- **Data Layer**: gRPC clients for MCP communication
- **Platform Integration**: Native desktop platform channels

## Contributing

1. Follow the existing code style
2. Add tests for new features
3. Ensure all platforms build successfully
4. Run `flutter analyze` before submitting

For more details, see the main [README.md](../README.md).