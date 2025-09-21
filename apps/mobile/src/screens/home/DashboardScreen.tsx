import React, { useEffect, useState } from 'react';
import {
  StyleSheet,
  Text,
  View,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
  SafeAreaView,
} from 'react-native';

import apiClient from '../../services/apiClient';

export default function DashboardScreen() {
  const [refreshing, setRefreshing] = useState(false);
  const [earnings, setEarnings] = useState({
    today: 0,
    week: 0,
    month: 850000,
  });
  const [missions, setMissions] = useState([
    { id: '1', title: '프로필 완성하기', completed: true },
    { id: '2', title: '첫 작업 지원하기', completed: true },
    { id: '3', title: '리뷰 작성하기', completed: false },
    { id: '4', title: '친구 초대하기', completed: false },
    { id: '5', title: '스킬 인증받기', completed: false },
  ]);

  const onRefresh = async () => {
    setRefreshing(true);
    try {
      await apiClient.healthCheck();
    } catch (error) {
      console.error('Refresh error:', error);
    }
    setRefreshing(false);
  };

  const completedMissions = missions.filter((m) => m.completed).length;

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
      >
        <View style={styles.header}>
          <Text style={styles.greeting}>좋은 아침이에요!</Text>
          <Text style={styles.userName}>김지현님</Text>
        </View>

        <View style={styles.earningsCard}>
          <Text style={styles.earningsLabel}>이번 달 수익</Text>
          <Text style={styles.earningsAmount}>
            ₩{earnings.month.toLocaleString()}
          </Text>
          <View style={styles.earningsRow}>
            <View style={styles.earningItem}>
              <Text style={styles.earningItemLabel}>오늘</Text>
              <Text style={styles.earningItemValue}>
                ₩{earnings.today.toLocaleString()}
              </Text>
            </View>
            <View style={styles.earningItem}>
              <Text style={styles.earningItemLabel}>이번 주</Text>
              <Text style={styles.earningItemValue}>
                ₩{earnings.week.toLocaleString()}
              </Text>
            </View>
          </View>
        </View>

        <View style={styles.missionsCard}>
          <View style={styles.missionHeader}>
            <Text style={styles.sectionTitle}>
              오늘의 미션 ({completedMissions}/{missions.length})
            </Text>
            <Text style={styles.missionReward}>🎁 +500 포인트</Text>
          </View>
          <View style={styles.missionList}>
            {missions.slice(0, 3).map((mission) => (
              <View key={mission.id} style={styles.missionItem}>
                <Text
                  style={[
                    styles.missionCheck,
                    mission.completed && styles.missionCompleted,
                  ]}
                >
                  {mission.completed ? '✅' : '⬜'}
                </Text>
                <Text
                  style={[
                    styles.missionText,
                    mission.completed && styles.missionTextCompleted,
                  ]}
                >
                  {mission.title}
                </Text>
              </View>
            ))}
          </View>
        </View>

        <View style={styles.quickActions}>
          <Text style={styles.sectionTitle}>빠른 시작</Text>
          <View style={styles.actionGrid}>
            <TouchableOpacity style={styles.actionButton}>
              <Text style={styles.actionIcon}>📝</Text>
              <Text style={styles.actionText}>번역</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.actionButton}>
              <Text style={styles.actionIcon}>🎨</Text>
              <Text style={styles.actionText}>디자인</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.actionButton}>
              <Text style={styles.actionIcon}>📚</Text>
              <Text style={styles.actionText}>강의</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.actionButton}>
              <Text style={styles.actionIcon}>💻</Text>
              <Text style={styles.actionText}>개발</Text>
            </TouchableOpacity>
          </View>
        </View>

        <View style={styles.recommendedTasks}>
          <Text style={styles.sectionTitle}>추천 작업</Text>
          {[1, 2].map((i) => (
            <TouchableOpacity key={i} style={styles.taskCard}>
              <View style={styles.taskHeader}>
                <Text style={styles.taskCategory}>디자인</Text>
                <Text style={styles.taskBudget}>₩50,000</Text>
              </View>
              <Text style={styles.taskTitle}>
                로고 디자인이 필요합니다
              </Text>
              <Text style={styles.taskDescription}>
                스타트업 로고 제작, 미니멀한 스타일 선호
              </Text>
              <View style={styles.taskFooter}>
                <Text style={styles.taskTime}>2시간 전</Text>
                <Text style={styles.taskApplicants}>지원자 5명</Text>
              </View>
            </TouchableOpacity>
          ))}
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
  scrollContent: {
    paddingBottom: 20,
  },
  header: {
    padding: 20,
    backgroundColor: '#fff',
  },
  greeting: {
    fontSize: 16,
    color: '#666',
  },
  userName: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#333',
    marginTop: 5,
  },
  earningsCard: {
    backgroundColor: '#007AFF',
    margin: 20,
    padding: 20,
    borderRadius: 16,
  },
  earningsLabel: {
    color: '#fff',
    opacity: 0.8,
    fontSize: 14,
  },
  earningsAmount: {
    color: '#fff',
    fontSize: 32,
    fontWeight: 'bold',
    marginVertical: 10,
  },
  earningsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 10,
  },
  earningItem: {
    flex: 1,
  },
  earningItemLabel: {
    color: '#fff',
    opacity: 0.7,
    fontSize: 12,
  },
  earningItemValue: {
    color: '#fff',
    fontSize: 18,
    fontWeight: '600',
    marginTop: 4,
  },
  missionsCard: {
    backgroundColor: '#fff',
    marginHorizontal: 20,
    marginBottom: 20,
    padding: 20,
    borderRadius: 12,
  },
  missionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 15,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
  },
  missionReward: {
    fontSize: 14,
    color: '#007AFF',
  },
  missionList: {},
  missionItem: {
    flexDirection: 'row',
    alignItems: 'center',
    marginVertical: 8,
  },
  missionCheck: {
    fontSize: 20,
    marginRight: 10,
  },
  missionCompleted: {
    opacity: 0.6,
  },
  missionText: {
    fontSize: 16,
    color: '#333',
  },
  missionTextCompleted: {
    textDecorationLine: 'line-through',
    opacity: 0.6,
  },
  quickActions: {
    paddingHorizontal: 20,
    marginBottom: 20,
  },
  actionGrid: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 15,
  },
  actionButton: {
    backgroundColor: '#fff',
    flex: 1,
    aspectRatio: 1,
    marginHorizontal: 5,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  actionIcon: {
    fontSize: 30,
    marginBottom: 5,
  },
  actionText: {
    fontSize: 12,
    color: '#666',
  },
  recommendedTasks: {
    paddingHorizontal: 20,
  },
  taskCard: {
    backgroundColor: '#fff',
    padding: 16,
    borderRadius: 12,
    marginTop: 15,
  },
  taskHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 10,
  },
  taskCategory: {
    backgroundColor: '#f0f0f0',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 6,
    fontSize: 12,
    color: '#666',
  },
  taskBudget: {
    fontSize: 16,
    fontWeight: '600',
    color: '#007AFF',
  },
  taskTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginBottom: 5,
  },
  taskDescription: {
    fontSize: 14,
    color: '#666',
    marginBottom: 10,
  },
  taskFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  taskTime: {
    fontSize: 12,
    color: '#999',
  },
  taskApplicants: {
    fontSize: 12,
    color: '#999',
  },
});