import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'database_service.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CloudBackupService {
  final DatabaseService _dbService = DatabaseService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  static const String _backupVersion = '2.0.0';

  // 전체 백업 데이터 생성
  Future<Map<String, dynamic>> createFullBackup() async {
    try {
      await _dbService.database;
      
      final incomes = await _dbService.getAllIncomes();
      final goals = await _dbService.getAllGoals();
      
      // 통계 계산
      double totalIncome = 0;
      Map<String, double> incomeByType = {};
      
      for (var income in incomes) {
        final amount = (income['amount'] as num).toDouble();
        totalIncome += amount;
        
        final type = income['type'] as String;
        incomeByType[type] = (incomeByType[type] ?? 0) + amount;
      }
      
      final backupData = {
        'app_info': {
          'name': 'PayDay',
          'version': _backupVersion,
          'platform': Platform.operatingSystem,
        },
        'metadata': {
          'created_at': DateTime.now().toIso8601String(),
          'device_id': await _getDeviceId(),
          'backup_type': 'full',
        },
        'data': {
          'incomes': incomes.map((income) => {
            ...income,
            'synced': false,
          }).toList(),
          'goals': goals.map((goal) => {
            ...goal,
            'synced': false,
          }).toList(),
        },
        'summary': {
          'total_income': totalIncome,
          'income_count': incomes.length,
          'goals_count': goals.length,
          'income_by_type': incomeByType,
          'date_range': _getDateRange(incomes),
        },
      };
      
      return {
        'success': true,
        'backup': backupData,
        'size': _calculateBackupSize(backupData),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // 백업 파일로 내보내기
  Future<void> exportBackup() async {
    try {
      final result = await createFullBackup();
      if (!result['success']) throw Exception(result['error']);
      
      final backupData = result['backup'];
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      
      // 파일 이름 생성
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'PayDay_Backup_$timestamp.json';
      
      // 임시 파일로 저장
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonString);
      
      // 공유
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'PayDay 백업',
        text: 'PayDay 데이터 백업 (${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())})',
      );
      
      // 백업 시간 저장
      await _saveLastBackupTime();
    } catch (e) {
      throw Exception('백업 내보내기 실패: $e');
    }
  }

  // 백업에서 복원
  Future<Map<String, dynamic>> restoreFromJson(String jsonContent) async {
    try {
      final backupData = jsonDecode(jsonContent);
      
      // 버전 확인
      final version = backupData['app_info']?['version'] ?? '1.0.0';
      if (!_isVersionCompatible(version)) {
        return {
          'success': false,
          'error': '호환되지 않는 백업 버전입니다 ($version)',
        };
      }
      
      final data = backupData['data'];
      final incomes = List<Map<String, dynamic>>.from(data['incomes'] ?? []);
      final goals = List<Map<String, dynamic>>.from(data['goals'] ?? []);
      
      int restoredIncomes = 0;
      int restoredGoals = 0;
      int skipped = 0;
      
      // 수익 복원
      for (var income in incomes) {
        try {
          // 중복 체크
          if (await _isDuplicateIncome(income)) {
            skipped++;
            continue;
          }
          
          await _dbService.addIncome(
            type: income['type'] ?? 'other',
            title: income['title'] ?? income['name'] ?? '',
            amount: (income['amount'] as num).toDouble(),
            description: income['description'] ?? income['note'] ?? '',
            date: income['date'] != null ? DateTime.parse(income['date']) : null,
          );
          restoredIncomes++;
        } catch (e) {
          print('Income restore error: $e');
        }
      }
      
      // 목표 복원
      for (var goal in goals) {
        try {
          // 중복 체크
          if (await _isDuplicateGoal(goal)) {
            skipped++;
            continue;
          }
          
          await _dbService.addGoal(
            title: goal['title'] ?? '',
            targetAmount: (goal['target_amount'] as num).toDouble(),
            deadline: goal['deadline'] != null
              ? DateTime.parse(goal['deadline'])
              : null,
          );
          restoredGoals++;
        } catch (e) {
          print('Goal restore error: $e');
        }
      }
      
      // 복원 시간 저장
      await _saveLastRestoreTime();
      
      return {
        'success': true,
        'restored': {
          'incomes': restoredIncomes,
          'goals': restoredGoals,
          'skipped': skipped,
        },
        'message': '복원 완료: 수익 $restoredIncomes개, 목표 $restoredGoals개',
      };
    } catch (e) {
      return {
        'success': false,
        'error': '복원 실패: $e',
      };
    }
  }

  // 백업 히스토리 가져오기
  Future<List<Map<String, dynamic>>> getBackupHistory() async {
    final historyJson = await _secureStorage.read(key: 'backup_history');
    if (historyJson == null) return [];
    
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(historyJson));
    } catch (e) {
      return [];
    }
  }

  // 자동 백업 설정
  Future<void> setAutoBackup(bool enabled, {int? intervalDays = 7}) async {
    await _secureStorage.write(
      key: 'auto_backup_enabled',
      value: enabled.toString(),
    );
    
    if (enabled && intervalDays != null) {
      await _secureStorage.write(
        key: 'auto_backup_interval',
        value: intervalDays.toString(),
      );
    }
  }

  // 자동 백업 상태
  Future<Map<String, dynamic>> getAutoBackupStatus() async {
    final enabled = await _secureStorage.read(key: 'auto_backup_enabled') == 'true';
    final intervalStr = await _secureStorage.read(key: 'auto_backup_interval');
    final lastBackup = await _secureStorage.read(key: 'last_backup_time');
    
    return {
      'enabled': enabled,
      'interval_days': int.tryParse(intervalStr ?? '7') ?? 7,
      'last_backup': lastBackup != null ? DateTime.tryParse(lastBackup) : null,
      'needs_backup': await _needsAutoBackup(),
    };
  }

  // Private 헬퍼 메서드들
  Future<String> _getDeviceId() async {
    var deviceId = await _secureStorage.read(key: 'device_id');
    if (deviceId == null) {
      deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      await _secureStorage.write(key: 'device_id', value: deviceId);
    }
    return deviceId;
  }

  Map<String, String> _getDateRange(List<Map<String, dynamic>> incomes) {
    if (incomes.isEmpty) {
      return {'start': '', 'end': ''};
    }
    
    final dates = incomes
      .where((i) => i['date'] != null)
      .map((i) => DateTime.parse(i['date'] as String))
      .toList()
      ..sort();
      
    if (dates.isEmpty) return {'start': '', 'end': ''};
    
    return {
      'start': DateFormat('yyyy-MM-dd').format(dates.first),
      'end': DateFormat('yyyy-MM-dd').format(dates.last),
    };
  }

  int _calculateBackupSize(Map<String, dynamic> data) {
    return jsonEncode(data).length;
  }

  bool _isVersionCompatible(String version) {
    // 메이저 버전만 비교
    final current = _backupVersion.split('.')[0];
    final backup = version.split('.')[0];
    return current == backup;
  }

  Future<bool> _isDuplicateIncome(Map<String, dynamic> income) async {
    // 간단한 중복 체크 로직
    // 실제 구현 시 더 정교한 비교 필요
    return false;
  }

  Future<bool> _isDuplicateGoal(Map<String, dynamic> goal) async {
    // 간단한 중복 체크 로직
    return false;
  }

  Future<void> _saveLastBackupTime() async {
    await _secureStorage.write(
      key: 'last_backup_time',
      value: DateTime.now().toIso8601String(),
    );
    
    // 히스토리에 추가
    await _addToHistory('backup');
  }

  Future<void> _saveLastRestoreTime() async {
    await _secureStorage.write(
      key: 'last_restore_time',
      value: DateTime.now().toIso8601String(),
    );
    
    // 히스토리에 추가
    await _addToHistory('restore');
  }

  Future<void> _addToHistory(String type) async {
    final history = await getBackupHistory();
    
    history.insert(0, {
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
      'device': Platform.operatingSystem,
    });
    
    // 최근 10개만 유지
    if (history.length > 10) {
      history.removeRange(10, history.length);
    }
    
    await _secureStorage.write(
      key: 'backup_history',
      value: jsonEncode(history),
    );
  }

  Future<bool> _needsAutoBackup() async {
    final status = await getAutoBackupStatus();
    if (!status['enabled']) return false;
    
    final lastBackup = status['last_backup'] as DateTime?;
    if (lastBackup == null) return true;
    
    final intervalDays = status['interval_days'] as int;
    final daysSinceBackup = DateTime.now().difference(lastBackup).inDays;
    
    return daysSinceBackup >= intervalDays;
  }
}