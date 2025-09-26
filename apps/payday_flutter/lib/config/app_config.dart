// 실제 수익 창출 서비스 연동 설정
class AppConfig {
  // 광고 네트워크 설정
  static const String admobAppId = 'ca-app-pub-XXXXXXXXXXXXX'; // AdMob App ID
  static const String admobBannerId = 'ca-app-pub-XXXXXXXXXXXXX/XXXXXXXXXX';
  static const String admobInterstitialId = 'ca-app-pub-XXXXXXXXXXXXX/XXXXXXXXXX';
  static const String admobRewardedId = 'ca-app-pub-XXXXXXXXXXXXX/XXXXXXXXXX';

  // Unity Ads
  static const String unityGameId = 'XXXXXXX';
  static const String unityRewardedPlacementId = 'rewardedVideo';

  // Facebook Audience Network
  static const String fbPlacementId = 'XXXXXXXXXX_XXXXXXXXXX';

  // 설문조사 플랫폼
  static const String surveytimeApiKey = 'YOUR_API_KEY';
  static const String pollpassApiKey = 'YOUR_API_KEY';
  static const String cpxResearchAppId = 'YOUR_APP_ID';
  static const String theoremReachApiToken = 'YOUR_TOKEN';

  // 캐시백/리워드 파트너
  static const String coupangPartnersId = 'YOUR_PARTNER_ID';
  static const String naverShoppingPartnerId = 'YOUR_PARTNER_ID';
  static const String wemadefPlayPartnerId = 'YOUR_PARTNER_ID';

  // 결제/출금 시스템
  static const String tossPaymentsClientKey = 'test_ck_XXXXXXXXXXXXXXXXXX';
  static const String tossPaymentsSecretKey = 'test_sk_XXXXXXXXXXXXXXXXXX';
  static const String kakaopayAdminKey = 'YOUR_ADMIN_KEY';

  // 최소 출금 금액 (원)
  static const int minWithdrawalAmount = 5000;

  // 수수료 설정
  static const double platformFeeRate = 0.1; // 10% 플랫폼 수수료
  static const double withdrawalFee = 500; // 출금 수수료 500원

  // API 서버
  static const String apiBaseUrl = 'https://payday-production.up.railway.app';
  static const String apiVersion = 'v1';

  // Local development URL (for testing)
  static const String localApiUrl = 'http://localhost:3000';

  // Use Railway URL in production, local for development
  static const bool useProduction = true;

  static String get baseUrl => useProduction ? apiBaseUrl : localApiUrl;
}