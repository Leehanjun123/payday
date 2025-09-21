class Portfolio {
  final String id;
  final String name;
  final String description;
  final double totalValue;
  final double totalInvestment;
  final double totalReturn;
  final double returnPercentage;
  final List<Asset> assets;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String riskLevel;
  final bool isActive;

  const Portfolio({
    required this.id,
    required this.name,
    required this.description,
    required this.totalValue,
    required this.totalInvestment,
    required this.totalReturn,
    required this.returnPercentage,
    required this.assets,
    required this.createdAt,
    required this.updatedAt,
    required this.riskLevel,
    this.isActive = true,
  });

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    return Portfolio(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      totalValue: (json['totalValue'] ?? 0).toDouble(),
      totalInvestment: (json['totalInvestment'] ?? 0).toDouble(),
      totalReturn: (json['totalReturn'] ?? 0).toDouble(),
      returnPercentage: (json['returnPercentage'] ?? 0).toDouble(),
      assets: (json['assets'] as List?)?.map((e) => Asset.fromJson(e)).toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      riskLevel: json['riskLevel'] ?? 'medium',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'totalValue': totalValue,
      'totalInvestment': totalInvestment,
      'totalReturn': totalReturn,
      'returnPercentage': returnPercentage,
      'assets': assets.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'riskLevel': riskLevel,
      'isActive': isActive,
    };
  }

  Portfolio copyWith({
    String? id,
    String? name,
    String? description,
    double? totalValue,
    double? totalInvestment,
    double? totalReturn,
    double? returnPercentage,
    List<Asset>? assets,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? riskLevel,
    bool? isActive,
  }) {
    return Portfolio(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      totalValue: totalValue ?? this.totalValue,
      totalInvestment: totalInvestment ?? this.totalInvestment,
      totalReturn: totalReturn ?? this.totalReturn,
      returnPercentage: returnPercentage ?? this.returnPercentage,
      assets: assets ?? this.assets,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      riskLevel: riskLevel ?? this.riskLevel,
      isActive: isActive ?? this.isActive,
    );
  }

  bool get isProfit => totalReturn > 0;
  String get formattedTotalValue => '₩${totalValue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  String get formattedTotalReturn => '₩${totalReturn.abs().toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
}

class Asset {
  final String id;
  final String symbol;
  final String name;
  final String type;
  final double quantity;
  final double currentPrice;
  final double averagePrice;
  final double totalValue;
  final double totalReturn;
  final double returnPercentage;
  final DateTime lastUpdated;

  const Asset({
    required this.id,
    required this.symbol,
    required this.name,
    required this.type,
    required this.quantity,
    required this.currentPrice,
    required this.averagePrice,
    required this.totalValue,
    required this.totalReturn,
    required this.returnPercentage,
    required this.lastUpdated,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] ?? '',
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      currentPrice: (json['currentPrice'] ?? 0).toDouble(),
      averagePrice: (json['averagePrice'] ?? 0).toDouble(),
      totalValue: (json['totalValue'] ?? 0).toDouble(),
      totalReturn: (json['totalReturn'] ?? 0).toDouble(),
      returnPercentage: (json['returnPercentage'] ?? 0).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'name': name,
      'type': type,
      'quantity': quantity,
      'currentPrice': currentPrice,
      'averagePrice': averagePrice,
      'totalValue': totalValue,
      'totalReturn': totalReturn,
      'returnPercentage': returnPercentage,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  bool get isProfit => totalReturn > 0;
  String get formattedCurrentPrice => '₩${currentPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  String get formattedTotalValue => '₩${totalValue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  String get formattedTotalReturn => '₩${totalReturn.abs().toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
}