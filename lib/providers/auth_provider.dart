import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  String? _apiKey;

  String? get apiKey => _apiKey;
  bool get isAuthenticated => _apiKey != null && _apiKey!.isNotEmpty;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> loadApiKey() async {
    _apiKey = await _storageService.getApiKey();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setApiKey(String key) async {
    _apiKey = key;
    await _storageService.saveApiKey(key);
    notifyListeners();
  }

  Future<void> logout() async {
    _apiKey = null;
    await _storageService.deleteApiKey();
    notifyListeners();
  }
}
