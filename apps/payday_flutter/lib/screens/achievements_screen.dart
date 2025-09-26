import 'package:flutter/material.dart';
import '../services/achievement_service.dart';
import '../services/social_sharing_service.dart';
import 'package:percent_indicator/percent_indicator.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with TickerProviderStateMixin {
  final AchievementService _achievementService = AchievementService();
  final SocialSharingService _sharingService = SocialSharingService();

  late TabController _tabController;
  late AnimationController _animationController;
  late AnimationController _floatingController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _floatingAnimation;

  bool _isLoading = true;
  List<Achievement> _allAchievements = [];
  List<Achievement> _unlockedAchievements = [];
  List<Achievement> _lockedAchievements = [];
  Achievement? _nextAchievable;
  double _overallProgress = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _floatingAnimation = Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() => _isLoading = true);

    try {
      await _achievementService.initialize();
      await _achievementService.checkAchievements();

      setState(() {
        _allAchievements = _achievementService.allAchievements;
        _unlockedAchievements = _achievementService.unlockedAchievements;
        _lockedAchievements = _achievementService.lockedAchievements;
        _nextAchievable = _achievementService.nextAchievable;
        _overallProgress = _achievementService.overallProgress;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('업적 로드 실패: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 업적 & 공유'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '전체', icon: Icon(Icons.apps)),
            Tab(text: '획득', icon: Icon(Icons.emoji_events)),
            Tab(text: '진행중', icon: Icon(Icons.timer)),
          ],
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildProgressHeader(isDark),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAllAchievements(isDark),
                        _buildUnlockedAchievements(isDark),
                        _buildLockedAchievements(isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: _buildShareFAB(),
    );
  }

  Widget _buildProgressHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade400, Colors.orange.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Text(
            '전체 진행률',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          LinearPercentIndicator(
            width: MediaQuery.of(context).size.width - 40,
            lineHeight: 24,
            percent: _overallProgress,
            center: Text(
              '${(_overallProgress * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.white.withOpacity(0.3),
            progressColor: Colors.white,
            animation: true,
            animationDuration: 1000,
            barRadius: const Radius.circular(12),
          ),
          const SizedBox(height: 12),
          Text(
            '${_unlockedAchievements.length} / ${_allAchievements.length} 업적 달성',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllAchievements(bool isDark) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_nextAchievable != null)
                _buildNextAchievableCard(_nextAchievable!, isDark),
              const SizedBox(height: 16),
              ..._allAchievements.map((achievement) =>
                  _buildAchievementCard(achievement, isDark)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUnlockedAchievements(bool isDark) {
    if (_unlockedAchievements.isEmpty) {
      return _buildEmptyState(
        '아직 획득한 업적이 없습니다',
        '수익을 기록하고 업적을 달성해보세요!',
        Icons.emoji_events_outlined,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _unlockedAchievements.length,
      itemBuilder: (context, index) {
        final achievement = _unlockedAchievements[index];
        return _buildAchievementTile(achievement, isDark, true);
      },
    );
  }

  Widget _buildLockedAchievements(bool isDark) {
    if (_lockedAchievements.isEmpty) {
      return _buildEmptyState(
        '모든 업적을 달성했습니다!',
        '축하합니다! 당신은 진정한 마스터입니다!',
        Icons.celebration,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _lockedAchievements.length,
      itemBuilder: (context, index) {
        final achievement = _lockedAchievements[index];
        return _buildProgressCard(achievement, isDark);
      },
    );
  }

  Widget _buildNextAchievableCard(Achievement achievement, bool isDark) {
    final progress = _achievementService.getProgress(achievement);

    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimation.value),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  achievement.color.withOpacity(0.8),
                  achievement.color,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: achievement.color.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        achievement.icon,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '다음 목표',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            achievement.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  achievement.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: LinearPercentIndicator(
                        lineHeight: 8,
                        percent: progress,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        progressColor: Colors.white,
                        animation: true,
                        barRadius: const Radius.circular(4),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${achievement.currentProgress}/${achievement.requiredValue}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool isDark) {
    final isUnlocked = achievement.isUnlocked;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isUnlocked
            ? () => _showAchievementDetail(achievement)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUnlocked
                ? achievement.color.withOpacity(0.1)
                : (isDark ? Colors.grey[850] : Colors.grey[100]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUnlocked
                  ? achievement.color.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? achievement.color
                      : Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  achievement.icon,
                  color: isUnlocked ? Colors.white : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isUnlocked
                            ? (isDark ? Colors.grey[400] : Colors.grey[600])
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (isUnlocked)
                IconButton(
                  icon: const Icon(Icons.share, size: 20),
                  color: achievement.color,
                  onPressed: () => _shareAchievement(achievement),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementTile(Achievement achievement, bool isDark, bool isUnlocked) {
    return InkWell(
      onTap: isUnlocked ? () => _showAchievementDetail(achievement) : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: isUnlocked
              ? LinearGradient(
                  colors: [
                    achievement.color.withOpacity(0.8),
                    achievement.color,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: !isUnlocked ? Colors.grey.withOpacity(0.2) : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: achievement.color.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              achievement.icon,
              size: 48,
              color: isUnlocked ? Colors.white : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? Colors.white : Colors.grey,
              ),
            ),
            if (isUnlocked && achievement.unlockedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${achievement.unlockedAt!.month}/${achievement.unlockedAt!.day} 달성',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(Achievement achievement, bool isDark) {
    final progress = _achievementService.getProgress(achievement);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: achievement.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  achievement.icon,
                  color: achievement.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      achievement.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: achievement.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearPercentIndicator(
            lineHeight: 8,
            percent: progress,
            backgroundColor: achievement.color.withOpacity(0.1),
            progressColor: achievement.color,
            animation: true,
            barRadius: const Radius.circular(4),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          Text(
            '${achievement.currentProgress} / ${achievement.requiredValue}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareFAB() {
    return FloatingActionButton.extended(
      onPressed: _showShareOptions,
      backgroundColor: Colors.amber,
      icon: const Icon(Icons.share),
      label: const Text('공유하기'),
    );
  }

  void _showAchievementDetail(Achievement achievement) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    achievement.color.withOpacity(0.8),
                    achievement.color,
                  ],
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                achievement.icon,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              achievement.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (achievement.unlockedAt != null) ...[
              const SizedBox(height: 16),
              Text(
                '달성일: ${achievement.unlockedAt!.year}년 ${achievement.unlockedAt!.month}월 ${achievement.unlockedAt!.day}일',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _shareAchievement(achievement);
                },
                icon: const Icon(Icons.share),
                label: const Text('업적 공유하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: achievement.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '무엇을 공유하시겠습니까?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildShareOption(
              '월간 리포트',
              Icons.calendar_month,
              Colors.blue,
              () async {
                Navigator.pop(context);
                final message = await _sharingService.generateMonthlyReport();
                await _sharingService.shareWithCustomMessage(
                  baseMessage: message,
                );
              },
            ),
            _buildShareOption(
              '주간 성과',
              Icons.trending_up,
              Colors.green,
              () async {
                Navigator.pop(context);
                final message = await _sharingService.generateWeeklyProgress();
                await _sharingService.shareWithCustomMessage(
                  baseMessage: message,
                );
              },
            ),
            _buildShareOption(
              '전체 업적',
              Icons.emoji_events,
              Colors.amber,
              () async {
                Navigator.pop(context);
                final message = '''
🏆 PayDay 업적 현황

달성한 업적: ${_unlockedAchievements.length}개
전체 진행률: ${(_overallProgress * 100).toStringAsFixed(1)}%

${_unlockedAchievements.take(3).map((a) => '✅ ${a.title}').join('\n')}

#PayDay #업적달성 #수익관리
📱 PayDay와 함께 성장하세요!
                ''';
                await _sharingService.shareWithCustomMessage(
                  baseMessage: message,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareAchievement(Achievement achievement) async {
    await _sharingService.shareAchievementWithImage(
      achievement: achievement,
      context: context,
    );
  }
}