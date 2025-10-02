import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'income_service.dart';
import 'data_service.dart';

class BackupService {
  final IncomeServiceInterface _incomeService = IncomeServiceProvider.instance;
  final DataService _databaseService = DataService();

  Future<String> createFullBackup() async {
    try {
      // 모든 데이터 수집
      final incomes = await _incomeService.getAllIncomes();
      final goals = await _databaseService.getAllGoals();
      final settings = await _getAllSettings();

      // 백업 데이터 구조 생성
      final backupData = {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'data': {
          'incomes': incomes,
          'goals': goals,
          'settings': settings,
        },
        'metadata': {
          'totalIncomes': incomes.length,
          'totalGoals': goals.length,
          'appVersion': '1.0.0',
        }
      };

      // 파일에 저장
      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final fileName = 'PayDay_백업_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.json';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(
        JsonEncoder.withIndent('  ').convert(backupData),
        encoding: utf8
      );

      return file.path;
    } catch (e) {
      throw Exception('백업 생성 실패: $e');
    }
  }

  Future<void> restoreFromBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('백업 파일을 찾을 수 없습니다');
      }

      final content = await file.readAsString(encoding: utf8);
      final backupData = jsonDecode(content);

      // 백업 데이터 검증
      if (!_validateBackupData(backupData)) {
        throw Exception('유효하지 않은 백업 파일입니다');
      }

      // 기존 데이터 백업 (안전장치)
      await _createSafetyBackup();

      // 데이터 복원
      await _restoreIncomes(backupData['data']['incomes']);
      await _restoreGoals(backupData['data']['goals']);
      await _restoreSettings(backupData['data']['settings']);

    } catch (e) {
      throw Exception('백업 복원 실패: $e');
    }
  }

  Future<Map<String, String>> _getAllSettings() async {
    try {
      // 모든 설정 키들
      final settingKeys = [
        'notifications',
        'darkMode',
        'currency',
        'monthlyGoal',
        'language',
        'lastBackup',
      ];

      Map<String, String> settings = {};
      for (String key in settingKeys) {
        final value = await _databaseService.getSetting(key);
        if (value != null) {
          settings[key] = value;
        }
      }

      return settings;
    } catch (e) {
      return {};
    }
  }

  bool _validateBackupData(Map<String, dynamic> data) {
    try {
      // 필수 필드 검사
      if (!data.containsKey('version') ||
          !data.containsKey('timestamp') ||
          !data.containsKey('data')) {
        return false;
      }

      final dataSection = data['data'];
      if (!dataSection.containsKey('incomes') ||
          !dataSection.containsKey('goals') ||
          !dataSection.containsKey('settings')) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _createSafetyBackup() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'PayDay_안전백업_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');

      final safetyBackup = await createFullBackup();
      // 안전 백업은 별도 처리하지 않고 파일만 생성
    } catch (e) {
      // 안전 백업 실패는 치명적이지 않음
    }
  }

  Future<void> _restoreIncomes(List<dynamic> incomes) async {
    try {
      // 기존 수입 데이터 클리어 (선택적)
      // await _incomeService.clearAllIncomes();

      for (var income in incomes) {
        await _incomeService.addIncome(
          type: income['type'],
          amount: income['amount'].toDouble(),
          title: income['title'],
          description: income['description'],
          date: income['date'],
        );
      }
    } catch (e) {
      throw Exception('수입 데이터 복원 실패: $e');
    }
  }

  Future<void> _restoreGoals(List<dynamic> goals) async {
    try {
      for (var goal in goals) {
        await _databaseService.addGoal(
          title: goal['title'],
          targetAmount: goal['target_amount'].toDouble(),
          deadline: goal['deadline'] != null
            ? DateTime.parse(goal['deadline'])
            : null,
        );
      }
    } catch (e) {
      throw Exception('목표 데이터 복원 실패: $e');
    }
  }

  Future<void> _restoreSettings(Map<String, dynamic> settings) async {
    try {
      for (var entry in settings.entries) {
        await _databaseService.saveSetting(entry.key, entry.value);
      }
    } catch (e) {
      throw Exception('설정 데이터 복원 실패: $e');
    }
  }

  Future<void> shareBackup() async {
    try {
      final backupPath = await createFullBackup();
      await Share.shareXFiles(
        [XFile(backupPath)],
        text: 'PayDay 앱 데이터 백업을 공유합니다.',
        subject: 'PayDay 백업 파일',
      );
    } catch (e) {
      throw Exception('백업 공유 실패: $e');
    }
  }

  Future<Map<String, dynamic>> getBackupInfo() async {
    try {
      final incomes = await _incomeService.getAllIncomes();
      final goals = await _databaseService.getAllGoals();
      final totalIncome = await _incomeService.getTotalIncome();

      return {
        'totalIncomes': incomes.length,
        'totalGoals': goals.length,
        'totalAmount': totalIncome,
        'oldestRecord': incomes.isNotEmpty
          ? incomes.last['date']
          : null,
        'newestRecord': incomes.isNotEmpty
          ? incomes.first['date']
          : null,
        'estimatedSize': _calculateBackupSize(incomes, goals),
      };
    } catch (e) {
      return {
        'totalIncomes': 0,
        'totalGoals': 0,
        'totalAmount': 0.0,
        'estimatedSize': '0 KB',
      };
    }
  }

  String _calculateBackupSize(List<Map<String, dynamic>> incomes, List<Map<String, dynamic>> goals) {
    try {
      // 대략적인 크기 계산 (JSON 문자열 기준)
      final sampleData = {
        'incomes': incomes.take(5).toList(),
        'goals': goals.take(5).toList(),
        'settings': {'sample': 'data'},
      };

      final sampleJson = jsonEncode(sampleData);
      final avgItemSize = sampleJson.length / (incomes.length.clamp(1, 5) + goals.length.clamp(1, 5));
      final estimatedBytes = avgItemSize * (incomes.length + goals.length + 10); // 10은 설정 및 메타데이터

      if (estimatedBytes < 1024) {
        return '${estimatedBytes.toInt()} B';
      } else if (estimatedBytes < 1024 * 1024) {
        return '${(estimatedBytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(estimatedBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      return '알 수 없음';
    }
  }

  Future<List<String>> getAvailableBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync()
          .where((file) => file.path.contains('PayDay_백업_') && file.path.endsWith('.json'))
          .map((file) => file.path)
          .toList();

      files.sort((a, b) => b.compareTo(a)); // 최신순 정렬
      return files;
    } catch (e) {
      return [];
    }
  }
}