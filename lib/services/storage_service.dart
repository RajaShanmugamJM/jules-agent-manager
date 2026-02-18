import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final _storage = const FlutterSecureStorage();
  static const _apiKeyKey = 'x-goog-api-key';
  static const _secureStoragePreferenceKey = 'secure_storage_preference';

  Future<void> saveApiKey(String apiKey) async {
    await _storage.write(key: _apiKeyKey, value: apiKey);
  }

  Future<void> saveSecureStoragePreference(bool isEnabled) async {
    await _storage.write(
      key: _secureStoragePreferenceKey,
      value: isEnabled.toString(),
    );
  }

  Future<bool> getSecureStoragePreference() async {
    String? value = await _storage.read(key: _secureStoragePreferenceKey);
    // Default to true if not set
    return value == null ? true : value == 'true';
  }

  Future<String?> getApiKey() async {
    return await _storage.read(key: _apiKeyKey);
  }

  Future<void> deleteApiKey() async {
    await _storage.delete(key: _apiKeyKey);
  }
}
