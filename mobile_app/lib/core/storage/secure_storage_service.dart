import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  static const String _keyToken = 'jwt_token';
  static const String _keyUserData = 'user_data';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    try {
      await _secureStorage.write(key: _keyToken, value: token);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
    }
  }

  Future<String?> getToken() async {
    try {
      final token = await _secureStorage.read(key: _keyToken);
      if (token != null) return token;
    } catch (_) {
      // Fallback to SharedPreferences
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyToken);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUserData(Map<String, dynamic> userJson) async {
    final raw = jsonEncode(userJson);
    try {
      await _secureStorage.write(key: _keyUserData, value: raw);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserData, raw);
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    String? raw;
    try {
      raw = await _secureStorage.read(key: _keyUserData);
    } catch (_) {
      // Fallback
    }
    if (raw == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        raw = prefs.getString(_keyUserData);
      } catch (_) {
        return null;
      }
    }
    if (raw != null) {
      try {
        return jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (_) {
      // Ignore
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUserData);
    } catch (_) {
      // Ignore
    }
  }
}
