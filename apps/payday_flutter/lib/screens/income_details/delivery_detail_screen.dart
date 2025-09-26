import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DeliveryDetailScreen extends StatefulWidget {
  const DeliveryDetailScreen({super.key});

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  final DeliveryMockData mockData = DeliveryMockData();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            _buildEarningsOverview(),
            _buildTodayStats(),
            _buildDeliveryPlatforms(),
            _buildWeeklySchedule(),
            _buildTips(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.green,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('배달 서비스', style: TextStyle(color: Colors.white)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.withOpacity(0.8), Colors.lightGreen.withOpacity(0.8)],
            ),
          ),
          child: Center(
            child: Icon(Icons.delivery_dining, size: 80, color: Colors.white.withOpacity(0.8)),
          ),
        ),
      ),
    );
  }

  Widget _buildEarningsOverview() {
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
            Text('이번 달 수익', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('₩${mockData.monthlyEarnings}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard('총 배달 건수', '${mockData.totalDeliveries}건', Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('평균 배달비', '₩${mockData.averageDeliveryFee}', Colors.orange)),
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

  Widget _buildTodayStats() {
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
            const Text('오늘의 배달', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTodayCard('완료', '${mockData.todayCompleted}건', Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _buildTodayCard('수익', '₩${mockData.todayEarnings}', Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildTodayCard('시간', '${mockData.workingHours}시간', Colors.purple)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDeliveryPlatforms() {
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
            const Text('플랫폼별 수익', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...mockData.platforms.map((platform) => Container(
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
                      color: platform['color'],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(platform['icon'], color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(platform['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${platform['deliveries']}건 배달 • 평점 ${platform['rating']}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₩${platform['earnings']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      Text('이번 달', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
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

  Widget _buildWeeklySchedule() {
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
            const Text('주간 일정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...mockData.weeklySchedule.map((day) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: day['isActive'] ? Colors.green.withOpacity(0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(day['day'], style: TextStyle(fontWeight: FontWeight.bold, color: day['isActive'] ? Colors.green : Colors.grey[600])),
                  Text(day['hours'], style: TextStyle(color: day['isActive'] ? Colors.green : Colors.grey[600])),
                  Text(day['earnings'], style: TextStyle(color: day['isActive'] ? Colors.green : Colors.grey[600], fontWeight: FontWeight.bold)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTips() {
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
            const Text('배달 팁', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...mockData.tips.map((tip) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(tip['icon'], color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tip['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(tip['description'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class DeliveryMockData {
  final String monthlyEarnings = '850,000';
  final int totalDeliveries = 156;
  final String averageDeliveryFee = '5,450';

  final int todayCompleted = 12;
  final String todayEarnings = '65,400';
  final int workingHours = 6;

  final List<Map<String, dynamic>> platforms = [
    {'name': '배달의민족', 'deliveries': 89, 'rating': '4.8', 'earnings': '485,000', 'icon': Icons.restaurant, 'color': Colors.cyan},
    {'name': '쿠팡이츠', 'deliveries': 67, 'rating': '4.9', 'earnings': '365,000', 'icon': Icons.shopping_bag, 'color': Colors.purple},
  ];

  final List<Map<String, dynamic>> weeklySchedule = [
    {'day': '월요일', 'hours': '5시간', 'earnings': '₩45,000', 'isActive': true},
    {'day': '화요일', 'hours': '6시간', 'earnings': '₩52,000', 'isActive': true},
    {'day': '수요일', 'hours': '휴무', 'earnings': '₩0', 'isActive': false},
    {'day': '목요일', 'hours': '7시간', 'earnings': '₩58,000', 'isActive': true},
    {'day': '금요일', 'hours': '8시간', 'earnings': '₩72,000', 'isActive': true},
    {'day': '토요일', 'hours': '9시간', 'earnings': '₩89,000', 'isActive': true},
    {'day': '일요일', 'hours': '6시간', 'earnings': '₩55,000', 'isActive': true},
  ];

  final List<Map<String, dynamic>> tips = [
    {'title': '피크 타임 활용', 'description': '점심(11-2시), 저녁(6-9시) 시간대에 집중하세요', 'icon': Icons.schedule},
    {'title': '날씨 체크', 'description': '비오는 날에는 배달비가 더 높아집니다', 'icon': Icons.cloud},
    {'title': '핫플레이스 파악', 'description': '주문이 많은 지역을 미리 파악해두세요', 'icon': Icons.location_on},
  ];
}