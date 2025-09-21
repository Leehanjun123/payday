import React, { useState, useEffect, useCallback } from 'react';
import {
  StyleSheet,
  Text,
  View,
  ScrollView,
  TouchableOpacity,
  FlatList,
  Image,
  Alert,
  RefreshControl,
  TextInput,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import marketplaceService, { MarketplaceItem, MarketplaceFilters } from '../../services/marketplaceService';

export default function MarketplaceScreen({ navigation }: any) {
  const [items, setItems] = useState<MarketplaceItem[]>([]);
  const [categories, setCategories] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [hasMore, setHasMore] = useState(true);
  const [page, setPage] = useState(1);
  const [selectedCategory, setSelectedCategory] = useState<string>('');
  const [searchQuery, setSearchQuery] = useState('');
  const [filters, setFilters] = useState<MarketplaceFilters>({});

  useEffect(() => {
    loadInitialData();
  }, []);

  useEffect(() => {
    if (searchQuery || selectedCategory) {
      handleSearch();
    }
  }, [searchQuery, selectedCategory]);

  const loadInitialData = async () => {
    setLoading(true);
    try {
      const [itemsResponse, categoriesResponse] = await Promise.all([
        marketplaceService.getItems({}, 1, 20),
        marketplaceService.getCategories(),
      ]);

      setItems(itemsResponse.items);
      setCategories([{ name: '전체', count: 0 }, ...categoriesResponse.categories]);
      setHasMore(itemsResponse.pagination.page < itemsResponse.pagination.pages);
      setPage(2);
    } catch (error: any) {
      Alert.alert('오류', error.message || '데이터를 불러오는데 실패했습니다.');
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = async () => {
    setLoading(true);
    try {
      const searchFilters: MarketplaceFilters = {
        ...filters,
        search: searchQuery || undefined,
        category: selectedCategory || undefined,
      };

      const response = await marketplaceService.getItems(searchFilters, 1, 20);
      setItems(response.items);
      setHasMore(response.pagination.page < response.pagination.pages);
      setPage(2);
    } catch (error: any) {
      Alert.alert('오류', error.message || '검색에 실패했습니다.');
    } finally {
      setLoading(false);
    }
  };

  const loadMoreItems = async () => {
    if (!hasMore || loading) return;

    try {
      const searchFilters: MarketplaceFilters = {
        ...filters,
        search: searchQuery || undefined,
        category: selectedCategory || undefined,
      };

      const response = await marketplaceService.getItems(searchFilters, page, 20);
      setItems(prev => [...prev, ...response.items]);
      setHasMore(response.pagination.page < response.pagination.pages);
      setPage(prev => prev + 1);
    } catch (error: any) {
      Alert.alert('오류', error.message || '추가 데이터를 불러오는데 실패했습니다.');
    }
  };

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    setPage(1);
    await loadInitialData();
    setRefreshing(false);
  }, []);

  const handleItemPress = (item: MarketplaceItem) => {
    navigation.navigate('MarketplaceDetail', { itemId: item.id });
  };

  const handleCategoryPress = (category: string) => {
    setSelectedCategory(category === '전체' ? '' : category);
  };

  const renderItem = ({ item }: { item: MarketplaceItem }) => (
    <TouchableOpacity style={styles.itemCard} onPress={() => handleItemPress(item)}>
      <View style={styles.imageContainer}>
        {item.images && item.images.length > 0 ? (
          <Image
            source={{ uri: item.images[0] }}
            style={styles.itemImage}
            resizeMode="cover"
          />
        ) : (
          <View style={styles.placeholderImage}>
            <Ionicons name="image-outline" size={32} color="#ccc" />
          </View>
        )}

        {item.auction && (
          <View style={styles.auctionBadge}>
            <Ionicons name="hammer" size={12} color="#fff" />
            <Text style={styles.auctionText}>경매</Text>
          </View>
        )}

        <View style={styles.conditionBadge}>
          <Text style={[styles.conditionText, { color: marketplaceService.getConditionColor(item.condition) }]}>
            {marketplaceService.getConditionText(item.condition)}
          </Text>
        </View>
      </View>

      <View style={styles.itemContent}>
        <Text style={styles.itemTitle} numberOfLines={2}>
          {item.title}
        </Text>

        <Text style={styles.itemPrice}>
          {marketplaceService.formatPrice(item.price)}
          {item.isNegotiable && <Text style={styles.negotiable}> (협의)</Text>}
        </Text>

        <View style={styles.itemMeta}>
          <View style={styles.sellerInfo}>
            <Ionicons name="person-outline" size={14} color="#666" />
            <Text style={styles.sellerName}>{item.seller.name}</Text>
            <View style={styles.levelBadge}>
              <Text style={styles.levelText}>Lv.{item.seller.level}</Text>
            </View>
          </View>

          <View style={styles.stats}>
            <View style={styles.statItem}>
              <Ionicons name="eye-outline" size={12} color="#666" />
              <Text style={styles.statText}>{item.views}</Text>
            </View>
            <View style={styles.statItem}>
              <Ionicons name="heart-outline" size={12} color="#666" />
              <Text style={styles.statText}>{item._count.favorites}</Text>
            </View>
          </View>
        </View>

        {item.location && (
          <View style={styles.locationInfo}>
            <Ionicons name="location-outline" size={12} color="#666" />
            <Text style={styles.locationText}>{item.location}</Text>
          </View>
        )}
      </View>
    </TouchableOpacity>
  );

  const renderCategory = ({ item }: { item: any }) => (
    <TouchableOpacity
      style={[
        styles.categoryChip,
        selectedCategory === (item.name === '전체' ? '' : item.name) && styles.categoryChipSelected,
      ]}
      onPress={() => handleCategoryPress(item.name)}
    >
      <Text
        style={[
          styles.categoryText,
          selectedCategory === (item.name === '전체' ? '' : item.name) && styles.categoryTextSelected,
        ]}
      >
        {item.name}
      </Text>
      {item.count > 0 && (
        <Text
          style={[
            styles.categoryCount,
            selectedCategory === (item.name === '전체' ? '' : item.name) && styles.categoryCountSelected,
          ]}
        >
          {item.count}
        </Text>
      )}
    </TouchableOpacity>
  );

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>중고마켓</Text>
        <View style={styles.headerActions}>
          <TouchableOpacity
            style={styles.headerButton}
            onPress={() => navigation.navigate('MarketplaceSearch')}
          >
            <Ionicons name="search" size={24} color="#333" />
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.headerButton}
            onPress={() => navigation.navigate('CreateMarketplaceItem')}
          >
            <Ionicons name="add" size={24} color="#333" />
          </TouchableOpacity>
        </View>
      </View>

      <View style={styles.searchContainer}>
        <View style={styles.searchInputContainer}>
          <Ionicons name="search" size={20} color="#666" />
          <TextInput
            style={styles.searchInput}
            placeholder="상품명, 브랜드명 등을 검색해보세요"
            value={searchQuery}
            onChangeText={setSearchQuery}
            onSubmitEditing={handleSearch}
          />
          {searchQuery.length > 0 && (
            <TouchableOpacity onPress={() => setSearchQuery('')}>
              <Ionicons name="close-circle" size={20} color="#666" />
            </TouchableOpacity>
          )}
        </View>
      </View>

      <View style={styles.categoryContainer}>
        <FlatList
          data={categories}
          renderItem={renderCategory}
          keyExtractor={(item) => item.name}
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.categoryList}
        />
      </View>

      <FlatList
        data={items}
        renderItem={renderItem}
        keyExtractor={(item) => item.id}
        numColumns={2}
        columnWrapperStyle={styles.row}
        contentContainerStyle={styles.itemList}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
        onEndReached={loadMoreItems}
        onEndReachedThreshold={0.5}
        ListEmptyComponent={
          !loading ? (
            <View style={styles.emptyContainer}>
              <Ionicons name="storefront-outline" size={64} color="#ccc" />
              <Text style={styles.emptyText}>등록된 상품이 없습니다</Text>
              <Text style={styles.emptySubtext}>첫 번째 상품을 등록해보세요!</Text>
            </View>
          ) : null
        }
      />

      {/* Floating Action Button */}
      <TouchableOpacity
        style={styles.fab}
        onPress={() => navigation.navigate('AuctionList')}
      >
        <Ionicons name="hammer" size={24} color="#fff" />
      </TouchableOpacity>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    paddingVertical: 16,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#333',
  },
  headerActions: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  headerButton: {
    padding: 8,
    marginLeft: 8,
  },
  searchContainer: {
    backgroundColor: '#fff',
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  searchInputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#f5f5f5',
    borderRadius: 20,
    paddingHorizontal: 16,
    paddingVertical: 8,
  },
  searchInput: {
    flex: 1,
    marginLeft: 8,
    fontSize: 14,
    color: '#333',
  },
  categoryContainer: {
    backgroundColor: '#fff',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  categoryList: {
    paddingHorizontal: 20,
  },
  categoryChip: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#f5f5f5',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
    marginRight: 8,
  },
  categoryChipSelected: {
    backgroundColor: '#007AFF',
  },
  categoryText: {
    fontSize: 14,
    color: '#666',
  },
  categoryTextSelected: {
    color: '#fff',
    fontWeight: '500',
  },
  categoryCount: {
    fontSize: 12,
    color: '#999',
    marginLeft: 4,
  },
  categoryCountSelected: {
    color: '#fff',
  },
  itemList: {
    padding: 16,
  },
  row: {
    justifyContent: 'space-between',
  },
  itemCard: {
    backgroundColor: '#fff',
    borderRadius: 12,
    marginBottom: 16,
    width: '48%',
    overflow: 'hidden',
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
  },
  imageContainer: {
    position: 'relative',
    height: 140,
  },
  itemImage: {
    width: '100%',
    height: '100%',
  },
  placeholderImage: {
    width: '100%',
    height: '100%',
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#f5f5f5',
  },
  auctionBadge: {
    position: 'absolute',
    top: 8,
    left: 8,
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FF5722',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  auctionText: {
    fontSize: 10,
    fontWeight: 'bold',
    color: '#fff',
    marginLeft: 2,
  },
  conditionBadge: {
    position: 'absolute',
    top: 8,
    right: 8,
    backgroundColor: 'rgba(255, 255, 255, 0.9)',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  conditionText: {
    fontSize: 10,
    fontWeight: '500',
  },
  itemContent: {
    padding: 12,
  },
  itemTitle: {
    fontSize: 14,
    fontWeight: '500',
    color: '#333',
    marginBottom: 4,
    lineHeight: 18,
  },
  itemPrice: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 8,
  },
  negotiable: {
    fontSize: 12,
    fontWeight: 'normal',
    color: '#007AFF',
  },
  itemMeta: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 6,
  },
  sellerInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  sellerName: {
    fontSize: 12,
    color: '#666',
    marginLeft: 4,
  },
  levelBadge: {
    backgroundColor: '#007AFF',
    paddingHorizontal: 4,
    paddingVertical: 1,
    borderRadius: 4,
    marginLeft: 4,
  },
  levelText: {
    fontSize: 10,
    color: '#fff',
    fontWeight: '500',
  },
  stats: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  statItem: {
    flexDirection: 'row',
    alignItems: 'center',
    marginLeft: 8,
  },
  statText: {
    fontSize: 10,
    color: '#666',
    marginLeft: 2,
  },
  locationInfo: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  locationText: {
    fontSize: 11,
    color: '#666',
    marginLeft: 4,
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: 80,
  },
  emptyText: {
    fontSize: 16,
    color: '#666',
    marginTop: 16,
    marginBottom: 4,
  },
  emptySubtext: {
    fontSize: 14,
    color: '#999',
  },
  fab: {
    position: 'absolute',
    bottom: 20,
    right: 20,
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: '#FF5722',
    justifyContent: 'center',
    alignItems: 'center',
    elevation: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
  },
});