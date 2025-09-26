import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'income_service.dart';
import '../models/income_source.dart';

class ExportService {
  final IncomeServiceInterface _incomeService = IncomeServiceProvider.instance;

  String _getTypeDisplayName(String type) {
    try {
      final incomeType = IncomeType.values.firstWhere(
        (e) => e.toString() == type,
        orElse: () => IncomeType.freelance,
      );

      switch (incomeType) {
        case IncomeType.freelance: return '프리랜서';
        case IncomeType.stock: return '주식';
        case IncomeType.crypto: return '암호화폐';
        case IncomeType.youtube: return 'YouTube';
        case IncomeType.tiktok: return 'TikTok';
        case IncomeType.instagram: return 'Instagram';
        case IncomeType.blog: return '블로그';
        case IncomeType.walkingReward: return '걸음 리워드';
        case IncomeType.game: return '게임';
        case IncomeType.review: return '리뷰';
        case IncomeType.survey: return '설문조사';
        case IncomeType.quiz: return '퀴즈';
        case IncomeType.dailyMission: return '데일리 미션';
        case IncomeType.referral: return '추천인';
        case IncomeType.rewardAd: return '리워드 광고';
        default: return type;
      }
    } catch (e) {
      return type;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<String> exportToCsv() async {
    try {
      // 모든 수익 데이터 가져오기
      final incomes = await _incomeService.getAllIncomes();

      // CSV 헤더
      List<List<String>> csvData = [
        ['날짜', '분류', '제목', '금액', '설명']
      ];

      // 데이터 추가
      for (final income in incomes) {
        csvData.add([
          _formatDate(income['date'] as String),
          _getTypeDisplayName(income['type'] as String),
          income['title'] as String,
          (income['amount'] as double).toStringAsFixed(0),
          income['description'] as String? ?? '',
        ]);
      }

      // CSV 문자열로 변환
      String csv = const ListToCsvConverter().convert(csvData);

      // 파일 저장
      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final fileName = 'PayDay_수익데이터_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.csv';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(csv, encoding: utf8);

      return file.path;
    } catch (e) {
      throw Exception('CSV 내보내기 실패: $e');
    }
  }

  Future<void> exportAndShare() async {
    try {
      final filePath = await exportToCsv();
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'PayDay 수익 데이터를 공유합니다.',
        subject: 'PayDay 수익 데이터',
      );
    } catch (e) {
      throw Exception('데이터 공유 실패: $e');
    }
  }

  Future<Map<String, dynamic>> getExportSummary() async {
    try {
      final incomes = await _incomeService.getAllIncomes();
      final totalIncome = await _incomeService.getTotalIncome();
      final incomeByTypes = await _incomeService.getIncomeByTypes();

      return {
        'totalRecords': incomes.length,
        'totalAmount': totalIncome,
        'oldestRecord': incomes.isNotEmpty
            ? _formatDate(incomes.last['date'] as String)
            : null,
        'newestRecord': incomes.isNotEmpty
            ? _formatDate(incomes.first['date'] as String)
            : null,
        'typeBreakdown': incomeByTypes.map(
          (key, value) => MapEntry(_getTypeDisplayName(key), value)
        ),
      };
    } catch (e) {
      throw Exception('요약 정보 생성 실패: $e');
    }
  }

  Future<String> exportToJson() async {
    try {
      // JSON 형태로 내보내기 (개발자용)
      final incomes = await _incomeService.getAllIncomes();
      final summary = await getExportSummary();

      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'summary': summary,
        'data': incomes,
      };

      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final fileName = 'PayDay_데이터백업_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.json';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(exportData.toString());

      return file.path;
    } catch (e) {
      throw Exception('JSON 내보내기 실패: $e');
    }
  }
}