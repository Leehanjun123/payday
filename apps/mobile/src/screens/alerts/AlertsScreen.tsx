import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  RefreshControl,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  Alert,
  Modal,
  TextInput,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Picker } from '@react-native-picker/picker';
import predictionService, { PriceAlert, CreatePriceAlertData } from '../../services/predictionService';

const AlertsScreen = () => {
  const [alerts, setAlerts] = useState<PriceAlert[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [createForm, setCreateForm] = useState<CreatePriceAlertData>({
    symbol: '',
    name: '',
    type: 'PRICE_TARGET',
    targetPrice: 0,
    currentPrice: 0,
    condition: 'ABOVE',
    message: '',
  });

  useEffect(() => {
    loadAlerts();
  }, []);

  const loadAlerts = async () => {
    try {
      setLoading(true);
      const response = await predictionService.getUserPriceAlerts();
      setAlerts(response.alerts);
    } catch (error) {
      console.error('Error loading alerts:', error);
      Alert.alert('오류', '알림 정보를 불러오는데 실패했습니다.');
    } finally {
      setLoading(false);
    }
  };

  const onRefresh = async () => {
    setRefreshing(true);
    await loadAlerts();
    setRefreshing(false);
  };

  const handleCreateAlert = async () => {
    try {
      if (!createForm.symbol || !createForm.name || createForm.targetPrice <= 0) {
        Alert.alert('오류', '모든 필드를 올바르게 입력해주세요.');
        return;
      }

      await predictionService.createPriceAlert(createForm);
      setShowCreateModal(false);
      setCreateForm({
        symbol: '',
        name: '',
        type: 'PRICE_TARGET',
        targetPrice: 0,
        currentPrice: 0,
        condition: 'ABOVE',
        message: '',
      });
      Alert.alert('성공', '가격 알림이 생성되었습니다.');
      await loadAlerts();
    } catch (error) {
      console.error('Error creating alert:', error);
      Alert.alert('오류', '알림 생성에 실패했습니다.');
    }
  };

  const handleToggleAlert = async (alertId: string, isActive: boolean) => {
    try {
      await predictionService.updatePriceAlert(alertId, { isActive: !isActive });
      setAlerts(prev => prev.map(alert =>
        alert.id === alertId ? { ...alert, isActive: !isActive } : alert
      ));
    } catch (error) {
      console.error('Error toggling alert:', error);
      Alert.alert('오류', '알림 상태 변경에 실패했습니다.');
    }
  };

  const handleDeleteAlert = async (alertId: string) => {
    Alert.alert(
      '알림 삭제',
      '이 알림을 삭제하시겠습니까?',
      [
        { text: '취소', style: 'cancel' },
        {
          text: '삭제',
          style: 'destructive',
          onPress: async () => {
            try {
              await predictionService.deletePriceAlert(alertId);
              setAlerts(prev => prev.filter(alert => alert.id !== alertId));
              Alert.alert('성공', '알림이 삭제되었습니다.');
            } catch (error) {
              console.error('Error deleting alert:', error);
              Alert.alert('오류', '알림 삭제에 실패했습니다.');
            }
          },
        },
      ]
    );
  };

  const renderAlertCard = (alert: PriceAlert) => {
    return (
      <View key={alert.id} style={styles.alertCard}>
        <View style={styles.cardHeader}>
          <View style={styles.alertInfo}>
            <Text style={styles.alertSymbol}>{alert.symbol}</Text>
            <Text style={styles.alertName}>{alert.name}</Text>
          </View>
          <View style={styles.alertActions}>
            <TouchableOpacity
              onPress={() => handleToggleAlert(alert.id, alert.isActive)}
              style={[styles.toggleButton, { backgroundColor: alert.isActive ? '#4CAF50' : '#ccc' }]}
            >
              <Ionicons
                name={alert.isActive ? 'notifications' : 'notifications-off'}
                size={16}
                color="#fff"
              />
            </TouchableOpacity>
            <TouchableOpacity
              onPress={() => handleDeleteAlert(alert.id)}
              style={styles.deleteButton}
            >
              <Ionicons name="trash-outline" size={16} color="#F44336" />
            </TouchableOpacity>
          </View>
        </View>

        <View style={styles.alertDetails}>
          <View style={styles.alertRow}>
            <Text style={styles.alertLabel}>알림 유형:</Text>
            <Text style={styles.alertValue}>
              {predictionService.getAlertTypeText(alert.type)}
            </Text>
          </View>
          <View style={styles.alertRow}>
            <Text style={styles.alertLabel}>조건:</Text>
            <Text style={styles.alertValue}>
              ₩{alert.targetPrice.toLocaleString()} {predictionService.getConditionText(alert.condition)}
            </Text>
          </View>
          <View style={styles.alertRow}>
            <Text style={styles.alertLabel}>현재가:</Text>
            <Text style={styles.alertValue}>₩{alert.currentPrice.toLocaleString()}</Text>
          </View>
          {alert.message && (
            <View style={styles.alertRow}>
              <Text style={styles.alertLabel}>메시지:</Text>
              <Text style={styles.alertValue}>{alert.message}</Text>
            </View>
          )}
        </View>

        {alert.isTriggered && (
          <View style={styles.triggeredBadge}>
            <Ionicons name="checkmark-circle" size={16} color="#4CAF50" />
            <Text style={styles.triggeredText}>
              {alert.triggeredAt ? predictionService.formatDateTime(alert.triggeredAt) : '알림 발생'}
            </Text>
          </View>
        )}

        <View style={styles.cardFooter}>
          <Text style={styles.createdAt}>
            생성일: {predictionService.formatDateShort(alert.createdAt)}
          </Text>
          <View style={[
            styles.statusBadge,
            { backgroundColor: alert.isActive ? '#E8F5E8' : '#F5F5F5' }
          ]}>
            <Text style={[
              styles.statusText,
              { color: alert.isActive ? '#4CAF50' : '#999' }
            ]}>
              {alert.isActive ? '활성' : '비활성'}
            </Text>
          </View>
        </View>
      </View>
    );
  };

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#007AFF" />
        <Text style={styles.loadingText}>알림 정보를 불러오는 중...</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>가격 알림</Text>
        <TouchableOpacity
          onPress={() => setShowCreateModal(true)}
          style={styles.addButton}
        >
          <Ionicons name="add" size={24} color="#fff" />
        </TouchableOpacity>
      </View>

      <ScrollView
        style={styles.content}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
      >
        {alerts.length === 0 ? (
          <View style={styles.emptyContainer}>
            <Ionicons name="notifications-outline" size={64} color="#ccc" />
            <Text style={styles.emptyTitle}>설정된 알림이 없습니다</Text>
            <Text style={styles.emptySubtitle}>+ 버튼을 눌러 가격 알림을 생성해보세요</Text>
          </View>
        ) : (
          alerts.map(renderAlertCard)
        )}
      </ScrollView>

      <Modal
        visible={showCreateModal}
        animationType="slide"
        presentationStyle="pageSheet"
      >
        <View style={styles.modalContainer}>
          <View style={styles.modalHeader}>
            <TouchableOpacity
              onPress={() => setShowCreateModal(false)}
              style={styles.modalCloseButton}
            >
              <Text style={styles.modalCloseText}>취소</Text>
            </TouchableOpacity>
            <Text style={styles.modalTitle}>가격 알림 생성</Text>
            <TouchableOpacity
              onPress={handleCreateAlert}
              style={styles.modalSaveButton}
            >
              <Text style={styles.modalSaveText}>저장</Text>
            </TouchableOpacity>
          </View>

          <ScrollView style={styles.modalContent}>
            <View style={styles.formGroup}>
              <Text style={styles.formLabel}>종목 심볼</Text>
              <TextInput
                style={styles.formInput}
                value={createForm.symbol}
                onChangeText={(text) => setCreateForm(prev => ({ ...prev, symbol: text }))}
                placeholder="예: AAPL, 삼성전자"
              />
            </View>

            <View style={styles.formGroup}>
              <Text style={styles.formLabel}>종목명</Text>
              <TextInput
                style={styles.formInput}
                value={createForm.name}
                onChangeText={(text) => setCreateForm(prev => ({ ...prev, name: text }))}
                placeholder="예: 애플, 삼성전자"
              />
            </View>

            <View style={styles.formGroup}>
              <Text style={styles.formLabel}>알림 유형</Text>
              <View style={styles.pickerContainer}>
                <Picker
                  selectedValue={createForm.type}
                  onValueChange={(value) => setCreateForm(prev => ({ ...prev, type: value }))}
                >
                  <Picker.Item label="목표가 알림" value="PRICE_TARGET" />
                  <Picker.Item label="등락률 알림" value="PERCENTAGE_CHANGE" />
                  <Picker.Item label="거래량 급증" value="VOLUME_SPIKE" />
                  <Picker.Item label="기술적 신호" value="TECHNICAL_SIGNAL" />
                </Picker>
              </View>
            </View>

            <View style={styles.formGroup}>
              <Text style={styles.formLabel}>조건</Text>
              <View style={styles.pickerContainer}>
                <Picker
                  selectedValue={createForm.condition}
                  onValueChange={(value) => setCreateForm(prev => ({ ...prev, condition: value }))}
                >
                  <Picker.Item label="이상" value="ABOVE" />
                  <Picker.Item label="이하" value="BELOW" />
                  <Picker.Item label="도달" value="EQUALS" />
                </Picker>
              </View>
            </View>

            <View style={styles.formGroup}>
              <Text style={styles.formLabel}>목표가</Text>
              <TextInput
                style={styles.formInput}
                value={createForm.targetPrice.toString()}
                onChangeText={(text) => setCreateForm(prev => ({ ...prev, targetPrice: parseFloat(text) || 0 }))}
                placeholder="목표가를 입력하세요"
                keyboardType="numeric"
              />
            </View>

            <View style={styles.formGroup}>
              <Text style={styles.formLabel}>현재가</Text>
              <TextInput
                style={styles.formInput}
                value={createForm.currentPrice.toString()}
                onChangeText={(text) => setCreateForm(prev => ({ ...prev, currentPrice: parseFloat(text) || 0 }))}
                placeholder="현재가를 입력하세요"
                keyboardType="numeric"
              />
            </View>

            <View style={styles.formGroup}>
              <Text style={styles.formLabel}>메시지 (선택)</Text>
              <TextInput
                style={[styles.formInput, styles.messageInput]}
                value={createForm.message}
                onChangeText={(text) => setCreateForm(prev => ({ ...prev, message: text }))}
                placeholder="알림 메시지를 입력하세요"
                multiline
                numberOfLines={3}
              />
            </View>
          </ScrollView>
        </View>
      </Modal>
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
  addButton: {
    backgroundColor: '#007AFF',
    width: 40,
    height: 40,
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
  },
  content: {
    flex: 1,
    padding: 20,
  },
  alertCard: {
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
  alertInfo: {
    flex: 1,
  },
  alertSymbol: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 2,
  },
  alertName: {
    fontSize: 14,
    color: '#666',
  },
  alertActions: {
    flexDirection: 'row',
    gap: 8,
  },
  toggleButton: {
    width: 32,
    height: 32,
    borderRadius: 16,
    justifyContent: 'center',
    alignItems: 'center',
  },
  deleteButton: {
    width: 32,
    height: 32,
    borderRadius: 16,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#f5f5f5',
  },
  alertDetails: {
    marginBottom: 12,
  },
  alertRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 6,
  },
  alertLabel: {
    fontSize: 14,
    color: '#666',
  },
  alertValue: {
    fontSize: 14,
    color: '#333',
    fontWeight: '500',
    textAlign: 'right',
    flex: 1,
    marginLeft: 12,
  },
  triggeredBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#E8F5E8',
    padding: 8,
    borderRadius: 8,
    marginBottom: 12,
  },
  triggeredText: {
    fontSize: 12,
    color: '#4CAF50',
    marginLeft: 6,
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
  createdAt: {
    fontSize: 12,
    color: '#999',
  },
  statusBadge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 8,
  },
  statusText: {
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
  modalContainer: {
    flex: 1,
    backgroundColor: '#fff',
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
  modalCloseButton: {
    padding: 4,
  },
  modalCloseText: {
    fontSize: 16,
    color: '#007AFF',
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
  },
  modalSaveButton: {
    padding: 4,
  },
  modalSaveText: {
    fontSize: 16,
    color: '#007AFF',
    fontWeight: '600',
  },
  modalContent: {
    flex: 1,
    padding: 20,
  },
  formGroup: {
    marginBottom: 20,
  },
  formLabel: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginBottom: 8,
  },
  formInput: {
    borderWidth: 1,
    borderColor: '#e0e0e0',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 12,
    fontSize: 16,
    backgroundColor: '#fff',
  },
  messageInput: {
    height: 80,
    textAlignVertical: 'top',
  },
  pickerContainer: {
    borderWidth: 1,
    borderColor: '#e0e0e0',
    borderRadius: 8,
    backgroundColor: '#fff',
  },
});

export default AlertsScreen;