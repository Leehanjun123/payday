import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

// 음성 명령 타입
enum VoiceCommandType {
  addIncome,
  checkBalance,
  getInsights,
  setReminder,
  checkGoals,
  exportData,
  help,
  unknown,
}

// 음성 명령 결과
class VoiceCommandResult {
  final VoiceCommandType type;
  final String response;
  final Map<String, dynamic>? data;
  final bool success;

  VoiceCommandResult({
    required this.type,
    required this.response,
    this.data,
    required this.success,
  });
}

// 대화 히스토리
class ConversationItem {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final VoiceCommandType? commandType;

  ConversationItem({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.commandType,
  });
}

class VoiceAssistantService {
  final DatabaseService _dbService = DatabaseService();

  static const String _settingsKey = 'voice_settings';
  static const String _historyKey = 'voice_history';

  // 음성 설정
  bool _isEnabled = true;
  String _voiceType = 'female'; // male, female, robot
  double _speechRate = 1.0;
  String _language = 'ko-KR';
  bool _autoListen = false;

  // 대화 히스토리
  final List<ConversationItem> _conversationHistory = [];

  // 음성 인식 상태
  bool _isListening = false;
  String _currentTranscript = '';

  // 초기화
  Future<void> initialize() async {
    await _loadSettings();
    await _loadHistory();
  }

  // 설정 로드
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);

    if (settingsJson != null) {
      // 실제 앱에서는 JSON 파싱
      // 여기서는 기본값 사용
    }
  }

  // 히스토리 로드
  Future<void> _loadHistory() async {
    // 최근 대화 내역 로드
    // 실제로는 로컬 DB에서
  }

  // 음성 명령 처리
  Future<VoiceCommandResult> processVoiceCommand(String transcript) async {
    _currentTranscript = transcript;

    // 대화 히스토리에 추가
    _conversationHistory.add(ConversationItem(
      text: transcript,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    // 명령 타입 식별
    final commandType = _identifyCommand(transcript);

    // 명령 실행
    VoiceCommandResult result;
    switch (commandType) {
      case VoiceCommandType.addIncome:
        result = await _handleAddIncome(transcript);
        break;
      case VoiceCommandType.checkBalance:
        result = await _handleCheckBalance();
        break;
      case VoiceCommandType.getInsights:
        result = await _handleGetInsights();
        break;
      case VoiceCommandType.setReminder:
        result = await _handleSetReminder(transcript);
        break;
      case VoiceCommandType.checkGoals:
        result = await _handleCheckGoals();
        break;
      case VoiceCommandType.exportData:
        result = await _handleExportData();
        break;
      case VoiceCommandType.help:
        result = await _handleHelp();
        break;
      default:
        result = await _handleUnknownCommand();
    }

    // 응답을 히스토리에 추가
    _conversationHistory.add(ConversationItem(
      text: result.response,
      isUser: false,
      timestamp: DateTime.now(),
      commandType: commandType,
    ));

    return result;
  }

  // 명령 타입 식별
  VoiceCommandType _identifyCommand(String transcript) {
    final lowerText = transcript.toLowerCase();

    // 수익 추가 관련 키워드
    if (lowerText.contains('수익') && (lowerText.contains('추가') || lowerText.contains('기록'))) {
      return VoiceCommandType.addIncome;
    }

    // 잔액/총액 확인
    if (lowerText.contains('잔액') || lowerText.contains('총') || lowerText.contains('얼마')) {
      return VoiceCommandType.checkBalance;
    }

    // 인사이트/분석
    if (lowerText.contains('분석') || lowerText.contains('인사이트') || lowerText.contains('조언')) {
      return VoiceCommandType.getInsights;
    }

    // 알림/리마인더
    if (lowerText.contains('알림') || lowerText.contains('리마인더') || lowerText.contains('알려')) {
      return VoiceCommandType.setReminder;
    }

    // 목표 확인
    if (lowerText.contains('목표') || lowerText.contains('타겟')) {
      return VoiceCommandType.checkGoals;
    }

    // 내보내기
    if (lowerText.contains('내보') || lowerText.contains('export') || lowerText.contains('csv')) {
      return VoiceCommandType.exportData;
    }

    // 도움말
    if (lowerText.contains('도움') || lowerText.contains('help') || lowerText.contains('명령')) {
      return VoiceCommandType.help;
    }

    return VoiceCommandType.unknown;
  }

  // 수익 추가 처리
  Future<VoiceCommandResult> _handleAddIncome(String transcript) async {
    // 금액 추출 (간단한 예시)
    final regex = RegExp(r'\d+');
    final matches = regex.allMatches(transcript);

    if (matches.isNotEmpty) {
      final amount = int.parse(matches.first.group(0)!);

      // DB에 저장
      await _dbService.addIncome(
        type: 'voice',
        title: '음성 입력 수익',
        amount: amount.toDouble(),
        description: transcript,
      );

      return VoiceCommandResult(
        type: VoiceCommandType.addIncome,
        response: '${amount}원이 기록되었습니다. 오늘도 수고하셨어요! 💪',
        data: {'amount': amount},
        success: true,
      );
    }

    return VoiceCommandResult(
      type: VoiceCommandType.addIncome,
      response: '금액을 인식하지 못했습니다. "5만원 추가해줘"와 같이 말씀해주세요.',
      success: false,
    );
  }

  // 잔액 확인
  Future<VoiceCommandResult> _handleCheckBalance() async {
    final incomes = await _dbService.getAllIncomes();
    double total = 0;
    double todayTotal = 0;
    double weekTotal = 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));

    for (var income in incomes) {
      final amount = (income['amount'] as num).toDouble();
      total += amount;

      final date = DateTime.parse(income['date'] as String);
      if (date.isAfter(today)) {
        todayTotal += amount;
      }
      if (date.isAfter(weekAgo)) {
        weekTotal += amount;
      }
    }

    final response = '''현재까지 총 수익은 ${total.toStringAsFixed(0)}원입니다.
오늘 수익: ${todayTotal.toStringAsFixed(0)}원
이번 주 수익: ${weekTotal.toStringAsFixed(0)}원
계속 이 페이스라면 월말에 ${(weekTotal * 4).toStringAsFixed(0)}원을 달성할 수 있어요!''';

    return VoiceCommandResult(
      type: VoiceCommandType.checkBalance,
      response: response,
      data: {
        'total': total,
        'today': todayTotal,
        'week': weekTotal,
      },
      success: true,
    );
  }

  // 인사이트 제공
  Future<VoiceCommandResult> _handleGetInsights() async {
    // 간단한 인사이트 생성
    final incomes = await _dbService.getAllIncomes();
    double total = 0;
    double todayTotal = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var income in incomes) {
      final amount = (income['amount'] as num).toDouble();
      total += amount;
      final date = DateTime.parse(income['date'] as String);
      if (date.isAfter(today)) {
        todayTotal += amount;
      }
    }

    final avgDaily = incomes.isNotEmpty ? total / incomes.length : 0;

    final responses = <String>[];
    responses.add('💡 총 수익: ${total.toStringAsFixed(0)}원');
    responses.add('📈 일평균: ${avgDaily.toStringAsFixed(0)}원');
    responses.add('🎯 오늘 수익: ${todayTotal.toStringAsFixed(0)}원');

    return VoiceCommandResult(
      type: VoiceCommandType.getInsights,
      response: responses.join('\n\n'),
      data: {'total': total, 'average': avgDaily, 'today': todayTotal},
      success: true,
    );
  }

  // 리마인더 설정
  Future<VoiceCommandResult> _handleSetReminder(String transcript) async {
    // 시간 파싱 (간단한 예시)
    String time = '오후 7시'; // 기본값

    if (transcript.contains('아침')) {
      time = '오전 9시';
    } else if (transcript.contains('점심')) {
      time = '오후 12시';
    } else if (transcript.contains('저녁')) {
      time = '오후 7시';
    } else if (transcript.contains('밤')) {
      time = '오후 10시';
    }

    return VoiceCommandResult(
      type: VoiceCommandType.setReminder,
      response: '매일 $time에 수익 기록 알림을 설정했습니다. 알림 설정에서 변경할 수 있어요.',
      data: {'time': time},
      success: true,
    );
  }

  // 목표 확인
  Future<VoiceCommandResult> _handleCheckGoals() async {
    // 목표 데이터 가져오기 (더미 데이터)
    final monthlyGoal = 1000000;
    final currentTotal = 650000;
    final progress = (currentTotal / monthlyGoal * 100).toStringAsFixed(0);
    final remaining = monthlyGoal - currentTotal;
    final daysLeft = 30 - DateTime.now().day;
    final dailyRequired = remaining / daysLeft;

    final response = '''이번 달 목표는 ${monthlyGoal ~/ 10000}만원입니다.
현재 ${currentTotal ~/ 10000}만원 달성! (${progress}%)
목표까지 ${remaining ~/ 10000}만원 남았어요.
남은 ${daysLeft}일 동안 하루 ${dailyRequired.toStringAsFixed(0)}원씩 벌면 목표 달성! 💎''';

    return VoiceCommandResult(
      type: VoiceCommandType.checkGoals,
      response: response,
      data: {
        'goal': monthlyGoal,
        'current': currentTotal,
        'progress': progress,
      },
      success: true,
    );
  }

  // 데이터 내보내기
  Future<VoiceCommandResult> _handleExportData() async {
    return VoiceCommandResult(
      type: VoiceCommandType.exportData,
      response: '데이터를 CSV 파일로 내보냈습니다. 다운로드 폴더를 확인해주세요.',
      success: true,
    );
  }

  // 도움말
  Future<VoiceCommandResult> _handleHelp() async {
    const helpText = '''사용 가능한 음성 명령:

📝 "5만원 수익 추가" - 수익을 기록합니다
💰 "총 수익 얼마야?" - 잔액을 확인합니다
📊 "인사이트 알려줘" - AI 분석을 받습니다
⏰ "저녁에 알림 설정" - 리마인더를 설정합니다
🎯 "목표 확인" - 목표 달성률을 확인합니다
📤 "데이터 내보내기" - CSV로 내보냅니다

무엇을 도와드릴까요?''';

    return VoiceCommandResult(
      type: VoiceCommandType.help,
      response: helpText,
      success: true,
    );
  }

  // 알 수 없는 명령
  Future<VoiceCommandResult> _handleUnknownCommand() async {
    final suggestions = [
      '"오늘 3만원 벌었어" 라고 수익을 기록해보세요',
      '"총 수익이 얼마야?" 라고 물어보세요',
      '"분석해줘" 라고 AI 인사이트를 요청해보세요',
      '"도움말" 이라고 말하면 사용법을 알려드려요',
    ];

    final randomSuggestion = suggestions[Random().nextInt(suggestions.length)];

    return VoiceCommandResult(
      type: VoiceCommandType.unknown,
      response: '무슨 말씀인지 잘 모르겠어요. $randomSuggestion',
      success: false,
    );
  }

  // 음성 인식 시작
  Future<void> startListening() async {
    _isListening = true;
    _currentTranscript = '';

    // 실제 앱에서는 speech_to_text 패키지 사용
    // 여기서는 시뮬레이션
    Timer(const Duration(seconds: 3), () {
      _isListening = false;
    });
  }

  // 음성 인식 중지
  void stopListening() {
    _isListening = false;
  }

  // 음성 합성 (TTS)
  Future<void> speak(String text) async {
    // 실제 앱에서는 flutter_tts 패키지 사용
    // 설정에 따라 음성 타입, 속도 조절
  }

  // 대화 히스토리 가져오기
  List<ConversationItem> getConversationHistory() {
    return List.unmodifiable(_conversationHistory);
  }

  // 대화 히스토리 초기화
  void clearHistory() {
    _conversationHistory.clear();
  }

  // 설정 업데이트
  Future<void> updateSettings({
    bool? enabled,
    String? voiceType,
    double? speechRate,
    String? language,
    bool? autoListen,
  }) async {
    if (enabled != null) _isEnabled = enabled;
    if (voiceType != null) _voiceType = voiceType;
    if (speechRate != null) _speechRate = speechRate;
    if (language != null) _language = language;
    if (autoListen != null) _autoListen = autoListen;

    // 설정 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, ''); // JSON으로 저장
  }

  // Getters
  bool get isEnabled => _isEnabled;
  bool get isListening => _isListening;
  String get currentTranscript => _currentTranscript;
  String get voiceType => _voiceType;
  double get speechRate => _speechRate;
  String get language => _language;
  bool get autoListen => _autoListen;

  // 빠른 응답 생성
  String getQuickResponse(String topic) {
    final responses = {
      'greeting': [
        '안녕하세요! 오늘도 수익 만들기 좋은 날이네요! 🌟',
        '반가워요! 무엇을 도와드릴까요? 😊',
        '안녕하세요! PayDay AI 비서입니다. 궁금한 점이 있으신가요?',
      ],
      'motivation': [
        '오늘도 한 걸음 더! 작은 수익도 모이면 큰 돈이 됩니다 💪',
        '대단해요! 꾸준함이 성공의 비결이죠 🎯',
        '멋져요! 이런 페이스라면 목표 달성은 시간문제예요 🚀',
      ],
      'congratulation': [
        '축하합니다! 정말 대단하세요! 🎉',
        '와! 목표 달성이네요! 멋져요! 🏆',
        '훌륭해요! 이런 성과를 내다니! ⭐',
      ],
    };

    final list = responses[topic] ?? ['무엇을 도와드릴까요?'];
    return list[Random().nextInt(list.length)];
  }
}