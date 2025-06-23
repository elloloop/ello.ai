# gRPC Test Server

This is a simple gRPC server that implements the LLMService interface for testing the Flutter client.

## Prerequisites

1. Install Go (version 1.21 or later)
2. Install Protocol Buffers compiler (protoc)
3. Install Go protobuf plugins:
   ```bash
   go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
   go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.3.0
   ```

## Setup

1. Generate the protobuf files:

   ```bash
   chmod +x generate_protos.sh
   ./generate_protos.sh
   ```

2. Install dependencies:
   ```bash
   go mod tidy
   ```

## Running the Server

```bash
go run main.go
```

The server will start on port 50051 and echo back any messages sent by the Flutter client.

## Testing the Server

You can test the server using the included test client:

```bash
cd test
go run main.go
```

This will test both streaming and non-streaming chat completion endpoints.

## Configuring the Flutter App

To connect your Flutter app to this server:

1. **Start the gRPC server** (see above)

2. **Open the Flutter app** and navigate to Settings

3. **Configure the connection settings**:

   - **Disable "Use Mock gRPC Client"** - This enables real gRPC connection
   - **Host**: `localhost` (or your server's IP if running on a different machine)
   - **Port**: `50051`
   - **Secure**: `false` (since we're using insecure connection)
   - **Use Direct API**: `false`

4. **Save the settings** and return to the chat screen

5. **Test the connection** by sending a message - you should see the server echo back your message

## Features

- **ChatCompletionStream**: Streams back the user's message word by word with delays
- **ChatCompletion**: Returns a complete response echoing the user's message

## Testing

The server is designed to work with the Flutter client in this repository. It will:

- Echo back user messages
- Simulate streaming responses
- Provide realistic response structures matching the protobuf definitions

## Configuration

The server runs on `localhost:50051` by default. You can modify the port in `main.go` if needed.

## Troubleshooting

- **Connection refused**: Make sure the server is running on the correct port
- **Mock client still active**: Ensure "Use Mock gRPC Client" is disabled in Flutter settings
- **Different machine**: Use the server's IP address instead of `localhost` in Flutter settings
