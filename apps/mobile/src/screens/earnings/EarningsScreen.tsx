import React, { useState, useEffect } from 'react';
import {
  StyleSheet,
  Text,
  View,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
  ActivityIndicator,
  FlatList,
  Dimensions,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import earningsService, { EarningsSummary, Transaction } from '../../services/earningsService';

const { width } = Dimensions.get('window');

export default function EarningsScreen({ navigation }: any) {
  const [summary, setSummary] = useState<EarningsSummary | null>(null);
  const [recentTransactions, setRecentTransactions] = useState<Transaction[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const [summaryData, transactionsData] = await Promise.all([
        earningsService.getEarningsSummary(),
        earningsService.getTransactionHistory(1, 5),
      ]);

      setSummary(summaryData);
      setRecentTransactions(transactionsData.transactions);
    } catch (error) {
      console.error('Error loading earnings data:', error);
      // Set mock data for development
      setSummary({
        totalEarnings: 2500000,
        availableBalance: 850000,
        pendingAmount: 150000,
        completedTasks: 24,
        thisMonthEarnings: 680000,
        lastMonthEarnings: 520000,
      });
      setRecentTransactions([
        {
          id: '1',
          type: 'EARNING',
          amount: 150000,
          description: '로고 디자인 작업 완료',
          status: 'COMPLETED',
          createdAt: new Date().toISOString(),
        },
        {
          id: '2',
          type: 'WITHDRAWAL',
          amount: -500000,
          description: '계좌 출금',
          status: 'COMPLETED',
          createdAt: new Date(Date.now() - 86400000).toISOString(),
        },
      ]);
    } finally {
      setLoading(false);
    }
  };

  const handleRefresh = async () => {
    setRefreshing(true);
    await loadData();
    setRefreshing(false);
  };

  const formatAmount = (amount: number) => {
    const absAmount = Math.abs(amount);
    if (absAmount >= 10000) {
      return `${(absAmount / 10000).toFixed(1)}만원`;
    }
    return `${absAmount.toLocaleString()}원`;
  };

  const getTransactionIcon = (type: string) => {
    switch (type) {
      case 'EARNING':
        return 'arrow-down-circle';
      case 'WITHDRAWAL':
        return 'arrow-up-circle';
      case 'REFUND':
        return 'refresh-circle';
      case 'BONUS':
        return 'gift';
      default:
        return 'cash-outline';
    }
  };

  const getTransactionColor = (type: string) => {
    switch (type) {
      case 'EARNING':
      case 'BONUS':
        return '#4CAF50';
      case 'WITHDRAWAL':
        return '#FF5252';
      case 'REFUND':
        return '#FF9800';
      default:
        return '#666';
    }
  };

  const renderTransaction = ({ item }: { item: Transaction }) => (
    <TouchableOpacity style={styles.transactionItem}>
      <View
        style={[
          styles.transactionIcon,
          { backgroundColor: getTransactionColor(item.type) + '20' },
        ]}
      >
        <Ionicons
          name={getTransactionIcon(item.type) as any}
          size={24}
          color={getTransactionColor(item.type)}
        />
      </View>
      <View style={styles.transactionDetails}>
        <Text style={styles.transactionDescription} numberOfLines={1}>
          {item.description}
        </Text>
        <Text style={styles.transactionDate}>
          {new Date(item.createdAt).toLocaleDateString('ko-KR', {
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
          })}
        </Text>
      </View>
      <Text
        style={[
          styles.transactionAmount,
          { color: item.amount > 0 ? '#4CAF50' : '#FF5252' },
        ]}
      >
        {item.amount > 0 ? '+' : ''}{formatAmount(item.amount)}
      </Text>
    </TouchableOpacity>
  );

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#007AFF" />
        </View>
      </SafeAreaView>
    );
  }

  const monthlyGrowth = summary
    ? ((summary.thisMonthEarnings - summary.lastMonthEarnings) / summary.lastMonthEarnings) * 100
    : 0;

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView
        style={styles.content}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={handleRefresh} />
        }
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.header}>
          <Text style={styles.headerTitle}>수익 관리</Text>
          <TouchableOpacity
            style={styles.withdrawButton}
            onPress={() => navigation.navigate('Withdraw')}
          >
            <Ionicons name="wallet-outline" size={20} color="#fff" />
            <Text style={styles.withdrawButtonText}>출금</Text>
          </TouchableOpacity>
        </View>

        <View style={styles.balanceCard}>
          <Text style={styles.balanceLabel}>사용 가능 잔액</Text>
          <Text style={styles.balanceAmount}>
            ₩{summary ? formatAmount(summary.availableBalance) : '0'}
          </Text>
          <View style={styles.balanceDetails}>
            <View style={styles.balanceDetailItem}>
              <Text style={styles.balanceDetailLabel}>총 수익</Text>
              <Text style={styles.balanceDetailValue}>
                ₩{summary ? formatAmount(summary.totalEarnings) : '0'}
              </Text>
            </View>
            <View style={styles.balanceDetailDivider} />
            <View style={styles.balanceDetailItem}>
              <Text style={styles.balanceDetailLabel}>대기중</Text>
              <Text style={styles.balanceDetailValue}>
                ₩{summary ? formatAmount(summary.pendingAmount) : '0'}
              </Text>
            </View>
          </View>
        </View>

        <View style={styles.statsContainer}>
          <View style={styles.statCard}>
            <View style={styles.statHeader}>
              <Ionicons name="trending-up" size={20} color="#4CAF50" />
              <Text style={styles.statTitle}>이번 달 수익</Text>
            </View>
            <Text style={styles.statAmount}>
              ₩{summary ? formatAmount(summary.thisMonthEarnings) : '0'}
            </Text>
            <View style={styles.statGrowth}>
              <Ionicons
                name={monthlyGrowth >= 0 ? 'arrow-up' : 'arrow-down'}
                size={16}
                color={monthlyGrowth >= 0 ? '#4CAF50' : '#FF5252'}
              />
              <Text
                style={[
                  styles.statGrowthText,
                  { color: monthlyGrowth >= 0 ? '#4CAF50' : '#FF5252' },
                ]}
              >
                {Math.abs(monthlyGrowth).toFixed(1)}%
              </Text>
            </View>
          </View>

          <View style={styles.statCard}>
            <View style={styles.statHeader}>
              <Ionicons name="checkmark-circle" size={20} color="#007AFF" />
              <Text style={styles.statTitle}>완료 작업</Text>
            </View>
            <Text style={styles.statAmount}>
              {summary ? summary.completedTasks : 0}개
            </Text>
            <Text style={styles.statSubtext}>이번 달</Text>
          </View>
        </View>

        <View style={styles.quickActions}>
          <TouchableOpacity
            style={styles.actionButton}
            onPress={() => navigation.navigate('Analytics')}
          >
            <Ionicons name="bar-chart-outline" size={24} color="#007AFF" />
            <Text style={styles.actionButtonText}>수익 분석</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.actionButton}
            onPress={() => navigation.navigate('History')}
          >
            <Ionicons name="time-outline" size={24} color="#007AFF" />
            <Text style={styles.actionButtonText}>거래 내역</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.actionButton}
            onPress={() => navigation.navigate('TaxInfo')}
          >
            <Ionicons name="document-text-outline" size={24} color="#007AFF" />
            <Text style={styles.actionButtonText}>세금 정보</Text>
          </TouchableOpacity>
        </View>

        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>최근 거래</Text>
            <TouchableOpacity onPress={() => navigation.navigate('History')}>
              <Text style={styles.seeAllText}>전체보기</Text>
            </TouchableOpacity>
          </View>

          {recentTransactions.length > 0 ? (
            <View style={styles.transactionsList}>
              {recentTransactions.map((transaction) => (
                <View key={transaction.id}>
                  {renderTransaction({ item: transaction })}
                </View>
              ))}
            </View>
          ) : (
            <View style={styles.emptyTransactions}>
              <Text style={styles.emptyText}>최근 거래가 없습니다</Text>
            </View>
          )}
        </View>

        <View style={styles.tipCard}>
          <Ionicons name="bulb-outline" size={24} color="#FF9800" />
          <View style={styles.tipContent}>
            <Text style={styles.tipTitle}>수익 증대 팁</Text>
            <Text style={styles.tipText}>
              프로필을 완성하고 스킬을 추가하면 더 많은 작업 기회를 받을 수 있습니다!
            </Text>
          </View>
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
  content: {
    flex: 1,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 16,
    backgroundColor: '#fff',
  },
  headerTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#333',
  },
  withdrawButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#007AFF',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
  },
  withdrawButtonText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: '600',
    marginLeft: 6,
  },
  balanceCard: {
    backgroundColor: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
    backgroundColor: '#007AFF',
    margin: 20,
    padding: 24,
    borderRadius: 16,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 4,
    },
    shadowOpacity: 0.2,
    shadowRadius: 5.46,
    elevation: 9,
  },
  balanceLabel: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.8)',
    marginBottom: 8,
  },
  balanceAmount: {
    fontSize: 36,
    fontWeight: 'bold',
    color: '#fff',
    marginBottom: 20,
  },
  balanceDetails: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingTop: 16,
    borderTopWidth: 1,
    borderTopColor: 'rgba(255, 255, 255, 0.2)',
  },
  balanceDetailItem: {
    flex: 1,
  },
  balanceDetailLabel: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
    marginBottom: 4,
  },
  balanceDetailValue: {
    fontSize: 16,
    color: '#fff',
    fontWeight: '600',
  },
  balanceDetailDivider: {
    width: 1,
    height: 30,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    marginHorizontal: 20,
  },
  statsContainer: {
    flexDirection: 'row',
    paddingHorizontal: 20,
    marginBottom: 20,
  },
  statCard: {
    flex: 1,
    backgroundColor: '#fff',
    padding: 16,
    borderRadius: 12,
    marginRight: 12,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.1,
    shadowRadius: 3.84,
    elevation: 5,
  },
  statCard2: {
    marginRight: 0,
    marginLeft: 12,
  },
  statHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  statTitle: {
    fontSize: 14,
    color: '#666',
    marginLeft: 8,
  },
  statAmount: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 4,
  },
  statGrowth: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  statGrowthText: {
    fontSize: 14,
    fontWeight: '600',
    marginLeft: 4,
  },
  statSubtext: {
    fontSize: 12,
    color: '#999',
  },
  quickActions: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    paddingHorizontal: 20,
    marginBottom: 24,
  },
  actionButton: {
    alignItems: 'center',
    backgroundColor: '#fff',
    paddingVertical: 16,
    paddingHorizontal: 20,
    borderRadius: 12,
    flex: 1,
    marginHorizontal: 6,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.1,
    shadowRadius: 3.84,
    elevation: 5,
  },
  actionButtonText: {
    fontSize: 12,
    color: '#333',
    marginTop: 8,
    fontWeight: '500',
  },
  section: {
    paddingHorizontal: 20,
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
  seeAllText: {
    fontSize: 14,
    color: '#007AFF',
    fontWeight: '500',
  },
  transactionsList: {
    backgroundColor: '#fff',
    borderRadius: 12,
    overflow: 'hidden',
  },
  transactionItem: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  transactionIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  transactionDetails: {
    flex: 1,
  },
  transactionDescription: {
    fontSize: 14,
    color: '#333',
    fontWeight: '500',
    marginBottom: 2,
  },
  transactionDate: {
    fontSize: 12,
    color: '#999',
  },
  transactionAmount: {
    fontSize: 16,
    fontWeight: '600',
  },
  emptyTransactions: {
    backgroundColor: '#fff',
    padding: 32,
    borderRadius: 12,
    alignItems: 'center',
  },
  emptyText: {
    fontSize: 14,
    color: '#999',
  },
  tipCard: {
    flexDirection: 'row',
    backgroundColor: '#FFF8E1',
    padding: 16,
    marginHorizontal: 20,
    marginBottom: 20,
    borderRadius: 12,
    borderLeftWidth: 4,
    borderLeftColor: '#FF9800',
  },
  tipContent: {
    flex: 1,
    marginLeft: 12,
  },
  tipTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#F57C00',
    marginBottom: 4,
  },
  tipText: {
    fontSize: 12,
    color: '#666',
    lineHeight: 18,
  },
});