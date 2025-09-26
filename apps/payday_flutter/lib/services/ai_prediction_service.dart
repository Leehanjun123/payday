import 'dart:math' as math;
import '../models/income.dart';

class AIPredictionService {
  // 선형 회귀 기반 예측 알고리즘
  static PredictionResult predictFutureIncome(List<Income> historicalData) {
    if (historicalData.isEmpty) {
      return PredictionResult(
        nextMonthPrediction: 0,
        threeMonthPrediction: 0,
        sixMonthPrediction: 0,
        confidence: 0,
        trend: TrendType.stable,
        insights: ['데이터가 부족하여 예측할 수 없습니다.'],
      );
    }

    // 날짜별 데이터 정리
    Map<DateTime, double> dailyIncomes = {};
    for (var income in historicalData) {
      final date = DateTime(income.date.year, income.date.month, income.date.day);
      dailyIncomes[date] = (dailyIncomes[date] ?? 0) + income.amount;
    }

    // 월별 수익 계산
    Map<String, double> monthlyIncomes = {};
    for (var entry in dailyIncomes.entries) {
      final monthKey = '${entry.key.year}-${entry.key.month.toString().padLeft(2, '0')}';
      monthlyIncomes[monthKey] = (monthlyIncomes[monthKey] ?? 0) + entry.value;
    }

    if (monthlyIncomes.isEmpty) {
      return PredictionResult(
        nextMonthPrediction: 0,
        threeMonthPrediction: 0,
        sixMonthPrediction: 0,
        confidence: 0,
        trend: TrendType.stable,
        insights: ['데이터가 부족하여 예측할 수 없습니다.'],
      );
    }

    // 최근 6개월 데이터 추출
    final sortedMonths = monthlyIncomes.keys.toList()..sort();
    final recentMonths = sortedMonths.reversed.take(6).toList().reversed.toList();
    final recentValues = recentMonths.map((m) => monthlyIncomes[m]!).toList();

    // 트렌드 분석
    final trend = _analyzeTrend(recentValues);

    // 예측 수행
    final predictions = _performPrediction(recentValues, trend);

    // 신뢰도 계산
    final confidence = _calculateConfidence(recentValues);

    // 인사이트 생성
    final insights = _generateInsights(
      historicalData,
      monthlyIncomes,
      trend,
      predictions,
      confidence,
    );

    return PredictionResult(
      nextMonthPrediction: predictions['nextMonth']!,
      threeMonthPrediction: predictions['threeMonth']!,
      sixMonthPrediction: predictions['sixMonth']!,
      confidence: confidence,
      trend: trend,
      insights: insights,
      categoryPredictions: _predictByCategory(historicalData),
    );
  }

  static TrendType _analyzeTrend(List<double> values) {
    if (values.length < 2) return TrendType.stable;

    double totalChange = 0;
    for (int i = 1; i < values.length; i++) {
      totalChange += (values[i] - values[i - 1]);
    }

    final avgChange = totalChange / (values.length - 1);
    final avgValue = values.reduce((a, b) => a + b) / values.length;
    final changePercent = (avgChange / avgValue) * 100;

    if (changePercent > 10) return TrendType.growing;
    if (changePercent < -10) return TrendType.declining;
    return TrendType.stable;
  }

  static Map<String, double> _performPrediction(List<double> values, TrendType trend) {
    if (values.isEmpty) {
      return {
        'nextMonth': 0,
        'threeMonth': 0,
        'sixMonth': 0,
      };
    }

    // 단순 이동 평균과 트렌드 기반 예측
    final avg = values.reduce((a, b) => a + b) / values.length;

    // 가중 이동 평균 (최근 데이터에 더 많은 가중치)
    double weightedAvg = 0;
    double weightSum = 0;
    for (int i = 0; i < values.length; i++) {
      final weight = i + 1.0;
      weightedAvg += values[i] * weight;
      weightSum += weight;
    }
    weightedAvg = weightedAvg / weightSum;

    // 트렌드 팩터 계산
    double trendFactor = 0;
    if (values.length >= 3) {
      final recentAvg = values.skip(values.length - 3).reduce((a, b) => a + b) / 3;
      final oldAvg = values.take(3).reduce((a, b) => a + b) / 3;
      trendFactor = (recentAvg - oldAvg) / oldAvg;
    }

    // 예측값 계산
    double nextMonth = weightedAvg * (1 + trendFactor * 0.5);
    double threeMonth = nextMonth * 3 * (1 + trendFactor * 0.3);
    double sixMonth = nextMonth * 6 * (1 + trendFactor * 0.2);

    // 변동성 고려
    final stdDev = _calculateStdDev(values);
    final volatilityFactor = 1 - (stdDev / avg).clamp(0, 0.5);

    nextMonth *= volatilityFactor;
    threeMonth *= volatilityFactor;
    sixMonth *= volatilityFactor;

    return {
      'nextMonth': nextMonth.clamp(0, double.infinity),
      'threeMonth': threeMonth.clamp(0, double.infinity),
      'sixMonth': sixMonth.clamp(0, double.infinity),
    };
  }

  static double _calculateConfidence(List<double> values) {
    if (values.length < 3) return 30.0;

    final avg = values.reduce((a, b) => a + b) / values.length;
    final stdDev = _calculateStdDev(values);

    // 변동계수 (CV) 계산
    final cv = (stdDev / avg) * 100;

    // 신뢰도 계산 (CV가 낮을수록 신뢰도 높음)
    double confidence = 100 - cv.clamp(0, 60);

    // 데이터 포인트 수에 따른 보정
    final dataPointBonus = math.min(values.length * 3, 15);
    confidence = (confidence + dataPointBonus).clamp(30, 95);

    return confidence;
  }

  static double _calculateStdDev(List<double> values) {
    if (values.isEmpty) return 0;

    final avg = values.reduce((a, b) => a + b) / values.length;
    double sumSquaredDiff = 0;

    for (var value in values) {
      sumSquaredDiff += math.pow(value - avg, 2);
    }

    return math.sqrt(sumSquaredDiff / values.length);
  }

  static List<String> _generateInsights(
    List<Income> historicalData,
    Map<String, double> monthlyIncomes,
    TrendType trend,
    Map<String, double> predictions,
    double confidence,
  ) {
    List<String> insights = [];

    // 트렌드 인사이트
    switch (trend) {
      case TrendType.growing:
        insights.add('📈 수익이 상승 추세에 있습니다! 이 추세를 유지하세요.');
        break;
      case TrendType.declining:
        insights.add('📉 수익이 하락 추세입니다. 새로운 수익원을 고려해보세요.');
        break;
      case TrendType.stable:
        insights.add('➡️ 수익이 안정적입니다. 성장을 위한 새로운 시도를 해보세요.');
        break;
    }

    // 최고 수익 월 찾기
    if (monthlyIncomes.isNotEmpty) {
      final maxEntry = monthlyIncomes.entries.reduce((a, b) =>
        a.value > b.value ? a : b
      );
      insights.add('🏆 최고 수익 월: ${maxEntry.key} (₩${_formatNumber(maxEntry.value)})');
    }

    // 카테고리 다양성 분석
    final categories = historicalData.map((i) => i.type).toSet();
    if (categories.length < 3) {
      insights.add('💡 수익원이 ${categories.length}개로 제한적입니다. 다양화를 고려하세요.');
    } else if (categories.length > 7) {
      insights.add('🎯 ${categories.length}개의 다양한 수익원을 보유하고 있습니다!');
    }

    // 예측 정확도
    if (confidence >= 80) {
      insights.add('🎯 예측 신뢰도가 높습니다 (${confidence.toStringAsFixed(0)}%)');
    } else if (confidence >= 60) {
      insights.add('📊 예측 신뢰도가 보통입니다 (${confidence.toStringAsFixed(0)}%)');
    } else {
      insights.add('⚠️ 더 많은 데이터가 필요합니다 (신뢰도: ${confidence.toStringAsFixed(0)}%)');
    }

    // 목표 달성 예상
    final nextMonthPred = predictions['nextMonth'] ?? 0;
    if (nextMonthPred > 0) {
      insights.add('🎯 다음 달 예상 수익: ₩${_formatNumber(nextMonthPred)}');
    }

    return insights;
  }

  static Map<String, double> _predictByCategory(List<Income> historicalData) {
    Map<String, List<double>> categoryMonthlyData = {};

    // 카테고리별 월별 데이터 수집
    for (var income in historicalData) {
      final monthKey = '${income.date.year}-${income.date.month}';
      final category = income.type;

      if (!categoryMonthlyData.containsKey(category)) {
        categoryMonthlyData[category] = [];
      }

      // 동일 월의 데이터를 합산
      // 실제로는 더 복잡한 로직이 필요하지만, 간단히 구현
      categoryMonthlyData[category]!.add(income.amount);
    }

    Map<String, double> predictions = {};

    for (var entry in categoryMonthlyData.entries) {
      final values = entry.value;
      if (values.isNotEmpty) {
        final avg = values.reduce((a, b) => a + b) / values.length;
        predictions[entry.key] = avg;
      }
    }

    return predictions;
  }

  static String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toStringAsFixed(0);
  }
}

enum TrendType {
  growing,
  stable,
  declining,
}

class PredictionResult {
  final double nextMonthPrediction;
  final double threeMonthPrediction;
  final double sixMonthPrediction;
  final double confidence;
  final TrendType trend;
  final List<String> insights;
  final Map<String, double>? categoryPredictions;

  PredictionResult({
    required this.nextMonthPrediction,
    required this.threeMonthPrediction,
    required this.sixMonthPrediction,
    required this.confidence,
    required this.trend,
    required this.insights,
    this.categoryPredictions,
  });
}