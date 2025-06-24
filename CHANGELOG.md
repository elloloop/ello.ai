# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-06-24

### 🎉 Initial MVP Release

This is the first release of ello.AI, a sleek, modern AI chat assistant for every platform.

### ✨ Features

- **Multi-Platform Support**: Runs natively on Web, macOS, Windows, Linux, iOS and Android
- **Single Codebase**: Maintained in Flutter 3.22 and Dart 3
- **Model Integration**: Support for multiple AI models:
  - OpenAI (GPT‑3.5 Turbo, GPT‑4o)
  - Anthropic Claude 3
  - Google Gemini 1.5
  - Meta Llama 3 (OpenAI compatible endpoint)
  - Local GGUF models served over llama.cpp or Ollama
- **Rich UI**: Streaming markdown output with syntax highlighted code blocks
- **Conversation Memory**: Local searchable history
- **Offline First**: Data stays on device unless cloud sync is enabled
- **Advanced Features**: Function calling and JSON mode for tool invocation
- **Customization**: Theming (light, dark, system) and 20+ accent colours
- **Accessibility**: Tested with TalkBack and VoiceOver
- **Internationalization**: Localisation with Flutter Intl

### 🛠️ Architecture

- **Flutter Frontend**: Cross-platform UI built with Flutter 3.22
- **gRPC Integration**: Efficient communication with backend services
- **Protobuf**: Type-safe message serialization
- **Riverpod**: State management for reactive UI
- **Go Server**: Optional server component for enhanced functionality

### 🔧 Developer Experience

- **CI/CD Pipeline**: Automated testing and building with GitHub Actions
- **Code Quality**: Comprehensive linting, formatting, and analysis
- **Testing**: Unit and widget tests with coverage reporting
- **Documentation**: Detailed setup and contribution guides
- **Security**: Vulnerability scanning with Trivy

### 📱 Platform Builds

Supported build targets:
- Web: `flutter build web --release`
- Android: `flutter build apk --release`
- iOS: `flutter build ipa --release`
- Windows: `flutter build windows --release`
- macOS: `flutter build macos --release`
- Linux: `flutter build linux --release`

### 🚀 What's Next

See our [Roadmap](README.md#roadmap) for upcoming features:
- Voice input powered by OpenAI Whisper
- Image understanding with Gemini Vision
- Calendar and email plugins
- In-app prompt engineering playground
- Self-hosted Rust backend

### 📦 Download

- **Web App**: [ello.ai](https://ello.ai) (coming soon)
- **Desktop**: Download from [GitHub Releases](https://github.com/elloloop/ello.ai/releases/tag/v0.1.0)
- **Mobile**: Available on App Store and Google Play (coming soon)

### 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](README.md#contributing) and [Agent Guidelines](AGENTS.md) for details.

### 📄 License

Released under the [MIT License](LICENSE).

---

**Full Changelog**: https://github.com/elloloop/ello.ai/commits/v0.1.0