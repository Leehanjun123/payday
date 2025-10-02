import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'local_storage_service.dart';

class RailwayService {
  static final RailwayService _instance = RailwayService._internal();
  factory RailwayService() => _instance;
  RailwayService._internal();

  final LocalStorageService _localStorage = LocalStorageService();

  // Railway 데이터베이스 연결 설정
  static const String _baseUrl = 'YOUR_RAILWAY_API_URL'; // Railway API URL
  static const String _apiKey = 'YOUR_API_KEY'; // API 키

  String? _userId;
  String? _authToken;

  // 공통 HTTP 헤더
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_apiKey',
    if (_authToken != null) 'X-User-Token': _authToken!,
  };

  // 초기화
  Future<void> initialize() async {
    await _localStorage.initialize();
    _userId = _localStorage.getString('user_id');
    _authToken = _localStorage.getString('auth_token');
  }

  // 사용자 등록/로그인
  Future<Map<String, dynamic>?> authenticateUser({
    required String deviceId,
    String? email,
    String? phone,
    String? firebaseUid,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: _headers,
        body: json.encode({
          'device_id': deviceId,
          'email': email,
          'phone': phone,
          'firebase_uid': firebaseUid,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _userId = data['user']['id'];
        _authToken = data['auth_token'];

        // 로컬에 저장
        await _localStorage.setString('user_id', _userId!);
        await _localStorage.setString('auth_token', _authToken!);

        return data;
      } else {
        print('인증 실패: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('인증 오류: $e');
      return null;
    }
  }

  // 사용자 잔액 조회
  Future<double?> getUserBalance() async {
    if (_userId == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$_userId/balance'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['balance'] as num).toDouble();
      }
    } catch (e) {
      print('잔액 조회 오류: $e');
    }
    return null;
  }

  // 수익 기록 및 검증
  Future<bool> recordEarning({
    required String earningMethod,
    required double amount,
    required String description,
    Map<String, dynamic>? metadata,
    String? adUnitId,
    String? adImpressionId,
  }) async {
    if (_userId == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/transactions'),
        headers: _headers,
        body: json.encode({
          'user_id': _userId,
          'type': 'earn',
          'earning_method': earningMethod,
          'amount': amount,
          'description': description,
          'metadata': metadata ?? {},
          'ad_unit_id': adUnitId,
          'ad_impression_id': adImpressionId,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        print('💰 서버에 수익 기록됨: ${data['transaction']['id']}');
        return true;
      } else {
        print('수익 기록 실패: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('수익 기록 오류: $e');
      return false;
    }
  }

  // AdMob 수익 검증
  Future<bool> verifyAdRevenue({
    required String adUnitId,
    required String impressionId,
    required double revenueUsd,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/admob/verify'),
        headers: _headers,
        body: json.encode({
          'user_id': _userId,
          'ad_unit_id': adUnitId,
          'impression_id': impressionId,
          'revenue_usd': revenueUsd,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['verified'] == true) {
          // 검증된 수익을 사용자 계정에 적립
          await recordEarning(
            earningMethod: 'ad_view',
            amount: data['user_reward_krw'],
            description: '검증된 AdMob 광고 수익',
            adUnitId: adUnitId,
            adImpressionId: impressionId,
          );
          return true;
        }
      }
    } catch (e) {
      print('AdMob 수익 검증 오류: $e');
    }
    return false;
  }

  // 일일 제한 체크
  Future<bool> checkDailyLimit(String earningMethod) async {
    if (_userId == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$_userId/daily-limits/$earningMethod'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['can_earn'] == true;
      }
    } catch (e) {
      print('일일 제한 체크 오류: $e');
    }
    return false;
  }

  // 거래 내역 동기화
  Future<List<Map<String, dynamic>>> syncTransactions({
    int limit = 50,
    DateTime? since,
  }) async {
    if (_userId == null) return [];

    try {
      String url = '$_baseUrl/users/$_userId/transactions?limit=$limit';
      if (since != null) {
        url += '&since=${since.toIso8601String()}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['transactions']);
      }
    } catch (e) {
      print('거래 내역 동기화 오류: $e');
    }
    return [];
  }

  // 출금 요청
  Future<String?> requestWithdrawal({
    required double amount,
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
    required String pin,
  }) async {
    if (_userId == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/withdrawals'),
        headers: _headers,
        body: json.encode({
          'user_id': _userId,
          'amount': amount,
          'bank_name': bankName,
          'account_number': accountNumber,
          'account_holder_name': accountHolderName,
          'pin': pin,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['withdrawal_request']['id'];
      } else {
        print('출금 요청 실패: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('출금 요청 오류: $e');
    }
    return null;
  }

  // 출금 내역 조회
  Future<List<Map<String, dynamic>>> getWithdrawals() async {
    if (_userId == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$_userId/withdrawals'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['withdrawals']);
      }
    } catch (e) {
      print('출금 내역 조회 오류: $e');
    }
    return [];
  }

  // 추천인 코드 생성
  Future<String?> generateReferralCode() async {
    if (_userId == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/$_userId/referral-code'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['referral_code'];
      }
    } catch (e) {
      print('추천인 코드 생성 오류: $e');
    }
    return null;
  }

  // 추천인 등록
  Future<bool> registerReferral(String referralCode) async {
    if (_userId == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/$_userId/referral'),
        headers: _headers,
        body: json.encode({
          'referral_code': referralCode,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('추천인 등록 오류: $e');
      return false;
    }
  }

  // 시스템 설정 조회
  Future<Map<String, dynamic>?> getSystemSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/system/settings'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['settings'];
      }
    } catch (e) {
      print('시스템 설정 조회 오류: $e');
    }
    return null;
  }

  // 로컬 데이터와 서버 동기화
  Future<void> syncWithLocal() async {
    try {
      // 1. 서버에서 최신 잔액 가져오기
      final serverBalance = await getUserBalance();
      if (serverBalance != null) {
        await _localStorage.setDouble('server_balance', serverBalance);
      }

      // 2. 로컬 거래 내역을 서버로 업로드
      await _uploadLocalTransactions();

      // 3. 서버 거래 내역을 로컬로 다운로드
      await _downloadServerTransactions();

      print('✅ 서버 동기화 완료');
    } catch (e) {
      print('동기화 오류: $e');
    }
  }

  // 로컬 거래 내역 서버 업로드
  Future<void> _uploadLocalTransactions() async {
    final localTransactions = await _localStorage.getJsonList('pending_transactions');

    for (final transaction in localTransactions) {
      final success = await recordEarning(
        earningMethod: transaction['source'] ?? 'unknown',
        amount: (transaction['amount'] as num).toDouble(),
        description: transaction['description'] ?? '',
        metadata: transaction['metadata'],
      );

      if (success) {
        // 업로드 성공한 거래는 로컬에서 제거
        localTransactions.remove(transaction);
      }
    }

    await _localStorage.setJsonList('pending_transactions', localTransactions);
  }

  // 서버 거래 내역 로컬 다운로드
  Future<void> _downloadServerTransactions() async {
    final lastSync = _localStorage.getString('last_sync_date');
    DateTime? sinceDate;

    if (lastSync != null) {
      sinceDate = DateTime.parse(lastSync);
    }

    final serverTransactions = await syncTransactions(since: sinceDate);

    if (serverTransactions.isNotEmpty) {
      // 서버 거래 내역을 로컬에 저장
      final localTransactions = await _localStorage.getJsonList('transaction_history');
      localTransactions.addAll(serverTransactions);

      // 중복 제거 및 최신순 정렬
      final uniqueTransactions = <String, Map<String, dynamic>>{};
      for (final transaction in localTransactions) {
        final id = transaction['id'] ?? transaction['timestamp'];
        uniqueTransactions[id.toString()] = transaction;
      }

      final sortedTransactions = uniqueTransactions.values.toList()
        ..sort((a, b) => DateTime.parse(b['created_at'] ?? b['timestamp'])
            .compareTo(DateTime.parse(a['created_at'] ?? a['timestamp'])));

      await _localStorage.setJsonList('transaction_history', sortedTransactions.take(1000).toList());
      await _localStorage.setString('last_sync_date', DateTime.now().toIso8601String());
    }
  }

  // 오프라인 모드 지원
  Future<void> addPendingTransaction(Map<String, dynamic> transaction) async {
    final pendingTransactions = await _localStorage.getJsonList('pending_transactions');
    pendingTransactions.add({
      ...transaction,
      'pending_upload': true,
      'created_offline': DateTime.now().toIso8601String(),
    });
    await _localStorage.setJsonList('pending_transactions', pendingTransactions);
  }

  // 연결 상태 확인
  Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 로그아웃
  Future<void> logout() async {
    _userId = null;
    _authToken = null;
    await _localStorage.setString('user_id', '');
    await _localStorage.setString('auth_token', '');
  }

  // Getters
  String? get userId => _userId;
  bool get isAuthenticated => _userId != null && _authToken != null;
}