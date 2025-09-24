import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/constants/constants.dart';

final dateRangeProvider = StateNotifierProvider<DateRangeNotifier, DateRangeState>((ref) {
  return DateRangeNotifier();
});

class DateRangeState {
  final DateTime? start;
  final DateTime? end;
  final String selectedType;

  const DateRangeState({
    this.start,
    this.end,
    this.selectedType = TrKeys.week, // Default to day
  });

  DateRangeState copyWith({
    DateTime? start,
    DateTime? end,
    String? selectedType,
  }) {
    return DateRangeState(
      start: start ?? this.start,
      end: end ?? this.end,
      selectedType: selectedType ?? this.selectedType,
    );
  }
}

class DateRangeNotifier extends StateNotifier<DateRangeState> {
  DateRangeNotifier() : super(const DateRangeState());

  void updateDateRange({
    DateTime? start,
    DateTime? end,
    String? type,
  }) {
    DateTime calculatedStart;
    DateTime calculatedEnd = end ?? DateTime.now();

    // Calculate start date based on type if not provided
    if (start != null) {
      calculatedStart = start;
    } else {
      switch (type ?? state.selectedType) {
        case TrKeys.day:
          calculatedStart = calculatedEnd;
          break;

        case TrKeys.week:
        // Find the most recent Monday
          int daysToSubtract = (calculatedEnd.weekday - DateTime.monday) % 7;
          calculatedStart = DateTime(
            calculatedEnd.year,
            calculatedEnd.month,
            calculatedEnd.day - daysToSubtract,
          );
          break;

        case TrKeys.month:
        // Get the first day of the current month
          DateTime firstDayOfMonth = DateTime(
            calculatedEnd.year,
            calculatedEnd.month,
            1,
          );

          // Calculate days passed in the current month
          int daysPassed = calculatedEnd.difference(firstDayOfMonth).inDays;

          // If we've passed 3 weeks (21 days) and we're still in the same month
          if (daysPassed >= 21 && calculatedEnd.month == firstDayOfMonth.month) {
            calculatedStart = firstDayOfMonth;
          } else {
            // Less than 3 weeks passed or we're looking at a past month
            // Go back 30 days
            calculatedStart = calculatedEnd.subtract(const Duration(days: 30));
          }
          break;

        default:
          calculatedStart = calculatedEnd;
      }
    }

    state = state.copyWith(
      start: calculatedStart,
      end: calculatedEnd,
      selectedType: type ?? state.selectedType,
    );
  }
}
