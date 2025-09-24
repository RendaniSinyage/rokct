class CalculatorOperator {
  final String symbol;

  CalculatorOperator(this.symbol);

  num calculate(num first, num second) {
    switch (symbol) {
      case '÷':
        return first / second;
      case '×':
        return first * second;
      case '-':
        return first - second;
      case '+':
        return first + second;
      default:
        return 0;
    }
  }
}
