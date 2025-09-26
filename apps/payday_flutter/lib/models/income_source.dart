// 부수익 소스 모델 - 실제 API와 쉽게 연동 가능한 구조

enum IncomeCategory {
  inApp,      // 앱 내 직접 수익
  external,   // 외부 플랫폼 연동
}

enum IncomeType {
  // 앱 내 직접 수익
  rewardAd,
  dailyMission,
  referral,
  survey,
  quiz,
  walking,
  game,
  review,
  dailyBonus,
  walkingReward,

  // 외부 플랫폼 연동
  youtube,
  blog,
  tiktok,
  instagram,
  freelance,
  stock,
  crypto,
  realestate,
  delivery,
  ecommerce,
  education,
  nft,
  affiliate,
  tutoring,
  realEstate,
  p2p,
  crowdFunding,
  dividends,
  bonds,
  savings,
  reselling,
}

class IncomeSource {
  final String id;
  final String title;
  final String description;
  final String icon;
  final IncomeCategory category;
  final IncomeType type;
  final double monthlyIncome;
  final double todayIncome;
  final double totalIncome;
  final double changePercent;
  final bool isActive;
  final Map<String, dynamic> metadata;
  final DateTime lastUpdated;

  // Additional fields for detail screens
  final double estimatedEarning;
  final int timeRequired;
  final String difficulty;
  final double currentEarnings;
  final int popularity;
  final List<String> requirements;

  String get name => title; // getter for compatibility

  IncomeSource({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.type,
    required this.monthlyIncome,
    required this.todayIncome,
    required this.totalIncome,
    required this.changePercent,
    required this.isActive,
    required this.metadata,
    required this.lastUpdated,
    this.estimatedEarning = 0,
    this.timeRequired = 30,
    this.difficulty = '보통',
    this.currentEarnings = 0,
    this.popularity = 75,
    this.requirements = const [],
  });

  factory IncomeSource.fromJson(Map<String, dynamic> json) {
    return IncomeSource(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      icon: json['icon'],
      category: IncomeCategory.values.firstWhere(
        (e) => e.toString() == 'IncomeCategory.${json['category']}',
      ),
      type: IncomeType.values.firstWhere(
        (e) => e.toString() == 'IncomeType.${json['type']}',
      ),
      monthlyIncome: json['monthlyIncome'].toDouble(),
      todayIncome: json['todayIncome'].toDouble(),
      totalIncome: json['totalIncome'].toDouble(),
      changePercent: json['changePercent'].toDouble(),
      isActive: json['isActive'],
      metadata: json['metadata'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
      estimatedEarning: json['estimatedEarning']?.toDouble() ?? 0,
      timeRequired: json['timeRequired'] ?? 30,
      difficulty: json['difficulty'] ?? '보통',
      currentEarnings: json['currentEarnings']?.toDouble() ?? 0,
      popularity: json['popularity'] ?? 75,
      requirements: List<String>.from(json['requirements'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'category': category.toString().split('.').last,
      'type': type.toString().split('.').last,
      'monthlyIncome': monthlyIncome,
      'todayIncome': todayIncome,
      'totalIncome': totalIncome,
      'changePercent': changePercent,
      'isActive': isActive,
      'metadata': metadata,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

// YouTube 상세 데이터
class YouTubeMetadata {
  final int subscribers;
  final int totalViews;
  final int videoCount;
  final String channelName;
  final double averageWatchTime;
  final double cpm;

  YouTubeMetadata({
    required this.subscribers,
    required this.totalViews,
    required this.videoCount,
    required this.channelName,
    required this.averageWatchTime,
    required this.cpm,
  });
}

// 프리랜서 프로젝트 데이터
class FreelanceProject {
  final String id;
  final String title;
  final String platform;
  final double amount;
  final double progress;
  final DateTime deadline;
  final String status;

  FreelanceProject({
    required this.id,
    required this.title,
    required this.platform,
    required this.amount,
    required this.progress,
    required this.deadline,
    required this.status,
  });
}

// 주식 포트폴리오 데이터
class StockPortfolio {
  final String ticker;
  final String name;
  final int shares;
  final double purchasePrice;
  final double currentPrice;
  final double dividendYield;
  final double yearlyDividend;

  StockPortfolio({
    required this.ticker,
    required this.name,
    required this.shares,
    required this.purchasePrice,
    required this.currentPrice,
    required this.dividendYield,
    required this.yearlyDividend,
  });
}

// 광고 시청 기록
class AdWatchRecord {
  final String id;
  final String adType;
  final double reward;
  final DateTime watchedAt;
  final int duration;

  AdWatchRecord({
    required this.id,
    required this.adType,
    required this.reward,
    required this.watchedAt,
    required this.duration,
  });
}

// 일일 미션
class DailyMission {
  final String id;
  final String title;
  final String description;
  final double reward;
  final int progress;
  final int target;
  final bool isCompleted;
  final DateTime expiresAt;

  DailyMission({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    required this.progress,
    required this.target,
    required this.isCompleted,
    required this.expiresAt,
  });
}