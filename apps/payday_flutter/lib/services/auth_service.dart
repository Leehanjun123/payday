import 'dart:convert';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'local_storage_service.dart';
import 'railway_service.dart';
import 'cloud_cash_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final LocalStorageService _localStorage = LocalStorageService();
  final RailwayService _railway = RailwayService();
  final CloudCashService _cashService = CloudCashService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  String? _deviceId;
  User? _currentUser;
  Map<String, dynamic>? _userProfile;

  // 초기화
  Future<void> initialize() async {
    await _localStorage.initialize();
    await _railway.initialize();
    await _generateDeviceId();
    await _loadSavedUser();
  }

  // 디바이스 ID 생성
  Future<void> _generateDeviceId() async {
    _deviceId = _localStorage.getString('device_id');

    if (_deviceId == null) {
      final deviceInfo = DeviceInfoPlugin();
      String uniqueId;

      try {
        final iosInfo = await deviceInfo.iosInfo;
        uniqueId = iosInfo.identifierForVendor ?? _generateRandomId();
      } catch (e) {
        uniqueId = _generateRandomId();
      }

      _deviceId = uniqueId;
      await _localStorage.setString('device_id', _deviceId!);
    }
  }

  String _generateRandomId() {
    final random = Random();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  // 저장된 사용자 정보 로드
  Future<void> _loadSavedUser() async {
    final savedProfile = _localStorage.getJson('user_profile');
    if (savedProfile != null) {
      _userProfile = savedProfile;
    }

    // Firebase 자동 로그인 체크
    _currentUser = _firebaseAuth.currentUser;
  }

  // 게스트로 시작 (디바이스 ID 기반)
  Future<bool> startAsGuest() async {
    try {
      if (_deviceId == null) {
        await _generateDeviceId();
      }

      // Railway 서버에 디바이스 등록
      final authResult = await _railway.authenticateUser(
        deviceId: _deviceId!,
      );

      if (authResult != null) {
        _userProfile = {
          'id': authResult['user']['id'],
          'device_id': _deviceId,
          'auth_type': 'guest',
          'nickname': '게스트${_deviceId!.substring(0, 6)}',
          'referral_code': authResult['user']['referral_code'],
          'created_at': authResult['user']['created_at'],
        };

        await _localStorage.setJson('user_profile', _userProfile!);
        await _cashService.initialize();

        print('👤 게스트 로그인 성공: ${_userProfile!['nickname']}');
        return true;
      }

      return false;
    } catch (e) {
      print('게스트 로그인 실패: $e');
      return false;
    }
  }

  // 이메일 회원가입
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    String? nickname,
    String? referralCode,
  }) async {
    try {
      // 1. Firebase Auth 회원가입
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) return false;

      _currentUser = credential.user;

      // 2. Railway 서버에 사용자 등록
      final authResult = await _railway.authenticateUser(
        deviceId: _deviceId!,
        email: email,
        firebaseUid: credential.user!.uid,
      );

      if (authResult != null) {
        _userProfile = {
          'id': authResult['user']['id'],
          'email': email,
          'firebase_uid': credential.user!.uid,
          'device_id': _deviceId,
          'auth_type': 'email',
          'nickname': nickname ?? '사용자${_deviceId!.substring(0, 6)}',
          'referral_code': authResult['user']['referral_code'],
          'created_at': authResult['user']['created_at'],
        };

        // 3. 추천인 코드가 있으면 등록
        if (referralCode != null && referralCode.isNotEmpty) {
          await _railway.registerReferral(referralCode);
        }

        await _localStorage.setJson('user_profile', _userProfile!);
        await _cashService.initialize();

        // 4. 회원가입 보너스
        await _cashService.earnCash(
          source: 'signup_bonus',
          amount: 1000,
          description: '회원가입 축하 보너스',
        );

        print('✅ 이메일 회원가입 성공: $email');
        return true;
      }

      return false;
    } catch (e) {
      print('이메일 회원가입 실패: $e');
      return false;
    }
  }

  // 이메일 로그인
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Firebase Auth 로그인
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) return false;

      _currentUser = credential.user;

      // 2. Railway 서버 인증
      final authResult = await _railway.authenticateUser(
        deviceId: _deviceId!,
        email: email,
        firebaseUid: credential.user!.uid,
      );

      if (authResult != null) {
        _userProfile = {
          'id': authResult['user']['id'],
          'email': email,
          'firebase_uid': credential.user!.uid,
          'device_id': _deviceId,
          'auth_type': 'email',
          'nickname': authResult['user']['nickname'] ?? '사용자',
          'referral_code': authResult['user']['referral_code'],
          'last_login': DateTime.now().toIso8601String(),
        };

        await _localStorage.setJson('user_profile', _userProfile!);
        await _cashService.initialize();

        print('✅ 이메일 로그인 성공: $email');
        return true;
      }

      return false;
    } catch (e) {
      print('이메일 로그인 실패: $e');
      return false;
    }
  }

  // 전화번호 인증 시작
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // 자동 인증 완료
          await _signInWithPhoneCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? '전화번호 인증 실패');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // 타임아웃
        },
      );
    } catch (e) {
      onError('전화번호 인증 중 오류: $e');
    }
  }

  // SMS 코드로 로그인
  Future<bool> signInWithSmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      return await _signInWithPhoneCredential(credential);
    } catch (e) {
      print('SMS 코드 로그인 실패: $e');
      return false;
    }
  }

  Future<bool> _signInWithPhoneCredential(PhoneAuthCredential credential) async {
    try {
      final authResult = await _firebaseAuth.signInWithCredential(credential);

      if (authResult.user == null) return false;

      _currentUser = authResult.user;
      final phoneNumber = authResult.user!.phoneNumber!;

      // Railway 서버 인증
      final railwayAuth = await _railway.authenticateUser(
        deviceId: _deviceId!,
        phone: phoneNumber,
        firebaseUid: authResult.user!.uid,
      );

      if (railwayAuth != null) {
        _userProfile = {
          'id': railwayAuth['user']['id'],
          'phone': phoneNumber,
          'firebase_uid': authResult.user!.uid,
          'device_id': _deviceId,
          'auth_type': 'phone',
          'nickname': railwayAuth['user']['nickname'] ?? '사용자',
          'referral_code': railwayAuth['user']['referral_code'],
          'last_login': DateTime.now().toIso8601String(),
        };

        await _localStorage.setJson('user_profile', _userProfile!);
        await _cashService.initialize();

        print('✅ 전화번호 로그인 성공: $phoneNumber');
        return true;
      }

      return false;
    } catch (e) {
      print('전화번호 로그인 실패: $e');
      return false;
    }
  }

  // 출금 PIN 설정
  Future<bool> setWithdrawalPin(String pin) async {
    if (!isAuthenticated) return false;

    try {
      final hashedPin = _hashPin(pin);
      await _localStorage.setString('withdrawal_pin_hash', hashedPin);

      // 서버에도 저장 (해시된 상태로)
      // TODO: Railway API 호출

      print('🔐 출금 PIN 설정 완료');
      return true;
    } catch (e) {
      print('PIN 설정 실패: $e');
      return false;
    }
  }

  // 출금 PIN 검증
  Future<bool> verifyWithdrawalPin(String pin) async {
    try {
      final savedHash = _localStorage.getString('withdrawal_pin_hash');
      if (savedHash == null) return false;

      final inputHash = _hashPin(pin);
      return savedHash == inputHash;
    } catch (e) {
      print('PIN 검증 실패: $e');
      return false;
    }
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin + _deviceId!); // 디바이스 ID를 솔트로 사용
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // 계좌 정보 저장
  Future<bool> saveBankAccount({
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
  }) async {
    if (!isAuthenticated) return false;

    try {
      final bankInfo = {
        'bank_name': bankName,
        'account_number': _encryptAccountNumber(accountNumber),
        'account_holder_name': accountHolderName,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _localStorage.setJson('bank_account', bankInfo);

      // 서버에도 저장
      // TODO: Railway API 호출

      print('🏦 계좌 정보 저장 완료');
      return true;
    } catch (e) {
      print('계좌 정보 저장 실패: $e');
      return false;
    }
  }

  String _encryptAccountNumber(String accountNumber) {
    // 간단한 XOR 암호화 (실제로는 더 강력한 암호화 사용)
    final key = _deviceId!.codeUnits;
    final encrypted = accountNumber.codeUnits.asMap().entries.map((entry) {
      final index = entry.key;
      final char = entry.value;
      return char ^ key[index % key.length];
    }).toList();

    return base64.encode(encrypted);
  }

  // 프로필 업데이트
  Future<bool> updateProfile({
    String? nickname,
    String? email,
  }) async {
    if (!isAuthenticated || _userProfile == null) return false;

    try {
      final updates = <String, dynamic>{};

      if (nickname != null) {
        updates['nickname'] = nickname;
        _userProfile!['nickname'] = nickname;
      }

      if (email != null && _userProfile!['auth_type'] != 'email') {
        updates['email'] = email;
        _userProfile!['email'] = email;
      }

      if (updates.isNotEmpty) {
        await _localStorage.setJson('user_profile', _userProfile!);

        // 서버에도 업데이트
        // TODO: Railway API 호출

        print('👤 프로필 업데이트 완료');
      }

      return true;
    } catch (e) {
      print('프로필 업데이트 실패: $e');
      return false;
    }
  }

  // 추천인 코드 생성
  Future<String?> generateReferralCode() async {
    if (!isAuthenticated) return null;

    try {
      return await _railway.generateReferralCode();
    } catch (e) {
      print('추천인 코드 생성 실패: $e');
      return null;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await _railway.logout();

      _currentUser = null;
      _userProfile = null;

      await _localStorage.setString('user_profile', '');

      print('👋 로그아웃 완료');
    } catch (e) {
      print('로그아웃 실패: $e');
    }
  }

  // 계정 삭제
  Future<bool> deleteAccount() async {
    if (!isAuthenticated) return false;

    try {
      // Firebase 계정 삭제
      await _currentUser?.delete();

      // 로컬 데이터 삭제
      await _localStorage.clearAllData();

      // 서버에 계정 삭제 요청
      // TODO: Railway API 호출

      _currentUser = null;
      _userProfile = null;

      print('🗑️ 계정 삭제 완료');
      return true;
    } catch (e) {
      print('계정 삭제 실패: $e');
      return false;
    }
  }

  // Getters
  bool get isAuthenticated => _userProfile != null;
  bool get isGuest => _userProfile?['auth_type'] == 'guest';
  bool get isEmailUser => _userProfile?['auth_type'] == 'email';
  bool get isPhoneUser => _userProfile?['auth_type'] == 'phone';

  String? get userId => _userProfile?['id'];
  String? get email => _userProfile?['email'];
  String? get phone => _userProfile?['phone'];
  String? get nickname => _userProfile?['nickname'];
  String? get referralCode => _userProfile?['referral_code'];
  String? get deviceId => _deviceId;

  Map<String, dynamic>? get userProfile => _userProfile;
  User? get currentUser => _currentUser;
}