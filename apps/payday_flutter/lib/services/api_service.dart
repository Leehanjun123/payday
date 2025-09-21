import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  late CookieJar _cookieJar;
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  void initialize() {
    _cookieJar = CookieJar();
    _dio = Dio();

    _dio.options = BaseOptions(
      baseUrl: '${dotenv.env['API_URL']}/api/${dotenv.env['API_VERSION']}',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    _dio.interceptors.add(CookieManager(_cookieJar));
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (object) => print(object),
    ));

    // Add token interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await clearToken();
            // Navigate to login screen
          }
          handler.next(error);
        },
      ),
    );
  }

  // Token management
  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<void> setToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'access_token');
  }

  // Auth APIs
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.data['token'] != null) {
        await setToken(response.data['token']);
      }

      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String name,
    String phone,
  ) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'name': name,
        'phone': phone,
      });

      if (response.data['token'] != null) {
        await setToken(response.data['token']);
      }

      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } finally {
      await clearToken();
    }
  }

  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final response = await _dio.post('/auth/refresh');

      if (response.data['token'] != null) {
        await setToken(response.data['token']);
      }

      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Investment APIs
  Future<List<dynamic>> getPortfolios() async {
    try {
      final response = await _dio.get('/investments/portfolios');
      return response.data['portfolios'] ?? [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getPortfolio(String portfolioId) async {
    try {
      final response = await _dio.get('/investments/portfolios/$portfolioId');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createPortfolio(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/investments/portfolios', data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getInvestmentHistory() async {
    try {
      final response = await _dio.get('/investments/history');
      return response.data['history'] ?? [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Prediction APIs
  Future<List<dynamic>> getPredictions() async {
    try {
      final response = await _dio.get('/predictions/predictions');
      return response.data['predictions'] ?? [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getPrediction(String predictionId) async {
    try {
      final response = await _dio.get('/predictions/predictions/$predictionId');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getMarketAnalysis() async {
    try {
      final response = await _dio.get('/predictions/market-analysis');
      return response.data['analysis'] ?? [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getAiInsights() async {
    try {
      final response = await _dio.get('/predictions/ai-insights');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Earnings APIs
  Future<Map<String, dynamic>> getEarningsSummary() async {
    try {
      final response = await _dio.get('/earnings/summary');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getEarningsHistory() async {
    try {
      final response = await _dio.get('/earnings/history');
      return response.data['earnings'] ?? [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getMonthlyEarnings(int year, int month) async {
    try {
      final response = await _dio.get('/earnings/monthly', queryParameters: {
        'year': year,
        'month': month,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getPassiveIncomeStreams() async {
    try {
      final response = await _dio.get('/earnings/passive-income');
      return response.data['streams'] ?? [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  // User APIs
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _dio.get('/user/profile');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/user/profile', data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final response = await _dio.get('/user/dashboard');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getNotifications() async {
    try {
      final response = await _dio.get('/user/notifications');
      return response.data['notifications'] ?? [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _dio.put('/user/notifications/$notificationId/read');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Error handling
  String _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return '네트워크 연결 시간이 초과되었습니다.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final message = error.response?.data['message'] ??
                         error.response?.data['error'] ??
                         '서버 오류가 발생했습니다.';

          switch (statusCode) {
            case 400:
              return message;
            case 401:
              return '인증이 필요합니다. 다시 로그인해주세요.';
            case 403:
              return '접근 권한이 없습니다.';
            case 404:
              return '요청한 리소스를 찾을 수 없습니다.';
            case 422:
              return message;
            case 500:
              return '서버 내부 오류가 발생했습니다.';
            default:
              return message;
          }
        case DioExceptionType.cancel:
          return '요청이 취소되었습니다.';
        case DioExceptionType.connectionError:
          return '네트워크 연결을 확인해주세요.';
        default:
          return '알 수 없는 오류가 발생했습니다.';
      }
    }
    return error.toString();
  }

  // File upload
  Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    String filePath,
    String fileName,
  ) async {
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dio.post(endpoint, data: formData);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  void dispose() {
    _dio.close();
  }
}