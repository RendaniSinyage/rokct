import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../../theme/theme.dart';
import 'rain_feedback.dart';
import 'service/weather_state.dart';

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
