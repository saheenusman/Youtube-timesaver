import 'package:flutter/material.dart';
import 'package:utube/core/constants/app_colors.dart';

class StatsCard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const StatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.1), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Analysis Stats',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.video_library_outlined,
                  label: 'Total Videos',
                  value: stats['total_analyses']?.toString() ?? '0',
                ),
              ),

              Container(height: 40, width: 1, color: AppColors.surfaceElevated),

              Expanded(
                child: _buildStatItem(
                  icon: Icons.highlight_alt,
                  label: 'Total Highlights',
                  value: stats['total_highlights']?.toString() ?? '0',
                ),
              ),

              Container(height: 40, width: 1, color: AppColors.surfaceElevated),

              Expanded(
                child: _buildStatItem(
                  icon: Icons.today_outlined,
                  label: 'This Week',
                  value: stats['this_week']?.toString() ?? '0',
                ),
              ),
            ],
          ),

          if (stats['favorite_category'] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_outline, color: AppColors.primary, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Top category: ${stats['favorite_category']}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),

        const SizedBox(height: 8),

        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
