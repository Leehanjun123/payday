import React, { useState, useEffect, useCallback } from 'react';
import {
  StyleSheet,
  Text,
  View,
  ScrollView,
  TouchableOpacity,
  FlatList,
  Alert,
  RefreshControl,
  Dimensions,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { LineChart } from 'react-native-chart-kit';
import investmentService, { Portfolio, WatchlistItem } from '../../services/investmentService';

const { width } = Dimensions.get('window');

export default function InvestmentDashboardScreen({ navigation }: any) {
  const [portfolios, setPortfolios] = useState<Portfolio[]>([]);
  const [watchlist, setWatchlist] = useState<WatchlistItem[]>([]);
  const [summary, setSummary] = useState({
    totalValue: 0,
    totalCost: 0,
    totalProfitLoss: 0,
    totalProfitLossRate: 0,
    portfolioCount: 0,
  });
  const [loading, setLoading] = useState(false);
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    loadDashboardData();
    initializeDemoData();
  }, []);

  const initializeDemoData = async () => {
    try {
      await investmentService.initDemoData();
    } catch (error) {
      // Demo data already exists
    }
  };

  const loadDashboardData = async () => {
    setLoading(true);
    try {
      const [portfoliosResponse, watchlistResponse] = await Promise.all([
        investmentService.getUserPortfolios(),
        investmentService.getUserWatchlist(),
      ]);

      setPortfolios(portfoliosResponse.portfolios);
      setWatchlist(watchlistResponse.watchlist);

      const calculatedSummary = investmentService.calculatePortfolioSummary(portfoliosResponse.portfolios);
      setSummary(calculatedSummary);
    } catch (error: any) {
      Alert.alert('오류', error.message || '대시보드 데이터를 불러오는데 실패했습니다.');
    } finally {
      setLoading(false);
    }
  };

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await loadDashboardData();
    setRefreshing(false);
  }, []);

  const handleCreatePortfolio = () => {
    navigation.navigate('CreatePortfolio');
  };

  const handlePortfolioPress = (portfolio: Portfolio) => {
    navigation.navigate('PortfolioDetail', { portfolioId: portfolio.id });
  };

  const handleWatchlistPress = () => {
    navigation.navigate('Watchlist');
  };

  const handleMarketPress = () => {
    navigation.navigate('MarketOverview');
  };

  const simulateMarketUpdate = async () => {
    try {
      await investmentService.simulateMarketUpdate();
      await loadDashboardData();
      Alert.alert('성공', '시장 데이터가 업데이트되었습니다.');
    } catch (error: any) {
      Alert.alert('오류', error.message || '시장 업데이트에 실패했습니다.');
    }
  };

  const handlePredictionPress = () => {
    navigation.navigate('Prediction');
  };

  const handleAnalysisPress = () => {
    navigation.navigate('Analysis');
  };

  const handleAlertsPress = () => {
    navigation.navigate('Alerts');
  };

  const profitLossColor = summary.totalProfitLoss >= 0 ? '#4CAF50' : '#F44336';
  const profitLossText = summary.totalProfitLoss >= 0 ? '+' : '';

  // Mock chart data for demonstration
  const chartData = {
    labels: ['1월', '2월', '3월', '4월', '5월', '6월'],
    datasets: [
      {
        data: [
          summary.totalValue * 0.8,
          summary.totalValue * 0.85,
          summary.totalValue * 0.9,
          summary.totalValue * 0.95,
          summary.totalValue * 0.98,
          summary.totalValue,
        ],
        color: (opacity = 1) => `rgba(76, 175, 80, ${opacity})`,
        strokeWidth: 2,
      },
    ],
  };

  const renderPortfolio = ({ item: portfolio }: { item: Portfolio }) => {
    const profitLoss = portfolio.totalValue - portfolio.totalCost;
    const profitLossRate = portfolio.totalCost > 0 ? (profitLoss / portfolio.totalCost) * 100 : 0;
    const isPositive = profitLoss >= 0;

    return (
      <TouchableOpacity
        style={styles.portfolioCard}
        onPress={() => handlePortfolioPress(portfolio)}
      >
        <View style={styles.portfolioHeader}>
          <Text style={styles.portfolioName}>{portfolio.name}</Text>
          <Text style={styles.portfolioHoldings}>
            {portfolio._count.holdings}개 종목
          </Text>
        </View>

        <View style={styles.portfolioValues}>
          <Text style={styles.portfolioValue}>
            {investmentService.formatPrice(portfolio.totalValue)}
          </Text>
          <View style={styles.profitLossContainer}>
            <Text style={[styles.profitLoss, { color: isPositive ? '#4CAF50' : '#F44336' }]}>
              {isPositive ? '+' : ''}{investmentService.formatPrice(Math.abs(profitLoss))}
            </Text>
            <Text style={[styles.profitLossRate, { color: isPositive ? '#4CAF50' : '#F44336' }]}>
              ({isPositive ? '+' : ''}{profitLossRate.toFixed(2)}%)
            </Text>
          </View>
        </View>

        {portfolio.description && (
          <Text style={styles.portfolioDescription} numberOfLines={1}>
            {portfolio.description}
          </Text>
        )}
      </TouchableOpacity>
    );
  };

  const renderWatchlistItem = ({ item }: { item: WatchlistItem }) => (
    <TouchableOpacity style={styles.watchlistItem}>
      <View style={styles.watchlistInfo}>
        <Text style={styles.watchlistSymbol}>{item.symbol}</Text>
        <Text style={styles.watchlistName} numberOfLines={1}>
          {item.name}
        </Text>
        <View style={[styles.assetTypeBadge, { backgroundColor: investmentService.getAssetTypeColor(item.type) }]}>
          <Text style={styles.assetTypeText}>
            {investmentService.getAssetTypeText(item.type)}
          </Text>
        </View>
      </View>

      {item.marketData && (
        <View style={styles.watchlistPrice}>
          <Text style={styles.currentPrice}>
            {investmentService.formatPrice(
              item.marketData.currentPrice,
              investmentService.getCurrencyByAssetType(item.type)
            )}
          </Text>
          <Text
            style={[
              styles.priceChange,
              { color: item.marketData.change >= 0 ? '#4CAF50' : '#F44336' }
            ]}
          >
            {item.marketData.change >= 0 ? '+' : ''}
            {item.marketData.changePercent.toFixed(2)}%
          </Text>
        </View>
      )}
    </TouchableOpacity>
  );

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>투자 대시보드</Text>
        <View style={styles.headerActions}>
          <TouchableOpacity style={styles.headerButton} onPress={simulateMarketUpdate}>
            <Ionicons name="refresh" size={24} color="#333" />
          </TouchableOpacity>
          <TouchableOpacity style={styles.headerButton} onPress={handleMarketPress}>
            <Ionicons name="trending-up" size={24} color="#333" />
          </TouchableOpacity>
        </View>
      </View>

      <ScrollView
        style={styles.content}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
        showsVerticalScrollIndicator={false}
      >
        {/* Portfolio Summary */}
        <View style={styles.summaryCard}>
          <Text style={styles.summaryTitle}>총 자산</Text>
          <Text style={styles.totalValue}>
            {investmentService.formatPrice(summary.totalValue)}
          </Text>

          <View style={styles.summaryDetails}>
            <View style={styles.summaryItem}>
              <Text style={styles.summaryLabel}>투자 원금</Text>
              <Text style={styles.summaryAmount}>
                {investmentService.formatPrice(summary.totalCost)}
              </Text>
            </View>

            <View style={styles.summaryItem}>
              <Text style={styles.summaryLabel}>손익</Text>
              <Text style={[styles.summaryAmount, { color: profitLossColor }]}>
                {profitLossText}{investmentService.formatPrice(Math.abs(summary.totalProfitLoss))}
              </Text>
            </View>

            <View style={styles.summaryItem}>
              <Text style={styles.summaryLabel}>수익률</Text>
              <Text style={[styles.summaryAmount, { color: profitLossColor }]}>
                {profitLossText}{summary.totalProfitLossRate.toFixed(2)}%
              </Text>
            </View>
          </View>
        </View>

        {/* Portfolio Performance Chart */}
        {summary.totalValue > 0 && (
          <View style={styles.chartCard}>
            <Text style={styles.chartTitle}>포트폴리오 성과</Text>
            <LineChart
              data={chartData}
              width={width - 40}
              height={180}
              chartConfig={{
                backgroundColor: '#ffffff',
                backgroundGradientFrom: '#ffffff',
                backgroundGradientTo: '#ffffff',
                decimalPlaces: 0,
                color: (opacity = 1) => `rgba(76, 175, 80, ${opacity})`,
                labelColor: (opacity = 1) => `rgba(0, 0, 0, ${opacity})`,
                style: {
                  borderRadius: 16,
                },
                propsForDots: {
                  r: '4',
                  strokeWidth: '2',
                  stroke: '#4CAF50',
                },
              }}
              bezier
              style={styles.chart}
            />
          </View>
        )}

        {/* Quick Actions */}
        <View style={styles.quickActions}>
          <TouchableOpacity style={styles.actionButton} onPress={handleCreatePortfolio}>
            <Ionicons name="add-circle" size={24} color="#007AFF" />
            <Text style={styles.actionText}>포트폴리오 생성</Text>
          </TouchableOpacity>

          <TouchableOpacity style={styles.actionButton} onPress={handleWatchlistPress}>
            <Ionicons name="star" size={24} color="#FF9800" />
            <Text style={styles.actionText}>관심종목</Text>
          </TouchableOpacity>

          <TouchableOpacity style={styles.actionButton} onPress={handleMarketPress}>
            <Ionicons name="trending-up" size={24} color="#4CAF50" />
            <Text style={styles.actionText}>시장현황</Text>
          </TouchableOpacity>
        </View>

        {/* AI Analysis Section */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>AI 분석</Text>

          <View style={styles.analysisActions}>
            <TouchableOpacity style={styles.analysisButton} onPress={handlePredictionPress}>
              <View style={styles.analysisIconContainer}>
                <Ionicons name="analytics" size={24} color="#9C27B0" />
              </View>
              <Text style={styles.analysisTitle}>AI 예측</Text>
              <Text style={styles.analysisSubtitle}>투자 목표가 예측 및 시장 전망</Text>
            </TouchableOpacity>

            <TouchableOpacity style={styles.analysisButton} onPress={handleAnalysisPress}>
              <View style={styles.analysisIconContainer}>
                <Ionicons name="bar-chart" size={24} color="#FF5722" />
              </View>
              <Text style={styles.analysisTitle}>시장 분석</Text>
              <Text style={styles.analysisSubtitle}>전문가 분석 및 투자 인사이트</Text>
            </TouchableOpacity>

            <TouchableOpacity style={styles.analysisButton} onPress={handleAlertsPress}>
              <View style={styles.analysisIconContainer}>
                <Ionicons name="notifications" size={24} color="#F44336" />
              </View>
              <Text style={styles.analysisTitle}>가격 알림</Text>
              <Text style={styles.analysisSubtitle}>목표가 달성 시 실시간 알림</Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* My Portfolios */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>내 포트폴리오</Text>
            <TouchableOpacity onPress={handleCreatePortfolio}>
              <Text style={styles.sectionAction}>+ 추가</Text>
            </TouchableOpacity>
          </View>

          {portfolios.length > 0 ? (
            <FlatList
              data={portfolios}
              renderItem={renderPortfolio}
              keyExtractor={(item) => item.id}
              horizontal
              showsHorizontalScrollIndicator={false}
              contentContainerStyle={styles.portfolioList}
            />
          ) : (
            <View style={styles.emptyState}>
              <Ionicons name="pie-chart-outline" size={48} color="#ccc" />
              <Text style={styles.emptyText}>포트폴리오가 없습니다</Text>
              <Text style={styles.emptySubtext}>첫 번째 포트폴리오를 만들어보세요</Text>
            </View>
          )}
        </View>

        {/* Watchlist Preview */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>관심종목</Text>
            <TouchableOpacity onPress={handleWatchlistPress}>
              <Text style={styles.sectionAction}>전체보기</Text>
            </TouchableOpacity>
          </View>

          {watchlist.length > 0 ? (
            <FlatList
              data={watchlist.slice(0, 3)}
              renderItem={renderWatchlistItem}
              keyExtractor={(item) => item.id}
              scrollEnabled={false}
            />
          ) : (
            <View style={styles.emptyState}>
              <Ionicons name="star-outline" size={48} color="#ccc" />
              <Text style={styles.emptyText}>관심종목이 없습니다</Text>
              <Text style={styles.emptySubtext}>관심있는 종목을 추가해보세요</Text>
            </View>
          )}
        </View>
      </ScrollView>
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
  content: {
    flex: 1,
  },
  summaryCard: {
    backgroundColor: '#fff',
    margin: 20,
    padding: 24,
    borderRadius: 16,
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  summaryTitle: {
    fontSize: 14,
    color: '#666',
    marginBottom: 8,
  },
  totalValue: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 20,
  },
  summaryDetails: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  summaryItem: {
    alignItems: 'center',
  },
  summaryLabel: {
    fontSize: 12,
    color: '#666',
    marginBottom: 4,
  },
  summaryAmount: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
  },
  chartCard: {
    backgroundColor: '#fff',
    marginHorizontal: 20,
    marginBottom: 20,
    padding: 20,
    borderRadius: 16,
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  chartTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginBottom: 16,
  },
  chart: {
    marginVertical: 8,
    borderRadius: 16,
  },
  quickActions: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    backgroundColor: '#fff',
    marginHorizontal: 20,
    marginBottom: 20,
    padding: 20,
    borderRadius: 16,
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  actionButton: {
    alignItems: 'center',
  },
  actionText: {
    fontSize: 12,
    color: '#333',
    marginTop: 8,
    fontWeight: '500',
  },
  section: {
    marginHorizontal: 20,
    marginBottom: 24,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
  },
  sectionAction: {
    fontSize: 14,
    color: '#007AFF',
    fontWeight: '500',
  },
  portfolioList: {
    paddingRight: 20,
  },
  portfolioCard: {
    backgroundColor: '#fff',
    padding: 20,
    borderRadius: 12,
    marginRight: 16,
    width: 280,
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
  },
  portfolioHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  portfolioName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    flex: 1,
  },
  portfolioHoldings: {
    fontSize: 12,
    color: '#666',
  },
  portfolioValues: {
    marginBottom: 8,
  },
  portfolioValue: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 4,
  },
  profitLossContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  profitLoss: {
    fontSize: 14,
    fontWeight: '600',
    marginRight: 8,
  },
  profitLossRate: {
    fontSize: 14,
    fontWeight: '500',
  },
  portfolioDescription: {
    fontSize: 12,
    color: '#666',
  },
  watchlistItem: {
    backgroundColor: '#fff',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 16,
    borderRadius: 12,
    marginBottom: 8,
    elevation: 1,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 1,
  },
  watchlistInfo: {
    flex: 1,
  },
  watchlistSymbol: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginBottom: 2,
  },
  watchlistName: {
    fontSize: 12,
    color: '#666',
    marginBottom: 4,
  },
  assetTypeBadge: {
    alignSelf: 'flex-start',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  assetTypeText: {
    fontSize: 10,
    color: '#fff',
    fontWeight: '500',
  },
  watchlistPrice: {
    alignItems: 'flex-end',
  },
  currentPrice: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
    marginBottom: 2,
  },
  priceChange: {
    fontSize: 12,
    fontWeight: '500',
  },
  emptyState: {
    alignItems: 'center',
    paddingVertical: 40,
  },
  emptyText: {
    fontSize: 16,
    color: '#666',
    marginTop: 12,
    marginBottom: 4,
  },
  emptySubtext: {
    fontSize: 14,
    color: '#999',
  },
  analysisActions: {
    gap: 12,
  },
  analysisButton: {
    backgroundColor: '#fff',
    padding: 16,
    borderRadius: 12,
    flexDirection: 'row',
    alignItems: 'center',
    elevation: 1,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
  },
  analysisIconContainer: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#f8f9fa',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 16,
  },
  analysisTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginBottom: 2,
    flex: 1,
  },
  analysisSubtitle: {
    fontSize: 12,
    color: '#666',
    flex: 1,
  },
});