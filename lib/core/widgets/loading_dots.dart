import 'package:flutter/material.dart';
import 'package:utube/core/constants/app_colors.dart';

class LoadingDots extends StatefulWidget {
  const LoadingDots({super.key});

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;
  late Animation<double> _animation1;
  late Animation<double> _animation2;
  late Animation<double> _animation3;

  @override
  void initState() {
    super.initState();

    // Create controllers for each dot
    _controller1 = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _controller2 = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _controller3 = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Create fade in/out animations
    _animation1 = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller1, curve: Curves.easeInOut));

    _animation2 = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller2, curve: Curves.easeInOut));

    _animation3 = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller3, curve: Curves.easeInOut));

    // Start animations with staggered delays
    _startAnimations();
  }

  void _startAnimations() {
    // Start first dot immediately
    _controller1.repeat(reverse: true);

    // Start second dot with 0.3 stagger (360ms delay)
    Future.delayed(const Duration(milliseconds: 360), () {
      if (mounted) _controller2.repeat(reverse: true);
    });

    // Start third dot with 0.6 stagger (720ms delay)
    Future.delayed(const Duration(milliseconds: 720), () {
      if (mounted) _controller3.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _animation1,
          builder: (context, child) => Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(_animation1.value),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 2),
        AnimatedBuilder(
          animation: _animation2,
          builder: (context, child) => Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(_animation2.value),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 2),
        AnimatedBuilder(
          animation: _animation3,
          builder: (context, child) => Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(_animation3.value),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
