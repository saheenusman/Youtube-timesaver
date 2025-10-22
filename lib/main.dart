import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:utube/core/theme/app_theme.dart';
import 'package:utube/features/analysis/screens/analysis_screen.dart';
import 'package:utube/features/home/screens/home_screen.dart';
import 'package:utube/features/navigation/main_navigation_screen.dart';
import 'package:utube/features/history/screens/history_screen.dart';
import 'package:utube/features/search/screens/search_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(const UtubeApp());
}

class UtubeApp extends StatelessWidget {
  const UtubeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Time Saver',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeScreen(),
      routes: {
        '/analysis': (context) => const AnalysisScreen(),
        '/main': (context) => const MainNavigationScreen(),
        '/history': (context) => const HistoryScreen(),
        '/search': (context) => const SearchScreen(),
      },
    );
  }
}
