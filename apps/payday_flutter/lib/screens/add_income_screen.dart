import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/income_source.dart';
import '../services/income_data_service.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({Key? key}) : super(key: key);

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final IncomeDataService _incomeService = IncomeDataService();

  List<IncomeSource> inAppSources = [];
  List<IncomeSource> externalSources = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadIncomeSources();
  }

  Future<void> _loadIncomeSources() async {
    final sources = await _incomeService.getAllIncomeSources();
    setState(() {
      inAppSources = sources
          .where((s) => s.category == IncomeCategory.inApp)
          .toList();
      externalSources = sources
          .where((s) => s.category == IncomeCategory.external)
          .toList();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E3A5F),
              Color(0xFF2E5A7F),
              Color(0xFF1E3A5F),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with Search
              Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '수익원 추가',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.add_circle,
                                color: Colors.green,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '빠른 추가',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value.toLowerCase();
                          });
                        },
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '수익원 검색...',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Bar
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.lightBlue],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone_android, size: 18),
                          SizedBox(width: 8),
                          Text('인앱 수익'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.public, size: 18),
                          SizedBox(width: 8),
                          Text('외부 수익'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildIncomeList(inAppSources),
                    _buildIncomeList(externalSources),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeList(List<IncomeSource> sources) {
    final filteredSources = sources.where((source) {
      if (searchQuery.isEmpty) return true;
      return source.name.toLowerCase().contains(searchQuery) ||
          source.description.toLowerCase().contains(searchQuery);
    }).toList();

    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: filteredSources.length,
      itemBuilder: (context, index) {
        final source = filteredSources[index];
        return _buildIncomeCard(source);
      },
    );
  }

  Widget _buildIncomeCard(IncomeSource source) {
    final bool isActive = source.isActive;
    final IconData iconData = _getIconForType(source.type);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isActive
              ? [
                  Colors.green.withOpacity(0.2),
                  Colors.green.withOpacity(0.1),
                ]
              : [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? Colors.green.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            _showAddSourceDialog(source);
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.withOpacity(0.2)
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        iconData,
                        color: isActive ? Colors.green : Colors.white70,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 16),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                source.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isActive)
                                Container(
                                  margin: EdgeInsets.only(left: 8),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '활성',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            source.description,
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStat(
                      '예상 수익',
                      '\$${source.estimatedEarning}/월',
                      Colors.blue,
                    ),
                    _buildStat(
                      '난이도',
                      source.difficulty,
                      _getDifficultyColor(source.difficulty),
                    ),
                    _buildStat(
                      '소요 시간',
                      '${source.timeRequired}분/일',
                      Colors.orange,
                    ),
                  ],
                ),

                if (!isActive)
                  Container(
                    margin: EdgeInsets.only(top: 16),
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _showAddSourceDialog(source);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '+ 추가하기',
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
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  IconData _getIconForType(IncomeType type) {
    switch (type) {
      case IncomeType.rewardAd:
        return Icons.play_circle_outline;
      case IncomeType.survey:
        return Icons.quiz;
      case IncomeType.dailyBonus:
        return Icons.card_giftcard;
      case IncomeType.walkingReward:
        return Icons.directions_walk;
      case IncomeType.youtube:
        return Icons.video_library;
      case IncomeType.blog:
        return Icons.article;
      case IncomeType.affiliate:
        return Icons.link;
      case IncomeType.freelance:
        return Icons.work;
      case IncomeType.tutoring:
        return Icons.school;
      case IncomeType.stock:
        return Icons.trending_up;
      case IncomeType.crypto:
        return Icons.currency_bitcoin;
      case IncomeType.realEstate:
        return Icons.home_work;
      case IncomeType.p2p:
        return Icons.handshake;
      case IncomeType.crowdFunding:
        return Icons.people_outline;
      case IncomeType.dividends:
        return Icons.account_balance;
      case IncomeType.bonds:
        return Icons.security;
      case IncomeType.savings:
        return Icons.savings;
      case IncomeType.reselling:
        return Icons.shopping_cart;
      case IncomeType.nft:
        return Icons.token;
      case IncomeType.dailyMission:
        return Icons.task_alt;
      case IncomeType.referral:
        return Icons.group_add;
      case IncomeType.quiz:
        return Icons.quiz;
      case IncomeType.walking:
        return Icons.directions_walk;
      case IncomeType.game:
        return Icons.sports_esports;
      case IncomeType.review:
        return Icons.rate_review;
      case IncomeType.tiktok:
        return Icons.music_note;
      case IncomeType.instagram:
        return Icons.camera_alt;
      case IncomeType.realestate:
        return Icons.home_work;
      case IncomeType.delivery:
        return Icons.delivery_dining;
      case IncomeType.ecommerce:
        return Icons.storefront;
      case IncomeType.education:
        return Icons.school;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case '쉬움':
        return Colors.green;
      case '보통':
        return Colors.yellow;
      case '어려움':
        return Colors.orange;
      case '매우 어려움':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showAddSourceDialog(IncomeSource source) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2E3A4F),
              Color(0xFF1E2A3F),
            ],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 5,
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue, Colors.lightBlue],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            _getIconForType(source.type),
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                source.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                source.category == IncomeCategory.inApp
                                    ? '인앱 수익원'
                                    : '외부 수익원',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24),

                    // Description
                    Text(
                      '설명',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      source.description,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: 24),

                    // Requirements
                    Text(
                      '필요 조건',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    ...source.requirements.map((req) => Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              req,
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),

                    SizedBox(height: 24),

                    // Stats Grid
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildDetailStat(
                                '예상 월 수익',
                                '\$${source.estimatedEarning}',
                                '약 ${(source.estimatedEarning * 1300).toStringAsFixed(0)}원',
                                Colors.green,
                              ),
                              _buildDetailStat(
                                '필요 시간',
                                '${source.timeRequired}분',
                                '하루 평균',
                                Colors.blue,
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildDetailStat(
                                '난이도',
                                source.difficulty,
                                '초보자 ${source.difficulty == "쉬움" ? "추천" : "주의"}',
                                _getDifficultyColor(source.difficulty),
                              ),
                              _buildDetailStat(
                                '인기도',
                                '${source.popularity}%',
                                '사용자 만족도',
                                Colors.orange,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Action Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: source.isActive
                              ? [Colors.grey, Colors.grey.shade700]
                              : [Colors.blue, Colors.lightBlue],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ElevatedButton(
                        onPressed: source.isActive
                            ? null
                            : () {
                                HapticFeedback.heavyImpact();
                                Navigator.pop(context);
                                _showSuccessSnackBar(source.name);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          source.isActive ? '이미 추가됨' : '지금 시작하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailStat(
    String title,
    String value,
    String subtitle,
    Color color,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String sourceName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$sourceName 추가 완료!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '홈 화면에서 확인하세요',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
      ),
    );
  }
}