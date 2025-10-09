import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../theme/theme.dart';



class ApiStatusIndicator extends StatefulWidget {
  const ApiStatusIndicator({Key? key}) : super(key: key);

  @override
  _ApiStatusIndicatorState createState() => _ApiStatusIndicatorState();
}

class _ApiStatusIndicatorState extends State<ApiStatusIndicator> {
  bool _isApiOk = true;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _checkApiStatus();
    // Check API status every 60 seconds
    _timer =
        Timer.periodic(const Duration(seconds: 60), (_) => _checkApiStatus());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _checkApiStatus() async {
    try {
      final response =
          await http.get(Uri.parse('https://your-api-endpoint.com/status'));
      setState(() {
        _isApiOk = response.statusCode == 200;
      });
    } catch (e) {
      setState(() {
        _isApiOk = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _isApiOk ? 'API is operational' : 'API is down',
      child: Container(
        width: 12,
        height: 12,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isApiOk ? AppStyle.green : AppStyle.red,
        ),
      ),
    );
  }
}

