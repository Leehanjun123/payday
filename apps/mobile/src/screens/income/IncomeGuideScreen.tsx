import React, { useState } from 'react';
import {
  StyleSheet,
  Text,
  View,
  ScrollView,
  TouchableOpacity,
  FlatList,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';

// 실제 검증된 수익 데이터
const incomeCategories = {
  // 💻 디지털 크리에이티브 (월 50-200만원)
  digital_creative: {
    name: '디지털 크리에이티브',
    icon: '💻',
    averageIncome: '50-200만원',
    description: '온라인 콘텐츠 제작으로 수익 창출',
    items: [
      {
        id: 'blog_adsense',
        name: '블로그 & 애드센스',
        description: '블로그 운영 + 구글 애드센스 광고 수익',
        avgIncome: '30-300만원',
        difficulty: '중급',
        timeToProfit: '2-6개월',
        verified: '실제 후기 다수',
        tips: '특정 키워드 타겟팅, 꾸준한 포스팅'
      },
      {
        id: 'youtube_shorts',
        name: '유튜브 쇼츠',
        description: '짧은 영상 제작으로 조회수 기반 수익',
        avgIncome: '20-150만원',
        difficulty: '초급',
        timeToProfit: '1-3개월',
        verified: '2023년부터 폭발적 성장',
        tips: '트렌드 키워드 활용, 일관된 업로드'
      },
      {
        id: 'design_templates',
        name: '디자인 템플릿 판매',
        description: '미리캔버스에서 디자인 자산 판매',
        avgIncome: '30-200만원',
        difficulty: '중급',
        timeToProfit: '1-4개월',
        verified: '월 200만원 달성 사례 다수',
        tips: '1000개 이상 등록, 트렌드 연구'
      }
    ]
  },

  // 🛍️ 온라인 커머스 (월 100-500만원)
  online_commerce: {
    name: '온라인 커머스',
    icon: '🛍️',
    averageIncome: '100-500만원',
    description: '온라인 상품 판매로 안정적 수익',
    items: [
      {
        id: 'coupang_seller',
        name: '쿠팡 온라인 셀러',
        description: '쿠팡 파트너스 + 직접 판매',
        avgIncome: '100-300만원',
        difficulty: '중급',
        timeToProfit: '1-2개월',
        verified: '원가 1000원도 수익 가능',
        tips: '트렌드 상품 발굴, CS 관리'
      },
      {
        id: 'smart_store',
        name: '스마트스토어 운영',
        description: '네이버 스마트스토어 상품 판매',
        avgIncome: '50-200만원',
        difficulty: '중급',
        timeToProfit: '2-4개월',
        verified: '네이버 공식 지원',
        tips: '상품 차별화, 광고 운영'
      }
    ]
  },

  // 🚚 플랫폼 서비스 (월 80-200만원)
  platform_services: {
    name: '플랫폼 서비스',
    icon: '🚚',
    averageIncome: '80-200만원',
    description: '즉시 시작 가능한 서비스업',
    items: [
      {
        id: 'delivery_driver',
        name: '배달 라이더',
        description: '배민커넥트, 쿠팡이츠 배달 대행',
        avgIncome: '80-180만원',
        difficulty: '초급',
        timeToProfit: '즉시',
        verified: '1건당 3,000-4,000원',
        tips: '피크타임 집중, 효율적인 동선'
      },
      {
        id: 'designated_driver',
        name: '대리운전',
        description: '카카오T 대리, 앱 기반 대리운전',
        avgIncome: '평균 161만원',
        difficulty: '중급',
        timeToProfit: '즉시',
        verified: '노동조합 공식 통계',
        tips: '야간/주말 집중, 안전 운전'
      }
    ]
  },

  // 🎨 프리랜서 서비스 (월 50-300만원)
  freelance_services: {
    name: '프리랜서 서비스',
    icon: '🎨',
    averageIncome: '50-300만원',
    description: '전문 기술로 고수익 창출',
    items: [
      {
        id: 'design_freelance',
        name: '디자인 프리랜서',
        description: '로고, 브랜딩, 웹디자인 등',
        avgIncome: '80-300만원',
        difficulty: '고급',
        timeToProfit: '1-2개월',
        verified: '크몽 상위 판매자 수익',
        tips: '포트폴리오 구축, 차별화'
      },
      {
        id: 'development',
        name: '개발 프리랜서',
        description: '웹개발, 앱개발, 자동화 툴',
        avgIncome: '100-500만원',
        difficulty: '고급',
        timeToProfit: '1-3개월',
        verified: '프리랜서 플랫폼 평균',
        tips: '기술 스택 전문화, 품질'
      }
    ]
  },

  // 💰 투자 & 금융 (월 20-무제한)
  investment_finance: {
    name: '투자 & 금융',
    icon: '💰',
    averageIncome: '변동적',
    description: '자본을 활용한 투자 수익',
    items: [
      {
        id: 'real_estate_auction',
        name: '부동산 소액 경매',
        description: '500만-5,000만원 소액 경매 투자',
        avgIncome: '변동적',
        difficulty: '고급',
        timeToProfit: '3-12개월',
        verified: '2030세대 급증',
        tips: '권리분석 철저히, 시세 조사'
      },
      {
        id: 'reselling_business',
        name: '리셀링 사업',
        description: '한정판, 희귀템 거래',
        avgIncome: '50-300만원',
        difficulty: '중급',
        timeToProfit: '즉시-3개월',
        verified: '크림, 솔드아웃 거래량 증가',
        tips: '트렌드 파악, 진품 확인'
      }
    ]
  }
};

const difficultyColors = {
  '초급': '#4CAF50',
  '중급': '#FF9800',
  '고급': '#F44336'
};

export default function IncomeGuideScreen({ navigation }: any) {
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null);
  const [filterType, setFilterType] = useState('all');

  const categories = Object.entries(incomeCategories);

  const handleItemPress = (item: any) => {
    Alert.alert(
      item.name,
      `월 평균 수익: ${item.avgIncome}\n난이도: ${item.difficulty}\n수익 시점: ${item.timeToProfit}\n\n${item.verified}\n\n팁: ${item.tips}`,
      [
        { text: '취소', style: 'cancel' },
        { text: '관련 작업 찾기', onPress: () => navigation.navigate('TaskList') }
      ]
    );
  };

  const renderCategoryCard = ({ item }: { item: [string, any] }) => {
    const [key, category] = item;
    const isSelected = selectedCategory === key;

    return (
      <TouchableOpacity
        style={[styles.categoryCard, isSelected && styles.selectedCard]}
        onPress={() => setSelectedCategory(isSelected ? null : key)}
      >
        <View style={styles.categoryHeader}>
          <Text style={styles.categoryIcon}>{category.icon}</Text>
          <View style={styles.categoryInfo}>
            <Text style={styles.categoryName}>{category.name}</Text>
            <Text style={styles.categoryIncome}>월 {category.averageIncome}</Text>
          </View>
          <Ionicons
            name={isSelected ? "chevron-up" : "chevron-down"}
            size={24}
            color="#666"
          />
        </View>

        <Text style={styles.categoryDescription}>{category.description}</Text>

        {isSelected && (
          <View style={styles.itemsList}>
            {category.items.map((item: any, index: number) => (
              <TouchableOpacity
                key={index}
                style={styles.incomeItem}
                onPress={() => handleItemPress(item)}
              >
                <View style={styles.itemHeader}>
                  <Text style={styles.itemName}>{item.name}</Text>
                  <View style={[
                    styles.difficultyBadge,
                    { backgroundColor: difficultyColors[item.difficulty as keyof typeof difficultyColors] }
                  ]}>
                    <Text style={styles.difficultyText}>{item.difficulty}</Text>
                  </View>
                </View>

                <Text style={styles.itemDescription}>{item.description}</Text>

                <View style={styles.itemStats}>
                  <View style={styles.statItem}>
                    <Text style={styles.statLabel}>월 수익</Text>
                    <Text style={styles.statValue}>{item.avgIncome}</Text>
                  </View>
                  <View style={styles.statItem}>
                    <Text style={styles.statLabel}>수익 시점</Text>
                    <Text style={styles.statValue}>{item.timeToProfit}</Text>
                  </View>
                </View>

                <View style={styles.verifiedBadge}>
                  <Ionicons name="checkmark-circle" size={16} color="#4CAF50" />
                  <Text style={styles.verifiedText}>{item.verified}</Text>
                </View>
              </TouchableOpacity>
            ))}
          </View>
        )}
      </TouchableOpacity>
    );
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity
          style={styles.backButton}
          onPress={() => navigation.goBack()}
        >
          <Ionicons name="arrow-back" size={24} color="#333" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>💰 수익 가이드</Text>
        <View style={styles.placeholder} />
      </View>

      <View style={styles.summaryCard}>
        <Text style={styles.summaryTitle}>실제 검증된 부업 정보</Text>
        <Text style={styles.summaryText}>
          2024년 실제 수익 사례가 검증된 부업들을 정리했습니다.
          각 분야별 평균 수익, 난이도, 시작 방법을 확인하세요.
        </Text>
        <View style={styles.statsRow}>
          <View style={styles.statBox}>
            <Text style={styles.statNumber}>15+</Text>
            <Text style={styles.statLabel}>검증된 부업</Text>
          </View>
          <View style={styles.statBox}>
            <Text style={styles.statNumber}>월 50만원+</Text>
            <Text style={styles.statLabel}>평균 수익</Text>
          </View>
          <View style={styles.statBox}>
            <Text style={styles.statNumber}>24시간</Text>
            <Text style={styles.statLabel}>빠른 시작</Text>
          </View>
        </View>
      </View>

      <FlatList
        data={categories}
        renderItem={renderCategoryCard}
        keyExtractor={([key]) => key}
        contentContainerStyle={styles.listContent}
        showsVerticalScrollIndicator={false}
      />

      <View style={styles.bottomTip}>
        <Ionicons name="bulb-outline" size={20} color="#FF9800" />
        <Text style={styles.tipText}>
          💡 여러 부업을 조합하면 월 200만원 이상도 가능합니다!
        </Text>
      </View>
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
  backButton: {
    padding: 4,
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#333',
  },
  placeholder: {
    width: 32,
  },
  summaryCard: {
    backgroundColor: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
    backgroundColor: '#007AFF',
    margin: 20,
    padding: 20,
    borderRadius: 16,
  },
  summaryTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#fff',
    marginBottom: 8,
  },
  summaryText: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.9)',
    lineHeight: 20,
    marginBottom: 16,
  },
  statsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  statBox: {
    alignItems: 'center',
  },
  statNumber: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#fff',
  },
  statLabel: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.8)',
    marginTop: 2,
  },
  listContent: {
    paddingHorizontal: 20,
    paddingBottom: 100,
  },
  categoryCard: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.1,
    shadowRadius: 3.84,
    elevation: 5,
  },
  selectedCard: {
    borderColor: '#007AFF',
    borderWidth: 2,
  },
  categoryHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  categoryIcon: {
    fontSize: 24,
    marginRight: 12,
  },
  categoryInfo: {
    flex: 1,
  },
  categoryName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
  },
  categoryIncome: {
    fontSize: 14,
    color: '#007AFF',
    fontWeight: '500',
  },
  categoryDescription: {
    fontSize: 13,
    color: '#666',
    lineHeight: 18,
  },
  itemsList: {
    marginTop: 16,
    paddingTop: 16,
    borderTopWidth: 1,
    borderTopColor: '#f0f0f0',
  },
  incomeItem: {
    backgroundColor: '#f8f9fa',
    padding: 12,
    borderRadius: 8,
    marginBottom: 12,
  },
  itemHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 6,
  },
  itemName: {
    fontSize: 15,
    fontWeight: '600',
    color: '#333',
    flex: 1,
  },
  difficultyBadge: {
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 4,
  },
  difficultyText: {
    fontSize: 11,
    color: '#fff',
    fontWeight: '500',
  },
  itemDescription: {
    fontSize: 13,
    color: '#666',
    marginBottom: 8,
    lineHeight: 18,
  },
  itemStats: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  statItem: {
    flex: 1,
  },
  statLabel: {
    fontSize: 11,
    color: '#999',
  },
  statValue: {
    fontSize: 13,
    fontWeight: '500',
    color: '#333',
  },
  verifiedBadge: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  verifiedText: {
    fontSize: 12,
    color: '#4CAF50',
    marginLeft: 4,
    fontWeight: '500',
  },
  bottomTip: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFF8E1',
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderTopWidth: 1,
    borderTopColor: '#e0e0e0',
  },
  tipText: {
    fontSize: 13,
    color: '#F57C00',
    marginLeft: 8,
    fontWeight: '500',
    flex: 1,
  },
});