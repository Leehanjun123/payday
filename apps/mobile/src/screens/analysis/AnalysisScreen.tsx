import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  RefreshControl,
  TouchableOpacity,
  StyleSheet,
  Dimensions,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import predictionService, { MarketAnalysis } from '../../services/predictionService';

const { width } = Dimensions.get('window');

const AnalysisScreen = () => {
  const [analyses, setAnalyses] = useState<MarketAnalysis[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState<string>('all');

  const categories = [
    { key: 'all', label: '전체' },
    { key: 'MARKET_OVERVIEW', label: '시장 전망' },
    { key: 'TECHNICAL_ANALYSIS', label: '기술 분석' },
    { key: 'FUNDAMENTAL_ANALYSIS', label: '기본 분석' },
    { key: 'SECTOR_ANALYSIS', label: '섹터 분석' },
  ];

  useEffect(() => {
    loadAnalyses();
  }, [selectedCategory]);

  const loadAnalyses = async () => {
    try {
      setLoading(true);
      const category = selectedCategory === 'all' ? undefined : selectedCategory;
      const response = await predictionService.getAnalyses(undefined, category, 50);
      setAnalyses(response.analyses);
    } catch (error) {
      console.error('Error loading analyses:', error);
      Alert.alert('오류', '분석 정보를 불러오는데 실패했습니다.');
    } finally {
      setLoading(false);
    }
  };

  const onRefresh = async () => {
    setRefreshing(true);
    await loadAnalyses();
    setRefreshing(false);
  };

  const initDemoData = async () => {
    try {
      await predictionService.initDemoAnalyses();
      Alert.alert('성공', '데모 분석 데이터가 생성되었습니다.');
      await loadAnalyses();
    } catch (error) {
      console.error('Error initializing demo data:', error);
      Alert.alert('오류', '데모 데이터 생성에 실패했습니다.');
    }
  };

  const handleLike = async (analysisId: string) => {
    try {
      await predictionService.likeAnalysis(analysisId);
      // Update the local state to reflect the like
      setAnalyses(prev => prev.map(analysis =>
        analysis.id === analysisId
          ? { ...analysis, likeCount: analysis.likeCount + 1 }
          : analysis
      ));
    } catch (error) {
      console.error('Error liking analysis:', error);
    }
  };

  const renderAnalysisCard = (analysis: MarketAnalysis) => {
    return (
      <View key={analysis.id} style={styles.analysisCard}>
        <View style={styles.cardHeader}>
          <View style={styles.titleSection}>
            <Text style={styles.title}>{analysis.title}</Text>
            {analysis.symbol && (
              <Text style={styles.symbol}>{analysis.symbol}</Text>
            )}
          </View>
          <View style={styles.categoryTag}>
            <Text style={styles.categoryText}>
              {predictionService.getAnalysisCategoryText(analysis.category)}
            </Text>
          </View>
        </View>

        <Text style={styles.summary}>{analysis.summary}</Text>

        <View style={styles.metricsRow}>
          <View style={styles.metricItem}>
            <Text style={styles.metricLabel}>심리</Text>
            <View style={[
              styles.sentimentBadge,
              { backgroundColor: predictionService.getSentimentColor(analysis.sentiment) }
            ]}>
              <Text style={styles.sentimentText}>
                {predictionService.getSentimentText(analysis.sentiment)}
              </Text>
            </View>
          </View>

          <View style={styles.metricItem}>
            <Text style={styles.metricLabel}>리스크</Text>
            <View style={[
              styles.riskBadge,
              { backgroundColor: predictionService.getRiskLevelColor(analysis.riskLevel) }
            ]}>
              <Text style={styles.riskText}>
                {predictionService.getRiskLevelText(analysis.riskLevel)}
              </Text>
            </View>
          </View>
        </View>

        {analysis.recommendations && (
          <View style={styles.recommendationsSection}>
            <Text style={styles.recommendationsTitle}>투자 권고사항</Text>
            <Text style={styles.recommendations}>{analysis.recommendations}</Text>
          </View>
        )}

        {analysis.tags && analysis.tags.length > 0 && (
          <View style={styles.tagsSection}>
            <ScrollView horizontal showsHorizontalScrollIndicator={false}>
              {analysis.tags.map((tag, index) => (
                <View key={index} style={styles.tag}>
                  <Text style={styles.tagText}>#{tag}</Text>
                </View>
              ))}
            </ScrollView>
          </View>
        )}

        <View style={styles.cardFooter}>
          <View style={styles.statsContainer}>
            <View style={styles.statItem}>
              <Ionicons name="eye-outline" size={16} color="#666" />
              <Text style={styles.statText}>{analysis.viewCount}</Text>
            </View>
            <TouchableOpacity
              style={styles.statItem}
              onPress={() => handleLike(analysis.id)}
            >
              <Ionicons name="heart-outline" size={16} color="#666" />
              <Text style={styles.statText}>{analysis.likeCount}</Text>
            </TouchableOpacity>
          </View>
          <Text style={styles.dateText}>
            {predictionService.formatDateShort(analysis.createdAt)}
          </Text>
        </View>
      </View>
    );
  };

  if (loading && analyses.length === 0) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#007AFF" />
        <Text style={styles.loadingText}>분석 정보를 불러오는 중...</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>시장 분석</Text>
        <TouchableOpacity onPress={initDemoData} style={styles.demoButton}>
          <Ionicons name="flask-outline" size={20} color="#007AFF" />
          <Text style={styles.demoButtonText}>데모</Text>
        </TouchableOpacity>
      </View>

      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        style={styles.categoryFilter}
        contentContainerStyle={styles.categoryFilterContent}
      >
        {categories.map((category) => (
          <TouchableOpacity
            key={category.key}
            style={[
              styles.categoryButton,
              selectedCategory === category.key && styles.categoryButtonActive
            ]}
            onPress={() => setSelectedCategory(category.key)}
          >
            <Text style={[
              styles.categoryButtonText,
              selectedCategory === category.key && styles.categoryButtonTextActive
            ]}>
              {category.label}
            </Text>
          </TouchableOpacity>
        ))}
      </ScrollView>

      <ScrollView
        style={styles.content}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
      >
        {analyses.length === 0 ? (
          <View style={styles.emptyContainer}>
            <Ionicons name="bar-chart-outline" size={64} color="#ccc" />
            <Text style={styles.emptyTitle}>분석 정보가 없습니다</Text>
            <Text style={styles.emptySubtitle}>데모 버튼을 눌러 분석 데이터를 생성해보세요</Text>
          </View>
        ) : (
          analyses.map(renderAnalysisCard)
        )}
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingTop: 20,
    paddingBottom: 10,
    backgroundColor: '#fff',
  },
  headerTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#333',
  },
  demoButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#f0f8ff',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 15,
  },
  demoButtonText: {
    color: '#007AFF',
    fontSize: 14,
    fontWeight: '600',
    marginLeft: 4,
  },
  categoryFilter: {
    backgroundColor: '#fff',
    paddingVertical: 10,
  },
  categoryFilterContent: {
    paddingHorizontal: 20,
  },
  categoryButton: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: '#f8f9fa',
    marginRight: 10,
  },
  categoryButtonActive: {
    backgroundColor: '#007AFF',
  },
  categoryButtonText: {
    fontSize: 14,
    color: '#666',
    fontWeight: '500',
  },
  categoryButtonTextActive: {
    color: '#fff',
    fontWeight: '600',
  },
  content: {
    flex: 1,
    padding: 20,
  },
  analysisCard: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 12,
  },
  titleSection: {
    flex: 1,
    marginRight: 12,
  },
  title: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#333',
    lineHeight: 22,
    marginBottom: 4,
  },
  symbol: {
    fontSize: 14,
    color: '#666',
    fontWeight: '500',
  },
  categoryTag: {
    backgroundColor: '#E3F2FD',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 8,
  },
  categoryText: {
    fontSize: 12,
    color: '#1976D2',
    fontWeight: '600',
  },
  summary: {
    fontSize: 14,
    color: '#333',
    lineHeight: 20,
    marginBottom: 16,
  },
  metricsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 16,
  },
  metricItem: {
    flex: 1,
    marginRight: 12,
  },
  metricLabel: {
    fontSize: 12,
    color: '#666',
    marginBottom: 4,
  },
  sentimentBadge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 8,
    alignSelf: 'flex-start',
  },
  sentimentText: {
    fontSize: 12,
    color: '#fff',
    fontWeight: '600',
  },
  riskBadge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 8,
    alignSelf: 'flex-start',
  },
  riskText: {
    fontSize: 12,
    color: '#fff',
    fontWeight: '600',
  },
  recommendationsSection: {
    backgroundColor: '#F8F9FA',
    padding: 12,
    borderRadius: 8,
    marginBottom: 12,
  },
  recommendationsTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
    marginBottom: 6,
  },
  recommendations: {
    fontSize: 13,
    color: '#555',
    lineHeight: 18,
  },
  tagsSection: {
    marginBottom: 12,
  },
  tag: {
    backgroundColor: '#F0F0F0',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 12,
    marginRight: 6,
  },
  tagText: {
    fontSize: 12,
    color: '#666',
    fontWeight: '500',
  },
  cardFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: '#f0f0f0',
  },
  statsContainer: {
    flexDirection: 'row',
  },
  statItem: {
    flexDirection: 'row',
    alignItems: 'center',
    marginRight: 16,
  },
  statText: {
    fontSize: 12,
    color: '#666',
    marginLeft: 4,
  },
  dateText: {
    fontSize: 12,
    color: '#999',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#f5f5f5',
  },
  loadingText: {
    marginTop: 16,
    fontSize: 16,
    color: '#666',
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: 60,
  },
  emptyTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
    marginTop: 16,
    marginBottom: 8,
  },
  emptySubtitle: {
    fontSize: 14,
    color: '#666',
    textAlign: 'center',
  },
});

export default AnalysisScreen;