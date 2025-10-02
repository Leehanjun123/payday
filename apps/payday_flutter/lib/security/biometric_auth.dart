import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricAuth {
  static final BiometricAuth _instance = BiometricAuth._internal();
  factory BiometricAuth() => _instance;
  BiometricAuth._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (!_isInitialized) {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
    }
  }

  // 생체 인증 가능 여부 확인
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  // 사용 가능한 생체 인증 타입 확인
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  // 생체 인증 실행
  Future<BiometricAuthResult> authenticate({
    String localizedReason = 'PayDay 앱에 접근하기 위해 생체 인증이 필요합니다',
    bool biometricOnly = false,
    bool stickyAuth = true,
  }) async {
    await initialize();

    try {
      if (!await isBiometricAvailable()) {
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.notAvailable,
          message: '생체 인증을 사용할 수 없습니다',
        );
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: stickyAuth,
        ),
      );

      if (didAuthenticate) {
        await _recordSuccessfulAuth();
        return BiometricAuthResult(
          success: true,
          message: '인증 성공',
        );
      } else {
        await _recordFailedAuth();
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.userCancel,
          message: '사용자가 인증을 취소했습니다',
        );
      }
    } on PlatformException catch (e) {
      await _recordFailedAuth();

      return BiometricAuthResult(
        success: false,
        errorType: _mapPlatformException(e),
        message: _getErrorMessage(e),
      );
    }
  }

  // PIN 기반 백업 인증
  Future<bool> authenticateWithPIN(String pin) async {
    await initialize();

    final storedPin = _prefs.getString('backup_pin');
    if (storedPin == null) {
      return false;
    }

    final hashedPin = _hashPin(pin);
    final isValid = hashedPin == storedPin;

    if (isValid) {
      await _recordSuccessfulAuth();
    } else {
      await _recordFailedAuth();
    }

    return isValid;
  }

  // PIN 설정
  Future<bool> setupPIN(String pin) async {
    await initialize();

    if (pin.length < 4 || pin.length > 6) {
      return false;
    }

    final hashedPin = _hashPin(pin);
    await _prefs.setString('backup_pin', hashedPin);
    await _prefs.setBool('pin_enabled', true);

    return true;
  }

  // PIN 활성화 여부 확인
  Future<bool> isPINEnabled() async {
    await initialize();
    return _prefs.getBool('pin_enabled') ?? false;
  }

  // 생체 인증 설정 활성화
  Future<void> enableBiometricAuth() async {
    await initialize();
    await _prefs.setBool('biometric_enabled', true);
  }

  // 생체 인증 설정 비활성화
  Future<void> disableBiometricAuth() async {
    await initialize();
    await _prefs.setBool('biometric_enabled', false);
  }

  // 생체 인증 활성화 여부 확인
  Future<bool> isBiometricEnabled() async {
    await initialize();
    return _prefs.getBool('biometric_enabled') ?? false;
  }

  // 인증 실패 횟수 확인
  Future<int> getFailedAttempts() async {
    await initialize();
    return _prefs.getInt('failed_attempts') ?? 0;
  }

  // 계정 잠금 여부 확인
  Future<bool> isAccountLocked() async {
    await initialize();
    final failedAttempts = await getFailedAttempts();
    final lockTime = _prefs.getInt('lock_time') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // 5회 실패 시 30분 잠금
    if (failedAttempts >= 5) {
      if (now - lockTime < 30 * 60 * 1000) {
        return true;
      } else {
        // 잠금 시간 경과 시 초기화
        await _resetFailedAttempts();
        return false;
      }
    }

    return false;
  }

  // 계정 잠금 해제까지 남은 시간 (분 단위)
  Future<int> getRemainingLockTime() async {
    await initialize();
    final lockTime = _prefs.getInt('lock_time') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final remainingMs = (30 * 60 * 1000) - (now - lockTime);

    return remainingMs > 0 ? (remainingMs / (60 * 1000)).ceil() : 0;
  }

  // 앱 보안 설정 정보
  Future<SecuritySettings> getSecuritySettings() async {
    await initialize();

    return SecuritySettings(
      isBiometricAvailable: await isBiometricAvailable(),
      isBiometricEnabled: await isBiometricEnabled(),
      isPINEnabled: await isPINEnabled(),
      availableBiometrics: await getAvailableBiometrics(),
      failedAttempts: await getFailedAttempts(),
      isAccountLocked: await isAccountLocked(),
      remainingLockTime: await getRemainingLockTime(),
    );
  }

  // === 내부 메서드 ===

  String _hashPin(String pin) {
    // 실제 구현에서는 더 강력한 해싱 알고리즘 사용
    return pin.hashCode.toString();
  }

  Future<void> _recordSuccessfulAuth() async {
    await _prefs.setInt('failed_attempts', 0);
    await _prefs.setInt('last_auth_time', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _recordFailedAuth() async {
    final currentAttempts = await getFailedAttempts();
    final newAttempts = currentAttempts + 1;

    await _prefs.setInt('failed_attempts', newAttempts);

    if (newAttempts >= 5) {
      await _prefs.setInt('lock_time', DateTime.now().millisecondsSinceEpoch);
    }
  }

  Future<void> _resetFailedAttempts() async {
    await _prefs.setInt('failed_attempts', 0);
    await _prefs.remove('lock_time');
  }

  BiometricErrorType _mapPlatformException(PlatformException e) {
    switch (e.code) {
      case 'NotAvailable':
        return BiometricErrorType.notAvailable;
      case 'NotEnrolled':
        return BiometricErrorType.notEnrolled;
      case 'PasscodeNotSet':
        return BiometricErrorType.passcodeNotSet;
      case 'LockedOut':
        return BiometricErrorType.lockedOut;
      case 'PermanentlyLockedOut':
        return BiometricErrorType.permanentlyLockedOut;
      default:
        return BiometricErrorType.unknown;
    }
  }

  String _getErrorMessage(PlatformException e) {
    switch (e.code) {
      case 'NotAvailable':
        return '생체 인증을 사용할 수 없습니다';
      case 'NotEnrolled':
        return '생체 인증이 등록되지 않았습니다';
      case 'PasscodeNotSet':
        return '기기에 패스코드가 설정되지 않았습니다';
      case 'LockedOut':
        return '너무 많은 시도로 인해 일시적으로 잠겼습니다';
      case 'PermanentlyLockedOut':
        return '생체 인증이 영구적으로 비활성화되었습니다';
      default:
        return '알 수 없는 오류가 발생했습니다: ${e.message}';
    }
  }
}

// 결과 모델
class BiometricAuthResult {
  final bool success;
  final BiometricErrorType? errorType;
  final String message;

  BiometricAuthResult({
    required this.success,
    this.errorType,
    required this.message,
  });
}

// 오류 타입
enum BiometricErrorType {
  notAvailable,
  notEnrolled,
  passcodeNotSet,
  lockedOut,
  permanentlyLockedOut,
  userCancel,
  unknown,
}

// 보안 설정 모델
class SecuritySettings {
  final bool isBiometricAvailable;
  final bool isBiometricEnabled;
  final bool isPINEnabled;
  final List<BiometricType> availableBiometrics;
  final int failedAttempts;
  final bool isAccountLocked;
  final int remainingLockTime;

  SecuritySettings({
    required this.isBiometricAvailable,
    required this.isBiometricEnabled,
    required this.isPINEnabled,
    required this.availableBiometrics,
    required this.failedAttempts,
    required this.isAccountLocked,
    required this.remainingLockTime,
  });
}