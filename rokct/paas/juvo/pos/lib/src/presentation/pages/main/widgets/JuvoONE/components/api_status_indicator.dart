import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../core/constants/constants.dart';
import '../../../../../../core/utils/utils.dart';
import '../../../../../theme/app_style.dart';
import 'package:http/http.dart' as http;


class ApiStatusIndicator extends StatefulWidget {
  const ApiStatusIndicator({super.key});

  @override
  State<ApiStatusIndicator> createState() => _ApiStatusIndicatorState();
}

class _ApiStatusIndicatorState extends State<ApiStatusIndicator>
    with SingleTickerProviderStateMixin {
  bool _isApiOk = true;
  bool _isOnline = true;
  bool _showContainer = true;
  late Timer _statusCheckTimer;
  late Timer _fadeOutTimer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _checkStatus();
    _statusCheckTimer =
        Timer.periodic(const Duration(minutes: 1), (_) => _checkStatus());
  }

  @override
  void dispose() {
    _statusCheckTimer.cancel();
    _fadeOutTimer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    await _checkConnectivity();
    if (_isOnline) {
      await _checkApiStatus();
    } else {
      setState(() {
        _isApiOk = false;
      });
    }
    _updateAnimationState();
  }

  Future<void> _checkConnectivity() async {
    bool isConnected = await AppConnectivity.connectivity();
    setState(() {
      _isOnline = isConnected;
    });
  }

  Future<void> _checkApiStatus() async {
    try {
      final response =
      await http.get(Uri.parse('${AppConstants.baseUrl}/api/v1/rest/status'));
      setState(() {
        _isApiOk = response.statusCode == 200;
      });
    } catch (e) {
      setState(() {
        _isApiOk = false;
      });
    }
  }

  void _updateAnimationState() {
    if (_isOnline && _isApiOk) {
      _animationController.stop();
      _animationController.value = 1.0;
      setState(() {
        _showContainer = true;
      });
      _startFadeOutTimer();
    } else {
      _animationController.repeat(reverse: true);
      setState(() {
        _showContainer = true;
      });
      _fadeOutTimer.cancel();
    }
  }

  void _startFadeOutTimer() {
    _fadeOutTimer = Timer(const Duration(seconds: 5), () {
      setState(() {
        _showContainer = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _checkStatus();
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Opacity(
            opacity: _isOnline && _isApiOk ? 1.0 : _fadeAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: 24.r,
              width: _showContainer ? 80.r : 24.r,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: _isOnline && _isApiOk ? AppStyle.green : AppStyle.red,
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _showContainer
                      ? Text(
                    _isOnline && _isApiOk
                        ? AppHelpers.getTranslation(TrKeys.online)
                        : AppHelpers.getTranslation(TrKeys.offline),
                    key: const ValueKey("text"),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 14.sp,
                      color: AppStyle.black,
                    ),
                  )
                      : const SizedBox.shrink(key: ValueKey("empty")),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
