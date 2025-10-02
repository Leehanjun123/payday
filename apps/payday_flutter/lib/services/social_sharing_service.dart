import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'achievement_service.dart';
import 'data_service.dart';

class SocialSharingService {
  final DataService _dbService = DataService();
  final DateFormat _dateFormatter = DateFormat('yyyy년 MM월 dd일');
  final NumberFormat _currencyFormatter = NumberFormat('#,###');

  // 성과 카드 템플릿 생성
  Future<String> generateAchievementCard({
    required Achievement achievement,
    required BuildContext context,
  }) async {
    final message = '''
🏆 ${achievement.title} 달성!

${achievement.description}
${achievement.shareMessage}

#PayDay #수익관리 #목표달성 #${achievement.title.replaceAll(' ', '')}
📱 PayDay - AI 기반 스마트 수익 창출 플랫폼
''';
    return message;
  }

  // 월간 리포트 공유
  Future<String> generateMonthlyReport() async {
    await _dbService.database;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final incomes = await _dbService.getIncomesByDateRange(startOfMonth, endOfMonth);

    double totalIncome = 0;
    Map<String, double> incomeByType = {};
    Map<String, int> countByType = {};

    for (var income in incomes) {
      final amount = (income['amount'] as num).toDouble();
      final type = income['type'] as String;

      totalIncome += amount;
      incomeByType[type] = (incomeByType[type] ?? 0) + amount;
      countByType[type] = (countByType[type] ?? 0) + 1;
    }

    // 가장 많은 수익원 찾기
    String topSource = '';
    double topAmount = 0;
    incomeByType.forEach((type, amount) {
      if (amount > topAmount) {
        topSource = _getTypeLabel(type);
        topAmount = amount;
      }
    });

    final message = '''
📊 ${now.month}월 수익 리포트

💰 총 수익: ₩${_currencyFormatter.format(totalIncome)}
📈 수익 건수: ${incomes.length}건
🥇 최고 수익원: $topSource (₩${_currencyFormatter.format(topAmount)})

${_generateHashtags(totalIncome, incomes.length)}
📱 PayDay로 체계적인 수익 관리 시작하기
''';

    return message;
  }

  // 주간 성과 공유
  Future<String> generateWeeklyProgress() async {
    await _dbService.database;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final thisWeekIncomes = await _dbService.getIncomesByDateRange(weekStart, now);
    final lastWeekStart = weekStart.subtract(const Duration(days: 7));
    final lastWeekEnd = weekStart.subtract(const Duration(days: 1));
    final lastWeekIncomes = await _dbService.getIncomesByDateRange(lastWeekStart, lastWeekEnd);

    double thisWeekTotal = 0;
    double lastWeekTotal = 0;

    for (var income in thisWeekIncomes) {
      thisWeekTotal += (income['amount'] as num).toDouble();
    }

    for (var income in lastWeekIncomes) {
      lastWeekTotal += (income['amount'] as num).toDouble();
    }

    final growth = lastWeekTotal > 0
      ? ((thisWeekTotal - lastWeekTotal) / lastWeekTotal * 100)
      : 0;

    String growthEmoji = growth > 0 ? '📈' : (growth < 0 ? '📉' : '➡️');
    String growthText = growth > 0
      ? '지난주 대비 ${growth.toStringAsFixed(1)}% 상승!'
      : (growth < 0
          ? '지난주 대비 ${growth.abs().toStringAsFixed(1)}% 하락'
          : '지난주와 동일');

    final message = '''
📅 이번 주 수익 현황

💰 이번 주: ₩${_currencyFormatter.format(thisWeekTotal)}
📊 지난 주: ₩${_currencyFormatter.format(lastWeekTotal)}
$growthEmoji $growthText

${thisWeekIncomes.length}건의 수익 활동
평균 ₩${_currencyFormatter.format(thisWeekTotal / (thisWeekIncomes.isEmpty ? 1 : thisWeekIncomes.length))}

#주간리포트 #PayDay #수익관리 #성장
📱 PayDay - 당신의 수익 성장 파트너
''';

    return message;
  }

  // 목표 달성 공유
  Future<String> generateGoalAchievement(Map<String, dynamic> goal) async {
    final goalTitle = goal['title'] ?? '목표';
    final targetAmount = (goal['target_amount'] as num).toDouble();
    final progress = goal['progress'] ?? 0.0;
    final deadline = goal['deadline'] != null
      ? _dateFormatter.format(DateTime.parse(goal['deadline']))
      : '기한 없음';

    String emoji = progress >= 1.0 ? '🎯' : '💪';
    String status = progress >= 1.0 ? '목표 달성!' : '${(progress * 100).toStringAsFixed(1)}% 진행중';

    final message = '''
$emoji $goalTitle $status

🎯 목표 금액: ₩${_currencyFormatter.format(targetAmount)}
📊 진행률: ${(progress * 100).toStringAsFixed(1)}%
📅 목표일: $deadline

${progress >= 1.0 ? '축하합니다! 목표를 달성했습니다! 🎉' : '목표 달성까지 조금만 더 화이팅!'}

#목표달성 #PayDay #동기부여 #성공
📱 PayDay와 함께 목표를 이루세요
''';

    return message;
  }

  // 연속 기록 공유
  Future<String> generateStreakShare(int streakDays) async {
    String emoji = '';
    String title = '';

    if (streakDays >= 100) {
      emoji = '💎';
      title = '100일 연속 기록!';
    } else if (streakDays >= 30) {
      emoji = '🔥';
      title = '${streakDays}일 연속 기록중!';
    } else if (streakDays >= 7) {
      emoji = '⚡';
      title = '${streakDays}일 연속 기록!';
    } else {
      emoji = '✨';
      title = '${streakDays}일 연속!';
    }

    final message = '''
$emoji $title

매일매일 꾸준히 수익을 기록하고 있습니다!
연속 기록: ${streakDays}일 🗓️

${_getStreakMotivation(streakDays)}

#연속기록 #꾸준함 #PayDay #동기부여
📱 PayDay - 꾸준한 수익 관리의 시작
''';

    return message;
  }

  // 커스텀 메시지와 함께 공유
  Future<void> shareWithCustomMessage({
    required String baseMessage,
    String? additionalText,
  }) async {
    final finalMessage = additionalText != null
      ? '$baseMessage\n\n💬 $additionalText'
      : baseMessage;

    await Share.share(finalMessage);
  }

  // 이미지와 함께 공유 (성과 카드 이미지 생성)
  Future<void> shareAchievementWithImage({
    required Achievement achievement,
    required BuildContext context,
  }) async {
    try {
      // 성과 카드 위젯을 이미지로 변환
      final image = await _generateAchievementImage(achievement, context);

      if (image != null) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/achievement_${achievement.id}.png');
        await file.writeAsBytes(image);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: achievement.shareMessage,
        );
      } else {
        // 이미지 생성 실패시 텍스트만 공유
        final message = await generateAchievementCard(
          achievement: achievement,
          context: context,
        );
        await Share.share(message);
      }
    } catch (e) {
      // 오류 발생시 텍스트만 공유
      final message = await generateAchievementCard(
        achievement: achievement,
        context: context,
      );
      await Share.share(message);
    }
  }

  // Private 헬퍼 메서드들
  Future<Uint8List?> _generateAchievementImage(
    Achievement achievement,
    BuildContext context,
  ) async {
    // 간단한 이미지 생성 (실제 구현시 더 복잡한 디자인 가능)
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    // 배경
    paint.color = achievement.color;
    canvas.drawRect(const Rect.fromLTWH(0, 0, 400, 300), paint);

    // 텍스트
    final textPainter = TextPainter(
      text: TextSpan(
        text: achievement.title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(50, 100));

    final picture = recorder.endRecording();
    final img = await picture.toImage(400, 300);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return byteData?.buffer.asUint8List();
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

  String _generateHashtags(double amount, int count) {
    List<String> hashtags = ['#PayDay', '#수익관리'];

    if (amount >= 10000000) {
      hashtags.add('#천만원달성');
    } else if (amount >= 1000000) {
      hashtags.add('#백만원달성');
    } else if (amount >= 100000) {
      hashtags.add('#십만원달성');
    }

    if (count >= 30) {
      hashtags.add('#매일기록');
    } else if (count >= 20) {
      hashtags.add('#꾸준한기록');
    }

    return hashtags.join(' ');
  }

  String _getStreakMotivation(int days) {
    if (days >= 100) {
      return '놀라운 끈기와 꾸준함! 당신은 진정한 프로입니다! 👏';
    } else if (days >= 30) {
      return '한 달 이상 꾸준히! 습관이 되었네요! 💪';
    } else if (days >= 7) {
      return '일주일 연속! 좋은 습관을 만들어가고 있어요! 👍';
    } else {
      return '시작이 반입니다! 계속 이어가세요! 🚀';
    }
  }
}