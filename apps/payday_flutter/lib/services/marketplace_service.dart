// services/marketplace_service.dart

import 'package:dio/dio.dart';
import '../models/marketplace_item.dart';

class MarketplaceService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.45.250:3000/api',
      headers: {
        'X-API-Key': 'temporary-api-key',
      },
    ),
  );

  // 모든 'ACTIVE' 상태의 재능 상품 목록을 가져옵니다.
  Future<List<MarketplaceItem>> getActiveItems({String? category}) async {
    try {
      final Map<String, dynamic> queryParameters = {};
      if (category != null) {
        queryParameters['category'] = category;
      }

      final response = await _dio.get('/marketplace', queryParameters: queryParameters);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> itemData = response.data['data'];
        return itemData.map((json) => MarketplaceItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load marketplace items');
      }
    } catch (e) {
      print('Error fetching marketplace items: $e');
      throw Exception('Failed to load marketplace items');
    }
  }

  // 새로운 재능 상품을 등록합니다.
  Future<MarketplaceItem> createItem(Map<String, dynamic> itemData) async {
    try {
      final response = await _dio.post('/marketplace', data: itemData);
      if (response.statusCode == 201 && response.data['success'] == true) {
        return MarketplaceItem.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to create item');
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['error'] ?? e.message;
      throw Exception('Failed to create item: $errorMessage');
    } catch (e) {
      throw Exception('An unknown error occurred');
    }
  }
}
