import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../../widgets/income_detail_template.dart';
import '../../models/income_source.dart';

class SurveyDetailScreen extends StatefulWidget {
  const SurveyDetailScreen({super.key});

  @override
  State<SurveyDetailScreen> createState() => _SurveyDetailScreenState();
}

class _SurveyDetailScreenState extends State<SurveyDetailScreen>
    with TickerProviderStateMixin, IncomeDetailMixin {
  final MockSurveyData mockData = MockSurveyData();
  late AnimationController _progressAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _cardAnimation;

  int _currentQuestionIndex = 0;
  Map<int, dynamic> _answers = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeOutCubic,
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutBack,
    );

    _progressAnimationController.forward();
    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildStatsCard(),
                _buildAvailableSurveys(),
                _buildInProgressSurvey(),
                _buildCompletedSurveys(),
                _buildEarningStats(),
                _buildSurveyTips(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: buildIncomeFloatingActionButton(
        IncomeType.survey,
        '설문조사',
        Colors.cyan,
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF3B82F6),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          '설문조사',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF3B82F6),
                Color(0xFF2563EB),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.assignment,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '₩${mockData.totalEarnings.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    '총 설문 수익',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.check_circle,
                value: mockData.completedSurveysCount.toString(),
                label: '완료',
                color: Colors.green,
              ),
              _buildStatItem(
                icon: Icons.timer,
                value: '${mockData.averageTime}분',
                label: '평균 시간',
                color: Colors.orange,
              ),
              _buildStatItem(
                icon: Icons.star,
                value: '${mockData.qualityScore}%',
                label: '품질 점수',
                color: Colors.blue,
              ),
              _buildStatItem(
                icon: Icons.trending_up,
                value: '₩${mockData.averageReward}',
                label: '평균 보상',
                color: Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableSurveys() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '참여 가능한 설문',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '새로고침 3시간 후',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          ...mockData.availableSurveys.map((survey) => _buildSurveyCard(survey)),
        ],
      ),
    );
  }

  Widget _buildSurveyCard(Survey survey) {
    final difficultyColor = survey.difficulty == '쉬움'
        ? Colors.green
        : survey.difficulty == '보통'
            ? Colors.orange
            : Colors.red;

    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _startSurvey(survey),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: survey.categoryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              survey.icon,
                              color: survey.categoryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  survey.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  survey.company,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '₩${survey.reward}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        survey.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildTag(Icons.timer, '${survey.estimatedTime}분'),
                          const SizedBox(width: 8),
                          _buildTag(Icons.quiz, '${survey.questionCount}문항'),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: difficultyColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              survey.difficulty,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: difficultyColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (survey.isHot)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.red, Colors.orange],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    'HOT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey[500],
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInProgressSurvey() {
    if (mockData.inProgressSurvey == null) return const SizedBox();

    final survey = mockData.inProgressSurvey!;
    final progress = survey.answeredQuestions / survey.questionCount;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.purple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.play_circle_outline,
                color: Colors.blue,
              ),
              SizedBox(width: 8),
              Text(
                '진행 중인 설문',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            survey.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress * _progressAnimation.value,
                      minHeight: 10,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${survey.answeredQuestions}/${survey.questionCount} 완료',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _continueSurvey(survey),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          '계속하기',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedSurveys() {
    if (mockData.completedSurveysList.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              '완료한 설문',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: mockData.completedSurveysList.length,
              itemBuilder: (context, index) {
                final completed = mockData.completedSurveysList[index];
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              completed['title'],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        completed['date'],
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '+₩${completed['reward']}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 12,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${completed['quality']}%',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningStats() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '이번 주 수익 통계',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.analytics,
                color: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final day = ['월', '화', '수', '목', '금', '토', '일'][index];
              final earnings = mockData.weeklyEarnings[index];
              final maxEarning = mockData.weeklyEarnings.reduce((a, b) => a > b ? a : b);
              final height = earnings > 0 ? (earnings / maxEarning) * 60 : 10;

              return Column(
                children: [
                  Text(
                    earnings > 0 ? '₩${earnings}' : '-',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 30,
                    height: height.toDouble(),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: earnings > 0
                            ? [Colors.blue, Colors.blue.withOpacity(0.5)]
                            : [Colors.grey[300]!, Colors.grey[300]!],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '주간 총 수익',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Text(
                '₩${mockData.weeklyTotal}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyTips() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.05),
            Colors.yellow.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.orange,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                '설문 팁',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipItem('성실하게 답변하면 품질 점수가 올라가 더 많은 설문을 받을 수 있어요'),
          _buildTipItem('일관성 있는 답변으로 신뢰도를 유지하세요'),
          _buildTipItem('프로필을 자세히 작성하면 맞춤 설문이 더 많이 제공됩니다'),
          _buildTipItem('시간이 충분할 때 참여하여 집중도를 높이세요'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startSurvey(Survey survey) {
    HapticFeedback.mediumImpact();
    // 설문 시작 로직
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${survey.title} 설문을 시작합니다'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _continueSurvey(Survey survey) {
    HapticFeedback.mediumImpact();
    // 설문 계속 로직
  }
}

// Mock Data Classes
class Survey {
  final String id;
  final String title;
  final String company;
  final String description;
  final int reward;
  final int estimatedTime;
  final int questionCount;
  final String difficulty;
  final String category;
  final IconData icon;
  final Color categoryColor;
  final bool isHot;
  final int answeredQuestions;

  Survey({
    required this.id,
    required this.title,
    required this.company,
    required this.description,
    required this.reward,
    required this.estimatedTime,
    required this.questionCount,
    required this.difficulty,
    required this.category,
    required this.icon,
    required this.categoryColor,
    this.isHot = false,
    this.answeredQuestions = 0,
  });
}

class MockSurveyData {
  final double totalEarnings = 45000;
  final int completedSurveysCount = 23;
  final int averageTime = 12;
  final int qualityScore = 92;
  final int averageReward = 1950;
  final int weeklyTotal = 8500;

  final List<int> weeklyEarnings = [2000, 1500, 0, 2500, 1000, 1500, 0];

  Survey? inProgressSurvey = Survey(
    id: 'in_progress',
    title: '2025년 라이프스타일 설문',
    company: '트렌드 리서치',
    description: '새해 계획과 라이프스타일에 대한 설문',
    reward: 2500,
    estimatedTime: 15,
    questionCount: 20,
    difficulty: '보통',
    category: '라이프스타일',
    icon: Icons.favorite,
    categoryColor: Colors.pink,
    answeredQuestions: 12,
  );

  final List<Survey> availableSurveys = [
    Survey(
      id: '1',
      title: '모바일 쇼핑 경험 설문',
      company: '이커머스 연구소',
      description: '온라인 쇼핑 습관과 선호도에 대한 설문조사',
      reward: 3000,
      estimatedTime: 20,
      questionCount: 25,
      difficulty: '보통',
      category: '쇼핑',
      icon: Icons.shopping_cart,
      categoryColor: Colors.purple,
      isHot: true,
    ),
    Survey(
      id: '2',
      title: 'OTT 서비스 이용 패턴',
      company: '미디어 리서치',
      description: '넷플릭스, 디즈니+ 등 OTT 서비스 이용 현황',
      reward: 2000,
      estimatedTime: 10,
      questionCount: 15,
      difficulty: '쉬움',
      category: '엔터테인먼트',
      icon: Icons.movie,
      categoryColor: Colors.red,
    ),
    Survey(
      id: '3',
      title: '건강 관리 앱 사용성',
      company: '헬스케어 랩',
      description: '운동과 식단 관리 앱 사용 경험 조사',
      reward: 2500,
      estimatedTime: 15,
      questionCount: 20,
      difficulty: '보통',
      category: '건강',
      icon: Icons.fitness_center,
      categoryColor: Colors.green,
    ),
    Survey(
      id: '4',
      title: '금융 서비스 만족도',
      company: '핀테크 연구원',
      description: '모바일 뱅킹과 간편결제 서비스 이용 경험',
      reward: 4000,
      estimatedTime: 25,
      questionCount: 30,
      difficulty: '어려움',
      category: '금융',
      icon: Icons.account_balance,
      categoryColor: Colors.blue,
      isHot: true,
    ),
  ];

  final List<Map<String, dynamic>> completedSurveysList = [
    {'title': '음식 배달 앱 선호도', 'date': '12/28 14:30', 'reward': 2000, 'quality': 95},
    {'title': '게임 플레이 습관', 'date': '12/27 10:15', 'reward': 1500, 'quality': 88},
    {'title': '여행 계획 설문', 'date': '12/26 16:45', 'reward': 2500, 'quality': 92},
  ];
}