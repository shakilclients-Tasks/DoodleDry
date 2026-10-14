import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class PulsingHeartbeatIcon extends StatefulWidget {
  final double size;
  final Color color;

  const PulsingHeartbeatIcon({
    super.key,
    this.size = 24.0,
    this.color = AppColors.heartRate,
  });

  @override
  State<PulsingHeartbeatIcon> createState() => _PulsingHeartbeatIconState();
}

class _PulsingHeartbeatIconState extends State<PulsingHeartbeatIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Icon(
            Icons.favorite_rounded,
            size: widget.size,
            color: widget.color,
          ),
        );
      },
    );
  }
}
