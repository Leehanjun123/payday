import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import '../services/pedometer_service.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';

class WalkingRewardScreen extends StatefulWidget {
  @override
  _WalkingRewardScreenState createState() => _WalkingRewardScreenState();
}

class _WalkingRewardScreenState extends State<WalkingRewardScreen>
    with TickerProviderStateMixin {
  final PedometerService _pedometerService = PedometerService();

  late AnimationController _walkingAnimController;
  late AnimationController _coinAnimController;
  late Animation<double> _walkingAnimation;
  late Animation<double> _coinAnimation;

  Timer? _updateTimer;
  Map<String, dynamic> _todayProgress = {};
  Map<String, dynamic> _weeklyStats = {};

  @override
  void initState() {
    super.initState();

    // 애니메이션 설정
    _walkingAnimController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat();

    _coinAnimController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _walkingAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_walkingAnimController);

    _coinAnimation = Tween<double>(
      begin: 1,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _coinAnimController,
      curve: Curves.elasticOut,
    ));

    _initializeService();
  }

  Future<void> _initializeService() async {
    final success = await _pedometerService.initialize();

    if (success) {
      _loadData();

      // 1초마다 업데이트
      _updateTimer = Timer.periodic(Duration(seconds: 1), (_) {
        _loadData();
      });
    } else {
      _showPermissionDialog();
    }
  }

  void _loadData() {
    setState(() {
      _todayProgress = _pedometerService.getTodayProgress();
    });

    _loadWeeklyStats();

    // 걷는 중이면 애니메이션
    if (_todayProgress['isWalking'] == true) {
      _walkingAnimController.repeat();
    } else {
      _walkingAnimController.stop();
    }
  }

  Future<void> _loadWeeklyStats() async {
    final stats = await _pedometerService.getWeeklyStats();
    setState(() {
      _weeklyStats = stats;
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
              Color(0xFF667EEA),
              Color(0xFF764BA2),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                _buildMainCounter(),
                _buildMilestones(),
                _buildWeeklyChart(),
                _buildTips(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '오늘의 걷기',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Text(
                '${DateTime.now().month}월 ${DateTime.now().day}일',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.monetization_on, color: Colors.yellow, size: 20),
                SizedBox(width: 8),
                Text(
                  '${_todayProgress['coins'] ?? 0}',
                  style: TextStyle(
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
    );
  }

  Widget _buildMainCounter() {
    final steps = _todayProgress['steps'] ?? 0;
    final progress = _todayProgress['progress'] ?? 0.0;
    final isWalking = _todayProgress['isWalking'] ?? false;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 30),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 배경 원
          CircularPercentIndicator(
            radius: 120.0,
            lineWidth: 15.0,
            animation: true,
            percent: progress,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _walkingAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: isWalking ? _walkingAnimation.value * 0.1 : 0,
                      child: Icon(
                        Icons.directions_walk,
                        size: 40,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
                SizedBox(height: 10),
                Text(
                  '$steps',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '걸음',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: Colors.white.withOpacity(0.2),
            progressColor: Colors.yellow,
          ),

          // 걷기 상태 표시
          if (isWalking)
            Positioned(
              bottom: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '걷는 중',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMilestones() {
    final steps = _todayProgress['steps'] ?? 0;

    final milestones = [
      {'steps': 1000, 'coins': 5, 'achieved': steps >= 1000},
      {'steps': 3000, 'coins': 10, 'achieved': steps >= 3000},
      {'steps': 5000, 'coins': 15, 'achieved': steps >= 5000},
      {'steps': 10000, 'coins': 30, 'achieved': steps >= 10000},
    ];

    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '오늘의 도전',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          ...milestones.map((milestone) {
            final achieved = milestone['achieved'] as bool;
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: achieved
                    ? Colors.green.withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: achieved ? Colors.green : Colors.white30,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    achieved ? Icons.check_circle : Icons.circle_outlined,
                    color: achieved ? Colors.green : Colors.white54,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${milestone['steps']}보 달성',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: achieved ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: achieved
                          ? Colors.yellow.withOpacity(0.3)
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '+${milestone['coins']}',
                      style: TextStyle(
                        color: achieved ? Colors.yellow : Colors.white54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    if (_weeklyStats.isEmpty || _weeklyStats['data'] == null) {
      return SizedBox.shrink();
    }

    final weekData = _weeklyStats['data'] as List;

    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '주간 기록',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.all(16),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 10000,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final days = ['월', '화', '수', '목', '금', '토', '일'];
                        return Text(
                          days[value.toInt() % 7],
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(weekData.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: (weekData[i]['steps'] as int).toDouble(),
                        color: Colors.yellow,
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '총 걸음',
                '${_weeklyStats['totalSteps'] ?? 0}',
                Icons.directions_walk,
              ),
              _buildStatItem(
                '총 코인',
                '${_weeklyStats['totalCoins'] ?? 0}',
                Icons.monetization_on,
              ),
              _buildStatItem(
                '일 평균',
                '${_weeklyStats['avgSteps'] ?? 0}',
                Icons.trending_up,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTips() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.yellow),
              SizedBox(width: 8),
              Text(
                '걷기 팁',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '• 하루 10,000보를 목표로 걸어보세요\n'
            '• 엘리베이터 대신 계단을 이용해보세요\n'
            '• 점심시간에 짧은 산책을 즐겨보세요\n'
            '• 대중교통 한 정거장 전에 내려 걸어보세요',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('권한 필요'),
        content: Text('걸음 수를 측정하려면 활동 권한이 필요합니다.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeService();
            },
            child: Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _walkingAnimController.dispose();
    _coinAnimController.dispose();
    super.dispose();
  }
}