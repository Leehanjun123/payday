import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final Dio _dio = Dio(
    BaseOptions(baseUrl: 'http://192.168.45.250:3000/api/auth'),
  );
  final _secureStorage = const FlutterSecureStorage();

  // Private constants for storage keys
  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';

  Future<bool> register(String email, String password, String name) async {
    try {
      final response = await _dio.post('/register', data: {
        'email': email,
        'password': password,
        'name': name,
      });

      if (response.statusCode == 201 && response.data['accessToken'] != null) {
        await _saveTokens(
          accessToken: response.data['accessToken'],
          refreshToken: response.data['refreshToken'],
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Registration failed: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await _dio.post('/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 && response.data['accessToken'] != null) {
        await _saveTokens(
          accessToken: response.data['accessToken'],
          refreshToken: response.data['refreshToken'],
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Login failed: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> _saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
  }
}

class User {
  final String id;
  final String email;
  final String? token;

  User({
    required this.id,
    required this.email,
    this.token,
  });
}