class Earning {
  final String id;
  final String source;
  final String type;
  final double amount;
  final String currency;
  final DateTime date;
  final String description;
  final EarningCategory category;
  final Map<String, dynamic>? metadata;
  final bool isRecurring;
  final String? portfolioId;

  const Earning({
    required this.id,
    required this.source,
    required this.type,
    required this.amount,
    required this.currency,
    required this.date,
    required this.description,
    required this.category,
    this.metadata,
    this.isRecurring = false,
    this.portfolioId,
  });

  factory Earning.fromJson(Map<String, dynamic> json) {
    return Earning(
      id: json['id'] ?? '',
      source: json['source'] ?? '',
      type: json['type'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'KRW',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      description: json['description'] ?? '',
      category: EarningCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => EarningCategory.other,
      ),
      metadata: json['metadata'],
      isRecurring: json['isRecurring'] ?? false,
      portfolioId: json['portfolioId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source,
      'type': type,
      'amount': amount,
      'currency': currency,
      'date': date.toIso8601String(),
      'description': description,
      'category': category.name,
      'metadata': metadata,
      'isRecurring': isRecurring,
      'portfolioId': portfolioId,
    };
  }

  String get formattedAmount => '₩${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '오늘';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.year}년 ${date.month}월 ${date.day}일';
    }
  }

  bool get isPositive => amount > 0;
}

enum EarningCategory {
  dividend,      // 배당금
  interest,      // 이자
  rental,        // 임대료
  royalty,       // 로열티
  trading,       // 트레이딩
  staking,       // 스테이킹
  mining,        // 마이닝
  cashback,      // 캐시백
  referral,      // 추천수수료
  other,         // 기타
}

class EarningSummary {
  final double totalEarnings;
  final double monthlyEarnings;
  final double yearlyEarnings;
  final double averageMonthly;
  final double growthRate;
  final Map<EarningCategory, double> categoryBreakdown;
  final List<MonthlyEarning> monthlyHistory;
  final DateTime lastUpdated;

  const EarningSummary({
    required this.totalEarnings,
    required this.monthlyEarnings,
    required this.yearlyEarnings,
    required this.averageMonthly,
    required this.growthRate,
    required this.categoryBreakdown,
    required this.monthlyHistory,
    required this.lastUpdated,
  });

  factory EarningSummary.fromJson(Map<String, dynamic> json) {
    return EarningSummary(
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      monthlyEarnings: (json['monthlyEarnings'] ?? 0).toDouble(),
      yearlyEarnings: (json['yearlyEarnings'] ?? 0).toDouble(),
      averageMonthly: (json['averageMonthly'] ?? 0).toDouble(),
      growthRate: (json['growthRate'] ?? 0).toDouble(),
      categoryBreakdown: Map<EarningCategory, double>.fromEntries(
        (json['categoryBreakdown'] as Map<String, dynamic>? ?? {}).entries.map(
          (e) => MapEntry(
            EarningCategory.values.firstWhere(
              (cat) => cat.name == e.key,
              orElse: () => EarningCategory.other,
            ),
            (e.value ?? 0).toDouble(),
          ),
        ),
      ),
      monthlyHistory: (json['monthlyHistory'] as List?)?.map((e) => MonthlyEarning.fromJson(e)).toList() ?? [],
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalEarnings': totalEarnings,
      'monthlyEarnings': monthlyEarnings,
      'yearlyEarnings': yearlyEarnings,
      'averageMonthly': averageMonthly,
      'growthRate': growthRate,
      'categoryBreakdown': categoryBreakdown.map((key, value) => MapEntry(key.name, value)),
      'monthlyHistory': monthlyHistory.map((e) => e.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  String get formattedTotalEarnings => '₩${totalEarnings.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  String get formattedMonthlyEarnings => '₩${monthlyEarnings.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  String get formattedYearlyEarnings => '₩${yearlyEarnings.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  String get formattedAverageMonthly => '₩${averageMonthly.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';

  bool get hasGrowth => growthRate > 0;
  String get growthText => '${growthRate.abs().toStringAsFixed(1)}%';
}

class MonthlyEarning {
  final int year;
  final int month;
  final double amount;
  final int transactionCount;
  final Map<EarningCategory, double> categoryBreakdown;

  const MonthlyEarning({
    required this.year,
    required this.month,
    required this.amount,
    required this.transactionCount,
    required this.categoryBreakdown,
  });

  factory MonthlyEarning.fromJson(Map<String, dynamic> json) {
    return MonthlyEarning(
      year: json['year'] ?? DateTime.now().year,
      month: json['month'] ?? DateTime.now().month,
      amount: (json['amount'] ?? 0).toDouble(),
      transactionCount: json['transactionCount'] ?? 0,
      categoryBreakdown: Map<EarningCategory, double>.fromEntries(
        (json['categoryBreakdown'] as Map<String, dynamic>? ?? {}).entries.map(
          (e) => MapEntry(
            EarningCategory.values.firstWhere(
              (cat) => cat.name == e.key,
              orElse: () => EarningCategory.other,
            ),
            (e.value ?? 0).toDouble(),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'amount': amount,
      'transactionCount': transactionCount,
      'categoryBreakdown': categoryBreakdown.map((key, value) => MapEntry(key.name, value)),
    };
  }

  String get formattedAmount => '₩${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  String get monthName => [
    '', '1월', '2월', '3월', '4월', '5월', '6월',
    '7월', '8월', '9월', '10월', '11월', '12월'
  ][month];
  String get displayName => '$year년 $monthName';
}

class PassiveIncomeStream {
  final String id;
  final String name;
  final String description;
  final String type;
  final double monthlyAmount;
  final double yearlyAmount;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final double reliability;
  final Map<String, dynamic>? settings;

  const PassiveIncomeStream({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.monthlyAmount,
    required this.yearlyAmount,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    required this.reliability,
    this.settings,
  });

  factory PassiveIncomeStream.fromJson(Map<String, dynamic> json) {
    return PassiveIncomeStream(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      monthlyAmount: (json['monthlyAmount'] ?? 0).toDouble(),
      yearlyAmount: (json['yearlyAmount'] ?? 0).toDouble(),
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isActive: json['isActive'] ?? true,
      reliability: (json['reliability'] ?? 0).toDouble(),
      settings: json['settings'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'monthlyAmount': monthlyAmount,
      'yearlyAmount': yearlyAmount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
      'reliability': reliability,
      'settings': settings,
    };
  }

  String get formattedMonthlyAmount => '₩${monthlyAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  String get formattedYearlyAmount => '₩${yearlyAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  String get reliabilityText => '${(reliability * 100).toInt()}%';
}