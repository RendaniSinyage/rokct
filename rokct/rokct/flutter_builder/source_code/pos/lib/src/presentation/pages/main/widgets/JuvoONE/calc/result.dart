import 'operator.dart';

class CalculationResult {
  String? firstNum;
  String? secondNum;
  CalculatorOperator? operator;
  num? result;
  bool complete = false;

  CalculationResult();

  CalculationResult.from(CalculationResult other) {
    firstNum = other.firstNum;
    secondNum = other.secondNum;
    operator = other.operator;
    result = other.result;
    complete = other.complete;
  }
}
