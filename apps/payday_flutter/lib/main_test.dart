import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'firebase_options.dart';
import 'services/admob_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // AdMob 초기화
  await MobileAds.instance.initialize();

  runApp(const PayDayTestApp());
}

class PayDayTestApp extends StatelessWidget {
  const PayDayTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PayDay 광고 테스트',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AdTestScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// 광고 테스트 화면
class AdTestScreen extends StatefulWidget {
  const AdTestScreen({Key? key}) : super(key: key);

  @override
  State<AdTestScreen> createState() => _AdTestScreenState();
}

class _AdTestScreenState extends State<AdTestScreen> {
  final AdMobService _adMobService = AdMobService();
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  String _message = "앱이 정상적으로 실행되었습니다!";

  @override
  void initState() {
    super.initState();
    _initializeAds();
  }

  Future<void> _initializeAds() async {
    setState(() {
      _message = "AdMob 초기화 중...";
    });

    // AdMob 서비스 초기화
    await _adMobService.initialize();

    setState(() {
      _message = "배너 광고 로드 중...";
    });

    // 배너 광고 로드
    _bannerAd = _adMobService.createBannerAd(
      adSize: AdSize.banner,
      onAdLoaded: (Ad ad) {
        setState(() {
          _isBannerAdReady = true;
          _message = "✅ 배너 광고가 로드되었습니다!";
        });
      },
      onAdFailedToLoad: (Ad ad, LoadAdError error) {
        setState(() {
          _message = "❌ 배너 광고 로드 실패: $error";
        });
        ad.dispose();
      },
    );

    await _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PayDay 광고 테스트'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.monetization_on,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _message,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () async {
                setState(() {
                  _message = "🎬 리워드 광고 준비 중...";
                });

                bool success = await _adMobService.showRewardedAd();

                setState(() {
                  _message = success
                      ? "✅ 리워드 광고 시청 완료! 보상을 받았습니다."
                      : "⏳ 리워드 광고가 아직 준비되지 않았습니다. 잠시 후 다시 시도해주세요.";
                });
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('리워드 광고 보기'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: () async {
                setState(() {
                  _message = "📱 전면 광고 준비 중...";
                });

                bool success = await _adMobService.showInterstitialAd();

                setState(() {
                  _message = success
                      ? "✅ 전면 광고 표시 완료!"
                      : "⏳ 전면 광고가 아직 준비되지 않았습니다. 잠시 후 다시 시도해주세요.";
                });
              },
              icon: const Icon(Icons.fullscreen),
              label: const Text('전면 광고 보기'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
            const Spacer(),
            // 배너 광고 표시
            if (_isBannerAdReady && _bannerAd != null)
              Container(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              )
            else
              Container(
                width: 320,
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    '배너 광고 로딩 중...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}