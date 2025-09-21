import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';
import Constants from 'expo-constants';
import { Platform } from 'react-native';
import apiClient from './apiClient';

// Configure notification handler
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: true,
  }),
});

export interface NotificationData {
  title: string;
  body: string;
  data?: any;
}

class NotificationService {
  private expoPushToken: string | null = null;
  private notificationListener: any = null;
  private responseListener: any = null;

  async initialize() {
    try {
      // Register for push notifications
      const token = await this.registerForPushNotifications();
      if (token) {
        this.expoPushToken = token;
        // Send token to backend
        await this.updatePushToken(token);
      }

      // Set up notification listeners
      this.setupNotificationListeners();
    } catch (error) {
      console.log('Push notifications initialization skipped:', error);
      // Continue without push notifications - they're optional
      this.setupNotificationListeners();
    }
  }

  private async registerForPushNotifications(): Promise<string | null> {
    if (!Device.isDevice) {
      console.log('Push notifications only work on physical devices');
      return null;
    }

    try {
      // Get existing permissions
      const { status: existingStatus } = await Notifications.getPermissionsAsync();
      let finalStatus = existingStatus;

      // Request permissions if not granted
      if (existingStatus !== 'granted') {
        const { status } = await Notifications.requestPermissionsAsync();
        finalStatus = status;
      }

      if (finalStatus !== 'granted') {
        console.log('Failed to get push token for push notification');
        return null;
      }

      // Get Expo push token - Skip projectId for local testing
      const tokenData = await Notifications.getExpoPushTokenAsync();

      // Configure Android channel
      if (Platform.OS === 'android') {
        await Notifications.setNotificationChannelAsync('default', {
          name: 'default',
          importance: Notifications.AndroidImportance.MAX,
          vibrationPattern: [0, 250, 250, 250],
          lightColor: '#FF231F7C',
        });
      }

      return tokenData.data;
    } catch (error) {
      console.error('Error registering for push notifications:', error);
      return null;
    }
  }

  private setupNotificationListeners() {
    // Handle notifications received while app is foregrounded
    this.notificationListener = Notifications.addNotificationReceivedListener(
      (notification) => {
        console.log('Notification received:', notification);
      }
    );

    // Handle user tapping on notification
    this.responseListener = Notifications.addNotificationResponseReceivedListener(
      (response) => {
        console.log('Notification response:', response);
        this.handleNotificationResponse(response);
      }
    );
  }

  private handleNotificationResponse(response: Notifications.NotificationResponse) {
    const { data } = response.notification.request.content;

    // Navigate based on notification type
    if (data?.type === 'task_application') {
      // Navigate to task detail
      // navigationRef.current?.navigate('TaskDetail', { taskId: data.taskId });
    } else if (data?.type === 'task_accepted') {
      // Navigate to my tasks
      // navigationRef.current?.navigate('MyTasks');
    } else if (data?.type === 'payment_received') {
      // Navigate to earnings
      // navigationRef.current?.navigate('Earnings');
    }
  }

  async updatePushToken(token: string) {
    try {
      await apiClient.post('/api/v1/users/push-token', { token });
    } catch (error) {
      console.error('Error updating push token:', error);
    }
  }

  async scheduleLocalNotification(data: NotificationData, delay: number = 0) {
    await Notifications.scheduleNotificationAsync({
      content: {
        title: data.title,
        body: data.body,
        data: data.data,
        sound: true,
      },
      trigger: delay > 0 ? { seconds: delay } : null,
    });
  }

  async cancelAllNotifications() {
    await Notifications.cancelAllScheduledNotificationsAsync();
  }

  async getBadgeCount(): Promise<number> {
    return Notifications.getBadgeCountAsync();
  }

  async setBadgeCount(count: number) {
    await Notifications.setBadgeCountAsync(count);
  }

  cleanup() {
    if (this.notificationListener) {
      Notifications.removeNotificationSubscription(this.notificationListener);
    }
    if (this.responseListener) {
      Notifications.removeNotificationSubscription(this.responseListener);
    }
  }
}

export default new NotificationService();