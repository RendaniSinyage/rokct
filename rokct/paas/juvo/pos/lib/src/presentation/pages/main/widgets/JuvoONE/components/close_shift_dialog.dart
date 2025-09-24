import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_desktop/src/core/utils/local_storage.dart';
import 'package:admin_desktop/src/presentation/theme/theme.dart';
import 'package:admin_desktop/src/presentation/pages/main/riverpod/provider/main_provider.dart';

import '../../sale_history/riverpod/sale_history_provider.dart';

class CloseShiftDialog extends ConsumerStatefulWidget {
  final VoidCallback onLogout;

  const CloseShiftDialog({
    Key? key,
    required this.onLogout,
  }) : super(key: key);

  @override
  ConsumerState<CloseShiftDialog> createState() => _CloseShiftDialogState();
}

class _CloseShiftDialogState extends ConsumerState<CloseShiftDialog> {
  final TextEditingController _cashupController = TextEditingController();
  String? _errorMessage;
  bool _showSuccess = false;
  bool _isLoading = true;
  double? _cashSales;
  double? _otherSales;
  double? _totalSales;
  double? _expectedTotal;
  int? _previousIndex;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    // Store current index
    _previousIndex = ref.read(mainProvider).selectIndex;

    // Change to sale history index (4) temporarily
    ref.read(mainProvider.notifier).changeIndex(4);

    // Wait a bit for the state to update
    await Future.delayed(const Duration(milliseconds: 100));

    // Fetch sale history data
    final saleHistoryNotifier = ref.read(saleHistoryProvider.notifier);
    await saleHistoryNotifier.fetchSale();
    await saleHistoryNotifier.fetchSaleCarts();

    _calculateTotals();

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    // Restore previous index if needed
    if (_previousIndex != null) {
      ref.read(mainProvider.notifier).changeIndex(_previousIndex!);
    }
    _cashupController.dispose();
    super.dispose();
  }

  void _calculateTotals() {
    final saleHistoryState = ref.read(saleHistoryProvider);

    // Get cash and other payment sales from saleCart
    _cashSales = saleHistoryState.saleCart?.cash ?? 0;
    _otherSales = saleHistoryState.saleCart?.other ?? 0;

    // Calculate total sales (cash + other payments)
    _totalSales = _cashSales! + _otherSales!;

    // Calculate expected total (float + cash sales only)
    final floatAmount = LocalStorage.getFloatAmount();
    _expectedTotal = floatAmount + _cashSales!;
  }

  void _handleCashup() {
    if (_cashupController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter cashup amount';
      });
      return;
    }

    double cashupAmount = double.parse(_cashupController.text);
    double difference = cashupAmount - (_expectedTotal ?? 0);

    if (difference == 0) {
      setState(() {
        _showSuccess = true;
        _errorMessage = null;
      });

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.of(context).pop();
        widget.onLogout();
      });
    } else {
      final formattedDifference = difference.abs().toStringAsFixed(2);
      final currencySymbol = LocalStorage.getSelectedCurrency().symbol;
      setState(() {
        _errorMessage = difference > 0
            ? 'Over by $currencySymbol $formattedDifference'
            : 'Short by $currencySymbol $formattedDifference';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = LocalStorage.getSelectedCurrency().symbol;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Close Shift',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppStyle.black,
                ),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                const SizedBox.shrink(),
    /* Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppStyle.bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Float Amount: $currencySymbol ${LocalStorage.getFloatAmount().toStringAsFixed(2)}',
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                  const SizedBox(height: 8),
                     Text(
                        'Cash Sales: $currencySymbol ${_cashSales?.toStringAsFixed(2) ?? "0.00"}',
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Card/Other Sales: $currencySymbol ${_otherSales?.toStringAsFixed(2) ?? "0.00"}',
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total Sales: $currencySymbol ${_totalSales?.toStringAsFixed(2) ?? "0.00"}',
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Divider(color: AppStyle.black.withOpacity(0.1)),
                      const SizedBox(height: 12),
                      Text(
                        'Expected Cash in Drawer: $currencySymbol ${_expectedTotal?.toStringAsFixed(2) ?? "0.00"}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),*/
              if (_showSuccess) ...[
                Center(
                  child: Icon(
                    Icons.check_circle,
                    color: AppStyle.brandGreen,
                    size: 48,
                  ),
                ),
              ] else if (!_isLoading) ...[
                TextFormField(
                  controller: _cashupController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Enter Cash in Drawer',
                    errorText: _errorMessage,
                    prefix: Text(
                      '$currencySymbol ',
                      style: const TextStyle(color: AppStyle.black),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onLogout();
                    },
                    child: Text(
                      'Skip',
                      style: GoogleFonts.inter(
                        color: AppStyle.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!_showSuccess && !_isLoading)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyle.brandGreen,
                      ),
                      onPressed: _handleCashup,
                      child: Text(
                        'Submit',
                        style: GoogleFonts.inter(
                          color: AppStyle.white,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
