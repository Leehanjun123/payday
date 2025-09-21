import { io, Socket } from 'socket.io-client';
import AsyncStorage from '@react-native-async-storage/async-storage';

export interface Message {
  id: string;
  content: string;
  roomId: string;
  senderId: string;
  sender: {
    id: string;
    name: string;
    profileImage?: string;
  };
  readBy: any[];
  createdAt: string;
}

export interface ChatRoom {
  id: string;
  taskId: string;
  messages: Message[];
}

class ChatService {
  private socket: Socket | null = null;
  private listeners: Map<string, Function[]> = new Map();

  async connect() {
    if (this.socket?.connected) {
      return;
    }

    const token = await AsyncStorage.getItem('authToken');
    if (!token) {
      throw new Error('No auth token found');
    }

    this.socket = io('http://localhost:3000', {
      auth: {
        token,
      },
      reconnection: true,
      reconnectionAttempts: 5,
      reconnectionDelay: 1000,
    });

    this.setupEventListeners();
  }

  private setupEventListeners() {
    if (!this.socket) return;

    this.socket.on('connect', () => {
      console.log('Socket connected');
      this.emit('connected', true);
    });

    this.socket.on('disconnect', () => {
      console.log('Socket disconnected');
      this.emit('connected', false);
    });

    this.socket.on('error', (error) => {
      console.error('Socket error:', error);
      this.emit('error', error);
    });

    this.socket.on('room_joined', (data: { roomId: string; messages: Message[] }) => {
      this.emit('room_joined', data);
    });

    this.socket.on('new_message', (message: Message) => {
      this.emit('new_message', message);
    });

    this.socket.on('user_typing', (data: { userId: string; isTyping: boolean }) => {
      this.emit('user_typing', data);
    });

    this.socket.on('message_read', (data: { messageId: string; userId: string }) => {
      this.emit('message_read', data);
    });
  }

  joinRoom(taskId: string) {
    if (!this.socket?.connected) {
      throw new Error('Socket not connected');
    }

    this.socket.emit('join_room', { taskId });
  }

  sendMessage(roomId: string, content: string) {
    if (!this.socket?.connected) {
      throw new Error('Socket not connected');
    }

    this.socket.emit('send_message', { roomId, content });
  }

  sendTypingIndicator(roomId: string, isTyping: boolean) {
    if (!this.socket?.connected) {
      return;
    }

    this.socket.emit('typing', { roomId, isTyping });
  }

  markMessageAsRead(messageId: string) {
    if (!this.socket?.connected) {
      return;
    }

    this.socket.emit('mark_read', { messageId });
  }

  on(event: string, callback: Function) {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, []);
    }
    this.listeners.get(event)?.push(callback);

    // Return unsubscribe function
    return () => {
      const callbacks = this.listeners.get(event);
      if (callbacks) {
        const index = callbacks.indexOf(callback);
        if (index > -1) {
          callbacks.splice(index, 1);
        }
      }
    };
  }

  private emit(event: string, data: any) {
    const callbacks = this.listeners.get(event);
    if (callbacks) {
      callbacks.forEach((callback) => callback(data));
    }
  }

  disconnect() {
    if (this.socket) {
      this.socket.disconnect();
      this.socket = null;
    }
    this.listeners.clear();
  }

  isConnected(): boolean {
    return this.socket?.connected ?? false;
  }
}

export default new ChatService();