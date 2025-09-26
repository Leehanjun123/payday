import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class ShareAchievementCard extends StatefulWidget {
  final double totalAmount;
  final String period;
  final Map<String, double> topCategories;
  final int totalDays;

  const ShareAchievementCard({
    Key? key,
    required this.totalAmount,
    required this.period,
    required this.topCategories,
    required this.totalDays,
  }) : super(key: key);

  @override
  State<ShareAchievementCard> createState() => _ShareAchievementCardState();
}

class _ShareAchievementCardState extends State<ShareAchievementCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _rotateAnimation = Tween<double>(
      begin: -0.1,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '₩${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '₩${(amount / 1000).toStringAsFixed(0)}K';
    }
    return '₩${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotateAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue[600]!,
                    Colors.purple[600]!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildAmountDisplay(),
                  const SizedBox(height: 20),
                  _buildStats(),
                  const SizedBox(height: 24),
                  _buildTopCategories(),
                  const SizedBox(height: 24),
                  _buildShareButtons(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.emoji_events,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.period} 수익 달성!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'PayDay와 함께한 ${widget.totalDays}일',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            '총 수익',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatAmount(widget.totalAmount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final dailyAvg = widget.totalDays > 0
        ? widget.totalAmount / widget.totalDays
        : 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(
          Icons.calendar_today,
          '${widget.totalDays}일',
          '활동 일수',
        ),
        _buildStatItem(
          Icons.trending_up,
          _formatAmount(dailyAvg.toDouble()),
          '일 평균',
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTopCategories() {
    final sortedCategories = widget.topCategories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topThree = sortedCategories.take(3).toList();

    if (topThree.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Text(
          'TOP 수익원',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...topThree.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          final medals = ['🥇', '🥈', '🥉'];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  medals[index],
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.key,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  _formatAmount(category.value),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildShareButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _shareText,
          icon: const Icon(Icons.share),
          label: const Text('공유하기'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue[700],
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '#PayDay #수익관리 #부업수익',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _shareText() {
    final dailyAvg = widget.totalDays > 0
        ? widget.totalAmount / widget.totalDays
        : 0;

    final shareText = '''
🎉 ${widget.period} PayDay 수익 리포트 🎉

💰 총 수익: ${_formatAmount(widget.totalAmount)}
📅 활동 일수: ${widget.totalDays}일
📈 일 평균: ${_formatAmount(dailyAvg.toDouble())}

🏆 TOP 3 수익원
${_getTop3Text()}

PayDay와 함께 스마트한 수익 관리를 시작하세요!
#PayDay #수익관리 #부업수익 #재테크
''';

    Share.share(shareText);
  }

  String _getTop3Text() {
    final sortedCategories = widget.topCategories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topThree = sortedCategories.take(3).toList();
    final medals = ['🥇', '🥈', '🥉'];

    return topThree.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      return '${medals[index]} ${category.key}: ${_formatAmount(category.value)}';
    }).join('\n');
  }
}