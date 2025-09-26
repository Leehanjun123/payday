import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EarningInfoScreen extends StatelessWidget {
  const EarningInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('💰 수익 창출 가이드'),
        backgroundColor: const Color(0xFF3182F7),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(
            icon: Icons.gavel,
            title: '경매로 돈 벌기',
            subtitle: '중고나라, 이베이 등',
            earnings: '월 10~500만원',
            difficulty: '중급',
            onTap: () => _showDetailModal(context, 'auction'),
          ),
          _buildInfoCard(
            icon: Icons.group_work,
            title: '크라우드펀딩',
            subtitle: '와디즈, 텀블벅',
            earnings: '연 5~20% 수익',
            difficulty: '중급',
            onTap: () => _showDetailModal(context, 'crowdfunding'),
          ),
          _buildInfoCard(
            icon: Icons.work,
            title: '프리랜서',
            subtitle: '크몽, 숨고',
            earnings: '월 50~500만원',
            difficulty: '중급',
            onTap: () => _showDetailModal(context, 'freelance'),
          ),
          _buildInfoCard(
            icon: Icons.currency_bitcoin,
            title: '암호화폐',
            subtitle: '업비트 스테이킹',
            earnings: '연 3~12%',
            difficulty: '초급',
            onTap: () => _showDetailModal(context, 'crypto'),
          ),
          _buildInfoCard(
            icon: Icons.account_balance,
            title: 'P2P 투자',
            subtitle: '카카오페이 투자',
            earnings: '연 3~8%',
            difficulty: '초급',
            onTap: () => _showDetailModal(context, 'p2p'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String earnings,
    required String difficulty,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF3182F7).withOpacity(0.1),
          child: Icon(icon, color: const Color(0xFF3182F7)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    earnings,
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    difficulty,
                    style: const TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showDetailModal(BuildContext context, String type) {
    final details = _getDetails(type);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    details['title']!,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(details['description']!),
                  const SizedBox(height: 20),
                  const Text(
                    '시작하는 방법',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...details['steps']!.map((step) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(step),
                  )),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _copyUrl(context, details['url']!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3182F7),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'URL 복사하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getDetails(String type) {
    switch (type) {
      case 'auction':
        return {
          'title': '경매로 돈 벌기',
          'description': '중고나라, 이베이 등에서 물품을 저가에 구매하고 고가에 판매하여 수익을 창출합니다.',
          'steps': [
            '1. 플랫폼 가입 (중고나라, 이베이 등)',
            '2. 시세 파악 및 물품 리서치',
            '3. 저가 매입 → 고가 판매',
            '4. 경매 타이밍 파악',
            '5. 리뷰 관리 및 신뢰도 구축',
          ],
          'url': 'https://cafe.naver.com/joonggonara',
        };
      case 'crowdfunding':
        return {
          'title': '크라우드펀딩 투자',
          'description': '와디즈, 텀블벅 등에서 스타트업이나 창작 프로젝트에 투자하여 수익을 얻습니다.',
          'steps': [
            '1. 와디즈/텀블벅 가입',
            '2. 투자자 인증 (와디즈)',
            '3. 프로젝트 분석 및 선별',
            '4. 분산 투자 진행',
            '5. 리워드/수익 수령',
          ],
          'url': 'https://www.wadiz.kr',
        };
      case 'freelance':
        return {
          'title': '프리랜서 활동',
          'description': '크몽, 숨고에서 자신의 재능과 기술을 판매하여 수익을 창출합니다.',
          'steps': [
            '1. 크몽/숨고 전문가 등록',
            '2. 포트폴리오 작성',
            '3. 서비스 가격 설정',
            '4. 고객 응대 및 작업',
            '5. 리뷰 관리',
          ],
          'url': 'https://kmong.com',
        };
      case 'crypto':
        return {
          'title': '암호화폐 스테이킹',
          'description': '업비트 등에서 암호화폐를 스테이킹하여 패시브 인컴을 얻습니다.',
          'steps': [
            '1. 업비트 가입 및 인증',
            '2. 스테이킹 지원 코인 구매',
            '3. 스테이킹 신청',
            '4. 일일 보상 수령',
            '5. 복리 재투자',
          ],
          'url': 'https://upbit.com',
        };
      case 'p2p':
        return {
          'title': 'P2P 투자',
          'description': '카카오페이 등에서 P2P 투자 상품에 투자하여 이자 수익을 얻습니다.',
          'steps': [
            '1. 카카오페이 앱 설치',
            '2. 투자 서비스 신청',
            '3. 상품별 수익률 비교',
            '4. 분산 투자',
            '5. 수익 재투자',
          ],
          'url': 'https://www.kakaopay.com',
        };
      default:
        return {
          'title': '',
          'description': '',
          'steps': [],
          'url': '',
        };
    }
  }

  void _copyUrl(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('URL이 복사되었습니다: $url'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}