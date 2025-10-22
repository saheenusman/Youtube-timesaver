import 'package:flutter/material.dart';
import 'package:utube/core/constants/app_colors.dart';
import 'package:utube/features/home/widgets/url_input_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String route = '/';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showTitle = false;
  bool _showCard = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showTitle = true);
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showCard = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final double horizontal = MediaQuery.of(context).size.width >= 600
        ? 24
        : 16;
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true, // Handle keyboard
      body: SafeArea(
        child: SingleChildScrollView(
          // Add scroll view for keyboard
          padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  32,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  AnimatedOpacity(
                    opacity: _showTitle ? 1 : 0,
                    duration: const Duration(milliseconds: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Time Saver',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Paste any YouTube URL',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    offset: _showCard ? Offset.zero : const Offset(0, 0.1),
                    child: Column(
                      children: const [
                        // Hero placeholder to pair with analysis screen thumbnail
                        Hero(tag: 'video_thumbnail', child: SizedBox.shrink()),
                        UrlInputCard(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Quick access to History and Search
                  AnimatedOpacity(
                    opacity: _showCard ? 1 : 0,
                    duration: const Duration(milliseconds: 600),
                    child: Column(
                      children: [
                        const Text(
                          'Quick Access',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickAccessButton(
                                context: context,
                                icon: Icons.history,
                                title: 'History',
                                subtitle: 'View past analyses',
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/main',
                                  arguments: {
                                    'initialTab': 1,
                                  }, // Go to history tab
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildQuickAccessButton(
                                context: context,
                                icon: Icons.bookmark_border,
                                title: 'Bookmarks',
                                subtitle: 'Saved videos',
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/main',
                                  arguments: {
                                    'initialTab': 2,
                                  }, // Go to bookmarks tab
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Powered by AI Agents',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.whiteTransparent, width: 1),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
