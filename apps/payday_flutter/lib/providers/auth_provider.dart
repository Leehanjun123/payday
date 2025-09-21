import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _user;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _apiService.initialize();
    _checkAuthStatus();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final token = await _apiService.getToken();
      if (token != null) {
        await _loadUserProfile();
      }
    } catch (e) {
      print('Auth check failed: $e');
      await logout();
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final userData = await _apiService.getUserProfile();
      _user = User.fromJson(userData['user'] ?? userData);
      _isLoggedIn = true;

      // Save login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);

      notifyListeners();
    } catch (e) {
      print('Failed to load user profile: $e');
      await logout();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.login(email, password);

      if (response['success'] == true || response['token'] != null) {
        await _loadUserProfile();
        return true;
      } else {
        _setError(response['message'] ?? '로그인에 실패했습니다.');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(
    String email,
    String password,
    String name,
    String phone,
  ) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.register(email, password, name, phone);

      if (response['success'] == true || response['token'] != null) {
        await _loadUserProfile();
        return true;
      } else {
        _setError(response['message'] ?? '회원가입에 실패했습니다.');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    try {
      _setLoading(true);

      // Call API logout if user is logged in
      if (_isLoggedIn) {
        try {
          await _apiService.logout();
        } catch (e) {
          print('API logout failed: $e');
        }
      }

      // Clear local state
      _user = null;
      _isLoggedIn = false;

      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_logged_in');

      notifyListeners();
    } catch (e) {
      print('Logout error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? bio,
    String? profileImage,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      if (bio != null) updateData['bio'] = bio;
      if (profileImage != null) updateData['profileImage'] = profileImage;

      final response = await _apiService.updateUserProfile(updateData);

      if (response['success'] == true || response['user'] != null) {
        _user = User.fromJson(response['user'] ?? response);
        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? '프로필 업데이트에 실패했습니다.');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      _setLoading(true);
      _setError(null);

      // This would be implemented based on your API
      // For now, just return true as placeholder
      await Future.delayed(const Duration(seconds: 1));

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _setError(null);

      // This would be implemented based on your API
      // For now, just return true as placeholder
      await Future.delayed(const Duration(seconds: 1));

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> refreshToken() async {
    try {
      final response = await _apiService.refreshToken();
      return response['success'] == true;
    } catch (e) {
      print('Token refresh failed: $e');
      await logout();
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      _setLoading(true);
      _setError(null);

      // This would be implemented based on your API
      // For now, just logout as placeholder
      await logout();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Validation helpers
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  static bool isValidPassword(String password) {
    // At least 8 characters, with at least one letter and one number
    return password.length >= 8 &&
           RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(password);
  }

  static bool isValidPhone(String phone) {
    // Korean phone number format
    return RegExp(r'^01[0-9]-?[0-9]{4}-?[0-9]{4}$').hasMatch(phone);
  }

  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return '이메일을 입력해주세요.';
    }
    if (!isValidEmail(email)) {
      return '올바른 이메일 형식을 입력해주세요.';
    }
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return '비밀번호를 입력해주세요.';
    }
    if (password.length < 8) {
      return '비밀번호는 8자 이상이어야 합니다.';
    }
    if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(password)) {
      return '비밀번호는 영문과 숫자를 포함해야 합니다.';
    }
    return null;
  }

  static String? validateName(String? name) {
    if (name == null || name.isEmpty) {
      return '이름을 입력해주세요.';
    }
    if (name.length < 2) {
      return '이름은 2자 이상이어야 합니다.';
    }
    return null;
  }

  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return '전화번호를 입력해주세요.';
    }
    if (!isValidPhone(phone)) {
      return '올바른 전화번호 형식을 입력해주세요.';
    }
    return null;
  }

  static String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return '비밀번호 확인을 입력해주세요.';
    }
    if (password != confirmPassword) {
      return '비밀번호가 일치하지 않습니다.';
    }
    return null;
  }
}