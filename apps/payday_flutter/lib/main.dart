import 'package:flutter/material.dart';
import 'screens/marketplace/marketplace_list_screen.dart'; // 새로 만든 화면 import

void main() {
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
      // 앱의 첫 화면을 MarketplaceListScreen으로 설정
      home: const MarketplaceListScreen(),
    );
  }
}

