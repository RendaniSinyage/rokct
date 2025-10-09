import 'package:admin_desktop/src/core/constants/tr_keys.dart';
import 'package:admin_desktop/src/core/utils/app_helpers.dart';
import 'package:admin_desktop/src/models/data/edit_shop_data.dart';
import 'package:admin_desktop/src/presentation/components/login_button.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/edit_shop/riverpod/shop_provider.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/profile/edit_profile/riverpod/provider/edit_profile_provider.dart';
import 'package:admin_desktop/src/presentation/theme/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:multi_dropdown/models/value_item.dart';
import '../../right_side/address/riverpod/select_address_provider.dart';

class DeliveryTimeWidget extends ConsumerWidget {
  final List<ValueItem> selectedCategory;
  final List<ValueItem> selectedTag;
  final List<ValueItem> selectedType;
  final GlobalKey<FormState> formKey;

  const DeliveryTimeWidget(
      {super.key,
      required this.selectedTag,
      required this.selectedCategory,
      required this.selectedType,
      required this.formKey});

  @override
  Widget build(BuildContext context, ref) {
    final state = ref.watch(shopProvider);
    final notifier = ref.read(shopProvider.notifier);
    final profileNotifier = ref.read(editProfileProvider.notifier);
    List<ShopWorkingDays> workingDays =
        state.editShopData?.shopWorkingDays ?? [];

    void setTimeToDay({
      required TimeOfDay time,
      bool isFrom = true,
      required int currentIndex,
    }) {
      if (isFrom) {
        workingDays[currentIndex] = workingDays[currentIndex].copyWith(
          from:
              '${time.hour.toString().padLeft(2, '0')}-${time.minute.toString().padLeft(2, '0')}',
        );
      } else {
        workingDays[currentIndex] = workingDays[currentIndex].copyWith(
          to: '${time.hour.toString().padLeft(2, '0')}-${time.minute.toString().padLeft(2, '0')}',
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        18.verticalSpace,
        const Divider(),
        18.verticalSpace,
        Text(
          AppHelpers.getTranslation(TrKeys.workingHours),
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 22.r),
        ),
        18.verticalSpace,
        Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: AppStyle.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              width: 1.r,
              style: BorderStyle.solid,
              color: AppStyle.border,
            ),
          ),
          child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: state.editShopData?.shopWorkingDays?.length ?? 0,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    12.verticalSpace,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                            width: (MediaQuery.sizeOf(context).width - 100) / 8,
                            child: Text(
                              AppHelpers.getTranslation(workingDays[index].day ?? ""),
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w400, fontSize: 22.r),
                            )),
                        workingDays[index].disabled ?? false
                            ? Text(
                                AppHelpers.getTranslation(TrKeys.shopClosed),
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 18.r),
                              )
                            : SizedBox(
                                width:
                                    (MediaQuery.sizeOf(context).width - 100) /
                                        3,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      height: 36.h,
                                      width: 140.w,
                                      child: CupertinoDatePicker(
                                        key: UniqueKey(),
                                        mode: CupertinoDatePickerMode.time,
                                        initialDateTime: DateTime(
                                          2024,
                                          1,
                                          1,
                                          int.parse(workingDays[index]
                                                  .from
                                                  ?.substring(0, 2) ??
                                              ''),
                                          int.parse(workingDays[index]
                                                  .from
                                                  ?.substring(3, 5) ??
                                              ''),
                                        ),
                                        onDateTimeChanged:
                                            (DateTime newDateTime) {
                                          setTimeToDay(
                                            time: TimeOfDay.fromDateTime(
                                                newDateTime),
                                            currentIndex: index,
                                          );
                                        },
                                        use24hFormat: true,
                                        minuteInterval: 1,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 36.h,
                                      width: 140.w,
                                      child: CupertinoDatePicker(
                                        key: UniqueKey(),
                                        mode: CupertinoDatePickerMode.time,
                                        initialDateTime: DateTime(
                                          2024,
                                          1,
                                          1,
                                          int.parse(workingDays[index]
                                                  .to
                                                  ?.substring(0, 2) ??
                                              ''),
                                          int.parse(workingDays[index]
                                                  .to
                                                  ?.substring(3, 5) ??
                                              ''),
                                        ),
                                        onDateTimeChanged:
                                            (DateTime newDateTime) {
                                          setTimeToDay(
                                              time: TimeOfDay.fromDateTime(
                                                  newDateTime),
                                              currentIndex: index,
                                              isFrom: false);
                                        },
                                        use24hFormat: true,
                                        minuteInterval: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        CupertinoSwitch(
                            value: workingDays[index].disabled ?? false,
                            onChanged: (s) {
                              notifier.setCloseDay(index);
                            })
                      ],
                    ),
                    12.verticalSpace,
                    if (index < (workingDays.length) - 1) const Divider(),
                  ],
                );
              }),
        ),
        40.verticalSpace,
        SizedBox(
          width: 250.w,
          child: LoginButton(
              isLoading: state.isSave,
              title: AppHelpers.getTranslation(TrKeys.save),
              onPressed: () async {
                final stateLocation = ref.watch(selectAddressProvider);
                if (formKey.currentState?.validate() ?? false) {
                  await notifier.updateWorkingDays(
                      days: workingDays,
                      shopUuid: state.editShopData?.uuid ?? "");
                  await notifier.updateShopData(
                      displayName: stateLocation.textController?.text,
                      location: stateLocation.location,
                      category: selectedCategory,
                      tag: selectedTag,
                      type: selectedType,
                      onSuccess: () {
                        profileNotifier.setShopEdit(0);
                      });
                }
              }),
        )
      ],
    );
  }
}

