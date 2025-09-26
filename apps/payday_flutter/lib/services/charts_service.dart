import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'database_service.dart';

class ChartsService {
  final DatabaseService _dbService = DatabaseService();

  // 수익 트렌드 라인 차트 데이터
  Future<LineChartData> getIncomeLineChartData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _dbService.database;
    final incomes = await _dbService.getIncomesByDateRange(startDate, endDate);

    // 날짜별로 그룹화
    Map<DateTime, double> dailyIncomes = {};
    for (var income in incomes) {
      final date = DateTime(income['date'].year, income['date'].month, income['date'].day);
      dailyIncomes[date] = (dailyIncomes[date] ?? 0) + income['amount'];
    }

    // 날짜 순으로 정렬
    final sortedEntries = dailyIncomes.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // FlSpot 리스트 생성
    List<FlSpot> spots = [];
    double maxY = 0;

    for (int i = 0; i < sortedEntries.length; i++) {
      final value = sortedEntries[i].value;
      spots.add(FlSpot(i.toDouble(), value));
      if (value > maxY) maxY = value;
    }

    if (spots.isEmpty) {
      spots = [FlSpot(0, 0)];
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget: (value, meta) {
              return Text(
                '₩${(value / 10000).toStringAsFixed(0)}만',
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < sortedEntries.length) {
                final date = sortedEntries[value.toInt()].key;
                return Text(
                  '${date.month}/${date.day}',
                  style: const TextStyle(fontSize: 10),
                );
              }
              return const Text('');
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.purple.shade400],
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: Colors.blue,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.3),
                Colors.purple.withOpacity(0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      minX: 0,
      maxX: max(0, (spots.length - 1).toDouble()),
      minY: 0,
      maxY: maxY * 1.2,
    );
  }

  // 수익 타입별 파이 차트 데이터
  Future<List<PieChartSectionData>> getIncomeTypePieChartData() async {
    await _dbService.database;
    final incomes = await _dbService.getAllIncomes();

    Map<String, double> typeAmounts = {};
    double total = 0;

    for (var income in incomes) {
      final type = income['type'] as String;
      final amount = (income['amount'] as num).toDouble();
      typeAmounts[type] = (typeAmounts[type] ?? 0) + amount;
      total += amount;
    }

    List<PieChartSectionData> sections = [];
    final colors = [
      Colors.blue.shade400,
      Colors.purple.shade400,
      Colors.pink.shade400,
      Colors.orange.shade400,
      Colors.teal.shade400,
      Colors.indigo.shade400,
    ];

    int colorIndex = 0;
    typeAmounts.forEach((type, amount) {
      final percentage = (amount / total * 100);
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: amount,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              _getTypeLabel(type),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          badgePositionPercentageOffset: 1.3,
        ),
      );
      colorIndex++;
    });

    return sections.isEmpty
        ? [
            PieChartSectionData(
              color: Colors.grey.shade300,
              value: 1,
              title: '데이터 없음',
              radius: 50,
            ),
          ]
        : sections;
  }

  // 월별 수익 막대 차트 데이터
  Future<BarChartData> getMonthlyBarChartData() async {
    await _dbService.database;
    final incomes = await _dbService.getAllIncomes();

    Map<String, double> monthlyIncomes = {};
    final now = DateTime.now();

    // 최근 6개월 데이터만
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      monthlyIncomes[key] = 0;
    }

    for (var income in incomes) {
      final date = income['date'] as DateTime;
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      if (monthlyIncomes.containsKey(key)) {
        monthlyIncomes[key] = monthlyIncomes[key]! + (income['amount'] as num).toDouble();
      }
    }

    List<BarChartGroupData> barGroups = [];
    final sortedKeys = monthlyIncomes.keys.toList()..sort();
    double maxY = 0;

    for (int i = 0; i < sortedKeys.length; i++) {
      final value = monthlyIncomes[sortedKeys[i]]!;
      if (value > maxY) maxY = value;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: value,
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.purple.shade400],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 20,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
          ],
        ),
      );
    }

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY * 1.2,
      barGroups: barGroups,
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget: (value, meta) {
              return Text(
                '₩${(value / 10000).toStringAsFixed(0)}만',
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < sortedKeys.length) {
                final monthStr = sortedKeys[value.toInt()].split('-')[1];
                return Text(
                  '${int.parse(monthStr)}월',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                );
              }
              return const Text('');
            },
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
      ),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (group) => Colors.blueGrey.shade900,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final month = sortedKeys[group.x];
            return BarTooltipItem(
              '$month\n₩${rod.toY.toStringAsFixed(0)}',
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            );
          },
        ),
      ),
    );
  }

  // 주간 수익 비교 데이터
  Future<Map<String, dynamic>> getWeeklyComparisonData() async {
    await _dbService.database;
    final now = DateTime.now();

    // 이번 주
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final thisWeekEnd = thisWeekStart.add(const Duration(days: 6));

    // 지난 주
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final lastWeekEnd = thisWeekStart.subtract(const Duration(days: 1));

    final thisWeekIncomes = await _dbService.getIncomesByDateRange(thisWeekStart, thisWeekEnd);
    final lastWeekIncomes = await _dbService.getIncomesByDateRange(lastWeekStart, lastWeekEnd);

    double thisWeekTotal = 0;
    double lastWeekTotal = 0;

    for (var income in thisWeekIncomes) {
      thisWeekTotal += (income['amount'] as num).toDouble();
    }

    for (var income in lastWeekIncomes) {
      lastWeekTotal += (income['amount'] as num).toDouble();
    }

    double changePercentage = 0;
    if (lastWeekTotal > 0) {
      changePercentage = ((thisWeekTotal - lastWeekTotal) / lastWeekTotal) * 100;
    }

    return {
      'thisWeek': thisWeekTotal,
      'lastWeek': lastWeekTotal,
      'change': thisWeekTotal - lastWeekTotal,
      'changePercentage': changePercentage,
    };
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'freelance':
        return '프리랜서';
      case 'side_job':
        return '부업';
      case 'investment':
        return '투자';
      case 'rental':
        return '임대';
      case 'sales':
        return '판매';
      case 'other':
      default:
        return '기타';
    }
  }
}