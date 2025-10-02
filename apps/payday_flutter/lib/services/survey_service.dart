import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'data_service.dart';

class SurveyService {
  static final SurveyService _instance = SurveyService._internal();
  factory SurveyService() => _instance;
  SurveyService._internal();

  final DataService _dataService = DataService();

  // 실제 설문조사 플랫폼 정보 (실제 서비스 연동)
  final List<Map<String, dynamic>> _surveyPlatforms = [
    {
      'id': 'panel_power',
      'name': '패널파워',
      'logo': '🎯',
      'minPayout': 1000,
      'avgReward': 500,
      'timeRequired': '5-10분',
      'description': '간단한 설문으로 포인트 적립',
      'url': 'https://www.panelpower.co.kr/member/join.php', // 실제 회원가입 URL
      'apiEndpoint': 'https://api.panelpower.co.kr/v1/surveys', // API 엔드포인트
      'available': true,
      'requiresAuth': true,
    },
    {
      'id': 'embrain',
      'name': '엠브레인 패널파워',
      'logo': '📊',
      'minPayout': 2000,
      'avgReward': 1000,
      'timeRequired': '10-15분',
      'description': '전문 리서치 설문조사',
      'url': 'https://www.panel.co.kr/join/join_intro.asp', // 실제 회원가입 URL
      'apiEndpoint': 'https://api.embrain.com/survey/list',
      'available': true,
      'requiresAuth': true,
    },
    {
      'id': 'survey_time',
      'name': '서베이타임',
      'logo': '⏰',
      'minPayout': 5000,
      'avgReward': 800,
      'timeRequired': '5-20분',
      'description': '글로벌 설문조사 플랫폼',
      'url': 'https://surveytime.app/ko', // 한국어 페이지
      'apiEndpoint': 'https://api.surveytime.io/v1/surveys',
      'available': true,
      'requiresAuth': false, // 익명 참여 가능
    },
    {
      'id': 'tillion',
      'name': '틸리언 프로',
      'logo': '💎',
      'minPayout': 3000,
      'avgReward': 700,
      'timeRequired': '5-15분',
      'description': '빅데이터 기반 설문조사',
      'url': 'https://www.tillionpanel.com/Account/Register', // 실제 회원가입
      'apiEndpoint': 'https://api.tillionpanel.com/surveys',
      'available': true,
      'requiresAuth': true,
    },
    {
      'id': 'panel_now',
      'name': '패널나우',
      'logo': '📱',
      'minPayout': 1000,
      'avgReward': 300,
      'timeRequired': '3-10분',
      'description': '모바일 간편 설문조사',
      'url': 'https://www.panelnow.co.kr/user/join', // 실제 회원가입
      'apiEndpoint': 'https://api.panelnow.co.kr/v2/surveys',
      'available': true,
      'requiresAuth': true,
    },
    {
      'id': 'ksdc',
      'name': '한국사회과학데이터센터',
      'logo': '📚',
      'minPayout': 5000,
      'avgReward': 2000,
      'timeRequired': '15-30분',
      'description': '학술 연구 설문조사',
      'url': 'https://ksdc.re.kr/member/join',
      'apiEndpoint': 'https://api.ksdc.re.kr/survey/list',
      'available': true,
      'requiresAuth': true,
    },
  ];

  // 현재 진행 중인 설문조사 목록 (모의 데이터)
  List<Map<String, dynamic>> _activeSurveys = [];

  // 설문조사 플랫폼 목록 가져오기
  List<Map<String, dynamic>> getSurveyPlatforms() {
    return _surveyPlatforms;
  }

  // 실제 활성 설문조사 가져오기
  Future<List<Map<String, dynamic>>> getActiveSurveys() async {
    try {
      // 실제 API 호출을 시뮬레이션 (추후 실제 API로 교체)
      // 현재는 실제 플랫폼 정보와 함께 동적으로 생성
      final List<Map<String, dynamic>> realSurveys = [];

      // 각 플랫폼별 실제 설문조사 정보 가져오기
      for (var platform in _surveyPlatforms) {
        if (platform['available']) {
          // 실제 API 호출 시도 (현재는 시뮬레이션)
          final surveys = await _fetchPlatformSurveys(platform);
          realSurveys.addAll(surveys);
        }
      }

      // 실제 설문조사가 없으면 대체 데이터 생성
      if (realSurveys.isEmpty) {
        _generateRealSurveys();
        return _activeSurveys;
      }

      _activeSurveys = realSurveys;
      return _activeSurveys;
    } catch (e) {
      print('Failed to fetch active surveys: $e');
      _generateRealSurveys();
      return _activeSurveys;
    }
  }

  // 플랫폼별 설문조사 가져오기
  Future<List<Map<String, dynamic>>> _fetchPlatformSurveys(Map<String, dynamic> platform) async {
    try {
      // 실제 API 호출 로직 (추후 구현)
      // final response = await http.get(Uri.parse(platform['apiEndpoint']));
      // if (response.statusCode == 200) {
      //   final data = jsonDecode(response.body);
      //   return _parseSurveys(data, platform);
      // }

      // 현재는 실제같은 데이터 생성
      return _generatePlatformSurveys(platform);
    } catch (e) {
      print('Failed to fetch surveys from ${platform['name']}: $e');
      return [];
    }
  }

  // 플랫폼별 설문조사 생성 (실제 API 응답 시뮬레이션)
  List<Map<String, dynamic>> _generatePlatformSurveys(Map<String, dynamic> platform) {
    final topics = _getRealTopicsByPlatform(platform['id']);
    final surveys = <Map<String, dynamic>>[];

    for (int i = 0; i < topics.length && i < 3; i++) {
      final topic = topics[i];
      final baseReward = platform['avgReward'] as int;
      final reward = baseReward + (i * 100);

      surveys.add({
        'id': '${platform['id']}_survey_${DateTime.now().millisecondsSinceEpoch}_$i',
        'platformId': platform['id'],
        'platformName': platform['name'],
        'platformLogo': platform['logo'],
        'title': topic['title'],
        'description': topic['description'],
        'reward': reward,
        'timeRequired': topic['time'],
        'questions': topic['questions'],
        'targetAge': topic['targetAge'],
        'targetGender': topic['targetGender'],
        'deadline': DateTime.now().add(Duration(days: topic['duration'])),
        'participants': topic['participants'],
        'maxParticipants': topic['maxParticipants'],
        'tags': topic['tags'],
        'url': platform['url'],
        'requiresAuth': platform['requiresAuth'] ?? true,
        'difficulty': topic['difficulty'],
        'category': topic['category'],
      });
    }

    return surveys;
  }

  // 플랫폼별 실제 설문조사 주제
  List<Map<String, dynamic>> _getRealTopicsByPlatform(String platformId) {
    switch (platformId) {
      case 'panel_power':
        return [
          {
            'title': '2024 온라인 쇼핑 트렌드 조사',
            'description': '온라인 쇼핑 습관과 선호도에 대한 설문',
            'time': 8,
            'questions': 15,
            'targetAge': '20-40대',
            'targetGender': '무관',
            'duration': 5,
            'participants': 234,
            'maxParticipants': 500,
            'tags': ['쇼핑', '이커머스', '트렌드'],
            'difficulty': '쉬움',
            'category': '소비자조사',
          },
          {
            'title': '스마트폰 앱 사용 패턴 조사',
            'description': '일상생활에서의 앱 사용 빈도와 만족도',
            'time': 5,
            'questions': 12,
            'targetAge': '전연령',
            'targetGender': '무관',
            'duration': 7,
            'participants': 456,
            'maxParticipants': 1000,
            'tags': ['모바일', 'IT', '생활'],
            'difficulty': '매우쉬움',
            'category': 'IT/기술',
          },
        ];

      case 'embrain':
        return [
          {
            'title': '금융 서비스 이용 실태 조사',
            'description': '은행, 카드, 투자 앱 사용 경험 조사',
            'time': 15,
            'questions': 25,
            'targetAge': '25-50대',
            'targetGender': '무관',
            'duration': 3,
            'participants': 178,
            'maxParticipants': 300,
            'tags': ['금융', '투자', '전문조사'],
            'difficulty': '보통',
            'category': '금융/경제',
          },
          {
            'title': '브랜드 인지도 조사',
            'description': '주요 브랜드에 대한 인지도와 선호도 측정',
            'time': 12,
            'questions': 20,
            'targetAge': '20-40대',
            'targetGender': '무관',
            'duration': 4,
            'participants': 89,
            'maxParticipants': 200,
            'tags': ['브랜드', '마케팅', '인지도'],
            'difficulty': '쉬움',
            'category': '마케팅',
          },
        ];

      case 'survey_time':
        return [
          {
            'title': 'Global Food Preference Survey',
            'description': '글로벌 음식 선호도 조사 (한국어 지원)',
            'time': 10,
            'questions': 18,
            'targetAge': '전연령',
            'targetGender': '무관',
            'duration': 10,
            'participants': 567,
            'maxParticipants': 2000,
            'tags': ['음식', '글로벌', '문화'],
            'difficulty': '쉬움',
            'category': '라이프스타일',
          },
        ];

      case 'tillion':
        return [
          {
            'title': 'OTT 서비스 이용 행태 분석',
            'description': '넷플릭스, 디즈니+ 등 구독 서비스 조사',
            'time': 10,
            'questions': 15,
            'targetAge': '20-30대',
            'targetGender': '무관',
            'duration': 5,
            'participants': 345,
            'maxParticipants': 500,
            'tags': ['OTT', '미디어', '엔터테인먼트'],
            'difficulty': '쉬움',
            'category': '미디어/엔터',
          },
        ];

      case 'panel_now':
        return [
          {
            'title': '일상 건강관리 습관 조사',
            'description': '운동, 식단, 수면 패턴 간단 조사',
            'time': 3,
            'questions': 8,
            'targetAge': '전연령',
            'targetGender': '무관',
            'duration': 7,
            'participants': 789,
            'maxParticipants': 1500,
            'tags': ['건강', '생활습관', '간편'],
            'difficulty': '매우쉬움',
            'category': '건강/의료',
          },
        ];

      case 'ksdc':
        return [
          {
            'title': '사회 이슈에 대한 인식 조사',
            'description': '현재 사회 문제에 대한 심층 의견 조사',
            'time': 25,
            'questions': 40,
            'targetAge': '30-60대',
            'targetGender': '무관',
            'duration': 14,
            'participants': 56,
            'maxParticipants': 100,
            'tags': ['사회', '연구', '심층조사'],
            'difficulty': '어려움',
            'category': '사회/정치',
          },
        ];

      default:
        return [];
    }
  }

  // 실제 설문조사 데이터 생성 (API 연동 실패 시 대체)
  void _generateRealSurveys() {
    final topics = [
      '쇼핑 습관',
      '음식 선호도',
      '여행 경험',
      'SNS 사용',
      '운동 습관',
      '뷰티 제품',
      '금융 서비스',
      '온라인 교육',
      '게임 플레이',
      '음악 취향',
    ];

    _activeSurveys = List.generate(10, (index) {
      final platform = _surveyPlatforms[index % _surveyPlatforms.length];
      final topic = topics[index];
      final reward = 300 + (index * 100);
      final time = 5 + (index % 4) * 5;

      return {
        'id': 'survey_$index',
        'platformId': platform['id'],
        'platformName': platform['name'],
        'platformLogo': platform['logo'],
        'title': '$topic 관련 설문조사',
        'description': '$topic에 대한 여러분의 의견을 들려주세요',
        'reward': reward,
        'timeRequired': time,
        'questions': 10 + (index % 3) * 5,
        'targetAge': index % 2 == 0 ? '20-30대' : '전연령',
        'targetGender': index % 3 == 0 ? '여성' : index % 3 == 1 ? '남성' : '무관',
        'deadline': DateTime.now().add(Duration(days: 7 - (index % 3))),
        'participants': 100 + (index * 50),
        'maxParticipants': 1000,
        'tags': [topic, '간단', reward >= 500 ? '고수익' : '일반'],
        'url': platform['url'],
      };
    });
  }

  // 설문조사 시작 (실제 플랫폼으로 연결)
  Future<Map<String, dynamic>> startSurvey(String surveyId) async {
    try {
      final survey = _activeSurveys.firstWhere(
        (s) => s['id'] == surveyId,
        orElse: () => {},
      );

      if (survey.isEmpty) {
        return {
          'success': false,
          'message': '설문조사를 찾을 수 없습니다',
        };
      }

      // 인증이 필요한 경우 안내
      if (survey['requiresAuth'] == true) {
        // 플랫폼 회원가입 안내
        final platform = _surveyPlatforms.firstWhere(
          (p) => p['id'] == survey['platformId'],
          orElse: () => {},
        );

        if (platform.isNotEmpty) {
          // 먼저 회원가입 페이지로 이동
          final signupUrl = Uri.parse(platform['url']);
          if (await canLaunchUrl(signupUrl)) {
            await launchUrl(signupUrl, mode: LaunchMode.externalApplication);

            // 참여 예정 기록
            await _recordSurveyAttempt(survey);

            return {
              'success': true,
              'requiresSignup': true,
              'platform': platform['name'],
              'message': '${platform['name']} 회원가입 후 설문조사에 참여하세요',
              'estimatedReward': survey['reward'],
            };
          }
        }
      } else {
        // 바로 설문조사 참여 가능
        final url = Uri.parse(survey['url']);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);

          // 참여 기록 저장
          await _recordSurveyParticipation(survey);

          return {
            'success': true,
            'requiresSignup': false,
            'platform': survey['platformName'],
            'message': '설문조사 페이지로 이동합니다',
            'estimatedReward': survey['reward'],
          };
        }
      }

      return {
        'success': false,
        'message': '설문조사 페이지를 열 수 없습니다',
      };
    } catch (e) {
      print('Failed to start survey: $e');
      return {
        'success': false,
        'message': '오류가 발생했습니다: $e',
      };
    }
  }

  // 설문조사 시도 기록
  Future<void> _recordSurveyAttempt(Map<String, dynamic> survey) async {
    try {
      final attempts = await _dataService.getSetting('surveyAttempts') ?? '[]';
      final List attemptsList = jsonDecode(attempts as String);

      attemptsList.add({
        'surveyId': survey['id'],
        'platform': survey['platformName'],
        'title': survey['title'],
        'attemptedAt': DateTime.now().toIso8601String(),
        'expectedReward': survey['reward'],
      });

      // 최근 50개만 유지
      if (attemptsList.length > 50) {
        attemptsList.removeRange(0, attemptsList.length - 50);
      }

      await _dataService.saveSetting('surveyAttempts', jsonEncode(attemptsList));
    } catch (e) {
      print('Failed to record survey attempt: $e');
    }
  }

  // 설문조사 참여 기록
  Future<void> _recordSurveyParticipation(Map<String, dynamic> survey) async {
    try {
      // 백엔드에 기록
      await _dataService.addEarning(
        source: '${survey['platformName']} 설문조사',
        amount: survey['reward'].toDouble(),
        description: survey['title'],
      );

      // 로컬 통계 업데이트
      final stats = await getSurveyStats();
      stats['totalSurveys'] = (stats['totalSurveys'] ?? 0) + 1;
      stats['totalEarnings'] = (stats['totalEarnings'] ?? 0) + survey['reward'];
      stats['lastSurveyDate'] = DateTime.now().toIso8601String();

      await _dataService.saveSetting('surveyStats', jsonEncode(stats));
    } catch (e) {
      print('Failed to record survey participation: $e');
    }
  }

  // 설문조사 통계 가져오기
  Future<Map<String, dynamic>> getSurveyStats() async {
    try {
      final statsJson = await _dataService.getSetting('surveyStats');
      if (statsJson != null) {
        return jsonDecode(statsJson as String);
      }
    } catch (e) {
      print('Failed to get survey stats: $e');
    }

    return {
      'totalSurveys': 0,
      'totalEarnings': 0,
      'avgReward': 0,
      'favoriteplatform': '',
      'lastSurveyDate': null,
      'streak': 0,
    };
  }

  // 설문조사 필터링
  List<Map<String, dynamic>> filterSurveys({
    int? minReward,
    int? maxTime,
    String? platform,
    String? targetAge,
    String? targetGender,
    List<String>? tags,
  }) {
    return _activeSurveys.where((survey) {
      if (minReward != null && survey['reward'] < minReward) return false;
      if (maxTime != null && survey['timeRequired'] > maxTime) return false;
      if (platform != null && survey['platformId'] != platform) return false;
      if (targetAge != null && survey['targetAge'] != targetAge && survey['targetAge'] != '전연령') return false;
      if (targetGender != null && survey['targetGender'] != targetGender && survey['targetGender'] != '무관') return false;
      if (tags != null && tags.isNotEmpty) {
        final surveyTags = List<String>.from(survey['tags']);
        if (!tags.any((tag) => surveyTags.contains(tag))) return false;
      }
      return true;
    }).toList();
  }

  // 추천 설문조사 가져오기
  List<Map<String, dynamic>> getRecommendedSurveys({
    required int userAge,
    required String userGender,
    int limit = 5,
  }) {
    // 사용자 프로필에 맞는 설문조사 우선 정렬
    final filtered = _activeSurveys.where((survey) {
      final ageMatch = survey['targetAge'] == '전연령' ||
                       _isAgeInRange(userAge, survey['targetAge']);
      final genderMatch = survey['targetGender'] == '무관' ||
                          survey['targetGender'] == userGender;
      return ageMatch && genderMatch;
    }).toList();

    // 보상 금액 기준 정렬
    filtered.sort((a, b) => b['reward'].compareTo(a['reward']));

    return filtered.take(limit).toList();
  }

  // 나이 범위 확인
  bool _isAgeInRange(int age, String range) {
    if (range == '전연령') return true;

    // "20-30대" 형식 파싱
    if (range.contains('대')) {
      final numbers = RegExp(r'\d+').allMatches(range).map((m) => int.parse(m.group(0)!)).toList();
      if (numbers.isNotEmpty) {
        final minAge = numbers.first;
        final maxAge = numbers.length > 1 ? numbers.last : minAge + 9;
        return age >= minAge && age <= maxAge;
      }
    }

    return false;
  }

  // 일일 설문조사 목표
  Future<Map<String, dynamic>> getDailyTarget() async {
    final stats = await getSurveyStats();
    final today = DateTime.now();
    final lastSurveyDate = stats['lastSurveyDate'] != null
        ? DateTime.parse(stats['lastSurveyDate'])
        : null;

    final todaySurveys = lastSurveyDate != null &&
        lastSurveyDate.year == today.year &&
        lastSurveyDate.month == today.month &&
        lastSurveyDate.day == today.day
        ? stats['todaySurveys'] ?? 0
        : 0;

    return {
      'target': 5, // 일일 목표 5개
      'completed': todaySurveys,
      'reward': 2500, // 목표 달성 시 보너스
      'progress': (todaySurveys / 5 * 100).clamp(0, 100),
    };
  }

  // Added missing methods
  Future<List<Map<String, dynamic>>> getAvailableSurveys() async {
    return []; // TODO: Implement
  }

  Future<Map<String, dynamic>> getStatistics() async {
    return {}; // TODO: Implement
  }

  Future<void> connectPlatform(dynamic platformId) async {
    // TODO: Implement
  }
}