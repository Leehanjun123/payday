import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';
import '../../widgets/income_detail_template.dart';
import '../../models/income_source.dart';

class QuizDetailScreen extends StatefulWidget {
  const QuizDetailScreen({super.key});

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen>
    with TickerProviderStateMixin, IncomeDetailMixin {
  final MockQuizData mockData = MockQuizData();
  late AnimationController _timerAnimationController;
  late AnimationController _scoreAnimationController;
  late AnimationController _questionAnimationController;
  late Animation<double> _timerAnimation;
  late Animation<double> _scoreAnimation;
  late Animation<double> _questionAnimation;

  Timer? _countdownTimer;
  int _remainingTime = 30;
  int _currentQuestionIndex = 0;
  int? _selectedAnswer;
  bool _isAnswered = false;
  int _score = 0;
  int _combo = 0;
  List<bool> _answerResults = [];

  @override
  void initState() {
    super.initState();
    _timerAnimationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );
    _scoreAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _questionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _timerAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _timerAnimationController,
      curve: Curves.linear,
    ));

    _scoreAnimation = CurvedAnimation(
      parent: _scoreAnimationController,
      curve: Curves.elasticOut,
    );

    _questionAnimation = CurvedAnimation(
      parent: _questionAnimationController,
      curve: Curves.easeOutBack,
    );

    _questionAnimationController.forward();
  }

  @override
  void dispose() {
    _timerAnimationController.dispose();
    _scoreAnimationController.dispose();
    _questionAnimationController.dispose();
    _countdownTimer?.cancel();
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
                _buildCurrentQuiz(),
                _buildCategories(),
                _buildLeaderboard(),
                _buildAchievements(),
                _buildQuizHistory(),
                _buildTipsSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: buildIncomeFloatingActionButton(
        IncomeType.quiz,
        '퀴즈',
        Colors.deepPurple,
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFFFF6B6B),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          '퀴즈 게임',
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
                Color(0xFFFF6B6B),
                Color(0xFFFF8E53),
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
                    Icons.quiz,
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
                    '총 퀴즈 수익',
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
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.blue.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.purple.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.emoji_events,
                value: mockData.totalQuizzes.toString(),
                label: '총 퀴즈',
                color: Colors.amber,
              ),
              _buildStatItem(
                icon: Icons.check_circle,
                value: '${mockData.correctRate}%',
                label: '정답률',
                color: Colors.green,
              ),
              _buildStatItem(
                icon: Icons.local_fire_department,
                value: mockData.bestCombo.toString(),
                label: '최고 콤보',
                color: Colors.orange,
              ),
              _buildStatItem(
                icon: Icons.star,
                value: 'Lv.${mockData.quizLevel}',
                label: '퀴즈 레벨',
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

  Widget _buildCurrentQuiz() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '콤보 x${mockData.currentCombo}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
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
                      child: Row(
                        children: [
                          const Icon(
                            Icons.attach_money,
                            size: 16,
                            color: Colors.green,
                          ),
                          Text(
                            '${mockData.currentEarnings}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  '오늘의 퀴즈',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '일반상식',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '난이도: ★★☆',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '대한민국의 수도는 어디인가요?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    _buildAnswerOption('서울', true),
                    _buildAnswerOption('부산', false),
                    _buildAnswerOption('대구', false),
                    _buildAnswerOption('인천', false),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _startQuiz(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    '퀴즈 시작하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOption(String text, bool isCorrect) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.selectionClick();
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey[300]!,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              '퀴즈 카테고리',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: mockData.categories.length,
            itemBuilder: (context, index) {
              final category = mockData.categories[index];
              return _buildCategoryCard(category);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(QuizCategory category) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _selectCategory(category),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                category.icon,
                size: 32,
                color: category.color,
              ),
              const SizedBox(height: 8),
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${category.questionCount}문제',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+₩${category.reward}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: category.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboard() {
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
                '주간 랭킹',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.leaderboard,
                color: Colors.amber,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(5, (index) {
            final player = mockData.leaderboard[index];
            return _buildLeaderboardItem(player, index + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(Map<String, dynamic> player, int rank) {
    final medalColor = rank == 1
        ? Colors.amber
        : rank == 2
            ? Colors.grey
            : rank == 3
                ? Colors.brown
                : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: medalColor?.withOpacity(0.2) ?? Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: rank <= 3
                  ? Icon(
                      Icons.emoji_events,
                      size: 18,
                      color: medalColor,
                    )
                  : Text(
                      rank.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 16,
            backgroundColor: player['color'],
            child: Text(
              player['name'][0],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              player['name'],
              style: TextStyle(
                fontSize: 14,
                fontWeight: player['isMe'] ? FontWeight.bold : FontWeight.w500,
                color: player['isMe'] ? Colors.blue : Colors.black,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${player['score']}점',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₩${player['earnings']}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              '업적',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: mockData.achievements.length,
              itemBuilder: (context, index) {
                final achievement = mockData.achievements[index];
                return _buildAchievementCard(achievement);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: achievement.isUnlocked
            ? LinearGradient(
                colors: [
                  achievement.color.withOpacity(0.8),
                  achievement.color.withOpacity(0.5),
                ],
              )
            : null,
        color: achievement.isUnlocked ? null : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            achievement.icon,
            size: 28,
            color: achievement.isUnlocked ? Colors.white : Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            achievement.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: achievement.isUnlocked ? Colors.white : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          if (achievement.isUnlocked)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '+₩${achievement.reward}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuizHistory() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.05),
            Colors.purple.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.history,
                color: Colors.blue,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                '최근 퀴즈 기록',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...mockData.recentHistory.map((history) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: history['score'] >= 80
                        ? Colors.green.withOpacity(0.1)
                        : history['score'] >= 60
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${history['score']}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: history['score'] >= 80
                            ? Colors.green
                            : history['score'] >= 60
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        history['category'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        history['time'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '+₩${history['reward']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.yellow.withOpacity(0.05),
            Colors.orange.withOpacity(0.05),
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
                '퀴즈 팁',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipItem('빠르게 답할수록 보너스 점수를 받을 수 있어요'),
          _buildTipItem('연속 정답 시 콤보 보너스가 쌓입니다'),
          _buildTipItem('매일 로그인하면 퀴즈 보너스를 받을 수 있어요'),
          _buildTipItem('친구와 함께 플레이하면 추가 보상이 있어요'),
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

  void _startQuiz() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('퀴즈를 시작합니다!'),
        backgroundColor: Color(0xFFFF6B6B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _selectCategory(QuizCategory category) {
    HapticFeedback.selectionClick();
    // 카테고리 선택 로직
  }
}

// Mock Data Classes
class QuizCategory {
  final String name;
  final IconData icon;
  final Color color;
  final int questionCount;
  final int reward;

  QuizCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.questionCount,
    required this.reward,
  });
}

class Achievement {
  final String name;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final int reward;

  Achievement({
    required this.name,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    required this.reward,
  });
}

class MockQuizData {
  final double totalEarnings = 32000;
  final int totalQuizzes = 156;
  final int correctRate = 78;
  final int bestCombo = 15;
  final int quizLevel = 8;
  final int currentCombo = 3;
  final int currentEarnings = 500;

  final List<QuizCategory> categories = [
    QuizCategory(
      name: '일반상식',
      icon: Icons.school,
      color: Colors.blue,
      questionCount: 20,
      reward: 500,
    ),
    QuizCategory(
      name: '연예/스포츠',
      icon: Icons.sports_basketball,
      color: Colors.orange,
      questionCount: 15,
      reward: 400,
    ),
    QuizCategory(
      name: '과학/IT',
      icon: Icons.science,
      color: Colors.green,
      questionCount: 25,
      reward: 600,
    ),
    QuizCategory(
      name: '역사',
      icon: Icons.history_edu,
      color: Colors.brown,
      questionCount: 20,
      reward: 500,
    ),
    QuizCategory(
      name: '영화/드라마',
      icon: Icons.movie,
      color: Colors.purple,
      questionCount: 18,
      reward: 450,
    ),
    QuizCategory(
      name: '경제/금융',
      icon: Icons.trending_up,
      color: Colors.teal,
      questionCount: 22,
      reward: 550,
    ),
  ];

  final List<Map<String, dynamic>> leaderboard = [
    {'name': '퀴즈왕', 'score': 9850, 'earnings': 5000, 'color': Colors.amber, 'isMe': false},
    {'name': '똑똑이', 'score': 8920, 'earnings': 4500, 'color': Colors.blue, 'isMe': false},
    {'name': '나', 'score': 7650, 'earnings': 3800, 'color': Colors.green, 'isMe': true},
    {'name': '퀴즈러', 'score': 7200, 'earnings': 3500, 'color': Colors.purple, 'isMe': false},
    {'name': '지식인', 'score': 6800, 'earnings': 3200, 'color': Colors.orange, 'isMe': false},
  ];

  final List<Achievement> achievements = [
    Achievement(
      name: '첫 퀴즈',
      icon: Icons.flag,
      color: Colors.green,
      isUnlocked: true,
      reward: 100,
    ),
    Achievement(
      name: '10연속 정답',
      icon: Icons.local_fire_department,
      color: Colors.orange,
      isUnlocked: true,
      reward: 500,
    ),
    Achievement(
      name: '퀴즈 마스터',
      icon: Icons.emoji_events,
      color: Colors.amber,
      isUnlocked: false,
      reward: 1000,
    ),
    Achievement(
      name: '속도의 신',
      icon: Icons.flash_on,
      color: Colors.blue,
      isUnlocked: false,
      reward: 800,
    ),
  ];

  final List<Map<String, dynamic>> recentHistory = [
    {'category': '일반상식', 'score': 85, 'time': '오늘 14:30', 'reward': 500},
    {'category': '영화/드라마', 'score': 70, 'time': '오늘 10:15', 'reward': 350},
    {'category': '과학/IT', 'score': 90, 'time': '어제 18:20', 'reward': 600},
    {'category': '역사', 'score': 65, 'time': '어제 15:00', 'reward': 300},
  ];
}