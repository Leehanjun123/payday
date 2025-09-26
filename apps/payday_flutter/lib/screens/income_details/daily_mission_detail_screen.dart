import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../../widgets/income_detail_template.dart';
import '../../models/income_source.dart';

class DailyMissionDetailScreen extends StatefulWidget {
  const DailyMissionDetailScreen({super.key});

  @override
  State<DailyMissionDetailScreen> createState() => _DailyMissionDetailScreenState();
}

class _DailyMissionDetailScreenState extends State<DailyMissionDetailScreen>
    with TickerProviderStateMixin, IncomeDetailMixin {
  final MockDailyMissionData mockData = MockDailyMissionData();
  late AnimationController _streakAnimationController;
  late AnimationController _progressAnimationController;
  late Animation<double> _streakAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _streakAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _streakAnimation = CurvedAnimation(
      parent: _streakAnimationController,
      curve: Curves.elasticOut,
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeOutCubic,
    );

    _streakAnimationController.forward();
    _progressAnimationController.forward();
    mockData.startMissionRefresh();
  }

  @override
  void dispose() {
    _streakAnimationController.dispose();
    _progressAnimationController.dispose();
    mockData.dispose();
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
                _buildStreakCard(),
                _buildTodayProgress(),
                _buildActiveMissions(),
                _buildCompletedMissions(),
                _buildRewardHistory(),
                _buildTipsSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: buildIncomeFloatingActionButton(
        IncomeType.dailyMission,
        '데일리 미션',
        Colors.brown,
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF1A1A1A),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          '일일 미션',
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
                Color(0xFF1A1A1A),
                Color(0xFF2D2D2D),
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
                    Icons.task_alt_rounded,
                    size: 48,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '₩${mockData.todayEarnings.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    '오늘의 수익',
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

  Widget _buildStreakCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _streakAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.9 + (_streakAnimation.value * 0.1),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_fire_department,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '연속 출석',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        '${mockData.currentStreak}일째',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    const Text(
                      '다음 보너스까지',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '${7 - (mockData.currentStreak % 7)}일',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTodayProgress() {
    final progress = mockData.completedToday / mockData.totalMissionsToday;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '오늘의 진행률',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${mockData.completedToday}/${mockData.totalMissionsToday}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2196F3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress * _progressAnimation.value,
                      minHeight: 12,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 1.0 ? Colors.green : const Color(0xFF2196F3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (progress >= 1.0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '오늘의 미션 완료! +₩2,000 보너스',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActiveMissions() {
    return StreamBuilder<List<Mission>>(
      stream: mockData.missionsStream,
      initialData: mockData.activeMissions,
      builder: (context, snapshot) {
        final missions = snapshot.data!;
        if (missions.isEmpty) return const SizedBox();

        return Container(
          margin: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  '진행 중인 미션',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...missions.map((mission) => _buildMissionCard(mission)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMissionCard(Mission mission) {
    final progressPercent = mission.progress / mission.target;
    final isCompleted = mission.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isCompleted ? null : () => _completeMission(mission),
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
                        color: mission.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        mission.icon,
                        color: mission.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mission.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mission.description,
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
                        color: isCompleted
                            ? Colors.green.withOpacity(0.1)
                            : mission.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isCompleted ? '완료' : '+₩${mission.reward.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? Colors.green : mission.color,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isCompleted) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progressPercent,
                            minHeight: 8,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(mission.color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${mission.progress}/${mission.target}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimeRemaining(mission.expiresAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedMissions() {
    if (mockData.completedMissions.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              '완료된 미션',
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
              itemCount: mockData.completedMissions.length,
              itemBuilder: (context, index) {
                final mission = mockData.completedMissions[index];
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withOpacity(0.1),
                        Colors.green.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mission.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+₩${mission.reward.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildRewardHistory() {
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
                '이번 주 획득 보상',
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
          ...mockData.weeklyRewards.map((day) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: day['completed']
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      day['day'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: day['completed'] ? Colors.green : Colors.grey,
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
                        day['date'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '미션 ${day['missions']}개 완료',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '+₩${day['reward']}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: day['completed'] ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          )),
          const Divider(height: 24),
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
                '₩${mockData.weeklyTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2196F3),
                ),
              ),
            ],
          ),
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
                Icons.lightbulb_outline,
                color: Colors.amber,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                '미션 공략 팁',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipItem('매일 같은 시간에 접속하면 습관이 되어 연속 출석이 쉬워져요'),
          _buildTipItem('간단한 미션부터 완료하면 동기부여가 됩니다'),
          _buildTipItem('주간 보너스를 받으려면 매일 최소 3개 이상 완료하세요'),
          _buildTipItem('친구 초대 미션은 보상이 가장 크니 놓치지 마세요'),
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

  String _formatTimeRemaining(DateTime expiresAt) {
    final now = DateTime.now();
    final difference = expiresAt.difference(now);

    if (difference.inHours > 0) {
      return '${difference.inHours}시간 남음';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 남음';
    } else {
      return '곧 만료';
    }
  }

  void _completeMission(Mission mission) {
    if (mission.isCompleted) return;

    HapticFeedback.mediumImpact();
    setState(() {
      mission.progress = mission.target;
      mission.isCompleted = true;
      mockData.completedToday++;
      mockData.todayEarnings += mission.reward;
      mockData.completedMissions.add(mission);
      mockData.activeMissions.remove(mission);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('${mission.title} 완료! +₩${mission.reward.toStringAsFixed(0)}'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

// Mock Data Classes
class Mission {
  final String id;
  final String title;
  final String description;
  final double reward;
  int progress;
  final int target;
  bool isCompleted;
  final DateTime expiresAt;
  final IconData icon;
  final Color color;

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    required this.progress,
    required this.target,
    required this.isCompleted,
    required this.expiresAt,
    required this.icon,
    required this.color,
  });
}

class MockDailyMissionData {
  List<Mission> activeMissions = [];
  List<Mission> completedMissions = [];
  int completedToday = 0;
  int totalMissionsToday = 5;
  int currentStreak = 12;
  double todayEarnings = 3500;
  double weeklyTotal = 18500;

  final Stream<List<Mission>> missionsStream = Stream.periodic(
    const Duration(seconds: 30),
    (count) => [],
  );

  List<Map<String, dynamic>> weeklyRewards = [
    {'day': '월', 'date': '12/23', 'missions': 5, 'reward': 3500, 'completed': true},
    {'day': '화', 'date': '12/24', 'missions': 4, 'reward': 2800, 'completed': true},
    {'day': '수', 'date': '12/25', 'missions': 6, 'reward': 4200, 'completed': true},
    {'day': '목', 'date': '12/26', 'missions': 5, 'reward': 3500, 'completed': true},
    {'day': '금', 'date': '12/27', 'missions': 3, 'reward': 2100, 'completed': true},
    {'day': '토', 'date': '12/28', 'missions': 4, 'reward': 2400, 'completed': true},
    {'day': '일', 'date': '12/29', 'missions': 0, 'reward': 0, 'completed': false},
  ];

  MockDailyMissionData() {
    _initializeMissions();
  }

  void _initializeMissions() {
    final now = DateTime.now();
    activeMissions = [
      Mission(
        id: '1',
        title: '출석 체크',
        description: '오늘의 출석을 완료하세요',
        reward: 500,
        progress: 1,
        target: 1,
        isCompleted: false,
        expiresAt: now.add(const Duration(hours: 23)),
        icon: Icons.calendar_today,
        color: Colors.blue,
      ),
      Mission(
        id: '2',
        title: '광고 3개 시청',
        description: '리워드 광고를 3개 시청하세요',
        reward: 800,
        progress: 1,
        target: 3,
        isCompleted: false,
        expiresAt: now.add(const Duration(hours: 22)),
        icon: Icons.play_circle_outline,
        color: Colors.purple,
      ),
      Mission(
        id: '3',
        title: '설문조사 참여',
        description: '간단한 설문조사 1개 완료',
        reward: 1200,
        progress: 0,
        target: 1,
        isCompleted: false,
        expiresAt: now.add(const Duration(hours: 20)),
        icon: Icons.assignment,
        color: Colors.orange,
      ),
      Mission(
        id: '4',
        title: '5,000보 걷기',
        description: '오늘 5,000보를 걸어보세요',
        reward: 600,
        progress: 3241,
        target: 5000,
        isCompleted: false,
        expiresAt: now.add(const Duration(hours: 18)),
        icon: Icons.directions_walk,
        color: Colors.green,
      ),
      Mission(
        id: '5',
        title: '친구 초대',
        description: '친구 1명을 앱에 초대하세요',
        reward: 2000,
        progress: 0,
        target: 1,
        isCompleted: false,
        expiresAt: now.add(const Duration(hours: 15)),
        icon: Icons.person_add,
        color: Colors.pink,
      ),
    ];
  }

  void startMissionRefresh() {
    // Simulates mission updates
  }

  void dispose() {
    // Clean up
  }
}