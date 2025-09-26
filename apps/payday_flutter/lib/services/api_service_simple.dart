import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;
  static const String baseUrl = 'http://192.168.45.250:3000/api/v1';
  String? _accessToken;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        handler.next(options);
      },
    ));
  }

  Future<void> _saveToken(String token) async {
    _accessToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      print('로그인 응답: ${response.data}');

      // 백엔드가 'token'으로 반환
      if (response.data['token'] != null) {
        await _saveToken(response.data['token']);
        print('토큰 저장 완료: ${response.data['token']}');
      } else {
        print('응답에 token이 없음!');
      }

      return response.data;
    } catch (e) {
      throw Exception('로그인 실패: $e');
    }
  }

  Future<Map<String, dynamic>> getUserBalance() async {
    try {
      print('잔액 조회 시작, 현재 토큰: $_accessToken');
      final response = await _dio.get('/earnings/balance');
      print('잔액 조회 성공: ${response.data}');
      return response.data;
    } catch (e) {
      print('잔액 조회 실패: $e');
      throw Exception('잔액 조회 실패: $e');
    }
  }

  Future<Map<String, dynamic>> processAdReward(String adUnit, String rewardType) async {
    try {
      final response = await _dio.post('/rewards/ad', data: {
        'adUnitId': adUnit,
        'rewardType': rewardType,
        'amount': 0.002,
      });
      return response.data;
    } catch (e) {
      throw Exception('광고 보상 처리 실패: $e');
    }
  }

  Future<Map<String, dynamic>> processDailyBonus() async {
    try {
      final response = await _dio.post('/rewards/daily-bonus');
      return response.data;
    } catch (e) {
      throw Exception('일일 보너스 처리 실패: $e');
    }
  }
}