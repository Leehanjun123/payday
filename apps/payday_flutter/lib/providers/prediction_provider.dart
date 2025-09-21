import 'package:flutter/material.dart';
import '../models/prediction.dart';
import '../services/api_service.dart';

class PredictionProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Prediction> _predictions = [];
  List<MarketAnalysis> _marketAnalysis = [];
  Map<String, dynamic> _aiInsights = {};
  Prediction? _selectedPrediction;
  bool _isLoading = false;
  String? _errorMessage;

  List<Prediction> get predictions => _predictions;
  List<MarketAnalysis> get marketAnalysis => _marketAnalysis;
  Map<String, dynamic> get aiInsights => _aiInsights;
  Prediction? get selectedPrediction => _selectedPrediction;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Filtered predictions
  List<Prediction> get activePredictions => _predictions.where((p) => p.status == PredictionStatus.active).toList();
  List<Prediction> get bullishPredictions => _predictions.where((p) => p.isBullish).toList();
  List<Prediction> get bearishPredictions => _predictions.where((p) => !p.isBullish).toList();
  List<Prediction> get highConfidencePredictions => _predictions.where((p) => p.confidence >= 0.8).toList();
  List<Prediction> get shortTermPredictions => _predictions.where((p) => p.timeframe == PredictionTimeframe.shortTerm).toList();

  // Statistics
  double get averageConfidence {
    if (_predictions.isEmpty) return 0.0;
    return _predictions.map((p) => p.confidence).reduce((a, b) => a + b) / _predictions.length;
  }

  int get bullishCount => bullishPredictions.length;
  int get bearishCount => bearishPredictions.length;
  double get bullishRatio => _predictions.isNotEmpty ? bullishCount / _predictions.length : 0.0;

  PredictionProvider() {
    _apiService.initialize();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadPredictions() async {
    try {
      _setLoading(true);
      _setError(null);

      final predictionsData = await _apiService.getPredictions();
      _predictions = predictionsData.map((data) => Prediction.fromJson(data)).toList();

      // Sort by confidence and created date
      _predictions.sort((a, b) {
        final confidenceComparison = b.confidence.compareTo(a.confidence);
        if (confidenceComparison != 0) return confidenceComparison;
        return b.createdAt.compareTo(a.createdAt);
      });

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPrediction(String predictionId) async {
    try {
      _setLoading(true);
      _setError(null);

      final predictionData = await _apiService.getPrediction(predictionId);
      _selectedPrediction = Prediction.fromJson(predictionData['prediction'] ?? predictionData);

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMarketAnalysis() async {
    try {
      _setLoading(true);
      _setError(null);

      final analysisData = await _apiService.getMarketAnalysis();
      _marketAnalysis = analysisData.map((data) => MarketAnalysis.fromJson(data)).toList();

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadAiInsights() async {
    try {
      _setLoading(true);
      _setError(null);

      _aiInsights = await _apiService.getAiInsights();

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void selectPrediction(Prediction prediction) {
    _selectedPrediction = prediction;
    notifyListeners();
  }

  void clearSelectedPrediction() {
    _selectedPrediction = null;
    notifyListeners();
  }

  // Analysis methods
  List<Prediction> getPredictionsByTimeframe(PredictionTimeframe timeframe) {
    return _predictions.where((p) => p.timeframe == timeframe).toList();
  }

  List<Prediction> getPredictionsByAsset(String assetSymbol) {
    return _predictions.where((p) => p.assetSymbol == assetSymbol).toList();
  }

  List<Prediction> getPredictionsByConfidence(double minConfidence) {
    return _predictions.where((p) => p.confidence >= minConfidence).toList();
  }

  Map<String, int> get predictionsByAssetCount {
    final assetCounts = <String, int>{};
    for (final prediction in _predictions) {
      assetCounts[prediction.assetSymbol] = (assetCounts[prediction.assetSymbol] ?? 0) + 1;
    }
    return assetCounts;
  }

  Map<PredictionTimeframe, int> get predictionsByTimeframeCount {
    final timeframeCounts = <PredictionTimeframe, int>{};
    for (final prediction in _predictions) {
      timeframeCounts[prediction.timeframe] = (timeframeCounts[prediction.timeframe] ?? 0) + 1;
    }
    return timeframeCounts;
  }

  // Chart data methods
  List<Map<String, dynamic>> getPredictionConfidenceChartData() {
    final confidenceRanges = {
      '90%+': 0,
      '80-89%': 0,
      '70-79%': 0,
      '60-69%': 0,
      '60% 미만': 0,
    };

    for (final prediction in _predictions) {
      final confidencePercent = prediction.confidence * 100;
      if (confidencePercent >= 90) {
        confidenceRanges['90%+'] = confidenceRanges['90%+']! + 1;
      } else if (confidencePercent >= 80) {
        confidenceRanges['80-89%'] = confidenceRanges['80-89%']! + 1;
      } else if (confidencePercent >= 70) {
        confidenceRanges['70-79%'] = confidenceRanges['70-79%']! + 1;
      } else if (confidencePercent >= 60) {
        confidenceRanges['60-69%'] = confidenceRanges['60-69%']! + 1;
      } else {
        confidenceRanges['60% 미만'] = confidenceRanges['60% 미만']! + 1;
      }
    }

    return confidenceRanges.entries.map((entry) => {
      'range': entry.key,
      'count': entry.value,
    }).toList();
  }

  List<Map<String, dynamic>> getPredictionTypeChartData() {
    final typeCounts = <PredictionType, int>{};
    for (final prediction in _predictions) {
      typeCounts[prediction.type] = (typeCounts[prediction.type] ?? 0) + 1;
    }

    return typeCounts.entries.map((entry) => {
      'type': entry.key.name,
      'count': entry.value,
      'label': _getPredictionTypeLabel(entry.key),
    }).toList();
  }

  String _getPredictionTypeLabel(PredictionType type) {
    switch (type) {
      case PredictionType.buy:
        return '매수';
      case PredictionType.sell:
        return '매도';
      case PredictionType.hold:
        return '보유';
    }
  }

  List<Map<String, dynamic>> getAssetPredictionChartData() {
    final assetCounts = predictionsByAssetCount;
    return assetCounts.entries.map((entry) => {
      'asset': entry.key,
      'count': entry.value,
    }).toList();
  }

  // Market sentiment analysis
  MarketAnalysis? get latestMarketAnalysis {
    if (_marketAnalysis.isEmpty) return null;
    return _marketAnalysis.reduce((a, b) => a.updatedAt.isAfter(b.updatedAt) ? a : b);
  }

  String get overallMarketSentiment {
    final latest = latestMarketAnalysis;
    if (latest == null) return '분석 중';

    if (latest.isBullish) {
      return '강세';
    } else if (latest.isBearish) {
      return '약세';
    } else {
      return '중립';
    }
  }

  double get marketSentimentScore {
    final latest = latestMarketAnalysis;
    return latest?.sentimentScore ?? 0.5;
  }

  // AI insights
  String get aiMarketOutlook => _aiInsights['marketOutlook'] ?? '분석 중...';
  String get aiRecommendation => _aiInsights['recommendation'] ?? '추천사항을 분석하고 있습니다...';
  List<String> get aiKeyFactors => List<String>.from(_aiInsights['keyFactors'] ?? []);
  double get aiConfidenceLevel => (_aiInsights['confidenceLevel'] ?? 0.0).toDouble();

  // Prediction performance tracking
  List<Prediction> get expiredPredictions => _predictions.where((p) => p.isExpired).toList();

  Map<String, dynamic> getPredictionPerformanceStats() {
    final expired = expiredPredictions;
    if (expired.isEmpty) {
      return {
        'accuracy': 0.0,
        'totalPredictions': 0,
        'successfulPredictions': 0,
      };
    }

    // This would need actual outcome data to calculate accuracy
    // For now, return placeholder values
    return {
      'accuracy': 0.75, // 75% accuracy placeholder
      'totalPredictions': expired.length,
      'successfulPredictions': (expired.length * 0.75).round(),
    };
  }

  // Refresh all data
  Future<void> refreshData() async {
    await Future.wait([
      loadPredictions(),
      loadMarketAnalysis(),
      loadAiInsights(),
    ]);
  }

  // Notification helpers
  List<Prediction> get urgentPredictions {
    return _predictions.where((p) =>
      p.status == PredictionStatus.active &&
      p.daysUntilExpiry <= 3 &&
      p.confidence >= 0.8
    ).toList();
  }

  bool get hasUrgentPredictions => urgentPredictions.isNotEmpty;
}