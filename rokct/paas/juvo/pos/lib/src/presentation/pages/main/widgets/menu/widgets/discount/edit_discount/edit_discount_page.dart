import 'package:admin_desktop/src/presentation/theme/theme.dart';
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
import '../../../../income/widgets/custom_date_picker.dart';
import '../add_discount/widgets/product_multiselection.dart';
import '../add_discount/widgets/type_drop_down.dart';
import '../riverpod/discount/discount_provider.dart';
import '../riverpod/discount/edit_discount/edit_discount_provider.dart';

class EditDiscountPage extends ConsumerStatefulWidget {
  final int id;
  const EditDiscountPage(this.id, {super.key});

  @override
  ConsumerState<EditDiscountPage> createState() => _EditDiscountPageState();
}

class _EditDiscountPageState extends ConsumerState<EditDiscountPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref
          .read(editDiscountProvider.notifier)
          .fetchDiscountDetails(context: context, id: widget.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDisable(
      child: Scaffold(
        backgroundColor: AppStyle.white,
        body: Consumer(
          builder: (context, ref, child) {
            final state = ref.watch(editDiscountProvider);
            final event = ref.read(editDiscountProvider.notifier);
            return state.discount == null || state.isLoading
                ? const Loading()
                : SafeArea(
                    child: Padding(
                      padding: REdgeInsets.symmetric(horizontal: 16),
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    AppHelpers.getTranslation(
                                        TrKeys.editDiscount),
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
                              24.verticalSpace,
                              Row(
                                children: [
                                  Expanded(
                                    child: SingleImagePicker(
                                      //isEdit: true,
                                      height:
                                          MediaQuery.sizeOf(context).height / 6,
                                      width: MediaQuery.sizeOf(context).height / 6,
                                      isAdding: state.discount?.img == null,
                                      imageFilePath: state.imageFile,
                                      imageUrl: state.discount?.img,
                                      onImageChange: event.setImageFile,
                                      onDelete: () => event.setImageFile(null),
                                    ),
                                  ),
                                  24.horizontalSpace,
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppHelpers.getTranslation(
                                              TrKeys.status),
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w500
                                          ),
                                        ),
                                        CustomToggle(
                                          controller:
                                              ValueNotifier(state.active),
                                          onChange: (c) => event
                                              .changeActive(!(state.active)),
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
                                      onTap: (value) => event.setActiveIndex(value!),
                                      typeValue: state.discount?.type,
                                      label: AppHelpers.getTranslation(TrKeys.type),
                                    ),
                                  ),
                                  16.horizontalSpace,
                                  Expanded(
                                    child: OutlinedBorderTextField(
                                      label:
                                      '${AppHelpers.getTranslation(TrKeys.price)}${state.type != "fixed" ? "%" : ""}*',
                                      initialText: "${state.discount?.price ?? 0}",
                                      textInputAction: TextInputAction.next,
                                      onChanged: event.setPrice,
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
                                readOnly: true,
                                label:
                                    '${AppHelpers.getTranslation(TrKeys.startDate)} - ${AppHelpers.getTranslation(TrKeys.endDate)}',
                                inputType: TextInputType.number,
                                onTap: () {
                                  AppHelpers.showAlertDialog(
                                    context: context,
                                    child: SizedBox(
                                      height:
                                          MediaQuery.sizeOf(context).height / 3,
                                      width:
                                          MediaQuery.sizeOf(context).width / 3,
                                      child: CustomDatePicker(
                                        range: const [],
                                        onChange: event.setDate,
                                      ),
                                    ),
                                  );
                                },
                                textInputAction: TextInputAction.next,
                                onChanged: event.setPrice,
                                validator: AppValidators.emptyCheck,
                              ),
                              24.verticalSpace,
                              GestureDetector(
                                onTap: () {
                                  AppHelpers.showAlertDialog(
                                      context: context,
                                      child: SizedBox(
                                        height:
                                            MediaQuery.sizeOf(context).height /
                                                2,
                                        width:
                                            MediaQuery.sizeOf(context).width /
                                                3,
                                        child: const MultiSelectionWidget(
                                            isEdit: true),
                                      ));
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
                                          AppHelpers.getTranslation(
                                              TrKeys.select),
                                          style: GoogleFonts.inter(
                                              fontSize: 14.sp,
                                              color: AppStyle.colorGrey,
                                              fontWeight: FontWeight.w500
                                          ),
                                        )
                                      : ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: state.stocks.length,
                                          itemBuilder: (BuildContext context,
                                              int index) {
                                            return Chip(
                                              backgroundColor: AppStyle.primary,
                                              deleteIcon: Icon(
                                                FlutterRemix.close_circle_fill,
                                                size: 20.r,
                                                color: AppStyle.white,
                                              ),
                                              onDeleted: () =>
                                                  event.deleteFromAddedProducts(
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
                                              (BuildContext context,
                                                  int index) {
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
                                  if (_formKey.currentState?.validate() ??
                                      false) {
                                    event.updateDiscount(context, updated: () {
                                      ref
                                          .read(discountProvider.notifier)
                                          .fetchDiscounts(
                                              context: context,
                                              isRefresh: true);
                                      Navigator.pop(context);
                                    });
                                  }
                                },
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
          },
        ),
      ),
    );
  }
}

