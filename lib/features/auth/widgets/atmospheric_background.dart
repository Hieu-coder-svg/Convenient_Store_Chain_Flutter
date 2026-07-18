import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../core/constants/app_colors.dart';

class AtmosphericBackground extends StatefulWidget {
  final Widget child;

  const AtmosphericBackground({super.key, required this.child});

  @override
  State<AtmosphericBackground> createState() => _AtmosphericBackgroundState();
}

class _AtmosphericBackgroundState extends State<AtmosphericBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(
        0.05,
        0.05,
      ), // Mimics the CSS drift translate(10px, 10px)
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background color
        Container(color: AppColors.background),

        // Atmospheric Blobs
        SlideTransition(
          position: _animation,
          child: Stack(
            children: [
              Positioned(
                top: -50,
                left: -50,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                right: -50,
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFFEBF0D,
                    ).withValues(alpha: 0.1), // secondary-container from HTML
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Blur Filter to spread the blobs
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(color: Colors.transparent),
        ),

        // Main content
        SafeArea(child: widget.child),
      ],
    );
  }
}
