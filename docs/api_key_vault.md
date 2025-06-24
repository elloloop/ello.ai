# API Key Vault

This implementation provides secure storage for API keys using platform-specific secure storage mechanisms.

## Security Features

### Platform-Specific Storage
- **macOS**: Uses Keychain via `flutter_secure_storage`
- **Windows**: Uses DPAPI (Data Protection API) via `flutter_secure_storage`
- **Linux**: Uses libsecret via `flutter_secure_storage`

### Fallback Security
- **AES-256 Encryption**: When platform storage is unavailable, keys are encrypted using AES-256
- **HMAC Verification**: Ensures data integrity and prevents tampering
- **Secure Key Generation**: Uses cryptographically secure random key generation
- **Constant-Time Comparison**: Prevents timing attacks during decryption

### User Experience
- **Warning Notifications**: Users are notified when fallback storage is used
- **Automatic Migration**: Environment variable API keys are automatically migrated to secure storage
- **Intuitive UI**: Easy-to-use interface for managing API keys in debug settings

## Usage

### Adding an API Key
1. Open debug settings (only visible in debug mode)
2. Scroll to "API Key Management" section
3. Enter your OpenAI API key
4. Click "Save"

### Security Status
The UI shows the current storage status:
- **Configured**: API key is stored securely
- **Not Set**: No API key configured
- **Error**: Issue accessing secure storage

### Migration
API keys stored in environment variables (`OPENAI_API_KEY`) are automatically migrated to secure storage on first run.

## Implementation Details

### Files
- `lib/src/services/api_key_vault.dart`: Core secure storage implementation
- `lib/src/services/notification_service.dart`: User notification system
- `lib/src/ui/settings/api_key_manager.dart`: UI component for key management
- `lib/src/core/dependencies.dart`: Riverpod providers for state management

### Dependencies Added
- `flutter_secure_storage: ^9.2.2`: Platform-specific secure storage
- `crypto: ^3.0.3`: Cryptographic functions for fallback encryption

### Testing
- `test/api_key_vault_test.dart`: Comprehensive tests for key storage functionality

## Security Considerations

1. **No Hardcoded Keys**: Never commit API keys to version control
2. **Secure Defaults**: Platform storage is preferred, fallback is clearly indicated
3. **User Awareness**: Clear warnings when using fallback storage
4. **Data Isolation**: Keys are stored with app-specific prefixes
5. **Secure Cleanup**: Keys can be completely removed when no longer needed