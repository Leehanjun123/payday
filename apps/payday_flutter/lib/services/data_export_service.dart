import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'data_service.dart';
import 'ai_prediction_service.dart';
import '../models/income.dart';

class DataExportService {
  final DataService _dbService = DataService();
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');
  final DateFormat _timeFormatter = DateFormat('HH:mm:ss');

  // CSV 형식으로 내보내기
  Future<Map<String, dynamic>> exportToCSV({
    DateTime? startDate,
    DateTime? endDate,
    bool includeGoals = true,
    bool includeStats = true,
  }) async {
    try {
      await _dbService.database;

      // 데이터 가져오기
      List<Map<String, dynamic>> incomes;
      if (startDate != null && endDate != null) {
        incomes = await _dbService.getIncomesByDateRange(startDate, endDate);
      } else {
        incomes = await _dbService.getAllIncomes();
      }

      // CSV 데이터 생성
      List<List<dynamic>> csvData = [];

      // 헤더 추가
      csvData.add(['PayDay 수익 리포트']);
      csvData.add(['생성일시: ${DateTime.now().toIso8601String()}']);
      csvData.add([]);

      // 수익 데이터 섹션
      csvData.add(['=== 수익 데이터 ===']);
      csvData.add(['날짜', '유형', '이름', '금액', '설명']);

      for (var income in incomes) {
        csvData.add([
          _dateFormatter.format(income['date']),
          _getTypeLabel(income['type']),
          income['name'] ?? income['title'] ?? '',
          income['amount'],
          income['description'] ?? '',
        ]);
      }

      // 목표 데이터 추가
      if (includeGoals) {
        csvData.add([]);
        csvData.add(['=== 목표 데이터 ===']);

        final goals = await _dbService.getAllGoals();
        csvData.add(['목표명', '목표 금액', '현재 진행률', '마감일']);

        for (var goal in goals) {
          final progress = await _calculateGoalProgress(goal);
          csvData.add([
            goal['title'],
            goal['target_amount'],
            '${(progress * 100).toStringAsFixed(1)}%',
            goal['deadline'] != null
              ? _dateFormatter.format(DateTime.parse(goal['deadline']))
              : '없음',
          ]);
        }
      }

      // 통계 추가
      if (includeStats) {
        csvData.add([]);
        csvData.add(['=== 통계 요약 ===']);

        final stats = _calculateStatistics(incomes);
        csvData.add(['총 수익', stats['total']]);
        csvData.add(['평균 수익', stats['average']]);
        csvData.add(['최고 수익', stats['max']]);
        csvData.add(['최저 수익', stats['min']]);
        csvData.add(['수익 건수', stats['count']]);
      }

      // CSV 파일로 변환
      String csv = const ListToCsvConverter().convert(csvData);

      // 파일 저장
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'PayDay_Export_$timestamp.csv';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(csv);

      return {
        'success': true,
        'file': file,
        'fileName': fileName,
        'recordCount': incomes.length,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // JSON 형식으로 내보내기
  Future<Map<String, dynamic>> exportToJSON({
    DateTime? startDate,
    DateTime? endDate,
    bool includeGoals = true,
    bool includeStats = true,
    bool includePredictions = true,
  }) async {
    try {
      await _dbService.database;

      // 데이터 수집
      List<Map<String, dynamic>> incomes;
      if (startDate != null && endDate != null) {
        incomes = await _dbService.getIncomesByDateRange(startDate, endDate);
      } else {
        incomes = await _dbService.getAllIncomes();
      }

      Map<String, dynamic> exportData = {
        'metadata': {
          'appName': 'PayDay',
          'exportDate': DateTime.now().toIso8601String(),
          'version': '1.0.0',
          'recordCount': incomes.length,
        },
        'incomes': incomes.map((income) => {
          'date': income['date'].toIso8601String(),
          'type': income['type'],
          'typeLabel': _getTypeLabel(income['type']),
          'name': income['name'] ?? income['title'] ?? '',
          'amount': income['amount'],
          'description': income['description'],
        }).toList(),
      };

      // 목표 추가
      if (includeGoals) {
        final goals = await _dbService.getAllGoals();
        exportData['goals'] = [];

        for (var goal in goals) {
          final progress = await _calculateGoalProgress(goal);
          exportData['goals'].add({
            'title': goal['title'],
            'targetAmount': goal['target_amount'],
            'progress': progress,
            'deadline': goal['deadline'],
          });
        }
      }

      // 통계 추가
      if (includeStats) {
        exportData['statistics'] = _calculateStatistics(incomes);
        exportData['statistics']['byType'] = _calculateByType(incomes);
        exportData['statistics']['byMonth'] = _calculateByMonth(incomes);
      }

      // AI 예측 추가
      if (includePredictions && incomes.isNotEmpty) {
        final predictions = AIPredictionService.predictFutureIncome(
          incomes.map((i) => Income(
            id: i['id'] as int?,
            type: i['type'] as String? ?? 'other',
            name: i['title'] as String? ?? i['name'] as String? ?? '',
            amount: (i['amount'] as num).toDouble(),
            date: DateTime.parse(i['date']),
            description: i['description'] as String?,
          )).toList(),
        );

        exportData['predictions'] = {
          'oneMonth': predictions.nextMonthPrediction,
          'threeMonths': predictions.threeMonthPrediction,
          'sixMonths': predictions.sixMonthPrediction,
          'trend': predictions.trend.toString(),
          'confidence': predictions.confidence,
        };
      }

      // JSON 파일 생성
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'PayDay_Report_$timestamp.json';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonString);

      return {
        'success': true,
        'file': file,
        'fileName': fileName,
        'recordCount': incomes.length,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // HTML 리포트 생성
  Future<Map<String, dynamic>> generateHTMLReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      await _dbService.database;

      List<Map<String, dynamic>> incomes;
      if (startDate != null && endDate != null) {
        incomes = await _dbService.getIncomesByDateRange(startDate, endDate);
      } else {
        incomes = await _dbService.getAllIncomes();
      }

      final stats = _calculateStatistics(incomes);
      final byType = _calculateByType(incomes);
      final goals = await _dbService.getAllGoals();

      // HTML 생성
      String html = '''
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PayDay 수익 리포트</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        .container {
            background: white;
            border-radius: 20px;
            padding: 40px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
        }
        h1 {
            color: #667eea;
            text-align: center;
            font-size: 2.5em;
            margin-bottom: 30px;
        }
        h2 {
            color: #764ba2;
            border-bottom: 2px solid #f0f0f0;
            padding-bottom: 10px;
            margin-top: 40px;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }
        .stat-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 15px;
            text-align: center;
        }
        .stat-value {
            font-size: 2em;
            font-weight: bold;
            margin: 10px 0;
        }
        .stat-label {
            opacity: 0.9;
            font-size: 0.9em;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        th {
            background: #f8f9fa;
            padding: 12px;
            text-align: left;
            font-weight: 600;
        }
        td {
            padding: 12px;
            border-bottom: 1px solid #f0f0f0;
        }
        .type-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.85em;
            font-weight: 500;
        }
        .footer {
            text-align: center;
            margin-top: 50px;
            padding-top: 20px;
            border-top: 1px solid #f0f0f0;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 PayDay 수익 리포트</h1>
        <p style="text-align: center; color: #666;">
            생성일: ${DateFormat('yyyy년 MM월 dd일 HH:mm').format(DateTime.now())}
        </p>

        <h2>📈 요약 통계</h2>
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-label">총 수익</div>
                <div class="stat-value">₩${stats['total'].toStringAsFixed(0)}</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">평균 수익</div>
                <div class="stat-value">₩${stats['average'].toStringAsFixed(0)}</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">수익 건수</div>
                <div class="stat-value">${stats['count']}건</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">최고 수익</div>
                <div class="stat-value">₩${stats['max'].toStringAsFixed(0)}</div>
            </div>
        </div>

        <h2>💼 유형별 분석</h2>
        <table>
            <thead>
                <tr>
                    <th>유형</th>
                    <th>금액</th>
                    <th>비율</th>
                </tr>
            </thead>
            <tbody>
                ${byType.entries.map((e) => '''
                <tr>
                    <td><span class="type-badge" style="background: #${_getTypeColor(e.key)};">${_getTypeLabel(e.key)}</span></td>
                    <td>₩${e.value.toStringAsFixed(0)}</td>
                    <td>${((e.value / stats['total']) * 100).toStringAsFixed(1)}%</td>
                </tr>
                ''').join()}
            </tbody>
        </table>

        <h2>🎯 목표 현황</h2>
        <table>
            <thead>
                <tr>
                    <th>목표</th>
                    <th>목표 금액</th>
                    <th>진행률</th>
                    <th>마감일</th>
                </tr>
            </thead>
            <tbody>
                ${goals.map((goal) => '''
                <tr>
                    <td>${goal['title']}</td>
                    <td>₩${goal['target_amount'].toStringAsFixed(0)}</td>
                    <td>${(goal['progress'] * 100).toStringAsFixed(1)}%</td>
                    <td>${goal['deadline'] != null ? DateFormat('yyyy-MM-dd').format(DateTime.parse(goal['deadline'])) : '없음'}</td>
                </tr>
                ''').join()}
            </tbody>
        </table>

        <div class="footer">
            <p>PayDay - AI 기반 스마트 수익 창출 플랫폼</p>
            <p style="font-size: 0.9em;">이 리포트는 자동으로 생성되었습니다.</p>
        </div>
    </div>
</body>
</html>
      ''';

      // HTML 파일 저장
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'PayDay_Report_$timestamp.html';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(html);

      return {
        'success': true,
        'file': file,
        'fileName': fileName,
        'recordCount': incomes.length,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // 파일 공유
  Future<void> shareFile(File file, String subject) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: subject,
      text: 'PayDay 데이터 내보내기',
    );
  }

  // Private 헬퍼 메서드들
  Map<String, dynamic> _calculateStatistics(List<Map<String, dynamic>> incomes) {
    if (incomes.isEmpty) {
      return {
        'total': 0.0,
        'average': 0.0,
        'max': 0.0,
        'min': 0.0,
        'count': 0,
      };
    }

    double total = 0;
    double max = 0;
    double min = double.infinity;

    for (var income in incomes) {
      final amount = (income['amount'] as num).toDouble();
      total += amount;
      if (amount > max) max = amount;
      if (amount < min) min = amount;
    }

    return {
      'total': total,
      'average': total / incomes.length,
      'max': max,
      'min': min == double.infinity ? 0 : min,
      'count': incomes.length,
    };
  }

  Map<String, double> _calculateByType(List<Map<String, dynamic>> incomes) {
    Map<String, double> byType = {};

    for (var income in incomes) {
      final type = income['type'] as String;
      final amount = (income['amount'] as num).toDouble();
      byType[type] = (byType[type] ?? 0) + amount;
    }

    return byType;
  }

  Map<String, double> _calculateByMonth(List<Map<String, dynamic>> incomes) {
    Map<String, double> byMonth = {};

    for (var income in incomes) {
      final date = income['date'] as DateTime;
      final key = DateFormat('yyyy-MM').format(date);
      final amount = (income['amount'] as num).toDouble();
      byMonth[key] = (byMonth[key] ?? 0) + amount;
    }

    return byMonth;
  }

  Future<double> _calculateGoalProgress(Map<String, dynamic> goal) async {
    // 간단한 진행률 계산 (실제로는 더 복잡한 로직 필요)
    final currentAmount = await _getCurrentAmountForGoal(goal);
    final targetAmount = (goal['target_amount'] as num).toDouble();

    if (targetAmount <= 0) return 0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  Future<double> _getCurrentAmountForGoal(Map<String, dynamic> goal) async {
    // 목표와 관련된 현재 금액 계산
    final incomes = await _dbService.getAllIncomes();
    double total = 0;

    for (var income in incomes) {
      total += (income['amount'] as num).toDouble();
    }

    // 목표 기간 고려한 비율 계산 (간단한 예시)
    return total * 0.3; // 예시로 30% 반환
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'freelance':
        return '프리랜서';
      case 'side_job':
        return '부업';
      case 'investment':
        return '투자';
      case 'rental':
        return '임대';
      case 'sales':
        return '판매';
      case 'other':
      default:
        return '기타';
    }
  }

  String _getTypeColor(String type) {
    switch (type) {
      case 'freelance':
        return '667eea';
      case 'side_job':
        return '764ba2';
      case 'investment':
        return 'f093fb';
      case 'rental':
        return 'f5576c';
      case 'sales':
        return '4facfe';
      case 'other':
      default:
        return '43e97b';
    }
  }
}