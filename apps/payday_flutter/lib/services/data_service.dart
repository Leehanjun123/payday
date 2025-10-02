import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/app_config.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  late Dio _dio;

  Future<void> initialize() async {
    _dio = Dio(BaseOptions(
      baseUrl: '${AppConfig.baseUrl}/api/${AppConfig.apiVersion}',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {
        'Content-Type': 'application/json',
      },
      validateStatus: (status) {
        // 401, 404 오류도 정상 응답으로 처리하여 앱이 크래시되지 않도록 함
        return status != null && status < 500;
      },
    ));

    // Auth 인터셉터 추가
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // 임시 API 키 추가 (백엔드와 협의 필요)
        options.headers['X-API-Key'] = 'temporary-api-key';
        handler.next(options);
      },
    ));
  }

  // 네트워크 연결 확인
  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  // 수익 데이터 가져오기 (Railway API 사용)
  Future<List<Map<String, dynamic>>> getEarnings() async {
    try {
      print('Checking network connection...');
      if (await isOnline()) {
        print('Network is online. Fetching from: ${_dio.options.baseUrl}/earnings');
        final response = await _dio.get('/earnings');
        print('Response status: ${response.statusCode}');
        print('Response data: ${response.data}');
        if (response.statusCode == 200 && response.data != null) {
          final responseData = response.data;
          if (responseData is Map && responseData['data'] != null) {
            final dataList = responseData['data'];
            if (dataList is List) {
              final data = dataList.map((item) => Map<String, dynamic>.from(item as Map)).toList();
              print('Parsed ${data.length} earnings');
              return data;
            }
          }
        }
      } else {
        print('Network is offline');
      }
    } catch (e) {
      print('수익 데이터 가져오기 실패: $e');
      print('Error type: ${e.runtimeType}');
      if (e is DioException) {
        print('DioError message: ${e.message}');
        print('DioError response: ${e.response}');
      }
    }
    return [];
  }

  // 수익 추가 (Railway API 사용)
  Future<Map<String, dynamic>?> addEarning({
    required String source,
    required double amount,
    required String description,
  }) async {
    final data = {
      'source': source,
      'amount': amount,
      'description': description,
      'date': DateTime.now().toIso8601String(),
    };

    try {
      if (await isOnline()) {
        final response = await _dio.post('/earnings', data: data);
        if (response.statusCode == 201 || response.statusCode == 200) {
          return response.data['data'] ?? data;
        }
      }
    } catch (e) {
      print('수익 추가 실패: $e');
    }

    return null;
  }

  // 통계 데이터
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      if (await isOnline()) {
        final response = await _dio.get('/statistics');
        if (response.statusCode == 200) {
          return response.data['data'] ?? {};
        }
      }
    } catch (e) {
      print('통계 가져오기 실패: $e');
    }

    // API 실패시 로컬 계산
    final earnings = await getEarnings();

    double totalEarnings = 0.0;
    double monthlyEarnings = 0.0;
    double weeklyEarnings = 0.0;
    double todayEarnings = 0.0;
    Map<String, double> earningsBySource = {};

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(Duration(days: 7));
    final monthAgo = DateTime(now.year, now.month - 1, now.day);

    for (var earning in earnings) {
      // 안전한 amount 변환
      double amount = 0.0;
      if (earning['amount'] != null) {
        if (earning['amount'] is num) {
          amount = (earning['amount'] as num).toDouble();
        }
      }
      final source = earning['source'] as String? ?? 'Unknown';

      // 날짜 파싱
      DateTime? date;
      if (earning['date'] != null) {
        try {
          date = DateTime.parse(earning['date']);
        } catch (e) {
          date = now;
        }
      }

      // 총 수익
      totalEarnings += amount;

      // 소스별 수익
      earningsBySource[source] = (earningsBySource[source] ?? 0.0) + amount;

      if (date != null) {
        // 오늘 수익
        if (date.year == today.year &&
            date.month == today.month &&
            date.day == today.day) {
          todayEarnings += amount;
        }

        // 주간 수익
        if (date.isAfter(weekAgo)) {
          weeklyEarnings += amount;
        }

        // 월간 수익
        if (date.isAfter(monthAgo)) {
          monthlyEarnings += amount;
        }
      }
    }

    return {
      'totalEarnings': totalEarnings,
      'monthlyEarnings': monthlyEarnings,
      'weeklyEarnings': weeklyEarnings,
      'todayEarnings': todayEarnings,
      'earningsBySource': earningsBySource,
    };
  }

  // === 추가 호환성 메서드들 (구 DatabaseService API) ===

  // 수익 관련 메서드들
  Future<double> getTodayEarnings() async {
    final stats = await getStatistics();
    return stats['todayEarnings'] ?? 0.0;
  }

  Future<double> getWeeklyEarnings() async {
    final stats = await getStatistics();
    return stats['weeklyEarnings'] ?? 0.0;
  }

  Future<double> getMonthlyEarnings() async {
    final stats = await getStatistics();
    return stats['monthlyEarnings'] ?? 0.0;
  }

  Future<List<Map<String, dynamic>>> getRecentEarnings({int limit = 10}) async {
    final earnings = await getEarnings();
    // 날짜 순으로 정렬 (최신순)
    earnings.sort((a, b) {
      final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime.now();
      return dateB.compareTo(dateA);
    });
    return earnings.take(limit).toList();
  }

  // 목표 데이터 관련
  Future<List<Map<String, dynamic>>> getAllGoals() async {
    return await getGoals();
  }

  Future<List<Map<String, dynamic>>> getGoals() async {
    try {
      if (await isOnline()) {
        final response = await _dio.get('/goals');
        if (response.statusCode == 200) {
          return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        }
      }
    } catch (e) {
      print('목표 데이터 가져오기 실패: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> createGoal(Map<String, dynamic> goalData) async {
    try {
      if (await isOnline()) {
        final response = await _dio.post('/goals', data: goalData);
        if (response.statusCode == 201) {
          return response.data['data'];
        }
      }
    } catch (e) {
      print('목표 생성 실패: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> updateGoal(String id, Map<String, dynamic> goalData) async {
    try {
      if (await isOnline()) {
        final response = await _dio.put('/goals/$id', data: goalData);
        if (response.statusCode == 200) {
          return response.data['data'];
        }
      }
    } catch (e) {
      print('목표 업데이트 실패: $e');
    }
    return null;
  }

  Future<bool> deleteGoal(String id) async {
    try {
      if (await isOnline()) {
        final response = await _dio.delete('/goals/$id');
        if (response.statusCode == 200) {
          return true;
        }
      }
    } catch (e) {
      print('목표 삭제 실패: $e');
    }
    return false;
  }

  // 수익 데이터 관련 (추가 메서드)
  Future<List<Map<String, dynamic>>> getAllIncomes() async {
    return await getEarnings();
  }

  Future<int> addIncome({
    required String type,
    required String title,
    required double amount,
    String? description,
    DateTime? date,
  }) async {
    final result = await addEarning(
      source: title,
      amount: amount,
      description: description ?? '',
    );
    return result?['id'] ?? 0;
  }

  Future<List<Map<String, dynamic>>> getIncomesByDateRange(DateTime start, DateTime end) async {
    // API 엔드포인트가 없으므로 전체 데이터를 가져와서 필터링
    final allIncomes = await getAllIncomes();
    return allIncomes.where((income) {
      final dateStr = income['date'];
      if (dateStr == null) return false;
      final date = DateTime.tryParse(dateStr.toString());
      if (date == null) return false;
      return date.isAfter(start.subtract(Duration(days: 1))) &&
             date.isBefore(end.add(Duration(days: 1)));
    }).toList();
  }

  // 설정 관련
  Future<dynamic> getSetting(String key) async {
    try {
      if (await isOnline()) {
        final response = await _dio.get('/settings');
        if (response.statusCode == 200) {
          final data = response.data['data'] as Map<String, dynamic>;
          return data[key];
        }
      }
    } catch (e) {
      print('설정 가져오기 실패: $e');
    }

    // 기본값 반환
    switch (key) {
      case 'notifications':
        return 'true';
      case 'darkMode':
        return 'false';
      case 'currency':
        return 'KRW';
      case 'monthlyGoal':
        return 1000000.0;
      default:
        return null;
    }
  }

  Future<void> saveSetting(String key, dynamic value) async {
    try {
      if (await isOnline()) {
        await _dio.put('/settings', data: {key: value});
      }
    } catch (e) {
      print('설정 저장 실패: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserSettings() async {
    try {
      if (await isOnline()) {
        final response = await _dio.get('/settings');
        if (response.statusCode == 200) {
          return response.data['data'] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      print('사용자 설정 가져오기 실패: $e');
    }

    return {
      'notifications': true,
      'darkMode': false,
      'currency': 'KRW',
      'monthlyGoal': 0.0,
    };
  }

  // 추가 수익 관련 메서드들
  Future<List<Map<String, dynamic>>> getIncomesByType(String type) async {
    final allIncomes = await getAllIncomes();
    return allIncomes.where((income) => income['type'] == type).toList();
  }

  Future<double> getTotalIncome() async {
    final allIncomes = await getAllIncomes();
    return allIncomes.fold<double>(0.0, (sum, income) {
      final amount = income['amount'];
      if (amount == null) return sum;
      return sum + (amount is num ? amount.toDouble() : 0.0);
    });
  }

  Future<double> getMonthlyIncome(int year, int month) async {
    final allIncomes = await getAllIncomes();
    return allIncomes.where((income) {
      if (income['date'] == null) return false;
      final date = DateTime.parse(income['date']);
      return date.year == year && date.month == month;
    }).fold<double>(0.0, (sum, income) {
      final amount = income['amount'];
      if (amount == null) return sum;
      return sum + (amount is num ? amount.toDouble() : 0.0);
    });
  }

  Future<Map<String, double>> getIncomeByTypes() async {
    final allIncomes = await getAllIncomes();
    final Map<String, double> typeAmounts = {};

    for (final income in allIncomes) {
      final type = income['type'] as String? ?? 'other';
      final amount = income['amount'];
      final doubleAmount = amount is num ? amount.toDouble() : 0.0;
      typeAmounts[type] = (typeAmounts[type] ?? 0.0) + doubleAmount;
    }

    return typeAmounts;
  }

  Future<int> updateIncome(int id, {
    String? title,
    double? amount,
    String? description,
    DateTime? date,
  }) async {
    final updateData = <String, dynamic>{};
    if (title != null) updateData['source'] = title;
    if (amount != null) updateData['amount'] = amount;
    if (description != null) updateData['description'] = description;
    if (date != null) updateData['date'] = date.toIso8601String();

    try {
      if (await isOnline()) {
        final response = await _dio.put('/earnings/${id.toString()}', data: updateData);
        if (response.statusCode == 200) {
          return 1;
        }
      }
    } catch (e) {
      print('수익 업데이트 실패: $e');
    }
    return 0;
  }

  Future<int> deleteIncome(int id) async {
    try {
      if (await isOnline()) {
        final response = await _dio.delete('/earnings/${id.toString()}');
        if (response.statusCode == 200) {
          return 1;
        }
      }
    } catch (e) {
      print('수익 삭제 실패: $e');
    }
    return 0;
  }

  // 목표 관련 추가 메서드들
  Future<Map<String, dynamic>?> addGoal({
    required String title,
    required double targetAmount,
    DateTime? deadline,
    String? description,
  }) async {
    final goalData = {
      'title': title,
      'targetAmount': targetAmount,
      'deadline': deadline?.toIso8601String(),
      'description': description,
      'currentAmount': 0.0,
      'createdAt': DateTime.now().toIso8601String(),
    };

    return await createGoal(goalData);
  }

  Future<bool> updateGoalProgress(String id, double currentAmount) async {
    try {
      if (await isOnline()) {
        final response = await _dio.put('/goals/$id/progress', data: {
          'currentAmount': currentAmount,
        });
        if (response.statusCode == 200) {
          return true;
        }
      }
    } catch (e) {
      print('목표 진행률 업데이트 실패: $e');
    }
    return false;
  }

  // 데이터베이스 호환성을 위한 getter
  Future<dynamic> get database async {
    // 호환성을 위해 this 자체를 반환
    return this;
  }
}