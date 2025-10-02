import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_service.dart';
import 'package:intl/intl.dart';

// 위젯 데이터 모델
class WidgetData {
  final double todayIncome;
  final double weekIncome;
  final double monthIncome;
  final double totalIncome;
  final int incomeCount;
  final double goalProgress;
  final String goalTitle;
  final double goalAmount;
  final String lastUpdate;
  final String trend; // up, down, stable
  final double trendPercentage;
  final List<ChartPoint> weekChart;
  final Map<String, double> typeDistribution;

  WidgetData({
    required this.todayIncome,
    required this.weekIncome,
    required this.monthIncome,
    required this.totalIncome,
    required this.incomeCount,
    required this.goalProgress,
    required this.goalTitle,
    required this.goalAmount,
    required this.lastUpdate,
    required this.trend,
    required this.trendPercentage,
    required this.weekChart,
    required this.typeDistribution,
  });

  Map<String, dynamic> toJson() => {
    'todayIncome': todayIncome,
    'weekIncome': weekIncome,
    'monthIncome': monthIncome,
    'totalIncome': totalIncome,
    'incomeCount': incomeCount,
    'goalProgress': goalProgress,
    'goalTitle': goalTitle,
    'goalAmount': goalAmount,
    'lastUpdate': lastUpdate,
    'trend': trend,
    'trendPercentage': trendPercentage,
    'weekChart': weekChart.map((p) => p.toJson()).toList(),
    'typeDistribution': typeDistribution,
  };

  factory WidgetData.fromJson(Map<String, dynamic> json) => WidgetData(
    todayIncome: (json['todayIncome'] ?? 0.0).toDouble(),
    weekIncome: (json['weekIncome'] ?? 0.0).toDouble(),
    monthIncome: (json['monthIncome'] ?? 0.0).toDouble(),
    totalIncome: (json['totalIncome'] ?? 0.0).toDouble(),
    incomeCount: json['incomeCount'] ?? 0,
    goalProgress: (json['goalProgress'] ?? 0.0).toDouble(),
    goalTitle: json['goalTitle'] ?? '',
    goalAmount: (json['goalAmount'] ?? 0.0).toDouble(),
    lastUpdate: json['lastUpdate'] ?? '',
    trend: json['trend'] ?? 'stable',
    trendPercentage: (json['trendPercentage'] ?? 0.0).toDouble(),
    weekChart: (json['weekChart'] as List?)
        ?.map((p) => ChartPoint.fromJson(p))
        .toList() ?? [],
    typeDistribution: Map<String, double>.from(json['typeDistribution'] ?? {}),
  );
}

class ChartPoint {
  final String day;
  final double amount;

  ChartPoint({required this.day, required this.amount});

  Map<String, dynamic> toJson() => {
    'day': day,
    'amount': amount,
  };

  factory ChartPoint.fromJson(Map<String, dynamic> json) => ChartPoint(
    day: json['day'] ?? '',
    amount: (json['amount'] ?? 0.0).toDouble(),
  );
}

// 위젯 종류
enum WidgetType {
  summary,      // 요약 위젯 (오늘/이번주/이번달)
  goal,        // 목표 진행률 위젯
  chart,       // 차트 위젯
  quick,       // 빠른 기록 위젯
  motivation,  // 동기부여 메시지 위젯
}

// 위젯 크기
enum WidgetSize {
  small,   // 2x2
  medium,  // 4x2
  large,   // 4x4
}

class WidgetService {
  final DataService _dbService = DataService();
  static const String _widgetDataKey = 'widget_data';
  static const String _widgetConfigKey = 'widget_config';

  // 위젯 데이터 생성 및 업데이트
  Future<WidgetData> generateWidgetData() async {
    await _dbService.database;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    // 오늘 수익
    final todayIncomes = await _dbService.getIncomesByDateRange(
      todayStart,
      now,
    );
    double todayIncome = 0;
    for (var income in todayIncomes) {
      todayIncome += (income['amount'] as num).toDouble();
    }

    // 이번 주 수익
    final weekIncomes = await _dbService.getIncomesByDateRange(
      weekStart,
      now,
    );
    double weekIncome = 0;
    for (var income in weekIncomes) {
      weekIncome += (income['amount'] as num).toDouble();
    }

    // 이번 달 수익
    final monthIncomes = await _dbService.getIncomesByDateRange(
      monthStart,
      now,
    );
    double monthIncome = 0;
    Map<String, double> typeDistribution = {};
    for (var income in monthIncomes) {
      final amount = (income['amount'] as num).toDouble();
      final type = income['type'] as String;
      monthIncome += amount;
      typeDistribution[type] = (typeDistribution[type] ?? 0) + amount;
    }

    // 전체 수익
    final allIncomes = await _dbService.getAllIncomes();
    double totalIncome = 0;
    for (var income in allIncomes) {
      totalIncome += (income['amount'] as num).toDouble();
    }

    // 주간 차트 데이터
    List<ChartPoint> weekChart = [];
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final dayIncomes = await _dbService.getIncomesByDateRange(
        DateTime(day.year, day.month, day.day),
        DateTime(day.year, day.month, day.day, 23, 59, 59),
      );
      double dayTotal = 0;
      for (var income in dayIncomes) {
        dayTotal += (income['amount'] as num).toDouble();
      }
      weekChart.add(ChartPoint(
        day: DateFormat('E', 'ko').format(day),
        amount: dayTotal,
      ));
    }

    // 지난 주 대비 트렌드
    final lastWeekStart = weekStart.subtract(const Duration(days: 7));
    final lastWeekEnd = weekStart.subtract(const Duration(days: 1));
    final lastWeekIncomes = await _dbService.getIncomesByDateRange(
      lastWeekStart,
      lastWeekEnd,
    );
    double lastWeekTotal = 0;
    for (var income in lastWeekIncomes) {
      lastWeekTotal += (income['amount'] as num).toDouble();
    }

    String trend = 'stable';
    double trendPercentage = 0;
    if (lastWeekTotal > 0) {
      trendPercentage = ((weekIncome - lastWeekTotal) / lastWeekTotal) * 100;
      if (trendPercentage > 5) {
        trend = 'up';
      } else if (trendPercentage < -5) {
        trend = 'down';
      }
    } else if (weekIncome > 0) {
      trend = 'up';
      trendPercentage = 100;
    }

    // 현재 목표
    final goals = await _dbService.getAllGoals();
    double goalProgress = 0;
    String goalTitle = '목표 없음';
    double goalAmount = 0;

    if (goals.isNotEmpty) {
      // 가장 가까운 목표 선택
      final activeGoal = goals.firstWhere(
        (g) => g['progress'] != null && g['progress'] < 1.0,
        orElse: () => goals.first,
      );

      goalTitle = activeGoal['title'] ?? '목표';
      goalAmount = (activeGoal['target_amount'] as num).toDouble();
      goalProgress = (activeGoal['progress'] ?? 0.0).toDouble();
    }

    final widgetData = WidgetData(
      todayIncome: todayIncome,
      weekIncome: weekIncome,
      monthIncome: monthIncome,
      totalIncome: totalIncome,
      incomeCount: allIncomes.length,
      goalProgress: goalProgress,
      goalTitle: goalTitle,
      goalAmount: goalAmount,
      lastUpdate: DateFormat('MM/dd HH:mm').format(now),
      trend: trend,
      trendPercentage: trendPercentage.abs(),
      weekChart: weekChart,
      typeDistribution: typeDistribution,
    );

    // SharedPreferences에 저장 (위젯에서 접근)
    await _saveWidgetData(widgetData);

    return widgetData;
  }

  // 위젯 데이터 저장
  Future<void> _saveWidgetData(WidgetData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_widgetDataKey, jsonEncode(data.toJson()));
  }

  // 위젯 데이터 로드
  Future<WidgetData?> loadWidgetData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_widgetDataKey);

    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString);
        return WidgetData.fromJson(json);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // 위젯 설정 저장
  Future<void> saveWidgetConfig({
    required WidgetType type,
    required WidgetSize size,
    Color? primaryColor,
    Color? secondaryColor,
    bool showLabels = true,
    bool showTrend = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final config = {
      'type': type.index,
      'size': size.index,
      'primaryColor': primaryColor?.value,
      'secondaryColor': secondaryColor?.value,
      'showLabels': showLabels,
      'showTrend': showTrend,
    };

    await prefs.setString(_widgetConfigKey, jsonEncode(config));
  }

  // 위젯 설정 로드
  Future<Map<String, dynamic>?> loadWidgetConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_widgetConfigKey);

    if (jsonString != null) {
      try {
        return jsonDecode(jsonString);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // 동기부여 메시지 생성
  String getMotivationalMessage(WidgetData data) {
    final hour = DateTime.now().hour;
    final messages = <String>[];

    // 시간대별 메시지
    if (hour < 6) {
      messages.add('🌅 이른 아침부터 화이팅!');
    } else if (hour < 12) {
      messages.add('☀️ 좋은 아침! 오늘도 수익 만들기!');
    } else if (hour < 18) {
      messages.add('🌤️ 오후도 힘차게!');
    } else {
      messages.add('🌙 오늘 하루도 수고했어요!');
    }

    // 트렌드 기반 메시지
    if (data.trend == 'up') {
      messages.add('📈 ${data.trendPercentage.toStringAsFixed(0)}% 상승중! 대단해요!');
    } else if (data.trend == 'down') {
      messages.add('💪 다시 일어설 수 있어요!');
    }

    // 목표 기반 메시지
    if (data.goalProgress >= 0.8) {
      messages.add('🎯 목표 달성이 눈앞에!');
    } else if (data.goalProgress >= 0.5) {
      messages.add('✨ 절반 이상 달성! 잘하고 있어요!');
    }

    // 연속 기록 기반 메시지
    if (data.incomeCount > 0 && data.incomeCount % 10 == 0) {
      messages.add('🎉 ${data.incomeCount}번째 수익 기록!');
    }

    // 오늘 수익 기반 메시지
    if (data.todayIncome > 0) {
      messages.add('💰 오늘 ₩${NumberFormat('#,###').format(data.todayIncome)} 달성!');
    } else {
      messages.add('📝 오늘 첫 수익을 기록해보세요!');
    }

    return messages[DateTime.now().millisecondsSinceEpoch % messages.length];
  }

  // 빠른 기록 URL Scheme 생성
  String getQuickAddUrl({String? type, double? amount}) {
    final params = <String, String>{};

    if (type != null) {
      params['type'] = type;
    }
    if (amount != null) {
      params['amount'] = amount.toString();
    }

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'payday://add${queryString.isNotEmpty ? '?$queryString' : ''}';
  }

  // 위젯 색상 테마
  static const Map<String, List<Color>> widgetThemes = {
    'blue': [Color(0xFF2196F3), Color(0xFF1976D2)],
    'purple': [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
    'green': [Color(0xFF4CAF50), Color(0xFF388E3C)],
    'orange': [Color(0xFFFF9800), Color(0xFFF57C00)],
    'red': [Color(0xFFF44336), Color(0xFFD32F2F)],
    'teal': [Color(0xFF009688), Color(0xFF00796B)],
    'indigo': [Color(0xFF3F51B5), Color(0xFF303F9F)],
  };

  // 위젯 아이콘
  static IconData getWidgetIcon(WidgetType type) {
    switch (type) {
      case WidgetType.summary:
        return Icons.dashboard;
      case WidgetType.goal:
        return Icons.flag;
      case WidgetType.chart:
        return Icons.show_chart;
      case WidgetType.quick:
        return Icons.add_circle;
      case WidgetType.motivation:
        return Icons.emoji_emotions;
    }
  }

  // 위젯 제목
  static String getWidgetTitle(WidgetType type) {
    switch (type) {
      case WidgetType.summary:
        return '수익 요약';
      case WidgetType.goal:
        return '목표 진행률';
      case WidgetType.chart:
        return '주간 차트';
      case WidgetType.quick:
        return '빠른 기록';
      case WidgetType.motivation:
        return '오늘의 동기부여';
    }
  }
}