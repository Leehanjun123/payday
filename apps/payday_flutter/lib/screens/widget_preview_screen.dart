import 'package:flutter/material.dart';
import '../services/widget_service.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class WidgetPreviewScreen extends StatefulWidget {
  const WidgetPreviewScreen({Key? key}) : super(key: key);

  @override
  State<WidgetPreviewScreen> createState() => _WidgetPreviewScreenState();
}

class _WidgetPreviewScreenState extends State<WidgetPreviewScreen>
    with TickerProviderStateMixin {
  final WidgetService _widgetService = WidgetService();
  final NumberFormat _currencyFormatter = NumberFormat('#,###');

  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;

  WidgetType _selectedType = WidgetType.summary;
  WidgetSize _selectedSize = WidgetSize.medium;
  String _selectedTheme = 'blue';
  bool _showLabels = true;
  bool _showTrend = true;

  WidgetData? _widgetData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _loadWidgetData();
  }

  Future<void> _loadWidgetData() async {
    setState(() => _isLoading = true);

    try {
      // 새로운 위젯 데이터 생성
      final data = await _widgetService.generateWidgetData();

      // 기존 설정 로드
      final config = await _widgetService.loadWidgetConfig();
      if (config != null) {
        setState(() {
          _selectedType = WidgetType.values[config['type'] ?? 0];
          _selectedSize = WidgetSize.values[config['size'] ?? 1];
          _showLabels = config['showLabels'] ?? true;
          _showTrend = config['showTrend'] ?? true;
        });
      }

      setState(() {
        _widgetData = data;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('위젯 데이터 로드 실패: $e')),
        );
      }
    }
  }

  Future<void> _saveWidgetConfig() async {
    await _widgetService.saveWidgetConfig(
      type: _selectedType,
      size: _selectedSize,
      primaryColor: WidgetService.widgetThemes[_selectedTheme]![0],
      secondaryColor: WidgetService.widgetThemes[_selectedTheme]![1],
      showLabels: _showLabels,
      showTrend: _showTrend,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('위젯 설정이 저장되었습니다'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('홈 화면 위젯'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWidgetData,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveWidgetConfig,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPreviewSection(isDark),
                    const SizedBox(height: 24),
                    _buildTypeSelector(isDark),
                    const SizedBox(height: 20),
                    _buildSizeSelector(isDark),
                    const SizedBox(height: 20),
                    _buildThemeSelector(isDark),
                    const SizedBox(height: 20),
                    _buildOptionsSection(isDark),
                    const SizedBox(height: 24),
                    _buildInstructions(isDark),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPreviewSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade100,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '위젯 미리보기',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: _buildWidgetPreview(),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetPreview() {
    if (_widgetData == null) return const SizedBox();

    double width;
    double height;

    switch (_selectedSize) {
      case WidgetSize.small:
        width = 150;
        height = 150;
        break;
      case WidgetSize.medium:
        width = 320;
        height = 150;
        break;
      case WidgetSize.large:
        width = 320;
        height = 320;
        break;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: WidgetService.widgetThemes[_selectedTheme]!,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: WidgetService.widgetThemes[_selectedTheme]![0]
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: _getWidgetContent(),
    );
  }

  Widget _getWidgetContent() {
    switch (_selectedType) {
      case WidgetType.summary:
        return _buildSummaryWidget();
      case WidgetType.goal:
        return _buildGoalWidget();
      case WidgetType.chart:
        return _buildChartWidget();
      case WidgetType.quick:
        return _buildQuickWidget();
      case WidgetType.motivation:
        return _buildMotivationWidget();
    }
  }

  Widget _buildSummaryWidget() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.dashboard, color: Colors.white, size: 24),
              if (_showTrend && _widgetData!.trend != 'stable')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _widgetData!.trend == 'up'
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_widgetData!.trendPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (_selectedSize != WidgetSize.small) ...[
            _buildSummaryRow(
              '오늘',
              '₩${_currencyFormatter.format(_widgetData!.todayIncome)}',
            ),
            _buildSummaryRow(
              '이번 주',
              '₩${_currencyFormatter.format(_widgetData!.weekIncome)}',
            ),
          ],
          _buildSummaryRow(
            _selectedSize == WidgetSize.small ? '이번달' : '이번 달',
            '₩${_currencyFormatter.format(_widgetData!.monthIncome)}',
            isHighlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_showLabels)
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: _selectedSize == WidgetSize.small ? 12 : 14,
            ),
          ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isHighlight
                ? (_selectedSize == WidgetSize.small ? 16 : 20)
                : (_selectedSize == WidgetSize.small ? 14 : 16),
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalWidget() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flag, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            _widgetData!.goalTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: _widgetData!.goalProgress,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 8,
                ),
              ),
              Text(
                '${(_widgetData!.goalProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (_showLabels) ...[
            const SizedBox(height: 12),
            Text(
              '₩${_currencyFormatter.format(_widgetData!.goalAmount)}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChartWidget() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.show_chart, color: Colors.white, size: 24),
              Text(
                '주간 차트',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _widgetData!.weekChart
                    .map((p) => p.amount)
                    .reduce((a, b) => a > b ? a : b) * 1.2,
                barGroups: _widgetData!.weekChart.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.amount,
                        color: Colors.white.withOpacity(0.8),
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  show: _showLabels,
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < _widgetData!.weekChart.length) {
                          return Text(
                            _widgetData!.weekChart[value.toInt()].day,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickWidget() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '빠른 수익 기록',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_showLabels) ...[
            const SizedBox(height: 8),
            Text(
              '탭하여 앱 열기',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMotivationWidget() {
    final message = _widgetService.getMotivationalMessage(_widgetData!);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.emoji_emotions,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (_showLabels) ...[
            const SizedBox(height: 12),
            Text(
              _widgetData!.lastUpdate,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '위젯 종류',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WidgetType.values.map((type) {
              final isSelected = _selectedType == type;
              return ChoiceChip(
                label: Text(WidgetService.getWidgetTitle(type)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedType = type;
                  });
                },
                avatar: Icon(
                  WidgetService.getWidgetIcon(type),
                  size: 18,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '위젯 크기',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSizeOption(WidgetSize.small, '2x2', Icons.crop_square),
              const SizedBox(width: 8),
              _buildSizeOption(WidgetSize.medium, '4x2', Icons.crop_16_9),
              const SizedBox(width: 8),
              _buildSizeOption(WidgetSize.large, '4x4', Icons.crop_din),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSizeOption(WidgetSize size, String label, IconData icon) {
    final isSelected = _selectedSize == size;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedSize = size),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blue.withOpacity(0.1)
                : Colors.grey.withOpacity(0.05),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.blue : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '색상 테마',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: WidgetService.widgetThemes.entries.map((entry) {
                final isSelected = _selectedTheme == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () => setState(() => _selectedTheme = entry.key),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: entry.value,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: entry.value[0].withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '표시 옵션',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('라벨 표시'),
            subtitle: const Text('위젯에 텍스트 라벨을 표시합니다'),
            value: _showLabels,
            onChanged: (value) => setState(() => _showLabels = value),
            activeColor: Colors.blue,
          ),
          SwitchListTile(
            title: const Text('트렌드 표시'),
            subtitle: const Text('상승/하락 트렌드를 표시합니다'),
            value: _showTrend,
            onChanged: (value) => setState(() => _showTrend = value),
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                '위젯 추가 방법',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionStep('1. 홈 화면 길게 누르기'),
          _buildInstructionStep('2. 위젯 추가 선택'),
          _buildInstructionStep('3. PayDay 위젯 검색'),
          _buildInstructionStep('4. 원하는 크기 선택 후 추가'),
          const SizedBox(height: 12),
          Text(
            '위젯은 자동으로 업데이트되며, 탭하면 앱이 실행됩니다.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.blue[600]),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[800],
            ),
          ),
        ],
      ),
    );
  }
}