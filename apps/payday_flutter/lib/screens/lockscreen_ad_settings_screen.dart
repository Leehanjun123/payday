import 'package:flutter/material.dart';
import '../services/lockscreen_ad_service.dart';
import '../services/enhanced_cash_service.dart';
import 'package:intl/intl.dart';

class LockscreenAdSettingsScreen extends StatefulWidget {
  const LockscreenAdSettingsScreen({Key? key}) : super(key: key);

  @override
  State<LockscreenAdSettingsScreen> createState() => _LockscreenAdSettingsScreenState();
}

class _LockscreenAdSettingsScreenState extends State<LockscreenAdSettingsScreen>
    with SingleTickerProviderStateMixin {
  final LockscreenAdService _adService = LockscreenAdService();
  final EnhancedCashService _cashService = EnhancedCashService();
  final NumberFormat _numberFormat = NumberFormat('#,###', 'ko_KR');

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  bool _isEnabled = false;
  int _selectedMultiplier = 1;
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _adService.initialize();
    final stats = await _adService.getStatistics();

    setState(() {
      _isEnabled = _adService.isEnabled;
      _selectedMultiplier = _adService.multiplier;
      _statistics = stats;
    });

    if (_isEnabled) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('잠금화면 광고 설정'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 메인 토글
            _buildMainToggle(),

            // 수익 극대화 안내
            _buildRevenueBoostInfo(),

            // 배수 선택 (활성화된 경우만)
            if (_isEnabled) ...[
              _buildMultiplierSelection(),
              _buildExpectedEarnings(),
              _buildStatistics(),
            ],

            // 하단 안내
            _buildBottomInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainToggle() {
    return Container(
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '잠금화면 광고',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    if (_isEnabled)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Text(
                          'ON',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  _isEnabled
                    ? '앱 시작 시 광고를 표시합니다'
                    : '활성화하면 수익이 최대 5배!',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isEnabled,
            onChanged: (value) async {
              await _adService.setEnabled(value);
              setState(() {
                _isEnabled = value;
              });

              if (value) {
                _animationController.forward();
                _showActivationBonus();
              } else {
                _animationController.reverse();
              }
            },
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueBoostInfo() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height: _isEnabled ? 0 : null,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange[400]!, Colors.red[400]!],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.trending_up,
              color: Colors.white,
              size: 32,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '수익 극대화 TIP! 🔥',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '잠금화면 광고를 켜면\n월 최대 15,000원까지 벌 수 있어요!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiplierSelection() {
    return ScaleTransition(
      scale: _scaleAnimation,
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
              '수익 배수 선택',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ...LockscreenAdService.MULTIPLIER_BENEFITS.entries.map((entry) {
              final multiplier = entry.key;
              final benefit = entry.value;
              final isSelected = _selectedMultiplier == multiplier;

              return GestureDetector(
                onTap: () async {
                  await _adService.setMultiplier(multiplier);
                  setState(() {
                    _selectedMultiplier = multiplier;
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[50] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.blue : Colors.grey[400],
                        ),
                        child: isSelected
                          ? Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${multiplier}x',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.blue : Colors.black,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  benefit,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              '예상 수익: ${_numberFormat.format(
                                LockscreenAdService.EXPECTED_EARNINGS[multiplier]
                              )}원/월',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.green[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (multiplier > 1)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '광고 ${multiplier - 1}개',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildExpectedEarnings() {
    final monthlyEarning = LockscreenAdService.EXPECTED_EARNINGS[_selectedMultiplier] ?? 0;
    final dailyEarning = monthlyEarning ~/ 30;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[400]!, Colors.green[600]!],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '예상 수익',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text(
                    '일일',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${_numberFormat.format(dailyEarning)}원',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white30,
              ),
              Column(
                children: [
                  Text(
                    '월간',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${_numberFormat.format(monthlyEarning)}원',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white30,
              ),
              Column(
                children: [
                  Text(
                    '연간',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${_numberFormat.format(monthlyEarning * 12)}원',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return Container(
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
            '오늘의 광고 현황',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '시청한 광고',
                '${_statistics['today_ads'] ?? 0}개',
                Icons.play_circle_outline,
                Colors.blue,
              ),
              _buildStatItem(
                '남은 광고',
                '${_adService.remainingAds}개',
                Icons.schedule,
                Colors.orange,
              ),
              _buildStatItem(
                '총 수익',
                '${_numberFormat.format(_statistics['total_cash'] ?? 0)}원',
                Icons.monetization_on,
                Colors.green,
              ),
            ],
          ),
          SizedBox(height: 16),
          LinearProgressIndicator(
            value: (_statistics['today_ads'] ?? 0) /
                   (LockscreenAdService.MAX_DAILY_ADS),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          SizedBox(height: 8),
          Text(
            '일일 한도: ${LockscreenAdService.MAX_DAILY_ADS}개',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomInfo() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              SizedBox(width: 8),
              Text(
                '안내사항',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• 잠금화면 광고는 앱을 실행할 때 표시됩니다\n'
            '• 광고 시청 후 자동으로 포인트가 적립됩니다\n'
            '• 배수가 높을수록 더 많은 광고를 시청합니다\n'
            '• 일일 한도 초과 시 다음날 다시 시청 가능합니다',
            style: TextStyle(
              color: Colors.blue[600],
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showActivationBonus() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.celebration, color: Colors.white),
            SizedBox(width: 8),
            Text('잠금화면 광고 활성화! 100원 보너스 지급! 💵'),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
}