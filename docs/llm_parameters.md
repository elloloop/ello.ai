# LLM Parameters Feature

This feature adds user-configurable temperature and top-p parameters for LLM responses using Flutter sliders.

## Usage

### UI Components

The feature provides two UI components:

1. **LlmParameterSettings**: A full expansion tile with detailed sliders and descriptions
2. **LlmParameterCompact**: A compact popup menu for space-constrained areas

### Parameters

#### Temperature (0.0 - 2.0, default: 0.7)
- Controls randomness in the model's responses
- Lower values (0.0-0.3): More focused and deterministic responses
- Medium values (0.4-0.9): Balanced creativity and coherence  
- Higher values (1.0-2.0): More creative and varied responses

#### Top-p (0.0 - 1.0, default: 1.0)
- Controls the diversity of vocabulary used
- Lower values (0.1-0.5): More focused vocabulary, fewer word choices
- Medium values (0.6-0.9): Balanced vocabulary diversity
- Higher values (0.95-1.0): Full vocabulary range available

### Integration

The parameters are automatically passed to all chat clients:
- OpenAI client: Uses `temperature` and `top_p` in API calls
- gRPC client: Includes parameters in protobuf ChatRequest
- Mock clients: Echo parameters in responses for testing

### Code Example

```dart
// Access current parameter values
final temperature = ref.read(temperatureProvider);
final topP = ref.read(topPProvider);

// Update parameter values
ref.read(temperatureProvider.notifier).updateTemperature(0.8);
ref.read(topPProvider.notifier).updateTopP(0.9);

// Reset to defaults
ref.read(temperatureProvider.notifier).updateTemperature(0.7);
ref.read(topPProvider.notifier).updateTopP(1.0);
```

### Testing

Comprehensive tests are included:
- UI component tests (`test/llm_parameters_test.dart`)
- Chat client integration tests (`test/chat_client_test.dart`)  
- End-to-end integration tests (`test/integration_test.dart`)

### Protobuf Schema

The feature extends the existing `ChatRequest` message with a new `top_p` field:

```protobuf
message ChatRequest {
  string model = 1;
  repeated Message messages = 2;
  float temperature = 3;  // existing
  int32 max_tokens = 4;
  string user_id = 5;
  float top_p = 6;        // new field
}
```

### Future Enhancements

- Parameter persistence across app sessions
- Model-specific parameter presets
- Advanced parameter validation
- Parameter history/favorites