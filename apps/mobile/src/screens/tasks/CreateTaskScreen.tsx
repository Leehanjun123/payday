import React, { useState, useEffect } from 'react';
import {
  StyleSheet,
  Text,
  View,
  ScrollView,
  TextInput,
  TouchableOpacity,
  Alert,
  ActivityIndicator,
  Platform,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import DateTimePicker from '@react-native-community/datetimepicker';
import taskService from '../../services/taskService';
import skillService, { Skill } from '../../services/skillService';

const categories = [
  { id: '디자인', name: '디자인', icon: '🎨' },
  { id: '개발', name: '개발', icon: '💻' },
  { id: '번역', name: '번역', icon: '🌏' },
  { id: '마케팅', name: '마케팅', icon: '📢' },
  { id: '교육', name: '교육', icon: '📚' },
  { id: '영상', name: '영상', icon: '🎬' },
  { id: '글쓰기', name: '글쓰기', icon: '✍️' },
  { id: '기타', name: '기타', icon: '📦' },
];

const priorities = [
  { id: 'LOW', name: '여유', color: '#4CAF50' },
  { id: 'NORMAL', name: '보통', color: '#2196F3' },
  { id: 'HIGH', name: '긴급', color: '#FF9800' },
  { id: 'URGENT', name: '매우 긴급', color: '#F44336' },
];

export default function CreateTaskScreen({ navigation }: any) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [category, setCategory] = useState('');
  const [budget, setBudget] = useState('');
  const [duration, setDuration] = useState('');
  const [priority, setPriority] = useState('NORMAL');
  const [deadline, setDeadline] = useState<Date | null>(null);
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [skills, setSkills] = useState<Skill[]>([]);
  const [selectedSkills, setSelectedSkills] = useState<string[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    loadSkills();
  }, []);

  const loadSkills = async () => {
    try {
      const skillsData = await skillService.getSkills();
      setSkills(skillsData);
    } catch (error) {
      console.error('Error loading skills:', error);
    }
  };

  const validateForm = (): boolean => {
    if (!title.trim()) {
      Alert.alert('오류', '작업 제목을 입력해주세요.');
      return false;
    }

    if (!description.trim()) {
      Alert.alert('오류', '작업 설명을 입력해주세요.');
      return false;
    }

    if (!category) {
      Alert.alert('오류', '카테고리를 선택해주세요.');
      return false;
    }

    const budgetNum = parseInt(budget);
    if (!budgetNum || budgetNum < 10000) {
      Alert.alert('오류', '예산은 최소 10,000원 이상이어야 합니다.');
      return false;
    }

    const durationNum = parseInt(duration);
    if (!durationNum || durationNum < 1) {
      Alert.alert('오류', '예상 작업 시간을 입력해주세요.');
      return false;
    }

    return true;
  };

  const handleSubmit = async () => {
    if (!validateForm()) return;

    setLoading(true);
    try {
      const taskData = {
        title: title.trim(),
        description: description.trim(),
        category,
        budget: parseInt(budget),
        duration: parseInt(duration),
        priority,
        deadline: deadline?.toISOString(),
        skillIds: selectedSkills,
      };

      const response = await taskService.createTask(taskData);

      Alert.alert(
        '성공',
        '작업이 등록되었습니다.',
        [
          {
            text: '확인',
            onPress: () => {
              navigation.navigate('TaskDetail', { taskId: response.task.id });
            },
          },
        ]
      );
    } catch (error: any) {
      Alert.alert('오류', error.message || '작업 등록에 실패했습니다.');
    } finally {
      setLoading(false);
    }
  };

  const toggleSkill = (skillId: string) => {
    setSelectedSkills((prev) =>
      prev.includes(skillId)
        ? prev.filter((id) => id !== skillId)
        : [...prev, skillId]
    );
  };

  const formatBudget = (value: string) => {
    const num = parseInt(value.replace(/[^0-9]/g, ''));
    if (isNaN(num)) return '';
    return num.toLocaleString('ko-KR');
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()}>
          <Ionicons name="arrow-back" size={24} color="#333" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>작업 등록</Text>
        <View style={styles.placeholder} />
      </View>

      <ScrollView
        style={styles.content}
        showsVerticalScrollIndicator={false}
        keyboardShouldPersistTaps="handled"
      >
        <View style={styles.section}>
          <Text style={styles.label}>작업 제목 *</Text>
          <TextInput
            style={styles.input}
            placeholder="예: 로고 디자인, 웹사이트 개발"
            placeholderTextColor="#999"
            value={title}
            onChangeText={setTitle}
            maxLength={100}
          />
          <Text style={styles.charCount}>{title.length}/100</Text>
        </View>

        <View style={styles.section}>
          <Text style={styles.label}>작업 설명 *</Text>
          <TextInput
            style={[styles.input, styles.textArea]}
            placeholder="작업에 대한 상세한 설명을 입력하세요..."
            placeholderTextColor="#999"
            value={description}
            onChangeText={setDescription}
            multiline
            numberOfLines={6}
            textAlignVertical="top"
            maxLength={1000}
          />
          <Text style={styles.charCount}>{description.length}/1000</Text>
        </View>

        <View style={styles.section}>
          <Text style={styles.label}>카테고리 *</Text>
          <ScrollView horizontal showsHorizontalScrollIndicator={false}>
            {categories.map((cat) => (
              <TouchableOpacity
                key={cat.id}
                style={[
                  styles.categoryButton,
                  category === cat.id && styles.categoryButtonActive,
                ]}
                onPress={() => setCategory(cat.id)}
              >
                <Text style={styles.categoryIcon}>{cat.icon}</Text>
                <Text
                  style={[
                    styles.categoryText,
                    category === cat.id && styles.categoryTextActive,
                  ]}
                >
                  {cat.name}
                </Text>
              </TouchableOpacity>
            ))}
          </ScrollView>
        </View>

        <View style={styles.row}>
          <View style={[styles.section, styles.halfSection]}>
            <Text style={styles.label}>예산 (₩) *</Text>
            <TextInput
              style={styles.input}
              placeholder="100,000"
              placeholderTextColor="#999"
              value={budget}
              onChangeText={(text) => setBudget(text.replace(/[^0-9]/g, ''))}
              keyboardType="numeric"
            />
            {budget && (
              <Text style={styles.budgetDisplay}>
                ₩{formatBudget(budget)}
              </Text>
            )}
          </View>

          <View style={[styles.section, styles.halfSection]}>
            <Text style={styles.label}>예상 시간 *</Text>
            <TextInput
              style={styles.input}
              placeholder="24"
              placeholderTextColor="#999"
              value={duration}
              onChangeText={setDuration}
              keyboardType="numeric"
            />
            {duration && (
              <Text style={styles.durationDisplay}>{duration}시간</Text>
            )}
          </View>
        </View>

        <View style={styles.section}>
          <Text style={styles.label}>우선순위</Text>
          <View style={styles.priorityContainer}>
            {priorities.map((p) => (
              <TouchableOpacity
                key={p.id}
                style={[
                  styles.priorityButton,
                  priority === p.id && styles.priorityButtonActive,
                  priority === p.id && { borderColor: p.color },
                ]}
                onPress={() => setPriority(p.id)}
              >
                <View
                  style={[styles.priorityDot, { backgroundColor: p.color }]}
                />
                <Text
                  style={[
                    styles.priorityText,
                    priority === p.id && { color: p.color },
                  ]}
                >
                  {p.name}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>

        <View style={styles.section}>
          <Text style={styles.label}>마감일</Text>
          <TouchableOpacity
            style={styles.dateButton}
            onPress={() => setShowDatePicker(true)}
          >
            <Ionicons name="calendar-outline" size={20} color="#666" />
            <Text style={styles.dateText}>
              {deadline
                ? deadline.toLocaleDateString('ko-KR')
                : '마감일 선택 (선택사항)'}
            </Text>
          </TouchableOpacity>
          {deadline && (
            <TouchableOpacity
              style={styles.clearButton}
              onPress={() => setDeadline(null)}
            >
              <Text style={styles.clearButtonText}>마감일 제거</Text>
            </TouchableOpacity>
          )}
        </View>

        {showDatePicker && (
          <DateTimePicker
            value={deadline || new Date()}
            mode="date"
            display={Platform.OS === 'ios' ? 'spinner' : 'default'}
            onChange={(event, date) => {
              setShowDatePicker(Platform.OS === 'ios');
              if (date) setDeadline(date);
            }}
            minimumDate={new Date()}
          />
        )}

        <View style={styles.section}>
          <Text style={styles.label}>필요 기술</Text>
          <View style={styles.skillsContainer}>
            {skills.map((skill) => (
              <TouchableOpacity
                key={skill.id}
                style={[
                  styles.skillTag,
                  selectedSkills.includes(skill.id) && styles.skillTagActive,
                ]}
                onPress={() => toggleSkill(skill.id)}
              >
                {skill.icon && <Text style={styles.skillIcon}>{skill.icon}</Text>}
                <Text
                  style={[
                    styles.skillText,
                    selectedSkills.includes(skill.id) && styles.skillTextActive,
                  ]}
                >
                  {skill.name}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>

        <View style={styles.tips}>
          <Ionicons name="bulb-outline" size={20} color="#FF9800" />
          <View style={styles.tipsContent}>
            <Text style={styles.tipsTitle}>작업 등록 팁</Text>
            <Text style={styles.tipsText}>
              • 구체적이고 명확한 설명을 작성하세요{'\n'}
              • 적정한 예산을 책정하면 더 많은 지원자를 받을 수 있습니다{'\n'}
              • 필요 기술을 정확히 선택하면 적합한 작업자를 찾기 쉽습니다
            </Text>
          </View>
        </View>
      </ScrollView>

      <View style={styles.bottomContainer}>
        <TouchableOpacity
          style={[styles.submitButton, loading && styles.submitButtonDisabled]}
          onPress={handleSubmit}
          disabled={loading}
        >
          {loading ? (
            <ActivityIndicator color="#fff" />
          ) : (
            <Text style={styles.submitButtonText}>작업 등록하기</Text>
          )}
        </TouchableOpacity>
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
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
  },
  placeholder: {
    width: 32,
  },
  content: {
    flex: 1,
  },
  section: {
    backgroundColor: '#fff',
    paddingHorizontal: 20,
    paddingVertical: 16,
    marginBottom: 1,
  },
  row: {
    flexDirection: 'row',
  },
  halfSection: {
    flex: 1,
  },
  label: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
    marginBottom: 8,
  },
  input: {
    borderWidth: 1,
    borderColor: '#e0e0e0',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
    fontSize: 16,
    color: '#333',
  },
  textArea: {
    height: 120,
    textAlignVertical: 'top',
  },
  charCount: {
    fontSize: 12,
    color: '#999',
    textAlign: 'right',
    marginTop: 4,
  },
  categoryButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 10,
    marginRight: 12,
    borderRadius: 20,
    backgroundColor: '#f5f5f5',
    borderWidth: 1,
    borderColor: 'transparent',
  },
  categoryButtonActive: {
    backgroundColor: '#007AFF',
    borderColor: '#007AFF',
  },
  categoryIcon: {
    fontSize: 18,
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
  budgetDisplay: {
    fontSize: 12,
    color: '#007AFF',
    marginTop: 4,
  },
  durationDisplay: {
    fontSize: 12,
    color: '#666',
    marginTop: 4,
  },
  priorityContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
  },
  priorityButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 8,
    marginRight: 12,
    marginBottom: 8,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#e0e0e0',
  },
  priorityButtonActive: {
    backgroundColor: '#f5f5f5',
  },
  priorityDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginRight: 6,
  },
  priorityText: {
    fontSize: 14,
    color: '#666',
  },
  dateButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderWidth: 1,
    borderColor: '#e0e0e0',
    borderRadius: 8,
  },
  dateText: {
    fontSize: 16,
    color: '#333',
    marginLeft: 8,
  },
  clearButton: {
    marginTop: 8,
  },
  clearButtonText: {
    fontSize: 14,
    color: '#FF3B30',
  },
  skillsContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
  },
  skillTag: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 6,
    marginRight: 8,
    marginBottom: 8,
    borderRadius: 16,
    backgroundColor: '#f0f0f0',
    borderWidth: 1,
    borderColor: 'transparent',
  },
  skillTagActive: {
    backgroundColor: '#e3f2fd',
    borderColor: '#1976d2',
  },
  skillIcon: {
    fontSize: 14,
    marginRight: 4,
  },
  skillText: {
    fontSize: 13,
    color: '#666',
  },
  skillTextActive: {
    color: '#1976d2',
    fontWeight: '500',
  },
  tips: {
    flexDirection: 'row',
    backgroundColor: '#FFF8E1',
    padding: 16,
    margin: 20,
    borderRadius: 8,
    borderLeftWidth: 4,
    borderLeftColor: '#FF9800',
  },
  tipsContent: {
    flex: 1,
    marginLeft: 12,
  },
  tipsTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#F57C00',
    marginBottom: 4,
  },
  tipsText: {
    fontSize: 12,
    color: '#666',
    lineHeight: 18,
  },
  bottomContainer: {
    backgroundColor: '#fff',
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderTopWidth: 1,
    borderTopColor: '#e0e0e0',
  },
  submitButton: {
    backgroundColor: '#007AFF',
    paddingVertical: 16,
    borderRadius: 12,
    alignItems: 'center',
  },
  submitButtonDisabled: {
    opacity: 0.6,
  },
  submitButtonText: {
    fontSize: 18,
    fontWeight: '600',
    color: '#fff',
  },
});