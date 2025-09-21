import React, { useState, useEffect, useCallback } from 'react';
import {
  StyleSheet,
  Text,
  View,
  FlatList,
  TouchableOpacity,
  RefreshControl,
  ActivityIndicator,
  TextInput,
  ScrollView,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { ExploreStackScreenProps } from '../../navigation/types';
import taskService, { Task, TaskFilters } from '../../services/taskService';

const categories = [
  { id: 'all', name: '전체', icon: '🌐' },
  { id: '디자인', name: '디자인', icon: '🎨' },
  { id: '개발', name: '개발', icon: '💻' },
  { id: '번역', name: '번역', icon: '🌏' },
  { id: '마케팅', name: '마케팅', icon: '📢' },
  { id: '교육', name: '교육', icon: '📚' },
  { id: '영상', name: '영상', icon: '🎬' },
  { id: '글쓰기', name: '글쓰기', icon: '✍️' },
];

export default function TaskListScreen({ navigation }: ExploreStackScreenProps<'TaskList'>) {
  const [tasks, setTasks] = useState<Task[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [loadingMore, setLoadingMore] = useState(false);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [searchText, setSearchText] = useState('');
  const [filters, setFilters] = useState<TaskFilters>({});

  const loadTasks = useCallback(
    async (pageNum = 1, append = false) => {
      if (pageNum > totalPages && totalPages > 0) return;

      try {
        const response = await taskService.getTasks({
          ...filters,
          category: selectedCategory === 'all' ? undefined : selectedCategory,
          search: searchText || undefined,
          page: pageNum,
          limit: 20,
        });

        if (append) {
          setTasks((prev) => [...prev, ...response.tasks]);
        } else {
          setTasks(response.tasks);
        }

        setPage(pageNum);
        setTotalPages(response.pagination.pages);
      } catch (error) {
        console.error('Error loading tasks:', error);
      }
    },
    [filters, selectedCategory, searchText, totalPages]
  );

  useEffect(() => {
    const init = async () => {
      setLoading(true);
      await loadTasks(1);
      setLoading(false);
    };
    init();
  }, [selectedCategory, filters]);

  const handleRefresh = async () => {
    setRefreshing(true);
    await loadTasks(1);
    setRefreshing(false);
  };

  const handleLoadMore = async () => {
    if (loadingMore || page >= totalPages) return;

    setLoadingMore(true);
    await loadTasks(page + 1, true);
    setLoadingMore(false);
  };

  const handleSearch = () => {
    setPage(1);
    loadTasks(1);
  };

  const formatBudget = (budget: number) => {
    if (budget >= 10000) {
      return `${(budget / 10000).toFixed(0)}만원`;
    }
    return `${budget.toLocaleString()}원`;
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'OPEN':
        return '#4CAF50';
      case 'IN_PROGRESS':
        return '#FF9800';
      case 'COMPLETED':
        return '#9E9E9E';
      default:
        return '#666';
    }
  };

  const getPriorityIcon = (priority: string) => {
    switch (priority) {
      case 'URGENT':
        return '🔥';
      case 'HIGH':
        return '⚡';
      case 'NORMAL':
        return '📋';
      default:
        return '';
    }
  };

  const renderTaskItem = ({ item }: { item: Task }) => (
    <TouchableOpacity
      style={styles.taskCard}
      onPress={() => navigation.navigate('TaskDetail', { taskId: item.id })}
    >
      <View style={styles.taskHeader}>
        <View style={styles.taskMeta}>
          <Text style={styles.taskCategory}>{item.category}</Text>
          {item.priority !== 'NORMAL' && (
            <Text style={styles.priorityIcon}>{getPriorityIcon(item.priority)}</Text>
          )}
        </View>
        <Text style={styles.taskBudget}>₩{formatBudget(item.budget)}</Text>
      </View>

      <Text style={styles.taskTitle} numberOfLines={2}>
        {item.title}
      </Text>

      <Text style={styles.taskDescription} numberOfLines={2}>
        {item.description}
      </Text>

      {item.skills && item.skills.length > 0 && (
        <View style={styles.skillsContainer}>
          {item.skills.slice(0, 3).map((skillItem, index) => (
            <View key={index} style={styles.skillTag}>
              <Text style={styles.skillText}>
                {skillItem.skill.icon} {skillItem.skill.name}
              </Text>
            </View>
          ))}
          {item.skills.length > 3 && (
            <Text style={styles.moreSkills}>+{item.skills.length - 3}</Text>
          )}
        </View>
      )}

      <View style={styles.taskFooter}>
        <View style={styles.posterInfo}>
          <View style={styles.posterAvatar}>
            <Text style={styles.posterInitial}>
              {item.poster.name.charAt(0)}
            </Text>
          </View>
          <Text style={styles.posterName}>{item.poster.name}</Text>
          <Text style={styles.posterLevel}>Lv.{item.poster.level}</Text>
        </View>

        <View style={styles.taskStats}>
          <View style={styles.statItem}>
            <Ionicons name="people-outline" size={16} color="#666" />
            <Text style={styles.statText}>
              {item._count?.applications || 0}명 지원
            </Text>
          </View>
          <View style={styles.statItem}>
            <Ionicons name="time-outline" size={16} color="#666" />
            <Text style={styles.statText}>{item.duration}시간</Text>
          </View>
        </View>
      </View>

      <View
        style={[
          styles.statusIndicator,
          { backgroundColor: getStatusColor(item.status) },
        ]}
      />
    </TouchableOpacity>
  );

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>작업 찾기</Text>
        <TouchableOpacity
          style={styles.filterButton}
          onPress={() => {
            // TODO: Implement filter modal
          }}
        >
          <Ionicons name="filter" size={24} color="#007AFF" />
        </TouchableOpacity>
      </View>

      <View style={styles.searchContainer}>
        <Ionicons name="search" size={20} color="#999" style={styles.searchIcon} />
        <TextInput
          style={styles.searchInput}
          placeholder="작업 검색..."
          value={searchText}
          onChangeText={setSearchText}
          onSubmitEditing={handleSearch}
          returnKeyType="search"
        />
      </View>

      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        style={styles.categoryScroll}
      >
        {categories.map((category) => (
          <TouchableOpacity
            key={category.id}
            style={[
              styles.categoryButton,
              selectedCategory === category.id && styles.categoryButtonActive,
            ]}
            onPress={() => setSelectedCategory(category.id)}
          >
            <Text style={styles.categoryIcon}>{category.icon}</Text>
            <Text
              style={[
                styles.categoryText,
                selectedCategory === category.id && styles.categoryTextActive,
              ]}
            >
              {category.name}
            </Text>
          </TouchableOpacity>
        ))}
      </ScrollView>

      {loading ? (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#007AFF" />
        </View>
      ) : (
        <FlatList
          data={tasks}
          renderItem={renderTaskItem}
          keyExtractor={(item) => item.id}
          refreshControl={
            <RefreshControl refreshing={refreshing} onRefresh={handleRefresh} />
          }
          onEndReached={handleLoadMore}
          onEndReachedThreshold={0.5}
          ListEmptyComponent={
            <View style={styles.emptyContainer}>
              <Text style={styles.emptyText}>작업이 없습니다</Text>
              <Text style={styles.emptySubtext}>
                다른 카테고리를 선택해보세요
              </Text>
            </View>
          }
          ListFooterComponent={
            loadingMore ? (
              <View style={styles.loadingMoreContainer}>
                <ActivityIndicator size="small" color="#007AFF" />
              </View>
            ) : null
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
  filterButton: {
    padding: 8,
  },
  searchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#fff',
    marginHorizontal: 20,
    marginVertical: 12,
    paddingHorizontal: 12,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#e0e0e0',
  },
  searchIcon: {
    marginRight: 8,
  },
  searchInput: {
    flex: 1,
    height: 40,
    fontSize: 16,
    color: '#333',
  },
  categoryScroll: {
    backgroundColor: '#fff',
    paddingVertical: 12,
    paddingHorizontal: 16,
    maxHeight: 60,
  },
  categoryButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 8,
    marginHorizontal: 4,
    borderRadius: 20,
    backgroundColor: '#f5f5f5',
  },
  categoryButtonActive: {
    backgroundColor: '#007AFF',
  },
  categoryIcon: {
    fontSize: 16,
    marginRight: 6,
  },
  categoryText: {
    fontSize: 14,
    color: '#666',
  },
  categoryTextActive: {
    color: '#fff',
    fontWeight: '600',
  },
  listContent: {
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
  taskMeta: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  taskCategory: {
    fontSize: 12,
    color: '#666',
    backgroundColor: '#f0f0f0',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 6,
  },
  priorityIcon: {
    fontSize: 16,
    marginLeft: 8,
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
  skillsContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginBottom: 12,
  },
  skillTag: {
    backgroundColor: '#e3f2fd',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 12,
    marginRight: 8,
    marginBottom: 8,
  },
  skillText: {
    fontSize: 12,
    color: '#1976d2',
  },
  moreSkills: {
    fontSize: 12,
    color: '#666',
    paddingHorizontal: 8,
    paddingVertical: 4,
  },
  taskFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  posterInfo: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  posterAvatar: {
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: '#007AFF',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 8,
  },
  posterInitial: {
    color: '#fff',
    fontSize: 12,
    fontWeight: 'bold',
  },
  posterName: {
    fontSize: 14,
    color: '#333',
    marginRight: 8,
  },
  posterLevel: {
    fontSize: 12,
    color: '#666',
    backgroundColor: '#f0f0f0',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  taskStats: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  statItem: {
    flexDirection: 'row',
    alignItems: 'center',
    marginLeft: 12,
  },
  statText: {
    fontSize: 12,
    color: '#666',
    marginLeft: 4,
  },
  statusIndicator: {
    position: 'absolute',
    top: 0,
    right: 0,
    width: 8,
    height: 8,
    borderRadius: 4,
    margin: 8,
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
    marginBottom: 8,
  },
  emptySubtext: {
    fontSize: 14,
    color: '#666',
  },
  loadingMoreContainer: {
    paddingVertical: 20,
    alignItems: 'center',
  },
});