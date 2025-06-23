#!/bin/bash

# Generate Go protobuf files
protoc --go_out=. --go_opt=paths=source_relative \
    --go-grpc_out=. --go-grpc_opt=paths=source_relative \
    proto/llm_service.proto

echo "Generated Go protobuf files" 