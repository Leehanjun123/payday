import 'package:flutter/material.dart';
import '../models/portfolio.dart';
import '../services/api_service.dart';

class InvestmentProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Portfolio> _portfolios = [];
  Portfolio? _selectedPortfolio;
  List<dynamic> _investmentHistory = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Portfolio> get portfolios => _portfolios;
  Portfolio? get selectedPortfolio => _selectedPortfolio;
  List<dynamic> get investmentHistory => _investmentHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalValue => _portfolios.fold(0.0, (sum, portfolio) => sum + portfolio.totalValue);
  double get totalInvestment => _portfolios.fold(0.0, (sum, portfolio) => sum + portfolio.totalInvestment);
  double get totalReturn => _portfolios.fold(0.0, (sum, portfolio) => sum + portfolio.totalReturn);
  double get totalReturnPercentage => totalInvestment > 0 ? (totalReturn / totalInvestment) * 100 : 0.0;

  String get formattedTotalValue => '₩${totalValue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  String get formattedTotalReturn => '₩${totalReturn.abs().toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  bool get hasProfit => totalReturn > 0;

  InvestmentProvider() {
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

  Future<void> loadPortfolios() async {
    try {
      _setLoading(true);
      _setError(null);

      final portfoliosData = await _apiService.getPortfolios();
      _portfolios = portfoliosData.map((data) => Portfolio.fromJson(data)).toList();

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPortfolio(String portfolioId) async {
    try {
      _setLoading(true);
      _setError(null);

      final portfolioData = await _apiService.getPortfolio(portfolioId);
      _selectedPortfolio = Portfolio.fromJson(portfolioData['portfolio'] ?? portfolioData);

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createPortfolio({
    required String name,
    required String description,
    required String riskLevel,
    required Map<String, double> assetAllocation,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final portfolioData = {
        'name': name,
        'description': description,
        'riskLevel': riskLevel,
        'assetAllocation': assetAllocation,
      };

      final response = await _apiService.createPortfolio(portfolioData);

      if (response['success'] == true || response['portfolio'] != null) {
        final newPortfolio = Portfolio.fromJson(response['portfolio'] ?? response);
        _portfolios.add(newPortfolio);
        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? '포트폴리오 생성에 실패했습니다.');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadInvestmentHistory() async {
    try {
      _setLoading(true);
      _setError(null);

      _investmentHistory = await _apiService.getInvestmentHistory();

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void selectPortfolio(Portfolio portfolio) {
    _selectedPortfolio = portfolio;
    notifyListeners();
  }

  void clearSelectedPortfolio() {
    _selectedPortfolio = null;
    notifyListeners();
  }

  // Portfolio analysis methods
  List<Portfolio> get profitablePortfolios => _portfolios.where((p) => p.isProfit).toList();
  List<Portfolio> get losingPortfolios => _portfolios.where((p) => !p.isProfit).toList();

  Portfolio? get bestPerformingPortfolio {
    if (_portfolios.isEmpty) return null;
    return _portfolios.reduce((a, b) => a.returnPercentage > b.returnPercentage ? a : b);
  }

  Portfolio? get worstPerformingPortfolio {
    if (_portfolios.isEmpty) return null;
    return _portfolios.reduce((a, b) => a.returnPercentage < b.returnPercentage ? a : b);
  }

  Map<String, double> get riskLevelBreakdown {
    final breakdown = <String, double>{};
    for (final portfolio in _portfolios) {
      breakdown[portfolio.riskLevel] = (breakdown[portfolio.riskLevel] ?? 0) + portfolio.totalValue;
    }
    return breakdown;
  }

  Map<String, double> get assetTypeBreakdown {
    final breakdown = <String, double>{};
    for (final portfolio in _portfolios) {
      for (final asset in portfolio.assets) {
        breakdown[asset.type] = (breakdown[asset.type] ?? 0) + asset.totalValue;
      }
    }
    return breakdown;
  }

  // Utility methods for chart data
  List<Map<String, dynamic>> getPortfolioChartData() {
    return _portfolios.map((portfolio) => {
      'name': portfolio.name,
      'value': portfolio.totalValue,
      'return': portfolio.totalReturn,
      'returnPercentage': portfolio.returnPercentage,
    }).toList();
  }

  List<Map<String, dynamic>> getAssetAllocationChartData() {
    final assetBreakdown = assetTypeBreakdown;
    return assetBreakdown.entries.map((entry) => {
      'type': entry.key,
      'value': entry.value,
      'percentage': totalValue > 0 ? (entry.value / totalValue) * 100 : 0,
    }).toList();
  }

  List<Map<String, dynamic>> getRiskAllocationChartData() {
    final riskBreakdown = riskLevelBreakdown;
    return riskBreakdown.entries.map((entry) => {
      'risk': entry.key,
      'value': entry.value,
      'percentage': totalValue > 0 ? (entry.value / totalValue) * 100 : 0,
    }).toList();
  }

  // Performance metrics
  double get diversificationScore {
    if (_portfolios.isEmpty) return 0.0;

    final assetTypes = <String>{};
    for (final portfolio in _portfolios) {
      for (final asset in portfolio.assets) {
        assetTypes.add(asset.type);
      }
    }

    // Simple diversification score based on number of asset types
    return (assetTypes.length / 10).clamp(0.0, 1.0);
  }

  double get averageReturn {
    if (_portfolios.isEmpty) return 0.0;
    return _portfolios.map((p) => p.returnPercentage).reduce((a, b) => a + b) / _portfolios.length;
  }

  String get performanceSummary {
    if (_portfolios.isEmpty) return '포트폴리오가 없습니다.';

    final profitCount = profitablePortfolios.length;
    final totalCount = _portfolios.length;
    final profitRatio = (profitCount / totalCount * 100).toInt();

    return '$totalCount개 포트폴리오 중 $profitCount개 수익 ($profitRatio%)';
  }

  // Refresh all data
  Future<void> refreshData() async {
    await Future.wait([
      loadPortfolios(),
      loadInvestmentHistory(),
    ]);
  }
}