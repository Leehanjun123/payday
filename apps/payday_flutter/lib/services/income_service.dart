// Income Service Interface and Provider
import 'dart:async';

// Interface for income service
abstract class IncomeServiceInterface {
  Stream<Map<String, dynamic>> get incomeStream;
  Map<String, dynamic> get currentData;

  void startEarning(String type, Map<String, dynamic> params);
  void stopEarning(String type);
  Future<void> claimEarnings(String type);
  Future<void> initializeAutomaticEarnings();
  Future<void> dispose();
  Future<Map<String, dynamic>> getStatistics();
  Future<Map<String, dynamic>> getAvailableRewards();
  Future<void> claimReward(String rewardId);
  Future<List<Map<String, dynamic>>> getTransactionHistory();
  Future<Map<String, dynamic>> getDailyBonus();
  Future<void> claimDailyBonus();
  Future<void> withdraw(double amount, String method);
  Future<Map<String, dynamic>> getWithdrawalInfo();
  Future<void> updateUserProfile(Map<String, dynamic> profile);
  Future<Map<String, dynamic>> getUserProfile();
  Future<double> getTotalIncome();
  Future<List<Map<String, dynamic>>> getAllIncomes();
  Future<Map<String, Map<String, dynamic>>> getIncomeByTypes();
  Future<void> updateIncome(int id, Map<String, dynamic> data);
  Future<void> deleteIncome(int id);
}

// Simple dummy implementation
class _DummyIncomeService implements IncomeServiceInterface {
  final _streamController = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get incomeStream => _streamController.stream;

  @override
  Map<String, dynamic> get currentData => {};

  @override
  void startEarning(String type, Map<String, dynamic> params) {}

  @override
  void stopEarning(String type) {}

  @override
  Future<void> claimEarnings(String type) async {}

  @override
  Future<void> initializeAutomaticEarnings() async {}

  @override
  Future<void> dispose() async {
    await _streamController.close();
  }

  @override
  Future<Map<String, dynamic>> getStatistics() async => {};

  @override
  Future<Map<String, dynamic>> getAvailableRewards() async => {};

  @override
  Future<void> claimReward(String rewardId) async {}

  @override
  Future<List<Map<String, dynamic>>> getTransactionHistory() async => [];

  @override
  Future<Map<String, dynamic>> getDailyBonus() async => {};

  @override
  Future<void> claimDailyBonus() async {}

  @override
  Future<void> withdraw(double amount, String method) async {}

  @override
  Future<Map<String, dynamic>> getWithdrawalInfo() async => {};

  @override
  Future<void> updateUserProfile(Map<String, dynamic> profile) async {}

  @override
  Future<Map<String, dynamic>> getUserProfile() async => {};

  @override
  Future<double> getTotalIncome() async => 0.0;

  @override
  Future<List<Map<String, dynamic>>> getAllIncomes() async => [];

  @override
  Future<Map<String, Map<String, dynamic>>> getIncomeByTypes() async => {};

  @override
  Future<void> updateIncome(int id, Map<String, dynamic> data) async {}

  @override
  Future<void> deleteIncome(int id) async {}
}

// Provider for the income service
class IncomeServiceProvider {
  static final IncomeServiceInterface _instance = _DummyIncomeService();

  static IncomeServiceInterface get instance => _instance;

  // Prevent instantiation
  IncomeServiceProvider._();
}