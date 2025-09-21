import React, { useState, useEffect, useRef } from 'react';
import {
  StyleSheet,
  Text,
  View,
  FlatList,
  TextInput,
  TouchableOpacity,
  KeyboardAvoidingView,
  Platform,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../contexts/AuthContext';
import chatService, { Message } from '../../services/chatService';

export default function ChatScreen({ route, navigation }: any) {
  const { taskId, taskTitle } = route.params;
  const { user } = useAuth();
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputText, setInputText] = useState('');
  const [loading, setLoading] = useState(true);
  const [connected, setConnected] = useState(false);
  const [roomId, setRoomId] = useState<string | null>(null);
  const [isTyping, setIsTyping] = useState<{ [userId: string]: boolean }>({});
  const flatListRef = useRef<FlatList>(null);
  const typingTimeoutRef = useRef<NodeJS.Timeout>();

  useEffect(() => {
    connectToChat();

    return () => {
      chatService.disconnect();
    };
  }, [taskId]);

  useEffect(() => {
    const unsubscribes = [
      chatService.on('connected', handleConnectionChange),
      chatService.on('room_joined', handleRoomJoined),
      chatService.on('new_message', handleNewMessage),
      chatService.on('user_typing', handleUserTyping),
      chatService.on('error', handleError),
    ];

    return () => {
      unsubscribes.forEach((unsubscribe) => unsubscribe());
    };
  }, []);

  const connectToChat = async () => {
    try {
      await chatService.connect();
      chatService.joinRoom(taskId);
    } catch (error) {
      console.error('Failed to connect to chat:', error);
      Alert.alert('오류', '채팅 연결에 실패했습니다.');
      setLoading(false);
    }
  };

  const handleConnectionChange = (isConnected: boolean) => {
    setConnected(isConnected);
    if (!isConnected && roomId) {
      // Try to reconnect
      setTimeout(() => {
        connectToChat();
      }, 2000);
    }
  };

  const handleRoomJoined = (data: { roomId: string; messages: Message[] }) => {
    setRoomId(data.roomId);
    setMessages(data.messages);
    setLoading(false);
    scrollToBottom();
  };

  const handleNewMessage = (message: Message) => {
    setMessages((prev) => [...prev, message]);
    scrollToBottom();

    // Mark message as read if it's not from current user
    if (message.senderId !== user?.id) {
      chatService.markMessageAsRead(message.id);
    }
  };

  const handleUserTyping = (data: { userId: string; isTyping: boolean }) => {
    setIsTyping((prev) => ({
      ...prev,
      [data.userId]: data.isTyping,
    }));
  };

  const handleError = (error: any) => {
    console.error('Chat error:', error);
    Alert.alert('오류', error.message || '채팅 오류가 발생했습니다.');
  };

  const sendMessage = () => {
    if (!inputText.trim() || !roomId) return;

    chatService.sendMessage(roomId, inputText.trim());
    setInputText('');
  };

  const handleTyping = (text: string) => {
    setInputText(text);

    if (!roomId) return;

    // Clear previous timeout
    if (typingTimeoutRef.current) {
      clearTimeout(typingTimeoutRef.current);
    }

    // Send typing indicator
    if (text) {
      chatService.sendTypingIndicator(roomId, true);

      // Stop typing after 2 seconds
      typingTimeoutRef.current = setTimeout(() => {
        chatService.sendTypingIndicator(roomId, false);
      }, 2000);
    } else {
      chatService.sendTypingIndicator(roomId, false);
    }
  };

  const scrollToBottom = () => {
    setTimeout(() => {
      flatListRef.current?.scrollToEnd({ animated: true });
    }, 100);
  };

  const formatTime = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleTimeString('ko-KR', {
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const renderMessage = ({ item }: { item: Message }) => {
    const isMyMessage = item.senderId === user?.id;

    return (
      <View
        style={[
          styles.messageContainer,
          isMyMessage ? styles.myMessageContainer : styles.otherMessageContainer,
        ]}
      >
        {!isMyMessage && (
          <View style={styles.senderInfo}>
            <View style={styles.senderAvatar}>
              <Text style={styles.senderInitial}>
                {item.sender.name.charAt(0)}
              </Text>
            </View>
            <Text style={styles.senderName}>{item.sender.name}</Text>
          </View>
        )}
        <View
          style={[
            styles.messageBubble,
            isMyMessage ? styles.myMessageBubble : styles.otherMessageBubble,
          ]}
        >
          <Text
            style={[
              styles.messageText,
              isMyMessage ? styles.myMessageText : styles.otherMessageText,
            ]}
          >
            {item.content}
          </Text>
          <Text
            style={[
              styles.messageTime,
              isMyMessage ? styles.myMessageTime : styles.otherMessageTime,
            ]}
          >
            {formatTime(item.createdAt)}
          </Text>
        </View>
      </View>
    );
  };

  const renderTypingIndicator = () => {
    const typingUsers = Object.entries(isTyping)
      .filter(([userId, typing]) => typing && userId !== user?.id)
      .map(([userId]) => userId);

    if (typingUsers.length === 0) return null;

    return (
      <View style={styles.typingContainer}>
        <View style={styles.typingBubble}>
          <ActivityIndicator size="small" color="#666" />
          <Text style={styles.typingText}>입력 중...</Text>
        </View>
      </View>
    );
  };

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#007AFF" />
          <Text style={styles.loadingText}>채팅 연결 중...</Text>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()}>
          <Ionicons name="arrow-back" size={24} color="#333" />
        </TouchableOpacity>
        <View style={styles.headerTitle}>
          <Text style={styles.taskTitle} numberOfLines={1}>
            {taskTitle}
          </Text>
          <View style={styles.connectionStatus}>
            <View
              style={[
                styles.statusDot,
                { backgroundColor: connected ? '#4CAF50' : '#FF5252' },
              ]}
            />
            <Text style={styles.statusText}>
              {connected ? '연결됨' : '연결 중...'}
            </Text>
          </View>
        </View>
        <TouchableOpacity style={styles.menuButton}>
          <Ionicons name="ellipsis-vertical" size={24} color="#333" />
        </TouchableOpacity>
      </View>

      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.chatContainer}
        keyboardVerticalOffset={90}
      >
        <FlatList
          ref={flatListRef}
          data={messages}
          renderItem={renderMessage}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.messagesList}
          onContentSizeChange={scrollToBottom}
          ListEmptyComponent={
            <View style={styles.emptyContainer}>
              <Text style={styles.emptyText}>대화를 시작해보세요!</Text>
            </View>
          }
          ListFooterComponent={renderTypingIndicator}
        />

        <View style={styles.inputContainer}>
          <TextInput
            style={styles.textInput}
            placeholder="메시지 입력..."
            placeholderTextColor="#999"
            value={inputText}
            onChangeText={handleTyping}
            multiline
            maxLength={500}
          />
          <TouchableOpacity
            style={[
              styles.sendButton,
              !inputText.trim() && styles.sendButtonDisabled,
            ]}
            onPress={sendMessage}
            disabled={!inputText.trim() || !connected}
          >
            <Ionicons
              name="send"
              size={20}
              color={inputText.trim() ? '#007AFF' : '#ccc'}
            />
          </TouchableOpacity>
        </View>
      </KeyboardAvoidingView>
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
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  backButton: {
    padding: 4,
    marginRight: 12,
  },
  headerTitle: {
    flex: 1,
  },
  taskTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginBottom: 2,
  },
  connectionStatus: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  statusDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    marginRight: 6,
  },
  statusText: {
    fontSize: 12,
    color: '#666',
  },
  menuButton: {
    padding: 4,
    marginLeft: 12,
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
  chatContainer: {
    flex: 1,
  },
  messagesList: {
    paddingHorizontal: 16,
    paddingVertical: 16,
    flexGrow: 1,
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingTop: 100,
  },
  emptyText: {
    fontSize: 16,
    color: '#999',
  },
  messageContainer: {
    marginBottom: 12,
  },
  myMessageContainer: {
    alignItems: 'flex-end',
  },
  otherMessageContainer: {
    alignItems: 'flex-start',
  },
  senderInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 4,
  },
  senderAvatar: {
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: '#007AFF',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 8,
  },
  senderInitial: {
    color: '#fff',
    fontSize: 12,
    fontWeight: 'bold',
  },
  senderName: {
    fontSize: 12,
    color: '#666',
  },
  messageBubble: {
    maxWidth: '80%',
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 16,
  },
  myMessageBubble: {
    backgroundColor: '#007AFF',
    borderBottomRightRadius: 4,
  },
  otherMessageBubble: {
    backgroundColor: '#fff',
    borderBottomLeftRadius: 4,
  },
  messageText: {
    fontSize: 15,
    lineHeight: 20,
  },
  myMessageText: {
    color: '#fff',
  },
  otherMessageText: {
    color: '#333',
  },
  messageTime: {
    fontSize: 11,
    marginTop: 4,
  },
  myMessageTime: {
    color: 'rgba(255, 255, 255, 0.7)',
  },
  otherMessageTime: {
    color: '#999',
  },
  typingContainer: {
    paddingHorizontal: 16,
    paddingVertical: 8,
  },
  typingBubble: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#fff',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 16,
    alignSelf: 'flex-start',
  },
  typingText: {
    fontSize: 12,
    color: '#666',
    marginLeft: 8,
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: '#fff',
    borderTopWidth: 1,
    borderTopColor: '#e0e0e0',
  },
  textInput: {
    flex: 1,
    backgroundColor: '#f5f5f5',
    borderRadius: 20,
    paddingHorizontal: 16,
    paddingVertical: 8,
    marginRight: 12,
    maxHeight: 100,
    fontSize: 15,
    color: '#333',
  },
  sendButton: {
    width: 36,
    height: 36,
    borderRadius: 18,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#fff',
  },
  sendButtonDisabled: {
    opacity: 0.5,
  },
});