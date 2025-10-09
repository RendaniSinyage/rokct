import 'package:flutter/material.dart';
import 'number.dart';
import 'operator.dart';
import 'result.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({Key? key}) : super(key: key);

  @override
  State<CalculatorPage> createState() => CalculatorPageState();
}

class CalculatorPageState extends State<CalculatorPage> {
  List<CalculationResult> history = [];
  CalculationResult currentCalculation = CalculationResult();
  String currentDisplay = '0';
  double memoryValue = 0;

  void addToHistory(CalculationResult result) {
    setState(() {
      if (history.length >= 10) {
        history.removeAt(0);
      }
      history.add(result);
    });
  }

  void onResultButtonPressed(String display) {
    if (display == '=') {
      if (currentCalculation.operator != null &&
          currentCalculation.firstNum != null &&
          currentCalculation.secondNum != null) {
        currentCalculation.result = currentCalculation.operator!.calculate(
            double.parse(currentCalculation.firstNum!),
            double.parse(currentCalculation.secondNum!));
        currentCalculation.complete = true;
        addToHistory(CalculationResult.from(currentCalculation));
        currentCalculation = CalculationResult();
        currentCalculation.firstNum = currentDisplay;
      }
    } else if (display == 'C') {
      currentCalculation = CalculationResult();
      currentDisplay = '0';
    }
    pickCurrentDisplay();
  }

  void clearHistory() {
    setState(() {
      history.clear();
    });
  }

  void onOperatorButtonPressed(CalculatorOperator operator) {
    if (currentCalculation.firstNum != null) {
      if (currentCalculation.operator != null && currentCalculation.secondNum != null) {
        onResultButtonPressed('=');
      }
      currentCalculation.operator = operator;
    }
    pickCurrentDisplay();
  }

  void onNumberButtonPressed(Number number) {
    if (currentCalculation.operator == null) {
      currentCalculation.firstNum = number.apply(currentCalculation.firstNum ?? '0');
    } else {
      currentCalculation.secondNum = number.apply(currentCalculation.secondNum ?? '0');
    }
    pickCurrentDisplay();
  }

  void onMemoryButtonPressed(String operation) {
    double currentValue = double.tryParse(currentDisplay) ?? 0;
    switch (operation) {
      case 'M+':
        memoryValue += currentValue;
        break;
      case 'M-':
        memoryValue -= currentValue;
        break;
      case 'MR':
        setState(() {
          currentDisplay = memoryValue.toString();
          if (currentCalculation.operator == null) {
            currentCalculation.firstNum = currentDisplay;
          } else {
            currentCalculation.secondNum = currentDisplay;
          }
        });
        break;
      case 'MC':
        memoryValue = 0;
        break;
    }
  }

  void pickCurrentDisplay() {
    setState(() {
      if (currentCalculation.result != null) {
        currentDisplay = format(currentCalculation.result!);
      } else if (currentCalculation.secondNum != null) {
        currentDisplay = currentCalculation.secondNum!;
      } else if (currentCalculation.firstNum != null) {
        currentDisplay = currentCalculation.firstNum!;
      } else {
        currentDisplay = '0';
      }
    });
  }

  String format(num number) {
    if (number == number.toInt()) {
      return number.toInt().toString();
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF22252D),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            Navigator.of(context).pop();
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Positioned(
                      top: 10,
                      left: 10,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.6,
                        child: ListView.builder(
                          shrinkWrap: true,
                          reverse: true,
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final result = history[history.length - 1 - index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Text(
                                '${result.firstNum} ${result.operator?.symbol} ${result.secondNum} = ${result.result}',
                                style: TextStyle(color: Colors.grey[500], fontSize: 14),
                                textAlign: TextAlign.right,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          currentDisplay,
                          style: const TextStyle(fontSize: 48, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      buildButtonRow(['MC', 'MR', 'M-', 'M+']),
                      buildButtonRow(['C', '±', '%', '÷']),
                      buildButtonRow(['7', '8', '9', '×']),
                      buildButtonRow(['4', '5', '6', '-']),
                      buildButtonRow(['1', '2', '3', '+']),
                      buildButtonRow(['0', '.', '=']),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildButtonRow(List<String> buttons) {
    return Expanded(
      child: Row(
        children: buttons.map((button) => buildButton(button)).toList(),
      ),
    );
  }

  Widget buildButton(String text) {
    Color buttonColor;
    Color textColor;
    if (['MC', 'MR', 'M-', 'M+'].contains(text)) {
      buttonColor = const Color(0xFF2A2D37);
      textColor = const Color(0xFFFF5A66);
    } else if (['C', '±', '%'].contains(text)) {
      buttonColor = const Color(0xFF2A2D37);
      textColor = const Color(0xFF26F4CE);
    } else if (['÷', '×', '-', '+', '='].contains(text)) {
      buttonColor = const Color(0xFFFF5A66);
      textColor = Colors.white;
    } else {
      buttonColor = const Color(0xFF2A2D37);
      textColor = Colors.white;
    }

    Widget buttonContent = Text(
      text,
      style: TextStyle(fontSize: 20, color: textColor),
    );

    if (text == 'C') {
      return Expanded(
        flex: 1,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: GestureDetector(
            onDoubleTap: clearHistory,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(24),
              ),
              child: buttonContent,
              onPressed: () => onResultButtonPressed(text),
            ),
          ),
        ),
      );
    }

    return Expanded(
      flex: text == '0' ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            shape: text == '0'
                ? const StadiumBorder()
                : const CircleBorder(),
            padding: const EdgeInsets.all(24),
          ),
          child: buttonContent,
          onPressed: () {
            if (['÷', '×', '-', '+'].contains(text)) {
              onOperatorButtonPressed(CalculatorOperator(text));
            } else if (text == '=') {
              onResultButtonPressed(text);
            } else if (text == 'C') {
              onResultButtonPressed(text);
            } else if (['MC', 'MR', 'M-', 'M+'].contains(text)) {
              onMemoryButtonPressed(text);
            } else {
              onNumberButtonPressed(NormalNumber(text));
            }
          },
        ),
      ),
    );
  }
}
