import apiClient from './apiClient';

export interface Payment {
  id: string;
  taskId: string;
  amount: number;
  fee: number;
  netAmount: number;
  status: 'PENDING' | 'PROCESSING' | 'COMPLETED' | 'FAILED' | 'REFUNDED';
  method?: string;
  transactionId?: string;
  paidAt?: string;
  createdAt: string;
  task?: {
    id: string;
    title: string;
    poster?: {
      id: string;
      name: string;
    };
    assignee?: {
      id: string;
      name: string;
    };
  };
  earning?: {
    id: string;
    amount: number;
    status: string;
  };
}

export interface PaymentHistoryResponse {
  payments: Payment[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    pages: number;
  };
}

export interface PaymentInitResponse {
  message: string;
  payment: Payment;
}

export interface PaymentProcessData {
  paymentMethod: 'CARD' | 'BANK' | 'KAKAO_PAY' | 'TOSS';
  paymentData?: {
    cardNumber?: string;
    cardExpiry?: string;
    cardCVV?: string;
    holderName?: string;
  };
}

class PaymentService {
  async initializePayment(taskId: string): Promise<PaymentInitResponse> {
    return apiClient.post('/api/v1/payments/initialize', { taskId });
  }

  async processPayment(
    paymentId: string,
    paymentData: PaymentProcessData
  ): Promise<{ message: string; payment: Payment }> {
    return apiClient.post(`/api/v1/payments/process/${paymentId}`, paymentData);
  }

  async getPayment(paymentId: string): Promise<Payment> {
    return apiClient.get(`/api/v1/payments/${paymentId}`);
  }

  async requestRefund(
    paymentId: string,
    reason: string
  ): Promise<{ message: string; payment: Payment }> {
    return apiClient.post(`/api/v1/payments/${paymentId}/refund`, { reason });
  }

  async getPaymentHistory(
    type: 'all' | 'sent' | 'received' = 'all',
    page = 1,
    limit = 20
  ): Promise<PaymentHistoryResponse> {
    const params = new URLSearchParams({
      type,
      page: String(page),
      limit: String(limit),
    });

    return apiClient.get(`/api/v1/payments/history/user?${params.toString()}`);
  }

  formatAmount(amount: number): string {
    return `₩${amount.toLocaleString('ko-KR')}`;
  }

  calculatePlatformFee(amount: number): number {
    return Math.floor(amount * 0.1); // 10% platform fee
  }

  calculateNetAmount(amount: number): number {
    return amount - this.calculatePlatformFee(amount);
  }

  getPaymentMethodName(method: string): string {
    switch (method) {
      case 'CARD':
        return '신용/체크카드';
      case 'BANK':
        return '계좌이체';
      case 'KAKAO_PAY':
        return '카카오페이';
      case 'TOSS':
        return '토스';
      default:
        return method;
    }
  }

  getPaymentStatusText(status: string): string {
    switch (status) {
      case 'PENDING':
        return '결제 대기';
      case 'PROCESSING':
        return '처리 중';
      case 'COMPLETED':
        return '결제 완료';
      case 'FAILED':
        return '결제 실패';
      case 'REFUNDED':
        return '환불됨';
      default:
        return status;
    }
  }

  getPaymentStatusColor(status: string): string {
    switch (status) {
      case 'PENDING':
        return '#FF9800';
      case 'PROCESSING':
        return '#2196F3';
      case 'COMPLETED':
        return '#4CAF50';
      case 'FAILED':
        return '#F44336';
      case 'REFUNDED':
        return '#9C27B0';
      default:
        return '#666';
    }
  }
}

export default new PaymentService();