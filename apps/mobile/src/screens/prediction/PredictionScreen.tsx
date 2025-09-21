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
import predictionService, { Prediction } from '../../services/predictionService';

const { width } = Dimensions.get('window');

const PredictionScreen = () => {
  const [predictions, setPredictions] = useState<Prediction[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [selectedType, setSelectedType] = useState<string>('all');

  const predictionTypes = [
    { key: 'all', label: '전체' },
    { key: 'PRICE_TARGET', label: '목표가' },
    { key: 'TREND_ANALYSIS', label: '추세' },
    { key: 'VOLATILITY', label: '변동성' },
    { key: 'SENTIMENT', label: '심리' },
  ];

  useEffect(() => {
    loadPredictions();
  }, [selectedType]);

  const loadPredictions = async () => {
    try {
      setLoading(true);
      const type = selectedType === 'all' ? undefined : selectedType;
      const response = await predictionService.getPredictions(undefined, type, 50);
      setPredictions(response.predictions);
    } catch (error) {
      console.error('Error loading predictions:', error);
      Alert.alert('오류', '예측 정보를 불러오는데 실패했습니다.');
    } finally {
      setLoading(false);
    }
  };

  const onRefresh = async () => {
    setRefreshing(true);
    await loadPredictions();
    setRefreshing(false);
  };

  const initDemoData = async () => {
    try {
      await predictionService.initDemoPredictions();
      Alert.alert('성공', '데모 예측 데이터가 생성되었습니다.');
      await loadPredictions();
    } catch (error) {
      console.error('Error initializing demo data:', error);
      Alert.alert('오류', '데모 데이터 생성에 실패했습니다.');
    }
  };

  const getConfidenceColor = (confidence: number) => {
    if (confidence >= 80) return '#4CAF50';
    if (confidence >= 60) return '#FF9800';
    return '#F44336';
  };

  const renderPredictionCard = (prediction: Prediction) => {
    const isPositive = prediction.predictedPrice > prediction.currentPrice;
    const changePercent = ((prediction.predictedPrice - prediction.currentPrice) / prediction.currentPrice) * 100;
    const daysLeft = predictionService.getDaysUntilExpiry(prediction.validUntil);

    return (
      <View key={prediction.id} style={styles.predictionCard}>
        <View style={styles.cardHeader}>
          <View style={styles.symbolInfo}>
            <Text style={styles.symbol}>{prediction.symbol}</Text>
            <View style={[styles.typeTag, { backgroundColor: predictionService.getPredictionTypeColor(prediction.type) }]}>
              <Text style={styles.typeText}>{predictionService.getPredictionTypeText(prediction.type)}</Text>
            </View>
          </View>
          <View style={styles.confidenceContainer}>
            <Text style={styles.confidenceLabel}>신뢰도</Text>
            <Text style={[styles.confidence, { color: getConfidenceColor(prediction.confidence) }]}>
              {predictionService.formatConfidence(prediction.confidence)}
            </Text>
          </View>
        </View>

        <View style={styles.priceSection}>
          <View style={styles.priceRow}>
            <Text style={styles.priceLabel}>현재가</Text>
            <Text style={styles.currentPrice}>
              ₩{prediction.currentPrice.toLocaleString()}
            </Text>
          </View>
          <View style={styles.priceRow}>
            <Text style={styles.priceLabel}>예상가</Text>
            <Text style={[styles.predictedPrice, { color: isPositive ? '#4CAF50' : '#F44336' }]}>
              ₩{prediction.predictedPrice.toLocaleString()}
            </Text>
          </View>
          <View style={styles.changeContainer}>
            <Ionicons
              name={isPositive ? 'trending-up' : 'trending-down'}
              size={16}
              color={isPositive ? '#4CAF50' : '#F44336'}
            />
            <Text style={[styles.changePercent, { color: isPositive ? '#4CAF50' : '#F44336' }]}>
              {isPositive ? '+' : ''}{changePercent.toFixed(2)}%
            </Text>
          </View>
        </View>

        <View style={styles.detailsSection}>
          <Text style={styles.reasoning}>{prediction.reasoning}</Text>

          <View style={styles.metaInfo}>
            <View style={styles.metaItem}>
              <Ionicons name="time-outline" size={14} color="#666" />
              <Text style={styles.metaText}>{prediction.timeframe}</Text>
            </View>
            <View style={styles.metaItem}>
              <Ionicons name="calendar-outline" size={14} color="#666" />
              <Text style={styles.metaText}>{daysLeft}일 남음</Text>
            </View>
            <View style={styles.metaItem}>
              <Ionicons name="pulse-outline" size={14} color="#666" />
              <Text style={styles.metaText}>{prediction.status}</Text>
            </View>
          </View>
        </View>

        {prediction.factors && (
          <View style={styles.factorsSection}>
            <Text style={styles.factorsTitle}>주요 요인</Text>
            <View style={styles.factorsList}>
              {prediction.factors.technical?.map((factor: string, index: number) => (
                <View key={`tech-${index}`} style={[styles.factorTag, { backgroundColor: '#E3F2FD' }]}>
                  <Text style={[styles.factorText, { color: '#1976D2' }]}>{factor}</Text>
                </View>
              ))}
              {prediction.factors.fundamental?.map((factor: string, index: number) => (
                <View key={`fund-${index}`} style={[styles.factorTag, { backgroundColor: '#E8F5E8' }]}>
                  <Text style={[styles.factorText, { color: '#388E3C' }]}>{factor}</Text>
                </View>
              ))}
            </View>
          </View>
        )}
      </View>
    );
  };

  if (loading && predictions.length === 0) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#007AFF" />
        <Text style={styles.loadingText}>예측 정보를 불러오는 중...</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>AI 투자 예측</Text>
        <TouchableOpacity onPress={initDemoData} style={styles.demoButton}>
          <Ionicons name="flask-outline" size={20} color="#007AFF" />
          <Text style={styles.demoButtonText}>데모</Text>
        </TouchableOpacity>
      </View>

      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        style={styles.typeFilter}
        contentContainerStyle={styles.typeFilterContent}
      >
        {predictionTypes.map((type) => (
          <TouchableOpacity
            key={type.key}
            style={[
              styles.typeButton,
              selectedType === type.key && styles.typeButtonActive
            ]}
            onPress={() => setSelectedType(type.key)}
          >
            <Text style={[
              styles.typeButtonText,
              selectedType === type.key && styles.typeButtonTextActive
            ]}>
              {type.label}
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
        {predictions.length === 0 ? (
          <View style={styles.emptyContainer}>
            <Ionicons name="analytics-outline" size={64} color="#ccc" />
            <Text style={styles.emptyTitle}>예측 정보가 없습니다</Text>
            <Text style={styles.emptySubtitle}>데모 버튼을 눌러 예측 데이터를 생성해보세요</Text>
          </View>
        ) : (
          predictions.map(renderPredictionCard)
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
  title: {
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
  typeFilter: {
    backgroundColor: '#fff',
    paddingVertical: 10,
  },
  typeFilterContent: {
    paddingHorizontal: 20,
  },
  typeButton: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: '#f8f9fa',
    marginRight: 10,
  },
  typeButtonActive: {
    backgroundColor: '#007AFF',
  },
  typeButtonText: {
    fontSize: 14,
    color: '#666',
    fontWeight: '500',
  },
  typeButtonTextActive: {
    color: '#fff',
    fontWeight: '600',
  },
  content: {
    flex: 1,
    padding: 20,
  },
  predictionCard: {
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
  symbolInfo: {
    flex: 1,
  },
  symbol: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 4,
  },
  typeTag: {
    alignSelf: 'flex-start',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 8,
  },
  typeText: {
    fontSize: 12,
    color: '#fff',
    fontWeight: '600',
  },
  confidenceContainer: {
    alignItems: 'flex-end',
  },
  confidenceLabel: {
    fontSize: 12,
    color: '#666',
    marginBottom: 2,
  },
  confidence: {
    fontSize: 16,
    fontWeight: 'bold',
  },
  priceSection: {
    marginBottom: 12,
  },
  priceRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 6,
  },
  priceLabel: {
    fontSize: 14,
    color: '#666',
  },
  currentPrice: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
  },
  predictedPrice: {
    fontSize: 16,
    fontWeight: 'bold',
  },
  changeContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'flex-end',
    marginTop: 4,
  },
  changePercent: {
    fontSize: 14,
    fontWeight: '600',
    marginLeft: 4,
  },
  detailsSection: {
    marginBottom: 12,
  },
  reasoning: {
    fontSize: 14,
    color: '#333',
    lineHeight: 20,
    marginBottom: 8,
  },
  metaInfo: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
  },
  metaItem: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  metaText: {
    fontSize: 12,
    color: '#666',
    marginLeft: 4,
  },
  factorsSection: {
    marginTop: 8,
  },
  factorsTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
    marginBottom: 8,
  },
  factorsList: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
  },
  factorTag: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 12,
  },
  factorText: {
    fontSize: 12,
    fontWeight: '500',
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

export default PredictionScreen;