import '../services/database_service.dart';
import '../models/income_source.dart';

// 추상 클래스로 인터페이스 정의 - 나중에 API 서비스로 쉽게 교체 가능
abstract class IncomeServiceInterface {
  Future<int> addIncome({
    required String type,
    required String title,
    required double amount,
    String? description,
    DateTime? date,
  });

  Future<List<Map<String, dynamic>>> getAllIncomes();
  Future<List<Map<String, dynamic>>> getIncomesByType(String type);
  Future<double> getTotalIncome();
  Future<double> getMonthlyIncome(int year, int month);
  Future<Map<String, double>> getIncomeByTypes();

  Future<int> updateIncome(int id, {
    String? title,
    double? amount,
    String? description,
    DateTime? date,
  });

  Future<int> deleteIncome(int id);
}

// 현재는 로컬 데이터베이스 구현 - 나중에 ApiIncomeService로 교체 가능
class LocalIncomeService implements IncomeServiceInterface {
  final DatabaseService _databaseService = DatabaseService();

  @override
  Future<int> addIncome({
    required String type,
    required String title,
    required double amount,
    String? description,
    DateTime? date,
  }) async {
    return await _databaseService.addIncome(
      type: type,
      title: title,
      amount: amount,
      description: description,
      date: date,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getAllIncomes() async {
    return await _databaseService.getAllIncomes();
  }

  @override
  Future<List<Map<String, dynamic>>> getIncomesByType(String type) async {
    return await _databaseService.getIncomesByType(type);
  }

  @override
  Future<double> getTotalIncome() async {
    return await _databaseService.getTotalIncome();
  }

  @override
  Future<double> getMonthlyIncome(int year, int month) async {
    return await _databaseService.getMonthlyIncome(year, month);
  }

  @override
  Future<Map<String, double>> getIncomeByTypes() async {
    return await _databaseService.getIncomeByTypes();
  }

  @override
  Future<int> updateIncome(int id, {
    String? title,
    double? amount,
    String? description,
    DateTime? date,
  }) async {
    return await _databaseService.updateIncome(
      id,
      title: title,
      amount: amount,
      description: description,
      date: date,
    );
  }

  @override
  Future<int> deleteIncome(int id) async {
    return await _databaseService.deleteIncome(id);
  }
}

// 나중에 API 구현할 때 사용할 클래스 (예시)
class ApiIncomeService implements IncomeServiceInterface {
  // final ApiClient _apiClient = ApiClient();

  @override
  Future<int> addIncome({
    required String type,
    required String title,
    required double amount,
    String? description,
    DateTime? date,
  }) async {
    // TODO: API 호출로 교체
    // final response = await _apiClient.post('/incomes', {
    //   'type': type,
    //   'title': title,
    //   'amount': amount,
    //   'description': description,
    //   'date': date?.toIso8601String(),
    // });
    // return response['id'];

    throw UnimplementedError('API 구현 필요');
  }

  @override
  Future<List<Map<String, dynamic>>> getAllIncomes() async {
    // TODO: API 호출로 교체
    // final response = await _apiClient.get('/incomes');
    // return List<Map<String, dynamic>>.from(response['data']);

    throw UnimplementedError('API 구현 필요');
  }

  @override
  Future<List<Map<String, dynamic>>> getIncomesByType(String type) async {
    // TODO: API 호출로 교체
    throw UnimplementedError('API 구현 필요');
  }

  @override
  Future<double> getTotalIncome() async {
    // TODO: API 호출로 교체
    throw UnimplementedError('API 구현 필요');
  }

  @override
  Future<double> getMonthlyIncome(int year, int month) async {
    // TODO: API 호출로 교체
    throw UnimplementedError('API 구현 필요');
  }

  @override
  Future<Map<String, double>> getIncomeByTypes() async {
    // TODO: API 호출로 교체
    throw UnimplementedError('API 구현 필요');
  }

  @override
  Future<int> updateIncome(int id, {
    String? title,
    double? amount,
    String? description,
    DateTime? date,
  }) async {
    // TODO: API 호출로 교체
    throw UnimplementedError('API 구현 필요');
  }

  @override
  Future<int> deleteIncome(int id) async {
    // TODO: API 호출로 교체
    throw UnimplementedError('API 구현 필요');
  }
}

// 싱글톤 패턴으로 서비스 인스턴스 관리
class IncomeServiceProvider {
  static IncomeServiceInterface? _instance;

  static IncomeServiceInterface get instance {
    // 개발 환경에서는 로컬 서비스 사용
    // 프로덕션에서는 API 서비스 사용
    _instance ??= LocalIncomeService(); // 나중에 ApiIncomeService()로 교체
    return _instance!;
  }

  // 테스트나 다른 환경에서 서비스를 교체할 수 있도록
  static void setInstance(IncomeServiceInterface service) {
    _instance = service;
  }
}