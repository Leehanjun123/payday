import 'package:flutter/material.dart';
import '../screens/income_entry_screen.dart';
import '../models/income_source.dart';

mixin IncomeDetailMixin<T extends StatefulWidget> on State<T> {
  void navigateToIncomeEntry(IncomeType type, String title, Color color) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IncomeEntryScreen(
          incomeType: type,
          incomeTitle: title,
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('수익이 성공적으로 추가되었습니다!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to home and refresh
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  FloatingActionButton buildIncomeFloatingActionButton(
    IncomeType type,
    String title,
    Color color,
  ) {
    return FloatingActionButton(
      onPressed: () => navigateToIncomeEntry(type, title, color),
      backgroundColor: color,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }
}