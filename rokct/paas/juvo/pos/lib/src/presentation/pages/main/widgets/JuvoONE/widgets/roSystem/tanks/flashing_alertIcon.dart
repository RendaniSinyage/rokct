import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

class FlashingAlertIcon extends StatefulWidget {
  const FlashingAlertIcon({super.key});

  @override
  _FlashingAlertIconState createState() => _FlashingAlertIconState();
}

class _FlashingAlertIconState extends State<FlashingAlertIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: const Icon(
        Remix.alert_fill,
        color: Colors.red,
        size: 24,
      ),
    );
  }
}
