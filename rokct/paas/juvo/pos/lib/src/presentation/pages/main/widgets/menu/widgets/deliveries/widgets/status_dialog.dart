import 'package:admin_desktop/src/presentation/pages/main/widgets/menu/widgets/deliveries/riverpod/deliveryman_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/core/utils/app_helpers.dart';
import '../../../../../../../components/buttons/button_effect_animation.dart';
import '../../../../../../../components/components.dart';
import '../../../../../../../components/custom_checkbox.dart';

class StatusDialog extends ConsumerWidget {
  final String status;
  final int? id;

  const StatusDialog({super.key, required this.status, this.id});

  @override
  Widget build(BuildContext context, ref) {
    final state = ref.watch(deliverymanProvider);
    final notifier = ref.read(deliverymanProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < AppHelpers.getMasterStatuses(status).length; i++)
          Padding(
            padding: REdgeInsets.only(bottom: 8),
            child: ButtonEffectAnimation(
              onTap: () => notifier.setStatusIndex(i),
              child: Row(
                children: [
                  CustomCheckbox(
                    isActive: i == state.statusIndex,
                    onTap: () => notifier.setStatusIndex(i),
                  ),
                  6.horizontalSpace,
                  Text(AppHelpers.getTranslation(
                      AppHelpers.getMasterStatuses(status)[i])),
                ],
              ),
            ),
          ),
        16.verticalSpace,
        CustomButton(
            // height: 44,
            title: TrKeys.save,
            isLoading: state.isUpdate,
            onTap: () {
              if (state.statusIndex == -1) {
                return;
              }
              notifier.updateStatus(
                  id: id,
                  status:
                      AppHelpers.getMasterStatuses(status)[state.statusIndex],
                  onSuccess: (index) {
                    ref.read(deliverymanProvider.notifier).fetchDeliverymen(isRefresh: true,);
                    Navigator.pop(context);
                  });
            }),
      ],
    );
  }
}

