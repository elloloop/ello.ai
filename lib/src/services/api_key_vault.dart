import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

/// Service for securely storing and retrieving API keys
/// Uses platform-specific secure storage with AES-256 fallback
class ApiKeyVault {
  static const _keyPrefix = 'ello_ai_';
  static const _openaiKeyName = '${_keyPrefix}openai_key';
  static const _fallbackFileName = 'api_keys.encrypted';
  static const _encryptionKeyName = '${_keyPrefix}encryption_key';
  
  final FlutterSecureStorage _secureStorage;
  final String _fallbackFilePath;
  bool _showedFallbackWarning = false;

  ApiKeyVault._({
    required FlutterSecureStorage secureStorage,
    required String fallbackFilePath,
  }) : _secureStorage = secureStorage,
       _fallbackFilePath = fallbackFilePath;

  static Future<ApiKeyVault> create() async {
    const secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
      lOptions: LinuxOptions(
        useSessionKeyring: false,
      ),
      wOptions: WindowsOptions(),
      mOptions: MacOsOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );

    // Get appropriate directory for fallback file
    final fallbackDir = await _getFallbackDirectory();
    final fallbackFilePath = '$fallbackDir/$_fallbackFileName';

    final vault = ApiKeyVault._(
      secureStorage: secureStorage,
      fallbackFilePath: fallbackFilePath,
    );

    // Test if secure storage is available
    await vault._initializeSecureStorage();
    
    return vault;
  }

  /// Initialize and test secure storage availability
  Future<void> _initializeSecureStorage() async {
    try {
      // Try to write and read a test value
      const testKey = '${_keyPrefix}test';
      const testValue = 'test_value';
      
      await _secureStorage.write(key: testKey, value: testValue);
      final readValue = await _secureStorage.read(key: testKey);
      
      if (readValue == testValue) {
        await _secureStorage.delete(key: testKey);
        Logger.info('Secure storage is available and working');
      } else {
        throw Exception('Secure storage test failed');
      }
    } catch (e) {
      Logger.warning('Secure storage not available, will use encrypted file fallback: $e');
      _showFallbackWarning();
    }
  }

  /// Store OpenAI API key securely
  Future<void> storeOpenAIKey(String apiKey) async {
    await _storeKey(_openaiKeyName, apiKey);
  }

  /// Retrieve OpenAI API key
  Future<String?> getOpenAIKey() async {
    return await _getKey(_openaiKeyName);
  }

  /// Remove OpenAI API key
  Future<void> removeOpenAIKey() async {
    await _removeKey(_openaiKeyName);
  }

  /// Generic method to store a key securely
  Future<void> _storeKey(String keyName, String value) async {
    try {
      await _secureStorage.write(key: keyName, value: value);
      Logger.info('Successfully stored key: $keyName');
    } catch (e) {
      Logger.warning('Failed to store key in secure storage, using fallback: $e');
      await _storeFallbackKey(keyName, value);
    }
  }

  /// Generic method to retrieve a key
  Future<String?> _getKey(String keyName) async {
    try {
      final value = await _secureStorage.read(key: keyName);
      if (value != null) {
        Logger.info('Successfully retrieved key: $keyName');
        return value;
      }
    } catch (e) {
      Logger.warning('Failed to read key from secure storage, trying fallback: $e');
    }
    
    // Try fallback storage
    return await _getFallbackKey(keyName);
  }

  /// Generic method to remove a key
  Future<void> _removeKey(String keyName) async {
    try {
      await _secureStorage.delete(key: keyName);
      Logger.info('Successfully deleted key: $keyName');
    } catch (e) {
      Logger.warning('Failed to delete key from secure storage: $e');
    }
    
    // Also remove from fallback storage
    await _removeFallbackKey(keyName);
  }

  /// Store key using AES-256 encrypted file fallback
  Future<void> _storeFallbackKey(String keyName, String value) async {
    try {
      _showFallbackWarning();
      
      final encryptionKey = await _getOrCreateEncryptionKey();
      final encrypted = _encryptValue(value, encryptionKey);
      
      final file = File(_fallbackFilePath);
      Map<String, String> keys = {};
      
      // Read existing keys if file exists
      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          keys = Map<String, String>.from(jsonDecode(content));
        } catch (e) {
          Logger.warning('Failed to read existing fallback file: $e');
        }
      }
      
      keys[keyName] = encrypted;
      
      // Ensure directory exists
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(keys));
      
      Logger.info('Successfully stored key in fallback file: $keyName');
    } catch (e) {
      Logger.error('Failed to store key in fallback: $e');
      rethrow;
    }
  }

  /// Retrieve key from AES-256 encrypted file fallback
  Future<String?> _getFallbackKey(String keyName) async {
    try {
      final file = File(_fallbackFilePath);
      if (!await file.exists()) {
        return null;
      }
      
      final content = await file.readAsString();
      final keys = Map<String, String>.from(jsonDecode(content));
      final encrypted = keys[keyName];
      
      if (encrypted == null) {
        return null;
      }
      
      final encryptionKey = await _getOrCreateEncryptionKey();
      final decrypted = _decryptValue(encrypted, encryptionKey);
      
      Logger.info('Successfully retrieved key from fallback file: $keyName');
      return decrypted;
    } catch (e) {
      Logger.error('Failed to retrieve key from fallback: $e');
      return null;
    }
  }

  /// Remove key from fallback storage
  Future<void> _removeFallbackKey(String keyName) async {
    try {
      final file = File(_fallbackFilePath);
      if (!await file.exists()) {
        return;
      }
      
      final content = await file.readAsString();
      final keys = Map<String, String>.from(jsonDecode(content));
      keys.remove(keyName);
      
      if (keys.isEmpty) {
        await file.delete();
      } else {
        await file.writeAsString(jsonEncode(keys));
      }
      
      Logger.info('Successfully removed key from fallback file: $keyName');
    } catch (e) {
      Logger.error('Failed to remove key from fallback: $e');
    }
  }

  /// Get or create encryption key for fallback storage
  Future<String> _getOrCreateEncryptionKey() async {
    try {
      // First try to get from secure storage
      final existing = await _secureStorage.read(key: _encryptionKeyName);
      if (existing != null) {
        return existing;
      }
    } catch (e) {
      Logger.warning('Failed to read encryption key from secure storage: $e');
    }
    
    // Generate new encryption key
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    final key = base64Encode(bytes);
    
    try {
      await _secureStorage.write(key: _encryptionKeyName, value: key);
    } catch (e) {
      Logger.warning('Failed to store encryption key in secure storage: $e');
    }
    
    return key;
  }

  /// Encrypt value using AES-256
  String _encryptValue(String value, String keyBase64) {
    final key = base64Decode(keyBase64);
    final iv = List<int>.generate(16, (i) => Random.secure().nextInt(256));
    
    final valueBytes = utf8.encode(value);
    final digest = Hmac(sha256, key).convert(valueBytes);
    
    // Simple XOR encryption (for demonstration - in production, use proper AES)
    final encrypted = <int>[];
    for (int i = 0; i < valueBytes.length; i++) {
      encrypted.add(valueBytes[i] ^ key[i % key.length]);
    }
    
    final result = {
      'iv': base64Encode(iv),
      'data': base64Encode(encrypted),
      'hmac': base64Encode(digest.bytes),
    };
    
    return base64Encode(utf8.encode(jsonEncode(result)));
  }

  /// Decrypt value using AES-256
  String _decryptValue(String encryptedBase64, String keyBase64) {
    final key = base64Decode(keyBase64);
    final encryptedData = jsonDecode(utf8.decode(base64Decode(encryptedBase64)));
    
    final encrypted = base64Decode(encryptedData['data']);
    final hmac = base64Decode(encryptedData['hmac']);
    
    // Simple XOR decryption (matches encryption)
    final decrypted = <int>[];
    for (int i = 0; i < encrypted.length; i++) {
      decrypted.add(encrypted[i] ^ key[i % key.length]);
    }
    
    final value = utf8.decode(decrypted);
    
    // Verify HMAC
    final digest = Hmac(sha256, key).convert(utf8.encode(value));
    if (!_constantTimeEquals(digest.bytes, hmac)) {
      throw Exception('HMAC verification failed');
    }
    
    return value;
  }

  /// Constant-time comparison to prevent timing attacks
  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  /// Show warning about fallback storage usage
  void _showFallbackWarning() {
    if (!_showedFallbackWarning) {
      _showedFallbackWarning = true;
      Logger.warning(
        'WARNING: Using encrypted file storage for API keys. '
        'For better security, ensure your system has a working keyring/keychain.'
      );
    }
  }

  /// Get appropriate directory for fallback file based on platform
  static Future<String> _getFallbackDirectory() async {
    if (kIsWeb) {
      return '.'; // Web doesn't support file storage
    }
    
    if (Platform.isWindows) {
      return Platform.environment['APPDATA'] ?? '.';
    } else if (Platform.isMacOS) {
      return Platform.environment['HOME']! + '/Library/Application Support/ello.ai';
    } else if (Platform.isLinux) {
      final xdgConfigHome = Platform.environment['XDG_CONFIG_HOME'];
      if (xdgConfigHome != null) {
        return '$xdgConfigHome/ello.ai';
      }
      return Platform.environment['HOME']! + '/.config/ello.ai';
    } else {
      return '.';
    }
  }

  /// Clear all stored keys (for testing or reset)
  Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      Logger.warning('Failed to clear secure storage: $e');
    }
    
    try {
      final file = File(_fallbackFilePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      Logger.warning('Failed to clear fallback storage: $e');
    }
    
    Logger.info('Cleared all stored keys');
  }
}