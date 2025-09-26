import 'package:flutter/material.dart';
import 'screens/simple_login_screen.dart';

void main() {
  runApp(const PayDayApp());
}

class PayDayApp extends StatelessWidget {
  const PayDayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PayDay',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF667eea)),
        useMaterial3: true,
      ),
      home: const SimpleLoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}