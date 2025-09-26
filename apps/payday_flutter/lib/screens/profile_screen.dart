import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;
import '../models/gamification.dart';
import '../services/income_data_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _levelAnimationController;
  late AnimationController _statsAnimationController;
  late Animation<double> _levelProgress;
  late Animation<double> _statsScale;

  // Mock user data
  final String userName = 'PayDay King';
  final String userEmail = 'testuser@payday.com';
  final String userAvatar = '👑';
  final int userPoints = 15234;
  final double totalEarnings = 12567.89;
  final int activeStreak = 42;
  final int completedQuests = 128;
  final int friendsReferred = 23;
  final DateTime joinDate = DateTime(2024, 1, 15);

  @override
  void initState() {
    super.initState();
    _levelAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _statsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _levelProgress = Tween<double>(
      begin: 0,
      end: 0.75,
    ).animate(CurvedAnimation(
      parent: _levelAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _statsScale = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _statsAnimationController,
      curve: Curves.elasticOut,
    ));

    _levelAnimationController.forward();
    _statsAnimationController.forward();
  }

  @override
  void dispose() {
    _levelAnimationController.dispose();
    _statsAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final levelInfo = LevelInfo.getLevelInfo(userPoints);
    final nextLevelInfo = LevelInfo.getLevelInfo(levelInfo.maxPoints + 1);
    final levelProgress =
        (userPoints - levelInfo.minPoints) / (levelInfo.maxPoints - levelInfo.minPoints + 1);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF0F3460),
              Color(0xFF16213E),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '프로필',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.settings, color: Colors.white),
                        onPressed: () {
                          // Navigate to settings
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Profile Header
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: levelInfo.gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: levelInfo.primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar and Level Badge
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              child: Text(
                                userAvatar,
                                style: TextStyle(fontSize: 50),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    levelInfo.badge,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    levelInfo.name,
                                    style: TextStyle(
                                      color: levelInfo.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // User Name
                      Text(
                        userName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        userEmail,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 20),

                      // Level Progress
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${userPoints.toStringAsFixed(0)} XP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${nextLevelInfo.minPoints} XP',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          AnimatedBuilder(
                            animation: _levelProgress,
                            builder: (context, child) {
                              return Stack(
                                children: [
                                  Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  Container(
                                    height: 8,
                                    width: MediaQuery.of(context).size.width *
                                        0.75 *
                                        _levelProgress.value *
                                        levelProgress,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white54,
                                          blurRadius: 5,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          SizedBox(height: 8),
                          Text(
                            '다음 레벨까지 ${(nextLevelInfo.minPoints - userPoints).toStringAsFixed(0)} XP',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Stats Grid
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _statsScale,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _statsScale.value,
                      child: Container(
                        margin: EdgeInsets.all(20),
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.5,
                          children: [
                            _buildStatCard(
                              icon: Icons.attach_money,
                              title: '총 수익',
                              value: '\$${totalEarnings.toStringAsFixed(2)}',
                              subtitle: '약 ${(totalEarnings * 1300).toStringAsFixed(0)}원',
                              color: Colors.green,
                            ),
                            _buildStatCard(
                              icon: Icons.local_fire_department,
                              title: '연속 출석',
                              value: '$activeStreak일',
                              subtitle: '🔥 최고 기록!',
                              color: Colors.orange,
                            ),
                            _buildStatCard(
                              icon: Icons.check_circle,
                              title: '완료 퀘스트',
                              value: '$completedQuests개',
                              subtitle: '상위 5%',
                              color: Colors.blue,
                            ),
                            _buildStatCard(
                              icon: Icons.people,
                              title: '친구 초대',
                              value: '$friendsReferred명',
                              subtitle: '+\$${(friendsReferred * 5).toStringAsFixed(2)} 보너스',
                              color: Colors.purple,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Menu Items
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.history,
                        title: '거래 내역',
                        subtitle: '모든 수익 기록 보기',
                        onTap: () {},
                      ),
                      _buildMenuDivider(),
                      _buildMenuItem(
                        icon: Icons.account_balance_wallet,
                        title: '출금 관리',
                        subtitle: '수익 출금하기',
                        onTap: () {},
                      ),
                      _buildMenuDivider(),
                      _buildMenuItem(
                        icon: Icons.bar_chart,
                        title: '수익 분석',
                        subtitle: '상세 통계 보기',
                        onTap: () {},
                      ),
                      _buildMenuDivider(),
                      _buildMenuItem(
                        icon: Icons.card_giftcard,
                        title: '보상 스토어',
                        subtitle: '포인트로 보상 받기',
                        onTap: () {},
                      ),
                      _buildMenuDivider(),
                      _buildMenuItem(
                        icon: Icons.share,
                        title: '친구 초대',
                        subtitle: '초대하고 보너스 받기',
                        onTap: () {},
                      ),
                      _buildMenuDivider(),
                      _buildMenuItem(
                        icon: Icons.help_outline,
                        title: '도움말',
                        subtitle: 'FAQ 및 지원',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),

              // Account Info
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.all(20),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '계정 정보',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '가입일',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${joinDate.year}년 ${joinDate.month}월 ${joinDate.day}일',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '회원 등급',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: levelInfo.gradientColors,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'VIP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Sign Out Button
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: TextButton(
                    onPressed: () {
                      // Handle sign out
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      '로그아웃',
                      style: TextStyle(
                        color: Colors.red[400],
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white70,
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white24,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuDivider() {
    return Container(
      height: 1,
      margin: EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white.withOpacity(0.05),
    );
  }
}