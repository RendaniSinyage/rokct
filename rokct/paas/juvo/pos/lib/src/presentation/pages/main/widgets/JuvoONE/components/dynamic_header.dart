import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../../core/constants/constants.dart';
import '../../../../../../core/utils/app_helpers.dart';
import '../../../../../components/custom_clock/custom_clock.dart';
import '../../../../../theme/app_style.dart';
import '../widgets/juvoone_typing_animation.dart';


class DynamicHeaderComponent extends ConsumerStatefulWidget {
  final int selectIndex;
  final String userRole;

  const DynamicHeaderComponent({
    super.key,
    required this.selectIndex,
    required this.userRole,
  });

  @override
  ConsumerState<DynamicHeaderComponent> createState() => _DynamicHeaderComponentState();
}

class _DynamicHeaderComponentState extends ConsumerState<DynamicHeaderComponent> {
  bool _showJuvoONEAnimation = true;
  String _displayText = '';
  int _currentDigit = 5;
  Timer? _revertTimer;

  static const Duration _revertDuration = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    _updateDisplayText();
  }

  @override
  void didUpdateWidget(DynamicHeaderComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectIndex != widget.selectIndex) {
      _updateDisplayText();
    }
  }

  @override
  void dispose() {
    _revertTimer?.cancel();
    super.dispose();
  }

  void _updateDisplayText() {
    setState(() {
      // Admin role specific headers
      if (widget.userRole == 'admin') {
        switch (widget.selectIndex) {
          case 0:
            _displayText = AppHelpers.getTranslation(TrKeys.orders);
            break;
          case 1:
            _displayText = AppHelpers.getTranslation(TrKeys.customers);
            break;
          case 2:
            if (AppConstants.enableJuvoONE) {
              _displayText = AppHelpers.getTranslation(TrKeys.dashboard);
            } else {
              _displayText = '';
              _currentDigit = 5;
            }
            break;
          default:
            _displayText = '';
            _currentDigit = 5;
            break;
        }
        if (widget.selectIndex != -1) {
          _startTextTransition();
        } else {
          _cancelRevertTimer();
        }
        return;
      }

      // Original logic for other roles
      switch (widget.selectIndex) {
        case 0:
          if (widget.userRole == TrKeys.cooker) {
            _displayText = AppHelpers.getTranslation(TrKeys.order);
          } else {
            _displayText = '';
            _currentDigit = 5;
          }
          break;
        case 1:
          _displayText = AppHelpers.getTranslation(TrKeys.orders);
          break;
        case 2:
          _displayText = widget.userRole == TrKeys.waiter
              ? AppHelpers.getTranslation(TrKeys.tables)
              : AppHelpers.getTranslation(TrKeys.customers);
          break;
        case 3:
          _displayText = AppHelpers.getTranslation(TrKeys.tables);
          break;
        case 4:
          _displayText = AppHelpers.getTranslation(TrKeys.saleHistory);
          break;
        case 5:
          _displayText = AppHelpers.getTranslation(TrKeys.income);
          break;
        case 6:
          _displayText = AppHelpers.getTranslation(TrKeys.stocks);
          break;
        case 7:
          _displayText = AppHelpers.getTranslation(TrKeys.dashboard);
          break;
        default:
          _displayText = '';
          _currentDigit = 5;
          break;
      }
      if (widget.selectIndex != 0 || (widget.selectIndex == 0 && widget.userRole == TrKeys.cooker)) {
        _startTextTransition();
      } else {
        _cancelRevertTimer();
      }
    });
  }

  void _startTextTransition() {
    if (_currentDigit > 0) {
      Future.delayed(const Duration(milliseconds: 100), () {
        setState(() {
          _currentDigit--;
        });
        _startTextTransition();
      });
    } else {
      setState(() {
        _currentDigit = -1;
      });
      _startRevertTimer();
    }
  }

  void _startRevertTimer() {
    _cancelRevertTimer();
    _revertTimer = Timer(_revertDuration, _revertToClock);
  }

  void _cancelRevertTimer() {
    _revertTimer?.cancel();
  }

  void _revertToClock() {
    setState(() {
      _currentDigit = 5;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130.w,
      child: AppConstants.enableJuvoONE
          ? (_showJuvoONEAnimation
          ? JuvoONETypingAnimation(
        onAnimationComplete: () {
          setState(() {
            _showJuvoONEAnimation = false;
          });
        },
      )
          : _buildDynamicContent())
          : _buildDynamicContent(),
    );
  }

  Widget _buildDynamicContent() {
    // For admin role, we always show the text instead of the clock for the relevant indexes
    if (widget.userRole == 'admin') {
      if (widget.selectIndex >= 0 && widget.selectIndex <= 2 && _currentDigit <= 0) {
        return Center(
          child: Text(
            _displayText,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppStyle.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }
    }

    // Original logic
    if (widget.selectIndex == 0 || _currentDigit == 5) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 110.w,  // Adjust this value based on your needs
            child: const CustomClock(),
          ),
          SizedBox(width: 8.w),
        ],
      );
    } else if (_currentDigit > 0) {
      return CustomClock(digitCount: _currentDigit);
    } else {
      return Center(
        child: Text(
          _displayText,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppStyle.black,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
  }
}
