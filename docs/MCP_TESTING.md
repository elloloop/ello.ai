# Local vs Remote MCP Picker - Testing Guide

This document explains how to test the Local vs Remote MCP (Model Control Protocol) picker functionality.

## Overview

The MCP picker automatically detects whether a local MCP server is available and falls back to a remote server if needed. It provides real-time latency monitoring with color-coded status indicators.

## Features Implemented

1. **Health Check Service**: Attempts to connect to `127.0.0.1:5100/healthz` on app launch
2. **Automatic Fallback**: Falls back to last-used remote URL if local is unavailable
3. **Latency Badge**: Shows connection status with color coding:
   - 🟢 Green: ≤150ms (Good)
   - 🟡 Amber: ≤400ms (Medium)  
   - 🔴 Red: >400ms (Poor)
   - ⚫ Gray: Offline

## Testing the Implementation

### 1. Visual Testing

When you run the app, you should see:

1. **MCP Latency Badge**: A new badge in the top-right area showing:
   - "LOCAL" or "REMOTE" text
   - Color-coded based on connection quality
   - Click to see detailed status

2. **Debug Settings**: Enhanced debug dialog showing:
   - Current MCP connection mode
   - Real-time latency information
   - Connection status

### 2. Functional Testing

#### Test Case 1: No Local Server (Default)
- **Expected**: App starts in REMOTE mode
- **Badge**: Shows "REMOTE" with gray/offline status initially
- **Behavior**: App connects to production gRPC server

#### Test Case 2: Local Server Available
To test this scenario, you would need to:
1. Start a local MCP server on `127.0.0.1:5100`
2. Ensure it responds to `/healthz` with HTTP 200
3. Restart the app
- **Expected**: App detects local server and switches to LOCAL mode
- **Badge**: Shows "LOCAL" with color based on response time
- **Behavior**: App connects to localhost:50051 for gRPC

#### Test Case 3: Local Server Goes Offline
1. Start app with local server running (LOCAL mode)
2. Stop local server
3. Wait 30 seconds for health monitoring
- **Expected**: App automatically switches to REMOTE mode
- **Badge**: Changes from "LOCAL" to "REMOTE"
- **Behavior**: Seamless fallback to production server

### 3. Manual Testing

You can manually test the health check endpoint:

```bash
# Test the health endpoint
curl -v http://127.0.0.1:5100/healthz

# Test with timing
time curl http://127.0.0.1:5100/healthz
```

### 4. Unit Testing

Run the included unit tests:

```bash
# Test MCP health service logic
flutter test test/mcp_health_service_test.dart

# Test MCP providers
flutter test test/mcp_providers_test.dart
```

## Integration Points

The MCP picker integrates with:

1. **gRPC Configuration**: Automatically updates host, port, and security settings
2. **Connection Status**: Works with existing connection monitoring
3. **Debug Settings**: Provides detailed information in debug mode
4. **Auto-fallback**: Coordinates with existing mock mode fallback logic

## Configuration

The MCP picker uses these default settings:

- **Local Health Endpoint**: `127.0.0.1:5100/healthz`
- **Health Check Timeout**: 5 seconds
- **Monitoring Interval**: 30 seconds (when in local mode)
- **Default Remote URL**: `grpc-server-4rwujpfquq-uc.a.run.app`

## Troubleshooting

### Local Server Not Detected
- Ensure server is running on `127.0.0.1:5100`
- Check that `/healthz` endpoint returns HTTP 200
- Verify no firewall blocking local connections

### Latency Issues
- High latency (>400ms) will show red badge
- Check network connectivity
- Consider local server performance

### Fallback Not Working
- Check debug settings for connection failure count
- Ensure auto-fallback is enabled
- Review app logs for error messages

## Implementation Files

- `lib/src/services/mcp_health_service.dart` - Health check logic
- `lib/src/ui/debug/mcp_latency_badge.dart` - UI badge component
- `lib/src/core/dependencies.dart` - MCP providers and state management
- `test/mcp_health_service_test.dart` - Unit tests
- `test/mcp_providers_test.dart` - Provider tests