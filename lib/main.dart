import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/hot_topics_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const ProviderScope(child: ContentSparkApp()));
}

class ContentSparkApp extends StatelessWidget {
  const ContentSparkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '灵感笔 ContentSpark',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});
  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _idx = 0;

  static const _tabs = [
    BottomNavigationBarItem(icon: Icon(Icons.edit_rounded), activeIcon: Icon(Icons.edit), label: '创作'),
    BottomNavigationBarItem(icon: Icon(Icons.local_fire_department_outlined), activeIcon: Icon(Icons.local_fire_department), label: '热点'),
    BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history_rounded), label: '历史'),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _page(_idx),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        type: BottomNavigationBarType.fixed,
        items: _tabs,
      ),
    );
  }

  Widget _page(int i) {
    switch (i) {
      case 0: return const HomeScreen();
      case 1: return const HotTopicsScreen();
      case 2: return const HistoryScreen();
      case 3: return const ProfileScreen();
      default: return const HomeScreen();
    }
  }
}
