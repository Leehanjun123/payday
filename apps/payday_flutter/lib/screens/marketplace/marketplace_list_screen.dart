import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart'; // Shimmer 패키지 import
import '../../services/marketplace_service.dart';
import '../../models/marketplace_item.dart';
import 'package:intl/intl.dart';
import 'create_marketplace_item_screen.dart';

class MarketplaceListScreen extends StatefulWidget {
  const MarketplaceListScreen({Key? key}) : super(key: key);

  @override
  _MarketplaceListScreenState createState() => _MarketplaceListScreenState();
}

class _MarketplaceListScreenState extends State<MarketplaceListScreen> {
  Future<List<MarketplaceItem>>? _itemsFuture;
  final MarketplaceService _marketplaceService = MarketplaceService();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _refreshItems();
  }

  void _refreshItems() {
    setState(() {
      _itemsFuture = _marketplaceService.getActiveItems(category: _selectedCategory);
    });
  }

  void _filterByCategory(String category) {
    setState(() {
      if (_selectedCategory == category) {
        _selectedCategory = null;
      } else {
        _selectedCategory = category;
      }
      _refreshItems();
    });
  }

  void _clearFilter() {
    setState(() {
      _selectedCategory = null;
      _refreshItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedCategory == null ? '재능 마켓' : '#$_selectedCategory'),
        actions: [
          if (_selectedCategory != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearFilter,
              tooltip: '필터 해제',
            ),
        ],
      ),
      body: FutureBuilder<List<MarketplaceItem>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildSkeletonList(); // 로딩 UI를 스켈레톤으로 변경
          }
          if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(_selectedCategory == null 
                ? '판매중인 재능이 없습니다.' 
                : '\'$_selectedCategory\' 카테고리의 재능이 없습니다.'),
            );
          }

          final items = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildItemCard(item);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreateMarketplaceItemScreen()),
          );
          if (result == true) {
            _refreshItems();
          }
        },
        child: const Icon(Icons.add),
        tooltip: '내 재능 판매하기',
      ),
    );
  }

  // 스켈레톤 UI 리스트 위젯
  Widget _buildSkeletonList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 5, // 로딩 중 보여줄 스켈레톤 아이템 개수
        itemBuilder: (context, index) => _buildSkeletonCard(),
      ),
    );
  }

  // 스켈레톤 카드 위젯
  Widget _buildSkeletonCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: double.infinity, height: 20.0, color: Colors.white),
            const SizedBox(height: 8),
            Container(width: double.infinity, height: 16.0, color: Colors.white),
            const SizedBox(height: 4),
            Container(width: 150.0, height: 16.0, color: Colors.white),
            const SizedBox(height: 16),
            Row(
              children: List.generate(3, (index) => Container(
                margin: const EdgeInsets.only(right: 8.0),
                width: 60.0, height: 30.0, color: Colors.white,
              )),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 100.0, height: 20.0, color: Colors.white),
                Container(width: 80.0, height: 36.0, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(MarketplaceItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              item.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${NumberFormat('#,###').format(item.price)}원',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.deepPurple),
                ),
                ActionChip(
                  label: Text(item.category),
                  onPressed: () => _filterByCategory(item.category),
                  backgroundColor: _selectedCategory == item.category 
                      ? Colors.deepPurple
                      : Colors.deepPurple.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: _selectedCategory == item.category ? Colors.white : Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
