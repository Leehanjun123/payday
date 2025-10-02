import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'earn_money_screen.dart';
import 'real_income_hub_screen.dart';
import '../services/survey_service.dart';
import '../services/data_service.dart';

class EarnHubScreen extends StatefulWidget {
  const EarnHubScreen({Key? key}) : super(key: key);

  @override
  State<EarnHubScreen> createState() => _EarnHubScreenState();
}

class _EarnHubScreenState extends State<EarnHubScreen> with SingleTickerProviderStateMixin {
  final SurveyService _surveyService = SurveyService();
  final DataService _dataService = DataService();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  Map<String, dynamic> _todayStats = {
    'totalEarnings': 0.0,
    'adsWatched': 0,
    'surveysCompleted': 0,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final statistics = await _dataService.getStatistics();
      setState(() {
        _todayStats = {
          'totalEarnings': statistics['todayEarnings'] ?? 0.0,
          'adsWatched': statistics['adsWatched'] ?? 0,
          'surveysCompleted': statistics['surveysCompleted'] ?? 0,
        };
      });
    } catch (e) {
      print('Failed to load stats: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadStats,
            child: CustomScrollView(
              slivers: [
                // 헤더
                SliverAppBar(
                  floating: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: const Text(
                    '💰 수익 창출',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),

                // 오늘의 수익 카드
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: _buildTodayEarningsCard(),
                  ),
                ),

                // 주요 수익 방법 그리드
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '💵 수익 창출 방법',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEarningMethodsGrid(),
                      ],
                    ),
                  ),
                ),

                // 추천 설문조사
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📋 추천 설문조사',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSurveyList(),
                      ],
                    ),
                  ),
                ),

                const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayEarningsCard() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade600, Colors.purple.shade600],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
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
                  '오늘의 수익',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.trending_up, color: Colors.greenAccent, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '+15%',
                        style: TextStyle(
                          color: Colors.greenAccent,
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
              '${_todayStats['totalEarnings'].toStringAsFixed(0)}원',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('광고 시청', '${_todayStats['adsWatched']}회', Icons.play_circle),
                _buildStatItem('설문 완료', '${_todayStats['surveysCompleted']}개', Icons.assignment),
                _buildStatItem('일일 목표', '70%', Icons.flag),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEarningMethodsGrid() {
    final methods = [
      {
        'title': '광고 시청',
        'subtitle': '50~100원/건',
        'icon': Icons.play_circle_filled,
        'color': Colors.red,
        'available': true,
        'onTap': () => _navigateToEarnMoney(),
      },
      {
        'title': '설문조사',
        'subtitle': '500~5,000원/건',
        'icon': Icons.assignment,
        'color': Colors.blue,
        'available': true,
        'onTap': () => _showSurveyPlatforms(),
      },
      {
        'title': '일일 미션',
        'subtitle': '1,000원/일',
        'icon': Icons.task_alt,
        'color': Colors.green,
        'available': true,
        'onTap': () => _showDailyMissions(),
      },
      {
        'title': '친구 초대',
        'subtitle': '2,000원/명',
        'icon': Icons.people,
        'color': Colors.orange,
        'available': true,
        'onTap': () => _showReferralInfo(),
      },
      {
        'title': '게임 플레이',
        'subtitle': '100~500원/판',
        'icon': Icons.sports_esports,
        'color': Colors.purple,
        'available': false,
        'onTap': () => _showComingSoon(),
      },
      {
        'title': '걷기 리워드',
        'subtitle': '10원/100걸음',
        'icon': Icons.directions_walk,
        'color': Colors.teal,
        'available': false,
        'onTap': () => _showComingSoon(),
      },
      {
        'title': '실제 부수익',
        'subtitle': '19개 플랫폼 통합',
        'icon': Icons.attach_money,
        'color': Colors.green,
        'available': true,
        'onTap': () => _navigateToRealIncome(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: methods.length,
      itemBuilder: (context, index) {
        final method = methods[index];
        return _buildMethodCard(method);
      },
    );
  }

  Widget _buildMethodCard(Map<String, dynamic> method) {
    final bool available = method['available'];

    return GestureDetector(
      onTap: available ? method['onTap'] : () => _showComingSoon(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: available ? Colors.grey.shade200 : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: available
              ? [
                  BoxShadow(
                    color: (method['color'] as Color).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (method['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    method['icon'] as IconData,
                    color: available
                        ? method['color'] as Color
                        : Colors.grey.shade400,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Text(
                  method['title'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: available ? Colors.black87 : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  method['subtitle'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: available
                        ? (method['color'] as Color).withOpacity(0.8)
                        : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
            if (!available)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'SOON',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurveyList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _surveyService.getActiveSurveys(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final surveys = snapshot.data!.take(3).toList();

        return Column(
          children: surveys.map((survey) => _buildSurveyCard(survey)).toList(),
        );
      },
    );
  }

  Widget _buildSurveyCard(Map<String, dynamic> survey) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                survey['platformLogo'],
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  survey['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${survey['timeRequired']}분',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.people, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      survey['targetGender'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${survey['reward']}원',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              ElevatedButton(
                onPressed: () async {
                  final result = await _surveyService.startSurvey(survey['id']);
                  if (result['success'] == true) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message'] ?? '설문조사 페이지로 이동합니다'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message'] ?? '설문조사를 시작할 수 없습니다'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '시작',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToEarnMoney() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EarnMoneyScreen()),
    );
  }

  void _showSurveyPlatforms() {
    HapticFeedback.lightImpact();
    final platforms = _surveyService.getSurveyPlatforms();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            const Text(
              '설문조사 플랫폼',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...platforms.map((platform) => ListTile(
              leading: Text(platform['logo'], style: const TextStyle(fontSize: 24)),
              title: Text(platform['name']),
              subtitle: Text('최소 출금: ${platform['minPayout']}원'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _surveyService.startSurvey(platform['id']),
            )).toList(),
          ],
        ),
        ),
      ),
    );
  }

  void _showDailyMissions() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일일 미션'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMissionItem('광고 5개 시청', '200원', true),
            _buildMissionItem('설문조사 3개 완료', '500원', false),
            _buildMissionItem('친구 1명 초대', '300원', false),
            _buildMissionItem('앱 5일 연속 접속', '1000원', true),
          ],
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

  Widget _buildMissionItem(String mission, String reward, bool completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.circle_outlined,
            color: completed ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mission,
              style: TextStyle(
                decoration: completed ? TextDecoration.lineThrough : null,
                color: completed ? Colors.grey : Colors.black,
              ),
            ),
          ),
          Text(
            reward,
            style: TextStyle(
              color: completed ? Colors.grey : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showReferralInfo() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('친구 초대'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('친구를 초대하고 보상을 받으세요!'),
            SizedBox(height: 16),
            Text('• 친구가 가입 시: 1,000원'),
            Text('• 친구가 첫 미션 완료 시: 500원'),
            Text('• 친구가 첫 출금 시: 500원'),
            SizedBox(height: 16),
            Text('초대 코드: PAYDAY2024'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // 공유 기능
            },
            child: const Text('공유하기'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('곧 출시 예정입니다!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToRealIncome() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RealIncomeHubScreen()),
    );
  }
}