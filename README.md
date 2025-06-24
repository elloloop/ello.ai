# ello.AI

> A sleek, modern AI chat assistant for every platform. Private, powerful, and model-flexible.

## Table of Contents

- Features
- Quick Start
- Architecture
- Model Integration
- Configuration
- Building for Each Platform
- Roadmap
- Contributing
- License

## Features

- Runs natively on Web, macOS, Windows, Linux, iOS and Android
- Single codebase maintained in Flutter 3.22 and Dart 3
- Model picker dropdown with presets for:
  - OpenAI (GPT‑3.5 Turbo, GPT‑4o)
  - Anthropic Claude 3
  - Google Gemini 1.5
  - Meta Llama 3 (OpenAI compatible endpoint)
  - Local GGUF models served over llama.cpp or Ollama
- Streaming markdown output with syntax highlighted code blocks
- Conversation memory with local searchable history
- Offline first: data stays on device unless cloud sync is enabled
- Function calling and JSON mode for tool invocation
- Theming (light, dark, system) and 20+ accent colours
- Localisation with Flutter Intl
- Accessibility tested with TalkBack and VoiceOver

## Quick Start

### Prerequisites

- Flutter stable channel (3.22 or newer)
- Dart SDK (included with Flutter)
- An API key for at least one supported provider
- Optional: llama.cpp server or Ollama for local models

```bash
git clone https://github.com/yourorg/elloAI.git
cd elloAI
flutter pub get

# Start in the browser
flutter run -d chrome

# Run on Android emulator
flutter emulators --launch android
flutter run -d emulator-5554
```

### Configuring API keys

Create a `.env` file at the project root:

```dotenv
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=...
GEMINI_API_KEY=...
LLAMA_ENDPOINT=http://localhost:11434
```

Keys can also be added through the in-app settings panel.
If no `OPENAI_API_KEY` is provided, the app uses a built-in mock model for local testing.

## Architecture

- **UI**: Flutter Material 3 with Riverpod for state management
- **Networking**: Dart `http` package with Server Sent Events
- **LLM Abstraction**: `lib/src/llm_client/` defines a common `ChatClient` interface per provider
- **Persistence**: `isar` database for local storage, optional Firebase sync layer
- **Background tasks**: `flutter_workmanager` plugin

A full diagram lives in `/docs/architecture.drawio`.

## Building for Each Platform

| Platform | Command                           | Artifact                                        |
| -------- | --------------------------------- | ----------------------------------------------- |
| Web      | `flutter build web --release`     | `build/web`                                     |
| Android  | `flutter build apk --release`     | `build/app/outputs/flutter-apk/app-release.apk` |
| iOS      | `flutter build ipa --release`     | Xcode archive                                   |
| Windows  | `flutter build windows --release` | `build/windows/runner/Release`                  |
| macOS    | `flutter build macos --release`   | `.app` bundle                                   |
| Linux    | `flutter build linux --release`   | `build/linux/x64/release/bundle`                |

CI workflows build and upload signed artefacts on each push to `main`.

## Model Integration

All providers implement:

```dart
Stream<ChatChunk> chat({
  required List<Message> messages,
  ModelConfig config,
})
```

To add a new model:

1. Create a class in `lib/src/llm_client/`
2. Implement `ChatClient`
3. Register it in `providers/llm_providers.dart`
4. Expose it in `ui/settings/model_picker.dart`

## gRPC Server Integration

ello.AI supports connecting to a gRPC server for chat functionality. The app includes:

1. Proto definitions in `/protos/chat.proto`
2. Generated Dart client code in `lib/src/generated/`
3. A gRPC client service in `lib/src/services/chat_service_client.dart`

### Setting up the gRPC Connection

Initialize the connection using the `grpcConnectionProvider`:

```dart
final config = GrpcConnectionConfig(
  host: 'localhost', // Change to your server's host
  port: 50051,      // Change to your server's port
  secure: false,    // Set to true for TLS
);

// Initialize the connection
await ref.read(grpcConnectionProvider(config).future);
```

### gRPC-Web Support

The app includes gRPC-Web support for better compatibility with services like Cloud Run:

- For Cloud Run and other similar services, gRPC-Web is automatically enabled
- You can toggle between standard gRPC and gRPC-Web in the debug settings

The client automatically detects Cloud Run services (domains ending with `run.app`) and defaults to gRPC-Web mode with secure connections.

### Debug Settings

In debug mode, a bug icon appears in the app bar that opens debug settings:

- Toggle between mock and real gRPC clients
- Switch between standard gRPC and gRPC-Web
- Edit gRPC server connection details (host, port, secure mode)
- Test connection to verify your settings
- Reset to production or local development settings
- Monitor connection failures and toggle auto-fallback to mock mode

The debug UI is only available in debug builds and will not appear in release builds.

### Streaming Chat Messages

Use the `chatStreamProvider` to stream responses:

```dart
// Assume messages is a List<YourMessageType>
ref.read(chatStreamProvider(messages)).when(
  data: (response) {
    // Handle each chunk from the stream
    print('Received: ${response.content}');

    // Check if the stream is complete
    if (response.isDone) {
      print('Stream completed');
    }
  },
  loading: () {
    // Stream is being processed
  },
  error: (error, stackTrace) {
    print('Error: $error');
  },
);
```

### Running the Go Server

A sample Go server is included in the `/server` directory:

```bash
cd server
go run main.go
```

The server listens on port 50051 by default and provides an echo service for testing.

## Roadmap

- Voice input powered by OpenAI Whisper
- Image understanding with Gemini Vision
- Calendar and email plugins
- In-app prompt engineering playground
- Self-hosted Rust backend

## Contributing

1. Fork and create a feature branch
2. Write unit and widget tests
3. Run `dart format` and `flutter analyze`
4. Open a pull request against `main`

### CI/CD Pipeline

This project uses GitHub Actions for continuous integration. Every pull request triggers:

- **Flutter Checks**: Linting, formatting, and tests
- **Go Server Checks**: Formatting, vetting, and tests
- **Build Verification**: Ensures all platforms compile
- **Security Scanning**: Vulnerability detection

#### Pre-Push Validation

Run the local validation script before pushing:

```bash
./scripts/pre-push-check.sh
```

This script runs the same checks as the CI pipeline locally, saving time and preventing failed builds.

#### Branch Protection

The `main` branch is protected and requires:

- All status checks to pass
- At least one approval
- Conversation resolution

Branch protection is configured and enforced automatically via GitHub settings.

## License

MIT. See `LICENSE` for the full text.
