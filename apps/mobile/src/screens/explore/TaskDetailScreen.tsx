import React, { useState, useEffect } from 'react';
import {
  StyleSheet,
  Text,
  View,
  ScrollView,
  TouchableOpacity,
  ActivityIndicator,
  Alert,
  TextInput,
  KeyboardAvoidingView,
  Platform,
  Modal,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { ExploreStackScreenProps } from '../../navigation/types';
import taskService, { Task, TaskApplication } from '../../services/taskService';
import { useAuth } from '../../contexts/AuthContext';

export default function TaskDetailScreen({
  route,
  navigation,
}: ExploreStackScreenProps<'TaskDetail'>) {
  const { taskId } = route.params;
  const { user } = useAuth();
  const [task, setTask] = useState<Task | null>(null);
  const [loading, setLoading] = useState(true);
  const [applyModalVisible, setApplyModalVisible] = useState(false);
  const [proposal, setProposal] = useState('');
  const [bidAmount, setBidAmount] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [hasApplied, setHasApplied] = useState(false);

  useEffect(() => {
    loadTask();
  }, [taskId]);

  const loadTask = async () => {
    try {
      const taskData = await taskService.getTask(taskId);
      setTask(taskData);

      // Check if current user has already applied
      if (user && taskData.applications) {
        const userApplication = taskData.applications.find(
          (app: TaskApplication) => app.userId === user.id
        );
        setHasApplied(!!userApplication);
      }
    } catch (error) {
      console.error('Error loading task:', error);
      Alert.alert('오류', '작업을 불러오는데 실패했습니다.');
      navigation.goBack();
    } finally {
      setLoading(false);
    }
  };

  const formatBudget = (budget: number) => {
    if (budget >= 10000) {
      return `${(budget / 10000).toFixed(0)}만원`;
    }
    return `${budget.toLocaleString()}원`;
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('ko-KR', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
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

  const getPriorityText = (priority: string) => {
    switch (priority) {
      case 'URGENT':
        return '매우 긴급';
      case 'HIGH':
        return '긴급';
      case 'NORMAL':
        return '보통';
      case 'LOW':
        return '여유';
      default:
        return priority;
    }
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'URGENT':
        return '#F44336';
      case 'HIGH':
        return '#FF9800';
      case 'NORMAL':
        return '#4CAF50';
      case 'LOW':
        return '#2196F3';
      default:
        return '#666';
    }
  };

  const handleApply = async () => {
    if (!proposal.trim()) {
      Alert.alert('오류', '제안 내용을 입력해주세요.');
      return;
    }

    const bid = parseInt(bidAmount);
    if (isNaN(bid) || bid <= 0) {
      Alert.alert('오류', '올바른 금액을 입력해주세요.');
      return;
    }

    if (task && bid > task.budget) {
      Alert.alert('오류', '입찰 금액은 예산을 초과할 수 없습니다.');
      return;
    }

    setSubmitting(true);
    try {
      await taskService.applyToTask(taskId, {
        proposal: proposal.trim(),
        bidAmount: bid,
      });

      Alert.alert('성공', '작업 신청이 완료되었습니다.');
      setApplyModalVisible(false);
      setHasApplied(true);
      loadTask(); // Reload task to get updated application count
    } catch (error: any) {
      Alert.alert('오류', error.message || '신청 중 오류가 발생했습니다.');
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#007AFF" />
        </View>
      </SafeAreaView>
    );
  }

  if (!task) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.errorContainer}>
          <Text style={styles.errorText}>작업을 찾을 수 없습니다</Text>
        </View>
      </SafeAreaView>
    );
  }

  const isOwner = user?.id === task.poster.id;
  const canApply = task.status === 'OPEN' && !isOwner && !hasApplied;

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()}>
          <Ionicons name="arrow-back" size={24} color="#333" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>작업 상세</Text>
        <TouchableOpacity style={styles.menuButton}>
          <Ionicons name="ellipsis-vertical" size={24} color="#333" />
        </TouchableOpacity>
      </View>

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        <View style={styles.statusBadge}>
          <View
            style={[
              styles.statusIndicator,
              { backgroundColor: getStatusColor(task.status) },
            ]}
          />
          <Text style={styles.statusText}>{getStatusText(task.status)}</Text>
        </View>

        <Text style={styles.title}>{task.title}</Text>

        <View style={styles.metaContainer}>
          <View style={styles.metaItem}>
            <Text style={styles.metaLabel}>카테고리</Text>
            <Text style={styles.metaValue}>{task.category}</Text>
          </View>
          <View style={styles.metaItem}>
            <Text style={styles.metaLabel}>예산</Text>
            <Text style={[styles.metaValue, styles.budgetText]}>
              ₩{formatBudget(task.budget)}
            </Text>
          </View>
          <View style={styles.metaItem}>
            <Text style={styles.metaLabel}>예상 시간</Text>
            <Text style={styles.metaValue}>{task.duration}시간</Text>
          </View>
        </View>

        {task.deadline && (
          <View style={styles.deadlineContainer}>
            <Ionicons name="calendar-outline" size={20} color="#FF9800" />
            <Text style={styles.deadlineText}>
              마감일: {formatDate(task.deadline)}
            </Text>
          </View>
        )}

        <View style={styles.priorityContainer}>
          <Text style={styles.sectionTitle}>우선순위</Text>
          <View
            style={[
              styles.priorityBadge,
              { backgroundColor: getPriorityColor(task.priority) },
            ]}
          >
            <Text style={styles.priorityBadgeText}>
              {getPriorityText(task.priority)}
            </Text>
          </View>
        </View>

        <View style={styles.descriptionContainer}>
          <Text style={styles.sectionTitle}>작업 설명</Text>
          <Text style={styles.description}>{task.description}</Text>
        </View>

        {task.skills && task.skills.length > 0 && (
          <View style={styles.skillsContainer}>
            <Text style={styles.sectionTitle}>필요 기술</Text>
            <View style={styles.skillsList}>
              {task.skills.map((skillItem, index) => (
                <View key={index} style={styles.skillTag}>
                  <Text style={styles.skillIcon}>{skillItem.skill.icon}</Text>
                  <Text style={styles.skillName}>{skillItem.skill.name}</Text>
                </View>
              ))}
            </View>
          </View>
        )}

        <View style={styles.posterContainer}>
          <Text style={styles.sectionTitle}>의뢰자 정보</Text>
          <View style={styles.posterInfo}>
            <View style={styles.posterAvatar}>
              <Text style={styles.posterInitial}>
                {task.poster.name.charAt(0)}
              </Text>
            </View>
            <View style={styles.posterDetails}>
              <Text style={styles.posterName}>{task.poster.name}</Text>
              <Text style={styles.posterLevel}>Level {task.poster.level}</Text>
            </View>
          </View>
        </View>

        <View style={styles.statsContainer}>
          <View style={styles.statItem}>
            <Ionicons name="people-outline" size={24} color="#666" />
            <Text style={styles.statValue}>{task._count?.applications || 0}</Text>
            <Text style={styles.statLabel}>지원자</Text>
          </View>
          <View style={styles.statItem}>
            <Ionicons name="time-outline" size={24} color="#666" />
            <Text style={styles.statValue}>{task.duration}</Text>
            <Text style={styles.statLabel}>시간</Text>
          </View>
          <View style={styles.statItem}>
            <Ionicons name="calendar-outline" size={24} color="#666" />
            <Text style={styles.statValue}>
              {new Date(task.createdAt).toLocaleDateString('ko-KR', {
                month: 'numeric',
                day: 'numeric',
              })}
            </Text>
            <Text style={styles.statLabel}>등록일</Text>
          </View>
        </View>
      </ScrollView>

      {canApply && (
        <View style={styles.bottomContainer}>
          <TouchableOpacity
            style={styles.applyButton}
            onPress={() => setApplyModalVisible(true)}
          >
            <Text style={styles.applyButtonText}>작업 신청하기</Text>
          </TouchableOpacity>
        </View>
      )}

      {hasApplied && (
        <View style={styles.bottomContainer}>
          <View style={styles.appliedBadge}>
            <Ionicons name="checkmark-circle" size={20} color="#4CAF50" />
            <Text style={styles.appliedText}>신청 완료</Text>
          </View>
        </View>
      )}

      <Modal
        animationType="slide"
        transparent={true}
        visible={applyModalVisible}
        onRequestClose={() => setApplyModalVisible(false)}
      >
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
          style={styles.modalOverlay}
        >
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>작업 신청</Text>
              <TouchableOpacity
                onPress={() => setApplyModalVisible(false)}
                disabled={submitting}
              >
                <Ionicons name="close" size={24} color="#333" />
              </TouchableOpacity>
            </View>

            <ScrollView style={styles.modalBody}>
              <Text style={styles.inputLabel}>입찰 금액 (₩)</Text>
              <TextInput
                style={styles.input}
                placeholder={`최대 ${formatBudget(task.budget)}`}
                placeholderTextColor="#999"
                value={bidAmount}
                onChangeText={setBidAmount}
                keyboardType="numeric"
                editable={!submitting}
              />

              <Text style={styles.inputLabel}>제안 내용</Text>
              <TextInput
                style={[styles.input, styles.textArea]}
                placeholder="왜 이 작업에 적합한지 설명해주세요..."
                placeholderTextColor="#999"
                value={proposal}
                onChangeText={setProposal}
                multiline
                numberOfLines={6}
                textAlignVertical="top"
                editable={!submitting}
              />

              <TouchableOpacity
                style={[styles.submitButton, submitting && styles.disabledButton]}
                onPress={handleApply}
                disabled={submitting}
              >
                {submitting ? (
                  <ActivityIndicator color="#fff" />
                ) : (
                  <Text style={styles.submitButtonText}>신청하기</Text>
                )}
              </TouchableOpacity>
            </ScrollView>
          </View>
        </KeyboardAvoidingView>
      </Modal>
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
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
  },
  menuButton: {
    padding: 4,
  },
  content: {
    flex: 1,
    backgroundColor: '#fff',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  errorText: {
    fontSize: 16,
    color: '#666',
  },
  statusBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingTop: 20,
  },
  statusIndicator: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginRight: 8,
  },
  statusText: {
    fontSize: 14,
    color: '#666',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#333',
    paddingHorizontal: 20,
    paddingVertical: 16,
  },
  metaContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  metaItem: {
    alignItems: 'center',
  },
  metaLabel: {
    fontSize: 12,
    color: '#999',
    marginBottom: 4,
  },
  metaValue: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
  },
  budgetText: {
    color: '#007AFF',
  },
  deadlineContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 12,
    backgroundColor: '#FFF3E0',
  },
  deadlineText: {
    fontSize: 14,
    color: '#FF9800',
    marginLeft: 8,
    fontWeight: '500',
  },
  priorityContainer: {
    paddingHorizontal: 20,
    paddingVertical: 16,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginBottom: 12,
  },
  priorityBadge: {
    alignSelf: 'flex-start',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 6,
  },
  priorityBadgeText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: '500',
  },
  descriptionContainer: {
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderTopWidth: 1,
    borderTopColor: '#f0f0f0',
  },
  description: {
    fontSize: 15,
    color: '#666',
    lineHeight: 24,
  },
  skillsContainer: {
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderTopWidth: 1,
    borderTopColor: '#f0f0f0',
  },
  skillsList: {
    flexDirection: 'row',
    flexWrap: 'wrap',
  },
  skillTag: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#e3f2fd',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
    marginRight: 8,
    marginBottom: 8,
  },
  skillIcon: {
    fontSize: 16,
    marginRight: 4,
  },
  skillName: {
    fontSize: 14,
    color: '#1976d2',
  },
  posterContainer: {
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderTopWidth: 1,
    borderTopColor: '#f0f0f0',
  },
  posterInfo: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  posterAvatar: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#007AFF',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  posterInitial: {
    color: '#fff',
    fontSize: 20,
    fontWeight: 'bold',
  },
  posterDetails: {
    flex: 1,
  },
  posterName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginBottom: 4,
  },
  posterLevel: {
    fontSize: 14,
    color: '#666',
  },
  statsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    paddingHorizontal: 20,
    paddingVertical: 20,
    borderTopWidth: 1,
    borderTopColor: '#f0f0f0',
    marginBottom: 20,
  },
  statItem: {
    alignItems: 'center',
  },
  statValue: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
    marginVertical: 4,
  },
  statLabel: {
    fontSize: 12,
    color: '#999',
  },
  bottomContainer: {
    backgroundColor: '#fff',
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderTopWidth: 1,
    borderTopColor: '#e0e0e0',
  },
  applyButton: {
    backgroundColor: '#007AFF',
    borderRadius: 8,
    paddingVertical: 16,
    alignItems: 'center',
  },
  applyButtonText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: '600',
  },
  appliedBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 12,
  },
  appliedText: {
    fontSize: 16,
    color: '#4CAF50',
    fontWeight: '600',
    marginLeft: 8,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'flex-end',
  },
  modalContent: {
    backgroundColor: '#fff',
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    maxHeight: '80%',
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  modalTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#333',
  },
  modalBody: {
    padding: 20,
  },
  inputLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
    marginBottom: 8,
  },
  input: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    paddingHorizontal: 16,
    paddingVertical: 12,
    fontSize: 16,
    color: '#333',
    marginBottom: 20,
  },
  textArea: {
    height: 120,
    textAlignVertical: 'top',
  },
  submitButton: {
    backgroundColor: '#007AFF',
    borderRadius: 8,
    paddingVertical: 16,
    alignItems: 'center',
    marginTop: 10,
  },
  disabledButton: {
    opacity: 0.6,
  },
  submitButtonText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: '600',
  },
});