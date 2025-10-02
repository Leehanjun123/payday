import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/income_source.dart';
import '../services/income_data_service.dart';
import 'side_income/youtube_detail_screen.dart';
import 'side_income/freelance_detail_screen.dart';

class ComprehensiveHome extends StatefulWidget {
  const ComprehensiveHome({Key? key}) : super(key: key);

  @override
  State<ComprehensiveHome> createState() => _ComprehensiveHomeState();
}

class _ComprehensiveHomeState extends State<ComprehensiveHome>
    with TickerProviderStateMixin {
  final IncomeDataService _incomeService = IncomeDataService();
  late TabController _tabController;

  List<IncomeSource> _allIncomeSources = [];
  List<IncomeSource> _inAppSources = [];
  List<IncomeSource> _externalSources = [];
  List<DailyMission> _dailyMissions = [];

  double _totalMonthlyIncome = 0;
  double _todayIncome = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final allSources = await _incomeService.getAllIncomeSources();
      final missions = await _incomeService.getDailyMissions();

      setState(() {
        _allIncomeSources = allSources;
        _inAppSources = allSources
            .where((s) => s.category == IncomeCategory.inApp)
            .toList();
        _externalSources = allSources
            .where((s) => s.category == IncomeCategory.external)
            .toList();
        _dailyMissions = missions;

        _totalMonthlyIncome = allSources
            .fold(0, (sum, source) => sum + source.monthlyIncome);
        _todayIncome = allSources
            .fold(0, (sum, source) => sum + source.todayIncome);

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('데이터 로드 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildIncomeOverview(),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAllSourcesList(),
                        _buildInAppSourcesList(),
                        _buildExternalSourcesList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '💰 PayDay',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '모든 수익을 한 곳에서',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeOverview() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 달 총 수익',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₩${_formatNumber(_totalMonthlyIncome.round())}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIncomeInfo('오늘 수익', '₩${_formatNumber(_todayIncome.round())}'),
              _buildIncomeInfo('활성 수익원', '${_allIncomeSources.where((s) => s.isActive).length}개'),
              _buildIncomeInfo('전월 대비', '+23.5%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF667eea),
        labelColor: const Color(0xFF667eea),
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(text: '전체'),
          Tab(text: '앱 내 수익'),
          Tab(text: '외부 플랫폼'),
        ],
      ),
    );
  }

  Widget _buildAllSourcesList() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 일일 미션 섹션
        if (_dailyMissions.isNotEmpty) ...[
          _buildSectionTitle('📅 오늘의 미션', '완료하고 보너스 받기'),
          ..._dailyMissions.map((mission) => _buildMissionCard(mission)),
          const SizedBox(height: 20),
        ],

        // 앱 내 수익
        _buildSectionTitle('📱 앱 내 수익', '바로 시작 가능'),
        ..._inAppSources.map((source) => _buildIncomeCard(source)),

        const SizedBox(height: 20),

        // 외부 플랫폼
        _buildSectionTitle('🌐 외부 플랫폼', '연동하여 관리'),
        ..._externalSources.map((source) => _buildIncomeCard(source)),
      ],
    );
  }

  Widget _buildInAppSourcesList() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 일일 미션
        if (_dailyMissions.isNotEmpty) ...[
          _buildSectionTitle('📅 오늘의 미션', '완료하고 보너스 받기'),
          ..._dailyMissions.map((mission) => _buildMissionCard(mission)),
          const SizedBox(height: 20),
        ],

        // 즉시 시작 가능
        _buildSectionTitle('🚀 즉시 시작 가능', '지금 바로 수익 창출'),
        ..._inAppSources.map((source) => _buildIncomeCard(source)),
      ],
    );
  }

  Widget _buildExternalSourcesList() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionTitle('🔗 플랫폼 연동', '외부 수익 통합 관리'),
        ..._externalSources.map((source) => _buildIncomeCard(source)),
      ],
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeCard(IncomeSource source) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _navigateToDetail(source);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getTypeColor(source.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  source.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        source.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!source.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '비활성',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    source.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '월 ₩${_formatNumber(source.monthlyIncome.round())}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _getTypeColor(source.type),
                        ),
                      ),
                      Row(
                        children: [
                          if (source.todayIncome > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '+₩${_formatNumber(source.todayIncome.round())}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          _buildChangeIndicator(source.changePercent),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionCard(DailyMission mission) {
    final progressPercent = mission.progress / mission.target;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: mission.isCompleted ? Colors.green[50] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: mission.isCompleted ? Colors.green : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        decoration: mission.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
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
                  color: mission.isCompleted
                      ? Colors.green
                      : Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  mission.isCompleted
                      ? '완료 ✓'
                      : '+${mission.reward}원',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: mission.isCompleted
                        ? Colors.white
                        : Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),
          if (!mission.isCompleted) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progressPercent,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.orange[400]!,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${mission.progress}/${mission.target}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChangeIndicator(double percent) {
    final isPositive = percent > 0;
    final color = isPositive ? Colors.green : Colors.red;

    return Row(
      children: [
        Icon(
          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
          size: 12,
          color: color,
        ),
        Text(
          '${percent.abs().toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getTypeColor(IncomeType type) {
    switch (type) {
      case IncomeType.rewardAd:
        return Colors.purple;
      case IncomeType.dailyMission:
        return Colors.orange;
      case IncomeType.referral:
        return Colors.blue;
      case IncomeType.youtube:
        return Colors.red;
      case IncomeType.blog:
        return Colors.green;
      case IncomeType.freelance:
        return Colors.indigo;
      case IncomeType.stock:
        return Colors.teal;
      case IncomeType.crypto:
        return Colors.amber;
      case IncomeType.realestate:
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  void _navigateToDetail(IncomeSource source) {
    if (source.type == IncomeType.youtube) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const YouTubeDetailScreen(),
        ),
      );
    } else if (source.type == IncomeType.freelance) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const FreelanceDetailScreen(),
        ),
      );
    }
    // TODO: 다른 상세 화면들 추가
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
    super.dispose();
  }
}