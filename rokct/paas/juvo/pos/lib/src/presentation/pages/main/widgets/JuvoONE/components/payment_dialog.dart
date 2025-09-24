import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../core/constants/constants.dart';
import '../../../../../../core/utils/local_storage.dart';
import '../../../../../components/components.dart';
import '../../../../../theme/app_style.dart';

class YocoTerminalDialog extends StatefulWidget {
  final num amount;
  final String currency;
  final Function(bool success, String? transactionId) onComplete;

  const YocoTerminalDialog({
    super.key,
    required this.amount,
    required this.currency,
    required this.onComplete,
  });

  @override
  _YocoTerminalDialogState createState() => _YocoTerminalDialogState();
}

class _YocoTerminalDialogState extends State<YocoTerminalDialog> {
  static const platform = MethodChannel('app.juvo.pos/yoco');  // Update this line in YocoTerminalDialog
  TerminalPaymentStatus status = TerminalPaymentStatus.initiating;
  String errorMessage = '';
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _startPaymentFlow();
    _startTimeoutTimer();
  }

  void _startTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(AppConstants.fetchTime, () {
      setState(() {
        status = TerminalPaymentStatus.failed;
        errorMessage = 'Payment timed out';
      });
      widget.onComplete(false, null);
    });
  }

  String _getStatusMessage() {
    switch (status) {
      case TerminalPaymentStatus.initiating:
        return 'Initializing payment...';
      case TerminalPaymentStatus.connecting:
        return 'Connecting to terminal...';
      case TerminalPaymentStatus.pairing:
        return 'Pairing with terminal...';
      case TerminalPaymentStatus.processing:
        return 'Processing payment...';
      case TerminalPaymentStatus.completed:
        return 'Payment completed';
      case TerminalPaymentStatus.failed:
        return 'Payment failed: $errorMessage';
    }
  }

  Future<Map<String, dynamic>> _invokeYocoMethod(String method, [Map<String, dynamic>? arguments]) async {
    try {
      final result = await platform.invokeMethod(method, arguments);
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Platform error occurred',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<void> _startPaymentFlow() async {
    try {
      // Check if Yoco is initialized
      setState(() => status = TerminalPaymentStatus.connecting);
      final initResult = await _invokeYocoMethod('initializeYoco', {
        'publicKey': LocalStorage.getYocoPublicKey(),
        'isTest': LocalStorage.isYocoTest(),
      });

      if (!initResult['success']) {
        throw Exception(initResult['error'] ?? 'Failed to initialize Yoco');
      }

      // Check terminal connection/pairing
      final pairedDevice = LocalStorage.getYocoPairedDevice();
      if (pairedDevice == null) {
        setState(() => status = TerminalPaymentStatus.pairing);
        final pairingResult = await _invokeYocoMethod('pairTerminal');

        if (!pairingResult['success']) {
          throw Exception(pairingResult['error'] ?? 'Pairing failed');
        }
        await LocalStorage.setYocoPairedDevice(pairingResult['deviceId']);
      }

      // Process payment
      setState(() => status = TerminalPaymentStatus.processing);
      final paymentResult = await _invokeYocoMethod('startPayment', {
        'amountInCents': (widget.amount * 100).toInt(),
        'currency': widget.currency,
        'environment': LocalStorage.isYocoTest() ? 'test' : 'live',
        'deviceId': LocalStorage.getYocoPairedDevice(),
      });

      if (paymentResult['success']) {
        setState(() => status = TerminalPaymentStatus.completed);
        _timeoutTimer?.cancel();
        widget.onComplete(true, paymentResult['transactionId']);
        Navigator.of(context).pop();
      } else {
        throw Exception(paymentResult['error'] ?? 'Payment failed');
      }
    } catch (e) {
      setState(() {
        status = TerminalPaymentStatus.failed;
        errorMessage = e.toString();
      });
      _timeoutTimer?.cancel();
      widget.onComplete(false, null);
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Container(
        height: 150.h,
        constraints: BoxConstraints(maxWidth: 300.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (status != TerminalPaymentStatus.completed &&
                status != TerminalPaymentStatus.failed)
              CircularProgressIndicator(color: AppStyle.primary),
            20.verticalSpace,
            Text(
              _getStatusMessage(),
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            20.verticalSpace,
            if (status == TerminalPaymentStatus.failed)
              SizedBox(
                width: 120.w,
                child: LoginButton(
                  title: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
