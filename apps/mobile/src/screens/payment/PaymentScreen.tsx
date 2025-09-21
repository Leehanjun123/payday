import React, { useState, useEffect } from 'react';
import {
  StyleSheet,
  Text,
  View,
  ScrollView,
  TouchableOpacity,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import paymentService, { Payment } from '../../services/paymentService';

export default function PaymentScreen({ route, navigation }: any) {
  const { taskId, taskTitle, taskBudget, assigneeName } = route.params;
  const [payment, setPayment] = useState<Payment | null>(null);
  const [selectedMethod, setSelectedMethod] = useState<string>('CARD');
  const [loading, setLoading] = useState(false);
  const [processing, setProcessing] = useState(false);

  const paymentMethods = [
    { id: 'CARD', name: '신용/체크카드', icon: 'card-outline' },
    { id: 'KAKAO_PAY', name: '카카오페이', icon: 'logo-octocat' },
    { id: 'TOSS', name: '토스', icon: 'cash-outline' },
    { id: 'BANK', name: '계좌이체', icon: 'business-outline' },
  ];

  useEffect(() => {
    initializePayment();
  }, []);

  const initializePayment = async () => {
    setLoading(true);
    try {
      const response = await paymentService.initializePayment(taskId);
      setPayment(response.payment);
    } catch (error: any) {
      Alert.alert('오류', error.message || '결제 초기화에 실패했습니다.');
      navigation.goBack();
    } finally {
      setLoading(false);
    }
  };

  const handlePayment = async () => {
    if (!payment) return;

    Alert.alert(
      '결제 확인',
      `${paymentService.formatAmount(payment.amount)}을 결제하시겠습니까?`,
      [
        { text: '취소', style: 'cancel' },
        {
          text: '결제',
          onPress: processPayment,
        },
      ]
    );
  };

  const processPayment = async () => {
    if (!payment) return;

    setProcessing(true);
    try {
      const response = await paymentService.processPayment(payment.id, {
        paymentMethod: selectedMethod as any,
      });

      Alert.alert(
        '결제 완료',
        '결제가 성공적으로 완료되었습니다.',
        [
          {
            text: '확인',
            onPress: () => {
              navigation.navigate('TaskDetail', { taskId });
            },
          },
        ]
      );
    } catch (error: any) {
      Alert.alert('결제 실패', error.message || '결제 처리 중 오류가 발생했습니다.');
    } finally {
      setProcessing(false);
    }
  };

  if (loading || !payment) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#007AFF" />
          <Text style={styles.loadingText}>결제 정보 불러오는 중...</Text>
        </View>
      </SafeAreaView>
    );
  }

  const platformFee = paymentService.calculatePlatformFee(payment.amount);
  const netAmount = paymentService.calculateNetAmount(payment.amount);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()}>
          <Ionicons name="arrow-back" size={24} color="#333" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>결제하기</Text>
        <View style={styles.placeholder} />
      </View>

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        <View style={styles.taskInfo}>
          <Text style={styles.taskTitle}>{taskTitle}</Text>
          <View style={styles.assigneeInfo}>
            <Ionicons name="person-outline" size={16} color="#666" />
            <Text style={styles.assigneeName}>작업자: {assigneeName}</Text>
          </View>
        </View>

        <View style={styles.priceBreakdown}>
          <Text style={styles.sectionTitle}>결제 금액</Text>

          <View style={styles.priceItem}>
            <Text style={styles.priceLabel}>작업 금액</Text>
            <Text style={styles.priceValue}>
              {paymentService.formatAmount(payment.amount)}
            </Text>
          </View>

          <View style={styles.priceItem}>
            <Text style={styles.priceLabel}>플랫폼 수수료 (10%)</Text>
            <Text style={styles.priceFee}>
              -{paymentService.formatAmount(platformFee)}
            </Text>
          </View>

          <View style={styles.divider} />

          <View style={styles.priceItem}>
            <Text style={styles.totalLabel}>작업자 수령액</Text>
            <Text style={styles.totalValue}>
              {paymentService.formatAmount(netAmount)}
            </Text>
          </View>
        </View>

        <View style={styles.paymentMethods}>
          <Text style={styles.sectionTitle}>결제 수단</Text>

          {paymentMethods.map((method) => (
            <TouchableOpacity
              key={method.id}
              style={[
                styles.methodItem,
                selectedMethod === method.id && styles.methodItemSelected,
              ]}
              onPress={() => setSelectedMethod(method.id)}
            >
              <View style={styles.methodLeft}>
                <Ionicons
                  name={method.icon as any}
                  size={24}
                  color={selectedMethod === method.id ? '#007AFF' : '#666'}
                />
                <Text
                  style={[
                    styles.methodName,
                    selectedMethod === method.id && styles.methodNameSelected,
                  ]}
                >
                  {method.name}
                </Text>
              </View>
              <View
                style={[
                  styles.radio,
                  selectedMethod === method.id && styles.radioSelected,
                ]}
              >
                {selectedMethod === method.id && (
                  <View style={styles.radioInner} />
                )}
              </View>
            </TouchableOpacity>
          ))}
        </View>

        <View style={styles.terms}>
          <Text style={styles.termsText}>
            결제 진행 시{' '}
            <Text style={styles.termsLink}>이용약관</Text> 및{' '}
            <Text style={styles.termsLink}>환불정책</Text>에 동의하는 것으로 간주됩니다.
          </Text>
        </View>

        <View style={styles.securityInfo}>
          <Ionicons name="shield-checkmark-outline" size={20} color="#4CAF50" />
          <Text style={styles.securityText}>
            모든 결제 정보는 안전하게 암호화되어 처리됩니다
          </Text>
        </View>
      </ScrollView>

      <View style={styles.bottomContainer}>
        <View style={styles.totalSummary}>
          <Text style={styles.totalSummaryLabel}>총 결제 금액</Text>
          <Text style={styles.totalSummaryValue}>
            {paymentService.formatAmount(payment.amount)}
          </Text>
        </View>

        <TouchableOpacity
          style={[styles.payButton, processing && styles.payButtonDisabled]}
          onPress={handlePayment}
          disabled={processing}
        >
          {processing ? (
            <ActivityIndicator color="#fff" />
          ) : (
            <>
              <Ionicons name="lock-closed" size={20} color="#fff" />
              <Text style={styles.payButtonText}>안전 결제</Text>
            </>
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
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    marginTop: 12,
    fontSize: 14,
    color: '#666',
  },
  content: {
    flex: 1,
  },
  taskInfo: {
    backgroundColor: '#fff',
    padding: 20,
    marginBottom: 12,
  },
  taskTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
    marginBottom: 8,
  },
  assigneeInfo: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  assigneeName: {
    fontSize: 14,
    color: '#666',
    marginLeft: 6,
  },
  priceBreakdown: {
    backgroundColor: '#fff',
    padding: 20,
    marginBottom: 12,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginBottom: 16,
  },
  priceItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  priceLabel: {
    fontSize: 14,
    color: '#666',
  },
  priceValue: {
    fontSize: 16,
    fontWeight: '500',
    color: '#333',
  },
  priceFee: {
    fontSize: 14,
    color: '#FF5252',
  },
  divider: {
    height: 1,
    backgroundColor: '#e0e0e0',
    marginVertical: 12,
  },
  totalLabel: {
    fontSize: 15,
    fontWeight: '600',
    color: '#333',
  },
  totalValue: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#007AFF',
  },
  paymentMethods: {
    backgroundColor: '#fff',
    padding: 20,
    marginBottom: 12,
  },
  methodItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 16,
    paddingHorizontal: 16,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#e0e0e0',
    marginBottom: 12,
  },
  methodItemSelected: {
    borderColor: '#007AFF',
    backgroundColor: '#f0f8ff',
  },
  methodLeft: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  methodName: {
    fontSize: 16,
    color: '#333',
    marginLeft: 12,
  },
  methodNameSelected: {
    color: '#007AFF',
    fontWeight: '500',
  },
  radio: {
    width: 20,
    height: 20,
    borderRadius: 10,
    borderWidth: 2,
    borderColor: '#ccc',
    justifyContent: 'center',
    alignItems: 'center',
  },
  radioSelected: {
    borderColor: '#007AFF',
  },
  radioInner: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: '#007AFF',
  },
  terms: {
    paddingHorizontal: 20,
    marginBottom: 16,
  },
  termsText: {
    fontSize: 12,
    color: '#666',
    lineHeight: 18,
  },
  termsLink: {
    color: '#007AFF',
    textDecorationLine: 'underline',
  },
  securityInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 12,
    backgroundColor: '#E8F5E9',
    marginHorizontal: 20,
    marginBottom: 20,
    borderRadius: 8,
  },
  securityText: {
    fontSize: 12,
    color: '#2E7D32',
    marginLeft: 8,
  },
  bottomContainer: {
    backgroundColor: '#fff',
    paddingHorizontal: 20,
    paddingTop: 16,
    paddingBottom: 20,
    borderTopWidth: 1,
    borderTopColor: '#e0e0e0',
  },
  totalSummary: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  totalSummaryLabel: {
    fontSize: 14,
    color: '#666',
  },
  totalSummaryValue: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#333',
  },
  payButton: {
    backgroundColor: '#007AFF',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 16,
    borderRadius: 12,
  },
  payButtonDisabled: {
    opacity: 0.6,
  },
  payButtonText: {
    fontSize: 18,
    fontWeight: '600',
    color: '#fff',
    marginLeft: 8,
  },
});