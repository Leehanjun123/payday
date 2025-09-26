import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/earning_service.dart';
import '../config/app_config.dart';

// 실제 광고 시청 화면
class WatchAdScreen extends StatefulWidget {
  const WatchAdScreen({Key? key}) : super(key: key);

  @override
  State<WatchAdScreen> createState() => _WatchAdScreenState();
}

class _WatchAdScreenState extends State<WatchAdScreen> {
  final EarningService _earningService = EarningService();
  bool _isLoading = false;
  String _message = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('광고 시청하고 돈 벌기'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.play_circle_outline,
                size: 120,
                color: Colors.green.shade400,
              ),
              const SizedBox(height: 24),
              const Text(
                '30초 광고를 시청하면',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                '100원',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
              const Text(
                '즉시 적립됩니다!',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              if (_message.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _message.contains('성공')
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _message,
                    style: TextStyle(
                      color: _message.contains('성공')
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: _isLoading ? null : _watchAd,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                  backgroundColor: const Color(0xFF10B981),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        '광고 시청 시작',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                '하루 최대 20회까지 시청 가능',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _watchAd() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    final success = await _earningService.showRewardedAd();

    setState(() {
      _isLoading = false;
      if (success) {
        _message = '✅ 100원이 적립되었습니다!';
      } else {
        _message = '❌ 광고를 불러올 수 없습니다. 잠시 후 다시 시도해주세요.';
      }
    });
  }
}

// 실제 설문조사 화면
class SurveyScreen extends StatefulWidget {
  const SurveyScreen({Key? key}) : super(key: key);

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final EarningService _earningService = EarningService();
  List<Survey> _surveys = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSurveys();
  }

  Future<void> _loadSurveys() async {
    final surveys = await _earningService.getAvailableSurveys();
    setState(() {
      _surveys = surveys;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설문조사'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _surveys.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '현재 참여 가능한 설문이 없습니다',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '잠시 후 다시 확인해주세요',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _surveys.length,
                  itemBuilder: (context, index) {
                    final survey = _surveys[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.quiz_outlined,
                            color: Colors.blue.shade600,
                          ),
                        ),
                        title: Text(
                          survey.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '예상 시간: ${survey.estimatedTime}분 | ${survey.provider}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₩${survey.reward.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const Text(
                              '보상',
                              style: TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                        onTap: () => _startSurvey(survey),
                      ),
                    );
                  },
                ),
    );
  }

  void _startSurvey(Survey survey) async {
    final url = await _earningService.getSurveyUrl(survey.id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SurveyWebView(
          url: url,
          title: survey.title,
          reward: survey.reward,
        ),
      ),
    );
  }
}

// 설문조사 웹뷰
class SurveyWebView extends StatefulWidget {
  final String url;
  final String title;
  final double reward;

  const SurveyWebView({
    Key? key,
    required this.url,
    required this.title,
    required this.reward,
  }) : super(key: key);

  @override
  State<SurveyWebView> createState() => _SurveyWebViewState();
}

class _SurveyWebViewState extends State<SurveyWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            // 설문 완료 체크
            if (url.contains('complete') || url.contains('thank')) {
              _showCompletionDialog();
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('설문 완료!'),
        content: Text('${widget.reward.toStringAsFixed(0)}원이 적립되었습니다.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '₩${widget.reward.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

// 출금 화면
class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({Key? key}) : super(key: key);

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final EarningService _earningService = EarningService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _accountController = TextEditingController();

  String _selectedBank = '신한은행';
  bool _isProcessing = false;

  final List<String> _banks = [
    '신한은행',
    '국민은행',
    '우리은행',
    '하나은행',
    'NH농협은행',
    '카카오뱅크',
    '토스뱅크',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('출금 신청'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 현재 잔액
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      '출금 가능 금액',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₩${_earningService.userBalance.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 출금 금액
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '출금 금액',
                  hintText: '최소 5,000원',
                  prefixText: '₩ ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '금액을 입력해주세요';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    return '올바른 금액을 입력해주세요';
                  }
                  if (amount < AppConfig.minWithdrawalAmount) {
                    return '최소 출금 금액은 ${AppConfig.minWithdrawalAmount}원입니다';
                  }
                  if (amount > _earningService.userBalance) {
                    return '잔액이 부족합니다';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 은행 선택
              DropdownButtonFormField<String>(
                value: _selectedBank,
                decoration: const InputDecoration(
                  labelText: '은행 선택',
                  border: OutlineInputBorder(),
                ),
                items: _banks.map((bank) {
                  return DropdownMenuItem(
                    value: bank,
                    child: Text(bank),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBank = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // 계좌번호
              TextFormField(
                controller: _accountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '계좌번호',
                  hintText: '- 없이 입력',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '계좌번호를 입력해주세요';
                  }
                  if (!RegExp(r'^\d+$').hasMatch(value)) {
                    return '숫자만 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 안내사항
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                          size: 16,
                          color: Colors.blue.shade700),
                        const SizedBox(width: 4),
                        Text(
                          '출금 안내',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• 출금 수수료: ${AppConfig.withdrawalFee}원\n'
                      '• 처리 시간: 영업일 기준 1-2일\n'
                      '• 본인 명의 계좌만 가능합니다',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 출금 버튼
              ElevatedButton(
                onPressed: _isProcessing ? null : _requestWithdrawal,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFF10B981),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        '출금 신청',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestWithdrawal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      final bankAccount = '$_selectedBank ${_accountController.text}';

      final success = await _earningService.requestWithdrawal(
        amount,
        bankAccount,
      );

      if (success) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('출금 신청 완료'),
            content: Text(
              '${amount.toStringAsFixed(0)}원 출금 신청이 완료되었습니다.\n'
              '영업일 기준 1-2일 내에 입금됩니다.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('출금 신청에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    super.dispose();
  }
}