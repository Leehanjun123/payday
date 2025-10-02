import 'dart:math';
import 'package:intl/intl.dart';
import 'data_service.dart';

// 인사이트 타입
enum InsightType {
  trend,        // 트렌드 분석
  pattern,      // 패턴 인식
  prediction,   // 예측
  advice,       // 조언
  comparison,   // 비교 분석
  anomaly,      // 이상 감지
  opportunity,  // 기회 포착
  milestone,    // 마일스톤
}

// 인사이트 중요도
enum InsightPriority {
  high,
  medium,
  low,
}

// 인사이트 모델
class Insight {
  final String id;
  final String title;
  final String description;
  final InsightType type;
  final InsightPriority priority;
  final DateTime createdAt;
  final Map<String, dynamic> data;
  final String? actionText;
  final String? actionRoute;
  final String emoji;

  Insight({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.createdAt,
    required this.data,
    this.actionText,
    this.actionRoute,
    required this.emoji,
  });
}

// 예측 모델
class PredictionModel {
  final DateTime date;
  final double predictedAmount;
  final double confidence;
  final double upperBound;
  final double lowerBound;

  PredictionModel({
    required this.date,
    required this.predictedAmount,
    required this.confidence,
    required this.upperBound,
    required this.lowerBound,
  });
}

// 패턴 모델
class IncomePattern {
  final String name;
  final String description;
  final double confidence;
  final Map<String, dynamic> details;

  IncomePattern({
    required this.name,
    required this.description,
    required this.confidence,
    required this.details,
  });
}

class AIInsightsService {
  final DataService _dbService = DataService();

  // 모든 인사이트 생성
  Future<List<Insight>> generateInsights() async {
    final insights = <Insight>[];

    // 각 분석 수행
    insights.addAll(await _analyzeTrends());
    insights.addAll(await _detectPatterns());
    insights.addAll(await _generatePredictions());
    insights.addAll(await _provideAdvice());
    insights.addAll(await _comparePerformance());
    insights.addAll(await _detectAnomalies());
    insights.addAll(await _findOpportunities());
    insights.addAll(await _checkMilestones());

    // 우선순위별로 정렬
    insights.sort((a, b) {
      if (a.priority == b.priority) {
        return b.createdAt.compareTo(a.createdAt);
      }
      return a.priority.index.compareTo(b.priority.index);
    });

    return insights;
  }

  // 트렌드 분석
  Future<List<Insight>> _analyzeTrends() async {
    final insights = <Insight>[];
    final now = DateTime.now();

    // 최근 30일 데이터
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final recentIncomes = await _dbService.getIncomesByDateRange(thirtyDaysAgo, now);

    if (recentIncomes.isEmpty) return insights;

    // 주별 그룹화
    final weeklyTotals = <int, double>{};
    for (var income in recentIncomes) {
      final date = DateTime.parse(income['date'] as String);
      final weekNumber = _getWeekNumber(date);
      weeklyTotals[weekNumber] = (weeklyTotals[weekNumber] ?? 0) +
          (income['amount'] as num).toDouble();
    }

    // 트렌드 계산
    if (weeklyTotals.length >= 2) {
      final weeks = weeklyTotals.keys.toList()..sort();
      final lastWeek = weeklyTotals[weeks.last] ?? 0;
      final prevWeek = weeklyTotals[weeks[weeks.length - 2]] ?? 0;

      if (prevWeek > 0) {
        final change = ((lastWeek - prevWeek) / prevWeek) * 100;

        if (change > 20) {
          insights.add(Insight(
            id: 'trend_up_${now.millisecondsSinceEpoch}',
            title: '수익 급상승 중! 📈',
            description: '지난주 대비 ${change.toStringAsFixed(0)}% 증가했어요. 이 추세를 유지해보세요!',
            type: InsightType.trend,
            priority: InsightPriority.high,
            createdAt: now,
            data: {'change': change, 'lastWeek': lastWeek, 'prevWeek': prevWeek},
            emoji: '🚀',
          ));
        } else if (change < -20) {
          insights.add(Insight(
            id: 'trend_down_${now.millisecondsSinceEpoch}',
            title: '수익 감소 주의 📉',
            description: '지난주 대비 ${change.abs().toStringAsFixed(0)}% 감소했어요. 새로운 전략이 필요할 수 있습니다.',
            type: InsightType.trend,
            priority: InsightPriority.high,
            createdAt: now,
            data: {'change': change, 'lastWeek': lastWeek, 'prevWeek': prevWeek},
            actionText: '목표 재설정',
            actionRoute: '/goals',
            emoji: '⚠️',
          ));
        }
      }
    }

    // 월별 트렌드
    final monthlyGrowth = await _calculateMonthlyGrowth();
    if (monthlyGrowth > 0) {
      insights.add(Insight(
        id: 'monthly_growth_${now.millisecondsSinceEpoch}',
        title: '꾸준한 성장세',
        description: '최근 3개월간 평균 ${monthlyGrowth.toStringAsFixed(0)}% 성장했어요!',
        type: InsightType.trend,
        priority: InsightPriority.medium,
        createdAt: now,
        data: {'growth': monthlyGrowth},
        emoji: '📊',
      ));
    }

    return insights;
  }

  // 패턴 감지
  Future<List<Insight>> _detectPatterns() async {
    final insights = <Insight>[];
    final now = DateTime.now();
    final patterns = await _findIncomePatterns();

    for (var pattern in patterns) {
      if (pattern.confidence > 0.7) {
        InsightPriority priority = InsightPriority.low;
        if (pattern.confidence > 0.9) priority = InsightPriority.high;
        else if (pattern.confidence > 0.8) priority = InsightPriority.medium;

        insights.add(Insight(
          id: 'pattern_${pattern.name}_${now.millisecondsSinceEpoch}',
          title: pattern.name,
          description: pattern.description,
          type: InsightType.pattern,
          priority: priority,
          createdAt: now,
          data: pattern.details,
          emoji: '🔍',
        ));
      }
    }

    return insights;
  }

  // 예측 생성
  Future<List<Insight>> _generatePredictions() async {
    final insights = <Insight>[];
    final now = DateTime.now();

    // 다음 7일 예측
    final predictions = await predictNextWeek();
    if (predictions.isNotEmpty) {
      double totalPredicted = 0;
      double avgConfidence = 0;

      for (var pred in predictions) {
        totalPredicted += pred.predictedAmount;
        avgConfidence += pred.confidence;
      }
      avgConfidence /= predictions.length;

      insights.add(Insight(
        id: 'prediction_week_${now.millisecondsSinceEpoch}',
        title: '다음 주 예상 수익',
        description: '₩${NumberFormat('#,###').format(totalPredicted.round())} 예상 (신뢰도 ${(avgConfidence * 100).toStringAsFixed(0)}%)',
        type: InsightType.prediction,
        priority: InsightPriority.medium,
        createdAt: now,
        data: {
          'predictions': predictions.map((p) => {
            'date': p.date.toIso8601String(),
            'amount': p.predictedAmount,
            'confidence': p.confidence,
          }).toList(),
        },
        emoji: '🔮',
      ));
    }

    // 월말 예측
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final daysRemaining = monthEnd.difference(now).inDays;
    if (daysRemaining > 0) {
      final monthPrediction = await predictMonthEnd();
      if (monthPrediction != null) {
        insights.add(Insight(
          id: 'prediction_month_${now.millisecondsSinceEpoch}',
          title: '이번 달 예상 총수익',
          description: '₩${NumberFormat('#,###').format(monthPrediction.round())} 도달 예상',
          type: InsightType.prediction,
          priority: InsightPriority.high,
          createdAt: now,
          data: {'prediction': monthPrediction, 'daysRemaining': daysRemaining},
          emoji: '📅',
        ));
      }
    }

    return insights;
  }

  // 조언 제공
  Future<List<Insight>> _provideAdvice() async {
    final insights = <Insight>[];
    final now = DateTime.now();

    // 최고 수익 시간대 분석
    final bestHours = await _findBestIncomeHours();
    if (bestHours.isNotEmpty) {
      final topHour = bestHours.first;
      insights.add(Insight(
        id: 'advice_best_time_${now.millisecondsSinceEpoch}',
        title: '최적 활동 시간',
        description: '${topHour['hour']}시에 가장 높은 수익을 올리고 있어요. 이 시간대에 집중해보세요!',
        type: InsightType.advice,
        priority: InsightPriority.medium,
        createdAt: now,
        data: {'bestHours': bestHours},
        emoji: '⏰',
      ));
    }

    // 수익 다각화 조언
    final diversity = await _calculateIncomeDiversity();
    if (diversity < 0.3) {
      insights.add(Insight(
        id: 'advice_diversify_${now.millisecondsSinceEpoch}',
        title: '수익원 다각화 필요',
        description: '현재 특정 수익원에 집중되어 있어요. 다양한 수익원을 개발해보세요.',
        type: InsightType.advice,
        priority: InsightPriority.high,
        createdAt: now,
        data: {'diversity': diversity},
        actionText: '새 수익원 추가',
        actionRoute: '/add',
        emoji: '💡',
      ));
    }

    // 목표 설정 조언
    final goals = await _dbService.getAllGoals();
    if (goals.isEmpty) {
      insights.add(Insight(
        id: 'advice_set_goal_${now.millisecondsSinceEpoch}',
        title: '목표를 설정하세요',
        description: '명확한 목표가 있으면 동기부여가 됩니다. 첫 목표를 설정해보세요!',
        type: InsightType.advice,
        priority: InsightPriority.high,
        createdAt: now,
        data: {},
        actionText: '목표 설정하기',
        actionRoute: '/goals',
        emoji: '🎯',
      ));
    }

    return insights;
  }

  // 비교 분석
  Future<List<Insight>> _comparePerformance() async {
    final insights = <Insight>[];
    final now = DateTime.now();

    // 이번달 vs 지난달
    final thisMonth = await _getMonthTotal(now);
    final lastMonthDate = DateTime(now.year, now.month - 1);
    final lastMonth = await _getMonthTotal(lastMonthDate);

    if (lastMonth > 0) {
      final change = ((thisMonth - lastMonth) / lastMonth) * 100;

      if (change > 0) {
        insights.add(Insight(
          id: 'compare_month_${now.millisecondsSinceEpoch}',
          title: '전월 대비 성장',
          description: '지난달보다 ${change.toStringAsFixed(0)}% 더 벌었어요!',
          type: InsightType.comparison,
          priority: InsightPriority.medium,
          createdAt: now,
          data: {'thisMonth': thisMonth, 'lastMonth': lastMonth, 'change': change},
          emoji: '📊',
        ));
      }
    }

    // 요일별 비교
    final dayPerformance = await _getDayOfWeekPerformance();
    if (dayPerformance.isNotEmpty) {
      final best = dayPerformance.reduce((a, b) =>
          a['average'] > b['average'] ? a : b);
      final worst = dayPerformance.reduce((a, b) =>
          a['average'] < b['average'] ? a : b);

      insights.add(Insight(
        id: 'compare_days_${now.millisecondsSinceEpoch}',
        title: '요일별 수익 패턴',
        description: '${best['day']}요일이 가장 좋고, ${worst['day']}요일이 가장 낮아요.',
        type: InsightType.comparison,
        priority: InsightPriority.low,
        createdAt: now,
        data: {'dayPerformance': dayPerformance},
        emoji: '📅',
      ));
    }

    return insights;
  }

  // 이상 감지
  Future<List<Insight>> _detectAnomalies() async {
    final insights = <Insight>[];
    final now = DateTime.now();

    // 최근 수익 이상 감지
    final recentIncomes = await _dbService.getIncomesByDateRange(
      now.subtract(const Duration(days: 30)),
      now,
    );

    if (recentIncomes.length > 10) {
      // 평균과 표준편차 계산
      double sum = 0;
      for (var income in recentIncomes) {
        sum += (income['amount'] as num).toDouble();
      }
      final mean = sum / recentIncomes.length;

      double variance = 0;
      for (var income in recentIncomes) {
        final amount = (income['amount'] as num).toDouble();
        variance += pow(amount - mean, 2);
      }
      final stdDev = sqrt(variance / recentIncomes.length);

      // 이상값 찾기
      for (var income in recentIncomes) {
        final amount = (income['amount'] as num).toDouble();
        if (amount > mean + (2 * stdDev)) {
          insights.add(Insight(
            id: 'anomaly_high_${income['id']}',
            title: '특별한 수익 발생!',
            description: '₩${NumberFormat('#,###').format(amount.round())} - 평소보다 훨씬 높은 수익이에요!',
            type: InsightType.anomaly,
            priority: InsightPriority.high,
            createdAt: DateTime.parse(income['date'] as String),
            data: {'amount': amount, 'mean': mean, 'stdDev': stdDev},
            emoji: '🎉',
          ));
          break; // 하나만 표시
        }
      }
    }

    // 연속 무수익 일수
    final lastIncomeDate = await _getLastIncomeDate();
    if (lastIncomeDate != null) {
      final daysSince = now.difference(lastIncomeDate).inDays;
      if (daysSince > 3) {
        insights.add(Insight(
          id: 'anomaly_no_income_${now.millisecondsSinceEpoch}',
          title: '${daysSince}일째 수익 없음',
          description: '최근 활동이 없어요. 작은 수익이라도 기록해보세요!',
          type: InsightType.anomaly,
          priority: InsightPriority.high,
          createdAt: now,
          data: {'daysSince': daysSince},
          actionText: '수익 기록하기',
          actionRoute: '/add',
          emoji: '😟',
        ));
      }
    }

    return insights;
  }

  // 기회 포착
  Future<List<Insight>> _findOpportunities() async {
    final insights = <Insight>[];
    final now = DateTime.now();

    // 주말 수익 기회
    final weekendPerformance = await _getWeekendPerformance();
    if (weekendPerformance < 0.2) {
      insights.add(Insight(
        id: 'opportunity_weekend_${now.millisecondsSinceEpoch}',
        title: '주말 수익 기회',
        description: '주말 수익이 적어요. 주말 프로젝트를 시작해보는 건 어떨까요?',
        type: InsightType.opportunity,
        priority: InsightPriority.medium,
        createdAt: now,
        data: {'weekendPerformance': weekendPerformance},
        emoji: '🌟',
      ));
    }

    // 성장 가능성
    final growthRate = await _calculateGrowthRate();
    if (growthRate > 0.1) {
      final projection = await _projectGrowth(3); // 3개월 후
      insights.add(Insight(
        id: 'opportunity_growth_${now.millisecondsSinceEpoch}',
        title: '성장 가능성 높음',
        description: '현재 속도라면 3개월 후 ₩${NumberFormat('#,###').format(projection.round())} 달성 가능!',
        type: InsightType.opportunity,
        priority: InsightPriority.high,
        createdAt: now,
        data: {'growthRate': growthRate, 'projection': projection},
        emoji: '🚀',
      ));
    }

    // 최고 기록 갱신 임박
    final highestIncome = await _getHighestDailyIncome();
    final todayIncome = await _getTodayTotal();
    if (todayIncome > highestIncome * 0.8 && todayIncome < highestIncome) {
      insights.add(Insight(
        id: 'opportunity_record_${now.millisecondsSinceEpoch}',
        title: '최고 기록 도전!',
        description: '조금만 더하면 일일 최고 기록을 깰 수 있어요!',
        type: InsightType.opportunity,
        priority: InsightPriority.high,
        createdAt: now,
        data: {'current': todayIncome, 'record': highestIncome},
        emoji: '🏆',
      ));
    }

    return insights;
  }

  // 마일스톤 체크
  Future<List<Insight>> _checkMilestones() async {
    final insights = <Insight>[];
    final now = DateTime.now();

    // 총 수익 마일스톤
    final totalIncome = await _getTotalIncome();
    final milestones = [10000, 50000, 100000, 500000, 1000000, 5000000, 10000000];

    for (var milestone in milestones) {
      if (totalIncome > milestone * 0.9 && totalIncome < milestone) {
        insights.add(Insight(
          id: 'milestone_total_${milestone}',
          title: '마일스톤 임박!',
          description: '총 ₩${NumberFormat('#,###').format(milestone)} 달성까지 ${((milestone - totalIncome) / milestone * 100).toStringAsFixed(0)}% 남았어요!',
          type: InsightType.milestone,
          priority: InsightPriority.high,
          createdAt: now,
          data: {'milestone': milestone, 'current': totalIncome},
          emoji: '🎊',
        ));
        break;
      }
    }

    // 연속 기록 마일스톤
    final streak = await _getCurrentStreak();
    final streakMilestones = [3, 7, 14, 30, 60, 100];

    for (var milestone in streakMilestones) {
      if (streak == milestone) {
        insights.add(Insight(
          id: 'milestone_streak_$milestone',
          title: '$milestone일 연속 달성!',
          description: '대단해요! $milestone일 동안 꾸준히 기록하고 있어요!',
          type: InsightType.milestone,
          priority: InsightPriority.high,
          createdAt: now,
          data: {'streak': streak},
          emoji: '🔥',
        ));
        break;
      }
    }

    return insights;
  }

  // 다음 주 예측
  Future<List<PredictionModel>> predictNextWeek() async {
    final predictions = <PredictionModel>[];
    final now = DateTime.now();

    // 과거 4주 데이터 가져오기
    final fourWeeksAgo = now.subtract(const Duration(days: 28));
    final incomes = await _dbService.getIncomesByDateRange(fourWeeksAgo, now);

    if (incomes.length < 7) return predictions;

    // 요일별 평균 계산
    final dayAverages = <int, List<double>>{};
    for (var income in incomes) {
      final date = DateTime.parse(income['date'] as String);
      final weekday = date.weekday;
      dayAverages[weekday] ??= [];
      dayAverages[weekday]!.add((income['amount'] as num).toDouble());
    }

    // 다음 7일 예측
    for (int i = 1; i <= 7; i++) {
      final predictDate = now.add(Duration(days: i));
      final weekday = predictDate.weekday;

      if (dayAverages.containsKey(weekday)) {
        final amounts = dayAverages[weekday]!;
        final avg = amounts.reduce((a, b) => a + b) / amounts.length;
        final stdDev = _calculateStdDev(amounts);

        predictions.add(PredictionModel(
          date: predictDate,
          predictedAmount: avg,
          confidence: 1 - (stdDev / avg).clamp(0, 1),
          upperBound: avg + stdDev,
          lowerBound: (avg - stdDev).clamp(0, double.infinity),
        ));
      }
    }

    return predictions;
  }

  // 월말 예측
  Future<double?> predictMonthEnd() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final currentIncomes = await _dbService.getIncomesByDateRange(monthStart, now);
    if (currentIncomes.isEmpty) return null;

    double currentTotal = 0;
    for (var income in currentIncomes) {
      currentTotal += (income['amount'] as num).toDouble();
    }

    final daysPassed = now.difference(monthStart).inDays + 1;
    final totalDays = monthEnd.day;
    final avgDaily = currentTotal / daysPassed;

    return currentTotal + (avgDaily * (totalDays - daysPassed));
  }

  // 수익 패턴 찾기
  Future<List<IncomePattern>> _findIncomePatterns() async {
    final patterns = <IncomePattern>[];
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final incomes = await _dbService.getIncomesByDateRange(thirtyDaysAgo, now);

    if (incomes.length < 10) return patterns;

    // 주기적 패턴 감지
    final dailyAmounts = <int, List<double>>{};
    for (var income in incomes) {
      final date = DateTime.parse(income['date'] as String);
      final day = date.day;
      dailyAmounts[day] ??= [];
      dailyAmounts[day]!.add((income['amount'] as num).toDouble());
    }

    // 특정일 집중 패턴
    for (var entry in dailyAmounts.entries) {
      if (entry.value.length >= 2) {
        patterns.add(IncomePattern(
          name: '매달 ${entry.key}일 수익 집중',
          description: '${entry.key}일에 규칙적으로 수익이 발생하고 있어요',
          confidence: entry.value.length / 3, // 3개월 기준
          details: {
            'day': entry.key,
            'occurrences': entry.value.length,
            'avgAmount': entry.value.reduce((a, b) => a + b) / entry.value.length,
          },
        ));
      }
    }

    // 증가/감소 패턴
    if (incomes.length >= 14) {
      final firstWeek = incomes.sublist(0, 7);
      final lastWeek = incomes.sublist(incomes.length - 7);

      double firstWeekTotal = 0;
      double lastWeekTotal = 0;

      for (var income in firstWeek) {
        firstWeekTotal += (income['amount'] as num).toDouble();
      }
      for (var income in lastWeek) {
        lastWeekTotal += (income['amount'] as num).toDouble();
      }

      if (lastWeekTotal > firstWeekTotal * 1.2) {
        patterns.add(IncomePattern(
          name: '상승 트렌드 감지',
          description: '수익이 꾸준히 증가하는 패턴을 보이고 있어요',
          confidence: 0.8,
          details: {
            'firstWeek': firstWeekTotal,
            'lastWeek': lastWeekTotal,
            'growth': ((lastWeekTotal - firstWeekTotal) / firstWeekTotal * 100),
          },
        ));
      }
    }

    return patterns;
  }

  // Helper 메서드들
  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysDifference = date.difference(firstDayOfYear).inDays;
    return ((daysDifference + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  Future<double> _calculateMonthlyGrowth() async {
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3);

    double totalGrowth = 0;
    int months = 0;

    for (int i = 0; i < 3; i++) {
      final monthDate = DateTime(now.year, now.month - i);
      final prevMonthDate = DateTime(now.year, now.month - i - 1);

      final monthTotal = await _getMonthTotal(monthDate);
      final prevMonthTotal = await _getMonthTotal(prevMonthDate);

      if (prevMonthTotal > 0) {
        totalGrowth += ((monthTotal - prevMonthTotal) / prevMonthTotal) * 100;
        months++;
      }
    }

    return months > 0 ? totalGrowth / months : 0;
  }

  Future<double> _getMonthTotal(DateTime date) async {
    final monthStart = DateTime(date.year, date.month, 1);
    final monthEnd = DateTime(date.year, date.month + 1, 0, 23, 59, 59);

    final incomes = await _dbService.getIncomesByDateRange(monthStart, monthEnd);
    double total = 0;
    for (var income in incomes) {
      total += (income['amount'] as num).toDouble();
    }
    return total;
  }

  Future<List<Map<String, dynamic>>> _findBestIncomeHours() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final incomes = await _dbService.getIncomesByDateRange(thirtyDaysAgo, now);

    final hourTotals = <int, double>{};
    final hourCounts = <int, int>{};

    for (var income in incomes) {
      final date = DateTime.parse(income['date'] as String);
      final hour = date.hour;
      hourTotals[hour] = (hourTotals[hour] ?? 0) + (income['amount'] as num).toDouble();
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }

    final hourAverages = <Map<String, dynamic>>[];
    hourTotals.forEach((hour, total) {
      hourAverages.add({
        'hour': hour,
        'average': total / (hourCounts[hour] ?? 1),
        'count': hourCounts[hour],
      });
    });

    hourAverages.sort((a, b) => b['average'].compareTo(a['average']));
    return hourAverages.take(3).toList();
  }

  Future<double> _calculateIncomeDiversity() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final incomes = await _dbService.getIncomesByDateRange(thirtyDaysAgo, now);

    if (incomes.isEmpty) return 0;

    final typeTotals = <String, double>{};
    double totalAmount = 0;

    for (var income in incomes) {
      final type = income['type'] as String;
      final amount = (income['amount'] as num).toDouble();
      typeTotals[type] = (typeTotals[type] ?? 0) + amount;
      totalAmount += amount;
    }

    // Shannon entropy 계산
    double entropy = 0;
    for (var total in typeTotals.values) {
      final proportion = total / totalAmount;
      if (proportion > 0) {
        entropy -= proportion * log(proportion) / ln2;
      }
    }

    // 정규화 (0-1 범위)
    final maxEntropy = log(typeTotals.length) / ln2;
    return maxEntropy > 0 ? entropy / maxEntropy : 0;
  }

  Future<List<Map<String, dynamic>>> _getDayOfWeekPerformance() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final incomes = await _dbService.getIncomesByDateRange(thirtyDaysAgo, now);

    final dayTotals = <int, double>{};
    final dayCounts = <int, int>{};
    final dayNames = ['월', '화', '수', '목', '금', '토', '일'];

    for (var income in incomes) {
      final date = DateTime.parse(income['date'] as String);
      final weekday = date.weekday;
      dayTotals[weekday] = (dayTotals[weekday] ?? 0) + (income['amount'] as num).toDouble();
      dayCounts[weekday] = (dayCounts[weekday] ?? 0) + 1;
    }

    final performance = <Map<String, dynamic>>[];
    for (int i = 1; i <= 7; i++) {
      if (dayCounts.containsKey(i)) {
        performance.add({
          'day': dayNames[i - 1],
          'average': dayTotals[i]! / dayCounts[i]!,
          'total': dayTotals[i],
          'count': dayCounts[i],
        });
      }
    }

    return performance;
  }

  Future<DateTime?> _getLastIncomeDate() async {
    final incomes = await _dbService.getAllIncomes();
    if (incomes.isEmpty) return null;

    DateTime lastDate = DateTime.parse(incomes.first['date'] as String);
    for (var income in incomes) {
      final date = DateTime.parse(income['date'] as String);
      if (date.isAfter(lastDate)) {
        lastDate = date;
      }
    }
    return lastDate;
  }

  Future<double> _getWeekendPerformance() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final incomes = await _dbService.getIncomesByDateRange(thirtyDaysAgo, now);

    double weekdayTotal = 0;
    double weekendTotal = 0;

    for (var income in incomes) {
      final date = DateTime.parse(income['date'] as String);
      final amount = (income['amount'] as num).toDouble();

      if (date.weekday == 6 || date.weekday == 7) {
        weekendTotal += amount;
      } else {
        weekdayTotal += amount;
      }
    }

    final total = weekdayTotal + weekendTotal;
    return total > 0 ? weekendTotal / total : 0;
  }

  Future<double> _calculateGrowthRate() async {
    final now = DateTime.now();
    final twoMonthsAgo = DateTime(now.year, now.month - 2);
    final oneMonthAgo = DateTime(now.year, now.month - 1);

    final firstMonth = await _getMonthTotal(twoMonthsAgo);
    final secondMonth = await _getMonthTotal(oneMonthAgo);

    if (firstMonth > 0) {
      return (secondMonth - firstMonth) / firstMonth;
    }
    return 0;
  }

  Future<double> _projectGrowth(int months) async {
    final growthRate = await _calculateGrowthRate();
    final currentMonth = await _getMonthTotal(DateTime.now());

    return currentMonth * pow(1 + growthRate, months);
  }

  Future<double> _getHighestDailyIncome() async {
    final incomes = await _dbService.getAllIncomes();

    final dailyTotals = <String, double>{};
    for (var income in incomes) {
      final date = income['date'] as String;
      final dateOnly = date.split(' ')[0];
      dailyTotals[dateOnly] = (dailyTotals[dateOnly] ?? 0) +
          (income['amount'] as num).toDouble();
    }

    if (dailyTotals.isEmpty) return 0;
    return dailyTotals.values.reduce((a, b) => a > b ? a : b);
  }

  Future<double> _getTodayTotal() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final incomes = await _dbService.getIncomesByDateRange(todayStart, todayEnd);
    double total = 0;
    for (var income in incomes) {
      total += (income['amount'] as num).toDouble();
    }
    return total;
  }

  Future<double> _getTotalIncome() async {
    final incomes = await _dbService.getAllIncomes();
    double total = 0;
    for (var income in incomes) {
      total += (income['amount'] as num).toDouble();
    }
    return total;
  }

  Future<int> _getCurrentStreak() async {
    final incomes = await _dbService.getAllIncomes();
    if (incomes.isEmpty) return 0;

    final dates = <String>{};
    for (var income in incomes) {
      final date = income['date'] as String;
      dates.add(date.split(' ')[0]);
    }

    final sortedDates = dates.toList()..sort();
    int streak = 0;
    final now = DateTime.now();
    var checkDate = now;

    while (true) {
      final dateStr = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      if (dates.contains(dateStr)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  double _calculateStdDev(List<double> values) {
    if (values.isEmpty) return 0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    double variance = 0;
    for (var value in values) {
      variance += pow(value - mean, 2);
    }
    return sqrt(variance / values.length);
  }
}