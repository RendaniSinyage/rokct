import 'package:flutter/material.dart';

import '../../../../../../core/constants/tr_keys.dart';
import '../../../../../../core/utils/app_helpers.dart';
import '../../../../../components/buttons/confirm_button.dart';
import '../../../../../theme/app_style.dart';
import '../utils/open_cash_drawer.dart';

class CashDrawerButton extends StatelessWidget {
  const CashDrawerButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CashDrawerConfig>>(
      future: CashDrawerManager.getConfigurations(),
      builder: (context, snapshot) {
        bool isEnabled = snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data!.isNotEmpty;

        if (!isEnabled) {
          return const SizedBox.shrink();
        }

        return ConfirmButton(
          onTap: () async {
            try {
              await CashDrawerManager.openCashDrawer(snapshot.data!.first);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cash drawer opened successfully')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to open cash drawer: $e')),
              );
            }
          },
          title: AppHelpers.getTranslation(TrKeys.cashDrawer),
          isActive: true,
          bgColor: AppStyle.primary,
          textColor: AppStyle.white,
        );
      },
    );
  }
}
