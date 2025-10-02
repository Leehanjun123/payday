import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // 기본 저장/불러오기
  Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  Future<void> setInt(String key, int value) async {
    await _prefs?.setInt(key, value);
  }

  Future<void> setDouble(String key, double value) async {
    await _prefs?.setDouble(key, value);
  }

  Future<void> setBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  String? getString(String key) => _prefs?.getString(key);
  int? getInt(String key) => _prefs?.getInt(key);
  double? getDouble(String key) => _prefs?.getDouble(key);
  bool? getBool(String key) => _prefs?.getBool(key);

  // JSON 저장/불러오기
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    await setString(key, json.encode(value));
  }

  Map<String, dynamic>? getJson(String key) {
    final jsonString = getString(key);
    if (jsonString != null) {
      try {
        return json.decode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        print('JSON 파싱 오류: $e');
        return null;
      }
    }
    return null;
  }

  // 리스트 저장/불러오기
  Future<void> setJsonList(String key, List<Map<String, dynamic>> list) async {
    await setString(key, json.encode(list));
  }

  List<Map<String, dynamic>> getJsonList(String key) {
    final jsonString = getString(key);
    if (jsonString != null) {
      try {
        final decoded = json.decode(jsonString);
        if (decoded is List) {
          return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        }
      } catch (e) {
        print('JSON 리스트 파싱 오류: $e');
      }
    }
    return [];
  }

  // 캐시 관련 전용 메서드들
  Future<double> getCashBalance() async {
    return getDouble('cash_balance') ?? 0.0;
  }

  Future<void> setCashBalance(double balance) async {
    await setDouble('cash_balance', balance);
  }

  Future<double> getTodayEarnings() async {
    return getDouble('today_earnings') ?? 0.0;
  }

  Future<void> setTodayEarnings(double earnings) async {
    await setDouble('today_earnings', earnings);
  }

  Future<List<Map<String, dynamic>>> getTransactionHistory() async {
    return getJsonList('transaction_history');
  }

  Future<void> addTransaction(Map<String, dynamic> transaction) async {
    final transactions = getTransactionHistory();
    transactions.insert(0, transaction); // 최신순으로 추가

    // 최대 1000개까지만 저장
    if (transactions.length > 1000) {
      transactions.removeRange(1000, transactions.length);
    }

    await setJsonList('transaction_history', transactions);
  }

  Future<void> setTransactionHistory(List<Map<String, dynamic>> transactions) async {
    await setJsonList('transaction_history', transactions);
  }

  // 통계 관련
  Future<Map<String, double>> getEarningsBySource() async {
    final json = getJson('earnings_by_source');
    if (json != null) {
      return json.map((key, value) => MapEntry(key, (value as num).toDouble()));
    }
    return {};
  }

  Future<void> setEarningsBySource(Map<String, double> earnings) async {
    await setJson('earnings_by_source', earnings);
  }

  Future<double> getTotalEarned() async {
    return getDouble('total_earned') ?? 0.0;
  }

  Future<void> setTotalEarned(double total) async {
    await setDouble('total_earned', total);
  }

  // 일일 출석 관련
  Future<int> getAttendanceStreak() async {
    return getInt('attendance_streak') ?? 0;
  }

  Future<void> setAttendanceStreak(int streak) async {
    await setInt('attendance_streak', streak);
  }

  Future<String?> getLastAttendanceDate() async {
    return getString('last_attendance_date');
  }

  Future<void> setLastAttendanceDate(String date) async {
    await setString('last_attendance_date', date);
  }

  // 수익 수단별 일일 제한 체크
  Future<int> getDailyEarningCount(String source) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return getInt('daily_${source}_$today') ?? 0;
  }

  Future<void> incrementDailyEarningCount(String source) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final current = getDailyEarningCount(source);
    await setInt('daily_${source}_$today', current + 1);
  }

  // 일일 리셋 체크
  Future<void> checkDailyReset() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastReset = getString('last_daily_reset');

    if (lastReset != today) {
      // 일일 수익 리셋
      await setTodayEarnings(0.0);
      await setString('last_daily_reset', today);

      // 일일 제한 카운터들 정리 (어제 것들 삭제)
      await _cleanupOldDailyCounters();
    }
  }

  Future<void> _cleanupOldDailyCounters() async {
    final keys = _prefs?.getKeys() ?? {};
    final today = DateTime.now().toIso8601String().split('T')[0];

    for (final key in keys) {
      if (key.startsWith('daily_') && !key.endsWith(today)) {
        await _prefs?.remove(key);
      }
    }
  }

  // 데이터 초기화
  Future<void> clearAllData() async {
    await _prefs?.clear();
  }

  Future<void> clearCashData() async {
    final keys = [
      'cash_balance',
      'today_earnings',
      'transaction_history',
      'earnings_by_source',
      'total_earned',
    ];

    for (final key in keys) {
      await _prefs?.remove(key);
    }
  }
}