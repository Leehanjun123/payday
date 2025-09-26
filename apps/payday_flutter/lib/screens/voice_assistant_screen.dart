import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/voice_assistant_service.dart';
import 'dart:async';
import 'dart:math' as math;

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({Key? key}) : super(key: key);

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with TickerProviderStateMixin {
  final VoiceAssistantService _voiceService = VoiceAssistantService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 애니메이션 컨트롤러
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _fadeController;

  // 상태
  bool _isListening = false;
  bool _isProcessing = false;
  String _currentTranscript = '';
  List<ConversationItem> _conversations = [];

  // 빠른 명령
  final List<Map<String, dynamic>> _quickCommands = [
    {'icon': '💰', 'label': '수익 추가', 'command': '5만원 수익 추가'},
    {'icon': '📊', 'label': '잔액 확인', 'command': '총 수익 얼마야?'},
    {'icon': '🎯', 'label': '목표 확인', 'command': '목표 달성률 알려줘'},
    {'icon': '📈', 'label': 'AI 분석', 'command': '인사이트 보여줘'},
    {'icon': '⏰', 'label': '알림 설정', 'command': '저녁 7시에 알림'},
    {'icon': '📤', 'label': '내보내기', 'command': '데이터 내보내기'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeVoiceService();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  Future<void> _initializeVoiceService() async {
    await _voiceService.initialize();
    _conversations = _voiceService.getConversationHistory();

    // 인사 메시지
    final greeting = _voiceService.getQuickResponse('greeting');
    setState(() {
      _conversations.add(ConversationItem(
        text: greeting,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _fadeController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 음성 인식 토글
  Future<void> _toggleListening() async {
    if (_isListening) {
      _voiceService.stopListening();
      setState(() {
        _isListening = false;
      });
      _waveController.reverse();

      if (_currentTranscript.isNotEmpty) {
        await _processCommand(_currentTranscript);
      }
    } else {
      // 햅틱 피드백
      HapticFeedback.lightImpact();

      setState(() {
        _isListening = true;
        _currentTranscript = '';
      });
      _waveController.repeat();

      await _voiceService.startListening();

      // 시뮬레이션: 3초 후 자동 종료
      Timer(const Duration(seconds: 3), () {
        if (_isListening) {
          _toggleListening();
        }
      });
    }
  }

  // 명령 처리
  Future<void> _processCommand(String command) async {
    if (command.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    _fadeController.forward();

    // 명령 처리
    final result = await _voiceService.processVoiceCommand(command);

    setState(() {
      _conversations = _voiceService.getConversationHistory();
      _isProcessing = false;
    });

    // 스크롤 끝으로
    _scrollToBottom();

    // TTS 재생 (옵션)
    if (_voiceService.isEnabled) {
      await _voiceService.speak(result.response);
    }

    _fadeController.reverse();
  }

  // 텍스트 입력 전송
  void _sendTextCommand() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    _processCommand(text);
  }

  // 빠른 명령 실행
  void _executeQuickCommand(String command) {
    HapticFeedback.selectionClick();
    _processCommand(command);
  }

  // 스크롤 끝으로
  void _scrollToBottom() {
    Timer(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 음성 비서'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistory(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 대화 영역
          Expanded(
            child: _buildConversationArea(theme, isDark),
          ),

          // 빠른 명령
          _buildQuickCommands(theme, isDark),

          // 입력 영역
          _buildInputArea(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildConversationArea(ThemeData theme, bool isDark) {
    if (_conversations.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final item = _conversations[index];
        return _buildConversationItem(item, theme, isDark);
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + math.sin(_pulseController.value * 2 * math.pi) * 0.1,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.2),
                        theme.colorScheme.secondary.withOpacity(0.2),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.mic_none_rounded,
                    size: 60,
                    color: theme.colorScheme.primary,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'AI 음성 비서',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '마이크 버튼을 눌러 대화를 시작하세요',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationItem(ConversationItem item, ThemeData theme, bool isDark) {
    final isUser = item.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 20,
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary.withOpacity(isDark ? 0.3 : 0.1)
                    : isDark
                        ? Colors.grey[800]
                        : Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isUser
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  if (item.commandType != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _getCommandTypeLabel(item.commandType!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser)
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.secondary.withOpacity(0.1),
              ),
              child: Icon(
                Icons.person,
                color: theme.colorScheme.secondary,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickCommands(ThemeData theme, bool isDark) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickCommands.length,
        itemBuilder: (context, index) {
          final cmd = _quickCommands[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: Text(cmd['icon'], style: const TextStyle(fontSize: 18)),
              label: Text(cmd['label']),
              backgroundColor: theme.colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1),
              onPressed: () => _executeQuickCommand(cmd['command']),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          // 텍스트 입력
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: '메시지를 입력하거나 마이크를 누르세요',
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendTextCommand(),
            ),
          ),

          const SizedBox(width: 8),

          // 마이크 버튼
          GestureDetector(
            onTap: _toggleListening,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isListening
                          ? [
                              Colors.red.withOpacity(0.8),
                              Colors.red.withOpacity(0.6),
                            ]
                          : [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                    ),
                    boxShadow: _isListening
                        ? [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: _waveController.value * 10,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                  ),
                  child: Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 28,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 설정 다이얼로그
  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSettingsSheet(context),
    );
  }

  Widget _buildSettingsSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '음성 비서 설정',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  title: const Text('음성 비서 활성화'),
                  subtitle: const Text('음성 인식 및 응답 기능'),
                  value: _voiceService.isEnabled,
                  onChanged: (value) {
                    _voiceService.updateSettings(enabled: value);
                    setState(() {});
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('음성 타입'),
                  subtitle: Text(_getVoiceTypeLabel(_voiceService.voiceType)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // 음성 타입 선택 다이얼로그
                  },
                ),
                ListTile(
                  title: const Text('말하기 속도'),
                  subtitle: Slider(
                    value: _voiceService.speechRate,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    label: '${_voiceService.speechRate}x',
                    onChanged: (value) {
                      _voiceService.updateSettings(speechRate: value);
                      setState(() {});
                    },
                  ),
                ),
                SwitchListTile(
                  title: const Text('자동 듣기'),
                  subtitle: const Text('응답 후 자동으로 듣기 시작'),
                  value: _voiceService.autoListen,
                  onChanged: (value) {
                    _voiceService.updateSettings(autoListen: value);
                    setState(() {});
                  },
                ),
                ListTile(
                  title: const Text('언어'),
                  subtitle: const Text('한국어'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // 언어 선택 다이얼로그
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 히스토리 다이얼로그
  void _showHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('대화 기록'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _conversations.length,
            itemBuilder: (context, index) {
              final item = _conversations[index];
              return ListTile(
                leading: Icon(
                  item.isUser ? Icons.person : Icons.smart_toy,
                  size: 20,
                ),
                title: Text(item.text),
                subtitle: Text(
                  '${item.timestamp.hour}:${item.timestamp.minute.toString().padLeft(2, '0')}',
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _voiceService.clearHistory();
              setState(() {
                _conversations.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('기록 삭제'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getCommandTypeLabel(VoiceCommandType type) {
    switch (type) {
      case VoiceCommandType.addIncome:
        return '수익 기록';
      case VoiceCommandType.checkBalance:
        return '잔액 확인';
      case VoiceCommandType.getInsights:
        return 'AI 분석';
      case VoiceCommandType.setReminder:
        return '알림 설정';
      case VoiceCommandType.checkGoals:
        return '목표 확인';
      case VoiceCommandType.exportData:
        return '데이터 내보내기';
      case VoiceCommandType.help:
        return '도움말';
      default:
        return '기타';
    }
  }

  String _getVoiceTypeLabel(String type) {
    switch (type) {
      case 'male':
        return '남성 음성';
      case 'female':
        return '여성 음성';
      case 'robot':
        return '로봇 음성';
      default:
        return type;
    }
  }
}