#!/bin/bash

# Flutter gRPC server connection script
# This script helps connect the Flutter app to a gRPC server
# It supports both local development and Cloud Run deployed servers

set -e

# Display usage information
function show_usage {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  --local             Connect to local development server (default: localhost:50051)"
  echo "  --cloud             Connect to Cloud Run server"
  echo "  --custom HOST:PORT  Connect to custom server (e.g., --custom example.com:8080)"
  echo "  --help              Show this help message"
}

# Default to local if no arguments
if [ "$#" -eq 0 ]; then
  CONNECT_TYPE="local"
else
  case "$1" in
    --local)
      CONNECT_TYPE="local"
      ;;
    --cloud)
      CONNECT_TYPE="cloud"
      ;;
    --custom)
      CONNECT_TYPE="custom"
      if [ -z "$2" ]; then
        echo "❌ Error: --custom requires HOST:PORT parameter"
        show_usage
        exit 1
      fi
      CUSTOM_SERVER="$2"
      ;;
    --help)
      show_usage
      exit 0
      ;;
    *)
      echo "❌ Unknown option: $1"
      show_usage
      exit 1
      ;;
  esac
fi

# Prepare environment file
ENV_FILE=".env.grpc"
echo "# gRPC Connection Configuration" > $ENV_FILE
echo "# Generated on $(date)" >> $ENV_FILE

# Set configuration based on connection type
case "$CONNECT_TYPE" in
  local)
    echo "🔌 Configuring for local development server..."
    echo "GRPC_SERVER_HOST=localhost" >> $ENV_FILE
    echo "GRPC_SERVER_PORT=50051" >> $ENV_FILE
    echo "GRPC_USE_TLS=false" >> $ENV_FILE
    ;;
  cloud)
    echo "🔎 Fetching Cloud Run service URL..."
    SERVICE_URL=$(gcloud run services describe grpc-server --region=us-central1 --format="value(status.url)" 2>/dev/null | sed 's/https:\/\///')
    
    if [ -z "$SERVICE_URL" ]; then
        echo "⚠️ Warning: Could not retrieve the Cloud Run service URL."
        echo "Using default URL from previous deployment..."
        SERVICE_URL="grpc-server-4rwujpfquq-uc.a.run.app"
    fi
    
    echo "🚀 Configuring for Cloud Run server at $SERVICE_URL..."
    echo "GRPC_SERVER_HOST=$SERVICE_URL" >> $ENV_FILE
    echo "GRPC_SERVER_PORT=443" >> $ENV_FILE
    echo "GRPC_USE_TLS=true" >> $ENV_FILE
    ;;
  custom)
    # Parse host and port from CUSTOM_SERVER
    HOST=$(echo $CUSTOM_SERVER | cut -d':' -f1)
    PORT=$(echo $CUSTOM_SERVER | cut -d':' -f2)
    
    if [ -z "$PORT" ]; then
      echo "⚠️ No port specified, assuming port 50051..."
      PORT=50051
    fi
    
    # Assume TLS if port is 443
    if [ "$PORT" -eq 443 ]; then
      USE_TLS=true
    else
      USE_TLS=false
    fi
    
    echo "🔌 Configuring for custom server at $HOST:$PORT..."
    echo "GRPC_SERVER_HOST=$HOST" >> $ENV_FILE
    echo "GRPC_SERVER_PORT=$PORT" >> $ENV_FILE
    echo "GRPC_USE_TLS=$USE_TLS" >> $ENV_FILE
    ;;
esac

echo "✅ Configuration saved to $ENV_FILE"
echo ""
echo "To use this configuration in your Flutter app, add:"
echo "  1. A .env file parser package to your pubspec.yaml"
echo "  2. Load the environment variables at app startup"
echo "  3. Use the ServerConnectionUtil to connect with these values"
echo ""
echo "Happy coding! 🚀"
