# gRPC Integration with LLM Gateway

This document explains how to use the gRPC integration with the LLM Gateway server.

## Overview

The app now supports connecting to an LLM Gateway server using gRPC. This allows for:

- Streaming chat completions
- Efficient binary communication
- Model selection from a unified interface

## Connection Types

The app supports two ways to connect to LLM services:

1. **gRPC Gateway Connection** (Default): Connects to a gRPC server that acts as a gateway to various LLM providers
2. **Direct API Connection**: Connects directly to the OpenAI API (requires API key)

## Model Selection

The dropdown menu in the chat interface now allows you to select the LLM model to use:

- gpt-3.5-turbo (default)
- gpt-4o
- claude-3-opus
- claude-3-sonnet
- gemini-pro
- llama-3

The selected model name is passed to the gRPC server, which handles routing the request to the appropriate provider.

## Connection Settings

To configure the connection settings:

1. Click the settings icon in the app
2. Choose your connection type:
   - Use Direct API Connection: Connects directly to OpenAI API
   - Use gRPC Gateway: Connects to your LLM Gateway server

For gRPC connections, you can configure:

- **Host**: The hostname or IP address of your LLM Gateway server (default: localhost)
- **Port**: The port the gRPC service is running on (default: 50051)
- **Secure**: Toggle on if your server uses TLS encryption
- **Use Mock Client**: Enable this for testing when the actual server is unavailable

## Proto Files

The app uses the Protocol Buffer definitions from the LLM Gateway project. The main service definition is:

```proto
service LLMService {
  rpc ChatCompletionStream(ChatRequest) returns (stream ChatResponse) {}
  rpc ChatCompletion(ChatRequest) returns (ChatCompletionResponse) {}
}

message ChatRequest {
  string model = 1;  // Selected model (e.g., "gpt-3.5-turbo", "claude-3-opus")
  repeated Message messages = 2;
  // ... other parameters
}
```

## Running the LLM Gateway Server

To run the server locally:

1. Clone the LLM Gateway Python repository

   ```bash
   git clone /Users/arun/work/rough/ellp/llm-gateway-python
   ```

2. Install dependencies and start the server

   ```bash
   cd llm-gateway-python
   pip install -r requirements.txt
   python server.py
   ```

3. The server should now be available at `localhost:50051`

## Testing with Mock Client

If you don't have access to the LLM Gateway server, you can use the built-in mock client:

1. Select "gRPC" from the model dropdown
2. In the gRPC settings screen, enable "Use Mock gRPC Client"
3. The mock client will simulate responses as if connected to a real server

## Troubleshooting

If you experience connection issues:

- Verify the server is running
- Check network connectivity
- Ensure port forwarding is configured if connecting to a remote server
- Check if firewalls are blocking the connection
- Try using the mock client to verify the app's functionality

## Updating Proto Definitions

To update the proto definitions:

1. Place the updated proto files in `protos/llm_gateway/`
2. Run the proto generation script:
   ```bash
   ./tools/generate_protos.sh
   ```
3. The Dart code will be generated in `lib/src/generated/`
