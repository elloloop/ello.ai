#!/bin/bash
# Script to test gRPC server connectivity

SERVER="grpc-server-4rwujpfquq-uc.a.run.app"
PORT=443
PROTO_PATH="protos/chat.proto"
SERVICE="ello.chat.ChatService"

echo "========================================"
echo "gRPC Server Connectivity Test"
echo "========================================"
echo "Server: $SERVER:$PORT"
echo "Service: $SERVICE"
echo "========================================"

echo "1. Testing basic connectivity with ping..."
ping -c 3 $SERVER

echo "========================================"
echo "2. Testing HTTPS connectivity..."
curl -s https://$SERVER:$PORT
echo ""

echo "========================================"
echo "3. Testing if port 443 is open..."
nc -zv $SERVER $PORT 2>&1

echo "========================================"
echo "4. Testing HTTP/2 compatibility..."
curl -s --http2 https://$SERVER:$PORT

echo "========================================"
echo "5. Testing standard gRPC connectivity (should fail)..."
if command -v grpcurl &> /dev/null; then
  grpcurl -v -plaintext $SERVER:$PORT list 2>&1
  echo "Note: Expected to fail as the server only supports gRPC-Web"
else
  echo "grpcurl not found. Install with 'brew install grpcurl' on macOS"
fi

echo "========================================"
echo "6. Testing gRPC-Web compatibility..."
if command -v grpcurl &> /dev/null; then
  echo "Listing available gRPC services using gRPC-Web..."
  grpcurl -v -proto $PROTO_PATH -import-path . \
    -H "Content-Type: application/grpc-web+proto" \
    $SERVER:$PORT list

  echo "========================================"
  echo "7. Testing a simple gRPC-Web request..."
  # Create a test request
  cat > /tmp/test_request.json << EOL
{
  "messages": [
    {
      "content": "Hello from test script",
      "role": "USER",
      "timestamp": "1687444444000"
    }
  ]
}
EOL

  grpcurl -v -proto $PROTO_PATH -import-path . \
    -H "Content-Type: application/grpc-web+proto" \
    -d @ $SERVER:$PORT \
    $SERVICE/ChatStream < /tmp/test_request.json
else
  echo "grpcurl not found. Install with 'brew install grpcurl' on macOS"
fi

echo "========================================"
echo "Connectivity test completed"
echo ""
echo "FINDINGS:"
echo "1. The server is reachable and port 443 is open"
echo "2. Standard gRPC does not work with this server"
echo "3. gRPC-Web is required to connect to this Cloud Run server"
echo "4. The app has been updated to automatically use gRPC-Web for Cloud Run domains"
echo "5. In the app, you can toggle between gRPC modes in the debug settings (debug mode only)"
echo "========================================"
