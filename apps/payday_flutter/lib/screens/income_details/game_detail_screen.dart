import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';
import '../../widgets/income_detail_template.dart';
import '../../models/income_source.dart';

class GameDetailScreen extends StatefulWidget {
  const GameDetailScreen({super.key});

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen>
    with TickerProviderStateMixin, IncomeDetailMixin {
  final MockGameData mockData = MockGameData();
  late AnimationController _coinAnimationController;
  late AnimationController _levelAnimationController;
  late AnimationController _gameCardController;
  late Animation<double> _coinAnimation;
  late Animation<double> _levelAnimation;
  late Animation<double> _gameCardAnimation;

  @override
  void initState() {
    super.initState();
    _coinAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _levelAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _gameCardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _coinAnimation = CurvedAnimation(
      parent: _coinAnimationController,
      curve: Curves.linear,
    );
    _levelAnimation = CurvedAnimation(
      parent: _levelAnimationController,
      curve: Curves.elasticOut,
    );
    _gameCardAnimation = CurvedAnimation(
      parent: _gameCardController,
      curve: Curves.easeOutBack,
    );

    _levelAnimationController.forward();
    _gameCardController.forward();
  }

  @override
  void dispose() {
    _coinAnimationController.dispose();
    _levelAnimationController.dispose();
    _gameCardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildEnergyBar(),
                _buildFeaturedGames(),
                _buildDailyBonus(),
                _buildGameCategories(),
                _buildTopEarningGames(),
                _buildGameStats(),
                _buildAchievements(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: buildIncomeFloatingActionButton(
        IncomeType.game,
        '게임',
        Colors.purple,
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF1A1A2E),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          '게임 센터',
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
                Color(0xFF1A1A2E),
                Color(0xFF16213E),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _coinAnimation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _coinAnimation.value * 2 * math.pi,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.amber, Colors.orange],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.monetization_on,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '₩${mockData.totalEarnings.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    '총 게임 수익',
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

  Widget _buildEnergyBar() {
    final energyPercent = mockData.currentEnergy / mockData.maxEnergy;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.2),
            Colors.blue.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bolt,
                    color: Colors.yellow,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '에너지',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                '${mockData.currentEnergy}/${mockData.maxEnergy}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: energyPercent,
              minHeight: 20,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(
                energyPercent > 0.5
                    ? Colors.green
                    : energyPercent > 0.2
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '다음 충전까지 ${mockData.nextRechargeMinutes}분',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedGames() {
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
                  '추천 게임',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                      size: 20,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'HOT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: mockData.featuredGames.length,
              itemBuilder: (context, index) {
                final game = mockData.featuredGames[index];
                return AnimatedBuilder(
                  animation: _gameCardAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _gameCardAnimation.value,
                      child: _buildGameCard(game),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(Game game) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _playGame(game),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  game.primaryColor.withOpacity(0.8),
                  game.secondaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: game.primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  game.icon,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  game.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  game.genre,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bolt,
                        size: 14,
                        color: Colors.yellow,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${game.energyCost}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₩${game.reward}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.lightGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (game.isNew)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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

  Widget _buildDailyBonus() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.card_giftcard,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '일일 보너스',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  mockData.isDailyBonusClaimed
                      ? '내일 다시 받으세요!'
                      : '₩${mockData.dailyBonusAmount} 받기',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: mockData.isDailyBonusClaimed ? null : _claimDailyBonus,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              mockData.isDailyBonusClaimed ? '완료' : '받기',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCategories() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              '게임 카테고리',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: mockData.categories.length,
            itemBuilder: (context, index) {
              final category = mockData.categories[index];
              return _buildCategoryCard(category);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(GameCategory category) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _selectCategory(category),
        child: Container(
          decoration: BoxDecoration(
            color: category.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: category.color.withOpacity(0.5),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                category.icon,
                size: 28,
                color: category.color,
              ),
              const SizedBox(height: 8),
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${category.gameCount}개',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopEarningGames() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '인기 수익 게임',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Icon(
                Icons.trending_up,
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(3, (index) {
            final game = mockData.topEarningGames[index];
            return _buildTopGameItem(game, index + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildTopGameItem(Map<String, dynamic> game, int rank) {
    final rankColor = rank == 1
        ? Colors.amber
        : rank == 2
            ? Colors.grey
            : Colors.brown;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: rankColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            game['icon'],
            size: 24,
            color: game['color'],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game['name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${game['players']} 플레이어',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₩${game['avgEarning']}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                '평균 수익',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameStats() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.purple.withOpacity(0.1),
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
          const Text(
            '게임 통계',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.sports_esports,
                value: mockData.totalGamesPlayed.toString(),
                label: '총 플레이',
                color: Colors.blue,
              ),
              _buildStatItem(
                icon: Icons.emoji_events,
                value: mockData.totalWins.toString(),
                label: '승리',
                color: Colors.amber,
              ),
              _buildStatItem(
                icon: Icons.timer,
                value: '${mockData.totalPlayTime}시간',
                label: '플레이 시간',
                color: Colors.green,
              ),
              _buildStatItem(
                icon: Icons.star,
                value: 'Lv.${mockData.playerLevel}',
                label: '레벨',
                color: Colors.purple,
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildAchievements() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              '업적',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: mockData.achievements.length,
              itemBuilder: (context, index) {
                final achievement = mockData.achievements[index];
                return _buildAchievementCard(achievement);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: achievement['unlocked']
            ? LinearGradient(
                colors: [
                  achievement['color'].withOpacity(0.6),
                  achievement['color'].withOpacity(0.3),
                ],
              )
            : null,
        color: achievement['unlocked'] ? null : Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            achievement['icon'],
            size: 28,
            color: achievement['unlocked'] ? Colors.white : Colors.grey[600],
          ),
          const SizedBox(height: 8),
          Text(
            achievement['name'],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: achievement['unlocked'] ? Colors.white : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (achievement['unlocked'])
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '+₩${achievement['reward']}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _playGame(Game game) {
    if (mockData.currentEnergy >= game.energyCost) {
      HapticFeedback.heavyImpact();
      setState(() {
        mockData.currentEnergy -= game.energyCost;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${game.name}을 시작합니다!'),
          backgroundColor: game.primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('에너지가 부족합니다!'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _selectCategory(GameCategory category) {
    HapticFeedback.selectionClick();
  }

  void _claimDailyBonus() {
    HapticFeedback.heavyImpact();
    setState(() {
      mockData.isDailyBonusClaimed = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('일일 보너스 ₩${mockData.dailyBonusAmount}를 받았습니다!'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// Mock Data Classes
class Game {
  final String name;
  final String genre;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final int energyCost;
  final int reward;
  final bool isNew;

  Game({
    required this.name,
    required this.genre,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.energyCost,
    required this.reward,
    this.isNew = false,
  });
}

class GameCategory {
  final String name;
  final IconData icon;
  final Color color;
  final int gameCount;

  GameCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.gameCount,
  });
}

class MockGameData {
  final double totalEarnings = 52000;
  int currentEnergy = 45;
  final int maxEnergy = 100;
  final int nextRechargeMinutes = 12;
  bool isDailyBonusClaimed = false;
  final int dailyBonusAmount = 1000;

  final int totalGamesPlayed = 234;
  final int totalWins = 156;
  final int totalPlayTime = 48;
  final int playerLevel = 12;

  final List<Game> featuredGames = [
    Game(
      name: '코인 러쉬',
      genre: '아케이드',
      icon: Icons.monetization_on,
      primaryColor: Colors.amber,
      secondaryColor: Colors.orange,
      energyCost: 5,
      reward: 200,
      isNew: true,
    ),
    Game(
      name: '퍼즐 마스터',
      genre: '퍼즐',
      icon: Icons.extension,
      primaryColor: Colors.blue,
      secondaryColor: Colors.cyan,
      energyCost: 3,
      reward: 150,
    ),
    Game(
      name: '럭키 슬롯',
      genre: '카지노',
      icon: Icons.casino,
      primaryColor: Colors.purple,
      secondaryColor: Colors.pink,
      energyCost: 10,
      reward: 500,
      isNew: true,
    ),
    Game(
      name: '메모리 챌린지',
      genre: '두뇌',
      icon: Icons.psychology,
      primaryColor: Colors.green,
      secondaryColor: Colors.teal,
      energyCost: 4,
      reward: 180,
    ),
  ];

  final List<GameCategory> categories = [
    GameCategory(name: '아케이드', icon: Icons.sports_esports, color: Colors.red, gameCount: 15),
    GameCategory(name: '퍼즐', icon: Icons.extension, color: Colors.blue, gameCount: 12),
    GameCategory(name: '카드', icon: Icons.style, color: Colors.green, gameCount: 8),
    GameCategory(name: '전략', icon: Icons.military_tech, color: Colors.purple, gameCount: 10),
    GameCategory(name: '스포츠', icon: Icons.sports_soccer, color: Colors.orange, gameCount: 6),
    GameCategory(name: '두뇌', icon: Icons.psychology, color: Colors.cyan, gameCount: 9),
  ];

  final List<Map<String, dynamic>> topEarningGames = [
    {'name': '럭키 슬롯', 'icon': Icons.casino, 'color': Colors.purple, 'players': '10.2k', 'avgEarning': 450},
    {'name': '코인 러쉬', 'icon': Icons.monetization_on, 'color': Colors.amber, 'players': '8.5k', 'avgEarning': 380},
    {'name': '카드 마스터', 'icon': Icons.style, 'color': Colors.green, 'players': '7.1k', 'avgEarning': 320},
  ];

  final List<Map<String, dynamic>> achievements = [
    {'name': '첫 승리', 'icon': Icons.flag, 'color': Colors.green, 'unlocked': true, 'reward': 500},
    {'name': '10연승', 'icon': Icons.local_fire_department, 'color': Colors.orange, 'unlocked': true, 'reward': 1000},
    {'name': '게임 마스터', 'icon': Icons.emoji_events, 'color': Colors.amber, 'unlocked': false, 'reward': 2000},
    {'name': '스피드런', 'icon': Icons.flash_on, 'color': Colors.blue, 'unlocked': false, 'reward': 1500},
  ];
}