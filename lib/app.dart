import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_theme.dart';
import 'features/alerts/presentation/providers/alert_provider.dart';
import 'features/alerts/presentation/screens/alerts_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/history/presentation/screens/history_screen.dart';
import 'features/monitoring/presentation/screens/monitoring_screen.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'shared/widgets/navigation_bar.dart';

class DoodledryApp extends ConsumerWidget {
  const DoodledryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'DOODLEDRY',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}

class MainAppScreen extends ConsumerStatefulWidget {
  const MainAppScreen({super.key});

  @override
  ConsumerState<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends ConsumerState<MainAppScreen> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final unreadAlerts = ref.watch(unreadAlertsCountProvider);

    final pages = [
      DashboardScreen(onNavigateToTab: _onTabSelected),
      const MonitoringScreen(),
      const HistoryScreen(),
      const AlertsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: DoodledryBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        unreadAlertsCount: unreadAlerts,
      ),
    );
  }
}
