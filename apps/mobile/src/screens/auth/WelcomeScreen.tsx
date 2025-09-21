import React from 'react';
import {
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  Image,
  SafeAreaView,
} from 'react-native';

import { AuthStackScreenProps } from '../../navigation/types';

export default function WelcomeScreen({
  navigation,
}: AuthStackScreenProps<'Welcome'>) {
  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.content}>
        <View style={styles.logoContainer}>
          <Text style={styles.logo}>💰</Text>
          <Text style={styles.title}>PayDay</Text>
          <Text style={styles.subtitle}>당신의 시간을 돈으로</Text>
        </View>

        <View style={styles.features}>
          <View style={styles.featureItem}>
            <Text style={styles.featureIcon}>🎯</Text>
            <Text style={styles.featureText}>다양한 부수입 기회</Text>
          </View>
          <View style={styles.featureItem}>
            <Text style={styles.featureIcon}>💳</Text>
            <Text style={styles.featureText}>안전한 결제 시스템</Text>
          </View>
          <View style={styles.featureItem}>
            <Text style={styles.featureIcon}>🚀</Text>
            <Text style={styles.featureText}>성장하는 수익 구조</Text>
          </View>
        </View>

        <View style={styles.buttonContainer}>
          <TouchableOpacity
            style={styles.primaryButton}
            onPress={() => navigation.navigate('SignUp')}
          >
            <Text style={styles.primaryButtonText}>시작하기</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.secondaryButton}
            onPress={() => navigation.navigate('Login')}
          >
            <Text style={styles.secondaryButtonText}>
              이미 계정이 있으신가요? 로그인
            </Text>
          </TouchableOpacity>
        </View>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  content: {
    flex: 1,
    paddingHorizontal: 20,
    justifyContent: 'space-between',
    paddingVertical: 40,
  },
  logoContainer: {
    alignItems: 'center',
    marginTop: 60,
  },
  logo: {
    fontSize: 80,
    marginBottom: 20,
  },
  title: {
    fontSize: 40,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 10,
  },
  subtitle: {
    fontSize: 18,
    color: '#666',
  },
  features: {
    marginVertical: 40,
  },
  featureItem: {
    flexDirection: 'row',
    alignItems: 'center',
    marginVertical: 15,
    paddingHorizontal: 20,
  },
  featureIcon: {
    fontSize: 30,
    marginRight: 20,
  },
  featureText: {
    fontSize: 16,
    color: '#333',
  },
  buttonContainer: {
    marginBottom: 20,
  },
  primaryButton: {
    backgroundColor: '#007AFF',
    paddingVertical: 16,
    borderRadius: 12,
    alignItems: 'center',
    marginBottom: 15,
  },
  primaryButtonText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: '600',
  },
  secondaryButton: {
    alignItems: 'center',
    paddingVertical: 10,
  },
  secondaryButtonText: {
    color: '#007AFF',
    fontSize: 16,
  },
});