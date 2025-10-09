import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../../theme/theme.dart';
import 'service/weather_state.dart';

class RainFeedback {
  final DateTime date;
  final int predictedPOP;  // Daily chance of rain
  final double precipitationMM;  // Precipitation in millimeters
  final int dailyWillItRain;  // 1 if rain predicted, 0 if not
  bool userConfirmedRain;
  bool wasEdited;  // Track if feedback was edited

  RainFeedback({
    required this.date,
    required this.predictedPOP,
    required this.precipitationMM,
    required this.dailyWillItRain,
    required this.userConfirmedRain,
    this.wasEdited = false,
  });

  bool get wasCorrect {
    // Prediction is correct if:
    // 1. POP >= 80
    // 2. dailyWillItRain is 1 (predicting rain)
    // 3. User confirms rain
    return predictedPOP >= 80 &&
        dailyWillItRain == 1 &&
        userConfirmedRain;
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'predictedPOP': predictedPOP,
    'precipitationMM': precipitationMM,
    'dailyWillItRain': dailyWillItRain,
    'userConfirmedRain': userConfirmedRain,
    'wasEdited': wasEdited,
  };

  factory RainFeedback.fromJson(Map<String, dynamic> json) => RainFeedback(
    date: DateTime.parse(json['date']),
    predictedPOP: json['predictedPOP'] as int,
    precipitationMM: (json['precipitationMM'] as num).toDouble(),
    dailyWillItRain: json['dailyWillItRain'] as int,
    userConfirmedRain: json['userConfirmedRain'] as bool,
    wasEdited: json['wasEdited'] ?? false,
  );

  String get dateString => "${date.year}-${date.month}-${date.day}";
}

class RainFeedbackSystem {
  final String _storageKey = 'rain_feedback';
  static const int POP_THRESHOLD = 80;
  static const int FEEDBACK_START_HOUR = 6;   // 6 AM
  static const int FEEDBACK_END_HOUR = 22;    // 10 PM

  Future<void> _clearInvalidFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_storageKey) ?? [];

    // Filter out any entries outside valid hours
    final validFeedback = jsonList
        .map((jsonStr) => RainFeedback.fromJson(jsonDecode(jsonStr)))
        .where((feedback) =>
    feedback.date.hour >= FEEDBACK_START_HOUR &&
        feedback.date.hour <= FEEDBACK_END_HOUR)
        .map((feedback) => jsonEncode(feedback.toJson()))
        .toList();

    // Save only valid feedback
    await prefs.setStringList(_storageKey, validFeedback);
  }

  Future<void> saveFeedback({
    required int pop,
    required double precipMM,
    required int dailyWillItRain,
    required bool userConfirmedRain
  }) async {
    // Clear invalid feedback before saving
    await _clearInvalidFeedback();

    // Only save if within valid feedback hours
    final now = DateTime.now();
    if (now.hour < FEEDBACK_START_HOUR || now.hour > FEEDBACK_END_HOUR) return;

    final prefs = await SharedPreferences.getInstance();
    final feedbackList = await getFeedbackHistory();

    // Remove any existing feedback for today
    feedbackList.removeWhere((feedback) =>
    feedback.dateString == "${now.year}-${now.month}-${now.day}"
    );

    feedbackList.add(RainFeedback(
      date: now,
      predictedPOP: pop,
      precipitationMM: precipMM,
      dailyWillItRain: dailyWillItRain,
      userConfirmedRain: userConfirmedRain,
    ));

    // Keep only last 30 days AND within valid hours
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final recentValidFeedback = feedbackList
        .where((feedback) =>
    feedback.date.isAfter(thirtyDaysAgo) &&
        feedback.date.hour >= FEEDBACK_START_HOUR &&
        feedback.date.hour <= FEEDBACK_END_HOUR)
        .toList();

    await prefs.setStringList(
        _storageKey,
        recentValidFeedback.map((f) => jsonEncode(f.toJson())).toList()
    );
  }

  Future<void> updateFeedback({
    required DateTime date,
    required bool newUserConfirmedRain
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_storageKey) ?? [];

    final updatedJsonList = jsonList.map((jsonStr) {
      final feedback = RainFeedback.fromJson(jsonDecode(jsonStr));

      // Find the feedback for the specific date
      if (feedback.dateString == "${date.year}-${date.month}-${date.day}") {
        feedback.userConfirmedRain = newUserConfirmedRain;
        feedback.wasEdited = true;
      }

      return jsonEncode(feedback.toJson());
    }).toList();

    await prefs.setStringList(_storageKey, updatedJsonList);
  }

  Future<List<RainFeedback>> getFeedbackHistory() async {
    // Clear invalid feedback before retrieving
    await _clearInvalidFeedback();

    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_storageKey) ?? [];

    return jsonList
        .map((jsonStr) => RainFeedback.fromJson(jsonDecode(jsonStr)))
        .toList();
  }

  Future<double> getAccuracyRate() async {
    // Clear invalid feedback before calculating
    await _clearInvalidFeedback();

    final feedbackList = await getFeedbackHistory();
    if (feedbackList.isEmpty) return 0.0;

    final correctPredictions = feedbackList
        .where((feedback) => feedback.wasCorrect)
        .length;

    return (correctPredictions / feedbackList.length) * 100;
  }

  Future<bool> hasGivenFeedbackToday() async {
    // Clear invalid feedback before checking
    await _clearInvalidFeedback();

    final now = DateTime.now();
    // Only check for feedback within valid hours
    if (now.hour < FEEDBACK_START_HOUR || now.hour > FEEDBACK_END_HOUR) {
      return true;
    }

    final feedbackList = await getFeedbackHistory();

    return feedbackList.any((feedback) =>
    feedback.dateString == "${now.year}-${now.month}-${now.day}"
    );
  }
}

class RainFeedbackWidget extends StatefulWidget {
  final WeatherState weatherState;
  final bool showCityName;

  const RainFeedbackWidget({
    super.key,
    required this.weatherState,
    this.showCityName = false,
  });

  @override
  State<RainFeedbackWidget> createState() => _RainFeedbackWidgetState();
}

class _RainFeedbackWidgetState extends State<RainFeedbackWidget> {
  final RainFeedbackSystem _feedbackSystem = RainFeedbackSystem();
  bool _showingAccuracy = false;
  double _accuracy = 0.0;
  bool _showEditIcon = false;

  int _getChanceOfRain() {
    final now = DateTime.now();
    return widget.weatherState.forecast[0]['hour'][now.hour]['chance_of_rain'] as int;
  }

  int _getDailyWillItRain() {
    final now = DateTime.now();
    return widget.weatherState.forecast[0]['hour'][now.hour]['will_it_rain'] as int;
  }

  double _getPrecipitation() {
    final now = DateTime.now();
    return (widget.weatherState.forecast[0]['hour'][now.hour]['precip_mm'] as num).toDouble();
  }

  Future<void> _handleFeedback(bool wasRaining) async {
    await _feedbackSystem.saveFeedback(
        pop: _getChanceOfRain(),
        precipMM: _getPrecipitation(),
        dailyWillItRain: _getDailyWillItRain(),
        userConfirmedRain: wasRaining
    );

    final accuracy = await _feedbackSystem.getAccuracyRate();

    setState(() {
      _showingAccuracy = true;
      _accuracy = accuracy;
      _showEditIcon = !wasRaining;  // Show edit icon if user says no
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showingAccuracy = false;
          // Optionally keep edit icon visible if it was set to true
        });
      }
    });
  }

  Future<void> _handleEditFeedback() async {
    // Show a dialog to confirm changing feedback
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Rain Feedback'),
        content: const Text('Did it rain after your previous "No" response?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Update the existing feedback
      await _feedbackSystem.updateFeedback(
          date: DateTime.now(),
          newUserConfirmedRain: true
      );

      setState(() {
        _showEditIcon = false;
      });

      // Optional: Show a confirmation snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Feedback updated. Thanks for the correction!',
            style: TextStyle(fontSize: 12.sp),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Only allow feedback between 6 AM and 10 PM
    if (now.hour < RainFeedbackSystem.FEEDBACK_START_HOUR ||
        now.hour > RainFeedbackSystem.FEEDBACK_END_HOUR) {
      return const SizedBox.shrink();
    }

    final pop = _getChanceOfRain();
    final dailyWillItRain = _getDailyWillItRain();

    // Only show feedback widget if:
    // 1. POP is >= threshold
    // 2. dailyWillItRain is 1
    // 3. Not showing city name
    if (pop < RainFeedbackSystem.POP_THRESHOLD ||
        dailyWillItRain != 1 ||
        widget.showCityName) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<bool>(
      future: _feedbackSystem.hasGivenFeedbackToday(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final hasGivenFeedback = snapshot.data ?? true;
        if (hasGivenFeedback && !_showingAccuracy && !_showEditIcon) {
          return const SizedBox.shrink();
        }

        // If showing accuracy
        if (_showingAccuracy) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Accuracy: ${_accuracy.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.blue.shade700,
                height: 1,
              ),
            ),
          );
        }

        // If showing edit icon after saying no
        if (_showEditIcon) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Changed mind?',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppStyle.black,
                  height: 1,
                ),
              ),
              SizedBox(width: 8.sp),
              InkWell(
                onTap: _handleEditFeedback,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: EdgeInsets.all(4.sp),
                  child: Icon(
                    Remix.refresh_line,
                    size: 18.sp,
                    color: Colors.orange.shade600,
                  ),
                ),
              ),
            ],
          );
        }

        // Default to feedback buttons
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Raining?',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppStyle.black,
                height: 1,
              ),
            ),
            SizedBox(width: 8.sp),
            InkWell(
              onTap: () => _handleFeedback(true),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: EdgeInsets.all(4.sp),
                child: Icon(
                  Remix.thumb_up_fill,
                  size: 18.sp,
                  color: Colors.green.shade600,
                ),
              ),
            ),
            SizedBox(width: 4.sp),
            InkWell(
              onTap: () => _handleFeedback(false),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: EdgeInsets.all(4.sp),
                child: Icon(
                  Remix.thumb_down_fill,
                  size: 18.sp,
                  color: Colors.red.shade600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
