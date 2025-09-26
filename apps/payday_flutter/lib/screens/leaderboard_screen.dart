import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/gamification.dart';
import 'dart:math' as math;

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;

  final List<String> _periods = ['오늘', '이번 주', '이번 달', '전체'];
  String _selectedPeriod = '이번 주';

  final List<LeaderboardEntry> _globalLeaderboard = _generateMockLeaderboard(50);
  final List<LeaderboardEntry> _friendsLeaderboard = _generateMockLeaderboard(20);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  static List<LeaderboardEntry> _generateMockLeaderboard(int count) {
    final names = [
      '김철수', '이영희', '박민수', '최지우', '정다은',
      '한준', '송민지', '강현우', '윤서연', '임재현',
      '조수빈', '서예진', '신동욱', '문지훈', '홍서준',
    ];

    return List.generate(count, (index) {
      final random = math.Random(index);
      return LeaderboardEntry(
        userId: 'user_$index',
        userName: index == 2 ? '한준 (나)' : names[random.nextInt(names.length)],
        userAvatar: '',
        rank: index + 1,
        points: (50000 - (index * 1000) + random.nextInt(500)),
        earnings: (1000000 - (index * 20000) + random.nextInt(10000)).toDouble(),
        level: index < 3
          ? UserLevel.diamond
          : index < 10
            ? UserLevel.platinum
            : index < 20
              ? UserLevel.gold
              : index < 35
                ? UserLevel.silver
                : UserLevel.bronze,
        isCurrentUser: index == 2,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF667EEA),
              const Color(0xFF764BA2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTopThree(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLeaderboardList(_globalLeaderboard),
                    _buildLeaderboardList(_friendsLeaderboard),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🏆 리더보드',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white),
                onPressed: _showInfoDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 기간 선택
          Container(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _periods.length,
              itemBuilder: (context, index) {
                final period = _periods[index];
                final isSelected = _selectedPeriod == period;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedPeriod = period);
                    HapticFeedback.selectionClick();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        period,
                        style: TextStyle(
                          color: isSelected
                            ? const Color(0xFF667EEA)
                            : Colors.white,
                          fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopThree() {
    final top3 = _globalLeaderboard.take(3).toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2등
          _buildTopThreeItem(top3[1], 2),
          const SizedBox(width: 16),
          // 1등
          _buildTopThreeItem(top3[0], 1),
          const SizedBox(width: 16),
          // 3등
          _buildTopThreeItem(top3[2], 3),
        ],
      ),
    );
  }

  Widget _buildTopThreeItem(LeaderboardEntry entry, int rank) {
    final isFirst = rank == 1;
    final height = isFirst ? 140.0 : rank == 2 ? 120.0 : 100.0;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 왕관 (1등만)
          if (isFirst)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1000),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: const Text(
                    '👑',
                    style: TextStyle(fontSize: 32),
                  ),
                );
              },
            ),

          // 아바타
          Container(
            width: isFirst ? 70 : 60,
            height: isFirst ? 70 : 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: rank == 1
                  ? Colors.amber
                  : rank == 2
                    ? Colors.grey[300]!
                    : Colors.orange[700]!,
                width: 3,
              ),
              gradient: LinearGradient(
                colors: LevelInfo.getLevelInfo(entry.points).gradientColors,
              ),
            ),
            child: Center(
              child: Text(
                entry.userName[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isFirst ? 28 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 이름
          Text(
            entry.userName.length > 5
              ? '${entry.userName.substring(0, 5)}...'
              : entry.userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),

          // 포인트
          Text(
            '${entry.points} pts',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),

          // 받침대
          AnimatedContainer(
            duration: Duration(milliseconds: 500 + (rank * 100)),
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: rank == 1
                  ? [Colors.amber, Colors.amber[700]!]
                  : rank == 2
                    ? [Colors.grey[300]!, Colors.grey[400]!]
                    : [Colors.orange[600]!, Colors.orange[700]!],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isFirst ? 48 : 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: const Color(0xFF667EEA),
        unselectedLabelColor: Colors.white,
        tabs: const [
          Tab(text: '🌍 전체'),
          Tab(text: '👥 친구'),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(List<LeaderboardEntry> leaderboard) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 내 순위 고정 표시
          if (leaderboard.any((e) => e.isCurrentUser))
            _buildMyRankCard(leaderboard.firstWhere((e) => e.isCurrentUser)),

          // 리더보드 리스트
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: leaderboard.length,
              itemBuilder: (context, index) {
                final entry = leaderboard[index];

                // 내 순위는 이미 위에 표시했으므로 스킵
                if (entry.isCurrentUser) {
                  return const SizedBox.shrink();
                }

                return _buildLeaderboardItem(entry, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRankCard(LeaderboardEntry myEntry) {
    final levelInfo = LevelInfo.getLevelInfo(myEntry.points);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: levelInfo.gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: levelInfo.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // 순위
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#${myEntry.rank}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 아바타
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              color: Colors.white,
            ),
            child: Center(
              child: Text(
                '나',
                style: TextStyle(
                  color: levelInfo.primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '내 순위',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      levelInfo.badge,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                Text(
                  '${myEntry.points} pts • ₩${_formatNumber(myEntry.earnings.round())}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // 상승/하락 표시
          Column(
            children: [
              Icon(
                Icons.arrow_upward,
                color: Colors.white,
                size: 16,
              ),
              Text(
                '2',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(LeaderboardEntry entry, int index) {
    final levelInfo = LevelInfo.getLevelInfo(entry.points);
    final delay = math.min(index * 50, 500);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: entry.rank <= 10 ? 2 : 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              HapticFeedback.selectionClick();
              _showUserProfile(entry);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: entry.rank <= 10
                  ? Border.all(
                      color: levelInfo.primaryColor.withOpacity(0.2),
                      width: 1,
                    )
                  : null,
              ),
              child: Row(
                children: [
                  // 순위
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: entry.rank <= 3
                      ? Text(
                          entry.rank == 1 ? '🥇' : entry.rank == 2 ? '🥈' : '🥉',
                          style: const TextStyle(fontSize: 24),
                        )
                      : Text(
                          '#${entry.rank}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                  ),
                  const SizedBox(width: 12),

                  // 아바타
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: levelInfo.gradientColors,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        entry.userName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 사용자 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              entry.userName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              levelInfo.badge,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        Text(
                          '${entry.points} pts',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 수익
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₩${_formatNumber(entry.earnings.round())}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: levelInfo.primaryColor,
                        ),
                      ),
                      Text(
                        '이번 달',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
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
  }

  void _showUserProfile(LeaderboardEntry entry) {
    final levelInfo = LevelInfo.getLevelInfo(entry.points);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 프로필 헤더
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: levelInfo.gradientColors,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      entry.userName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            entry.userName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: levelInfo.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  levelInfo.badge,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  levelInfo.name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: levelInfo.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '전체 #${entry.rank}위',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 통계
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('포인트', '${entry.points}'),
                _buildStatItem('월 수익', '₩${_formatNumber(entry.earnings.round())}'),
                _buildStatItem('레벨', levelInfo.name),
              ],
            ),
            const SizedBox(height: 24),

            // 액션 버튼
            Row(
              children: [
                if (!entry.isCurrentUser) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('친구 추가'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.emoji_events, color: Colors.white),
                    label: const Text(
                      '도전하기',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667EEA),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('리더보드 안내'),
        content: const Text(
          '리더보드는 사용자들의 활동과 수익을 기준으로 순위가 매겨집니다.\n\n'
          '• 포인트: 미션 완료, 수익 창출 등으로 획득\n'
          '• 레벨: 포인트 누적으로 상승\n'
          '• 보상: 상위 랭커에게 특별 보너스 지급\n\n'
          '매주 월요일 순위가 초기화되며, 주간 보상이 지급됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toString();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}