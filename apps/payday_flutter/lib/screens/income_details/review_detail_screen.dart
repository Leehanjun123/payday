import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../widgets/income_detail_template.dart';
import '../../models/income_source.dart';

class ReviewDetailScreen extends StatefulWidget {
  const ReviewDetailScreen({super.key});

  @override
  State<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends State<ReviewDetailScreen>
    with TickerProviderStateMixin, IncomeDetailMixin {
  final MockReviewData mockData = MockReviewData();
  late AnimationController _starAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _starAnimation;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();
    _starAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _starAnimation = CurvedAnimation(
      parent: _starAnimationController,
      curve: Curves.elasticOut,
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutBack,
    );

    _starAnimationController.forward();
    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _starAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildLevelCard(),
                _buildAvailableReviews(),
                _buildPendingReviews(),
                _buildCompletedReviews(),
                _buildPlatformStats(),
                _buildEarningHistory(),
                _buildTipsSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: buildIncomeFloatingActionButton(
        IncomeType.review,
        '리뷰',
        Colors.amber,
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF00BFA5),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          '리뷰 작성',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF00BFA5),
                Color(0xFF00ACC1),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.rate_review,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '₩${mockData.totalEarnings.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    '총 리뷰 수익',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard() {
    final levelProgress = mockData.currentExp / mockData.nextLevelExp;

    return Container(
      margin: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: _starAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.9 + (_starAnimation.value * 0.1),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFC107), Color(0xFFFF9800)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '리뷰어 레벨',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            'Lv.${mockData.reviewerLevel} ${mockData.levelTitle}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < mockData.starRating ? Icons.star : Icons.star_border,
                            color: Colors.white,
                            size: 24,
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: levelProgress,
                      minHeight: 10,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${mockData.currentExp}/${mockData.nextLevelExp} EXP',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '신뢰도 ${mockData.trustScore}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvailableReviews() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '작성 가능한 리뷰',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '24시간마다 갱신',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          ...mockData.availableReviews.map((review) => _buildReviewCard(review)),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewTask review) {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _startReview(review),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: review.categoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            review.icon,
                            color: review.categoryColor,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review.productName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: review.platformColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    review.platform,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: review.platformColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  review.category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '최소 ${review.minLength}자',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.timer,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${review.deadline}일 남음',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: review.deadline <= 2 ? Colors.red : Colors.grey[600],
                                  ),
                                ),
                              ],
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
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '₩${review.reward}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPendingReviews() {
    if (mockData.pendingReviews.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              '검토 중인 리뷰',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: mockData.pendingReviews.map((pending) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.hourglass_empty,
                          size: 20,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pending['product'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${pending['platform']} · ${pending['date']} 제출',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₩${pending['reward']}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedReviews() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              '완료한 리뷰',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: mockData.completedReviews.length,
              itemBuilder: (context, index) {
                final completed = mockData.completedReviews[index];
                return _buildCompletedCard(completed);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedCard(Map<String, dynamic> completed) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.green.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  completed['product'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                Icons.star,
                size: 16,
                color: index < completed['rating'] ? Colors.amber : Colors.grey[300],
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            completed['date'],
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: completed['platformColor'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  completed['platform'],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: completed['platformColor'],
                  ),
                ),
              ),
              Text(
                '+₩${completed['reward']}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformStats() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '플랫폼별 실적',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.pie_chart,
                color: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...mockData.platformStats.map((stat) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: stat['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      stat['icon'],
                      size: 20,
                      color: stat['color'],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stat['name'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${stat['count']}개 작성',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₩${stat['earnings']}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          Icons.star,
                          size: 10,
                          color: index < stat['avgRating'] ? Colors.amber : Colors.grey[300],
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildEarningHistory() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.05),
            Colors.purple.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.history,
                color: Colors.blue,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                '수익 내역',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEarningStat('이번 주', mockData.weeklyEarnings, Colors.blue),
              _buildEarningStat('이번 달', mockData.monthlyEarnings, Colors.purple),
              _buildEarningStat('전체', mockData.totalEarnings.toInt(), Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningStat(String label, int amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₩${amount.toString()}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTipsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.withOpacity(0.05),
            Colors.cyan.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.teal.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.teal,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                '리뷰 작성 팁',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipItem('상세하고 솔직한 리뷰가 더 높은 평가를 받습니다'),
          _buildTipItem('사진을 포함하면 추가 보너스를 받을 수 있어요'),
          _buildTipItem('정해진 기간 내에 제출하면 신뢰도가 올라갑니다'),
          _buildTipItem('다양한 카테고리의 제품을 리뷰하면 레벨업이 빨라요'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.teal,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startReview(ReviewTask review) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${review.productName} 리뷰 작성을 시작합니다'),
        backgroundColor: const Color(0xFF00BFA5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// Mock Data Classes
class ReviewTask {
  final String productName;
  final String category;
  final String platform;
  final IconData icon;
  final Color categoryColor;
  final Color platformColor;
  final int minLength;
  final int deadline;
  final int reward;

  ReviewTask({
    required this.productName,
    required this.category,
    required this.platform,
    required this.icon,
    required this.categoryColor,
    required this.platformColor,
    required this.minLength,
    required this.deadline,
    required this.reward,
  });
}

class MockReviewData {
  final double totalEarnings = 68500;
  final int reviewerLevel = 7;
  final String levelTitle = '전문 리뷰어';
  final int starRating = 4;
  final int currentExp = 2800;
  final int nextLevelExp = 5000;
  final int trustScore = 92;

  final int weeklyEarnings = 8500;
  final int monthlyEarnings = 32000;

  final List<ReviewTask> availableReviews = [
    ReviewTask(
      productName: '에어팟 프로 2',
      category: '전자제품',
      platform: '네이버',
      icon: Icons.headphones,
      categoryColor: Colors.blue,
      platformColor: Colors.green,
      minLength: 200,
      deadline: 3,
      reward: 3000,
    ),
    ReviewTask(
      productName: '스타벅스 신메뉴',
      category: '음식',
      platform: '배민',
      icon: Icons.coffee,
      categoryColor: Colors.brown,
      platformColor: const Color(0xFF2AC1BC),
      minLength: 150,
      deadline: 1,
      reward: 2000,
    ),
    ReviewTask(
      productName: '나이키 운동화',
      category: '패션',
      platform: '쿠팡',
      icon: Icons.directions_run,
      categoryColor: Colors.orange,
      platformColor: Colors.red,
      minLength: 300,
      deadline: 5,
      reward: 3500,
    ),
  ];

  final List<Map<String, dynamic>> pendingReviews = [
    {'product': '갤럭시 버즈2', 'platform': '쿠팡', 'date': '12/27', 'reward': 2500},
    {'product': '올리브영 화장품', 'platform': '네이버', 'date': '12/26', 'reward': 2000},
  ];

  final List<Map<String, dynamic>> completedReviews = [
    {
      'product': '아이폰 케이스',
      'rating': 5,
      'date': '12/25 완료',
      'platform': '쿠팡',
      'platformColor': Colors.red,
      'reward': 2500,
    },
    {
      'product': '배달음식 리뷰',
      'rating': 4,
      'date': '12/24 완료',
      'platform': '배민',
      'platformColor': const Color(0xFF2AC1BC),
      'reward': 1500,
    },
    {
      'product': '넷플릭스 영화',
      'rating': 5,
      'date': '12/23 완료',
      'platform': '왓챠',
      'platformColor': Colors.pink,
      'reward': 2000,
    },
  ];

  final List<Map<String, dynamic>> platformStats = [
    {'name': '네이버', 'icon': Icons.search, 'color': Colors.green, 'count': 23, 'earnings': 28000, 'avgRating': 4.5},
    {'name': '쿠팡', 'icon': Icons.shopping_cart, 'color': Colors.red, 'count': 18, 'earnings': 22500, 'avgRating': 4.2},
    {'name': '배민', 'icon': Icons.delivery_dining, 'color': const Color(0xFF2AC1BC), 'count': 15, 'earnings': 18000, 'avgRating': 4.8},
  ];
}