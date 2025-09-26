import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/income.dart';
import 'dart:math' as math;

class IncomePieChart extends StatefulWidget {
  final List<Income> incomes;
  final String title;

  const IncomePieChart({
    Key? key,
    required this.incomes,
    this.title = '수익 분포',
  }) : super(key: key);

  @override
  State<IncomePieChart> createState() => _IncomePieChartState();
}

class _IncomePieChartState extends State<IncomePieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.incomes.isEmpty) {
      return Center(
        child: Text(
          '데이터가 없습니다',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 카테고리별 수익 집계
    Map<String, double> categoryIncomes = {};
    for (var income in widget.incomes) {
      categoryIncomes[income.type] = (categoryIncomes[income.type] ?? 0) + income.amount;
    }

    // 총액 계산
    double total = categoryIncomes.values.fold(0, (sum, amount) => sum + amount);

    // 정렬 (금액 큰 순서)
    var sortedEntries = categoryIncomes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 상위 5개만 표시, 나머지는 "기타"로
    Map<String, double> displayData = {};
    double othersTotal = 0;

    for (int i = 0; i < sortedEntries.length; i++) {
      if (i < 5) {
        displayData[sortedEntries[i].key] = sortedEntries[i].value;
      } else {
        othersTotal += sortedEntries[i].value;
      }
    }

    if (othersTotal > 0) {
      displayData['기타'] = othersTotal;
    }

    return Container(
      height: 320,
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
            widget.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              touchedIndex = -1;
                              return;
                            }
                            touchedIndex = pieTouchResponse
                                .touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: _showingSections(displayData, total),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildLegend(displayData, total, isDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _showingSections(Map<String, double> data, double total) {
    final colors = [
      Colors.blue[400]!,
      Colors.purple[400]!,
      Colors.pink[400]!,
      Colors.orange[400]!,
      Colors.green[400]!,
      Colors.teal[400]!,
    ];

    int index = 0;
    return data.entries.map((entry) {
      final isTouched = index == touchedIndex;
      final fontSize = isTouched ? 14.0 : 12.0;
      final radius = isTouched ? 60.0 : 50.0;
      final percentage = (entry.value / total * 100);
      final color = colors[index % colors.length];

      final section = PieChartSectionData(
        color: color,
        value: entry.value,
        title: percentage >= 5 ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
      index++;
      return section;
    }).toList();
  }

  List<Widget> _buildLegend(Map<String, double> data, double total, bool isDark) {
    final colors = [
      Colors.blue[400]!,
      Colors.purple[400]!,
      Colors.pink[400]!,
      Colors.orange[400]!,
      Colors.green[400]!,
      Colors.teal[400]!,
    ];

    int index = 0;
    return data.entries.map((entry) {
      final percentage = (entry.value / total * 100);
      final color = colors[index % colors.length];
      final widget = Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: touchedIndex == index ? FontWeight.bold : FontWeight.normal,
                      color: isDark ? Colors.white : Colors.grey[800],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      index++;
      return widget;
    }).toList();
  }
}