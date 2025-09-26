import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/dashboard_widget_service.dart';
import 'dart:math' as math;

class SmartDashboardScreen extends StatefulWidget {
  const SmartDashboardScreen({Key? key}) : super(key: key);

  @override
  State<SmartDashboardScreen> createState() => _SmartDashboardScreenState();
}

class _SmartDashboardScreenState extends State<SmartDashboardScreen>
    with TickerProviderStateMixin {
  final DashboardWidgetService _dashboardService = DashboardWidgetService();

  // 애니메이션 컨트롤러
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  late AnimationController _pulseController;

  // 상태
  List<DashboardWidget> _widgets = [];
  bool _isEditMode = false;
  bool _isLoading = true;
  String _selectedTimeRange = '주간';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeDashboard();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  Future<void> _initializeDashboard() async {
    await _dashboardService.initialize();

    _dashboardService.widgetStream.listen((widgets) {
      if (mounted) {
        setState(() {
          _widgets = widgets;
          _isLoading = false;
        });
      }
    });

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _rotateController.dispose();
    _pulseController.dispose();
    _dashboardService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 앱바
          _buildSliverAppBar(theme, isDark),

          // 대시보드 그리드
          if (_isLoading)
            SliverFillRemaining(
              child: _buildLoadingState(theme),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: _buildDashboardGrid(theme, isDark),
            ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(theme),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme, bool isDark) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: isDark ? Colors.grey[900] : Colors.blue[600],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          '스마트 대시보드',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // 그라데이션 배경
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
              ),
            ),

            // 애니메이션 패턴
            AnimatedBuilder(
              animation: _rotateController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotateController.value * 2 * math.pi,
                  child: CustomPaint(
                    painter: _PatternPainter(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                );
              },
            ),

            // 시간 범위 선택
            Positioned(
              bottom: 50,
              right: 20,
              child: _buildTimeRangeSelector(),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_isEditMode ? Icons.done : Icons.edit),
          onPressed: () {
            setState(() {
              _isEditMode = !_isEditMode;
            });
            HapticFeedback.lightImpact();
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () async {
            await _dashboardService.initialize();
            HapticFeedback.lightImpact();
          },
        ),
      ],
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['오늘', '주간', '월간'].map((range) {
          final isSelected = _selectedTimeRange == range;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTimeRange = range;
              });
              HapticFeedback.selectionClick();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                range,
                style: TextStyle(
                  color: isSelected ? Colors.blue[600] : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDashboardGrid(ThemeData theme, bool isDark) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final widget = _widgets[index];
          return _buildDashboardWidget(widget, theme, isDark, index);
        },
        childCount: _widgets.length,
      ),
    );
  }

  Widget _buildDashboardWidget(
    DashboardWidget widget,
    ThemeData theme,
    bool isDark,
    int index,
  ) {
    // 위젯 크기에 따른 GridTile 설정
    final isLarge = widget.size.width > 1 || widget.size.height > 1;

    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: _fadeController,
            curve: Interval(
              index * 0.1,
              1.0,
              curve: Curves.easeOut,
            ),
          ),
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: _scaleController,
              curve: Interval(
                index * 0.05,
                1.0,
                curve: Curves.elasticOut,
              ),
            ),
            child: _buildWidgetContent(widget, theme, isDark, isLarge),
          ),
        );
      },
    );
  }

  Widget _buildWidgetContent(
    DashboardWidget widget,
    ThemeData theme,
    bool isDark,
    bool isLarge,
  ) {
    if (!widget.isVisible && !_isEditMode) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _onWidgetTap(widget),
      onLongPress: _isEditMode ? () => _onWidgetLongPress(widget) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.color.withOpacity(isDark ? 0.3 : 0.1),
              widget.color.withOpacity(isDark ? 0.2 : 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            // 메인 컨텐츠
            Padding(
              padding: const EdgeInsets.all(16),
              child: _getWidgetContent(widget, theme, isDark),
            ),

            // 편집 모드 오버레이
            if (_isEditMode)
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: Icon(
                    widget.isVisible ? Icons.visibility : Icons.visibility_off,
                    size: 18,
                  ),
                  onPressed: () {
                    _dashboardService.toggleWidgetVisibility(widget.id);
                    HapticFeedback.lightImpact();
                  },
                ),
              ),

            // 업데이트 인디케이터
            Positioned(
              bottom: 8,
              right: 8,
              child: _buildUpdateIndicator(widget),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getWidgetContent(DashboardWidget widget, ThemeData theme, bool isDark) {
    switch (widget.type) {
      case DashboardWidgetType.totalIncome:
        return _buildTotalIncomeWidget(widget, theme);

      case DashboardWidgetType.todayIncome:
        return _buildTodayIncomeWidget(widget, theme);

      case DashboardWidgetType.weeklyChart:
        return _buildWeeklyChartWidget(widget, theme);

      case DashboardWidgetType.monthlyChart:
        return _buildMonthlyChartWidget(widget, theme);

      case DashboardWidgetType.goalProgress:
        return _buildGoalProgressWidget(widget, theme);

      case DashboardWidgetType.streakCounter:
        return _buildStreakWidget(widget, theme);

      case DashboardWidgetType.incomeDistribution:
        return _buildDistributionWidget(widget, theme);

      case DashboardWidgetType.growthRate:
        return _buildGrowthRateWidget(widget, theme);

      case DashboardWidgetType.quickStats:
        return _buildQuickStatsWidget(widget, theme);

      case DashboardWidgetType.aiPrediction:
        return _buildAIPredictionWidget(widget, theme);

      case DashboardWidgetType.topSources:
        return _buildTopSourcesWidget(widget, theme);

      case DashboardWidgetType.timeAnalysis:
        return _buildTimeAnalysisWidget(widget, theme);
    }
  }

  // 위젯별 컨텐츠 빌더들
  Widget _buildTotalIncomeWidget(DashboardWidget widget, ThemeData theme) {
    final data = widget.data;
    final total = data['total'] ?? 0.0;
    final change = data['change'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(widget.icon, color: widget.color, size: 24),
            const SizedBox(width: 8),
            Text(
              widget.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          data['formatted'] ?? '0원',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: widget.color,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              change > 0 ? Icons.trending_up : Icons.trending_down,
              color: change > 0 ? Colors.green : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '${change.abs().toStringAsFixed(1)}%',
              style: TextStyle(
                color: change > 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodayIncomeWidget(DashboardWidget widget, ThemeData theme) {
    final data = widget.data;
    final amount = data['amount'] ?? 0.0;
    final count = data['count'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(widget.icon, color: widget.color, size: 20),
        const SizedBox(height: 8),
        Text(
          widget.title,
          style: theme.textTheme.bodySmall,
        ),
        const Spacer(),
        Text(
          data['formatted'] ?? '0원',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: widget.color,
          ),
        ),
        Text(
          '$count건',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildWeeklyChartWidget(DashboardWidget widget, ThemeData theme) {
    final chartData = widget.data['chartData'] as List<ChartDataPoint>? ?? [];

    if (chartData.isEmpty) {
      return _buildEmptyChart(widget, theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(widget.icon, color: widget.color, size: 20),
            const SizedBox(width: 8),
            Text(widget.title, style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: BarChart(
            BarChartData(
              barGroups: chartData.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.value,
                      color: entry.value.color,
                      width: 12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() < chartData.length) {
                        return Text(
                          chartData[value.toInt()].label,
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const SizedBox();
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
    );
  }

  Widget _buildMonthlyChartWidget(DashboardWidget widget, ThemeData theme) {
    final chartData = widget.data['chartData'] as List<ChartDataPoint>? ?? [];
    final total = widget.data['total'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(widget.icon, color: widget.color, size: 20),
            const SizedBox(width: 8),
            Text(widget.title, style: theme.textTheme.bodySmall),
          ],
        ),
        const Spacer(),
        Text(
          '${(total / 10000).toStringAsFixed(1)}만원',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: chartData.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value.value);
                  }).toList(),
                  isCurved: true,
                  color: widget.color,
                  barWidth: 2,
                  dotData: FlDotData(show: false),
                ),
              ],
              titlesData: FlTitlesData(show: false),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalProgressWidget(DashboardWidget widget, ThemeData theme) {
    final progress = widget.data['progress'] ?? 0.0;
    final message = widget.data['message'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(widget.icon, color: widget.color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.title,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const Spacer(),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: progress / 100,
                strokeWidth: 8,
                backgroundColor: widget.color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(widget.color),
              ),
            ),
            Text(
              '${progress.toStringAsFixed(0)}%',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: widget.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          message,
          style: theme.textTheme.bodySmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStreakWidget(DashboardWidget widget, ThemeData theme) {
    final current = widget.data['current'] ?? 0;
    final badge = widget.data['badge'] ?? '🌱';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(badge, style: const TextStyle(fontSize: 36)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_fire_department, color: widget.color, size: 20),
            const SizedBox(width: 4),
            Text(
              '$current일',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          '연속 기록',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildDistributionWidget(DashboardWidget widget, ThemeData theme) {
    final chartData = widget.data['chartData'] as List<ChartDataPoint>? ?? [];

    if (chartData.isEmpty) {
      return _buildEmptyChart(widget, theme);
    }

    return Column(
      children: [
        Row(
          children: [
            Icon(widget.icon, color: widget.color, size: 20),
            const SizedBox(width: 8),
            Text(widget.title, style: theme.textTheme.bodySmall),
          ],
        ),
        const Spacer(),
        ...chartData.map((data) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: data.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    data.label,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${(data.value / 10000).toStringAsFixed(0)}만',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildGrowthRateWidget(DashboardWidget widget, ThemeData theme) {
    final rate = widget.data['rate'] ?? 0.0;
    final icon = widget.data['icon'] ?? Icons.trending_flat;
    final color = widget.data['color'] ?? Colors.grey;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 48),
        const SizedBox(height: 8),
        Text(
          '${rate > 0 ? '+' : ''}${rate.toStringAsFixed(1)}%',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          '성장률',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildQuickStatsWidget(DashboardWidget widget, ThemeData theme) {
    final stats = [
      {'label': '기록일수', 'value': widget.data['totalDays'] ?? 0},
      {'label': '일평균', 'value': '${((widget.data['averageDaily'] ?? 0) / 10000).toStringAsFixed(1)}만'},
      {'label': '최고기록', 'value': '${((widget.data['bestDay'] ?? 0) / 10000).toStringAsFixed(1)}만'},
      {'label': '수익원', 'value': widget.data['totalSources'] ?? 0},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(widget.icon, color: widget.color, size: 20),
        const SizedBox(height: 8),
        ...stats.map((stat) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  stat['label'] as String,
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  '${stat['value']}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildAIPredictionWidget(DashboardWidget widget, ThemeData theme) {
    final confidence = widget.data['confidence'] ?? 0.0;
    final nextWeek = widget.data['nextWeek'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(
                      0.2 + _pulseController.value * 0.3,
                    ),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: Colors.blue,
                    size: 16,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            Text('AI 예측', style: theme.textTheme.bodySmall),
          ],
        ),
        const Spacer(),
        Text(
          '다음주 예상',
          style: theme.textTheme.bodySmall,
        ),
        Text(
          '${(nextWeek / 10000).toStringAsFixed(1)}만원',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: confidence / 100,
          backgroundColor: Colors.blue.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        Text(
          '신뢰도 ${confidence.toStringAsFixed(0)}%',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildTopSourcesWidget(DashboardWidget widget, ThemeData theme) {
    final sources = widget.data['sources'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(widget.icon, color: widget.color, size: 20),
            const SizedBox(width: 8),
            Text(widget.title, style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: math.min(3, sources.length),
            itemBuilder: (context, index) {
              final source = sources[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text(
                      '${index + 1}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        source['name'],
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${(source['amount'] / 10000).toStringAsFixed(0)}만',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeAnalysisWidget(DashboardWidget widget, ThemeData theme) {
    final bestHour = widget.data['bestHour'] ?? 0;
    final bestDay = widget.data['bestDay'] ?? '월';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(widget.icon, color: widget.color, size: 24),
        const SizedBox(height: 8),
        Text(
          '최고 생산성',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                Icon(Icons.access_time, size: 16, color: widget.color),
                Text(
                  '$bestHour시',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Icon(Icons.calendar_today, size: 16, color: widget.color),
                Text(
                  bestDay,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyChart(DashboardWidget widget, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_chart_outlined,
            size: 48,
            color: Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 8),
          Text(
            '데이터 없음',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateIndicator(DashboardWidget widget) {
    final now = DateTime.now();
    final diff = now.difference(widget.lastUpdated);

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: diff.inSeconds < 10
                ? Colors.green.withOpacity(0.5 + _pulseController.value * 0.5)
                : Colors.grey.withOpacity(0.3),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _rotateController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateController.value * 2 * math.pi,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.dashboard,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            '대시보드 로딩 중...',
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(ThemeData theme) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + _pulseController.value * 0.1,
          child: FloatingActionButton(
            onPressed: _showWidgetSelector,
            backgroundColor: theme.colorScheme.primary,
            child: const Icon(Icons.add_chart),
          ),
        );
      },
    );
  }

  // 이벤트 핸들러
  void _onWidgetTap(DashboardWidget widget) {
    HapticFeedback.lightImpact();
    // 상세 화면으로 이동
    _showWidgetDetails(widget);
  }

  void _onWidgetLongPress(DashboardWidget widget) {
    HapticFeedback.mediumImpact();
    // 위젯 설정 다이얼로그
    _showWidgetSettings(widget);
  }

  void _showWidgetSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WidgetSelectorSheet(
        dashboardService: _dashboardService,
      ),
    );
  }

  void _showWidgetDetails(DashboardWidget widget) {
    showDialog(
      context: context,
      builder: (context) => _WidgetDetailDialog(widget: widget),
    );
  }

  void _showWidgetSettings(DashboardWidget widget) {
    showDialog(
      context: context,
      builder: (context) => _WidgetSettingsDialog(
        widget: widget,
        dashboardService: _dashboardService,
      ),
    );
  }
}

// 패턴 페인터
class _PatternPainter extends CustomPainter {
  final Color color;

  _PatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path();

    // 기하학적 패턴 그리기
    for (int i = 0; i < 5; i++) {
      final radius = size.width * (0.2 + i * 0.15);
      path.addOval(Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: radius,
      ));
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 위젯 선택 시트
class _WidgetSelectorSheet extends StatelessWidget {
  final DashboardWidgetService dashboardService;

  const _WidgetSelectorSheet({required this.dashboardService});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '위젯 추가',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: DashboardWidgetType.values.map((type) {
                return ListTile(
                  leading: Icon(_getIconForType(type)),
                  title: Text(_getTitleForType(type)),
                  subtitle: Text(_getDescriptionForType(type)),
                  onTap: () {
                    // 위젯 추가 로직
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(DashboardWidgetType type) {
    switch (type) {
      case DashboardWidgetType.totalIncome:
        return Icons.account_balance_wallet;
      case DashboardWidgetType.todayIncome:
        return Icons.today;
      case DashboardWidgetType.weeklyChart:
        return Icons.bar_chart;
      case DashboardWidgetType.monthlyChart:
        return Icons.show_chart;
      case DashboardWidgetType.goalProgress:
        return Icons.flag;
      case DashboardWidgetType.streakCounter:
        return Icons.local_fire_department;
      case DashboardWidgetType.incomeDistribution:
        return Icons.pie_chart;
      case DashboardWidgetType.growthRate:
        return Icons.trending_up;
      case DashboardWidgetType.quickStats:
        return Icons.speed;
      case DashboardWidgetType.aiPrediction:
        return Icons.auto_awesome;
      case DashboardWidgetType.topSources:
        return Icons.star;
      case DashboardWidgetType.timeAnalysis:
        return Icons.access_time;
    }
  }

  String _getTitleForType(DashboardWidgetType type) {
    switch (type) {
      case DashboardWidgetType.totalIncome:
        return '총 수익';
      case DashboardWidgetType.todayIncome:
        return '오늘 수익';
      case DashboardWidgetType.weeklyChart:
        return '주간 차트';
      case DashboardWidgetType.monthlyChart:
        return '월간 차트';
      case DashboardWidgetType.goalProgress:
        return '목표 진행률';
      case DashboardWidgetType.streakCounter:
        return '연속 기록';
      case DashboardWidgetType.incomeDistribution:
        return '수익 분포';
      case DashboardWidgetType.growthRate:
        return '성장률';
      case DashboardWidgetType.quickStats:
        return '빠른 통계';
      case DashboardWidgetType.aiPrediction:
        return 'AI 예측';
      case DashboardWidgetType.topSources:
        return '상위 수익원';
      case DashboardWidgetType.timeAnalysis:
        return '시간대 분석';
    }
  }

  String _getDescriptionForType(DashboardWidgetType type) {
    switch (type) {
      case DashboardWidgetType.totalIncome:
        return '전체 수익 요약';
      case DashboardWidgetType.todayIncome:
        return '오늘의 수익 현황';
      case DashboardWidgetType.weeklyChart:
        return '주간 수익 차트';
      case DashboardWidgetType.monthlyChart:
        return '월간 수익 추이';
      case DashboardWidgetType.goalProgress:
        return '목표 달성 현황';
      case DashboardWidgetType.streakCounter:
        return '연속 기록일수';
      case DashboardWidgetType.incomeDistribution:
        return '수익원별 분포';
      case DashboardWidgetType.growthRate:
        return '전월 대비 성장률';
      case DashboardWidgetType.quickStats:
        return '주요 통계 요약';
      case DashboardWidgetType.aiPrediction:
        return 'AI 기반 예측';
      case DashboardWidgetType.topSources:
        return '상위 수익원 순위';
      case DashboardWidgetType.timeAnalysis:
        return '생산성 시간 분석';
    }
  }
}

// 위젯 상세 다이얼로그
class _WidgetDetailDialog extends StatelessWidget {
  final DashboardWidget widget;

  const _WidgetDetailDialog({required this.widget});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 48, color: widget.color),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // 상세 정보 표시
            Text(
              '마지막 업데이트: ${_formatTime(widget.lastUpdated)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return '방금 전';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 전';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}시간 전';
    } else {
      return '${diff.inDays}일 전';
    }
  }
}

// 위젯 설정 다이얼로그
class _WidgetSettingsDialog extends StatelessWidget {
  final DashboardWidget widget;
  final DashboardWidgetService dashboardService;

  const _WidgetSettingsDialog({
    required this.widget,
    required this.dashboardService,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.title} 설정',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('위젯 표시'),
              value: widget.isVisible,
              onChanged: (value) {
                dashboardService.toggleWidgetVisibility(widget.id);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('위젯 제거'),
              onTap: () {
                // 위젯 제거 로직
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}