import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/core/utils/app_helpers.dart';
import 'package:admin_desktop/src/core/utils/app_validators.dart';
import 'package:admin_desktop/src/core/utils/input_formatter.dart';
import '../../../../../../../components/components.dart';
import '../../../../../../../components/custom_toggle.dart';
import '../../../../../../../components/single_image_picker.dart';
import 'package:admin_desktop/src/presentation/theme/theme.dart';
import '../../../../income/widgets/custom_date_picker.dart';
import '../riverpod/discount/add_discount/add_discount_provider.dart';
import '../riverpod/discount/discount_provider.dart';
import 'widgets/product_multiselection.dart';
import 'widgets/type_drop_down.dart';

class AddDiscountPage extends ConsumerStatefulWidget {
  const AddDiscountPage({super.key});

  @override
  ConsumerState<AddDiscountPage> createState() => _AddDiscountPageState();
}

class _AddDiscountPageState extends ConsumerState<AddDiscountPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(addDiscountProvider.notifier).clear());
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDisable(
      child: Scaffold(
        backgroundColor: AppStyle.white,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppHelpers.getTranslation(TrKeys.addDiscount),
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 22.sp,
                      color: AppStyle.black),
                ),
                const Spacer(),
                IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(FlutterRemix.close_fill))
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: REdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                child: Consumer(
                  builder: (context, ref, child) {
                    final state = ref.watch(addDiscountProvider);
                    final notifier = ref.read(addDiscountProvider.notifier);
                    return Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          16.verticalSpace,
                          Row(
                            children: [
                              Expanded(
                                child: SingleImagePicker(
                                  height: MediaQuery.sizeOf(context).height / 6,
                                  width: MediaQuery.sizeOf(context).height / 6,
                                  imageFilePath: state.imageFile,
                                  onImageChange: notifier.setImageFile,
                                  onDelete: () => notifier.setImageFile(null),
                                ),
                              ),
                              30.horizontalSpace,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppHelpers.getTranslation(TrKeys.status),
                                      style: GoogleFonts.inter(),
                                    ),
                                    6.verticalSpace,
                                    CustomToggle(
                                      controller: ValueNotifier(state.active),
                                      onChange: (c) =>
                                          notifier.setActive(!(state.active)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          24.verticalSpace,
                          Row(
                            children: [
                              Expanded(
                                child: DiscountTypeDropDown(
                                  onTap: (value) =>
                                      notifier.setActiveIndex(value!),
                                  label: AppHelpers.getTranslation(TrKeys.type),
                                ),
                              ),
                              16.horizontalSpace,
                              Expanded(
                                child: OutlinedBorderTextField(
                                  label:
                                      '${AppHelpers.getTranslation(TrKeys.price)}${state.type != "fixed" ? "%" : ""}*',
                                  inputType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  onChanged: notifier.setPrice,
                                  validator: AppValidators.emptyCheck,
                                  inputFormatters: [
                                    InputFormatter.currency
                                  ],
                                ),
                              ),
                            ],
                          ),
                          24.verticalSpace,
                          OutlinedBorderTextField(
                            textController: state.dateController,
                            label:       '${AppHelpers.getTranslation(TrKeys.startDate)} - ${AppHelpers.getTranslation(TrKeys.endDate)}',
                            inputType: TextInputType.number,
                            onTap: () {
                              AppHelpers.showAlertDialog(
                                context: context,
                                child: SizedBox(
                                  height: MediaQuery.sizeOf(context).height / 3,
                                  width: MediaQuery.sizeOf(context).width / 3,
                                  child: CustomDatePicker(
                                    onChange: notifier.setDate, range: const [],
                                  ),
                                ),
                              );
                            },
                            textInputAction: TextInputAction.next,
                            onChanged: notifier.setPrice,
                            validator: AppValidators.emptyCheck,
                          ),
                          24.verticalSpace,
                          GestureDetector(
                            onTap: () {
                              AppHelpers.showAlertDialog(
                                  context: context,
                                  child: SizedBox(
                                      height:
                                          MediaQuery.sizeOf(context).height / 2,
                                      width:
                                          MediaQuery.sizeOf(context).width / 3,
                                      child: const MultiSelectionWidget()));
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                          color: AppStyle.colorGrey,
                                          width: 0.5.r))),
                              height: 40.r,
                              width: MediaQuery.sizeOf(context).width,
                              child: state.stocks.isEmpty
                                  ? Text(
                                      AppHelpers.getTranslation(TrKeys.select),
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14, color: AppStyle.colorGrey),
                                    )
                                  : ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: state.stocks.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        return Chip(
                                          backgroundColor: AppStyle.primary,
                                          deleteIcon: Icon(
                                            FlutterRemix.close_circle_fill,
                                            size: 20.r,
                                            color: AppStyle.white,
                                          ),
                                          onDeleted: () =>
                                              notifier.deleteFromAddedProducts(
                                                  state.stocks[index].id),
                                          label: Text(
                                            state.stocks[index].product
                                                    ?.translation?.title ??
                                                "",
                                            style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w500,
                                                color: AppStyle.white),
                                          ),
                                        );
                                      },
                                      separatorBuilder:
                                          (BuildContext context, int index) {
                                        return 10.horizontalSpace;
                                      },
                                    ),
                            ),
                          ),
                          56.verticalSpace,
                          CustomButton(
                            background: AppStyle.primary,
                            textColor: AppStyle.white,
                            title: AppHelpers.getTranslation(TrKeys.save),
                            isLoading: state.isLoading,
                            onTap: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                notifier.createDiscount(context, created: () {
                                  //widget.onSave();
                                  ref
                                      .read(discountProvider.notifier)
                                      .fetchDiscounts(
                                          context: context, isRefresh: true);
                                  context.maybePop();
                                }, onError: () {});
                              }
                            },
                          ),
                          20.verticalSpace,
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

