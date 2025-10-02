import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/real_income_service.dart';
import '../services/data_service.dart';
import 'package:url_launcher/url_launcher.dart';

class RealIncomeHubScreen extends StatefulWidget {
  @override
  _RealIncomeHubScreenState createState() => _RealIncomeHubScreenState();
}

class _RealIncomeHubScreenState extends State<RealIncomeHubScreen>
    with TickerProviderStateMixin {
  final RealIncomeService _incomeService = RealIncomeService();
  final DataService _dataService = DataService();

  late TabController _tabController;
  String _selectedCategory = '전체';

  final List<String> _categories = [
    '전체',
    '걷기/건강',
    '제휴마케팅',
    '프리랜서',
    '설문조사',
    '콘텐츠',
    '배달',
    '투자',
  ];

  double _todayEarnings = 0;
  double _totalEarnings = 0;
  Map<String, dynamic> _dailyMissions = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _incomeService.initialize();
    await _loadEarnings();
    await _loadMissions();
    setState(() {});
  }

  Future<void> _loadEarnings() async {
    setState(() {
      _todayEarnings = _incomeService.getTodayTotalEarnings();
      _totalEarnings = _incomeService.getTotalEarnings();
    });
  }

  Future<void> _loadMissions() async {
    _dailyMissions = await _incomeService.getDailyMissions();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildEarningsSummary(),
            _buildDailyMissions(),
            _buildCategoryTabs(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _categories.map((category) {
                  return _buildPlatformGrid(category);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '실제 부수익 통합 관리',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '2024년 12월 최신 부수익 플랫폼',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: _showSettings,
                icon: Icon(Icons.settings),
                color: Colors.grey[700],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsSummary() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildEarningItem(
            '오늘 수익',
            '₩${_todayEarnings.toStringAsFixed(0)}',
            Icons.today,
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.white30,
          ),
          _buildEarningItem(
            '총 누적',
            '₩${_totalEarnings.toStringAsFixed(0)}',
            Icons.account_balance_wallet,
          ),
        ],
      ),
    );
  }

  Widget _buildEarningItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyMissions() {
    if (_dailyMissions.isEmpty) return SizedBox.shrink();

    return Container(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20),
        children: _dailyMissions.entries.map((entry) {
          final mission = entry.value as Map<String, dynamic>;
          final progress = (mission['current'] / mission['target']).clamp(0.0, 1.0);

          return Container(
            width: 150,
            margin: EdgeInsets.only(right: 12),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission['title'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress.toDouble(),
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1 ? Colors.green : Colors.blue,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${mission['current']}/${mission['target']}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                    Text(
                      '+${mission['reward']}원',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.blue,
        tabs: _categories.map((category) {
          return Tab(text: category);
        }).toList(),
      ),
    );
  }

  Widget _buildPlatformGrid(String category) {
    final platforms = category == '전체'
        ? RealIncomeService.INCOME_PLATFORMS.entries
            .map((e) => {'id': e.key, ...e.value})
            .toList()
        : _incomeService.getPlatformsByCategory(category);

    if (platforms.isEmpty) {
      return Center(
        child: Text(
          '해당 카테고리에 플랫폼이 없습니다.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: platforms.length,
      itemBuilder: (context, index) {
        final platform = platforms[index];
        final isConnected = platform['connected'] ?? false;

        return GestureDetector(
          onTap: () => _handlePlatformTap(platform),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isConnected ? Colors.green : Colors.grey[300]!,
                width: isConnected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        platform['icon'] ?? '💰',
                        style: TextStyle(fontSize: 32),
                      ),
                      SizedBox(height: 12),
                      Text(
                        platform['name'] ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        platform['earning_rate'] ?? '',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isConnected) ...[
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '연결됨',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (platform['max_daily'] != null && platform['max_daily'] > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '일 ${platform['max_daily']}원',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handlePlatformTap(Map<String, dynamic> platform) async {
    final platformId = platform['id'];
    final isConnected = platform['connected'] ?? false;

    if (isConnected) {
      // 수익 입력 다이얼로그
      await _showEarningsDialog(platform);
    } else {
      // 플랫폼 연결 다이얼로그
      await _showConnectDialog(platform);
    }
  }

  Future<void> _showConnectDialog(Map<String, dynamic> platform) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${platform['name']} 연결'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(platform['description'] ?? ''),
            SizedBox(height: 16),
            Text('예상 수익: ${platform['earning_rate']}'),
            if (platform['url'] != null) ...[
              SizedBox(height: 16),
              Text(
                '앱을 설치하고 연결하시겠습니까?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('연결하기'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _incomeService.connectPlatform(platform['id']);
      await _initializeService();
    }
  }

  Future<void> _showEarningsDialog(Map<String, dynamic> platform) async {
    final controller = TextEditingController();

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${platform['name']} 수익 입력'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '오늘 수익 (원)',
                prefixText: '₩',
                border: OutlineInputBorder(),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            SizedBox(height: 16),
            Text(
              '예상 수익: ${platform['earning_rate']}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              Navigator.pop(context, amount);
            },
            child: Text('저장'),
          ),
        ],
      ),
    );

    if (result != null && result > 0) {
      await _incomeService.updatePlatformEarnings(platform['id'], result);
      await _loadEarnings();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('₩${result.toStringAsFixed(0)} 수익이 추가되었습니다'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlatformSettingsScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// 설정 화면
class PlatformSettingsScreen extends StatelessWidget {
  final RealIncomeService _incomeService = RealIncomeService();

  @override
  Widget build(BuildContext context) {
    final connectedPlatforms = _incomeService.getConnectedPlatforms();

    return Scaffold(
      appBar: AppBar(
        title: Text('플랫폼 관리'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          Text(
            '연결된 플랫폼',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          if (connectedPlatforms.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  '연결된 플랫폼이 없습니다',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...connectedPlatforms.map((platform) {
              return ListTile(
                leading: Text(
                  platform['icon'] ?? '💰',
                  style: TextStyle(fontSize: 24),
                ),
                title: Text(platform['name'] ?? ''),
                subtitle: Text(
                  '총 수익: ₩${platform['data']?['total_earnings']?.toStringAsFixed(0) ?? '0'}',
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    await _incomeService.disconnectPlatform(platform['id']);
                    Navigator.pop(context);
                  },
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}