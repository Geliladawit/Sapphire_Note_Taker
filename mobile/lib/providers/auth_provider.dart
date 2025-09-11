import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  // Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Check if user is already logged in
  Future<void> checkAuthStatus() async {
    _setLoading(true);
    
    try {
      _user = await _apiService.getProfile();
      _isAuthenticated = true;
      _error = null;
    } catch (e) {
      _isAuthenticated = false;
      _user = null;
      await _apiService.clearTokens();
    }
    
    _setLoading(false);
  }

  // Register user
  Future<bool> register({
    required String email,
    required String username,
    required String firstName,
    required String lastName,
    required String password,
    required String passwordConfirm,
  }) async {
    _setLoading(true);
    
    try {
      final response = await _apiService.register(
        email: email,
        username: username,
        firstName: firstName,
        lastName: lastName,
        password: password,
        passwordConfirm: passwordConfirm,
      );
      
      _user = User.fromJson(response['user']);
      _isAuthenticated = true;
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      _setLoading(false);
      return false;
    }
  }

  // Login user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    
    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );
      
      _user = User.fromJson(response['user']);
      _isAuthenticated = true;
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      _setLoading(false);
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      await _apiService.logout();
    } catch (e) {
      // Continue with logout even if API call fails
      print('Logout API call failed: $e');
    }
    
    _user = null;
    _isAuthenticated = false;
    _error = null;
    _setLoading(false);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.data is Map) {
        final data = error.response!.data as Map<String, dynamic>;
        
        // Handle specific field errors
        if (data.containsKey('email')) {
          final emailErrors = data['email'];
          if (emailErrors is List && emailErrors.isNotEmpty) {
            final emailError = emailErrors.first.toString();
            if (emailError.contains('already exists') || emailError.contains('taken')) {
              return 'This email is already registered. Please use a different email or try logging in.';
            }
            return 'Email: $emailError';
          }
        }
        
        if (data.containsKey('username')) {
          final usernameErrors = data['username'];
          if (usernameErrors is List && usernameErrors.isNotEmpty) {
            final usernameError = usernameErrors.first.toString();
            if (usernameError.contains('already exists') || usernameError.contains('taken')) {
              return 'This username is already taken. Please choose a different username.';
            }
            return 'Username: $usernameError';
          }
        }
        
        if (data.containsKey('non_field_errors')) {
          return (data['non_field_errors'] as List).first.toString();
        }
        
        if (data.containsKey('detail')) {
          return data['detail'].toString();
        }
        
        // Extract first validation error
        for (final key in data.keys) {
          if (data[key] is List && (data[key] as List).isNotEmpty) {
            final fieldName = key.replaceAll('_', ' ');
            final errorMessage = (data[key] as List).first.toString();
            return '${fieldName[0].toUpperCase() + fieldName.substring(1)}: $errorMessage';
          }
        }
      }
      return error.message ?? 'Network error occurred';
    }
    return error.toString();
  }
}
