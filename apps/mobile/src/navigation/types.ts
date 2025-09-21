import { BottomTabScreenProps } from '@react-navigation/bottom-tabs';
import { CompositeScreenProps, NavigatorScreenParams } from '@react-navigation/native';
import { StackScreenProps } from '@react-navigation/stack';

// Root Stack
export type RootStackParamList = {
  Auth: NavigatorScreenParams<AuthStackParamList>;
  Main: NavigatorScreenParams<MainTabParamList>;
  Onboarding: NavigatorScreenParams<OnboardingStackParamList>;
};

// Auth Stack
export type AuthStackParamList = {
  Welcome: undefined;
  Login: undefined;
  SignUp: undefined;
  Verification: { phone: string };
};

// Onboarding Stack
export type OnboardingStackParamList = {
  Tutorial: undefined;
  ProfileSetup: undefined;
  SkillSelection: undefined;
  Preferences: undefined;
};

// Main Tab
export type MainTabParamList = {
  Home: NavigatorScreenParams<HomeStackParamList>;
  Explore: NavigatorScreenParams<ExploreStackParamList>;
  Marketplace: NavigatorScreenParams<MarketplaceStackParamList>;
  Investment: NavigatorScreenParams<InvestmentStackParamList>;
  Earnings: NavigatorScreenParams<EarningsStackParamList>;
  Profile: NavigatorScreenParams<ProfileStackParamList>;
};

// Home Stack
export type HomeStackParamList = {
  Dashboard: undefined;
  Notifications: undefined;
  QuickTasks: undefined;
};

// Explore Stack
export type ExploreStackParamList = {
  TaskList: undefined;
  TaskDetail: { taskId: string };
  Categories: undefined;
  Search: undefined;
};

// Marketplace Stack
export type MarketplaceStackParamList = {
  MarketplaceList: undefined;
  MarketplaceDetail: { itemId: string };
  CreateMarketplaceItem: undefined;
  MarketplaceSearch: undefined;
  AuctionList: undefined;
  AuctionDetail: { auctionId: string };
  CreateAuction: undefined;
  OffersList: { type: 'sent' | 'received' };
  UserMarketplace: undefined;
};

// Investment Stack
export type InvestmentStackParamList = {
  InvestmentDashboard: undefined;
  PortfolioDetail: { portfolioId: string };
  CreatePortfolio: undefined;
  Watchlist: undefined;
  MarketOverview: undefined;
  AddHolding: { portfolioId: string };
  StockDetail: { symbol: string };
  Prediction: undefined;
  Analysis: undefined;
  Alerts: undefined;
};

// MyTasks Stack
export type MyTasksStackParamList = {
  TaskManager: undefined;
  TaskProgress: { taskId: string };
  Calendar: undefined;
};

// Earnings Stack
export type EarningsStackParamList = {
  Overview: undefined;
  History: undefined;
  Analytics: undefined;
  Withdraw: undefined;
};

// Profile Stack
export type ProfileStackParamList = {
  MyProfile: undefined;
  Settings: undefined;
  Achievements: undefined;
  Help: undefined;
};

// Screen Props Types
export type RootStackScreenProps<T extends keyof RootStackParamList> =
  StackScreenProps<RootStackParamList, T>;

export type AuthStackScreenProps<T extends keyof AuthStackParamList> =
  CompositeScreenProps<
    StackScreenProps<AuthStackParamList, T>,
    RootStackScreenProps<'Auth'>
  >;

export type MainTabScreenProps<T extends keyof MainTabParamList> =
  CompositeScreenProps<
    BottomTabScreenProps<MainTabParamList, T>,
    RootStackScreenProps<'Main'>
  >;

export type HomeStackScreenProps<T extends keyof HomeStackParamList> =
  CompositeScreenProps<
    StackScreenProps<HomeStackParamList, T>,
    MainTabScreenProps<'Home'>
  >;

export type ExploreStackScreenProps<T extends keyof ExploreStackParamList> =
  CompositeScreenProps<
    StackScreenProps<ExploreStackParamList, T>,
    MainTabScreenProps<'Explore'>
  >;

export type MarketplaceStackScreenProps<T extends keyof MarketplaceStackParamList> =
  CompositeScreenProps<
    StackScreenProps<MarketplaceStackParamList, T>,
    MainTabScreenProps<'Marketplace'>
  >;

export type InvestmentStackScreenProps<T extends keyof InvestmentStackParamList> =
  CompositeScreenProps<
    StackScreenProps<InvestmentStackParamList, T>,
    MainTabScreenProps<'Investment'>
  >;