import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'local_storage_service.dart';
import 'railway_service.dart';
import 'auth_service.dart';

/// 한국 금융결제원 오픈뱅킹 API 연동 서비스
/// 실제 은행 계좌 인증 및 출금 처리
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final LocalStorageService _localStorage = LocalStorageService();
  final RailwayService _railway = RailwayService();
  final AuthService _auth = AuthService();

  // 오픈뱅킹 API 설정
  static const String _openBankingBaseUrl = 'https://testapi.openbanking.or.kr/v2.0';
  static const String _clientId = 'YOUR_OPENBANKING_CLIENT_ID';
  static const String _clientSecret = 'YOUR_OPENBANKING_CLIENT_SECRET';
  static const String _redirectUri = 'https://payday.app/auth/callback';

  String? _accessToken;
  String? _refreshToken;
  String? _userSeqNo;

  // 초기화
  Future<void> initialize() async {
    await _localStorage.initialize();
    _accessToken = _localStorage.getString('openbanking_access_token');
    _refreshToken = _localStorage.getString('openbanking_refresh_token');
    _userSeqNo = _localStorage.getString('openbanking_user_seq_no');

    if (_accessToken != null) {
      await _validateToken();
    }
  }

  // 오픈뱅킹 계좌 연동 URL 생성
  String generateAccountLinkUrl() {
    final state = DateTime.now().millisecondsSinceEpoch.toString();
    _localStorage.setString('auth_state', state);

    final params = {
      'response_type': 'code',
      'client_id': _clientId,
      'redirect_uri': _redirectUri,
      'scope': 'login inquiry transfer',
      'state': state,
      'auth_type': '0', // 계좌인증
    };

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '$_openBankingBaseUrl/oauth/authorize?$queryString';
  }

  // 인증 코드로 토큰 획득
  Future<bool> authenticateWithCode(String code, String state) async {
    try {
      // State 검증
      final savedState = _localStorage.getString('auth_state');
      if (savedState != state) {
        throw Exception('State 값이 일치하지 않습니다');
      }

      final response = await http.post(
        Uri.parse('$_openBankingBaseUrl/oauth/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'redirect_uri': _redirectUri,
          'code': code,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        _accessToken = data['access_token'];
        _refreshToken = data['refresh_token'];
        _userSeqNo = data['user_seq_no'];

        // 로컬 저장
        await _localStorage.setString('openbanking_access_token', _accessToken!);
        await _localStorage.setString('openbanking_refresh_token', _refreshToken!);
        await _localStorage.setString('openbanking_user_seq_no', _userSeqNo!);

        print('✅ 오픈뱅킹 인증 완료');
        return true;
      } else {
        print('오픈뱅킹 인증 실패: ${response.body}');
        return false;
      }
    } catch (e) {
      print('오픈뱅킹 인증 오류: $e');
      return false;
    }
  }

  // 토큰 유효성 검증
  Future<bool> _validateToken() async {
    if (_accessToken == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$_openBankingBaseUrl/user/me'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        // 토큰 갱신 시도
        return await _refreshAccessToken();
      }
    } catch (e) {
      print('토큰 검증 오류: $e');
      return false;
    }
  }

  // 토큰 갱신
  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_openBankingBaseUrl/oauth/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'refresh_token': _refreshToken!,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];

        await _localStorage.setString('openbanking_access_token', _accessToken!);

        print('✅ 토큰 갱신 완료');
        return true;
      }
    } catch (e) {
      print('토큰 갱신 실패: $e');
    }

    return false;
  }

  // 사용자 계좌 목록 조회
  Future<List<Map<String, dynamic>>> getUserAccounts() async {
    if (!await _validateToken()) {
      throw Exception('오픈뱅킹 인증이 필요합니다');
    }

    try {
      final response = await http.get(
        Uri.parse('$_openBankingBaseUrl/account/list?user_seq_no=$_userSeqNo&include_cancel_yn=N&sort_order=D'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['rsp_code'] == 'A0000') {
          final accounts = List<Map<String, dynamic>>.from(data['res_list'] ?? []);

          // 계좌 정보 포맷팅
          return accounts.map((account) => {
            'bank_code_std': account['bank_code_std'],
            'bank_name': account['bank_name'],
            'account_num_masked': account['account_num_masked'],
            'account_holder_name': account['account_holder_name'],
            'fintech_use_num': account['fintech_use_num'],
            'account_type': account['account_type'],
            'inquiry_agree_yn': account['inquiry_agree_yn'],
            'transfer_agree_yn': account['transfer_agree_yn'],
          }).toList();
        } else {
          throw Exception('계좌 조회 실패: ${data['rsp_message']}');
        }
      } else {
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('계좌 목록 조회 실패: $e');
      rethrow;
    }
  }

  // 계좌 잔액 조회
  Future<Map<String, dynamic>?> getAccountBalance(String fintechUseNum) async {
    if (!await _validateToken()) {
      throw Exception('오픈뱅킹 인증이 필요합니다');
    }

    try {
      final bankTranId = _generateBankTranId();
      final tranDtime = _getCurrentDtime();

      final response = await http.get(
        Uri.parse('$_openBankingBaseUrl/account/balance/fin_num'
            '?bank_tran_id=$bankTranId'
            '&fintech_use_num=$fintechUseNum'
            '&tran_dtime=$tranDtime'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['rsp_code'] == 'A0000') {
          return {
            'balance_amt': data['balance_amt'],
            'available_amt': data['available_amt'],
            'account_type': data['account_type'],
            'product_name': data['product_name'],
            'bank_name': data['bank_name'],
            'account_num_masked': data['account_num_masked'],
          };
        } else {
          throw Exception('잔액 조회 실패: ${data['rsp_message']}');
        }
      } else {
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('잔액 조회 실패: $e');
      return null;
    }
  }

  // 계좌 이체 (출금 처리)
  Future<Map<String, dynamic>> executeTransfer({
    required String withdrawFinNum, // 출금 계좌 (페이데이 계좌)
    required String depositBankCode,
    required String depositAccountNum,
    required String depositClientName,
    required String tranAmt,
    required String reqClientName,
    String? transferPurpose,
  }) async {
    if (!await _validateToken()) {
      throw Exception('오픈뱅킹 인증이 필요합니다');
    }

    try {
      final bankTranId = _generateBankTranId();
      final tranDtime = _getCurrentDtime();

      final requestBody = {
        'bank_tran_id': bankTranId,
        'cntr_account_type': 'N',
        'cntr_account_num': '123456789012345', // 페이데이 약정 계좌번호
        'dps_print_content': 'PayDay 출금',
        'fintech_use_num': withdrawFinNum,
        'wd_print_content': 'PayDay 출금',
        'tran_amt': tranAmt,
        'tran_dtime': tranDtime,
        'req_client_name': reqClientName,
        'req_client_fintech_use_num': withdrawFinNum,
        'req_client_num': '01012345678', // 요청자 연락처
        'transfer_purpose': transferPurpose ?? 'TR',
        'recv_client_name': depositClientName,
        'recv_client_bank_code': depositBankCode,
        'recv_client_account_num': depositAccountNum,
      };

      final response = await http.post(
        Uri.parse('$_openBankingBaseUrl/transfer/withdraw/fin_num'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['rsp_code'] == 'A0000') {
          return {
            'success': true,
            'bank_tran_id': data['bank_tran_id'],
            'bank_tran_date': data['bank_tran_date'],
            'bank_code_tran': data['bank_code_tran'],
            'account_num_masked': data['account_num_masked'],
            'print_content': data['print_content'],
            'tran_amt': data['tran_amt'],
            'cms_num': data['cms_num'],
          };
        } else {
          return {
            'success': false,
            'error_code': data['rsp_code'],
            'error_message': data['rsp_message'],
          };
        }
      } else {
        return {
          'success': false,
          'error': 'API 호출 실패: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': '이체 처리 중 오류: $e',
      };
    }
  }

  // 계좌 소유주 검증
  Future<bool> verifyAccountOwner({
    required String bankCode,
    required String accountNum,
    required String holderName,
  }) async {
    if (!await _validateToken()) {
      throw Exception('오픈뱅킹 인증이 필요합니다');
    }

    try {
      final bankTranId = _generateBankTranId();
      final tranDtime = _getCurrentDtime();

      final response = await http.post(
        Uri.parse('$_openBankingBaseUrl/inquiry/real_name'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'bank_tran_id': bankTranId,
          'bank_code_std': bankCode,
          'account_num': accountNum,
          'account_holder_name': holderName,
          'tran_dtime': tranDtime,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['rsp_code'] == 'A0000') {
          return data['bank_name'] != null && data['account_holder_name'] == holderName;
        }
      }

      return false;
    } catch (e) {
      print('계좌 검증 실패: $e');
      return false;
    }
  }

  // 거래 내역 조회
  Future<List<Map<String, dynamic>>> getTransactionHistory({
    required String fintechUseNum,
    required String fromDate,
    required String toDate,
    String? sortOrder,
  }) async {
    if (!await _validateToken()) {
      throw Exception('오픈뱅킹 인증이 필요합니다');
    }

    try {
      final bankTranId = _generateBankTranId();
      final tranDtime = _getCurrentDtime();

      final response = await http.get(
        Uri.parse('$_openBankingBaseUrl/account/transaction_list/fin_num'
            '?bank_tran_id=$bankTranId'
            '&fintech_use_num=$fintechUseNum'
            '&inquiry_type=A'
            '&inquiry_base=D'
            '&from_date=$fromDate'
            '&to_date=$toDate'
            '&sort_order=${sortOrder ?? 'D'}'
            '&tran_dtime=$tranDtime'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['rsp_code'] == 'A0000') {
          return List<Map<String, dynamic>>.from(data['res_list'] ?? []);
        } else {
          throw Exception('거래내역 조회 실패: ${data['rsp_message']}');
        }
      } else {
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('거래내역 조회 실패: $e');
      return [];
    }
  }

  // 유틸리티 메서드들
  String _generateBankTranId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    return 'PD${_auth.userId?.substring(0, 8) ?? '00000000'}U${timestamp.toString().substring(5)}';
  }

  String _getCurrentDtime() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
           '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}'
           '${now.second.toString().padLeft(2, '0')}';
  }

  // 은행 코드 매핑
  String getBankCode(String bankName) {
    final bankCodes = {
      '한국은행': '001',
      '산업은행': '002',
      '기업은행': '003',
      '국민은행': '004',
      '외환은행': '005',
      '수협중앙회': '007',
      '수출입은행': '008',
      '농협중앙회': '011',
      '단위농협': '012',
      '우리은행': '020',
      'SC제일은행': '023',
      '한국씨티은행': '027',
      '대구은행': '031',
      '부산은행': '032',
      '광주은행': '034',
      '제주은행': '035',
      '전북은행': '037',
      '경남은행': '039',
      '새마을금고중앙회': '045',
      '신협중앙회': '048',
      '상호저축은행중앙회': '050',
      '모간스탠리은행': '052',
      '씨티은행': '054',
      '케이이비하나은행': '081',
      '신한은행': '088',
      '케이뱅크': '089',
      '카카오뱅크': '090',
      '토스뱅크': '092',
    };
    return bankCodes[bankName] ?? '999';
  }

  String getBankName(String bankCode) {
    final bankNames = {
      '001': '한국은행',
      '002': '산업은행',
      '003': '기업은행',
      '004': '국민은행',
      '005': '외환은행',
      '007': '수협중앙회',
      '008': '수출입은행',
      '011': '농협중앙회',
      '012': '단위농협',
      '020': '우리은행',
      '023': 'SC제일은행',
      '027': '한국씨티은행',
      '031': '대구은행',
      '032': '부산은행',
      '034': '광주은행',
      '035': '제주은행',
      '037': '전북은행',
      '039': '경남은행',
      '045': '새마을금고중앙회',
      '048': '신협중앙회',
      '050': '상호저축은행중앙회',
      '052': '모간스탠리은행',
      '054': '씨티은행',
      '081': '케이이비하나은행',
      '088': '신한은행',
      '089': '케이뱅크',
      '090': '카카오뱅크',
      '092': '토스뱅크',
    };
    return bankNames[bankCode] ?? '기타';
  }

  // 연동 해제
  Future<bool> disconnectAccount() async {
    try {
      // 토큰 무효화
      if (_accessToken != null) {
        await http.post(
          Uri.parse('$_openBankingBaseUrl/oauth/revoke'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'client_id': _clientId,
            'client_secret': _clientSecret,
            'token': _accessToken!,
          },
        );
      }

      // 로컬 데이터 삭제
      await _localStorage.setString('openbanking_access_token', '');
      await _localStorage.setString('openbanking_refresh_token', '');
      await _localStorage.setString('openbanking_user_seq_no', '');

      _accessToken = null;
      _refreshToken = null;
      _userSeqNo = null;

      print('🔓 오픈뱅킹 연동 해제 완료');
      return true;
    } catch (e) {
      print('연동 해제 실패: $e');
      return false;
    }
  }

  // Getters
  bool get isConnected => _accessToken != null && _userSeqNo != null;
  String? get userSeqNo => _userSeqNo;
}