import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/income_detail_template.dart';
import '../../models/income_source.dart';

class CryptoDetailScreen extends StatefulWidget {
  const CryptoDetailScreen({super.key});

  @override
  State<CryptoDetailScreen> createState() => _CryptoDetailScreenState();
}

class _CryptoDetailScreenState extends State<CryptoDetailScreen> with TickerProviderStateMixin, IncomeDetailMixin {
  final CryptoMockData mockData = CryptoMockData();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            _buildPortfolioOverview(),
            _buildCryptoHoldings(),
            _buildTradingHistory(),
            _buildMarketTrends(),
          ],
        ),
      ),
      floatingActionButton: buildIncomeFloatingActionButton(
        IncomeType.crypto,
        '암호화폐',
        Colors.orange,
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.black,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('암호화폐', style: TextStyle(color: Colors.white)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.withOpacity(0.8), Colors.deepOrange.withOpacity(0.8)],
            ),
          ),
          child: Center(
            child: Icon(Icons.currency_bitcoin, size: 80, color: Colors.white.withOpacity(0.8)),
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
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text('포트폴리오 총 가치', style: TextStyle(color: Colors.grey[400])),
            const SizedBox(height: 8),
            Text('₩${mockData.totalValue}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.trending_up, color: Colors.green),
                Text('+${mockData.totalReturn}%', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCryptoHoldings() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('보유 자산', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...mockData.holdings.map((crypto) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: crypto['color'],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(crypto['symbol'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(crypto['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('${crypto['amount']} ${crypto['symbol']}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₩${crypto['value']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(crypto['change'], style: TextStyle(color: crypto['change'].startsWith('+') ? Colors.green : Colors.red, fontSize: 12)),
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

  Widget _buildTradingHistory() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('거래 내역', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...mockData.tradingHistory.map((trade) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: trade['type'] == 'BUY' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${trade['type']} ${trade['crypto']}', style: TextStyle(color: trade['type'] == 'BUY' ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                  Text('₩${trade['amount']}', style: const TextStyle(color: Colors.white)),
                  Text(trade['date'], style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketTrends() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('시장 동향', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...mockData.marketTrends.map((trend) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trend['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(trend['description'], style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class CryptoMockData {
  final String totalValue = '1,850,000';
  final double totalReturn = 28.5;

  final List<Map<String, dynamic>> holdings = [
    {'symbol': 'BTC', 'name': 'Bitcoin', 'amount': '0.05', 'value': '1,200,000', 'change': '+15.2%', 'color': Colors.orange},
    {'symbol': 'ETH', 'name': 'Ethereum', 'amount': '0.8', 'value': '450,000', 'change': '+8.7%', 'color': Colors.blue},
    {'symbol': 'ADA', 'name': 'Cardano', 'amount': '500', 'value': '200,000', 'change': '-2.1%', 'color': Colors.indigo},
  ];

  final List<Map<String, dynamic>> tradingHistory = [
    {'type': 'BUY', 'crypto': 'BTC', 'amount': '300,000', 'date': '11월 20일'},
    {'type': 'SELL', 'crypto': 'ETH', 'amount': '150,000', 'date': '11월 18일'},
    {'type': 'BUY', 'crypto': 'ADA', 'amount': '100,000', 'date': '11월 15일'},
  ];

  final List<Map<String, dynamic>> marketTrends = [
    {'title': '비트코인 신고가 경신', 'description': '기관 투자자들의 관심 증가로 BTC가 사상 최고가를 기록했습니다.'},
    {'title': '이더리움 2.0 업그레이드', 'description': 'ETH 네트워크의 확장성 개선으로 가격 상승세가 지속되고 있습니다.'},
    {'title': 'DeFi 시장 성장', 'description': '탈중앙화 금융 프로토콜의 성장으로 관련 토큰들이 주목받고 있습니다.'},
  ];
}