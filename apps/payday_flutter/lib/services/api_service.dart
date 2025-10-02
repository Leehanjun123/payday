import 'package:dio/dio.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.example.com',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  Future<Map<String, dynamic>> get(String path) async {
    try {
      final response = await _dio.get(path);
      return response.data;
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(path, data: data);
      return response.data;
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data;
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  Future<Map<String, dynamic>> clearAllEarnings() async {
    try {
      final response = await _dio.delete('/earnings/clear-all');
      return response.data;
    } catch (e) {
      throw Exception('Failed to clear earnings: $e');
    }
  }
}