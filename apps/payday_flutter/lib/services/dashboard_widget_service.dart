import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'database_service.dart';
import 'ai_insights_service.dart';

// 위젯 타입
enum DashboardWidgetType {
  totalIncome,        // 총 수익
  todayIncome,        // 오늘 수익
  weeklyChart,        // 주간 차트
  monthlyChart,       // 월간 차트
  goalProgress,       // 목표 진행률
  streakCounter,      // 연속 기록
  incomeDistribution, // 수익 분포
  growthRate,         // 성장률
  quickStats,         // 빠른 통계
  aiPrediction,       // AI 예측
  topSources,         // 상위 수익원
  timeAnalysis,       // 시간대 분석
}

// 위젯 데이터
class DashboardWidget {
  final String id;
  final DashboardWidgetType type;
  final String title;
  final IconData icon;
  final Color color;
  final Map<String, dynamic> data;
  final DateTime lastUpdated;
  final int priority;
  final bool isVisible;
  final Size size; // small, medium, large

  DashboardWidget({
    required this.id,
    required this.type,
    required this.title,
    required this.icon,
    required this.color,
    required this.data,
    required this.lastUpdated,
    required this.priority,
    required this.isVisible,
    required this.size,
  });
}

// 차트 데이터 포인트
class ChartDataPoint {
  final String label;
  final double value;
  final Color color;
  final String? tooltip;

  ChartDataPoint({
    required this.label,
    required this.value,
    required this.color,
    this.tooltip,
  });
}

// 실시간 데이터 스트림
class DashboardDataStream {
  final String widgetId;
  final Stream<Map<String, dynamic>> dataStream;
  final Duration updateInterval;

  DashboardDataStream({
    required this.widgetId,
    required this.dataStream,
    required this.updateInterval,
  });
}

class DashboardWidgetService {
  final DatabaseService _dbService = DatabaseService();
  final AiInsightsService _aiService = AiInsightsService();

  // 스트림 컨트롤러
  final _widgetDataController = StreamController<List<DashboardWidget>>.broadcast();
  Timer? _updateTimer;

  // 위젯 설정
  List<DashboardWidget> _activeWidgets = [];
  Map<String, bool> _widgetVisibility = {};

  // 초기화
  Future<void> initialize() async {
    await _loadWidgetSettings();
    _startDataUpdates();
  }

  // 위젯 설정 로드
  Future<void> _loadWidgetSettings() async {
    // 기본 위젯 구성
    _activeWidgets = await _generateDefaultWidgets();
    _widgetDataController.add(_activeWidgets);
  }

  // 실시간 데이터 업데이트 시작
  void _startDataUpdates() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _updateWidgetData();
    });
  }

  // 위젯 데이터 업데이트
  Future<void> _updateWidgetData() async {
    for (var widget in _activeWidgets) {
      if (widget.isVisible) {
        final newData = await _fetchWidgetData(widget.type);
        final updatedWidget = DashboardWidget(
          id: widget.id,
          type: widget.type,
          title: widget.title,
          icon: widget.icon,
          color: widget.color,
          data: newData,
          lastUpdated: DateTime.now(),
          priority: widget.priority,
          isVisible: widget.isVisible,
          size: widget.size,
        );

        final index = _activeWidgets.indexWhere((w) => w.id == widget.id);
        if (index != -1) {
          _activeWidgets[index] = updatedWidget;
        }
      }
    }
    _widgetDataController.add(_activeWidgets);
  }

  // 위젯별 데이터 가져오기
  Future<Map<String, dynamic>> _fetchWidgetData(DashboardWidgetType type) async {
    switch (type) {
      case DashboardWidgetType.totalIncome:
        return await _getTotalIncomeData();
      case DashboardWidgetType.todayIncome:
        return await _getTodayIncomeData();
      case DashboardWidgetType.weeklyChart:
        return await _getWeeklyChartData();
      case DashboardWidgetType.monthlyChart:
        return await _getMonthlyChartData();
      case DashboardWidgetType.goalProgress:
        return await _getGoalProgressData();
      case DashboardWidgetType.streakCounter:
        return await _getStreakData();
      case DashboardWidgetType.incomeDistribution:
        return await _getIncomeDistributionData();
      case DashboardWidgetType.growthRate:
        return await _getGrowthRateData();
      case DashboardWidgetType.quickStats:
        return await _getQuickStatsData();
      case DashboardWidgetType.aiPrediction:
        return await _getAIPredictionData();
      case DashboardWidgetType.topSources:
        return await _getTopSourcesData();
      case DashboardWidgetType.timeAnalysis:
        return await _getTimeAnalysisData();
    }
  }

  // 총 수익 데이터
  Future<Map<String, dynamic>> _getTotalIncomeData() async {
    final incomes = await _dbService.getAllIncomes();
    double total = 0;
    for (var income in incomes) {
      total += (income['amount'] as num).toDouble();
    }

    // 이전 달과 비교
    final lastMonth = DateTime.now().subtract(const Duration(days: 30));
    double lastMonthTotal = 0;
    for (var income in incomes) {
      final date = DateTime.parse(income['date'] as String);
      if (date.isAfter(lastMonth)) {
        lastMonthTotal += (income['amount'] as num).toDouble();
      }
    }

    final change = lastMonthTotal > 0
        ? ((total - lastMonthTotal) / lastMonthTotal * 100)
        : 0.0;

    return {
      'total': total,
      'lastMonth': lastMonthTotal,
      'change': change,
      'changeType': change > 0 ? 'increase' : change < 0 ? 'decrease' : 'stable',
      'formatted': '${(total / 10000).toStringAsFixed(1)}만원',
    };
  }

  // 오늘 수익 데이터
  Future<Map<String, dynamic>> _getTodayIncomeData() async {
    final incomes = await _dbService.getAllIncomes();
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    double todayTotal = 0;
    int todayCount = 0;

    for (var income in incomes) {
      final date = DateTime.parse(income['date'] as String);
      if (date.isAfter(todayStart)) {
        todayTotal += (income['amount'] as num).toDouble();
        todayCount++;
      }
    }

    // 어제와 비교
    final yesterday = todayStart.subtract(const Duration(days: 1));
    double yesterdayTotal = 0;

    for (var income in incomes) {
      final date = DateTime.parse(income['date'] as String);
      if (date.isAfter(yesterday) && date.isBefore(todayStart)) {
        yesterdayTotal += (income['amount'] as num).toDouble();
      }
    }

    return {
      'amount': todayTotal,
      'count': todayCount,
      'yesterday': yesterdayTotal,
      'change': yesterdayTotal > 0 ? ((todayTotal - yesterdayTotal) / yesterdayTotal * 100) : 0,
      'formatted': '${todayTotal.toStringAsFixed(0)}원',
      'hourlyAverage': todayCount > 0 ? todayTotal / DateTime.now().hour : 0,
    };
  }

  // 주간 차트 데이터
  Future<Map<String, dynamic>> _getWeeklyChartData() async {
    final incomes = await _dbService.getAllIncomes();
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    final weekDays = ['월', '화', '수', '목', '금', '토', '일'];
    final chartData = <ChartDataPoint>[];
    double weekTotal = 0;

    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      double dayTotal = 0;
      for (var income in incomes) {
        final date = DateTime.parse(income['date'] as String);
        if (date.isAfter(dayStart) && date.isBefore(dayEnd)) {
          dayTotal += (income['amount'] as num).toDouble();
        }
      }

      weekTotal += dayTotal;
      chartData.add(ChartDataPoint(
        label: weekDays[i],
        value: dayTotal,
        color: _getColorForValue(dayTotal),
        tooltip: '${weekDays[i]}: ${dayTotal.toStringAsFixed(0)}원',
      ));
    }

    return {
      'chartData': chartData,
      'total': weekTotal,
      'average': weekTotal / 7,
      'best': chartData.reduce((a, b) => a.value > b.value ? a : b),
      'worst': chartData.reduce((a, b) => a.value < b.value ? a : b),
    };
  }

  // 월간 차트 데이터
  Future<Map<String, dynamic>> _getMonthlyChartData() async {
    final incomes = await _dbService.getAllIncomes();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    final chartData = <ChartDataPoint>[];
    final weeklyTotals = <double>[];

    // 주차별 데이터
    for (int week = 0; week < 4; week++) {
      final weekStartDate = monthStart.add(Duration(days: week * 7));
      final weekEndDate = weekStartDate.add(const Duration(days: 7));

      double weekTotal = 0;
      for (var income in incomes) {
        final date = DateTime.parse(income['date'] as String);
        if (date.isAfter(weekStartDate) && date.isBefore(weekEndDate)) {
          weekTotal += (income['amount'] as num).toDouble();
        }
      }

      weeklyTotals.add(weekTotal);
      chartData.add(ChartDataPoint(
        label: '${week + 1}주차',
        value: weekTotal,
        color: _getColorForValue(weekTotal),
        tooltip: '${week + 1}주차: ${(weekTotal / 10000).toStringAsFixed(1)}만원',
      ));
    }

    final monthTotal = weeklyTotals.reduce((a, b) => a + b);

    return {
      'chartData': chartData,
      'total': monthTotal,
      'average': monthTotal / 4,
      'trend': _calculateTrend(weeklyTotals),
      'projection': monthTotal * 1.2, // 20% 성장 예상
    };
  }

  // 목표 진행률 데이터
  Future<Map<String, dynamic>> _getGoalProgressData() async {
    final monthlyGoal = 1000000.0; // 목표 금액
    final incomes = await _dbService.getAllIncomes();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    double monthTotal = 0;
    for (var income in incomes) {
      final date = DateTime.parse(income['date'] as String);
      if (date.isAfter(monthStart)) {
        monthTotal += (income['amount'] as num).toDouble();
      }
    }

    final progress = (monthTotal / monthlyGoal * 100).clamp(0, 100);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = daysInMonth - now.day;
    final dailyRequired = daysRemaining > 0
        ? (monthlyGoal - monthTotal) / daysRemaining
        : 0;

    return {
      'current': monthTotal,
      'goal': monthlyGoal,
      'progress': progress,
      'remaining': monthlyGoal - monthTotal,
      'daysRemaining': daysRemaining,
      'dailyRequired': dailyRequired,
      'onTrack': monthTotal >= (monthlyGoal * now.day / daysInMonth),
      'message': _getGoalMessage(progress),
    };
  }

  // 연속 기록 데이터
  Future<Map<String, dynamic>> _getStreakData() async {
    final incomes = await _dbService.getAllIncomes();
    if (incomes.isEmpty) {
      return {
        'current': 0,
        'best': 0,
        'message': '오늘부터 시작해보세요!',
        'milestone': 7,
      };
    }

    final dates = <String>{};
    for (var income in incomes) {
      final date = income['date'] as String;
      dates.add(date.split(' ')[0]);
    }

    int currentStreak = 0;
    var checkDate = DateTime.now();

    while (true) {
      final dateStr = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      if (dates.contains(dateStr)) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    // 최고 기록 계산 (더미)
    final bestStreak = max(currentStreak, Random().nextInt(30) + currentStreak);

    return {
      'current': currentStreak,
      'best': bestStreak,
      'message': _getStreakMessage(currentStreak),
      'milestone': _getNextMilestone(currentStreak),
      'badge': _getStreakBadge(currentStreak),
    };
  }

  // 수익 분포 데이터
  Future<Map<String, dynamic>> _getIncomeDistributionData() async {
    final incomes = await _dbService.getAllIncomes();
    final distribution = <String, double>{};

    for (var income in incomes) {
      final source = income['source'] as String? ?? '기타';
      final amount = (income['amount'] as num).toDouble();
      distribution[source] = (distribution[source] ?? 0) + amount;
    }

    final total = distribution.values.fold(0.0, (a, b) => a + b);
    final chartData = <ChartDataPoint>[];

    distribution.forEach((source, amount) {
      chartData.add(ChartDataPoint(
        label: source,
        value: amount,
        color: _getColorForSource(source),
        tooltip: '$source: ${(amount / total * 100).toStringAsFixed(1)}%',
      ));
    });

    // 상위 3개만 선택
    chartData.sort((a, b) => b.value.compareTo(a.value));
    final topSources = chartData.take(3).toList();

    return {
      'chartData': topSources,
      'total': total,
      'sourceCount': distribution.length,
      'topSource': topSources.isNotEmpty ? topSources.first : null,
    };
  }

  // 성장률 데이터
  Future<Map<String, dynamic>> _getGrowthRateData() async {
    final incomes = await _dbService.getAllIncomes();
    final now = DateTime.now();

    // 이번 달
    final thisMonthStart = DateTime(now.year, now.month, 1);
    double thisMonthTotal = 0;

    // 지난 달
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = thisMonthStart;
    double lastMonthTotal = 0;

    for (var income in incomes) {
      final date = DateTime.parse(income['date'] as String);
      final amount = (income['amount'] as num).toDouble();

      if (date.isAfter(thisMonthStart)) {
        thisMonthTotal += amount;
      } else if (date.isAfter(lastMonthStart) && date.isBefore(lastMonthEnd)) {
        lastMonthTotal += amount;
      }
    }

    final growthRate = lastMonthTotal > 0
        ? ((thisMonthTotal - lastMonthTotal) / lastMonthTotal * 100)
        : 0.0;

    return {
      'rate': growthRate,
      'thisMonth': thisMonthTotal,
      'lastMonth': lastMonthTotal,
      'trend': growthRate > 10 ? 'excellent' : growthRate > 0 ? 'good' : 'needs_improvement',
      'icon': growthRate > 0 ? Icons.trending_up : Icons.trending_down,
      'color': growthRate > 0 ? Colors.green : Colors.red,
    };
  }

  // 빠른 통계 데이터
  Future<Map<String, dynamic>> _getQuickStatsData() async {
    final incomes = await _dbService.getAllIncomes();
    if (incomes.isEmpty) {
      return {
        'totalDays': 0,
        'averageDaily': 0,
        'bestDay': 0,
        'totalSources': 0,
      };
    }

    final dailyTotals = <String, double>{};
    final sources = <String>{};

    for (var income in incomes) {
      final date = (income['date'] as String).split(' ')[0];
      final amount = (income['amount'] as num).toDouble();
      final source = income['source'] as String? ?? '기타';

      dailyTotals[date] = (dailyTotals[date] ?? 0) + amount;
      sources.add(source);
    }

    final bestDay = dailyTotals.values.isNotEmpty
        ? dailyTotals.values.reduce((a, b) => a > b ? a : b)
        : 0.0;

    final totalAmount = dailyTotals.values.fold(0.0, (a, b) => a + b);
    final averageDaily = dailyTotals.isNotEmpty ? totalAmount / dailyTotals.length : 0.0;

    return {
      'totalDays': dailyTotals.length,
      'averageDaily': averageDaily,
      'bestDay': bestDay,
      'totalSources': sources.length,
    };
  }

  // AI 예측 데이터
  Future<Map<String, dynamic>> _getAIPredictionData() async {
    final predictions = await _aiService.generatePredictions();

    if (predictions.isEmpty) {
      return {
        'nextWeek': 0,
        'nextMonth': 0,
        'confidence': 0,
        'trend': 'neutral',
      };
    }

    // 가장 신뢰도 높은 예측 선택
    final bestPrediction = predictions.reduce((a, b) =>
        a.confidence > b.confidence ? a : b);

    return {
      'nextWeek': bestPrediction.predictions[6],
      'nextMonth': bestPrediction.value,
      'confidence': bestPrediction.confidence * 100,
      'trend': bestPrediction.trend,
      'chartData': bestPrediction.predictions.asMap().entries.map((entry) {
        return ChartDataPoint(
          label: 'Day ${entry.key + 1}',
          value: entry.value,
          color: Colors.blue.withOpacity(0.7),
        );
      }).toList(),
    };
  }

  // 상위 수익원 데이터
  Future<Map<String, dynamic>> _getTopSourcesData() async {
    final incomes = await _dbService.getAllIncomes();
    final sourceMap = <String, double>{};

    for (var income in incomes) {
      final source = income['source'] as String? ?? '기타';
      final amount = (income['amount'] as num).toDouble();
      sourceMap[source] = (sourceMap[source] ?? 0) + amount;
    }

    final sortedSources = sourceMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topSources = sortedSources.take(5).map((entry) {
      return {
        'name': entry.key,
        'amount': entry.value,
        'percentage': (entry.value / sourceMap.values.fold(0.0, (a, b) => a + b) * 100),
        'icon': _getIconForSource(entry.key),
      };
    }).toList();

    return {
      'sources': topSources,
      'total': sourceMap.values.fold(0.0, (a, b) => a + b),
    };
  }

  // 시간대 분석 데이터
  Future<Map<String, dynamic>> _getTimeAnalysisData() async {
    final incomes = await _dbService.getAllIncomes();
    final hourlyData = List.generate(24, (_) => 0.0);
    final dayOfWeekData = List.generate(7, (_) => 0.0);

    for (var income in incomes) {
      final date = DateTime.parse(income['date'] as String);
      final amount = (income['amount'] as num).toDouble();

      hourlyData[date.hour] += amount;
      dayOfWeekData[date.weekday - 1] += amount;
    }

    // 가장 생산적인 시간대
    int bestHour = 0;
    double maxHourlyAmount = 0;
    for (int i = 0; i < hourlyData.length; i++) {
      if (hourlyData[i] > maxHourlyAmount) {
        maxHourlyAmount = hourlyData[i];
        bestHour = i;
      }
    }

    // 가장 생산적인 요일
    final weekDays = ['월', '화', '수', '목', '금', '토', '일'];
    int bestDay = 0;
    double maxDailyAmount = 0;
    for (int i = 0; i < dayOfWeekData.length; i++) {
      if (dayOfWeekData[i] > maxDailyAmount) {
        maxDailyAmount = dayOfWeekData[i];
        bestDay = i;
      }
    }

    return {
      'bestHour': bestHour,
      'bestHourAmount': maxHourlyAmount,
      'bestDay': weekDays[bestDay],
      'bestDayAmount': maxDailyAmount,
      'hourlyChart': hourlyData.asMap().entries.map((entry) {
        return ChartDataPoint(
          label: '${entry.key}시',
          value: entry.value,
          color: _getColorForHour(entry.key),
        );
      }).toList(),
    };
  }

  // 기본 위젯 생성
  Future<List<DashboardWidget>> _generateDefaultWidgets() async {
    return [
      DashboardWidget(
        id: 'total_income',
        type: DashboardWidgetType.totalIncome,
        title: '총 수익',
        icon: Icons.account_balance_wallet,
        color: Colors.blue,
        data: await _getTotalIncomeData(),
        lastUpdated: DateTime.now(),
        priority: 1,
        isVisible: true,
        size: const Size(2, 1), // medium
      ),
      DashboardWidget(
        id: 'today_income',
        type: DashboardWidgetType.todayIncome,
        title: '오늘 수익',
        icon: Icons.today,
        color: Colors.green,
        data: await _getTodayIncomeData(),
        lastUpdated: DateTime.now(),
        priority: 2,
        isVisible: true,
        size: const Size(1, 1), // small
      ),
      DashboardWidget(
        id: 'weekly_chart',
        type: DashboardWidgetType.weeklyChart,
        title: '주간 차트',
        icon: Icons.bar_chart,
        color: Colors.purple,
        data: await _getWeeklyChartData(),
        lastUpdated: DateTime.now(),
        priority: 3,
        isVisible: true,
        size: const Size(2, 2), // large
      ),
      DashboardWidget(
        id: 'goal_progress',
        type: DashboardWidgetType.goalProgress,
        title: '목표 달성률',
        icon: Icons.flag,
        color: Colors.orange,
        data: await _getGoalProgressData(),
        lastUpdated: DateTime.now(),
        priority: 4,
        isVisible: true,
        size: const Size(2, 1), // medium
      ),
      DashboardWidget(
        id: 'streak_counter',
        type: DashboardWidgetType.streakCounter,
        title: '연속 기록',
        icon: Icons.local_fire_department,
        color: Colors.red,
        data: await _getStreakData(),
        lastUpdated: DateTime.now(),
        priority: 5,
        isVisible: true,
        size: const Size(1, 1), // small
      ),
    ];
  }

  // Helper 메서드들
  Color _getColorForValue(double value) {
    if (value > 100000) return Colors.green;
    if (value > 50000) return Colors.blue;
    if (value > 10000) return Colors.orange;
    return Colors.grey;
  }

  Color _getColorForSource(String source) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.red,
      Colors.teal,
    ];
    return colors[source.hashCode % colors.length];
  }

  Color _getColorForHour(int hour) {
    if (hour >= 6 && hour < 12) return Colors.orange; // 아침
    if (hour >= 12 && hour < 18) return Colors.blue;  // 오후
    if (hour >= 18 && hour < 24) return Colors.purple; // 저녁
    return Colors.grey; // 새벽
  }

  String _getGoalMessage(double progress) {
    if (progress >= 100) return '목표 달성! 축하합니다! 🎉';
    if (progress >= 80) return '거의 다 왔어요! 조금만 더! 💪';
    if (progress >= 50) return '절반 이상 달성! 화이팅! 🔥';
    if (progress >= 30) return '순조롭게 진행 중! 👍';
    return '시작이 반! 오늘도 화이팅! 🚀';
  }

  String _getStreakMessage(int streak) {
    if (streak >= 30) return '한 달 연속! 대단해요! 🏆';
    if (streak >= 14) return '2주 연속! 습관이 되고 있어요! ⭐';
    if (streak >= 7) return '일주일 연속! 멋져요! 🔥';
    if (streak >= 3) return '3일 연속! 좋은 시작! 💪';
    return '오늘부터 시작해보세요! 🌟';
  }

  int _getNextMilestone(int current) {
    if (current < 3) return 3;
    if (current < 7) return 7;
    if (current < 14) return 14;
    if (current < 30) return 30;
    if (current < 60) return 60;
    if (current < 100) return 100;
    return current + 100;
  }

  String _getStreakBadge(int streak) {
    if (streak >= 100) return '💎';
    if (streak >= 60) return '👑';
    if (streak >= 30) return '🏆';
    if (streak >= 14) return '⭐';
    if (streak >= 7) return '🔥';
    if (streak >= 3) return '💪';
    return '🌱';
  }

  IconData _getIconForSource(String source) {
    final iconMap = {
      '프리랜서': Icons.laptop,
      '부업': Icons.work_outline,
      '투자': Icons.trending_up,
      '판매': Icons.shopping_cart,
      '기타': Icons.more_horiz,
    };
    return iconMap[source] ?? Icons.attach_money;
  }

  String _calculateTrend(List<double> values) {
    if (values.length < 2) return 'stable';

    double sum = 0;
    for (int i = 1; i < values.length; i++) {
      sum += values[i] - values[i - 1];
    }

    final avgChange = sum / (values.length - 1);
    if (avgChange > 10000) return 'increasing';
    if (avgChange < -10000) return 'decreasing';
    return 'stable';
  }

  // 위젯 가시성 토글
  void toggleWidgetVisibility(String widgetId) {
    final index = _activeWidgets.indexWhere((w) => w.id == widgetId);
    if (index != -1) {
      final widget = _activeWidgets[index];
      _activeWidgets[index] = DashboardWidget(
        id: widget.id,
        type: widget.type,
        title: widget.title,
        icon: widget.icon,
        color: widget.color,
        data: widget.data,
        lastUpdated: widget.lastUpdated,
        priority: widget.priority,
        isVisible: !widget.isVisible,
        size: widget.size,
      );
      _widgetDataController.add(_activeWidgets);
    }
  }

  // 위젯 순서 변경
  void reorderWidgets(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final widget = _activeWidgets.removeAt(oldIndex);
    _activeWidgets.insert(newIndex, widget);

    // 우선순위 재조정
    for (int i = 0; i < _activeWidgets.length; i++) {
      final w = _activeWidgets[i];
      _activeWidgets[i] = DashboardWidget(
        id: w.id,
        type: w.type,
        title: w.title,
        icon: w.icon,
        color: w.color,
        data: w.data,
        lastUpdated: w.lastUpdated,
        priority: i + 1,
        isVisible: w.isVisible,
        size: w.size,
      );
    }

    _widgetDataController.add(_activeWidgets);
  }

  // 스트림 구독
  Stream<List<DashboardWidget>> get widgetStream => _widgetDataController.stream;

  // 현재 위젯 목록
  List<DashboardWidget> get currentWidgets => _activeWidgets;

  // 정리
  void dispose() {
    _updateTimer?.cancel();
    _widgetDataController.close();
  }
}