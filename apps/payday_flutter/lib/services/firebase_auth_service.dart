import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../services/data_service.dart';
import '../services/api_service.dart';

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DataService _dataService = DataService();
  final ApiService _apiService = ApiService();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 자동 로그인 체크
  Future<bool> checkAuthStatus() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // 토큰 갱신
        final idToken = await user.getIdToken();
        await _apiService.setToken(idToken);
        await _syncUserData(user);
        return true;
      }
      return false;
    } catch (e) {
      print('Auth check failed: $e');
      return false;
    }
  }

  // 이메일 회원가입
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Firebase Auth 회원가입
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // 프로필 업데이트
        await credential.user!.updateDisplayName(name);

        // 서버에 사용자 정보 저장
        await _createUserProfile(credential.user!, {
          'name': name,
          'email': email,
          'signUpMethod': 'email',
          'createdAt': DateTime.now().toIso8601String(),
        });

        // 환영 포인트 지급 (신규 가입 보너스)
        await _giveWelcomeBonus(credential.user!.uid);

        return credential.user;
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
    return null;
  }

  // 이메일 로그인
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _syncUserData(credential.user!);
        await _checkDailyBonus(credential.user!.uid);
      }

      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // 구글 로그인
  Future<User?> signInWithGoogle() async {
    try {
      // 구글 로그인 플로우 시작
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // 인증 정보 획득
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase 인증 자격 증명 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase 로그인
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

        if (isNewUser) {
          await _createUserProfile(userCredential.user!, {
            'name': userCredential.user!.displayName ?? '',
            'email': userCredential.user!.email ?? '',
            'photoUrl': userCredential.user!.photoURL ?? '',
            'signUpMethod': 'google',
            'createdAt': DateTime.now().toIso8601String(),
          });
          await _giveWelcomeBonus(userCredential.user!.uid);
        } else {
          await _syncUserData(userCredential.user!);
          await _checkDailyBonus(userCredential.user!.uid);
        }
      }

      return userCredential.user;
    } catch (e) {
      print('Google sign in failed: $e');
      return null;
    }
  }

  // Apple 로그인 (iOS만)
  Future<User?> signInWithApple() async {
    if (!Platform.isIOS) return null;

    try {
      // Apple 로그인 요청
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // OAuth 자격 증명 생성
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Firebase 로그인
      final userCredential = await _auth.signInWithCredential(oauthCredential);

      if (userCredential.user != null) {
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

        if (isNewUser) {
          final name = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
          await _createUserProfile(userCredential.user!, {
            'name': name.isEmpty ? 'Apple User' : name,
            'email': appleCredential.email ?? userCredential.user!.email ?? '',
            'signUpMethod': 'apple',
            'createdAt': DateTime.now().toIso8601String(),
          });
          await _giveWelcomeBonus(userCredential.user!.uid);
        } else {
          await _syncUserData(userCredential.user!);
          await _checkDailyBonus(userCredential.user!.uid);
        }
      }

      return userCredential.user;
    } catch (e) {
      print('Apple sign in failed: $e');
      return null;
    }
  }

  // 사용자 프로필 생성 (서버)
  Future<void> _createUserProfile(User user, Map<String, dynamic> data) async {
    try {
      final idToken = await user.getIdToken();
      await _apiService.setToken(idToken);

      await _apiService.post('/users/profile', {
        'uid': user.uid,
        ...data,
        'points': 0,
        'totalEarnings': 0,
        'level': 1,
      });
    } catch (e) {
      print('Failed to create user profile: $e');
    }
  }

  // 사용자 데이터 동기화
  Future<void> _syncUserData(User user) async {
    try {
      final idToken = await user.getIdToken();
      await _apiService.setToken(idToken);

      // 서버에서 최신 데이터 가져오기
      final userData = await _apiService.get('/users/profile/${user.uid}');

      // 로컬에 저장
      await _dataService.saveSetting('user_data', userData);
      await _dataService.saveSetting('last_sync', DateTime.now().toIso8601String());
    } catch (e) {
      print('Failed to sync user data: $e');
    }
  }

  // 환영 보너스 지급
  Future<void> _giveWelcomeBonus(String uid) async {
    try {
      await _apiService.post('/points/welcome-bonus', {
        'uid': uid,
        'amount': 5000,
        'description': '신규 가입 환영 보너스',
      });
    } catch (e) {
      print('Failed to give welcome bonus: $e');
    }
  }

  // 일일 보너스 체크
  Future<void> _checkDailyBonus(String uid) async {
    try {
      final lastBonus = await _dataService.getSetting('last_daily_bonus');
      final today = DateTime.now().toIso8601String().split('T')[0];

      if (lastBonus != today) {
        await _apiService.post('/points/daily-bonus', {
          'uid': uid,
          'amount': 100,
          'description': '일일 출석 보너스',
        });

        await _dataService.saveSetting('last_daily_bonus', today);
      }
    } catch (e) {
      print('Failed to check daily bonus: $e');
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      // 모든 로그인 방법에서 로그아웃
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);

      // 로컬 데이터 초기화
      await _apiService.clearToken();
      await _dataService.saveSetting('user_data', null);
    } catch (e) {
      print('Sign out failed: $e');
    }
  }

  // 회원 탈퇴
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // 서버에서 사용자 데이터 삭제 요청
        await _apiService.delete('/users/profile/${user.uid}');

        // Firebase Auth에서 계정 삭제
        await user.delete();

        // 로컬 데이터 초기화
        await _apiService.clearToken();
        await _dataService.saveSetting('user_data', null);
      }
    } catch (e) {
      print('Delete account failed: $e');
      throw '회원 탈퇴 실패: 다시 로그인 후 시도해주세요.';
    }
  }

  // 에러 처리
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return '존재하지 않는 계정입니다.';
      case 'wrong-password':
        return '비밀번호가 올바르지 않습니다.';
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'weak-password':
        return '비밀번호가 너무 약합니다.';
      case 'invalid-email':
        return '올바른 이메일 형식이 아닙니다.';
      case 'operation-not-allowed':
        return '해당 로그인 방법은 현재 비활성화되어 있습니다.';
      case 'too-many-requests':
        return '너무 많은 시도가 있었습니다. 잠시 후 다시 시도해주세요.';
      default:
        return '로그인 실패: ${e.message}';
    }
  }

  // 포인트 조회
  Future<int> getUserPoints() async {
    try {
      final userData = await _dataService.getSetting('user_data');
      return userData?['points'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // 포인트 사용
  Future<bool> usePoints(int amount, String description) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final response = await _apiService.post('/points/use', {
        'uid': user.uid,
        'amount': amount,
        'description': description,
      });

      await _syncUserData(user);
      return response['success'] ?? false;
    } catch (e) {
      print('Failed to use points: $e');
      return false;
    }
  }

  // 포인트 획득
  Future<bool> earnPoints(int amount, String source, String description) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final response = await _apiService.post('/points/earn', {
        'uid': user.uid,
        'amount': amount,
        'source': source,
        'description': description,
      });

      await _syncUserData(user);
      return response['success'] ?? false;
    } catch (e) {
      print('Failed to earn points: $e');
      return false;
    }
  }
}