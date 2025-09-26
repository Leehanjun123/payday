import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';
import '../models/income_source.dart';
import '../models/gamification.dart';
import '../services/income_data_service.dart';
import 'income_detail_screen.dart';
import 'income_details/reward_ad_detail_screen.dart';
import 'income_details/daily_mission_detail_screen.dart';
import 'income_details/referral_detail_screen.dart';
import 'income_details/survey_detail_screen.dart';
import 'income_details/quiz_detail_screen.dart';
import 'income_details/walking_reward_detail_screen.dart';
import 'income_details/game_detail_screen.dart';
import 'income_details/review_detail_screen.dart';
import 'income_details/youtube_detail_screen.dart';
import 'income_details/blog_detail_screen.dart';
import 'income_details/tiktok_detail_screen.dart';
import 'income_details/instagram_detail_screen.dart';
import 'income_details/freelance_detail_screen.dart';
import 'income_details/stock_detail_screen.dart';
import 'income_details/crypto_detail_screen.dart';
import 'income_details/delivery_detail_screen.dart';

class UltimateFlowHome extends StatefulWidget {
  const UltimateFlowHome({Key? key}) : super(key: key);

  @override
  State<UltimateFlowHome> createState() => _UltimateFlowHomeState();
}

class _UltimateFlowHomeState extends State<UltimateFlowHome>
    with TickerProviderStateMixin {
  // Services
  final IncomeDataService _incomeService = IncomeDataService();

  // Controllers
  late PageController _pageController;
  late AnimationController _flowController;
  late AnimationController _counterController;
  late AnimationController _gradientController;
  late AnimationController _fabController;
  late AnimationController _celebrationController;

  // Data
  List<IncomeSource> _topIncomeSources = [];
  List<DailyQuest> _dailyQuests = [];
  double _totalEarnings = 0;
  double _todayEarnings = 0;
  double _displayedEarnings = 0;
  int _userPoints = 3250;
  late LevelInfo _userLevel;
  late EmotionalTheme _currentTheme;
  StreakInfo _streakInfo = StreakInfo(
    currentStreak: 7,
    bestStreak: 21,
    lastCheckIn: DateTime.now(),
    streakBonus: 200,
    todayCheckedIn: true,
  );

  // UI State
  int _currentPage = 0;
  bool _isLoading = false;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadData();
  }

  void _initializeControllers() {
    _pageController = PageController(viewportFraction: 0.85);

    _flowController = AnimationController(
      duration: FlowAnimation.pageTransition,
      vsync: this,
    );

    _counterController = AnimationController(
      duration: FlowAnimation.counterAnimation,
      vsync: this,
    );

    _gradientController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _fabController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );

    _celebrationController = AnimationController(
      duration: FlowAnimation.celebrationAnimation,
      vsync: this,
    );

    _userLevel = LevelInfo.getLevelInfo(_userPoints);
    _currentTheme = EmotionalTheme.getThemeByEarnings(_todayEarnings);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final allSources = await _incomeService.getAllIncomeSources();
      final quests = _generateDailyQuests();

      // Top 5 수익원만 표시
      allSources.sort((a, b) => b.monthlyIncome.compareTo(a.monthlyIncome));

      setState(() {
        _topIncomeSources = allSources.take(5).toList();
        _dailyQuests = quests;
        _totalEarnings = allSources.fold(0, (sum, s) => sum + s.monthlyIncome);
        _todayEarnings = allSources.fold(0, (sum, s) => sum + s.todayIncome);
        _currentTheme = EmotionalTheme.getThemeByEarnings(_todayEarnings);
        _isLoading = false;
      });

      // 카운터 애니메이션 시작
      _animateCounter();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _animateCounter() {
    final tween = Tween<double>(begin: 0, end: _todayEarnings);
    final animation = tween.animate(CurvedAnimation(
      parent: _counterController,
      curve: Curves.easeOutQuart,
    ));

    animation.addListener(() {
      setState(() {
        _displayedEarnings = animation.value;
      });
    });

    _counterController.forward();
  }

  List<DailyQuest> _generateDailyQuests() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    return [
      DailyQuest(
        id: 'q1',
        title: '광고 마스터',
        description: '광고 5개 시청',
        reward: 500,
        experience: 50,
        type: QuestType.watchAds,
        currentProgress: 2,
        targetProgress: 5,
        isCompleted: false,
        expiresAt: tomorrow,
        icon: '📺',
      ),
      DailyQuest(
        id: 'q2',
        title: '걷기 챌린지',
        description: '5,000보 걷기',
        reward: 300,
        experience: 30,
        type: QuestType.walkSteps,
        currentProgress: 3456,
        targetProgress: 5000,
        isCompleted: false,
        expiresAt: tomorrow,
        icon: '🚶',
      ),
      DailyQuest(
        id: 'q3',
        title: '수익 목표',
        description: '10,000원 달성',
        reward: 1000,
        experience: 100,
        type: QuestType.earnAmount,
        currentProgress: _todayEarnings.round(),
        targetProgress: 10000,
        isCompleted: _todayEarnings >= 10000,
        expiresAt: tomorrow,
        icon: '💰',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 감성 그라디언트 배경
          AnimatedBuilder(
            animation: _gradientController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _currentTheme.colors,
                    transform: GradientRotation(_gradientController.value * 2 * math.pi),
                  ),
                ),
              );
            },
          ),

          // 메인 컨텐츠
          SafeArea(
            child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                _buildLevelCard(),
                _buildEarningsCard(),
                _buildDailyQuests(),
                _buildTopIncomeCards(),
                _buildLeaderboard(),
              ],
            ),
          ),

          // FAB (플로팅 액션 버튼)
          _buildFloatingActionButton(),

          // 축하 애니메이션
          if (_showCelebration) _buildCelebrationOverlay(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 80,
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.all(16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '안녕하세요, 한준님 👋',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${_streakInfo.streakEmoji}',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${_streakInfo.currentStreak}일 연속',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_active, color: Colors.white),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.emoji_events, color: Colors.white),
                  onPressed: () => _showAchievements(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard() {
    final progress = (_userPoints - _userLevel.minPoints) /
                     (_userLevel.maxPoints - _userLevel.minPoints);

    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _userLevel.primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      _userLevel.badge,
                      style: TextStyle(fontSize: 32),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_userLevel.name} 레벨',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_userPoints} 포인트',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _userLevel.gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'x${_userLevel.bonusMultiplier} 보너스',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(_userLevel.primaryColor),
              ),
            ),
            SizedBox(height: 8),
            Text(
              '다음 레벨까지 ${_userLevel.maxPoints - _userPoints + 1} 포인트',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsCard() {
    return SliverToBoxAdapter(
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          // 드래그로 금액 조절 인터랙션
          if (details.delta.dy < 0) {
            setState(() {
              _displayedEarnings = math.min(
                _displayedEarnings + 1000,
                _todayEarnings * 1.5,
              );
            });
          }
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16),
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.white.withOpacity(0.9)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                '오늘의 수익',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: _displayedEarnings),
                duration: Duration(seconds: 2),
                curve: Curves.easeOutQuart,
                builder: (context, value, child) {
                  return Text(
                    '₩${value.round().toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]},',
                    )}',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..shader = LinearGradient(
                          colors: _currentTheme.colors,
                        ).createShader(Rect.fromLTWH(0, 0, 200, 70)),
                    ),
                  );
                },
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up, color: Colors.green, size: 16),
                  SizedBox(width: 4),
                  Text(
                    '어제보다 23% 증가',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // 실시간 수익 애니메이션
              _buildRealtimeEarnings(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRealtimeEarnings() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Text(
            '실시간',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(width: 8),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: 100),
            duration: Duration(seconds: 3),
            onEnd: () {
              setState(() {
                _displayedEarnings += 100;
              });
            },
            builder: (context, value, child) {
              return Text(
                '+₩$value',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDailyQuests() {
    return SliverToBoxAdapter(
      child: Container(
        height: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                '일일 퀘스트 🎯',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: _dailyQuests.length,
                itemBuilder: (context, index) {
                  final quest = _dailyQuests[index];
                  return _buildQuestCard(quest);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestCard(DailyQuest quest) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (!quest.isCompleted) {
          _completeQuest(quest);
        }
      },
      child: Container(
        width: 150,
        margin: EdgeInsets.only(right: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: quest.isCompleted
              ? Colors.green.withOpacity(0.9)
              : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: quest.isCompleted ? Colors.green : Colors.white,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quest.icon,
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 8),
            Text(
              quest.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: quest.isCompleted ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              quest.description,
              style: TextStyle(
                fontSize: 11,
                color: quest.isCompleted ? Colors.white70 : Colors.grey[600],
              ),
            ),
            Spacer(),
            if (!quest.isCompleted) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: quest.progressPercent,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  minHeight: 4,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${quest.currentProgress}/${quest.targetProgress}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ] else ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '✓ +${quest.reward}원',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopIncomeCards() {
    return SliverToBoxAdapter(
      child: Container(
        height: 200,
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() => _currentPage = index);
            HapticFeedback.selectionClick();
          },
          itemCount: _topIncomeSources.length,
          itemBuilder: (context, index) {
            final source = _topIncomeSources[index];
            return _buildIncomeCard(source, index);
          },
        ),
      ),
    );
  }

  Widget _buildIncomeCard(IncomeSource source, int index) {
    final isCurrentPage = _currentPage == index;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOutQuart,
      margin: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: isCurrentPage ? 8 : 16,
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          _navigateToDetail(source);
        },
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              if (isCurrentPage)
                BoxShadow(
                  color: _getTypeColor(source.type).withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                source.icon,
                style: TextStyle(fontSize: 32),
              ),
              SizedBox(height: 8),
              Text(
                source.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                source.description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Text(
                '₩${source.monthlyIncome.round().toString()}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _getTypeColor(source.type),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '이번 달',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    source.changePercent > 0
                        ? Icons.trending_up
                        : Icons.trending_down,
                    size: 14,
                    color: source.changePercent > 0 ? Colors.green : Colors.red,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${source.changePercent.abs()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: source.changePercent > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboard() {
    final leaderboard = _getMockLeaderboard();

    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🏆 리더보드',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text('전체 보기'),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...leaderboard.take(3).map((entry) => _buildLeaderboardItem(entry)),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardItem(LeaderboardEntry entry) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? _userLevel.primaryColor.withOpacity(0.1)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: entry.isCurrentUser
            ? Border.all(color: _userLevel.primaryColor, width: 2)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            child: Text(
              entry.rankEmoji,
              style: TextStyle(fontSize: 20),
            ),
          ),
          SizedBox(width: 12),
          CircleAvatar(
            radius: 20,
            backgroundColor: _userLevel.primaryColor.withOpacity(0.2),
            child: Text(
              entry.userName[0].toUpperCase(),
              style: TextStyle(
                color: _userLevel.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.userName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (entry.isCurrentUser) ...[
                      SizedBox(width: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _userLevel.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${entry.points} pts • ₩${entry.earnings.round()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            LevelInfo.getLevelInfo(entry.points).badge,
            style: TextStyle(fontSize: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Positioned(
      right: 16,
      bottom: 80,
      child: ScaleTransition(
        scale: Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _fabController,
            curve: Curves.elasticOut,
          ),
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            HapticFeedback.heavyImpact();
            _showQuickActions();
          },
          backgroundColor: _currentTheme.colors.first,
          icon: Icon(Icons.flash_on, color: Colors.white),
          label: Text(
            '빠른 수익',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, '홈', true),
              _buildNavItem(Icons.explore_rounded, '탐색', false),
              _buildNavItem(Icons.add_circle_outline_rounded, '추가', false),
              _buildNavItem(Icons.leaderboard_rounded, '순위', false),
              _buildNavItem(Icons.person_rounded, '프로필', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return GestureDetector(
      onTap: () => HapticFeedback.selectionClick(),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? _currentTheme.colors.first.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? _currentTheme.colors.first : Colors.grey,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? _currentTheme.colors.first : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebrationOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '🎉',
              style: TextStyle(fontSize: 80),
            ),
            SizedBox(height: 20),
            Text(
              '축하합니다!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '일일 목표 달성!',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: _currentTheme.colors),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                '+1,000원 보너스',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _completeQuest(DailyQuest quest) {
    setState(() {
      final index = _dailyQuests.indexOf(quest);
      _dailyQuests[index] = DailyQuest(
        id: quest.id,
        title: quest.title,
        description: quest.description,
        reward: quest.reward,
        experience: quest.experience,
        type: quest.type,
        currentProgress: quest.targetProgress,
        targetProgress: quest.targetProgress,
        isCompleted: true,
        expiresAt: quest.expiresAt,
        icon: quest.icon,
      );

      _userPoints += quest.experience;
      _todayEarnings += quest.reward;
      _displayedEarnings = _todayEarnings;

      // 레벨업 체크
      final newLevel = LevelInfo.getLevelInfo(_userPoints);
      if (newLevel.level != _userLevel.level) {
        _userLevel = newLevel;
        _showLevelUpAnimation();
      }
    });

    HapticFeedback.heavyImpact();
  }

  void _showLevelUpAnimation() {
    setState(() => _showCelebration = true);
    _celebrationController.forward().then((_) {
      setState(() => _showCelebration = false);
      _celebrationController.reset();
    });
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '⚡ 빠른 수익 창출',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            _buildQuickActionItem('📺', '광고 시청', '+300원', Colors.purple),
            _buildQuickActionItem('🎯', '미니게임', '+500원', Colors.orange),
            _buildQuickActionItem('📋', '설문조사', '+1,000원', Colors.blue),
            _buildQuickActionItem('👥', '친구 초대', '+5,000원', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(String emoji, String title, String reward, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(context);
            // 액션 실행
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(emoji, style: TextStyle(fontSize: 24)),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '즉시 실행 가능',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    reward,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAchievements() {
    // 업적 화면 표시
  }

  void _navigateToDetail(IncomeSource source) {
    Widget targetScreen;

    // 수익원 타입에 따라 다른 상세 화면으로 이동
    switch (source.type) {
      case IncomeType.rewardAd:
        targetScreen = const RewardAdDetailScreen();
        break;
      case IncomeType.dailyMission:
        targetScreen = const DailyMissionDetailScreen();
        break;
      case IncomeType.referral:
        targetScreen = const ReferralDetailScreen();
        break;
      case IncomeType.survey:
        targetScreen = const SurveyDetailScreen();
        break;
      case IncomeType.quiz:
        targetScreen = const QuizDetailScreen();
        break;
      case IncomeType.walking:
      case IncomeType.walkingReward:
        targetScreen = const WalkingRewardDetailScreen();
        break;
      case IncomeType.game:
        targetScreen = const GameDetailScreen();
        break;
      case IncomeType.review:
        targetScreen = const ReviewDetailScreen();
        break;
      case IncomeType.youtube:
        targetScreen = const YouTubeDetailScreen();
        break;
      case IncomeType.blog:
        targetScreen = const BlogDetailScreen();
        break;
      case IncomeType.tiktok:
        targetScreen = const TikTokDetailScreen();
        break;
      case IncomeType.instagram:
        targetScreen = const InstagramDetailScreen();
        break;
      case IncomeType.freelance:
        targetScreen = const FreelanceDetailScreen();
        break;
      case IncomeType.stock:
        targetScreen = const StockDetailScreen();
        break;
      case IncomeType.crypto:
        targetScreen = const CryptoDetailScreen();
        break;
      case IncomeType.delivery:
        targetScreen = const DeliveryDetailScreen();
        break;
      // TODO: 다른 수익원별 화면 추가
      default:
        targetScreen = IncomeDetailScreen(incomeSource: source);
        break;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => targetScreen,
      ),
    );
  }

  Color _getTypeColor(IncomeType type) {
    switch (type) {
      case IncomeType.youtube:
        return Colors.red;
      case IncomeType.freelance:
        return Colors.indigo;
      case IncomeType.stock:
        return Colors.teal;
      case IncomeType.crypto:
        return Colors.orange;
      case IncomeType.realestate:
        return Colors.brown;
      case IncomeType.tiktok:
        return Colors.black;
      case IncomeType.instagram:
        return Colors.purple;
      case IncomeType.blog:
        return Colors.green;
      case IncomeType.freelance:
        return Colors.indigo;
      case IncomeType.stock:
        return Colors.teal;
      case IncomeType.crypto:
        return Colors.orange;
      case IncomeType.delivery:
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  List<LeaderboardEntry> _getMockLeaderboard() {
    return [
      LeaderboardEntry(
        userId: '1',
        userName: '김철수',
        userAvatar: '',
        rank: 1,
        points: 12500,
        earnings: 850000,
        level: UserLevel.platinum,
        isCurrentUser: false,
      ),
      LeaderboardEntry(
        userId: '2',
        userName: '이영희',
        userAvatar: '',
        rank: 2,
        points: 9800,
        earnings: 650000,
        level: UserLevel.gold,
        isCurrentUser: false,
      ),
      LeaderboardEntry(
        userId: '3',
        userName: '한준',
        userAvatar: '',
        rank: 3,
        points: _userPoints,
        earnings: _todayEarnings,
        level: _userLevel.level,
        isCurrentUser: true,
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    _flowController.dispose();
    _counterController.dispose();
    _gradientController.dispose();
    _fabController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }
}