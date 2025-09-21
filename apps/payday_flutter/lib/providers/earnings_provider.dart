import 'package:flutter/material.dart';
import '../models/earning.dart';
import '../services/api_service.dart';

class EarningsProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  EarningSummary? _earningSummary;
  List<Earning> _earnings = [];
  List<PassiveIncomeStream> _passiveIncomeStreams = [];
  MonthlyEarning? _selectedMonthlyEarning;
  bool _isLoading = false;
  String? _errorMessage;

  EarningSummary? get earningSummary => _earningSummary;
  List<Earning> get earnings => _earnings;
  List<PassiveIncomeStream> get passiveIncomeStreams => _passiveIncomeStreams;
  MonthlyEarning? get selectedMonthlyEarning => _selectedMonthlyEarning;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Quick access properties
  double get totalEarnings => _earningSummary?.totalEarnings ?? 0.0;
  double get monthlyEarnings => _earningSummary?.monthlyEarnings ?? 0.0;
  double get yearlyEarnings => _earningSummary?.yearlyEarnings ?? 0.0;
  double get growthRate => _earningSummary?.growthRate ?? 0.0;
  bool get hasGrowth => _earningSummary?.hasGrowth ?? false;

  String get formattedTotalEarnings => _earningSummary?.formattedTotalEarnings ?? '₩0';
  String get formattedMonthlyEarnings => _earningSummary?.formattedMonthlyEarnings ?? '₩0';
  String get formattedYearlyEarnings => _earningSummary?.formattedYearlyEarnings ?? '₩0';

  // Filtered earnings
  List<Earning> get recentEarnings => _earnings.take(10).toList();
  List<Earning> get positiveEarnings => _earnings.where((e) => e.isPositive).toList();
  List<Earning> get recurringEarnings => _earnings.where((e) => e.isRecurring).toList();

  EarningsProvider() {
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

  Future<void> loadEarningSummary() async {
    try {
      _setLoading(true);
      _setError(null);

      final summaryData = await _apiService.getEarningsSummary();
      _earningSummary = EarningSummary.fromJson(summaryData);

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadEarningsHistory() async {
    try {
      _setLoading(true);
      _setError(null);

      final earningsData = await _apiService.getEarningsHistory();
      _earnings = earningsData.map((data) => Earning.fromJson(data)).toList();

      // Sort by date (newest first)
      _earnings.sort((a, b) => b.date.compareTo(a.date));

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMonthlyEarnings(int year, int month) async {
    try {
      _setLoading(true);
      _setError(null);

      final monthlyData = await _apiService.getMonthlyEarnings(year, month);
      _selectedMonthlyEarning = MonthlyEarning.fromJson(monthlyData);

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPassiveIncomeStreams() async {
    try {
      _setLoading(true);
      _setError(null);

      final streamsData = await _apiService.getPassiveIncomeStreams();
      _passiveIncomeStreams = streamsData.map((data) => PassiveIncomeStream.fromJson(data)).toList();

      // Sort by monthly amount (highest first)
      _passiveIncomeStreams.sort((a, b) => b.monthlyAmount.compareTo(a.monthlyAmount));

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Analysis methods
  List<Earning> getEarningsByCategory(EarningCategory category) {
    return _earnings.where((e) => e.category == category).toList();
  }

  List<Earning> getEarningsByDateRange(DateTime start, DateTime end) {
    return _earnings.where((e) =>
      e.date.isAfter(start) && e.date.isBefore(end.add(const Duration(days: 1)))
    ).toList();
  }

  Map<EarningCategory, double> get earningsByCategory {
    final categoryTotals = <EarningCategory, double>{};
    for (final earning in _earnings) {
      categoryTotals[earning.category] =
        (categoryTotals[earning.category] ?? 0) + earning.amount;
    }
    return categoryTotals;
  }

  Map<String, double> get earningsBySource {
    final sourceTotals = <String, double>{};
    for (final earning in _earnings) {
      sourceTotals[earning.source] =
        (sourceTotals[earning.source] ?? 0) + earning.amount;
    }
    return sourceTotals;
  }

  Map<int, double> get earningsByMonth {
    final monthlyTotals = <int, double>{};
    final currentYear = DateTime.now().year;

    for (final earning in _earnings) {
      if (earning.date.year == currentYear) {
        monthlyTotals[earning.date.month] =
          (monthlyTotals[earning.date.month] ?? 0) + earning.amount;
      }
    }
    return monthlyTotals;
  }

  // Chart data methods
  List<Map<String, dynamic>> getCategoryChartData() {
    final categoryTotals = earningsByCategory;
    return categoryTotals.entries.map((entry) => {
      'category': _getCategoryLabel(entry.key),
      'amount': entry.value,
      'percentage': totalEarnings > 0 ? (entry.value / totalEarnings) * 100 : 0,
    }).toList();
  }

  String _getCategoryLabel(EarningCategory category) {
    switch (category) {
      case EarningCategory.dividend:
        return '배당금';
      case EarningCategory.interest:
        return '이자';
      case EarningCategory.rental:
        return '임대료';
      case EarningCategory.royalty:
        return '로열티';
      case EarningCategory.trading:
        return '트레이딩';
      case EarningCategory.staking:
        return '스테이킹';
      case EarningCategory.mining:
        return '마이닝';
      case EarningCategory.cashback:
        return '캐시백';
      case EarningCategory.referral:
        return '추천수수료';
      case EarningCategory.other:
        return '기타';
    }
  }

  List<Map<String, dynamic>> getMonthlyChartData() {
    final monthlyTotals = earningsByMonth;
    final monthNames = [
      '', '1월', '2월', '3월', '4월', '5월', '6월',
      '7월', '8월', '9월', '10월', '11월', '12월'
    ];

    return List.generate(12, (index) {
      final month = index + 1;
      return {
        'month': monthNames[month],
        'amount': monthlyTotals[month] ?? 0.0,
        'monthNumber': month,
      };
    });
  }

  List<Map<String, dynamic>> getPassiveIncomeChartData() {
    return _passiveIncomeStreams.map((stream) => {
      'name': stream.name,
      'monthlyAmount': stream.monthlyAmount,
      'yearlyAmount': stream.yearlyAmount,
      'reliability': stream.reliability,
      'isActive': stream.isActive,
    }).toList();
  }

  // Performance metrics
  double get averageDailyEarnings {
    if (_earnings.isEmpty) return 0.0;

    final now = DateTime.now();
    final startDate = DateTime(now.year, 1, 1);
    final daysPassed = now.difference(startDate).inDays + 1;

    final yearEarnings = getEarningsByDateRange(startDate, now);
    final totalAmount = yearEarnings.fold(0.0, (sum, e) => sum + e.amount);

    return totalAmount / daysPassed;
  }

  double get projectedYearlyEarnings {
    final avgDaily = averageDailyEarnings;
    return avgDaily * 365;
  }

  EarningCategory? get topEarningCategory {
    final categoryTotals = earningsByCategory;
    if (categoryTotals.isEmpty) return null;

    return categoryTotals.entries
      .reduce((a, b) => a.value > b.value ? a : b)
      .key;
  }

  String? get topEarningSource {
    final sourceTotals = earningsBySource;
    if (sourceTotals.isEmpty) return null;

    return sourceTotals.entries
      .reduce((a, b) => a.value > b.value ? a : b)
      .key;
  }

  // Passive income analysis
  double get totalPassiveIncome {
    return _passiveIncomeStreams
      .where((stream) => stream.isActive)
      .fold(0.0, (sum, stream) => sum + stream.monthlyAmount);
  }

  double get totalPassiveIncomeYearly {
    return _passiveIncomeStreams
      .where((stream) => stream.isActive)
      .fold(0.0, (sum, stream) => sum + stream.yearlyAmount);
  }

  String get formattedTotalPassiveIncome =>
    '₩${totalPassiveIncome.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';

  double get passiveIncomeRatio {
    return monthlyEarnings > 0 ? (totalPassiveIncome / monthlyEarnings) : 0.0;
  }

  int get activeStreamsCount => _passiveIncomeStreams.where((s) => s.isActive).length;

  // Trends and insights
  String get earningsTrend {
    if (_earningSummary == null) return '분석 중';

    if (hasGrowth) {
      return '상승 추세 📈';
    } else if (growthRate < -5) {
      return '하락 추세 📉';
    } else {
      return '안정적 📊';
    }
  }

  String get monthlyGoalStatus {
    final targetMonthly = 1000000.0; // 100만원 목표 (설정 가능하게 만들 수 있음)
    final achievement = monthlyEarnings / targetMonthly;

    if (achievement >= 1.0) {
      return '목표 달성! 🎉';
    } else if (achievement >= 0.8) {
      return '목표 근접 💪';
    } else if (achievement >= 0.5) {
      return '목표 진행 중 📈';
    } else {
      return '목표 시작 🚀';
    }
  }

  // Refresh all data
  Future<void> refreshData() async {
    await Future.wait([
      loadEarningSummary(),
      loadEarningsHistory(),
      loadPassiveIncomeStreams(),
    ]);
  }

  // Utility methods
  void selectMonthlyEarning(MonthlyEarning monthlyEarning) {
    _selectedMonthlyEarning = monthlyEarning;
    notifyListeners();
  }

  void clearSelectedMonthlyEarning() {
    _selectedMonthlyEarning = null;
    notifyListeners();
  }
}