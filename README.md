
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

## License

MIT. See `LICENSE` for the full text.
