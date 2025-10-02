import 'dart:async';
import 'data_service.dart';
import 'cash_service.dart';
import 'analytics_service.dart';

class RevenueService {
  static final RevenueService _instance = RevenueService._internal();
  factory RevenueService() => _instance;
  RevenueService._internal();

  final DataService _dataService = DataService();
  final CashService _cashService = CashService();

  // 수익 분배 비율 (사용자:플랫폼)
  static const Map<String, double> REVENUE_SHARE = {
    'admob': 0.5,         // 50% 사용자에게
    'task': 0.4,          // 40% 사용자에게
    'talent': 0.8,        // 80% 판매자에게
    'affiliate': 0.7,     // 70% 사용자에게
    'survey': 0.5,        // 50% 사용자에게
  };

  // 플랫폼 수익 추적
  Map<String, double> _platformRevenue = {
    'daily': 0,
    'weekly': 0,
    'monthly': 0,
    'total': 0,
  };

  // 실시간 수익 데이터
  StreamController<Map<String, double>> _revenueStreamController =
    StreamController<Map<String, double>>.broadcast();

  Stream<Map<String, double>> get revenueStream => _revenueStreamController.stream;

  Future<void> initialize() async {
    await _loadRevenueData();
    _startDailyReset();
  }

  Future<void> _loadRevenueData() async {
    final savedRevenue = await _dataService.getSetting('platform_revenue');
    if (savedRevenue != null) {
      _platformRevenue = Map<String, double>.from(savedRevenue);
    }
  }

  // AdMob 광고 수익 처리
  Future<void> processAdRevenue({
    required String adType,
    required double revenue,
    required String userId,
  }) async {
    // 플랫폼 수익 기록
    final platformShare = revenue * (1 - REVENUE_SHARE['admob']!);
    final userShare = revenue * REVENUE_SHARE['admob']!;

    await _recordPlatformRevenue(platformShare);

    // 사용자에게 지급
    await _cashService.earnCash(
      source: 'ad_view',
      amount: userShare,
      description: '$adType 광고 시청',
      metadata: {
        'ad_type': adType,
        'platform_revenue': platformShare,
        'total_revenue': revenue,
      },
    );

    // 애널리틱스
    await AnalyticsService.logEvent(
      name: 'ad_revenue_generated',
      parameters: {
        'ad_type': adType,
        'total_revenue': revenue,
        'user_share': userShare,
        'platform_share': platformShare,
      },
    );
  }

  // 태스크 수수료 처리
  Future<void> processTaskCommission({
    required String taskId,
    required double taskValue,
    required String workerId,
    required String clientId,
  }) async {
    final workerShare = taskValue * REVENUE_SHARE['task']!;
    final platformCommission = taskValue * (1 - REVENUE_SHARE['task']!);

    // 플랫폼 수수료 기록
    await _recordPlatformRevenue(platformCommission);

    // 작업자에게 지급
    await _cashService.earnCash(
      source: 'task',
      amount: workerShare,
      description: '태스크 완료',
      metadata: {
        'task_id': taskId,
        'commission': platformCommission,
      },
    );

    _updateRevenueStream();
  }

  // 플랫폼 수익 기록
  Future<void> _recordPlatformRevenue(double amount) async {
    _platformRevenue['daily'] = (_platformRevenue['daily'] ?? 0) + amount;
    _platformRevenue['weekly'] = (_platformRevenue['weekly'] ?? 0) + amount;
    _platformRevenue['monthly'] = (_platformRevenue['monthly'] ?? 0) + amount;
    _platformRevenue['total'] = (_platformRevenue['total'] ?? 0) + amount;

    await _dataService.saveSetting('platform_revenue', _platformRevenue);
    _updateRevenueStream();
  }

  // 실시간 수익 업데이트
  void _updateRevenueStream() {
    _revenueStreamController.add(Map<String, double>.from(_platformRevenue));
  }

  // 일일 리셋
  void _startDailyReset() {
    // 매일 자정에 리셋
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    Timer(timeUntilMidnight, () {
      _resetDailyRevenue();
      // 24시간마다 반복
      Timer.periodic(Duration(hours: 24), (_) => _resetDailyRevenue());
    });

    // 주간 리셋 (월요일)
    if (now.weekday == DateTime.monday) {
      _resetWeeklyRevenue();
    }

    // 월간 리셋 (1일)
    if (now.day == 1) {
      _resetMonthlyRevenue();
    }
  }

  void _resetDailyRevenue() {
    _platformRevenue['daily'] = 0;
    _saveRevenue();
  }

  void _resetWeeklyRevenue() {
    _platformRevenue['weekly'] = 0;
    _saveRevenue();
  }

  void _resetMonthlyRevenue() {
    _platformRevenue['monthly'] = 0;
    _saveRevenue();
  }

  Future<void> _saveRevenue() async {
    await _dataService.saveSetting('platform_revenue', _platformRevenue);
    _updateRevenueStream();
  }

  // 수익 통계 가져오기
  Map<String, double> getRevenueStats() {
    return Map<String, double>.from(_platformRevenue);
  }

  // 예상 수익 계산
  double calculateExpectedRevenue({
    required int userCount,
    required double avgDailyActiveRate,
    required double avgRevenuePerUser,
  }) {
    final activeUsers = userCount * avgDailyActiveRate;
    final dailyRevenue = activeUsers * avgRevenuePerUser;
    return dailyRevenue * 30; // 월 예상 수익
  }

  // ROI 계산
  Map<String, double> calculateROI({
    required double monthlyRevenue,
    required double monthlyExpense,
    required double userAcquisitionCost,
    required int newUsers,
  }) {
    final profit = monthlyRevenue - monthlyExpense;
    final acquisitionExpense = userAcquisitionCost * newUsers;
    final roi = (profit / acquisitionExpense) * 100;

    return {
      'revenue': monthlyRevenue,
      'expense': monthlyExpense,
      'profit': profit,
      'roi': roi,
      'profit_margin': (profit / monthlyRevenue) * 100,
    };
  }

  void dispose() {
    _revenueStreamController.close();
  }
}