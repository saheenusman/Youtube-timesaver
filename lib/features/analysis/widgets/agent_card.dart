import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:utube/core/constants/app_colors.dart';
import 'package:utube/core/widgets/agent_progress.dart';

class AgentCard extends StatelessWidget {
  const AgentCard({
    super.key,
    required this.agentName,
    required this.icon,
    required this.isLoading,
    required this.status,
    this.progress = 0.0,
  });

  final String agentName;
  final IconData icon;
  final bool isLoading;
  final String status;
  final double progress; // 0.0 to 1.0, for loading progress

  // Helper to get agent-specific colors
  Color _getAgentColor() {
    final name = agentName.toLowerCase();
    if (name.contains('teacher')) return AppColors.agentTeacher;
    if (name.contains('analyst')) return AppColors.agentAnalyst;
    if (name.contains('explorer')) return AppColors.agentExplorer;
    return AppColors.primary;
  }

  // Helper to get progress-based text
  String _getProgressText() {
    if (progress == 0.0) return 'Initializing...';
    if (progress < 0.3) return 'Starting analysis...';
    if (progress < 0.6) return 'Processing data...';
    if (progress < 0.9) return 'Finalizing results...';
    if (progress >= 1.0) return 'Complete!';
    return 'Working...';
  }

  @override
  Widget build(BuildContext context) {
    final agentColor = _getAgentColor();

    Widget avatar = IconTheme(
      data: const IconThemeData(color: AppColors.white, size: 20),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isLoading ? AppColors.surfaceElevated : agentColor,
          border: isLoading
              ? Border.all(color: AppColors.whiteTransparent, width: 1)
              : Border.all(color: agentColor.withOpacity(0.5), width: 2),
        ),
        child: Center(child: Icon(icon)),
      ),
    );

    final content = Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar section - flexible
          Flexible(flex: 3, child: Center(child: avatar)),
          // Agent name section - flexible
          Flexible(
            flex: 1,
            child: Text(
              agentName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppColors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
          // Status section - flexible for consistency
          Flexible(
            flex: 2,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: isLoading
                  ? Column(
                      key: const ValueKey('loadingProgress'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AgentProgressBar(
                          progress: progress,
                          agentColor: _getAgentColor(),
                          height: 2.5,
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: AgentProgressText(
                            text: _getProgressText(),
                            progress: progress,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      key: const ValueKey('loadedColumn'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 10,
                        ),
                        const SizedBox(height: 2),
                        Expanded(
                          child: Text(
                            status,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );

    Widget card = Container(
      // Fixed dimensions to ensure all cards are exactly the same size
      width: double.infinity,
      height: 125, // Optimized height to prevent overflow
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLoading
              ? AppColors.whiteTransparent
              : agentColor.withOpacity(0.8),
          width: isLoading ? 1 : 2,
        ),
      ),
      child: content,
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: isLoading
          ? Shimmer.fromColors(
              key: const ValueKey('shimmerCard'),
              baseColor: Colors.grey.shade800,
              highlightColor: Colors.grey.shade700,
              child: card,
            )
          : KeyedSubtree(key: const ValueKey('contentCard'), child: card),
    );
  }
}
