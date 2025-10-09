import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/calculator_provider.dart';

class CalculatorWidget extends ConsumerWidget {
  const CalculatorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calculatorProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Calculator')),
      body: Column(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.all(16),
              child: Text(
                state.display,
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            children: [
              _buildButton('7', ref),
              _buildButton('8', ref),
              _buildButton('9', ref),
              _buildButton('÷', ref, isOperation: true),
              _buildButton('4', ref),
              _buildButton('5', ref),
              _buildButton('6', ref),
              _buildButton('×', ref, isOperation: true),
              _buildButton('1', ref),
              _buildButton('2', ref),
              _buildButton('3', ref),
              _buildButton('-', ref, isOperation: true),
              _buildButton('C', ref, onPressed: () => ref.read(calculatorProvider.notifier).clear()),
              _buildButton('0', ref),
              _buildButton('=', ref, onPressed: () => ref.read(calculatorProvider.notifier).calculateResult()),
              _buildButton('+', ref, isOperation: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String label, WidgetRef ref, {bool isOperation = false, VoidCallback? onPressed}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isOperation ? Colors.orange : Colors.grey[300],
        foregroundColor: isOperation ? Colors.white : Colors.black,
      ),
      onPressed: onPressed ?? () {
        if (isOperation) {
          ref.read(calculatorProvider.notifier).setOperation(label);
        } else {
          ref.read(calculatorProvider.notifier).addDigit(label);
        }
      },
      child: Text(label, style: const TextStyle(fontSize: 24)),
    );
  }
}
