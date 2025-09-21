class Prediction {
  final String id;
  final String title;
  final String description;
  final String asset;
  final String assetSymbol;
  final PredictionType type;
  final double currentPrice;
  final double targetPrice;
  final double confidence;
  final PredictionTimeframe timeframe;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<PredictionFactor> factors;
  final Map<String, dynamic> technicalIndicators;
  final PredictionStatus status;

  const Prediction({
    required this.id,
    required this.title,
    required this.description,
    required this.asset,
    required this.assetSymbol,
    required this.type,
    required this.currentPrice,
    required this.targetPrice,
    required this.confidence,
    required this.timeframe,
    required this.createdAt,
    required this.expiresAt,
    required this.factors,
    required this.technicalIndicators,
    required this.status,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      asset: json['asset'] ?? '',
      assetSymbol: json['assetSymbol'] ?? '',
      type: PredictionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PredictionType.hold,
      ),
      currentPrice: (json['currentPrice'] ?? 0).toDouble(),
      targetPrice: (json['targetPrice'] ?? 0).toDouble(),
      confidence: (json['confidence'] ?? 0).toDouble(),
      timeframe: PredictionTimeframe.values.firstWhere(
        (e) => e.name == json['timeframe'],
        orElse: () => PredictionTimeframe.shortTerm,
      ),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      expiresAt: DateTime.parse(json['expiresAt'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String()),
      factors: (json['factors'] as List?)?.map((e) => PredictionFactor.fromJson(e)).toList() ?? [],
      technicalIndicators: json['technicalIndicators'] ?? {},
      status: PredictionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PredictionStatus.active,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'asset': asset,
      'assetSymbol': assetSymbol,
      'type': type.name,
      'currentPrice': currentPrice,
      'targetPrice': targetPrice,
      'confidence': confidence,
      'timeframe': timeframe.name,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'factors': factors.map((e) => e.toJson()).toList(),
      'technicalIndicators': technicalIndicators,
      'status': status.name,
    };
  }

  double get potentialReturn => ((targetPrice - currentPrice) / currentPrice) * 100;
  String get formattedCurrentPrice => '₩${currentPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  String get formattedTargetPrice => '₩${targetPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  String get confidenceText => '${(confidence * 100).toInt()}%';

  bool get isBullish => type == PredictionType.buy || potentialReturn > 0;
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  int get daysUntilExpiry => expiresAt.difference(DateTime.now()).inDays;
}

enum PredictionType { buy, sell, hold }

enum PredictionTimeframe { shortTerm, mediumTerm, longTerm }

enum PredictionStatus { active, completed, expired, cancelled }

class PredictionFactor {
  final String name;
  final String description;
  final double weight;
  final FactorImpact impact;

  const PredictionFactor({
    required this.name,
    required this.description,
    required this.weight,
    required this.impact,
  });

  factory PredictionFactor.fromJson(Map<String, dynamic> json) {
    return PredictionFactor(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
      impact: FactorImpact.values.firstWhere(
        (e) => e.name == json['impact'],
        orElse: () => FactorImpact.neutral,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'weight': weight,
      'impact': impact.name,
    };
  }
}

enum FactorImpact { positive, negative, neutral }

class MarketAnalysis {
  final String id;
  final String market;
  final String sentiment;
  final double sentimentScore;
  final List<String> keyTrends;
  final Map<String, double> sectorPerformance;
  final DateTime updatedAt;
  final String summary;

  const MarketAnalysis({
    required this.id,
    required this.market,
    required this.sentiment,
    required this.sentimentScore,
    required this.keyTrends,
    required this.sectorPerformance,
    required this.updatedAt,
    required this.summary,
  });

  factory MarketAnalysis.fromJson(Map<String, dynamic> json) {
    return MarketAnalysis(
      id: json['id'] ?? '',
      market: json['market'] ?? '',
      sentiment: json['sentiment'] ?? '',
      sentimentScore: (json['sentimentScore'] ?? 0).toDouble(),
      keyTrends: List<String>.from(json['keyTrends'] ?? []),
      sectorPerformance: Map<String, double>.from(json['sectorPerformance'] ?? {}),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      summary: json['summary'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'market': market,
      'sentiment': sentiment,
      'sentimentScore': sentimentScore,
      'keyTrends': keyTrends,
      'sectorPerformance': sectorPerformance,
      'updatedAt': updatedAt.toIso8601String(),
      'summary': summary,
    };
  }

  bool get isBullish => sentimentScore > 0.6;
  bool get isBearish => sentimentScore < 0.4;
}