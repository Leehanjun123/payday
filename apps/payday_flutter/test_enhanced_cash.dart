import 'lib/services/enhanced_cash_service.dart';
import 'lib/services/local_storage_service.dart';

void main() async {
  print('🧪 Enhanced Cash Service 테스트 시작');

  final cashService = EnhancedCashService();
  await cashService.initialize();

  print('✅ 초기화 완료');

  // 초기 잔액 확인
  print('💰 초기 잔액: ${cashService.balance}원');

  // 광고 시청 수익
  print('\n📺 광고 시청 테스트...');
  final adResult = await cashService.earnAdCash('rewarded');
  print('광고 시청 결과: $adResult');
  print('현재 잔액: ${cashService.balance}원');

  // 걷기 수익
  print('\n🚶 걷기 수익 테스트...');
  await cashService.earnWalkingCash(150); // 150보 = 1회 수익
  print('현재 잔액: ${cashService.balance}원');

  // 새로운 수익 방법들 테스트
  print('\n⭐ 새로운 수익 방법 테스트...');

  // 앱 리뷰
  await cashService.earnFromAppReview('PayDay App', 5);
  print('앱 리뷰 후 잔액: ${cashService.balance}원');

  // 소셜 공유
  await cashService.earnFromSocialShare('Instagram');
  print('소셜 공유 후 잔액: ${cashService.balance}원');

  // 물 마시기
  await cashService.earnFromWaterDrink();
  print('물 마시기 후 잔액: ${cashService.balance}원');

  // 통계 확인
  print('\n📊 통계 확인...');
  final stats = await cashService.getCashStatistics();
  print('총 수익: ${stats['totalEarned']}원');
  print('오늘 수익: ${stats['todayEarnings']}원');
  print('거래 횟수: ${stats['transactionCount']}회');

  print('\n🎉 모든 테스트 완료!');
}