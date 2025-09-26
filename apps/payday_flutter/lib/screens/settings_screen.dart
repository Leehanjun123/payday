import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../services/export_service.dart';
import '../providers/theme_provider.dart';
import '../main_test.dart';
import 'goals_screen.dart';
import 'notification_settings_screen.dart';
import 'onboarding_screen.dart';
import 'backup_restore_screen.dart';
import 'data_export_screen.dart';
import 'achievements_screen.dart';
import 'widget_preview_screen.dart';
import 'insights_dashboard_screen.dart';
import 'leaderboard_screen.dart';
import 'voice_assistant_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final ExportService _exportService = ExportService();

  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _currency = 'KRW';
  double _monthlyGoal = 1000000;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final notifications = await _databaseService.getSetting('notifications');
    final darkMode = await _databaseService.getSetting('darkMode');
    final currency = await _databaseService.getSetting('currency');
    final goal = await _databaseService.getSetting('monthlyGoal');

    setState(() {
      _notificationsEnabled = notifications == 'true';
      _darkModeEnabled = darkMode == 'true';
      _currency = currency ?? 'KRW';
      _monthlyGoal = double.tryParse(goal ?? '1000000') ?? 1000000;
    });
  }

  Future<void> _saveSetting(String key, String value) async {
    await _databaseService.saveSetting(key, value);
  }

  void _showGoalDialog() {
    final controller = TextEditingController(text: _monthlyGoal.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('월 목표 설정'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '목표 금액',
            prefixText: '₩ ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final newGoal = double.tryParse(controller.text.replaceAll(',', ''));
              if (newGoal != null && newGoal > 0) {
                setState(() => _monthlyGoal = newGoal);
                _saveSetting('monthlyGoal', newGoal.toString());
              }
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'PayDay',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 PayDay. All rights reserved.',
      children: [
        const SizedBox(height: 16),
        const Text(
          'PayDay는 모든 수익을 한 곳에서 관리할 수 있는 스마트한 수익 창출 플랫폼입니다.',
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => ExportDialog(exportService: _exportService),
    );
  }

  void _navigateToGoals() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GoalsScreen()),
    );
  }



  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모든 데이터 삭제'),
        content: const Text(
          '정말로 모든 수익 데이터를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement data deletion
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('데이터 삭제 기능이 곧 추가될 예정입니다'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '설정',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          _buildProfileSection(),
          _buildPreferencesSection(),
          _buildDataSection(),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '프로필',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                  child: Text(
                    '한준',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '한준님',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      'PayDay 사용자',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: Colors.grey[600]),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('프로필 편집 기능이 곧 추가될 예정입니다'),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '환경 설정',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            '알림',
            '수익 기록 및 목표 달성 알림',
            Icons.notifications,
            Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                _saveSetting('notifications', value.toString());
              },
            ),
          ),
          _buildSettingItem(
            '다크 모드',
            '어두운 테마 사용',
            Icons.dark_mode,
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) async {
                    await themeProvider.setThemeMode(
                      value ? ThemeMode.dark : ThemeMode.light
                    );
                    await _saveSetting('darkMode', value.toString());
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value ? '다크 모드가 활성화되었습니다' : '라이트 모드가 활성화되었습니다'
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
          _buildSettingItem(
            '월 목표',
            '₩${_monthlyGoal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
            Icons.flag,
            IconButton(
              icon: Icon(Icons.edit, color: Colors.grey[600]),
              onPressed: _showGoalDialog,
            ),
          ),
          _buildSettingItem(
            '목표 관리',
            '상세한 목표 설정 및 추적',
            Icons.track_changes,
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, color: Colors.grey[600]),
              onPressed: _navigateToGoals,
            ),
          ),
          _buildSettingItem(
            '통화',
            _currency == 'KRW' ? '한국 원 (₩)' : _currency,
            Icons.attach_money,
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, color: Colors.grey[600]),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('통화 설정 기능이 곧 추가될 예정입니다'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '데이터 관리',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            '데이터 내보내기',
            'CSV, JSON, HTML 형태로 내보내기',
            Icons.download,
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, color: Colors.grey[600]),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DataExportScreen(),
                  ),
                );
              },
            ),
          ),
          _buildSettingItem(
            '데이터 백업',
            '완전한 데이터 백업 생성',
            Icons.backup,
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, color: Colors.grey[600]),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('백업 기능이 곧 추가될 예정입니다'),
                  ),
                );
              },
            ),
          ),
          _buildSettingItem(
            '모든 데이터 삭제',
            '모든 수익 기록을 삭제합니다',
            Icons.delete_forever,
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.red),
              onPressed: _showDeleteConfirmation,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '정보',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            '앱 정보',
            '버전 1.0.0',
            Icons.info,
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, color: Colors.grey[600]),
              onPressed: _showAboutDialog,
            ),
          ),
          _buildSettingItem(
            '고객 지원',
            '문의사항이나 피드백',
            Icons.support,
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, color: Colors.grey[600]),
              onPressed: () {
                Share.share('PayDay 앱에 대한 문의사항이 있습니다.');
              },
            ),
          ),
          _buildSettingItem(
            '개인정보 처리방침',
            '개인정보 처리 방침 확인',
            Icons.privacy_tip,
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, color: Colors.grey[600]),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('개인정보 처리방침 기능이 곧 추가될 예정입니다'),
                  ),
                );
              },
            ),
          ),
          _buildSettingItem(
            '백업 & 복원',
            '데이터 백업 및 복원',
            Icons.cloud_sync,
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, color: Colors.grey[600]),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BackupRestoreScreen(),
                  ),
                );
              },
            ),
          ),
          _buildSettingItem(
            '알림 설정',
            '수익 목표 및 리마인더',
            Icons.notifications_outlined,
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, color: Colors.grey[600]),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationSettingsScreen(),
                  ),
                );
              },
            ),
          ),
          _buildSettingItem(
            '홈 화면 위젯',
            '홈 화면에 위젯을 추가하세요',
            Icons.widgets,
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, color: Colors.purple[600]),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WidgetPreviewScreen(),
                  ),
                );
              },
            ),
          ),
          _buildSettingItem(
            '업적 & 공유',
            '나의 성과를 확인하고 공유하세요',
            Icons.emoji_events,
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, color: Colors.amber[700]),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AchievementsScreen(),
                  ),
                );
              },
            ),
          ),
          _buildSettingItem(
            'AI 인사이트',
            '스마트 분석 및 예측',
            Icons.insights,
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, color: Colors.grey[600]),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InsightsDashboardScreen(),
                  ),
                );
              },
            ),
          ),
          _buildSettingItem(
            '커뮤니티 & 리더보드',
            '다른 사용자들과 경쟁하기',
            Icons.people,
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, color: Colors.grey[600]),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LeaderboardScreen(),
                  ),
                );
              },
            ),
          ),
          _buildSettingItem(
            'AI 음성 비서',
            '음성으로 수익 기록하기',
            Icons.mic,
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, color: Colors.blue[600]),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VoiceAssistantScreen(),
                  ),
                );
              },
            ),
          ),
          _buildSettingItem(
            '튜토리얼 다시보기',
            '온보딩 화면 재실행',
            Icons.replay,
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, color: Colors.grey[600]),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('onboarding_completed', false);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/onboarding',
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title, String subtitle, IconData icon, Widget? trailing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: Colors.grey[600], size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}

class ExportDialog extends StatefulWidget {
  final ExportService exportService;

  const ExportDialog({Key? key, required this.exportService}) : super(key: key);

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  bool _isLoading = true;
  Map<String, dynamic>? _summary;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final summary = await widget.exportService.getExportSummary();
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.download, color: Colors.blue[600]),
          const SizedBox(width: 12),
          const Text('데이터 내보내기'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        '요약 정보를 불러올 수 없습니다',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '내보낼 데이터 요약',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryRow('총 기록 수', '${_summary!['totalRecords']}건'),
                      _buildSummaryRow('총 수익', _formatAmount(_summary!['totalAmount'])),
                      if (_summary!['oldestRecord'] != null)
                        _buildSummaryRow('최초 기록', _summary!['oldestRecord']),
                      if (_summary!['newestRecord'] != null)
                        _buildSummaryRow('최근 기록', _summary!['newestRecord']),
                      const SizedBox(height: 16),
                      const Text(
                        '분류별 수익',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...(_summary!['typeBreakdown'] as Map<String, double>)
                          .entries
                          .take(5)
                          .map((entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      _formatAmount(entry.value),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                      if ((_summary!['typeBreakdown'] as Map).length > 5)
                        Text(
                          '외 ${(_summary!['typeBreakdown'] as Map).length - 5}개 분류',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        if (!_isLoading && _error == null) ...[
          ElevatedButton.icon(
            onPressed: () => _exportCsv(context),
            icon: const Icon(Icons.table_chart, size: 18),
            label: const Text('CSV 내보내기'),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    return '₩${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  Future<void> _exportCsv(BuildContext context) async {
    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('CSV 파일을 생성하고 있습니다...'),
            ],
          ),
        ),
      );

      await widget.exportService.exportAndShare();

      // 로딩 다이얼로그 닫기
      Navigator.pop(context);
      // 내보내기 다이얼로그 닫기
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('데이터가 성공적으로 내보내졌습니다!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // 로딩 다이얼로그 닫기 (에러 발생시)
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('내보내기 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

}