import 'package:flutter/material.dart';
import 'screens/marketplace/task_list_screen.dart'; // 새로 만든 화면 import

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
      // 앱의 첫 화면을 TaskListScreen으로 설정
      home: const TaskListScreen(),
    );
  }
}

