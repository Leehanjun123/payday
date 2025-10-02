// screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:payday_flutter/services/auth_service.dart';
import 'auth_screen.dart';
import 'marketplace/marketplace_list_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // 네이티브 스플래시 스크린과 Flutter 스플래시 스크린 사이의 전환을 부드럽게 하기 위해
    // 약간의 지연 후 로직을 실행합니다.
    await Future.delayed(const Duration(milliseconds: 50));

    final authService = AuthService();
    final bool isLoggedIn = await authService.isLoggedIn();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => isLoggedIn ? const MarketplaceListScreen() : const AuthScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 이 화면은 거의 보이지 않거나, 앱의 배경색과 동일하게 하여
    // 화면 전환이 부드럽게 느껴지도록 합니다.
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
