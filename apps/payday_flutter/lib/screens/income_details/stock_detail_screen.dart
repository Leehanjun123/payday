import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../widgets/income_detail_template.dart';
import '../../models/income_source.dart';

class StockDetailScreen extends StatefulWidget {
  const StockDetailScreen({super.key});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen>
    with TickerProviderStateMixin, IncomeDetailMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final StockMockData mockData = StockMockData();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              _buildPortfolioOverview(),
              _buildHoldings(),
              _buildDividends(),
              _buildWatchlist(),
              _buildMarketNews(),
            ],
          ),
        ),
      ),
      floatingActionButton: buildIncomeFloatingActionButton(
        IncomeType.stock,
        '주식',
        Colors.teal,
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.teal,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          '주식 투자',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.withOpacity(0.8), Colors.green.withOpacity(0.8)],
            ),
          ),
          child: Center(
            child: Icon(Icons.trending_up, size: 80, color: Colors.white.withOpacity(0.8)),
          ),
        ),
      ),
    );
  }

  Widget _buildPortfolioOverview() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 8)],
        ),
        child: Column(
          children: [
            Text('포트폴리오 총 가치', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 8),
            Text('₩${mockData.totalValue}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(mockData.totalReturn > 0 ? Icons.trending_up : Icons.trending_down,
                     color: mockData.totalReturn > 0 ? Colors.green : Colors.red),
                Text('${mockData.totalReturn > 0 ? '+' : ''}${mockData.totalReturn}%',
                     style: TextStyle(color: mockData.totalReturn > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard('투자 원금', '₩${mockData.principal}', Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('평가 손익', '₩${mockData.unrealizedPL}', mockData.unrealizedPL.startsWith('+') ? Colors.green : Colors.red)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHoldings() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('보유 종목', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...mockData.holdings.map((stock) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: stock['color'],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(stock['symbol'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stock['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${stock['shares']}주 • ₩${stock['avgPrice']}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₩${stock['currentPrice']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(stock['change'], style: TextStyle(color: stock['change'].startsWith('+') ? Colors.green : Colors.red, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDividends() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('배당금', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard('올해 배당금', '₩${mockData.yearlyDividend}', Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('예상 수익률', '${mockData.dividendYield}%', Colors.blue)),
              ],
            ),
            const SizedBox(height: 16),
            ...mockData.dividendHistory.map((dividend) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dividend['company'], style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text('₩${dividend['amount']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  Text(dividend['date'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchlist() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('관심 종목', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...mockData.watchlist.map((stock) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(stock['symbol'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(stock['name'], style: TextStyle(color: Colors.grey[600]))),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₩${stock['price']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(stock['change'], style: TextStyle(color: stock['change'].startsWith('+') ? Colors.green : Colors.red, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketNews() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('시장 뉴스', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...mockData.marketNews.map((news) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(news['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(news['summary'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(news['time'], style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class StockMockData {
  final String totalValue = '3,250,000';
  final double totalReturn = 12.5;
  final String principal = '2,890,000';
  final String unrealizedPL = '+360,000';

  final List<Map<String, dynamic>> holdings = [
    {'symbol': 'AAPL', 'name': 'Apple Inc.', 'shares': 10, 'avgPrice': '180,000', 'currentPrice': '185,000', 'change': '+2.8%', 'color': Colors.grey},
    {'symbol': 'TSLA', 'name': 'Tesla Inc.', 'shares': 5, 'avgPrice': '250,000', 'currentPrice': '265,000', 'change': '+6.0%', 'color': Colors.red},
    {'symbol': '삼성전자', 'name': 'Samsung Electronics', 'shares': 20, 'avgPrice': '70,000', 'currentPrice': '72,500', 'change': '+3.6%', 'color': Colors.blue},
  ];

  final String yearlyDividend = '125,000';
  final double dividendYield = 3.8;

  final List<Map<String, dynamic>> dividendHistory = [
    {'company': '삼성전자', 'amount': '15,000', 'date': '11월 15일'},
    {'company': 'Apple', 'amount': '8,500', 'date': '11월 1일'},
    {'company': 'Microsoft', 'amount': '12,000', 'date': '10월 15일'},
  ];

  final List<Map<String, dynamic>> watchlist = [
    {'symbol': 'NVDA', 'name': 'NVIDIA Corp.', 'price': '420,000', 'change': '+8.2%'},
    {'symbol': 'MSFT', 'name': 'Microsoft Corp.', 'price': '380,000', 'change': '-1.5%'},
    {'symbol': 'LG화학', 'name': 'LG Chem Ltd.', 'price': '450,000', 'change': '+2.1%'},
  ];

  final List<Map<String, dynamic>> marketNews = [
    {'title': '반도체 업계 전망 밝아져', 'summary': '글로벌 반도체 수요 증가로 관련 종목들이 상승세를 보이고 있습니다.', 'time': '2시간 전'},
    {'title': '전기차 시장 성장 지속', 'summary': 'Tesla와 현대차 등 전기차 업체들의 실적이 예상을 상회했습니다.', 'time': '4시간 전'},
    {'title': '금리 인하 기대감 확산', 'summary': '연준의 금리 인하 가능성이 높아지면서 주식시장에 긍정적 영향을 미치고 있습니다.', 'time': '6시간 전'},
  ];
}