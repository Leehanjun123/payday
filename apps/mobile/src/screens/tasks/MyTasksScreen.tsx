import React, { useState, useEffect } from 'react';
import {
  StyleSheet,
  Text,
  View,
  FlatList,
  TouchableOpacity,
  RefreshControl,
  ActivityIndicator,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import taskService, { Task } from '../../services/taskService';
import { useAuth } from '../../contexts/AuthContext';

type TabType = 'posted' | 'assigned';

export default function MyTasksScreen({ navigation }: any) {
  const { user } = useAuth();
  const [activeTab, setActiveTab] = useState<TabType>('posted');
  const [postedTasks, setPostedTasks] = useState<Task[]>([]);
  const [assignedTasks, setAssignedTasks] = useState<Task[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    loadTasks();
  }, []);

  const loadTasks = async () => {
    try {
      const [posted, assigned] = await Promise.all([
        taskService.getMyPostedTasks(),
        taskService.getMyAssignedTasks(),
      ]);
      setPostedTasks(posted);
      setAssignedTasks(assigned);
    } catch (error) {
      console.error('Error loading tasks:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleRefresh = async () => {
    setRefreshing(true);
    await loadTasks();
    setRefreshing(false);
  };

  const formatBudget = (budget: number) => {
    if (budget >= 10000) {
      return `${(budget / 10000).toFixed(0)}만원`;
    }
    return `${budget.toLocaleString()}원`;
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'OPEN':
        return '모집 중';
      case 'IN_PROGRESS':
        return '진행 중';
      case 'UNDER_REVIEW':
        return '검토 중';
      case 'COMPLETED':
        return '완료됨';
      case 'CANCELLED':
        return '취소됨';
      default:
        return status;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'OPEN':
        return '#4CAF50';
      case 'IN_PROGRESS':
        return '#FF9800';
      case 'UNDER_REVIEW':
        return '#2196F3';
      case 'COMPLETED':
        return '#9E9E9E';
      case 'CANCELLED':
        return '#F44336';
      default:
        return '#666';
    }
  };

  const renderTaskItem = ({ item }: { item: Task }) => (
    <TouchableOpacity
      style={styles.taskCard}
      onPress={() => {
        // Navigate to task detail or task management based on tab
        if (activeTab === 'posted') {
          // Navigate to task management screen for poster
          navigation.navigate('TaskManagement', { taskId: item.id });
        } else {
          // Navigate to task progress screen for assignee
          navigation.navigate('TaskProgress', { taskId: item.id });
        }
      }}
    >
      <View style={styles.taskHeader}>
        <View
          style={[
            styles.statusBadge,
            { backgroundColor: getStatusColor(item.status) + '20' },
          ]}
        >
          <View
            style={[
              styles.statusDot,
              { backgroundColor: getStatusColor(item.status) },
            ]}
          />
          <Text style={[styles.statusText, { color: getStatusColor(item.status) }]}>
            {getStatusText(item.status)}
          </Text>
        </View>
        <Text style={styles.taskBudget}>₩{formatBudget(item.budget)}</Text>
      </View>

      <Text style={styles.taskTitle} numberOfLines={2}>
        {item.title}
      </Text>

      <Text style={styles.taskDescription} numberOfLines={2}>
        {item.description}
      </Text>

      <View style={styles.taskFooter}>
        <View style={styles.taskMeta}>
          <Ionicons name="time-outline" size={16} color="#666" />
          <Text style={styles.metaText}>{item.duration}시간</Text>
        </View>

        {activeTab === 'posted' && (
          <View style={styles.taskMeta}>
            <Ionicons name="people-outline" size={16} color="#666" />
            <Text style={styles.metaText}>
              {item._count?.applications || 0}명 지원
            </Text>
          </View>
        )}

        {activeTab === 'assigned' && item.poster && (
          <View style={styles.posterInfo}>
            <Text style={styles.posterText}>의뢰자: {item.poster.name}</Text>
          </View>
        )}

        <View style={styles.taskMeta}>
          <Ionicons name="calendar-outline" size={16} color="#666" />
          <Text style={styles.metaText}>
            {new Date(item.createdAt).toLocaleDateString('ko-KR', {
              month: 'short',
              day: 'numeric',
            })}
          </Text>
        </View>
      </View>
    </TouchableOpacity>
  );

  const currentTasks = activeTab === 'posted' ? postedTasks : assignedTasks;

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>내 작업</Text>
        <TouchableOpacity
          style={styles.addButton}
          onPress={() => navigation.navigate('CreateTask')}
        >
          <Ionicons name="add-circle" size={28} color="#007AFF" />
        </TouchableOpacity>
      </View>

      <View style={styles.tabContainer}>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'posted' && styles.activeTab]}
          onPress={() => setActiveTab('posted')}
        >
          <Text
            style={[styles.tabText, activeTab === 'posted' && styles.activeTabText]}
          >
            의뢰한 작업
          </Text>
          {postedTasks.length > 0 && (
            <View style={styles.tabBadge}>
              <Text style={styles.tabBadgeText}>{postedTasks.length}</Text>
            </View>
          )}
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.tab, activeTab === 'assigned' && styles.activeTab]}
          onPress={() => setActiveTab('assigned')}
        >
          <Text
            style={[styles.tabText, activeTab === 'assigned' && styles.activeTabText]}
          >
            진행중인 작업
          </Text>
          {assignedTasks.length > 0 && (
            <View style={styles.tabBadge}>
              <Text style={styles.tabBadgeText}>{assignedTasks.length}</Text>
            </View>
          )}
        </TouchableOpacity>
      </View>

      {loading ? (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#007AFF" />
        </View>
      ) : (
        <FlatList
          data={currentTasks}
          renderItem={renderTaskItem}
          keyExtractor={(item) => item.id}
          refreshControl={
            <RefreshControl refreshing={refreshing} onRefresh={handleRefresh} />
          }
          ListEmptyComponent={
            <View style={styles.emptyContainer}>
              <Ionicons
                name={activeTab === 'posted' ? 'document-outline' : 'briefcase-outline'}
                size={64}
                color="#ccc"
              />
              <Text style={styles.emptyText}>
                {activeTab === 'posted'
                  ? '의뢰한 작업이 없습니다'
                  : '진행중인 작업이 없습니다'}
              </Text>
              <Text style={styles.emptySubtext}>
                {activeTab === 'posted'
                  ? '새로운 작업을 등록해보세요'
                  : '작업을 찾아 지원해보세요'}
              </Text>
              {activeTab === 'posted' && (
                <TouchableOpacity
                  style={styles.createButton}
                  onPress={() => navigation.navigate('CreateTask')}
                >
                  <Text style={styles.createButtonText}>작업 등록하기</Text>
                </TouchableOpacity>
              )}
            </View>
          }
          contentContainerStyle={styles.listContent}
        />
      )}
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
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 16,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  headerTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#333',
  },
  addButton: {
    padding: 4,
  },
  tabContainer: {
    flexDirection: 'row',
    backgroundColor: '#fff',
    paddingHorizontal: 20,
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  tab: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 14,
    borderBottomWidth: 2,
    borderBottomColor: 'transparent',
  },
  activeTab: {
    borderBottomColor: '#007AFF',
  },
  tabText: {
    fontSize: 16,
    color: '#666',
  },
  activeTabText: {
    color: '#007AFF',
    fontWeight: '600',
  },
  tabBadge: {
    backgroundColor: '#007AFF',
    borderRadius: 10,
    paddingHorizontal: 6,
    paddingVertical: 2,
    marginLeft: 6,
  },
  tabBadgeText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: 'bold',
  },
  listContent: {
    flexGrow: 1,
    paddingHorizontal: 20,
    paddingBottom: 20,
  },
  taskCard: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginTop: 16,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.1,
    shadowRadius: 3.84,
    elevation: 5,
  },
  taskHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  statusBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 12,
  },
  statusDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    marginRight: 6,
  },
  statusText: {
    fontSize: 12,
    fontWeight: '600',
  },
  taskBudget: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#007AFF',
  },
  taskTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
    marginBottom: 8,
  },
  taskDescription: {
    fontSize: 14,
    color: '#666',
    marginBottom: 12,
    lineHeight: 20,
  },
  taskFooter: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  taskMeta: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  metaText: {
    fontSize: 12,
    color: '#666',
    marginLeft: 4,
  },
  posterInfo: {
    flex: 1,
    marginLeft: 12,
  },
  posterText: {
    fontSize: 12,
    color: '#666',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingTop: 100,
  },
  emptyText: {
    fontSize: 18,
    color: '#333',
    marginTop: 16,
    marginBottom: 8,
  },
  emptySubtext: {
    fontSize: 14,
    color: '#666',
    marginBottom: 24,
  },
  createButton: {
    backgroundColor: '#007AFF',
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 8,
  },
  createButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
});