import { StatusBar } from 'expo-status-bar';
import React, { useEffect } from 'react';

import { AuthProvider } from './src/contexts/AuthContext';
import MainNavigator from './src/navigation/MainNavigator';
import notificationService from './src/services/notificationService';

export default function App() {
  useEffect(() => {
    // Initialize notification service - Disabled for Expo Go testing
    // Push notifications don't work in Expo Go - need development build
    // notificationService.initialize();

    return () => {
      // Cleanup on unmount
      // notificationService.cleanup();
    };
  }, []);

  return (
    <AuthProvider>
      <MainNavigator />
      <StatusBar style="auto" />
    </AuthProvider>
  );
}
