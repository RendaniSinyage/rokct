import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/calculator_state.dart';

class CalculatorNotifier extends StateNotifier<CalculatorState> {
  CalculatorNotifier() : super(const CalculatorState());

  void addDigit(String digit) {
    if (state.display == '0' || state.display == 'Error') {
      state = state.copyWith(display: digit);
    } else {
      state = state.copyWith(display: state.display + digit);
    }
  }

  void clear() {
    state = const CalculatorState();
  }

  void setOperation(String operation) {
    try {
      double currentValue = double.parse(state.display);
      state = state.copyWith(
        previousValue: currentValue,
        currentOperation: operation,
        display: '0',
      );
    } catch (e) {
      state = state.copyWith(display: 'Error');
    }
  }

  void calculateResult() {
    try {
      double currentValue = double.parse(state.display);
      double? result;

      switch (state.currentOperation) {
        case '+':
          result = state.previousValue! + currentValue;
          break;
        case '-':
          result = state.previousValue! - currentValue;
          break;
        case '×':
          result = state.previousValue! * currentValue;
          break;
        case '÷':
          if (currentValue == 0) {
            throw Exception('Division by zero');
          }
          result = state.previousValue! / currentValue;
          break;
      }

      state = state.copyWith(
        display: result.toString(),
        currentOperation: '',
        previousValue: null,
      );
    } catch (e) {
      state = state.copyWith(display: 'Error');
    }
  }
}

final calculatorProvider =
StateNotifierProvider<CalculatorNotifier, CalculatorState>(
        (ref) => CalculatorNotifier());
