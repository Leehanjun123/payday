import React, { useState, useEffect, useCallback } from 'react';
import {
  StyleSheet,
  Text,
  View,
  FlatList,
  TouchableOpacity,
  Image,
  Alert,
  RefreshControl,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import auctionService, { Auction, TimeRemaining } from '../../services/auctionService';

export default function AuctionListScreen({ navigation }: any) {
  const [auctions, setAuctions] = useState<Auction[]>([]);
  const [loading, setLoading] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [hasMore, setHasMore] = useState(true);
  const [page, setPage] = useState(1);
  const [selectedStatus, setSelectedStatus] = useState<string>('ACTIVE');
  const [timeRemaining, setTimeRemaining] = useState<{ [key: string]: TimeRemaining }>({});

  const statusTabs = [
    { key: 'ACTIVE', label: '진행중' },
    { key: 'SCHEDULED', label: '예정' },
    { key: 'ENDED', label: '종료' },
  ];

  useEffect(() => {
    loadAuctions();
  }, [selectedStatus]);

  useEffect(() => {
    // Update time remaining every second for active auctions
    const interval = setInterval(() => {
      if (selectedStatus === 'ACTIVE') {
        updateTimeRemaining();
      }
    }, 1000);

    return () => clearInterval(interval);
  }, [auctions, selectedStatus]);

  const loadAuctions = async () => {
    setLoading(true);
    try {
      const response = await auctionService.getAuctions(selectedStatus, 1, 20);
      setAuctions(response.auctions);
      setHasMore(response.pagination.page < response.pagination.pages);
      setPage(2);
      updateTimeRemaining(response.auctions);
    } catch (error: any) {
      Alert.alert('오류', error.message || '경매 목록을 불러오는데 실패했습니다.');
    } finally {
      setLoading(false);
    }
  };

  const loadMoreAuctions = async () => {
    if (!hasMore || loading) return;

    try {
      const response = await auctionService.getAuctions(selectedStatus, page, 20);
      setAuctions(prev => [...prev, ...response.auctions]);
      setHasMore(response.pagination.page < response.pagination.pages);
      setPage(prev => prev + 1);
      updateTimeRemaining([...auctions, ...response.auctions]);
    } catch (error: any) {
      Alert.alert('오류', error.message || '추가 데이터를 불러오는데 실패했습니다.');
    }
  };

  const updateTimeRemaining = (auctionList = auctions) => {
    const newTimeRemaining: { [key: string]: TimeRemaining } = {};
    auctionList.forEach(auction => {
      newTimeRemaining[auction.id] = auctionService.calculateTimeRemaining(auction.endTime);
    });
    setTimeRemaining(newTimeRemaining);
  };

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    setPage(1);
    await loadAuctions();
    setRefreshing(false);
  }, [selectedStatus]);

  const handleAuctionPress = (auction: Auction) => {
    navigation.navigate('AuctionDetail', { auctionId: auction.id });
  };

  const handleStatusChange = (status: string) => {
    setSelectedStatus(status);
    setPage(1);
  };

  const renderAuction = ({ item: auction }: { item: Auction }) => {
    const currentTimeRemaining = timeRemaining[auction.id];
    const isExpired = currentTimeRemaining?.isExpired;

    return (
      <TouchableOpacity
        style={styles.auctionCard}
        onPress={() => handleAuctionPress(auction)}
      >
        <View style={styles.imageContainer}>
          {auction.item.images && auction.item.images.length > 0 ? (
            <Image
              source={{ uri: auction.item.images[0] }}
              style={styles.auctionImage}
              resizeMode="cover"
            />
          ) : (
            <View style={styles.placeholderImage}>
              <Ionicons name="image-outline" size={32} color="#ccc" />
            </View>
          )}

          <View style={[styles.statusBadge, { backgroundColor: auctionService.getStatusColor(auction.status) }]}>
            <Text style={styles.statusText}>
              {auctionService.getStatusText(auction.status)}
            </Text>
          </View>

          {auction.status === 'ACTIVE' && currentTimeRemaining && (
            <View style={[styles.timeBadge, isExpired && styles.timeBadgeExpired]}>
              <Ionicons
                name="time-outline"
                size={12}
                color={isExpired ? '#F44336' : '#fff'}
              />
              <Text style={[styles.timeText, isExpired && styles.timeTextExpired]}>
                {auctionService.formatTimeRemaining(currentTimeRemaining)}
              </Text>
            </View>
          )}
        </View>

        <View style={styles.auctionContent}>
          <Text style={styles.auctionTitle} numberOfLines={2}>
            {auction.item.title}
          </Text>

          <View style={styles.priceContainer}>
            <Text style={styles.startPriceLabel}>시작가</Text>
            <Text style={styles.startPrice}>
              {auctionService.formatPrice(auction.startPrice)}
            </Text>
          </View>

          {auction.currentBid ? (
            <View style={styles.priceContainer}>
              <Text style={styles.currentBidLabel}>현재가</Text>
              <Text style={styles.currentBid}>
                {auctionService.formatPrice(auction.currentBid)}
              </Text>
            </View>
          ) : (
            <Text style={styles.noBidsText}>입찰자 없음</Text>
          )}

          {auction.buyNowPrice && (
            <View style={styles.priceContainer}>
              <Text style={styles.buyNowLabel}>즉시구매가</Text>
              <Text style={styles.buyNowPrice}>
                {auctionService.formatPrice(auction.buyNowPrice)}
              </Text>
            </View>
          )}

          <View style={styles.auctionMeta}>
            <View style={styles.sellerInfo}>
              <Ionicons name="person-outline" size={14} color="#666" />
              <Text style={styles.sellerName}>{auction.item.seller.name}</Text>
              <View style={styles.levelBadge}>
                <Text style={styles.levelText}>Lv.{auction.item.seller.level}</Text>
              </View>
            </View>

            <View style={styles.bidCount}>
              <Ionicons name="hammer" size={14} color="#666" />
              <Text style={styles.bidCountText}>
                {auction._count?.bids || 0}건
              </Text>
            </View>
          </View>

          {selectedStatus === 'ACTIVE' && (
            <View style={styles.timeInfo}>
              <Text style={styles.endTimeLabel}>종료일시</Text>
              <Text style={styles.endTime}>
                {auctionService.formatDateTimeShort(auction.endTime)}
              </Text>
            </View>
          )}

          {selectedStatus === 'ENDED' && auction.winner && (
            <View style={styles.winnerInfo}>
              <Ionicons name="trophy" size={14} color="#FFD700" />
              <Text style={styles.winnerText}>
                낙찰자: {auction.winner.name}
              </Text>
            </View>
          )}
        </View>
      </TouchableOpacity>
    );
  };

  const renderStatusTab = (status: any) => (
    <TouchableOpacity
      key={status.key}
      style={[
        styles.statusTab,
        selectedStatus === status.key && styles.statusTabActive,
      ]}
      onPress={() => handleStatusChange(status.key)}
    >
      <Text
        style={[
          styles.statusTabText,
          selectedStatus === status.key && styles.statusTabTextActive,
        ]}
      >
        {status.label}
      </Text>
    </TouchableOpacity>
  );

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <Ionicons name="arrow-back" size={24} color="#333" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>경매</Text>
        <TouchableOpacity onPress={() => navigation.navigate('CreateAuction')}>
          <Ionicons name="add" size={24} color="#333" />
        </TouchableOpacity>
      </View>

      <View style={styles.statusTabs}>
        {statusTabs.map(renderStatusTab)}
      </View>

      <FlatList
        data={auctions}
        renderItem={renderAuction}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.auctionList}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
        onEndReached={loadMoreAuctions}
        onEndReachedThreshold={0.5}
        ListEmptyComponent={
          !loading ? (
            <View style={styles.emptyContainer}>
              <Ionicons name="hammer-outline" size={64} color="#ccc" />
              <Text style={styles.emptyText}>
                {selectedStatus === 'ACTIVE' ? '진행중인 경매가 없습니다' :
                 selectedStatus === 'SCHEDULED' ? '예정된 경매가 없습니다' :
                 '종료된 경매가 없습니다'}
              </Text>
              <Text style={styles.emptySubtext}>
                {selectedStatus === 'ACTIVE' ? '새로운 경매를 시작해보세요!' : ''}
              </Text>
            </View>
          ) : null
        }
      />
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
  statusTabs: {
    flexDirection: 'row',
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  statusTab: {
    flex: 1,
    paddingVertical: 12,
    alignItems: 'center',
    borderBottomWidth: 2,
    borderBottomColor: 'transparent',
  },
  statusTabActive: {
    borderBottomColor: '#007AFF',
  },
  statusTabText: {
    fontSize: 14,
    color: '#666',
  },
  statusTabTextActive: {
    color: '#007AFF',
    fontWeight: '600',
  },
  auctionList: {
    padding: 16,
  },
  auctionCard: {
    backgroundColor: '#fff',
    borderRadius: 12,
    marginBottom: 16,
    overflow: 'hidden',
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
  },
  imageContainer: {
    position: 'relative',
    height: 200,
  },
  auctionImage: {
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
  statusBadge: {
    position: 'absolute',
    top: 12,
    left: 12,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
  },
  statusText: {
    fontSize: 12,
    fontWeight: 'bold',
    color: '#fff',
  },
  timeBadge: {
    position: 'absolute',
    top: 12,
    right: 12,
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
  },
  timeBadgeExpired: {
    backgroundColor: 'rgba(244, 67, 54, 0.9)',
  },
  timeText: {
    fontSize: 12,
    fontWeight: 'bold',
    color: '#fff',
    marginLeft: 4,
  },
  timeTextExpired: {
    color: '#fff',
  },
  auctionContent: {
    padding: 16,
  },
  auctionTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginBottom: 12,
    lineHeight: 22,
  },
  priceContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 6,
  },
  startPriceLabel: {
    fontSize: 14,
    color: '#666',
  },
  startPrice: {
    fontSize: 14,
    color: '#333',
    fontWeight: '500',
  },
  currentBidLabel: {
    fontSize: 14,
    color: '#666',
  },
  currentBid: {
    fontSize: 16,
    color: '#007AFF',
    fontWeight: 'bold',
  },
  buyNowLabel: {
    fontSize: 14,
    color: '#666',
  },
  buyNowPrice: {
    fontSize: 14,
    color: '#FF5722',
    fontWeight: '600',
  },
  noBidsText: {
    fontSize: 14,
    color: '#999',
    fontStyle: 'italic',
    marginBottom: 6,
  },
  auctionMeta: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 12,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: '#f0f0f0',
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
  bidCount: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  bidCountText: {
    fontSize: 12,
    color: '#666',
    marginLeft: 4,
  },
  timeInfo: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 8,
  },
  endTimeLabel: {
    fontSize: 12,
    color: '#666',
  },
  endTime: {
    fontSize: 12,
    color: '#333',
    fontWeight: '500',
  },
  winnerInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 8,
    padding: 8,
    backgroundColor: '#FFF8E1',
    borderRadius: 6,
  },
  winnerText: {
    fontSize: 12,
    color: '#F57C00',
    fontWeight: '500',
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
});