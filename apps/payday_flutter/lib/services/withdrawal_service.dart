import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'local_storage_service.dart';
import 'railway_service.dart';
import 'auth_service.dart';
import 'cloud_cash_service.dart';

/// 실제 현금 출금 서비스
/// 은행 연동 및 실시간 출금 처리
class WithdrawalService {
  static final WithdrawalService _instance = WithdrawalService._internal();
  factory WithdrawalService() => _instance;
  WithdrawalService._internal();

  final LocalStorageService _localStorage = LocalStorageService();
  final RailwayService _railway = RailwayService();
  final AuthService _auth = AuthService();
  final CloudCashService _cashService = CloudCashService();

  // 출금 설정
  static const double _minimumWithdrawal = 10000.0; // 최소 10,000원
  static const double _maximumWithdrawal = 1000000.0; // 최대 100만원
  static const double _feePercentage = 0.03; // 3% 수수료
  static const int _processingDays = 3; // 처리 소요일

  // 은행 API 설정 (실제 은행 연동)
  static const String _bankApiUrl = 'https://api.openbanking.or.kr/v2.0';
  static const String _bankApiKey = 'YOUR_BANK_API_KEY';

  List<Map<String, dynamic>> _withdrawalHistory = [];
  Map<String, dynamic>? _currentRequest;

  // 초기화
  Future<void> initialize() async {
    await _localStorage.initialize();
    await _railway.initialize();
    await _loadWithdrawalHistory();
  }

  // 출금 내역 로드
  Future<void> _loadWithdrawalHistory() async {
    try {
      _withdrawalHistory = await _localStorage.getJsonList('withdrawal_history');

      // 서버에서도 동기화
      if (_railway.isAuthenticated) {
        final serverHistory = await _railway.getWithdrawals();
        _withdrawalHistory.addAll(serverHistory);

        // 중복 제거 및 최신순 정렬
        final uniqueWithdrawals = <String, Map<String, dynamic>>{};
        for (final withdrawal in _withdrawalHistory) {
          final id = withdrawal['id'] ?? withdrawal['created_at'];
          uniqueWithdrawals[id.toString()] = withdrawal;
        }

        _withdrawalHistory = uniqueWithdrawals.values.toList()
          ..sort((a, b) => DateTime.parse(b['created_at'] ?? b['timestamp'])
              .compareTo(DateTime.parse(a['created_at'] ?? a['timestamp'])));

        await _localStorage.setJsonList('withdrawal_history', _withdrawalHistory);
      }

      print('📜 출금 내역 로드 완료: ${_withdrawalHistory.length}건');
    } catch (e) {
      print('출금 내역 로드 실패: $e');
    }
  }

  // 출금 가능 여부 확인
  Future<Map<String, dynamic>> checkWithdrawalEligibility() async {
    final currentBalance = _cashService.totalBalance;
    final userProfile = _auth.userProfile;

    final result = {
      'canWithdraw': false,
      'reason': '',
      'minimumAmount': _minimumWithdrawal,
      'maximumAmount': _maximumWithdrawal,
      'currentBalance': currentBalance,
      'availableAmount': 0.0,
      'feePercentage': _feePercentage,
      'processingDays': _processingDays,
    };

    // 1. 로그인 확인
    if (!_auth.isAuthenticated) {
      result['reason'] = '로그인이 필요합니다';
      return result;
    }

    // 2. 게스트 계정 확인
    if (_auth.isGuest) {
      result['reason'] = '게스트 계정은 출금할 수 없습니다. 회원가입을 해주세요';
      return result;
    }

    // 3. 최소 금액 확인
    if (currentBalance < _minimumWithdrawal) {
      result['reason'] = '최소 출금 금액은 ${_minimumWithdrawal.toStringAsFixed(0)}원입니다';
      return result;
    }

    // 4. 계좌 정보 확인
    final bankAccount = await _getBankAccount();
    if (bankAccount == null) {
      result['reason'] = '계좌 정보를 먼저 등록해주세요';
      return result;
    }

    // 5. PIN 설정 확인
    if (!await _hasPinSet()) {
      result['reason'] = '출금 PIN을 먼저 설정해주세요';
      return result;
    }

    // 6. 처리 중인 출금 확인
    if (await _hasPendingWithdrawal()) {
      result['reason'] = '처리 중인 출금 요청이 있습니다';
      return result;
    }

    // 출금 가능
    result['canWithdraw'] = true;
    result['availableAmount'] = currentBalance > _maximumWithdrawal
        ? _maximumWithdrawal
        : currentBalance;

    return result;
  }

  // 출금 수수료 계산
  Map<String, double> calculateWithdrawalFee(double amount) {
    final fee = amount * _feePercentage;
    final netAmount = amount - fee;

    return {
      'requestAmount': amount,
      'fee': fee,
      'netAmount': netAmount,
      'feePercentage': _feePercentage,
    };
  }

  // 출금 요청 생성
  Future<String?> createWithdrawalRequest({
    required double amount,
    required String pin,
    String? memo,
  }) async {
    try {
      // 1. 자격 확인
      final eligibility = await checkWithdrawalEligibility();
      if (!eligibility['canWithdraw']) {
        throw Exception(eligibility['reason']);
      }

      // 2. 금액 유효성 검사
      if (amount < _minimumWithdrawal || amount > _maximumWithdrawal) {
        throw Exception('출금 금액이 유효하지 않습니다');
      }

      if (amount > _cashService.totalBalance) {
        throw Exception('잔액이 부족합니다');
      }

      // 3. PIN 검증
      if (!await _auth.verifyWithdrawalPin(pin)) {
        throw Exception('출금 PIN이 올바르지 않습니다');
      }

      // 4. 계좌 정보 조회
      final bankAccount = await _getBankAccount();
      if (bankAccount == null) {
        throw Exception('계좌 정보를 찾을 수 없습니다');
      }

      // 5. 수수료 계산
      final feeCalculation = calculateWithdrawalFee(amount);

      // 6. 서버에 출금 요청
      final withdrawalId = await _railway.requestWithdrawal(
        amount: amount,
        bankName: bankAccount['bank_name'],
        accountNumber: bankAccount['account_number'],
        accountHolderName: bankAccount['account_holder_name'],
        pin: pin,
      );

      if (withdrawalId == null) {
        throw Exception('출금 요청 처리 중 오류가 발생했습니다');
      }

      // 7. 로컬에 출금 요청 저장
      final withdrawalRequest = {
        'id': withdrawalId,
        'amount': amount,
        'fee': feeCalculation['fee'],
        'net_amount': feeCalculation['netAmount'],
        'bank_name': bankAccount['bank_name'],
        'account_number': _maskAccountNumber(bankAccount['account_number']),
        'account_holder_name': bankAccount['account_holder_name'],
        'status': 'pending',
        'memo': memo,
        'created_at': DateTime.now().toIso8601String(),
        'estimated_completion': DateTime.now()
            .add(Duration(days: _processingDays))
            .toIso8601String(),
      };

      _withdrawalHistory.insert(0, withdrawalRequest);
      await _localStorage.setJsonList('withdrawal_history', _withdrawalHistory);
      _currentRequest = withdrawalRequest;

      // 8. 캐시 서비스에 출금 반영
      await _cashService.requestWithdrawal(
        amount: amount,
        bankName: bankAccount['bank_name'],
        accountNumber: bankAccount['account_number'],
        accountHolderName: bankAccount['account_holder_name'],
        pin: pin,
      );

      print('💸 출금 요청 생성: ${amount.toStringAsFixed(0)}원 → $withdrawalId');
      return withdrawalId;

    } catch (e) {
      print('출금 요청 실패: $e');
      rethrow;
    }
  }

  // 출금 상태 확인 및 업데이트
  Future<Map<String, dynamic>?> checkWithdrawalStatus(String withdrawalId) async {
    try {
      // 서버에서 최신 상태 조회
      final serverWithdrawals = await _railway.getWithdrawals();
      final serverWithdrawal = serverWithdrawals.firstWhere(
        (w) => w['id'] == withdrawalId,
        orElse: () => {},
      );

      if (serverWithdrawal.isNotEmpty) {
        // 로컬 데이터 업데이트
        final localIndex = _withdrawalHistory.indexWhere((w) => w['id'] == withdrawalId);
        if (localIndex != -1) {
          _withdrawalHistory[localIndex] = serverWithdrawal;
          await _localStorage.setJsonList('withdrawal_history', _withdrawalHistory);
        }

        return serverWithdrawal;
      }

      return null;
    } catch (e) {
      print('출금 상태 확인 실패: $e');
      return null;
    }
  }

  // 실제 은행 송금 처리 (관리자용)
  Future<bool> processWithdrawal(String withdrawalId) async {
    try {
      final withdrawal = _withdrawalHistory.firstWhere(
        (w) => w['id'] == withdrawalId,
        orElse: () => {},
      );

      if (withdrawal.isEmpty) {
        throw Exception('출금 요청을 찾을 수 없습니다');
      }

      // 1. 은행 API를 통한 실제 송금
      final transferResult = await _executebankTransfer(withdrawal);

      if (transferResult['success'] == true) {
        // 2. 서버에 처리 완료 알림
        await _updateWithdrawalStatus(
          withdrawalId: withdrawalId,
          status: 'completed',
          transactionId: transferResult['transaction_id'],
        );

        print('✅ 출금 처리 완료: $withdrawalId');
        return true;
      } else {
        // 3. 실패 시 상태 업데이트
        await _updateWithdrawalStatus(
          withdrawalId: withdrawalId,
          status: 'failed',
          adminNotes: transferResult['error'],
        );

        print('❌ 출금 처리 실패: ${transferResult['error']}');
        return false;
      }

    } catch (e) {
      print('출금 처리 오류: $e');
      return false;
    }
  }

  // 실제 은행 송금 실행
  Future<Map<String, dynamic>> _executebankTransfer(Map<String, dynamic> withdrawal) async {
    try {
      // 오픈뱅킹 API를 통한 실제 송금
      final response = await http.post(
        Uri.parse('$_bankApiUrl/transfer'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_bankApiKey',
        },
        body: json.encode({
          'req_list': [{
            'tran_no': '${DateTime.now().millisecondsSinceEpoch}',
            'bank_tran_id': withdrawal['id'],
            'fintech_use_num': withdrawal['fintech_use_num'], // 계좌 고유번호
            'tran_amt': withdrawal['net_amount'].toString(),
            'req_client_name': withdrawal['account_holder_name'],
            'req_client_num': withdrawal['account_number'],
            'transfer_purpose': 'TR', // 송금
            'recv_client_name': withdrawal['account_holder_name'],
            'recv_client_bank_code': _getBankCode(withdrawal['bank_name']),
            'recv_client_account_num': withdrawal['account_number'],
          }],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['rsp_code'] == 'A0000') {
          return {
            'success': true,
            'transaction_id': data['res_list'][0]['bank_tran_id'],
            'bank_tran_date': data['res_list'][0]['bank_tran_date'],
          };
        } else {
          return {
            'success': false,
            'error': data['rsp_message'],
          };
        }
      } else {
        return {
          'success': false,
          'error': '은행 API 호출 실패: ${response.statusCode}',
        };
      }

    } catch (e) {
      return {
        'success': false,
        'error': '송금 처리 중 오류: $e',
      };
    }
  }

  // 출금 상태 업데이트
  Future<void> _updateWithdrawalStatus({
    required String withdrawalId,
    required String status,
    String? transactionId,
    String? adminNotes,
  }) async {
    // 로컬 업데이트
    final localIndex = _withdrawalHistory.indexWhere((w) => w['id'] == withdrawalId);
    if (localIndex != -1) {
      _withdrawalHistory[localIndex]['status'] = status;
      _withdrawalHistory[localIndex]['updated_at'] = DateTime.now().toIso8601String();

      if (transactionId != null) {
        _withdrawalHistory[localIndex]['transaction_id'] = transactionId;
        _withdrawalHistory[localIndex]['processed_at'] = DateTime.now().toIso8601String();
      }

      if (adminNotes != null) {
        _withdrawalHistory[localIndex]['admin_notes'] = adminNotes;
      }

      await _localStorage.setJsonList('withdrawal_history', _withdrawalHistory);
    }

    // 서버 업데이트는 Railway API를 통해 처리
  }

  // 헬퍼 메서드들
  Future<Map<String, dynamic>?> _getBankAccount() async {
    return _localStorage.getJson('bank_account');
  }

  Future<bool> _hasPinSet() async {
    return _localStorage.getString('withdrawal_pin_hash') != null;
  }

  Future<bool> _hasPendingWithdrawal() async {
    return _withdrawalHistory.any((w) =>
        w['status'] == 'pending' || w['status'] == 'processing');
  }

  String _maskAccountNumber(String accountNumber) {
    if (accountNumber.length <= 4) return accountNumber;
    final start = accountNumber.substring(0, 3);
    final end = accountNumber.substring(accountNumber.length - 3);
    final middle = '*' * (accountNumber.length - 6);
    return '$start$middle$end';
  }

  String _getBankCode(String bankName) {
    final bankCodes = {
      '국민은행': '004',
      '신한은행': '088',
      '우리은행': '020',
      '하나은행': '081',
      'NH농협은행': '011',
      'SC제일은행': '023',
      '케이뱅크': '089',
      '카카오뱅크': '090',
      '토스뱅크': '092',
    };
    return bankCodes[bankName] ?? '999';
  }

  // 출금 취소 (처리 전만 가능)
  Future<bool> cancelWithdrawal(String withdrawalId) async {
    try {
      final withdrawal = _withdrawalHistory.firstWhere(
        (w) => w['id'] == withdrawalId,
        orElse: () => {},
      );

      if (withdrawal.isEmpty) {
        throw Exception('출금 요청을 찾을 수 없습니다');
      }

      if (withdrawal['status'] != 'pending') {
        throw Exception('처리 중이거나 완료된 출금은 취소할 수 없습니다');
      }

      // 서버에 취소 요청
      // await _railway.cancelWithdrawal(withdrawalId);

      // 로컬 상태 업데이트
      await _updateWithdrawalStatus(
        withdrawalId: withdrawalId,
        status: 'cancelled',
        adminNotes: '사용자 요청으로 취소',
      );

      // 잔액 복구
      final amount = withdrawal['amount'] as double;
      // await _cashService.earnCash(
      //   source: 'withdrawal_cancelled',
      //   amount: amount,
      //   description: '출금 취소로 인한 잔액 복구',
      // );

      print('🚫 출금 취소 완료: $withdrawalId');
      return true;

    } catch (e) {
      print('출금 취소 실패: $e');
      return false;
    }
  }

  // 출금 통계
  Future<Map<String, dynamic>> getWithdrawalStatistics() async {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final thisYear = DateTime(now.year);

    double totalWithdrawn = 0;
    double totalFees = 0;
    double thisMonthWithdrawn = 0;
    double thisYearWithdrawn = 0;
    int completedCount = 0;
    int pendingCount = 0;

    for (final withdrawal in _withdrawalHistory) {
      final amount = (withdrawal['amount'] as num?)?.toDouble() ?? 0;
      final fee = (withdrawal['fee'] as num?)?.toDouble() ?? 0;
      final status = withdrawal['status'] as String? ?? '';
      final createdAt = DateTime.parse(withdrawal['created_at'] ?? withdrawal['timestamp']);

      if (status == 'completed') {
        totalWithdrawn += amount;
        totalFees += fee;
        completedCount++;

        if (createdAt.isAfter(thisMonth)) {
          thisMonthWithdrawn += amount;
        }

        if (createdAt.isAfter(thisYear)) {
          thisYearWithdrawn += amount;
        }
      } else if (status == 'pending' || status == 'processing') {
        pendingCount++;
      }
    }

    return {
      'totalWithdrawn': totalWithdrawn,
      'totalFees': totalFees,
      'thisMonthWithdrawn': thisMonthWithdrawn,
      'thisYearWithdrawn': thisYearWithdrawn,
      'completedCount': completedCount,
      'pendingCount': pendingCount,
      'totalRequests': _withdrawalHistory.length,
      'averageAmount': completedCount > 0 ? totalWithdrawn / completedCount : 0,
      'settings': {
        'minimumAmount': _minimumWithdrawal,
        'maximumAmount': _maximumWithdrawal,
        'feePercentage': _feePercentage,
        'processingDays': _processingDays,
      },
    };
  }

  // Getters
  List<Map<String, dynamic>> get withdrawalHistory => List.from(_withdrawalHistory);
  Map<String, dynamic>? get currentRequest => _currentRequest;

  bool get hasActiveBankAccount => _getBankAccount() != null;
  bool get hasPendingWithdrawal => _withdrawalHistory.any((w) =>
      w['status'] == 'pending' || w['status'] == 'processing');

  double get minimumWithdrawal => _minimumWithdrawal;
  double get maximumWithdrawal => _maximumWithdrawal;
  double get feePercentage => _feePercentage;
  int get processingDays => _processingDays;
}