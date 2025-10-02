import 'package:flutter/material.dart';
import '../services/real_income_service.dart';
import 'walking_reward_screen.dart';

class IncomePlatformsScreen extends StatefulWidget {
  const IncomePlatformsScreen({Key? key}) : super(key: key);

  @override
  State<IncomePlatformsScreen> createState() => _IncomePlatformsScreenState();
}

class _IncomePlatformsScreenState extends State<IncomePlatformsScreen> {
  final RealIncomeService _realIncomeService = RealIncomeService();
  String _selectedCategory = '전체';
  Map<String, bool> _platformStates = {};

  final List<String> _categories = [
    '전체',
    '걷기/건강',
    '제휴 마케팅',
    '프리랜서',
    '설문조사',
    '콘텐츠',
    '배달',
    '투자',
  ];

  @override
  void initState() {
    super.initState();
    _loadPlatformStates();
  }

  void _loadPlatformStates() {
    final platforms = _realIncomeService.getAllPlatforms();
    for (var platform in platforms) {
      _platformStates[platform['id']] = platform['connected'] ?? false;
    }
  }

  List<Map<String, dynamic>> _getFilteredPlatforms() {
    final allPlatforms = _realIncomeService.getAllPlatforms();
    if (_selectedCategory == '전체') {
      return allPlatforms;
    }
    return allPlatforms.where((p) => p['category'] == _selectedCategory).toList();
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '걷기/건강':
        return Colors.green;
      case '제휴 마케팅':
        return Colors.blue;
      case '프리랜서':
        return Colors.purple;
      case '설문조사':
        return Colors.orange;
      case '콘텐츠':
        return Colors.red;
      case '배달':
        return Colors.teal;
      case '투자':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '걷기/건강':
        return Icons.directions_walk;
      case '제휴 마케팅':
        return Icons.shopping_bag;
      case '프리랜서':
        return Icons.work;
      case '설문조사':
        return Icons.assignment;
      case '콘텐츠':
        return Icons.video_library;
      case '배달':
        return Icons.delivery_dining;
      case '투자':
        return Icons.trending_up;
      default:
        return Icons.attach_money;
    }
  }

  @override
  Widget build(BuildContext context) {
    final platforms = _getFilteredPlatforms();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '부수익 플랫폼',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // 카테고리 필터
          Container(
            height: 50,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: Colors.grey[100],
                    selectedColor: Colors.blue[50],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.blue[700] : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
                    ),
                  ),
                );
              },
            ),
          ),

          // 플랫폼 리스트
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: platforms.length,
              itemBuilder: (context, index) {
                final platform = platforms[index];
                final isConnected = _platformStates[platform['id']] ?? false;
                final category = platform['category'] ?? '';

                return Container(
                  margin: EdgeInsets.only(bottom: 12),
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
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        if (platform['name'] == '캐시워크') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WalkingRewardScreen(),
                            ),
                          );
                        } else {
                          _showPlatformDetails(platform);
                        }
                      },
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // 아이콘
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: _getCategoryColor(category).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getCategoryIcon(category),
                                color: _getCategoryColor(category),
                                size: 28,
                              ),
                            ),
                            SizedBox(width: 16),

                            // 정보
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        platform['name']?.toString() ?? '플랫폼',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      if (isConnected)
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green[50],
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.green[200]!),
                                          ),
                                          child: Text(
                                            '연동됨',
                                            style: TextStyle(
                                              color: Colors.green[700],
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    platform['description']?.toString() ?? '설명이 없습니다',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          platform['earning_rate']?.toString() ?? '정보 없음',
                                          style: TextStyle(
                                            color: Colors.blue[700],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '난이도: ${platform['difficulty']?.toString() ?? '보통'}',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // 화살표
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey[400],
                            ),
                          ],
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

  void _showPlatformDetails(Map<String, dynamic> platform) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // 핸들바
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 헤더
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(platform['category']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getCategoryIcon(platform['category']),
                      color: _getCategoryColor(platform['category']),
                      size: 32,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          platform['name']?.toString() ?? '플랫폼',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          platform['category']?.toString() ?? '카테고리',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1),

            // 컨텐츠
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection('설명', platform['description']?.toString() ?? '설명이 없습니다'),
                    SizedBox(height: 20),
                    _buildDetailSection('예상 수익', platform['earning_rate']?.toString() ?? '정보 없음'),
                    SizedBox(height: 20),
                    _buildDetailSection('난이도', platform['difficulty']?.toString() ?? '보통'),
                    SizedBox(height: 20),
                    _buildDetailSection('필요 조건', platform['requirements']?.toString() ?? '특별한 조건 없음'),
                    SizedBox(height: 20),
                    _buildDetailSection('팁', platform['tips']?.toString() ?? '꾸준히 활동하면 수익이 증가합니다'),
                  ],
                ),
              ),
            ),

            // 버튼
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _platformStates[platform['id']] =
                            !(_platformStates[platform['id']] ?? false);
                      });
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _platformStates[platform['id']]!
                                ? '${platform['name']?.toString() ?? '플랫폼'}이(가) 연동되었습니다'
                                : '${platform['name']?.toString() ?? '플랫폼'} 연동이 해제되었습니다',
                          ),
                          backgroundColor: _platformStates[platform['id']]!
                              ? Colors.green
                              : Colors.grey,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _platformStates[platform['id']] ?? false
                          ? Colors.grey[600]
                          : Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _platformStates[platform['id']] ?? false
                          ? '연동 해제'
                          : '플랫폼 연동하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }
}