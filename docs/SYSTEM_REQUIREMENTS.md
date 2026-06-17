# System Requirements

This document outlines the minimum and recommended system requirements for running ello.AI on different platforms.

## General Requirements

- **Network**: Internet connection for cloud AI models (optional for local models)
- **Storage**: 150MB available disk space (minimum), 500MB recommended
- **Memory**: 512MB RAM available (minimum), 2GB recommended

## Desktop Platforms

### 🪟 Windows

**Minimum Requirements:**
- Windows 10 (version 1809 or later)
- x64 processor
- 4GB RAM
- DirectX 11 compatible graphics
- 150MB available storage

**Recommended:**
- Windows 11
- Intel Core i3 or AMD Ryzen 3 (2017 or newer)
- 8GB RAM
- Dedicated graphics card
- 500MB available storage

### 🍎 macOS

**Minimum Requirements:**
- macOS 10.14 Mojave
- Intel or Apple Silicon processor
- 4GB RAM
- 150MB available storage

**Recommended:**
- macOS 12.0 Monterey or later
- Apple Silicon (M1/M2) or Intel Core i5 (2017 or newer)
- 8GB RAM
- 500MB available storage

### 🐧 Linux

**Minimum Requirements:**
- 64-bit Linux distribution
- glibc 2.17 or later
- GTK 3.0 or later
- 4GB RAM
- 150MB available storage

**Tested Distributions:**
- Ubuntu 18.04 LTS or later
- Debian 10 or later
- Fedora 30 or later
- openSUSE Leap 15.1 or later
- Arch Linux (current)

**Required Libraries:**
```bash
# Ubuntu/Debian
sudo apt-get install libgtk-3-0 libblkid1 liblzma5

# Fedora
sudo dnf install gtk3 libblkid xz-libs

# Arch Linux
sudo pacman -S gtk3 util-linux xz
```

## Web Platform

### 🌐 Browser Support

**Supported Browsers:**
- Chrome 88+ (recommended)
- Firefox 85+
- Safari 14+
- Edge 88+

**Features:**
- WebGL 2.0 support
- WebAssembly support
- IndexedDB for local storage
- Service Workers for offline functionality

**Hardware:**
- Any device capable of running a modern web browser
- 2GB RAM recommended for optimal performance

## Mobile Platforms

### 📱 iOS

**Minimum Requirements:**
- iOS 12.0 or later
- iPhone 6s or newer, iPad (5th generation) or newer
- 1GB available storage

**Recommended:**
- iOS 15.0 or later
- iPhone 8 or newer, iPad Air 2 or newer
- 2GB available storage

### 🤖 Android

**Minimum Requirements:**
- Android 6.0 (API level 23)
- ARM64 or x86_64 architecture
- 2GB RAM
- 1GB available storage

**Recommended:**
- Android 10.0 or later
- 4GB RAM
- 2GB available storage

## Performance Considerations

### AI Model Performance

**Local Models (GGUF):**
- **CPU**: Modern multi-core processor recommended
- **RAM**: Additional 4-8GB for model loading
- **Storage**: 2-20GB depending on model size

**Cloud Models:**
- **Network**: Stable internet connection (minimum 1 Mbps)
- **Latency**: <100ms ping to model providers for optimal experience

### UI Performance

**Smooth 60fps Experience:**
- Modern GPU with hardware acceleration
- 8GB+ RAM for large conversation histories
- SSD storage for faster app launch times

## Troubleshooting

### Common Issues

1. **App won't start on Linux:**
   - Install missing GTK dependencies
   - Check glibc version: `ldd --version`

2. **Poor performance on older hardware:**
   - Reduce conversation history limit
   - Use smaller local models
   - Close other applications

3. **Network connectivity issues:**
   - Check firewall settings
   - Verify API key configuration
   - Test with web version first

### Getting Help

If you encounter system compatibility issues:

1. Check our [FAQ](docs/FAQ.md)
2. Search [existing issues](https://github.com/elloloop/ello.ai/issues)
3. Create a [new issue](https://github.com/elloloop/ello.ai/issues/new) with:
   - Operating system and version
   - Hardware specifications
   - Error messages or logs
   - Steps to reproduce

## Development Requirements

For building from source, see our [Development Guide](README.md#contributing) for additional requirements including:

- Flutter SDK 3.22+
- Dart SDK 3.2+
- Platform-specific build tools
- Go 1.21+ (for server development)