import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/income_service.dart';
import '../models/income_source.dart';

class IncomeEntryScreen extends StatefulWidget {
  final IncomeType incomeType;
  final String incomeTitle;

  const IncomeEntryScreen({
    Key? key,
    required this.incomeType,
    required this.incomeTitle,
  }) : super(key: key);

  @override
  State<IncomeEntryScreen> createState() => _IncomeEntryScreenState();
}

class _IncomeEntryScreenState extends State<IncomeEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // 서비스 레이어 사용 - 나중에 API로 쉽게 교체 가능
  final IncomeServiceInterface _incomeService = IncomeServiceProvider.instance;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.incomeTitle;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Color _getTypeColor(IncomeType type) {
    switch (type) {
      case IncomeType.freelance: return Colors.indigo;
      case IncomeType.stock: return Colors.teal;
      case IncomeType.crypto: return Colors.orange;
      case IncomeType.delivery: return Colors.green;
      case IncomeType.youtube: return Colors.red;
      case IncomeType.tiktok: return Colors.black;
      case IncomeType.instagram: return Colors.purple;
      case IncomeType.blog: return Colors.green;
      case IncomeType.walkingReward: return Colors.lightGreen;
      case IncomeType.game: return Colors.purple;
      case IncomeType.review: return Colors.amber;
      case IncomeType.survey: return Colors.cyan;
      case IncomeType.quiz: return Colors.deepPurple;
      case IncomeType.dailyMission: return Colors.brown;
      case IncomeType.referral: return Colors.pink;
      case IncomeType.rewardAd: return Colors.deepOrange;
      default: return Colors.blue;
    }
  }

  IconData _getTypeIcon(IncomeType type) {
    switch (type) {
      case IncomeType.freelance: return Icons.work_outline;
      case IncomeType.stock: return Icons.trending_up;
      case IncomeType.crypto: return Icons.currency_bitcoin;
      case IncomeType.delivery: return Icons.delivery_dining;
      case IncomeType.youtube: return Icons.play_arrow;
      case IncomeType.tiktok: return Icons.music_note;
      case IncomeType.instagram: return Icons.camera_alt;
      case IncomeType.blog: return Icons.article;
      case IncomeType.walkingReward: return Icons.directions_walk;
      case IncomeType.game: return Icons.sports_esports;
      case IncomeType.review: return Icons.star;
      case IncomeType.survey: return Icons.poll;
      case IncomeType.quiz: return Icons.quiz;
      case IncomeType.dailyMission: return Icons.task_alt;
      case IncomeType.referral: return Icons.people;
      case IncomeType.rewardAd: return Icons.monetization_on;
      default: return Icons.attach_money;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 서비스 레이어를 통해 저장 - API로 교체 시 이 부분만 변경하면 됨
      await _incomeService.addIncome(
        type: widget.incomeType.toString(),
        title: _titleController.text,
        amount: double.parse(_amountController.text.replaceAll(',', '')),
        description: _descriptionController.text,
        date: _selectedDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('수익이 추가되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // 성공 시 true 반환
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getTypeColor(widget.incomeType);
    final icon = _getTypeIcon(widget.incomeType);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.grey[600]),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '수익 추가',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveIncome,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    '저장',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 수익원 타입 표시
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.incomeTitle,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            '새로운 수익을 기록하세요',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 제목 입력
              Text(
                '제목',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: '수익 제목을 입력하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: color),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '제목을 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // 금액 입력
              Text(
                '금액',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    if (newValue.text.isEmpty) {
                      return newValue.copyWith(text: '');
                    }

                    String numStr = newValue.text.replaceAll(',', '');
                    if (numStr.isEmpty) return newValue;

                    int num = int.tryParse(numStr) ?? 0;
                    String formatted = num.toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]},',
                    );

                    return newValue.copyWith(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }),
                ],
                decoration: InputDecoration(
                  hintText: '0',
                  prefixText: '₩ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: color),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '금액을 입력해주세요';
                  }
                  final numStr = value.replaceAll(',', '');
                  if (double.tryParse(numStr) == null || double.parse(numStr) <= 0) {
                    return '올바른 금액을 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // 날짜 선택
              Text(
                '날짜',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: color, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 메모 입력
              Text(
                '메모 (선택사항)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '수익에 대한 메모를 입력하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: color),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // 저장 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveIncome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '저장 중...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          '수익 추가하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}