import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/income.dart';

class IncomeLineChart extends StatelessWidget {
  final List<Income> incomes;
  final bool showGrid;

  const IncomeLineChart({
    Key? key,
    required this.incomes,
    this.showGrid = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (incomes.isEmpty) {
      return Center(
        child: Text(
          '데이터가 없습니다',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '수익 트렌드',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              _mainData(isDark),
              duration: const Duration(milliseconds: 150),
              curve: Curves.linear,
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _mainData(bool isDark) {
    // 날짜별 수익 집계
    Map<DateTime, double> dailyIncomes = {};
    for (var income in incomes) {
      final date = DateTime(income.date.year, income.date.month, income.date.day);
      dailyIncomes[date] = (dailyIncomes[date] ?? 0) + income.amount;
    }

    // 정렬된 날짜 리스트
    final sortedDates = dailyIncomes.keys.toList()..sort();
    if (sortedDates.isEmpty) {
      sortedDates.add(DateTime.now());
      dailyIncomes[DateTime.now()] = 0;
    }

    // 차트 데이터 포인트 생성
    List<FlSpot> spots = [];
    double maxY = 0;

    for (int i = 0; i < sortedDates.length; i++) {
      final amount = dailyIncomes[sortedDates[i]] ?? 0;
      spots.add(FlSpot(i.toDouble(), amount));
      if (amount > maxY) maxY = amount;
    }

    // 최대값에 여유 추가
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100000;

    return LineChartData(
      gridData: FlGridData(
        show: showGrid,
        drawVerticalLine: true,
        horizontalInterval: maxY / 5,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < sortedDates.length) {
                final date = sortedDates[value.toInt()];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${date.month}/${date.day}',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: maxY / 5,
            getTitlesWidget: (value, meta) {
              if (value >= 1000000) {
                return Text(
                  '${(value / 1000000).toStringAsFixed(1)}M',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 10,
                  ),
                );
              } else if (value >= 1000) {
                return Text(
                  '${(value / 1000).toStringAsFixed(0)}K',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 10,
                  ),
                );
              }
              return Text(
                value.toStringAsFixed(0),
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 10,
                ),
              );
            },
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      minX: 0,
      maxX: (sortedDates.length - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: LinearGradient(
            colors: [
              Colors.blue[400]!,
              Colors.purple[400]!,
            ],
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: spots.length <= 7,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: Colors.blue[400]!,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                Colors.blue[400]!.withOpacity(0.2),
                Colors.purple[400]!.withOpacity(0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => isDark ? Colors.grey[800]! : Colors.white,
          tooltipBorder: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1,
          ),
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final flSpot = barSpot;
              final date = sortedDates[flSpot.x.toInt()];
              return LineTooltipItem(
                '${date.month}월 ${date.day}일\n₩${flSpot.y.toStringAsFixed(0).replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                  (Match m) => '${m[1]},',
                )}',
                TextStyle(
                  color: isDark ? Colors.white : Colors.grey[800],
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }
}