import React, { useState } from 'react';
import {
  StyleSheet,
  Text,
  View,
  ScrollView,
  TouchableOpacity,
  Image,
  Alert,
  Switch,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../contexts/AuthContext';

export default function ProfileScreen({ navigation }: any) {
  const { user, logout } = useAuth();
  const [notifications, setNotifications] = useState(true);
  const [darkMode, setDarkMode] = useState(false);

  const handleLogout = () => {
    Alert.alert(
      '로그아웃',
      '정말 로그아웃 하시겠습니까?',
      [
        { text: '취소', style: 'cancel' },
        {
          text: '로그아웃',
          style: 'destructive',
          onPress: logout,
        },
      ],
      { cancelable: true }
    );
  };

  const menuItems = [
    {
      title: '계정 관리',
      items: [
        {
          icon: 'person-outline',
          label: '프로필 수정',
          onPress: () => navigation.navigate('EditProfile'),
        },
        {
          icon: 'school-outline',
          label: '스킬 관리',
          onPress: () => navigation.navigate('ManageSkills'),
          badge: '12',
        },
        {
          icon: 'shield-checkmark-outline',
          label: '계정 인증',
          onPress: () => navigation.navigate('Verification'),
          rightIcon: 'checkmark-circle',
          rightIconColor: '#4CAF50',
        },
      ],
    },
    {
      title: '수익 관리',
      items: [
        {
          icon: 'card-outline',
          label: '결제 수단',
          onPress: () => navigation.navigate('PaymentMethods'),
        },
        {
          icon: 'receipt-outline',
          label: '세금 정보',
          onPress: () => navigation.navigate('TaxInfo'),
        },
        {
          icon: 'analytics-outline',
          label: '수익 분석',
          onPress: () => navigation.navigate('EarningsAnalytics'),
        },
      ],
    },
    {
      title: '설정',
      items: [
        {
          icon: 'notifications-outline',
          label: '알림 설정',
          toggle: true,
          value: notifications,
          onToggle: setNotifications,
        },
        {
          icon: 'moon-outline',
          label: '다크 모드',
          toggle: true,
          value: darkMode,
          onToggle: setDarkMode,
        },
        {
          icon: 'language-outline',
          label: '언어 설정',
          onPress: () => navigation.navigate('Language'),
          value: '한국어',
        },
      ],
    },
    {
      title: '지원',
      items: [
        {
          icon: 'help-circle-outline',
          label: '도움말 센터',
          onPress: () => navigation.navigate('Help'),
        },
        {
          icon: 'document-text-outline',
          label: '이용약관',
          onPress: () => navigation.navigate('Terms'),
        },
        {
          icon: 'lock-closed-outline',
          label: '개인정보처리방침',
          onPress: () => navigation.navigate('Privacy'),
        },
        {
          icon: 'chatbubbles-outline',
          label: '고객 지원',
          onPress: () => navigation.navigate('Support'),
        },
      ],
    },
  ];

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        <View style={styles.header}>
          <Text style={styles.headerTitle}>프로필</Text>
          <TouchableOpacity style={styles.settingsButton}>
            <Ionicons name="settings-outline" size={24} color="#333" />
          </TouchableOpacity>
        </View>

        <View style={styles.profileSection}>
          <View style={styles.profileHeader}>
            <View style={styles.avatarContainer}>
              {user?.profileImage ? (
                <Image source={{ uri: user.profileImage }} style={styles.avatar} />
              ) : (
                <View style={styles.avatarPlaceholder}>
                  <Text style={styles.avatarInitial}>
                    {user?.name?.charAt(0) || 'U'}
                  </Text>
                </View>
              )}
              <TouchableOpacity style={styles.avatarEditButton}>
                <Ionicons name="camera" size={16} color="#fff" />
              </TouchableOpacity>
            </View>

            <View style={styles.profileInfo}>
              <Text style={styles.userName}>{user?.name || '사용자'}</Text>
              <Text style={styles.userEmail}>{user?.email || ''}</Text>
              <View style={styles.levelBadge}>
                <Ionicons name="star" size={14} color="#FFD700" />
                <Text style={styles.levelText}>Level {user?.level || 1}</Text>
              </View>
            </View>
          </View>

          <View style={styles.statsContainer}>
            <View style={styles.statItem}>
              <Text style={styles.statValue}>24</Text>
              <Text style={styles.statLabel}>완료 작업</Text>
            </View>
            <View style={styles.statDivider} />
            <View style={styles.statItem}>
              <Text style={styles.statValue}>4.8</Text>
              <Text style={styles.statLabel}>평점</Text>
            </View>
            <View style={styles.statDivider} />
            <View style={styles.statItem}>
              <Text style={styles.statValue}>98%</Text>
              <Text style={styles.statLabel}>응답률</Text>
            </View>
          </View>

          <TouchableOpacity style={styles.viewProfileButton}>
            <Text style={styles.viewProfileText}>공개 프로필 보기</Text>
            <Ionicons name="arrow-forward" size={18} color="#007AFF" />
          </TouchableOpacity>
        </View>

        {menuItems.map((section, sectionIndex) => (
          <View key={sectionIndex} style={styles.menuSection}>
            <Text style={styles.menuSectionTitle}>{section.title}</Text>
            <View style={styles.menuItems}>
              {section.items.map((item, itemIndex) => (
                <TouchableOpacity
                  key={itemIndex}
                  style={[
                    styles.menuItem,
                    itemIndex === section.items.length - 1 && styles.lastMenuItem,
                  ]}
                  onPress={item.onPress}
                  disabled={item.toggle}
                >
                  <View style={styles.menuItemLeft}>
                    <View style={styles.menuIconContainer}>
                      <Ionicons
                        name={item.icon as any}
                        size={22}
                        color="#666"
                      />
                    </View>
                    <Text style={styles.menuItemLabel}>{item.label}</Text>
                    {item.badge && (
                      <View style={styles.badge}>
                        <Text style={styles.badgeText}>{item.badge}</Text>
                      </View>
                    )}
                  </View>
                  <View style={styles.menuItemRight}>
                    {item.toggle ? (
                      <Switch
                        value={item.value}
                        onValueChange={item.onToggle}
                        trackColor={{ false: '#ddd', true: '#007AFF' }}
                        thumbColor="#fff"
                      />
                    ) : (
                      <>
                        {item.value && (
                          <Text style={styles.menuItemValue}>{item.value}</Text>
                        )}
                        {item.rightIcon ? (
                          <Ionicons
                            name={item.rightIcon as any}
                            size={20}
                            color={item.rightIconColor || '#999'}
                          />
                        ) : (
                          <Ionicons
                            name="chevron-forward"
                            size={20}
                            color="#999"
                          />
                        )}
                      </>
                    )}
                  </View>
                </TouchableOpacity>
              ))}
            </View>
          </View>
        ))}

        <TouchableOpacity style={styles.logoutButton} onPress={handleLogout}>
          <Ionicons name="log-out-outline" size={20} color="#FF3B30" />
          <Text style={styles.logoutText}>로그아웃</Text>
        </TouchableOpacity>

        <View style={styles.versionInfo}>
          <Text style={styles.versionText}>PayDay v1.0.0</Text>
          <Text style={styles.copyrightText}>© 2024 PayDay. All rights reserved.</Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  content: {
    flex: 1,
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
  settingsButton: {
    padding: 4,
  },
  profileSection: {
    backgroundColor: '#fff',
    marginTop: 1,
    paddingVertical: 20,
  },
  profileHeader: {
    flexDirection: 'row',
    paddingHorizontal: 20,
    marginBottom: 20,
  },
  avatarContainer: {
    position: 'relative',
    marginRight: 16,
  },
  avatar: {
    width: 80,
    height: 80,
    borderRadius: 40,
  },
  avatarPlaceholder: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: '#007AFF',
    justifyContent: 'center',
    alignItems: 'center',
  },
  avatarInitial: {
    fontSize: 32,
    color: '#fff',
    fontWeight: 'bold',
  },
  avatarEditButton: {
    position: 'absolute',
    bottom: 0,
    right: 0,
    backgroundColor: '#007AFF',
    width: 28,
    height: 28,
    borderRadius: 14,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#fff',
  },
  profileInfo: {
    flex: 1,
    justifyContent: 'center',
  },
  userName: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 4,
  },
  userEmail: {
    fontSize: 14,
    color: '#666',
    marginBottom: 8,
  },
  levelBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFF8E1',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 12,
    alignSelf: 'flex-start',
  },
  levelText: {
    fontSize: 12,
    color: '#F57C00',
    fontWeight: '600',
    marginLeft: 4,
  },
  statsContainer: {
    flexDirection: 'row',
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderTopWidth: 1,
    borderBottomWidth: 1,
    borderColor: '#f0f0f0',
  },
  statItem: {
    flex: 1,
    alignItems: 'center',
  },
  statValue: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 4,
  },
  statLabel: {
    fontSize: 12,
    color: '#999',
  },
  statDivider: {
    width: 1,
    height: 30,
    backgroundColor: '#e0e0e0',
  },
  viewProfileButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 12,
    marginHorizontal: 20,
    marginTop: 12,
  },
  viewProfileText: {
    fontSize: 14,
    color: '#007AFF',
    fontWeight: '600',
    marginRight: 4,
  },
  menuSection: {
    marginTop: 20,
  },
  menuSectionTitle: {
    fontSize: 13,
    color: '#999',
    fontWeight: '600',
    textTransform: 'uppercase',
    paddingHorizontal: 20,
    paddingVertical: 8,
  },
  menuItems: {
    backgroundColor: '#fff',
    borderTopWidth: 1,
    borderBottomWidth: 1,
    borderColor: '#e0e0e0',
  },
  menuItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    paddingVertical: 14,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  lastMenuItem: {
    borderBottomWidth: 0,
  },
  menuItemLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  menuIconContainer: {
    width: 32,
    marginRight: 12,
  },
  menuItemLabel: {
    fontSize: 16,
    color: '#333',
    flex: 1,
  },
  badge: {
    backgroundColor: '#FF3B30',
    borderRadius: 10,
    paddingHorizontal: 6,
    paddingVertical: 2,
    marginLeft: 8,
  },
  badgeText: {
    color: '#fff',
    fontSize: 11,
    fontWeight: 'bold',
  },
  menuItemRight: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  menuItemValue: {
    fontSize: 14,
    color: '#999',
    marginRight: 8,
  },
  logoutButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#fff',
    marginTop: 20,
    marginHorizontal: 20,
    paddingVertical: 14,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#FF3B30',
  },
  logoutText: {
    fontSize: 16,
    color: '#FF3B30',
    fontWeight: '600',
    marginLeft: 8,
  },
  versionInfo: {
    alignItems: 'center',
    paddingVertical: 24,
    marginTop: 20,
  },
  versionText: {
    fontSize: 12,
    color: '#999',
    marginBottom: 4,
  },
  copyrightText: {
    fontSize: 11,
    color: '#ccc',
  },
});