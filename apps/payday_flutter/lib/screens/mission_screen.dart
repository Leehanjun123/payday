import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/mission_service.dart';
import '../services/analytics_service.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class MissionScreen extends StatefulWidget {
  const MissionScreen({Key? key}) : super(key: key);

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen>
    with SingleTickerProviderStateMixin {
  final MissionService _missionService = MissionService();
  final NumberFormat _numberFormat = NumberFormat('#,###', 'ko_KR');

  late TabController _tabController;
  List<Map<String, dynamic>> _dailyMissions = [];
  List<Map<String, dynamic>> _weeklyMissions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    setState(() => _isLoading = true);

    try {
      await _missionService.initialize();

      setState(() {
        _dailyMissions = _missionService.getDailyMissions();
        _weeklyMissions = _missionService.getWeeklyMissions();
      });
    } catch (e) {
      print('미션 로드 실패: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMissionList(_dailyMissions, true),
                _buildMissionList(_weeklyMissions, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text('미션'),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      actions: [
        IconButton(
          icon: Stack(
            children: [
              Icon(Icons.card_giftcard),
              if (_missionService.getClaimableRewardsCount() > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_missionService.getClaimableRewardsCount()}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: _showRewards,
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final dailyCompleted = _missionService.getCompletedDailyCount();
    final weeklyCompleted = _missionService.getCompletedWeeklyCount();
    final totalDaily = _dailyMissions.length;
    final totalWeekly = _weeklyMissions.length;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[600]!],
        ),
      ),
      child: Column(
        children: [
          Text(
            '오늘의 미션 진행도',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildProgressCircle(
                '일일',
                dailyCompleted,
                totalDaily,
                Colors.yellow,
              ),
              _buildProgressCircle(
                '주간',
                weeklyCompleted,
                totalWeekly,
                Colors.green,
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: Colors.orange,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  '연속 미션: ${_getStreak()}일째',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildProgressCircle(
    String label,
    int completed,
    int total,
    Color color,
  ) {
    final percent = total > 0 ? completed / total : 0.0;

    return Column(
      children: [
        CircularPercentIndicator(
          radius: 50.0,
          lineWidth: 8.0,
          percent: percent,
          center: Text(
            '$completed/$total',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          progressColor: color,
          backgroundColor: Colors.white.withOpacity(0.2),
          circularStrokeCap: CircularStrokeCap.round,
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Colors.blue,
        tabs: [
          Tab(
            text: '일일 미션',
            icon: Icon(Icons.today, size: 20),
          ),
          Tab(
            text: '주간 미션',
            icon: Icon(Icons.date_range, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionList(List<Map<String, dynamic>> missions, bool isDaily) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (missions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_turned_in,
              size: 80,
              color: Colors.grey[300],
            ),
            SizedBox(height: 16),
            Text(
              '미션이 없습니다',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMissions,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: missions.length,
        itemBuilder: (context, index) {
          final mission = missions[index];
          return _buildMissionCard(mission, index, isDaily);
        },
      ),
    );
  }

  Widget _buildMissionCard(Map<String, dynamic> mission, int index, bool isDaily) {
    final isCompleted = mission['isCompleted'] == true;
    final isClaimed = mission['claimedAt'] != null;
    final progress = mission['progress'] ?? 0;
    final target = mission['target'];
    final progressPercent = target != null && target > 0
        ? (progress / target).clamp(0.0, 1.0)
        : (isCompleted ? 1.0 : 0.0);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? (isClaimed ? Colors.grey[300]! : Colors.green[300]!)
              : Colors.grey[200]!,
          width: isCompleted && !isClaimed ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isCompleted && !isClaimed
              ? () => _claimReward(mission)
              : null,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green[50]
                            : Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          mission['icon'] ?? '🎯',
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mission['name'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: isClaimed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isClaimed
                                  ? Colors.grey[400]
                                  : Colors.black,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            mission['description'],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? (isClaimed ? Colors.grey[100] : Colors.green[100])
                                : Colors.orange[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isClaimed
                                ? '받음'
                                : (isCompleted ? '완료!' : '${mission['points']}P'),
                            style: TextStyle(
                              color: isClaimed
                                  ? Colors.grey[600]
                                  : (isCompleted ? Colors.green[700] : Colors.orange[700]),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!isCompleted && target != null)
                          Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              '$progress/$target',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (target != null && !isClaimed)
                  Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          value: progressPercent,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCompleted ? Colors.green : Colors.blue,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${(progressPercent * 100).toStringAsFixed(0)}% 완료',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isCompleted && !isClaimed)
                  Container(
                    margin: EdgeInsets.only(top: 12),
                    padding: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '보상 받기',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate()
        .fadeIn(delay: Duration(milliseconds: index * 100))
        .slideX(begin: 0.2, end: 0);
  }

  Future<void> _claimReward(Map<String, dynamic> mission) async {
    final success = await _missionService.claimReward(mission['id']);

    if (success) {
      // 애니메이션과 함께 성공 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('${mission['points']}P 획득!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // 애널리틱스 로깅
      await AnalyticsService.logEvent(
        name: 'mission_reward_claimed',
        parameters: {
          'mission_name': mission['name'],
          'points': mission['points'],
        },
      );

      // 미션 목록 새로고침
      await _loadMissions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('보상을 받을 수 없습니다'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRewards() {
    final claimableMissions = [
      ..._dailyMissions.where((m) =>
        m['isCompleted'] == true && m['claimedAt'] == null
      ),
      ..._weeklyMissions.where((m) =>
        m['isCompleted'] == true && m['claimedAt'] == null
      ),
    ];

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '받을 수 있는 보상',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            if (claimableMissions.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  '받을 수 있는 보상이 없습니다',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            else
              ...claimableMissions.map((mission) => ListTile(
                leading: Text(
                  mission['icon'] ?? '🎁',
                  style: TextStyle(fontSize: 24),
                ),
                title: Text(mission['name']),
                trailing: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _claimReward(mission);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: Text('${mission['points']}P'),
                ),
              )),
            SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('닫기'),
            ),
          ],
        ),
      ),
    );
  }

  int _getStreak() {
    // TODO: 실제 연속 미션 일수 가져오기
    return 3;
  }
}