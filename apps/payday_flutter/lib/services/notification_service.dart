import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'data_service.dart';

// 알림 타입
enum NotificationType {
  daily,           // 매일 정해진 시간
  weekly,          // 주간 요약
  achievement,     // 업적 달성
  motivation,      // 동기부여 메시지
  reminder,        // 기록 리마인더
  goal,           // 목표 관련
  milestone,      // 마일스톤 달성
  streak,         // 연속 기록
}

// 알림 설정 모델
class NotificationSettings {
  final bool enabled;
  final TimeOfDay dailyTime;
  final bool weeklyEnabled;
  final int weeklyDay; // 1-7 (월-일)
  final bool achievementEnabled;
  final bool motivationEnabled;
  final bool reminderEnabled;
  final int reminderHour;
  final bool goalEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool streakEnabled;

  NotificationSettings({
    this.enabled = true,
    this.dailyTime = const TimeOfDay(hour: 9, minute: 0),
    this.weeklyEnabled = true,
    this.weeklyDay = 1,
    this.achievementEnabled = true,
    this.motivationEnabled = true,
    this.reminderEnabled = true,
    this.reminderHour = 20,
    this.goalEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.streakEnabled = true,
  });

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'dailyHour': dailyTime.hour,
    'dailyMinute': dailyTime.minute,
    'weeklyEnabled': weeklyEnabled,
    'weeklyDay': weeklyDay,
    'achievementEnabled': achievementEnabled,
    'motivationEnabled': motivationEnabled,
    'reminderEnabled': reminderEnabled,
    'reminderHour': reminderHour,
    'goalEnabled': goalEnabled,
    'soundEnabled': soundEnabled,
    'vibrationEnabled': vibrationEnabled,
    'streakEnabled': streakEnabled,
  };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: json['enabled'] ?? true,
      dailyTime: TimeOfDay(
        hour: json['dailyHour'] ?? 9,
        minute: json['dailyMinute'] ?? 0,
      ),
      weeklyEnabled: json['weeklyEnabled'] ?? true,
      weeklyDay: json['weeklyDay'] ?? 1,
      achievementEnabled: json['achievementEnabled'] ?? true,
      motivationEnabled: json['motivationEnabled'] ?? true,
      reminderEnabled: json['reminderEnabled'] ?? true,
      reminderHour: json['reminderHour'] ?? 20,
      goalEnabled: json['goalEnabled'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      streakEnabled: json['streakEnabled'] ?? true,
    );
  }

  NotificationSettings copyWith({
    bool? enabled,
    TimeOfDay? dailyTime,
    bool? weeklyEnabled,
    int? weeklyDay,
    bool? achievementEnabled,
    bool? motivationEnabled,
    bool? reminderEnabled,
    int? reminderHour,
    bool? goalEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? streakEnabled,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      dailyTime: dailyTime ?? this.dailyTime,
      weeklyEnabled: weeklyEnabled ?? this.weeklyEnabled,
      weeklyDay: weeklyDay ?? this.weeklyDay,
      achievementEnabled: achievementEnabled ?? this.achievementEnabled,
      motivationEnabled: motivationEnabled ?? this.motivationEnabled,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      goalEnabled: goalEnabled ?? this.goalEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      streakEnabled: streakEnabled ?? this.streakEnabled,
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final DataService _dbService = DataService();
  NotificationSettings _settings = NotificationSettings();
  Timer? _checkTimer;
  static const String _settingsKey = 'notification_settings_v2';
  
  // 알림 채널 ID
  static const String _channelId = 'payday_notifications';
  static const String _channelName = 'PayDay 알림';
  static const String _channelDescription = '수익 목표 달성 및 중요 알림';

  // 알림 ID
  static const int dailyNotificationId = 1;
  static const int weeklyReportId = 2;
  static const int reminderNotificationId = 3;
  static const int goalAchievementId = 4;
  static const int milestoneId = 5;
  static const int streakId = 6;

  Future<void> initialize() async {
    // Android 설정
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 설정
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    // 초기화 설정
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // 플러그인 초기화
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // 설정 로드
    await loadSettings();

    // 알림 권한 요청
    await _requestPermissions();

    // 스케줄 설정
    if (_settings.enabled) {
      await scheduleNotifications();
    }

    // 주기적 체크 시작
    _startPeriodicCheck();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Android 13 이상에서 알림 권한 요청
      final status = await Permission.notification.request();
      print('Notification permission status: $status');
    } else if (Platform.isIOS) {
      // iOS에서 알림 권한 요청
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  void _handleNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final payload = jsonDecode(response.payload!);
        final type = payload['type'];
        print('Notification tapped - Type: $type');
        // 네비게이션 로직은 앱에서 처리
      } catch (e) {
        print('Error handling notification tap: $e');
      }
    }
  }

  // 즉시 알림 표시
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  // 목표 달성 알림
  Future<void> showGoalAchievementNotification({
    required String goalName,
    required double achievedAmount,
    required double targetAmount,
  }) async {
    final percentage = ((achievedAmount / targetAmount) * 100).toStringAsFixed(0);
    
    await showInstantNotification(
      title: '🎯 목표 달성!',
      body: '$goalName 목표를 $percentage% 달성했습니다! (₩${_formatAmount(achievedAmount)} / ₩${_formatAmount(targetAmount)})',
      payload: 'goal_achievement',
    );
  }

  // 설정 로드
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_settingsKey);

    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString);
        _settings = NotificationSettings.fromJson(json);
      } catch (e) {
        _settings = NotificationSettings();
      }
    }
  }

  // 설정 저장
  Future<void> saveSettings(NotificationSettings settings) async {
    _settings = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));

    // 스케줄 재설정
    await cancelAllNotifications();
    if (settings.enabled) {
      await scheduleNotifications();
    }
  }

  // 현재 설정 가져오기
  NotificationSettings getSettings() => _settings;

  // 알림 스케줄링
  Future<void> scheduleNotifications() async {
    if (!_settings.enabled) return;

    // 매일 알림
    await _scheduleDailyNotification();

    // 주간 요약
    if (_settings.weeklyEnabled) {
      await _scheduleWeeklyNotification();
    }

    // 리마인더
    if (_settings.reminderEnabled) {
      await _scheduleReminderNotification();
    }
  }

  // 매일 알림 스케줄
  Future<void> _scheduleDailyNotification() async {
    final now = DateTime.now();
    final scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      _settings.dailyTime.hour,
      _settings.dailyTime.minute,
    );

    final message = await _generateDailyMessage();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    // 매일 반복 알림 설정
    await _flutterLocalNotificationsPlugin.periodicallyShow(
      dailyNotificationId,
      '💰 오늘의 수익 체크',
      message,
      RepeatInterval.daily,
      platformDetails,
      payload: jsonEncode({'type': 'daily'}),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // 주간 요약 알림 스케줄
  Future<void> _scheduleWeeklyNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    // 매주 지정된 요일에 주간 리포트
    await _flutterLocalNotificationsPlugin.periodicallyShow(
      weeklyReportId,
      '📊 주간 수익 리포트',
      await _generateWeeklyMessage(),
      RepeatInterval.weekly,
      platformDetails,
      payload: jsonEncode({'type': 'weekly'}),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // 리마인더 알림 스케줄
  Future<void> _scheduleReminderNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    // 매일 저녁 리마인더
    await _flutterLocalNotificationsPlugin.periodicallyShow(
      reminderNotificationId,
      '📝 오늘 수익을 기록하셨나요?',
      '하루를 마무리하며 수익을 정리해보세요!',
      RepeatInterval.daily,
      platformDetails,
      payload: jsonEncode({'type': 'reminder'}),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // 마일스톤 달성 알림
  Future<void> showMilestoneNotification({
    required double totalAmount,
    required String milestone,
  }) async {
    await showInstantNotification(
      title: '🏆 마일스톤 달성!',
      body: '축하합니다! 총 수익 $milestone을 달성했습니다! (₩${_formatAmount(totalAmount)})',
      payload: 'milestone',
    );
  }

  // 동기부여 메시지 생성
  Future<String> _generateDailyMessage() async {
    final now = DateTime.now();
    final todayIncomes = await _dbService.getIncomesByDateRange(
      DateTime(now.year, now.month, now.day),
      now,
    );

    if (todayIncomes.isNotEmpty) {
      double total = 0;
      for (var income in todayIncomes) {
        total += (income['amount'] as num).toDouble();
      }
      return '오늘 ₩${NumberFormat('#,###').format(total)}을 벌었어요! 대단해요!';
    } else {
      final messages = [
        '오늘도 화이팅! 작은 수익이라도 기록해보세요.',
        '새로운 하루, 새로운 기회! 오늘은 어떤 수익이 있을까요?',
        '꾸준함이 성공의 비결! 오늘도 수익을 만들어보세요.',
        '작은 시작이 큰 변화를 만듭니다. 오늘도 도전!',
        '당신의 노력이 빛날 거예요. 오늘도 파이팅!',
      ];
      return messages[Random().nextInt(messages.length)];
    }
  }

  // 주간 메시지 생성
  Future<String> _generateWeeklyMessage() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    final weekIncomes = await _dbService.getIncomesByDateRange(
      weekStart,
      now,
    );

    double total = 0;
    for (var income in weekIncomes) {
      total += (income['amount'] as num).toDouble();
    }

    if (total > 0) {
      return '이번 주 총 ₩${NumberFormat('#,###').format(total)}의 수익! 자세히 확인해보세요.';
    } else {
      return '이번 주 수익 리포트가 준비되었습니다. 확인해보세요!';
    }
  }

  // 연속 기록 체크 및 알림
  Future<void> checkStreakNotification() async {
    if (!_settings.enabled || !_settings.streakEnabled) return;

    final incomes = await _dbService.getAllIncomes();
    if (incomes.isEmpty) return;

    // 날짜별 그룹화
    final dateMap = <String, bool>{};
    for (var income in incomes) {
      final date = DateTime.parse(income['date'] as String);
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      dateMap[dateKey] = true;
    }

    // 연속 일수 계산
    int streak = 0;
    var checkDate = DateTime.now();

    while (true) {
      final dateKey = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      if (dateMap.containsKey(dateKey)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    // 특정 연속 일수 달성시 알림
    final prefs = await SharedPreferences.getInstance();
    final lastStreak = prefs.getInt('last_notified_streak') ?? 0;

    if (streak > lastStreak && (streak == 3 || streak == 7 || streak == 14 || streak == 30 || streak == 100)) {
      await prefs.setInt('last_notified_streak', streak);
      await showInstantNotification(
        title: '🔥 ${streak}일 연속 기록!',
        body: '대단해요! ${streak}일 동안 꾸준히 기록하고 있어요!',
        payload: jsonEncode({'type': 'streak', 'days': streak}),
      );
    }
  }

  // 주기적 체크 시작
  void _startPeriodicCheck() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(hours: 1), (_) async {
      await _checkForNotifications();
    });
  }

  // 알림 조건 체크
  Future<void> _checkForNotifications() async {
    if (!_settings.enabled) return;

    // 동기부여 메시지 (랜덤 시간)
    if (_settings.motivationEnabled && Random().nextInt(100) < 5) {
      final motivationMessages = [
        '💪 지금 이 순간도 당신의 자산이 됩니다!',
        '🌟 작은 노력이 모여 큰 성과를 만듭니다!',
        '🚀 오늘도 한 걸음 더 나아가세요!',
        '💰 꾸준함이 부를 만듭니다!',
        '🎯 목표를 향해 계속 전진하세요!',
      ];

      await showInstantNotification(
        title: '동기부여 메시지',
        body: motivationMessages[Random().nextInt(motivationMessages.length)],
        payload: jsonEncode({'type': 'motivation'}),
      );
    }

    // 연속 기록 체크
    await checkStreakNotification();

    // 목표 체크
    await checkGoalsAndNotify();
  }

  // 목표 체크 및 알림
  Future<void> checkGoalsAndNotify() async {
    if (!_settings.enabled || !_settings.goalEnabled) {
      return;
    }

    try {
      // 데이터베이스에서 목표와 현재 수익 확인
      await _dbService.database;
      final goals = await _dbService.getAllGoals();
      final incomes = await _dbService.getAllIncomes();

      for (var goal in goals) {
        final goalAmount = goal['target_amount'] as double;
        final goalName = goal['title'] as String;
        
        // 전체 수익 계산 (목표별 타입 구분 없이)
        double currentAmount = 0;
        for (var income in incomes) {
          currentAmount += income['amount'] as double;
        }
        
        // 목표 달성 체크 (90% 이상 달성 시 알림)
        final percentage = (currentAmount / goalAmount) * 100;
        if (percentage >= 90 && percentage < 100) {
          await showInstantNotification(
            title: '🎯 목표 달성 임박!',
            body: '$goalName 목표를 ${percentage.toStringAsFixed(0)}% 달성했습니다!',
            payload: 'goal_near',
          );
        } else if (percentage >= 100) {
          await showGoalAchievementNotification(
            goalName: goalName,
            achievedAmount: currentAmount,
            targetAmount: goalAmount,
          );
        }
      }
      
      // 마일스톤 체크
      double totalIncome = 0;
      for (var income in incomes) {
        totalIncome += income['amount'] as double;
      }
      
      await _checkMilestones(totalIncome);
    } catch (e) {
      print('Error checking goals: $e');
    }
  }

  // 마일스톤 체크
  Future<void> _checkMilestones(double totalAmount) async {
    final prefs = await SharedPreferences.getInstance();
    final milestones = [100000, 500000, 1000000, 5000000, 10000000];
    
    for (var milestone in milestones) {
      final key = 'milestone_$milestone';
      final achieved = prefs.getBool(key) ?? false;
      
      if (!achieved && totalAmount >= milestone) {
        await prefs.setBool(key, true);
        await showMilestoneNotification(
          totalAmount: totalAmount,
          milestone: _formatAmount(milestone.toDouble()),
        );
        break; // 한 번에 하나의 마일스톤만 알림
      }
    }
  }

  // 금액 포맷팅
  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  // 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // 특정 알림 취소
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  // 알림 설정 가져오기
  Future<Map<String, dynamic>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'dailyReminder': prefs.getBool('notification_daily_reminder') ?? true,
      'achievementAlerts': prefs.getBool('notification_achievement') ?? true,
      'weeklyReport': prefs.getBool('notification_weekly_report') ?? true,
      'reminderTime': prefs.getString('notification_reminder_time') ?? '20:00',
    };
  }

  // 알림 설정 저장
  Future<void> saveNotificationSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();

    if (settings['dailyReminder'] != null) {
      await prefs.setBool('notification_daily_reminder', settings['dailyReminder']);
    }
    if (settings['achievementAlerts'] != null) {
      await prefs.setBool('notification_achievement', settings['achievementAlerts']);
    }
    if (settings['weeklyReport'] != null) {
      await prefs.setBool('notification_weekly_report', settings['weeklyReport']);
    }
    if (settings['reminderTime'] != null) {
      await prefs.setString('notification_reminder_time', settings['reminderTime']);
    }

    // 설정에 따라 알림 재스케줄
    if (settings['dailyReminder'] == true) {
      // 매일 알림 설정 - 기존 _scheduleDailyNotification 메서드 활용
      await _scheduleDailyNotification();
    } else if (settings['dailyReminder'] == false) {
      await cancelNotification(1);
    }

    if (settings['weeklyReport'] == true) {
      // 주간 리포트 알림 설정 - 기존 _scheduleWeeklyNotification 메서드 활용
      await _scheduleWeeklyNotification();
    } else if (settings['weeklyReport'] == false) {
      await cancelNotification(100);
    }
  }

  // 리소스 정리
  void dispose() {
    _checkTimer?.cancel();
  }
}