import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math';
import 'package:share_plus/share_plus.dart';
import '../../widgets/income_detail_template.dart';
import '../../models/income_source.dart';

class ReferralDetailScreen extends StatefulWidget {
  const ReferralDetailScreen({super.key});

  @override
  State<ReferralDetailScreen> createState() => _ReferralDetailScreenState();
}

class _ReferralDetailScreenState extends State<ReferralDetailScreen>
    with TickerProviderStateMixin, IncomeDetailMixin {
  final MockReferralData mockData = MockReferralData();
  late AnimationController _rankAnimationController;
  late AnimationController _rewardAnimationController;
  late Animation<double> _rankAnimation;
  late Animation<double> _rewardAnimation;
  final TextEditingController _inviteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rankAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _rewardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rankAnimation = CurvedAnimation(
      parent: _rankAnimationController,
      curve: Curves.easeOutBack,
    );
    _rewardAnimation = CurvedAnimation(
      parent: _rewardAnimationController,
      curve: Curves.elasticOut,
    );

    _rankAnimationController.forward();
    _rewardAnimationController.forward();
  }

  @override
  void dispose() {
    _rankAnimationController.dispose();
    _rewardAnimationController.dispose();
    _inviteController.dispose();
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
                _buildReferralCodeCard(),
                _buildReferralStats(),
                _buildRankingCard(),
                _buildActiveReferrals(),
                _buildRewardTiers(),
                _buildReferralHistory(),
                _buildShareSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: buildIncomeFloatingActionButton(
        IncomeType.referral,
        '추천인',
        Colors.pink,
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF6B46C1),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          '친구 초대',
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
                Color(0xFF6B46C1),
                Color(0xFF9333EA),
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
                    Icons.people_alt_rounded,
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
                    '총 추천 수익',
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

  Widget _buildReferralCodeCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: _rewardAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.9 + (_rewardAnimation.value * 0.1),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    '나의 초대 코드',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          mockData.referralCode,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () => _copyReferralCode(),
                          icon: const Icon(
                            Icons.copy,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCodeStat('오늘 가입', mockData.todaySignups),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.white24,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      _buildCodeStat('이번 달', mockData.monthlySignups),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.white24,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      _buildCodeStat('전체', mockData.totalReferrals),
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

  Widget _buildCodeStat(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildReferralStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          const Text(
            '추천 통계',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.person_add,
                value: '${mockData.activeReferrals}명',
                label: '활성 추천인',
                color: Colors.green,
              ),
              _buildStatItem(
                icon: Icons.trending_up,
                value: '${mockData.conversionRate}%',
                label: '전환율',
                color: Colors.blue,
              ),
              _buildStatItem(
                icon: Icons.attach_money,
                value: '₩${mockData.averageEarningPerReferral}',
                label: '평균 수익',
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRankingCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: _rankAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _rankAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.withOpacity(0.1),
                    Colors.orange.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '이번 달 순위',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.emoji_events,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '#${mockData.currentRank}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: mockData.rankProgress,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '다음 순위까지 ${mockData.referralsToNextRank}명',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '상위 ${mockData.percentile}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
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

  Widget _buildActiveReferrals() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              '최근 추천 친구',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...mockData.recentReferrals.map((referral) => _buildReferralCard(referral)),
        ],
      ),
    );
  }

  Widget _buildReferralCard(ReferralFriend referral) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: referral.color.withOpacity(0.2),
                child: Text(
                  referral.name[0],
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: referral.color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          referral.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (referral.isPremium) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'PREMIUM',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          referral.joinDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.trending_up,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Lv.${referral.level}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+₩${referral.earning.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    referral.status,
                    style: TextStyle(
                      fontSize: 12,
                      color: referral.isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardTiers() {
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
                '추천 보상 단계',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.stars,
                color: Colors.amber,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...mockData.rewardTiers.map((tier) => _buildTierItem(tier)),
        ],
      ),
    );
  }

  Widget _buildTierItem(RewardTier tier) {
    final isUnlocked = mockData.totalReferrals >= tier.requiredReferrals;
    final progress = mockData.totalReferrals / tier.requiredReferrals;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: isUnlocked
                  ? LinearGradient(
                      colors: [tier.color.withOpacity(0.8), tier.color],
                    )
                  : null,
              color: isUnlocked ? null : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                tier.icon,
                color: isUnlocked ? Colors.white : Colors.grey[400],
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tier.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? Colors.black : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isUnlocked)
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${tier.requiredReferrals}명 달성 시',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: tier.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '+₩${tier.reward}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: tier.color,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isUnlocked) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(tier.color),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralHistory() {
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
                '추천 수익 내역',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...mockData.earningHistory.map((history) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: history['type'] == 'signup'
                        ? Colors.green
                        : history['type'] == 'tier'
                            ? Colors.amber
                            : Colors.blue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        history['description'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        history['date'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '+₩${history['amount']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildShareSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            '친구에게 공유하기',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildShareButton(
                icon: Icons.message,
                label: '카카오톡',
                color: const Color(0xFFFEE500),
                onTap: () => _shareViaKakao(),
              ),
              _buildShareButton(
                icon: Icons.link,
                label: '링크복사',
                color: Colors.grey,
                onTap: () => _copyInviteLink(),
              ),
              _buildShareButton(
                icon: Icons.share,
                label: '공유하기',
                color: Colors.blue,
                onTap: () => _shareGeneral(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _copyReferralCode() {
    if (!kIsWeb) {
      Clipboard.setData(ClipboardData(text: mockData.referralCode));
      HapticFeedback.mediumImpact();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('초대 코드가 복사되었습니다'),
        backgroundColor: Colors.purple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _copyInviteLink() {
    final link = 'https://payday.app/invite/${mockData.referralCode}';
    if (!kIsWeb) {
      Clipboard.setData(ClipboardData(text: link));
      HapticFeedback.mediumImpact();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('초대 링크가 복사되었습니다'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _shareViaKakao() {
    // 카카오톡 공유 구현
    _shareGeneral();
  }

  void _shareGeneral() {
    final text = '페이데이 앱으로 부수익 만들어요! 🎉\n'
        '제 초대코드: ${mockData.referralCode}\n'
        '지금 가입하면 ₩5,000 보너스!\n'
        'https://payday.app/invite/${mockData.referralCode}';

    if (!kIsWeb) {
      Share.share(text);
    }
  }
}

// Mock Data Classes
class ReferralFriend {
  final String name;
  final String joinDate;
  final double earning;
  final bool isActive;
  final int level;
  final bool isPremium;
  final String status;
  final Color color;

  ReferralFriend({
    required this.name,
    required this.joinDate,
    required this.earning,
    required this.isActive,
    required this.level,
    required this.isPremium,
    required this.status,
    required this.color,
  });
}

class RewardTier {
  final String name;
  final int requiredReferrals;
  final double reward;
  final IconData icon;
  final Color color;

  RewardTier({
    required this.name,
    required this.requiredReferrals,
    required this.reward,
    required this.icon,
    required this.color,
  });
}

class MockReferralData {
  final String referralCode = 'PAY2024';
  final int totalReferrals = 23;
  final int activeReferrals = 18;
  final int todaySignups = 2;
  final int monthlySignups = 8;
  final double totalEarnings = 115000;
  final int currentRank = 42;
  final double rankProgress = 0.7;
  final int referralsToNextRank = 3;
  final int percentile = 15;
  final int conversionRate = 72;
  final double averageEarningPerReferral = 5000;

  final List<ReferralFriend> recentReferrals = [
    ReferralFriend(
      name: '김민수',
      joinDate: '2024-12-28',
      earning: 5000,
      isActive: true,
      level: 3,
      isPremium: false,
      status: '활동중',
      color: Colors.blue,
    ),
    ReferralFriend(
      name: '이서연',
      joinDate: '2024-12-27',
      earning: 7500,
      isActive: true,
      level: 5,
      isPremium: true,
      status: '활동중',
      color: Colors.purple,
    ),
    ReferralFriend(
      name: '박준호',
      joinDate: '2024-12-25',
      earning: 3000,
      isActive: false,
      level: 2,
      isPremium: false,
      status: '휴면',
      color: Colors.orange,
    ),
  ];

  final List<RewardTier> rewardTiers = [
    RewardTier(
      name: '브론즈',
      requiredReferrals: 5,
      reward: 10000,
      icon: Icons.military_tech,
      color: Colors.brown,
    ),
    RewardTier(
      name: '실버',
      requiredReferrals: 10,
      reward: 25000,
      icon: Icons.workspace_premium,
      color: Colors.grey,
    ),
    RewardTier(
      name: '골드',
      requiredReferrals: 25,
      reward: 50000,
      icon: Icons.emoji_events,
      color: Colors.amber,
    ),
    RewardTier(
      name: '플래티넘',
      requiredReferrals: 50,
      reward: 100000,
      icon: Icons.diamond,
      color: Colors.purple,
    ),
  ];

  final List<Map<String, dynamic>> earningHistory = [
    {'date': '12/28 14:30', 'description': '김민수님 가입 보너스', 'amount': 5000, 'type': 'signup'},
    {'date': '12/27 09:15', 'description': '이서연님 프리미엄 전환', 'amount': 2500, 'type': 'premium'},
    {'date': '12/26 18:00', 'description': '실버 등급 달성 보상', 'amount': 25000, 'type': 'tier'},
    {'date': '12/25 11:20', 'description': '박준호님 가입 보너스', 'amount': 5000, 'type': 'signup'},
  ];
}