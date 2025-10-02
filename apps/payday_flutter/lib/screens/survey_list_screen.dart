import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/survey_service.dart';
import '../services/cash_service.dart';
import '../services/analytics_service.dart';
import 'package:intl/intl.dart';

class SurveyListScreen extends StatefulWidget {
  const SurveyListScreen({Key? key}) : super(key: key);

  @override
  State<SurveyListScreen> createState() => _SurveyListScreenState();
}

class _SurveyListScreenState extends State<SurveyListScreen>
    with SingleTickerProviderStateMixin {
  final SurveyService _surveyService = SurveyService();
  final CashService _cashService = CashService();
  final NumberFormat _numberFormat = NumberFormat('#,###', 'ko_KR');

  late TabController _tabController;
  List<Map<String, dynamic>> _surveys = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = false;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 설문 목록 로드
      final surveys = await _surveyService.getAvailableSurveys();
      final stats = await _surveyService.getStatistics();

      setState(() {
        _surveys = surveys;
        _statistics = stats;
      });
    } catch (e) {
      print('설문 데이터 로드 실패: $e');
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
          _buildCategories(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSurveyList('available'),
                _buildSurveyList('recommended'),
                _buildCompletedList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text('설문조사'),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(Icons.info_outline),
          onPressed: _showInfoDialog,
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[400]!, Colors.purple[600]!],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                '오늘 완료',
                '${_statistics['todayCompleted'] ?? 0}개',
                Icons.check_circle,
              ),
              _buildStatCard(
                '총 획득',
                '${_numberFormat.format(_statistics['totalPoints'] ?? 0)}P',
                Icons.monetization_on,
              ),
              _buildStatCard(
                '가능한 설문',
                '${_surveys.length}개',
                Icons.assignment,
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  '일일 한도: ${_statistics['todayCompleted'] ?? 0}/10',
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
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    final categories = [
      {'id': 'all', 'name': '전체', 'icon': Icons.apps},
      {'id': 'lifestyle', 'name': '라이프', 'icon': Icons.favorite},
      {'id': 'shopping', 'name': '쇼핑', 'icon': Icons.shopping_cart},
      {'id': 'tech', 'name': 'IT/기술', 'icon': Icons.computer},
      {'id': 'food', 'name': '음식', 'icon': Icons.restaurant},
    ];

    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category['id'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category['id'] as String;
              });
              _filterSurveys();
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.purple : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? Colors.purple : Colors.grey[300]!,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    category['icon'] as IconData,
                    color: isSelected ? Colors.white : Colors.grey[600],
                    size: 20,
                  ),
                  SizedBox(height: 4),
                  Text(
                    category['name'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ).animate().scale(
              duration: 200.ms,
              begin: Offset(1, 1),
              end: isSelected ? Offset(1.05, 1.05) : Offset(1, 1),
            ),
          );
        },
      ),
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
        labelColor: Colors.purple,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Colors.purple,
        tabs: [
          Tab(text: '전체 설문'),
          Tab(text: '추천 설문'),
          Tab(text: '완료 내역'),
        ],
      ),
    );
  }

  Widget _buildSurveyList(String type) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    List<Map<String, dynamic>> displaySurveys = [];

    if (type == 'recommended') {
      // 포인트 높은 순으로 정렬
      displaySurveys = List.from(_surveys)
        ..sort((a, b) => b['avgReward'].compareTo(a['avgReward']));
      displaySurveys = displaySurveys.take(5).toList();
    } else {
      displaySurveys = _surveys;
    }

    if (displaySurveys.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: displaySurveys.length,
        itemBuilder: (context, index) {
          final survey = displaySurveys[index];
          return _buildSurveyCard(survey, index);
        },
      ),
    );
  }

  Widget _buildSurveyCard(Map<String, dynamic> survey, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _startSurvey(survey),
        borderRadius: BorderRadius.circular(16),
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
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        survey['logo'] ?? '📋',
                        style: TextStyle(fontSize: 24),
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
                              survey['name'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            if (survey['isNew'] == true)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'NEW',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (survey['isHot'] == true)
                              Container(
                                margin: EdgeInsets.only(left: 4),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'HOT',
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          survey['description'] ?? '설문조사 참여하기',
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
                      Text(
                        '${_numberFormat.format(survey['avgReward'])}P',
                        style: TextStyle(
                          color: Colors.purple,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        survey['timeRequired'] ?? '5-10분',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.timer,
                    survey['timeRequired'] ?? '5-10분',
                  ),
                  SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.help_outline,
                    '${survey['questions'] ?? 10}문항',
                  ),
                  SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.people,
                    '${survey['completionRate'] ?? 85}% 완료율',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate()
        .fadeIn(delay: Duration(milliseconds: index * 100))
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedList() {
    // 완료된 설문 내역 (임시 데이터)
    final completedSurveys = [
      {
        'name': '쇼핑 습관 조사',
        'platform': '패널파워',
        'points': 500,
        'completedAt': '2024-10-01 14:30',
      },
      {
        'name': '모바일 앱 사용 패턴',
        'platform': '엠브레인',
        'points': 800,
        'completedAt': '2024-10-01 10:15',
      },
    ];

    if (completedSurveys.isEmpty) {
      return _buildEmptyState(completed: true);
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: completedSurveys.length,
      itemBuilder: (context, index) {
        final survey = completedSurveys[index];
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 32,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      survey['name'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${survey['platform']} • ${survey['completedAt']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '+${survey['points']}P',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({bool completed = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            completed ? Icons.assignment_turned_in : Icons.assignment_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16),
          Text(
            completed ? '완료한 설문이 없습니다' : '참여 가능한 설문이 없습니다',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            completed ? '설문에 참여하고 포인트를 받아보세요!' : '잠시 후 다시 확인해주세요',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _filterSurveys() async {
    // 카테고리별 필터링 로직
    await _loadData();
  }

  Future<void> _startSurvey(Map<String, dynamic> survey) async {
    // 설문 시작 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('설문 참여'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${survey['name']}에 참여하시겠습니까?'),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.monetization_on, size: 16, color: Colors.purple),
                SizedBox(width: 8),
                Text('예상 보상: ${survey['avgReward']}P'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Text('소요 시간: ${survey['timeRequired']}'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: Text('참여하기'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 설문 URL로 이동 또는 내장 설문 화면으로 이동
      await _surveyService.connectPlatform(survey['id']);

      // 애널리틱스 로깅
      await AnalyticsService.logEvent(
        name: 'survey_started',
        parameters: {
          'platform': survey['id'],
          'expected_reward': survey['avgReward'],
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${survey['name']} 설문이 시작됩니다'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('설문조사 안내'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• 설문 완료 시 포인트가 자동 지급됩니다'),
            SizedBox(height: 8),
            Text('• 일일 최대 10개까지 참여 가능합니다'),
            SizedBox(height: 8),
            Text('• 설문 중도 포기 시 포인트가 지급되지 않습니다'),
            SizedBox(height: 8),
            Text('• 성실한 답변을 부탁드립니다'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }
}