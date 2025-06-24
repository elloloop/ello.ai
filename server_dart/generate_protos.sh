#!/bin/bash

# Generate Dart protobuf files using build_runner
echo "Generating Dart protobuf files..."

# Get dependencies first
dart pub get

# Generate protobuf files using build_runner
dart run build_runner build --delete-conflicting-outputs

echo "Protobuf files generated successfully!" 