import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final SecureStorageService _storage = SecureStorageService();

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get errorMessage => _errorMessage;

  Future<void> checkAuthStatus() async {
    _isInitializing = true;
    notifyListeners();

    try {
      final token = await _storage.getToken();
      if (token != null && token.isNotEmpty) {
        final userData = await _storage.getUserData();
        if (userData != null) {
          _currentUser = UserModel.fromJson(userData);
        }
      }
    } catch (_) {
      await _storage.clearAll();
      _currentUser = null;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        ApiConstants.login,
        body: {
          'email': email.trim(),
          'password': password,
        },
      );

      if (response != null && response['token'] != null) {
        final token = response['token'].toString();
        await _storage.saveToken(token);

        final userMap = response['user'] as Map<String, dynamic>? ?? response;
        final user = UserModel.fromJson({
          ...userMap,
          'token': token,
        });

        _currentUser = user;
        await _storage.saveUserData(user.toJson());

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid response from server.';
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Login failed. Please try again.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String role = 'Candidate',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        ApiConstants.register,
        body: {
          'fullName': name.trim(),
          'email': email.trim(),
          'password': password,
          'role': role,
        },
      );

      if (response != null && response['token'] != null) {
        final token = response['token'].toString();
        await _storage.saveToken(token);

        final userMap = response['user'] as Map<String, dynamic>? ?? response;
        final user = UserModel.fromJson({
          ...userMap,
          'token': token,
        });

        _currentUser = user;
        await _storage.saveUserData(user.toJson());

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Registration succeeded but session token is missing.';
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Registration failed: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _storage.clearAll();
    _currentUser = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
