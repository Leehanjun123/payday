import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/income_service.dart';
import '../services/data_service.dart';

class CleanEarningsScreen extends StatefulWidget {
  const CleanEarningsScreen({Key? key}) : super(key: key);

  @override
  State<CleanEarningsScreen> createState() => _CleanEarningsScreenState();
}

class _CleanEarningsScreenState extends State<CleanEarningsScreen> {
  final IncomeServiceInterface _incomeService = IncomeServiceProvider.instance;
  final DataService _dataService = DataService();
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'ko_KR');

  String _selectedPeriod = '오늘';
  double _totalEarnings = 0.0;
  List<Map<String, dynamic>> _recentEarnings = [];
  Map<String, double> _categoryBreakdown = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEarningsData();
  }

  Future<void> _loadEarningsData() async {
    setState(() => _isLoading = true);

    try {
      // 수익 데이터 로드
      final today = await _dataService.getTodayEarnings();
      final weekly = await _dataService.getWeeklyEarnings();
      final monthly = await _dataService.getMonthlyEarnings();
      final recent = await _dataService.getRecentEarnings(limit: 10);

      // 선택된 기간에 따른 총 수익
      double total = 0.0;
      switch (_selectedPeriod) {
        case '오늘':
          total = today;
          break;
        case '이번 주':
          total = weekly;
          break;
        case '이번 달':
          total = monthly;
          break;
      }

      // 카테고리별 수익 분석
      Map<String, double> breakdown = {};
      for (var earning in recent) {
        String category = _getCategory(earning['source'] ?? '');
        breakdown[category] = (breakdown[category] ?? 0) + (earning['amount'] ?? 0.0);
      }

      setState(() {
        _totalEarnings = total;
        _recentEarnings = recent;
        _categoryBreakdown = breakdown;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _getCategory(String source) {
    if (source.contains('광고') || source.contains('AdMob')) {
      return '광고';
    } else if (source.contains('설문') || source.contains('Survey')) {
      return '설문조사';
    } else if (source.contains('걷기') || source.contains('Walk')) {
      return '걷기';
    } else if (source.contains('쿠팡') || source.contains('제휴')) {
      return '제휴마케팅';
    } else {
      return '기타';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '광고':
        return Colors.blue;
      case '설문조사':
        return Colors.green;
      case '걷기':
        return Colors.orange;
      case '제휴마케팅':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 헤더
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue[600]!, Colors.blue[400]!],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _selectedPeriod,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '₩${_currencyFormat.format(_totalEarnings)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 20),
                        // 기간 선택 버튼
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: ['오늘', '이번 주', '이번 달'].map((period) {
                            final isSelected = _selectedPeriod == period;
                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                label: Text(period),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedPeriod = period;
                                  });
                                  _loadEarningsData();
                                },
                                selectedColor: Colors.white,
                                backgroundColor: Colors.white30,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.blue[600] : Colors.white,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 카테고리별 수익
            if (_categoryBreakdown.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(20),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '수익 구성',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      ..._categoryBreakdown.entries.map((entry) {
                        final percentage = (_totalEarnings > 0)
                          ? (entry.value / _totalEarnings * 100)
                          : 0.0;
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: _getCategoryColor(entry.key),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        entry.key,
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '₩${_currencyFormat.format(entry.value)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percentage / 100,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getCategoryColor(entry.key),
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

            // 최근 수익 내역
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '최근 수익',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (_recentEarnings.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            '아직 수익 내역이 없습니다',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    }

                    final earning = _recentEarnings[index];
                    final category = _getCategory(earning['source'] ?? '');
                    final date = earning['date'] != null
                      ? DateFormat('MM/dd HH:mm').format(DateTime.parse(earning['date']))
                      : '';

                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(category).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getCategoryIcon(category),
                            color: _getCategoryColor(category),
                            size: 24,
                          ),
                        ),
                        title: Text(
                          earning['source'] ?? '알 수 없음',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          date,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        trailing: Text(
                          '+₩${_currencyFormat.format(earning['amount'] ?? 0)}',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _recentEarnings.isEmpty ? 1 : _recentEarnings.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '광고':
        return Icons.play_circle_outline;
      case '설문조사':
        return Icons.assignment_outlined;
      case '걷기':
        return Icons.directions_walk;
      case '제휴마케팅':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.attach_money;
    }
  }
}