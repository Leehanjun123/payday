import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';
import '../../widgets/income_detail_template.dart';
import '../../models/income_source.dart';

class WalkingRewardDetailScreen extends StatefulWidget {
  const WalkingRewardDetailScreen({super.key});

  @override
  State<WalkingRewardDetailScreen> createState() => _WalkingRewardDetailScreenState();
}

class _WalkingRewardDetailScreenState extends State<WalkingRewardDetailScreen>
    with TickerProviderStateMixin, IncomeDetailMixin {
  final MockWalkingData mockData = MockWalkingData();
  late AnimationController _stepAnimationController;
  late AnimationController _progressAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _stepAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  Timer? _stepTimer;
  bool _isWalking = false;

  @override
  void initState() {
    super.initState();
    _stepAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _stepAnimation = CurvedAnimation(
      parent: _stepAnimationController,
      curve: Curves.bounceOut,
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeOutCubic,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));

    _progressAnimationController.forward();
    _startStepSimulation();
  }

  void _startStepSimulation() {
    _stepTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && _isWalking) {
        setState(() {
          mockData.todaySteps += math.Random().nextInt(5) + 1;
          if (mockData.todaySteps > mockData.dailyGoal) {
            mockData.todaySteps = mockData.dailyGoal;
          }
        });
        _stepAnimationController.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _stepAnimationController.dispose();
    _progressAnimationController.dispose();
    _pulseAnimationController.dispose();
    _stepTimer?.cancel();
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
                _buildMainStepCard(),
                _buildDailyProgress(),
                _buildRewardMilestones(),
                _buildWeeklyStats(),
                _buildBadges(),
                _buildHealthStats(),
                _buildTipsSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: buildIncomeFloatingActionButton(
        IncomeType.walkingReward,
        '걸음 리워드',
        Colors.lightGreen,
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF4CAF50),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          '걷기 보상',
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
                Color(0xFF4CAF50),
                Color(0xFF8BC34A),
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
                    Icons.directions_walk,
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
                    '총 걷기 수익',
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

  Widget _buildMainStepCard() {
    final progress = mockData.todaySteps / mockData.dailyGoal;
    final remainingSteps = math.max(0, mockData.dailyGoal - mockData.todaySteps);

    return Container(
      margin: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isWalking ? _pulseAnimation.value : 1.0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF66BB6A),
                    Color(0xFF4CAF50),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return CircularProgressIndicator(
                              value: progress * _progressAnimation.value,
                              strokeWidth: 12,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            );
                          },
                        ),
                      ),
                      Column(
                        children: [
                          AnimatedBuilder(
                            animation: _stepAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 + (_stepAnimation.value * 0.1),
                                child: const Icon(
                                  Icons.directions_walk,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${mockData.todaySteps}',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '/ ${mockData.dailyGoal} 걸음',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (progress >= 1.0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 20,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '목표 달성! ₩1,000 획득',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      '${remainingSteps}걸음 더 걸으면 ₩1,000',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStepStat('거리', '${mockData.distance}km', Icons.route),
                      _buildStepStat('칼로리', '${mockData.calories}kcal', Icons.local_fire_department),
                      _buildStepStat('시간', '${mockData.activeTime}분', Icons.timer),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.white70,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyProgress() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                '오늘의 활동',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.trending_up,
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...mockData.todayActivities.map((activity) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: activity['completed']
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    activity['icon'] as IconData,
                    size: 20,
                    color: activity['completed'] ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity['title'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        activity['description'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (activity['completed'])
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '+₩${activity['reward']}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRewardMilestones() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              '보상 마일스톤',
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
              itemCount: mockData.milestones.length,
              itemBuilder: (context, index) {
                final milestone = mockData.milestones[index];
                return _buildMilestoneCard(milestone);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(Map<String, dynamic> milestone) {
    final isUnlocked = mockData.todaySteps >= milestone['steps'];
    final progress = math.min(1.0, mockData.todaySteps / milestone['steps']);

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isUnlocked
                      ? const LinearGradient(
                          colors: [Colors.amber, Colors.orange],
                        )
                      : null,
                  color: isUnlocked ? null : Colors.grey[200],
                ),
                child: Icon(
                  isUnlocked ? Icons.emoji_events : Icons.lock,
                  color: isUnlocked ? Colors.white : Colors.grey,
                  size: 28,
                ),
              ),
              SizedBox(
                width: 68,
                height: 68,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isUnlocked ? Colors.amber : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${milestone['steps']}걸음',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '₩${milestone['reward']}',
            style: TextStyle(
              fontSize: 11,
              color: isUnlocked ? Colors.green : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStats() {
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
                '주간 통계',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '평균 8,245걸음',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final day = ['월', '화', '수', '목', '금', '토', '일'][index];
              final steps = mockData.weeklySteps[index];
              final maxSteps = mockData.weeklySteps.reduce((a, b) => a > b ? a : b);
              final height = steps > 0 ? (steps / maxSteps) * 60 : 10;
              final isToday = index == 4; // 금요일이 오늘이라고 가정

              return Column(
                children: [
                  Text(
                    '${steps ~/ 1000}k',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? Colors.green : Colors.black,
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
                        colors: isToday
                            ? [Colors.green, Colors.green.withOpacity(0.5)]
                            : steps >= 10000
                                ? [Colors.blue, Colors.blue.withOpacity(0.5)]
                                : [Colors.grey[400]!, Colors.grey[300]!],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? Colors.green : Colors.grey[600],
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBadges() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              '획득한 배지',
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
              itemCount: mockData.badges.length,
              itemBuilder: (context, index) {
                final badge = mockData.badges[index];
                return _buildBadgeCard(badge);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(Map<String, dynamic> badge) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: badge['earned']
                  ? LinearGradient(
                      colors: [
                        badge['color'].withOpacity(0.8),
                        badge['color'],
                      ],
                    )
                  : null,
              color: badge['earned'] ? null : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              badge['icon'],
              size: 28,
              color: badge['earned'] ? Colors.white : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            badge['name'],
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: badge['earned'] ? Colors.black : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStats() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.05),
            Colors.pink.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.favorite,
                color: Colors.red,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                '건강 통계',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHealthItem('총 거리', '${mockData.totalDistance}km', Icons.map),
              _buildHealthItem('총 칼로리', '${mockData.totalCalories}kcal', Icons.local_fire_department),
              _buildHealthItem('평균 속도', '${mockData.averageSpeed}km/h', Icons.speed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: Colors.red[300],
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

  Widget _buildTipsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.05),
            Colors.cyan.withOpacity(0.05),
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
                Icons.lightbulb_outline,
                color: Colors.blue,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                '걷기 팁',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipItem('하루 10,000보를 목표로 꾸준히 걸어보세요'),
          _buildTipItem('계단 오르기로 추가 칼로리를 소모하세요'),
          _buildTipItem('점심시간에 짧은 산책으로 리프레시하세요'),
          _buildTipItem('친구와 함께 걸으면 더 재미있고 동기부여가 됩니다'),
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
              color: Colors.blue,
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

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        setState(() {
          _isWalking = !_isWalking;
        });
        HapticFeedback.mediumImpact();
      },
      backgroundColor: _isWalking ? Colors.red : const Color(0xFF4CAF50),
      icon: Icon(
        _isWalking ? Icons.pause : Icons.play_arrow,
        color: Colors.white,
      ),
      label: Text(
        _isWalking ? '일시정지' : '걷기 시작',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Mock Data Class
class MockWalkingData {
  int todaySteps = 7250;
  final int dailyGoal = 10000;
  final double distance = 5.2;
  final int calories = 245;
  final int activeTime = 62;
  final double totalEarnings = 28500;

  final List<int> weeklySteps = [8500, 12000, 9200, 11500, 7250, 6800, 0];

  final double totalDistance = 156.8;
  final int totalCalories = 8420;
  final double averageSpeed = 4.8;

  final List<Map<String, dynamic>> todayActivities = [
    {'title': '아침 산책', 'description': '2,500걸음 달성', 'icon': Icons.wb_sunny, 'completed': true, 'reward': 300},
    {'title': '점심 산책', 'description': '1,000걸음 달성', 'icon': Icons.restaurant, 'completed': true, 'reward': 150},
    {'title': '저녁 운동', 'description': '3,000걸음 목표', 'icon': Icons.nightlight, 'completed': false, 'reward': 400},
    {'title': '계단 오르기', 'description': '10층 달성', 'icon': Icons.stairs, 'completed': true, 'reward': 200},
  ];

  final List<Map<String, dynamic>> milestones = [
    {'steps': 2500, 'reward': 200},
    {'steps': 5000, 'reward': 400},
    {'steps': 7500, 'reward': 600},
    {'steps': 10000, 'reward': 1000},
    {'steps': 15000, 'reward': 1500},
  ];

  final List<Map<String, dynamic>> badges = [
    {'name': '첫 걸음', 'icon': Icons.flag, 'color': Colors.green, 'earned': true},
    {'name': '일주일\n연속', 'icon': Icons.calendar_today, 'color': Colors.blue, 'earned': true},
    {'name': '마라토너', 'icon': Icons.sports, 'color': Colors.purple, 'earned': false},
    {'name': '속도왕', 'icon': Icons.flash_on, 'color': Colors.orange, 'earned': false},
    {'name': '만보왕', 'icon': Icons.emoji_events, 'color': Colors.amber, 'earned': true},
  ];
}