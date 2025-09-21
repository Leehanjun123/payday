import React, { useState } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TextInput,
  TouchableOpacity,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { AuthStackScreenProps } from '../../navigation/types';
import { useAuth } from '../../contexts/AuthContext';

export default function SignUpScreen({ navigation }: AuthStackScreenProps<'SignUp'>) {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const { register } = useAuth();

  const validateForm = () => {
    if (!name || !email || !password || !confirmPassword) {
      Alert.alert('오류', '모든 필드를 입력해주세요.');
      return false;
    }

    if (!email.includes('@')) {
      Alert.alert('오류', '올바른 이메일 형식이 아닙니다.');
      return false;
    }

    if (password.length < 8) {
      Alert.alert('오류', '비밀번호는 최소 8자 이상이어야 합니다.');
      return false;
    }

    if (password !== confirmPassword) {
      Alert.alert('오류', '비밀번호가 일치하지 않습니다.');
      return false;
    }

    // Check password requirements
    const hasUpperCase = /[A-Z]/.test(password);
    const hasLowerCase = /[a-z]/.test(password);
    const hasNumber = /[0-9]/.test(password);

    if (!hasUpperCase || !hasLowerCase || !hasNumber) {
      Alert.alert(
        '오류',
        '비밀번호는 대문자, 소문자, 숫자를 각각 하나 이상 포함해야 합니다.'
      );
      return false;
    }

    return true;
  };

  const handleSignUp = async () => {
    if (!validateForm()) return;

    setLoading(true);
    try {
      await register(email, password, name);
      // Navigation will be handled by auth state change
    } catch (error: any) {
      Alert.alert(
        '회원가입 실패',
        error.message || '회원가입 중 오류가 발생했습니다.'
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.keyboardView}
      >
        <ScrollView
          contentContainerStyle={styles.scrollContent}
          keyboardShouldPersistTaps="handled"
        >
          <View style={styles.header}>
            <Text style={styles.logo}>💰</Text>
            <Text style={styles.title}>PayDay 시작하기</Text>
            <Text style={styles.subtitle}>부수입의 새로운 시작</Text>
          </View>

          <View style={styles.form}>
            <View style={styles.inputContainer}>
              <Text style={styles.label}>이름</Text>
              <TextInput
                style={styles.input}
                placeholder="홍길동"
                placeholderTextColor="#999"
                value={name}
                onChangeText={setName}
                autoCorrect={false}
                editable={!loading}
              />
            </View>

            <View style={styles.inputContainer}>
              <Text style={styles.label}>이메일</Text>
              <TextInput
                style={styles.input}
                placeholder="email@example.com"
                placeholderTextColor="#999"
                value={email}
                onChangeText={setEmail}
                autoCapitalize="none"
                keyboardType="email-address"
                autoCorrect={false}
                editable={!loading}
              />
            </View>

            <View style={styles.inputContainer}>
              <Text style={styles.label}>비밀번호</Text>
              <TextInput
                style={styles.input}
                placeholder="최소 8자, 대소문자 및 숫자 포함"
                placeholderTextColor="#999"
                value={password}
                onChangeText={setPassword}
                secureTextEntry
                autoCapitalize="none"
                autoCorrect={false}
                editable={!loading}
              />
            </View>

            <View style={styles.inputContainer}>
              <Text style={styles.label}>비밀번호 확인</Text>
              <TextInput
                style={styles.input}
                placeholder="비밀번호 재입력"
                placeholderTextColor="#999"
                value={confirmPassword}
                onChangeText={setConfirmPassword}
                secureTextEntry
                autoCapitalize="none"
                autoCorrect={false}
                editable={!loading}
              />
            </View>

            <View style={styles.terms}>
              <Text style={styles.termsText}>
                회원가입을 진행하면{' '}
                <Text
                  style={styles.termsLink}
                  onPress={() => Alert.alert('준비중', '이용약관 페이지는 준비중입니다.')}
                >
                  이용약관
                </Text>
                {' 및 '}
                <Text
                  style={styles.termsLink}
                  onPress={() => Alert.alert('준비중', '개인정보처리방침 페이지는 준비중입니다.')}
                >
                  개인정보처리방침
                </Text>
                에 동의하는 것으로 간주됩니다.
              </Text>
            </View>

            <TouchableOpacity
              style={[styles.signUpButton, loading && styles.disabledButton]}
              onPress={handleSignUp}
              disabled={loading}
            >
              {loading ? (
                <ActivityIndicator color="#fff" />
              ) : (
                <Text style={styles.signUpButtonText}>회원가입</Text>
              )}
            </TouchableOpacity>
          </View>

          <View style={styles.footer}>
            <Text style={styles.footerText}>이미 계정이 있으신가요?</Text>
            <TouchableOpacity
              onPress={() => navigation.navigate('Login')}
              disabled={loading}
            >
              <Text style={styles.loginLink}>로그인</Text>
            </TouchableOpacity>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  keyboardView: {
    flex: 1,
  },
  scrollContent: {
    flexGrow: 1,
    paddingHorizontal: 20,
  },
  header: {
    alignItems: 'center',
    marginTop: 40,
    marginBottom: 40,
  },
  logo: {
    fontSize: 60,
    marginBottom: 10,
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
  },
  form: {
    flex: 1,
  },
  inputContainer: {
    marginBottom: 20,
  },
  label: {
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
  },
  terms: {
    marginBottom: 24,
    paddingHorizontal: 8,
  },
  termsText: {
    fontSize: 13,
    color: '#666',
    lineHeight: 20,
  },
  termsLink: {
    color: '#007AFF',
    textDecorationLine: 'underline',
  },
  signUpButton: {
    backgroundColor: '#007AFF',
    borderRadius: 8,
    paddingVertical: 16,
    alignItems: 'center',
    marginBottom: 24,
  },
  disabledButton: {
    opacity: 0.6,
  },
  signUpButtonText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: '600',
  },
  footer: {
    flexDirection: 'row',
    justifyContent: 'center',
    paddingVertical: 20,
  },
  footerText: {
    color: '#666',
    fontSize: 14,
    marginRight: 8,
  },
  loginLink: {
    color: '#007AFF',
    fontSize: 14,
    fontWeight: '600',
  },
});