import 'package:flutter/material.dart';
import 'package:utube/core/constants/app_colors.dart';

class AgentProgressBar extends StatelessWidget {
  const AgentProgressBar({
    super.key,
    required this.progress,
    required this.agentColor,
    this.height = 3.0,
  });

  final double progress; // 0.0 to 1.0
  final Color agentColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: double.infinity,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(agentColor),
            minHeight: height,
          ),
        ),
      ),
    );
  }
}

class AgentProgressText extends StatelessWidget {
  const AgentProgressText({
    super.key,
    required this.text,
    required this.progress,
  });

  final String text;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: progress > 0 ? 1.0 : 0.5,
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 9, // Reduced from 10 to match status text
          color: progress > 0
              ? AppColors.textSecondary
              : AppColors.textTertiary,
          height: 1.1, // Reduced line height to match status text
          fontWeight: progress >= 1.0 ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}
