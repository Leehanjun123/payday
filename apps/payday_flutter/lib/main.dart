import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  // Flutter 엔진과 플러그인들이 상호작용할 수 있도록 보장합니다.
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase 초기화는 main에서 수행하는 것이 가장 안정적입니다.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PayDay App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // 앱의 첫 화면은 이제 인증 상태를 확인하는 SplashScreen입니다.
      home: const SplashScreen(),
    );
  }
}

