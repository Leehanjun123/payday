import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Ionicons } from '@expo/vector-icons';

import { RootStackParamList, MainTabParamList, AuthStackParamList, ExploreStackParamList, MarketplaceStackParamList, InvestmentStackParamList } from './types';
import { useAuth } from '../contexts/AuthContext';
import WelcomeScreen from '../screens/auth/WelcomeScreen';
import LoginScreen from '../screens/auth/LoginScreen';
import SignUpScreen from '../screens/auth/SignUpScreen';
import DashboardScreen from '../screens/home/DashboardScreen';
import TaskListScreen from '../screens/explore/TaskListScreen';
import TaskDetailScreen from '../screens/explore/TaskDetailScreen';
import MyTasksScreen from '../screens/tasks/MyTasksScreen';
import EarningsScreen from '../screens/earnings/EarningsScreen';
import ProfileScreen from '../screens/profile/ProfileScreen';
import MarketplaceScreen from '../screens/marketplace/MarketplaceScreen';
import AuctionListScreen from '../screens/auction/AuctionListScreen';
import InvestmentDashboardScreen from '../screens/investment/InvestmentDashboardScreen';
import PredictionScreen from '../screens/prediction/PredictionScreen';
import AnalysisScreen from '../screens/analysis/AnalysisScreen';
import AlertsScreen from '../screens/alerts/AlertsScreen';

const Stack = createStackNavigator<RootStackParamList>();
const AuthStack = createStackNavigator<AuthStackParamList>();
const Tab = createBottomTabNavigator<MainTabParamList>();
const ExploreStack = createStackNavigator<ExploreStackParamList>();
const MarketplaceStack = createStackNavigator<MarketplaceStackParamList>();
const InvestmentStack = createStackNavigator<InvestmentStackParamList>();

// Placeholder screens
const PlaceholderScreen = ({ name }: { name: string }) => (
  <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
    <Text>{name} Screen</Text>
  </View>
);

import { View, Text } from 'react-native';

function ExploreStackNavigator() {
  return (
    <ExploreStack.Navigator
      screenOptions={{
        headerShown: false,
      }}
    >
      <ExploreStack.Screen name="TaskList" component={TaskListScreen} />
      <ExploreStack.Screen name="TaskDetail" component={TaskDetailScreen} />
    </ExploreStack.Navigator>
  );
}

function MarketplaceStackNavigator() {
  return (
    <MarketplaceStack.Navigator
      screenOptions={{
        headerShown: false,
      }}
    >
      <MarketplaceStack.Screen name="MarketplaceList" component={MarketplaceScreen} />
      <MarketplaceStack.Screen name="AuctionList" component={AuctionListScreen} />
    </MarketplaceStack.Navigator>
  );
}

function InvestmentStackNavigator() {
  return (
    <InvestmentStack.Navigator
      screenOptions={{
        headerShown: false,
      }}
    >
      <InvestmentStack.Screen name="InvestmentDashboard" component={InvestmentDashboardScreen} />
      <InvestmentStack.Screen name="Prediction" component={PredictionScreen} />
      <InvestmentStack.Screen name="Analysis" component={AnalysisScreen} />
      <InvestmentStack.Screen name="Alerts" component={AlertsScreen} />
    </InvestmentStack.Navigator>
  );
}

function MainTabs() {
  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        tabBarIcon: ({ focused, color, size }) => {
          let iconName: keyof typeof Ionicons.glyphMap = 'home';

          if (route.name === 'Home') {
            iconName = focused ? 'home' : 'home-outline';
          } else if (route.name === 'Explore') {
            iconName = focused ? 'search' : 'search-outline';
          } else if (route.name === 'Marketplace') {
            iconName = focused ? 'storefront' : 'storefront-outline';
          } else if (route.name === 'Investment') {
            iconName = focused ? 'trending-up' : 'trending-up-outline';
          } else if (route.name === 'MyTasks') {
            iconName = focused ? 'briefcase' : 'briefcase-outline';
          } else if (route.name === 'Earnings') {
            iconName = focused ? 'wallet' : 'wallet-outline';
          } else if (route.name === 'Profile') {
            iconName = focused ? 'person' : 'person-outline';
          }

          return <Ionicons name={iconName} size={size} color={color} />;
        },
        tabBarActiveTintColor: '#007AFF',
        tabBarInactiveTintColor: 'gray',
        tabBarLabelStyle: {
          fontSize: 12,
        },
      })}
    >
      <Tab.Screen
        name="Home"
        component={DashboardScreen}
        options={{
          title: '홈',
          headerShown: false,
        }}
      />
      <Tab.Screen
        name="Explore"
        component={ExploreStackNavigator}
        options={{
          title: '탐색',
          headerShown: false,
        }}
      />
      <Tab.Screen
        name="Marketplace"
        component={MarketplaceStackNavigator}
        options={{
          title: '마켓',
          headerShown: false,
        }}
      />
      <Tab.Screen
        name="Investment"
        component={InvestmentStackNavigator}
        options={{
          title: '투자',
          headerShown: false,
        }}
      />
      <Tab.Screen
        name="Earnings"
        component={EarningsScreen}
        options={{
          title: '수익',
          headerShown: false,
        }}
      />
      <Tab.Screen
        name="Profile"
        component={ProfileScreen}
        options={{
          title: '프로필',
          headerShown: false,
        }}
      />
    </Tab.Navigator>
  );
}

function AuthStackNavigator() {
  return (
    <AuthStack.Navigator
      screenOptions={{
        headerShown: false,
      }}
    >
      <AuthStack.Screen name="Welcome" component={WelcomeScreen} />
      <AuthStack.Screen name="Login" component={LoginScreen} />
      <AuthStack.Screen name="SignUp" component={SignUpScreen} />
    </AuthStack.Navigator>
  );
}

export default function MainNavigator() {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    // You can return a loading screen here
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
        <Text>Loading...</Text>
      </View>
    );
  }

  return (
    <NavigationContainer>
      <Stack.Navigator screenOptions={{ headerShown: false }}>
        {isAuthenticated ? (
          <Stack.Screen name="Main" component={MainTabs} />
        ) : (
          <Stack.Screen name="Auth" component={AuthStackNavigator} />
        )}
      </Stack.Navigator>
    </NavigationContainer>
  );
}