# Settings Panel - Model & Key Management

## Overview

The new Settings Panel provides comprehensive management of AI models and API keys for the ello.ai application. It implements all the required acceptance criteria:

✅ **List all supported models grouped by provider**  
✅ **If user brings own key, only show those models**  
✅ **If common key present, show full list**  
✅ **Invalid key surfaces toast and inline error**

## Features

### Model Organization
- Models are now organized by provider (OpenAI, Anthropic, Google, Meta)
- Each provider shows available models when a valid API key is configured
- The model picker displays provider names alongside model names for clarity

### API Key Management
- Secure storage and management of API keys for multiple providers
- Real-time validation with provider-specific rules
- Visual feedback for key validity with inline errors
- Key visibility toggle for security
- Easy removal of configured keys

### Intelligent Model Filtering
- **No API keys configured**: Shows all available models for testing
- **API keys configured**: Only shows models from providers with valid keys
- **Invalid keys**: Models are hidden until keys are corrected
- **Mixed configuration**: Shows models from all providers with valid keys

### User Experience
- Comprehensive validation messages with actionable feedback
- Toast notifications for key operations
- Visual indicators showing how many models each provider offers
- Grouped display of available models per provider

## Usage

### Opening Settings
The settings panel can be accessed via:
1. Settings button next to the model picker in the app bar
2. Direct programmatic access via `showDialog(context: context, builder: (context) => const SettingsPanel())`

### Managing API Keys
1. **Adding Keys**: Enter your API key in the appropriate provider field
2. **Key Validation**: Keys are validated in real-time with provider-specific rules
3. **Visual Feedback**: Green chip shows number of available models for valid keys
4. **Error Handling**: Red error text appears for invalid keys with specific guidance

### Model Selection
1. **Model Picker**: Updated to show "Provider: Model" format
2. **Availability**: Only models from providers with valid keys are shown
3. **Fallback**: When no keys are configured, all models are available for testing

## Technical Implementation

### New Components

#### ModelProvider Class
```dart
class ModelProvider {
  final String id;           // Provider identifier (e.g., 'openai')
  final String name;         // Display name (e.g., 'OpenAI')
  final List<String> models; // Available models
  final String apiKeyName;   // API key field label
  final String Function(String)? validateKey; // Validation function
}
```

#### API Key Management
- `ApiKeysNotifier`: Manages API key state
- `apiKeysProvider`: Riverpod provider for API key access
- `apiKeyValidationProvider`: Real-time validation results

#### UI Components
- `SettingsPanel`: Main settings dialog
- `SettingsButton`: Access button
- Enhanced `ModelPicker`: Shows provider context

### Provider Configuration
Currently supports:
- **OpenAI**: GPT-3.5 Turbo, GPT-4o, GPT-4 Turbo, GPT-4
- **Anthropic**: Claude-3 Opus, Claude-3 Sonnet, Claude-3 Haiku
- **Google**: Gemini Pro, Gemini 1.5 Pro
- **Meta**: Llama-3, Llama-2

### Key Validation Rules
- **OpenAI**: Must start with "sk-"
- **Anthropic**: Must start with "sk-ant-"
- **Google**: Must be longer than 30 characters
- **Meta**: Basic non-empty validation

## Integration

The settings panel integrates seamlessly with existing code:
- Backward compatible with existing `availableModelsProvider`
- Works with existing `ModelPicker` component
- Maintains existing model selection functionality
- No breaking changes to existing APIs

## Testing

A comprehensive test suite validates:
- Provider configuration
- API key management operations
- Model filtering logic
- Validation rule enforcement

Run tests with: `flutter test test/model_management_test.dart`

## Future Enhancements

Potential improvements:
- Persistent storage of API keys (currently session-based)
- Advanced key management (multiple keys per provider)
- Usage tracking and quota monitoring
- Additional provider support
- Key encryption for enhanced security