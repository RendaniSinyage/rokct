// ignore_for_file: must_be_immutable
import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/core/utils/app_helpers.dart';
import 'package:admin_desktop/src/core/utils/app_validators.dart';
import 'package:admin_desktop/src/presentation/components/components.dart';
import 'package:admin_desktop/src/presentation/components/custom_edit_profile_widget.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/edit_shop/riverpod/shop_provider.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/profile/edit_profile/riverpod/provider/edit_profile_provider.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/right_side/status_note.dart';
import 'package:admin_desktop/src/presentation/theme/theme.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:multi_dropdown/multiselect_dropdown.dart';
import '../../../../components/custom_scaffold.dart';
import 'select_map.dart';
import 'widget/delivery_time.dart';

class EditShop extends ConsumerStatefulWidget {
  const EditShop({
    super.key,
  });

  @override
  ConsumerState<EditShop> createState() => _EditShopState();
}

class _EditShopState extends ConsumerState<EditShop> {
  List<ValueItem> selectedType = [];
  List<ValueItem> selectedCategory = [];
  List<ValueItem> selectedTag = [];
  List<ValueItem> categoryItem = [];
  List<ValueItem> tagItem = [];
  MultiSelectController controller = MultiSelectController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        if (ref.watch(shopProvider).isUpdate) {
          ref.read(shopProvider.notifier).fetchShopData(onSuccess: () {
            final state = ref.watch(shopProvider);
            state.categories?.data?.forEach((element) {
              categoryItem.add(ValueItem(
                  label: element.translation?.title ?? "",
                  value: element.id.toString()));
            });
            state.editShopData?.categoryData?.forEach((element) {
              selectedCategory.add(ValueItem(
                  label: element.translation?.title ?? "",
                  value: element.id.toString()));
            });

            state.tag?.data?.forEach((element) {
              tagItem.add(ValueItem(
                  label: element.translation?.title ?? "",
                  value: element.id.toString()));
            });
          });
        }
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(shopProvider.notifier);
    final profileNotifier = ref.read(editProfileProvider.notifier);
    final state = ref.watch(shopProvider);

    return CustomScaffold(
        body: (colors) => Padding(
              padding:
                  REdgeInsets.only(left: 18, top: 24, bottom: 18, right: 18),
              child: Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.r),
                  color: AppStyle.white,
                ),
                child: state.isEditShopData
                    ? const Loading()
                    : SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              8.verticalSpace,
                              Row(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      profileNotifier.setShopEdit(0);
                                      context.maybePop();
                                    },
                                    child: Icon(
                                      FlutterRemix.arrow_left_s_line,
                                      size: 32.r,
                                    ),
                                  ),
                                  14.horizontalSpace,
                                  Text(
                                    AppHelpers.getTranslation(TrKeys.editShop),
                                    style: GoogleFonts.inter(
                                        fontSize: 28.r,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  const Spacer(),
                                  ConfirmButton(
                                      isActive: false,
                                      isTab: true,
                                      title: state.editShopData?.status ?? "",
                                      onTap: () {
                                        AppHelpers.showAlertDialog(
                                            context: context,
                                            child: const StatusNoteDialog());
                                      })
                                ],
                              ),
                              32.verticalSpace,
                              Row(
                                children: [
                                  10.horizontalSpace,
                                  Expanded(
                                    child: Column(
                                      children: [
                                        CustomEditWidget(
                                            isLoading: state.isLogoImageLoading,
                                            height: 140,
                                            width: (MediaQuery.sizeOf(context)
                                                    .width) /
                                                2,
                                            radius: 16,
                                            image:
                                                state.editShopData?.logoImg ??
                                                    "",
                                            imagePath: state.logoImagePath,
                                            isEmptyorNot:
                                                state.logoImagePath.isEmpty,
                                            isEmptyorNot2:
                                                state.logoImagePath.isNotEmpty,
                                            localStoreImage:
                                                state.editShopData?.logoImg ??
                                                    "",
                                            onthisTap: () {
                                              notifier.getPhoto(
                                                  isLogoImage: true,
                                                  context: context);
                                            }),
                                        8.verticalSpace,
                                        Text(AppHelpers.getTranslation(
                                            TrKeys.logoImage))
                                      ],
                                    ),
                                  ),
                                  40.horizontalSpace,
                                  Expanded(
                                    child: Column(
                                      children: [
                                        CustomEditWidget(
                                            isLoading: state.isBackImageLoading,
                                            height: 140,
                                            width: (MediaQuery.sizeOf(context)
                                                    .width) /
                                                2,
                                            radius: 16,
                                            image: state.editShopData
                                                    ?.backgroundImg ??
                                                "",
                                            imagePath: state.backImagePath,
                                            isEmptyorNot:
                                                state.backImagePath.isEmpty,
                                            isEmptyorNot2:
                                                state.backImagePath.isNotEmpty,
                                            localStoreImage: state.editShopData
                                                    ?.backgroundImg ??
                                                "",
                                            onthisTap: () {
                                              notifier.getPhoto(
                                                  context: context);
                                            }),
                                        8.verticalSpace,
                                        Text(AppHelpers.getTranslation(
                                            TrKeys.backgroundImage))
                                      ],
                                    ),
                                  ),
                                  10.horizontalSpace
                                ],
                              ),
                              16.verticalSpace,
                              Text(
                                AppHelpers.getTranslation(TrKeys.generalInfo),
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 22.r),
                              ),
                              16.verticalSpace,
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        OutlinedBorderTextField(
                                          initialText: state
                                              .editShopData?.translation?.title,
                                          validator: AppValidators.emptyCheck,
                                          label: AppHelpers.getTranslation(
                                              TrKeys.title),
                                          onChanged: notifier.setTitle,
                                        ),
                                        12.verticalSpace,
                                        OutlinedBorderTextField(
                                          validator: AppValidators.emptyCheck,
                                          initialText:
                                              state.editShopData?.phone,
                                          label: AppHelpers.getTranslation(
                                              TrKeys.phone),
                                          onChanged: notifier.setPhone,
                                        ),
                                        12.verticalSpace,
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(AppHelpers.getTranslation(
                                                TrKeys.shopTag)),
                                            4.verticalSpace,
                                            MultiSelectDropDown(
                                              borderColor: AppStyle.border,
                                              borderRadius: 10,
                                              onOptionSelected: (List<ValueItem>
                                                  selectedOptions) {
                                                selectedTag = selectedOptions;
                                              },
                                              options: tagItem,
                                              selectedOptions: selectedTag,
                                              selectionType:
                                                  SelectionType.multi,
                                              dropdownHeight: 220.h,
                                              optionTextStyle:
                                                  const TextStyle(fontSize: 16),
                                              selectedOptionIcon: const Icon(
                                                  Icons.check_circle),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  12.horizontalSpace,
                                  Expanded(
                                    child: Column(
                                      children: [
                                        OutlinedBorderTextField(
                                          maxLine: 6,
                                          initialText: state.editShopData
                                              ?.translation?.description,
                                          onChanged: notifier.setDescription,
                                          label: AppHelpers.getTranslation(
                                              TrKeys.description),
                                        ),
                                        16.verticalSpace,
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(AppHelpers.getTranslation(
                                                TrKeys.categories)),
                                            4.verticalSpace,
                                            MultiSelectDropDown(
                                              borderColor: AppStyle.border,
                                              borderRadius: 10,
                                              onOptionSelected: (List<ValueItem>
                                                  selectedOptions) {
                                                selectedCategory =
                                                    selectedOptions;
                                              },
                                              options: categoryItem,
                                              selectedOptions: selectedCategory,
                                              selectionType:
                                                  SelectionType.multi,
                                              dropdownHeight: 220.h,
                                              optionTextStyle:
                                                  const TextStyle(fontSize: 16),
                                              selectedOptionIcon: const Icon(
                                                  Icons.check_circle),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                              18.verticalSpace,
                              const Divider(),
                              18.verticalSpace,
                              Row(
                                children: [
                                  Text(
                                    AppHelpers.getTranslation(
                                        TrKeys.shippingInformation),
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 22.r),
                                  ),
                                  const Spacer(),
                                  ConfirmButton(
                                      title: AppHelpers.getTranslation(
                                          TrKeys.editMap),
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return const SelectMap();
                                          },
                                        );
                                      })
                                ],
                              ),
                              18.verticalSpace,
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                      child: Column(
                                    children: [
                                      OutlinedBorderTextField(
                                        inputType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly
                                        ],
                                        validator: AppValidators.emptyCheck,
                                        initialText: state.editShopData?.price
                                            .toString(),
                                        label: AppHelpers.getTranslation(
                                            TrKeys.minPrice),
                                        onChanged: notifier.setPrice,
                                      ),
                                      12.verticalSpace,
                                      OutlinedBorderTextField(
                                        inputType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly
                                        ],
                                        validator: AppValidators.emptyCheck,
                                        initialText: state
                                            .editShopData?.deliveryTime?.from,
                                        label: AppHelpers.getTranslation(
                                            TrKeys.deliveryTimeFrom),
                                        onChanged: notifier.setFrom,
                                      ),
                                      12.verticalSpace,
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(AppHelpers.getTranslation(
                                              TrKeys.deliveryTimeType)),
                                          4.verticalSpace,
                                          MultiSelectDropDown(
                                            hintStyle:
                                                const TextStyle(fontSize: 16),
                                            borderColor: AppStyle.border,
                                            borderRadius: 10,
                                            onOptionSelected: (List<ValueItem>
                                                selectedOptions) {
                                              selectedType = selectedOptions;
                                            },
                                            selectedOptions: selectedType,
                                            options: [
                                              ValueItem(
                                                  label:
                                                      AppHelpers.getTranslation(
                                                          TrKeys.hour),
                                                  value: "hour"),
                                              ValueItem(
                                                  label:
                                                      AppHelpers.getTranslation(
                                                          TrKeys.minut),
                                                  value: "minute")
                                            ],
                                            selectionType: SelectionType.single,
                                            dropdownHeight: 220.h,
                                            optionTextStyle:
                                                const TextStyle(fontSize: 16),
                                            selectedOptionIcon:
                                                const Icon(Icons.check_circle),
                                          ),
                                        ],
                                      ),
                                      12.verticalSpace,
                                      OutlinedBorderTextField(
                                        inputType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly
                                        ],
                                        validator: AppValidators.emptyCheck,
                                        initialText:
                                            "${state.editShopData?.tax}",
                                        label: AppHelpers.getTranslation(
                                            TrKeys.tax),
                                        onChanged: notifier.setTax,
                                      ),
                                    ],
                                  )),
                                  12.horizontalSpace,
                                  Expanded(
                                      child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      OutlinedBorderTextField(
                                        inputType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly
                                        ],
                                        validator: AppValidators.emptyCheck,
                                        initialText:
                                            "${state.editShopData?.perKm ?? ''}",
                                        label: AppHelpers.getTranslation(
                                            TrKeys.perKm),
                                        onChanged: notifier.setPerKm,
                                      ),
                                      12.verticalSpace,
                                      OutlinedBorderTextField(
                                        inputType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly
                                        ],
                                        validator: AppValidators.emptyCheck,
                                        initialText: state
                                            .editShopData?.deliveryTime?.to,
                                        label: AppHelpers.getTranslation(
                                            TrKeys.deliveryTimeTo),
                                        onChanged: notifier.setTo,
                                      ),
                                      12.verticalSpace,
                                      OutlinedBorderTextField(
                                        inputType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly
                                        ],
                                        validator: AppValidators.emptyCheck,
                                        initialText: state
                                            .editShopData?.minAmount
                                            .toString(),
                                        label: AppHelpers.getTranslation(
                                            TrKeys.minAmount),
                                        onChanged: notifier.setAmount,
                                      ),
                                      12.verticalSpace,
                                    ],
                                  )),
                                ],
                              ),
                              DeliveryTimeWidget(
                                selectedCategory: selectedCategory,
                                selectedTag: selectedTag,
                                selectedType: selectedType,
                                formKey: _formKey,
                              )
                            ],
                          ),
                        ),
                      ),
              ),
            ));
  }
}

