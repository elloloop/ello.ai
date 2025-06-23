# gRPC Integration with LLM Gateway

This document explains how to use the gRPC integration with the LLM Gateway server.

## Overview

The app now supports connecting to an LLM Gateway server using gRPC. This allows for:

- Streaming chat completions
- Efficient binary communication
- Enhanced features like server-side model selection

## Requirements

1. Access to the LLM Gateway server running on your network or Cloud Run
2. The server should implement the same proto definitions as in `protos/llm_gateway/llm_service.proto`

## Setup Instructions

1. In the app, select "gRPC" from the model dropdown
2. Configure the connection settings:
   - Host: The hostname or IP address of your LLM Gateway server (or Cloud Run URL)
   - Port: The port the gRPC service is running on (default: 50051 locally, 443 for Cloud Run)
   - Secure: Toggle on if your server uses TLS encryption (always on for Cloud Run)

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

## Cloud Run Deployment

When deploying to Cloud Run:

1. Ensure your server listens on the PORT environment variable
2. Configure your server to use HTTP/2 for gRPC streaming
3. The app will automatically use secure TLS connections to Cloud Run services

## Troubleshooting

If you experience connection issues:

- Verify the server is running
- Check network connectivity
- Ensure port forwarding is configured if connecting to a remote server
- Check if firewalls are blocking the connection
- For Cloud Run, make sure your service is correctly configured for gRPC

## Contributing

To extend the gRPC functionality:

1. Modify the proto definitions in `protos/llm_gateway/`
2. Run the proto generation script:
   ```bash
   ./tools/generate_protos.sh
   ```
3. Update the `GrpcClient` class to implement new methods
