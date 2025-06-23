#!/bin/bash

# Clean up any existing generated files
rm -rf lib/src/generated/llm_gateway
rm -rf lib/src/generated/chat

# Create directories for generated Dart files
mkdir -p lib/src/generated/llm_gateway
mkdir -p lib/src/generated/chat

# Get dependencies
flutter pub get

# Make sure protoc_plugin is activated with the right version
dart pub global activate protoc_plugin 21.1.2

# Add the Dart pub cache bin to PATH temporarily to ensure we use the right version
export PATH="$PATH":"$HOME/.pub-cache/bin"

# Generate Dart files from proto
protoc --dart_out=grpc:lib/src/generated -Iprotos protos/llm_gateway/*.proto
protoc --dart_out=grpc:lib/src/generated -Iprotos protos/chat.proto

echo "Proto generation complete!"
