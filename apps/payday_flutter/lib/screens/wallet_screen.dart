import 'package:flutter/material.dart';
import '../services/income_service.dart';
import '../models/income_source.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  State<WalletScreen> createState() => WalletScreenState();
}

class WalletScreenState extends State<WalletScreen> {
  final IncomeServiceInterface _incomeService = IncomeServiceProvider.instance;

  double _totalIncome = 0.0;
  List<Map<String, dynamic>> _recentIncomes = [];
  List<Map<String, dynamic>> _filteredIncomes = [];
  Map<String, double> _incomeByTypes = {};
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = '전체';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    setState(() => _isLoading = true);

    try {
      final totalIncome = await _incomeService.getTotalIncome();
      final recentIncomes = await _incomeService.getAllIncomes();
      final incomeByTypes = await _incomeService.getIncomeByTypes();

      setState(() {
        _totalIncome = totalIncome;
        _recentIncomes = recentIncomes;
        _filteredIncomes = recentIncomes;
        _incomeByTypes = incomeByTypes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('데이터 로드 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void refreshWallet() {
    _loadWalletData();
  }

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
        case IncomeType.delivery: return '배달';
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

  IconData _getTypeIcon(String type) {
    try {
      final incomeType = IncomeType.values.firstWhere(
        (e) => e.toString() == type,
        orElse: () => IncomeType.freelance,
      );

      switch (incomeType) {
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
    } catch (e) {
      return Icons.attach_money;
    }
  }

  Color _getTypeColor(String type) {
    try {
      final incomeType = IncomeType.values.firstWhere(
        (e) => e.toString() == type,
        orElse: () => IncomeType.freelance,
      );

      switch (incomeType) {
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
    } catch (e) {
      return Colors.blue;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatAmount(double amount) {
    return '₩${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '지갑',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.grey[600]),
            onPressed: _loadWalletData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWalletData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTotalBalanceCard(),
                    _buildSearchAndFilter(),
                    _buildIncomeTypesSection(),
                    _buildRecentTransactionsSection(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTotalBalanceCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '총 수익',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatAmount(_totalIncome),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '총 ${_recentIncomes.length}건',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeTypesSection() {
    if (_incomeByTypes.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            '아직 수익 데이터가 없습니다',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    final sortedTypes = _incomeByTypes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '수익원별 현황',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          ...sortedTypes.map((entry) => _buildIncomeTypeCard(entry.key, entry.value)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildIncomeTypeCard(String type, double amount) {
    final percentage = _totalIncome > 0 ? (amount / _totalIncome * 100) : 0.0;
    final color = _getTypeColor(type);
    final icon = _getTypeIcon(type);
    final displayName = _getTypeDisplayName(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatAmount(amount),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '최근 수익',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          if (_filteredIncomes.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  _searchQuery.isNotEmpty || _selectedFilter != '전체'
                      ? '검색 결과가 없습니다'
                      : '아직 수익 기록이 없습니다',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredIncomes.length > 10 ? 10 : _filteredIncomes.length,
              itemBuilder: (context, index) {
                final income = _filteredIncomes[index];
                return _buildTransactionItem(income);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> income) {
    final id = income['id'] as int;
    final type = income['type'] as String;
    final title = income['title'] as String;
    final amount = income['amount'] as double;
    final date = income['date'] as String;
    final description = income['description'] as String?;

    final color = _getTypeColor(type);
    final icon = _getTypeIcon(type);
    final displayName = _getTypeDisplayName(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () => _showIncomeDetails(income),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatAmount(amount),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        _formatDate(date),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.grey[400]),
            onPressed: () => _showIncomeOptions(income),
          ),
        ],
      ),
    );
  }

  void _showIncomeDetails(Map<String, dynamic> income) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(income['title'] as String),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('분류', _getTypeDisplayName(income['type'] as String)),
            _buildDetailRow('금액', _formatAmount(income['amount'] as double)),
            _buildDetailRow('날짜', _formatDate(income['date'] as String)),
            if (income['description'] != null && (income['description'] as String).isNotEmpty)
              _buildDetailRow('설명', income['description'] as String),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _editIncome(income);
            },
            child: const Text('편집'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  void _showIncomeOptions(Map<String, dynamic> income) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: Colors.blue),
              title: Text('편집'),
              onTap: () {
                Navigator.pop(context);
                _editIncome(income);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('삭제', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteIncome(income);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editIncome(Map<String, dynamic> income) {
    final titleController = TextEditingController(text: income['title'] as String);
    final amountController = TextEditingController(text: (income['amount'] as double).toStringAsFixed(0));
    final descriptionController = TextEditingController(text: income['description'] as String? ?? '');
    DateTime selectedDate = DateTime.parse(income['date'] as String);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('수익 편집'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '제목',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '금액',
                  prefixText: '₩ ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '설명 (선택사항)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('날짜: ${_formatDate(selectedDate.toIso8601String())}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    selectedDate = date;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final amount = double.parse(amountController.text.replaceAll(',', ''));
                await _incomeService.updateIncome(
                  income['id'] as int,
                  title: titleController.text,
                  amount: amount,
                  description: descriptionController.text,
                  date: selectedDate,
                );
                Navigator.pop(context);
                _loadWalletData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('수익이 수정되었습니다')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('수정 실패: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _deleteIncome(Map<String, dynamic> income) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('수익 삭제'),
        content: Text('정말로 "${income['title']}"을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _incomeService.deleteIncome(income['id'] as int);
                Navigator.pop(context);
                _loadWalletData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('수익이 삭제되었습니다')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('삭제 실패: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    final filterOptions = ['전체', '프리랜서', '주식', '암호화폐', 'YouTube', 'TikTok', 'Instagram',
                          '블로그', '걸음 리워드', '게임', '리뷰', '설문조사', '퀴즈', '데일리 미션', '추천인', '리워드 광고'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    onChanged: _updateSearch,
                    decoration: InputDecoration(
                      hintText: '제목, 설명으로 검색...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    items: filterOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: _updateFilter,
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                ),
              ),
            ],
          ),
          if (_searchQuery.isNotEmpty || _selectedFilter != '전체') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (_searchQuery.isNotEmpty)
                  _buildFilterChip('검색: $_searchQuery', () => _clearSearch()),
                if (_searchQuery.isNotEmpty && _selectedFilter != '전체')
                  const SizedBox(width: 8),
                if (_selectedFilter != '전체')
                  _buildFilterChip('분류: $_selectedFilter', () => _clearFilter()),
                const Spacer(),
                TextButton(
                  onPressed: _clearAllFilters,
                  child: const Text('전체 지우기', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 16,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  void _updateSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _updateFilter(String? filter) {
    setState(() {
      _selectedFilter = filter ?? '전체';
    });
    _applyFilters();
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
    _applyFilters();
  }

  void _clearFilter() {
    setState(() {
      _selectedFilter = '전체';
    });
    _applyFilters();
  }

  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _selectedFilter = '전체';
      _searchController.clear();
    });
    _applyFilters();
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_recentIncomes);

    // 검색 필터 적용
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((income) {
        final title = (income['title'] as String).toLowerCase();
        final description = (income['description'] as String? ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return title.contains(query) || description.contains(query);
      }).toList();
    }

    // 분류 필터 적용
    if (_selectedFilter != '전체') {
      filtered = filtered.where((income) {
        final displayName = _getTypeDisplayName(income['type'] as String);
        return displayName == _selectedFilter;
      }).toList();
    }

    setState(() {
      _filteredIncomes = filtered;
    });
  }
}