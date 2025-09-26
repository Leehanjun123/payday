import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/income_source.dart';
import '../services/income_service.dart';
import 'income_details/reward_ad_detail_screen.dart';
import 'income_details/daily_mission_detail_screen.dart';
import 'income_details/referral_detail_screen.dart';
import 'income_details/survey_detail_screen.dart';
import 'income_details/quiz_detail_screen.dart';
import 'income_details/walking_reward_detail_screen.dart';
import 'income_details/game_detail_screen.dart';
import 'income_details/review_detail_screen.dart';
import 'income_details/youtube_detail_screen.dart';
import 'income_details/blog_detail_screen.dart';
import 'income_details/tiktok_detail_screen.dart';
import 'income_details/instagram_detail_screen.dart';
import 'income_details/freelance_detail_screen.dart';
import 'income_details/stock_detail_screen.dart';
import 'income_details/crypto_detail_screen.dart';

class SimpleHome extends StatefulWidget {
  const SimpleHome({Key? key}) : super(key: key);

  @override
  State<SimpleHome> createState() => SimpleHomeState();
}

class SimpleHomeState extends State<SimpleHome> {
  double _totalBalance = 42850.0; // 목업 데이터
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTotalBalance();
  }

  Future<void> _loadTotalBalance() async {
    setState(() => _isLoading = true);

    try {
      final IncomeServiceInterface incomeService = IncomeServiceProvider.instance;
      final totalIncome = await incomeService.getTotalIncome();

      setState(() {
        _totalBalance = totalIncome;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void refreshBalance() {
    _loadTotalBalance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildBalanceCard(),
              _buildIncomeGrid(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '안녕하세요, 한준님',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '오늘도 수익을 만들어보세요',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              Icons.notifications_none,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue[600],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '총 잔액',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₩${_totalBalance.toStringAsFixed(0)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '이번 달 +15.2%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeGrid() {
    final incomeTypes = [
      {'type': IncomeType.freelance, 'title': '프리랜서', 'icon': Icons.work_outline, 'color': Colors.indigo},
      {'type': IncomeType.stock, 'title': '주식', 'icon': Icons.trending_up, 'color': Colors.teal},
      {'type': IncomeType.crypto, 'title': '암호화폐', 'icon': Icons.currency_bitcoin, 'color': Colors.orange},
      {'type': IncomeType.youtube, 'title': 'YouTube', 'icon': Icons.play_arrow, 'color': Colors.red},
      {'type': IncomeType.tiktok, 'title': 'TikTok', 'icon': Icons.music_note, 'color': Colors.black},
      {'type': IncomeType.instagram, 'title': 'Instagram', 'icon': Icons.camera_alt, 'color': Colors.purple},
      {'type': IncomeType.blog, 'title': '블로그', 'icon': Icons.article, 'color': Colors.green},
      {'type': IncomeType.walkingReward, 'title': '걸음 리워드', 'icon': Icons.directions_walk, 'color': Colors.lightGreen},
      {'type': IncomeType.game, 'title': '게임', 'icon': Icons.sports_esports, 'color': Colors.purple},
      {'type': IncomeType.review, 'title': '리뷰', 'icon': Icons.star, 'color': Colors.amber},
      {'type': IncomeType.survey, 'title': '설문조사', 'icon': Icons.poll, 'color': Colors.cyan},
      {'type': IncomeType.quiz, 'title': '퀴즈', 'icon': Icons.quiz, 'color': Colors.deepPurple},
      {'type': IncomeType.dailyMission, 'title': '데일리 미션', 'icon': Icons.task_alt, 'color': Colors.brown},
      {'type': IncomeType.referral, 'title': '추천인', 'icon': Icons.people, 'color': Colors.pink},
      {'type': IncomeType.rewardAd, 'title': '리워드 광고', 'icon': Icons.monetization_on, 'color': Colors.deepOrange},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '수익원',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: incomeTypes.length,
            itemBuilder: (context, index) {
              final item = incomeTypes[index];
              return _buildIncomeCard(
                item['title'] as String,
                item['icon'] as IconData,
                item['color'] as Color,
                item['type'] as IncomeType,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeCard(String title, IconData icon, Color color, IncomeType type) {
    return GestureDetector(
      onTap: () => _navigateToDetail(type),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(IncomeType type) {
    Widget targetScreen;

    switch (type) {
      case IncomeType.freelance:
        targetScreen = const FreelanceDetailScreen();
        break;
      case IncomeType.stock:
        targetScreen = const StockDetailScreen();
        break;
      case IncomeType.crypto:
        targetScreen = const CryptoDetailScreen();
        break;
      case IncomeType.youtube:
        targetScreen = const YouTubeDetailScreen();
        break;
      case IncomeType.tiktok:
        targetScreen = const TikTokDetailScreen();
        break;
      case IncomeType.instagram:
        targetScreen = const InstagramDetailScreen();
        break;
      case IncomeType.blog:
        targetScreen = const BlogDetailScreen();
        break;
      case IncomeType.walkingReward:
        targetScreen = const WalkingRewardDetailScreen();
        break;
      case IncomeType.game:
        targetScreen = const GameDetailScreen();
        break;
      case IncomeType.review:
        targetScreen = const ReviewDetailScreen();
        break;
      case IncomeType.survey:
        targetScreen = const SurveyDetailScreen();
        break;
      case IncomeType.quiz:
        targetScreen = const QuizDetailScreen();
        break;
      case IncomeType.dailyMission:
        targetScreen = const DailyMissionDetailScreen();
        break;
      case IncomeType.referral:
        targetScreen = const ReferralDetailScreen();
        break;
      case IncomeType.rewardAd:
        targetScreen = const RewardAdDetailScreen();
        break;
      default:
        return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => targetScreen),
    );
  }
}