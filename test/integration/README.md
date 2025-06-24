# Integration Tests

This directory contains integration tests that verify the complete chat flow works end-to-end.

## Test Files

- `chat_integration_test.dart` - Headless integration tests for chat exchange functionality

## Running Integration Tests

To run the integration tests:

```bash
# Run all integration tests
flutter test test/integration/

# Run specific integration test
flutter test test/integration/chat_integration_test.dart

# Run with verbose output
flutter test test/integration/ --verbose
```

## Test Coverage

The integration tests cover:

1. **Complete Chat Flow**: User sends message → Assistant responds
2. **Multiple Message Exchange**: Testing conversation continuity
3. **State Management**: Verifying AsyncValue states during operations
4. **Conversation Reset**: Testing conversation reset functionality
5. **Error Handling**: Empty messages, rapid sends, edge cases
6. **Mock Client Integration**: Using MockGrpcClient for reliable testing
7. **Provider Integration**: Testing all relevant Riverpod providers

## Test Architecture

The tests use:
- `ProviderContainer` for isolated provider testing
- `MockGrpcNotifier` for mock mode activation
- `testWidgets` for async operation testing
- Provider overrides for controlled test environment

These tests run "headless" meaning they don't require UI widgets and test the core business logic directly.