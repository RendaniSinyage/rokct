import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../theme/app_style.dart';

class JuvoONETypingAnimation extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const JuvoONETypingAnimation({super.key, required this.onAnimationComplete});

  @override
  _JuvoONETypingAnimationState createState() => _JuvoONETypingAnimationState();
}

class _JuvoONETypingAnimationState extends State<JuvoONETypingAnimation> {
  String _text = 'JuvoONE';
  final String _fullText = 'JuvoONE';
  int _currentIndex = 7; // Start from the end of 'JuvoONE'

  @override
  void initState() {
    super.initState();
    // Increase the delay before starting the animation to 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _startDeletingAnimation();
      }
    });
  }

  void _startDeletingAnimation() {
    const duration = Duration(milliseconds: 200);
    Timer.periodic(duration, (timer) {
      if (_currentIndex >= 0) {
        setState(() {
          _text = _text.substring(0, _currentIndex);
          _currentIndex--;
        });
      } else {
        timer.cancel();
        // Ensure the text is completely empty before calling onAnimationComplete
        setState(() {
          _text = '';
        });
        // Add a small delay before calling onAnimationComplete
        Future.delayed(const Duration(milliseconds: 200), () {
          widget.onAnimationComplete();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 26.sp,
          fontWeight: FontWeight.bold,
          fontFamily: 'Nunito',
        ),
        children: [
          TextSpan(
            text: _text.substring(0, _text.length > 4 ? 4 : _text.length),
            style: const TextStyle(color: AppStyle.black),
          ),
          if (_text.length > 4)
            TextSpan(
              text: _text.substring(4),
              style: TextStyle(color: AppStyle.brandGreen),
            ),
        ],
      ),
    );
  }
}
