import 'package:flutter/material.dart';
import 'package:utube/core/constants/app_colors.dart';
import 'package:utube/features/analysis/screens/analysis_screen.dart';
import 'package:utube/features/history/screens/history_screen.dart';
import 'package:utube/features/bookmarks/screens/bookmarks_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  String? _analysisUrl;

  @override
  void initState() {
    super.initState();
    // Extract arguments after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments is Map<String, dynamic>) {
        final url = arguments['url'] as String?;
        final initialTab = arguments['initialTab'] as int? ?? 0;

        setState(() {
          _analysisUrl = url;
          _currentIndex = initialTab;
        });
      }
    });
  }

  List<Widget> get _screens => [
    AnalysisScreen(url: _analysisUrl), // Pass URL to analysis screen
    const HistoryScreen(),
    const BookmarksScreen(), // This will work once API methods are added
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.surfaceElevated, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.video_library_outlined),
              activeIcon: Icon(Icons.video_library),
              label: 'Analyze',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_border_outlined),
              activeIcon: Icon(Icons.bookmark),
              label: 'Bookmarks',
            ),
          ],
        ),
      ),
    );
  }
}
