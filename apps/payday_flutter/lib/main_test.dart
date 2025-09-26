import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // NotificationService 초기화
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(const PayDayApp());
}

class PayDayApp extends StatelessWidget {
  const PayDayApp({super.key});

  static Future<bool> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeProvider>(
      create: (context) => ThemeProvider(),
      builder: (context, child) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            if (themeProvider.isLoading) {
              return MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                debugShowCheckedModeBanner: false,
              );
            }

            return MaterialApp(
              title: 'PayDay',
              theme: AppThemes.lightTheme,
              darkTheme: AppThemes.darkTheme,
              themeMode: themeProvider.themeMode,
              home: FutureBuilder<bool>(
                future: _checkOnboardingStatus(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  return snapshot.data! ? const MainScreen() : const OnboardingScreen();
                },
              ),
              routes: {
                '/home': (context) => const MainScreen(),
                '/onboarding': (context) => const OnboardingScreen(),
              },
              debugShowCheckedModeBanner: false,
            );
          },
        );
      },
    );
  }
}

// Simplified provider classes for this implementation
class ChangeNotifierProvider<T extends ChangeNotifier> extends StatefulWidget {
  final T Function(BuildContext context) create;
  final Widget Function(BuildContext context, Widget? child) builder;

  const ChangeNotifierProvider({
    Key? key,
    required this.create,
    required this.builder,
  }) : super(key: key);

  @override
  State<ChangeNotifierProvider<T>> createState() => _ChangeNotifierProviderState<T>();
}

class _ChangeNotifierProviderState<T extends ChangeNotifier> extends State<ChangeNotifierProvider<T>> {
  late T _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = widget.create(context);
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedProvider<T>(
      notifier: _notifier,
      child: widget.builder(context, null),
    );
  }
}

class _InheritedProvider<T extends ChangeNotifier> extends InheritedNotifier<T> {
  const _InheritedProvider({
    required T notifier,
    required Widget child,
  }) : super(notifier: notifier, child: child);
}

class Consumer<T extends ChangeNotifier> extends StatelessWidget {
  final Widget Function(BuildContext context, T value, Widget? child) builder;

  const Consumer({Key? key, required this.builder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notifier = context.dependOnInheritedWidgetOfExactType<_InheritedProvider<T>>()?.notifier;
    if (notifier == null) {
      throw Exception('Provider not found');
    }
    return builder(context, notifier, null);
  }
}