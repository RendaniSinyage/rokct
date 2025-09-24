import 'package:flutter/material.dart';

import '../../../../../theme/app_style.dart';

class LoadingAnimation extends StatefulWidget {
  const LoadingAnimation({super.key});

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111827), // Equivalent to bg-gray-900
      child: Center(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Opacity(
              opacity: _animation.value,
              child: child,
            );
          },
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.25,
                fontWeight: FontWeight.bold,
                fontFamily: 'Nunito',
              ),
              children: [
                const TextSpan(
                  text: 'Juvo',
                  style: TextStyle(color: AppStyle.black),
                ),
                TextSpan(
                  text: 'ONE',
                  style: TextStyle(color: AppStyle.brandGreen),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
