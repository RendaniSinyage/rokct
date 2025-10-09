// ignore_for_file: must_be_immutable
import 'dart:io';

import 'package:admin_desktop/src/presentation/pages/main/widgets/right_side/riverpod/right_side_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:auto_route/auto_route.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/core/utils/app_helpers.dart';
import 'package:admin_desktop/src/core/utils/app_validators.dart';
import 'package:admin_desktop/src/core/utils/local_storage.dart';
import 'package:admin_desktop/src/models/data/bag_data.dart';
import 'package:admin_desktop/src/presentation/components/components.dart';
import 'package:admin_desktop/src/presentation/components/text_fields/custom_date_time_field.dart';

import '../../../../theme/theme.dart';
import '../../riverpod/provider/main_provider.dart';
import '../JuvoONE/components/payment_dialog.dart';
import '../income/widgets/custom_date_picker.dart';
import 'address/select_address_page.dart';
import 'address/select_address_page_desktop.dart';
import 'riverpod/right_side_notifier.dart';
import 'riverpod/right_side_provider.dart';

class OrderInformation extends ConsumerWidget {
  OrderInformation({super.key});

  final List<String> listOfType = [
    TrKeys.delivery,
    TrKeys.pickup,
    TrKeys.dine,
  ];

  final formKey = GlobalKey<FormState>();

  bool canPlaceOrder(BuildContext context, RightSideState state) {
    if (state.selectedPayment == null) {
      AppHelpers.showSnackBar(
        context,
        AppHelpers.getTranslation(TrKeys.selectPayment),
      );
      return false;
    }

    if (state.selectedCurrency == null) {
      AppHelpers.showSnackBar(
        context,
        AppHelpers.getTranslation(TrKeys.selectCurrency),
      );
      return false;
    }

    // Only check for phone number if a user is selected and phone validation is required
    if (state.selectedUser != null &&
        AppHelpers.isNumberRequiredToOrder() &&
        state.selectedUser?.phone == null &&
        !(formKey.currentState?.validate() ?? false)) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(rightSideProvider.notifier);
    final state = ref.watch(rightSideProvider);
    final BagData bag = state.bags[state.selectedBagIndex];

    // Auto-select default currency if none is selected and currencies are available
    if (state.selectedCurrency == null && state.currencies.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.setSelectedCurrency(state.currencies.first.id);
      });
    }

    // Auto-select cash payment if available and no payment method is selected
    if (state.selectedPayment == null && state.payments.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final cashPayment = state.payments.firstWhere(
              (payment) => payment.tag?.toLowerCase() == 'cash',
          orElse: () => state.payments.first,
        );
        notifier.setSelectedPayment(cashPayment.id);
      });
    }

    bool isDesktop() {
      return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    }

    return KeyboardDismisser(
      child: Container(
        width: MediaQuery.of(context).size.width / 2,
        padding: REdgeInsets.symmetric(horizontal: 24.r),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          color: AppStyle.white,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    AppHelpers.getTranslation(TrKeys.order),
                    style: GoogleFonts.inter(
                        fontSize: 22.r, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      context.maybePop();
                    },
                    icon: const Icon(FlutterRemix.close_line,
                        color: AppStyle.black),
                  )
                ],
              ),
              16.verticalSpace,
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (state.orderType == TrKeys.delivery)
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: AppStyle.unselectedBottomBarBack,
                                width: 1.r,
                              ),
                            ),
                            alignment: Alignment.center,
                            height: 56.r,
                            padding: EdgeInsets.only(left: 16.r),
                            child: CustomDropdown(
                              hintText:
                              AppHelpers.getTranslation(TrKeys.selectUser),
                              searchHintText:
                              AppHelpers.getTranslation(TrKeys.searchUser),
                              dropDownType: DropDownType.users,
                              onChanged: (value) =>
                                  notifier.setUsersQuery(context, value),
                              initialValue: bag.selectedUser?.firstname ?? '',
                            ),
                          ),
                        if (state.orderType == TrKeys.delivery)
                          Visibility(
                            visible: state.selectUserError != null,
                            child: Padding(
                              padding: EdgeInsets.only(top: 6.r, left: 4.r),
                              child: Text(
                                AppHelpers.getTranslation(
                                    state.selectUserError ?? ""),
                                style: GoogleFonts.inter(
                                    color: AppStyle.red, fontSize: 14.sp),
                              ),
                            ),
                          ),
                        if (state.orderType == TrKeys.delivery)
                          26.verticalSpace,
                        PopupMenuButton<int>(
                          itemBuilder: (context) {
                            return state.currencies
                                .map(
                                  (currency) => PopupMenuItem<int>(
                                value: currency.id,
                                child: Text(
                                  '${currency.title}(${currency.symbol})',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14.sp,
                                    color: AppStyle.black,
                                    letterSpacing: -14 * 0.02,
                                  ),
                                ),
                              ),
                            )
                                .toList();
                          },
                          onSelected: notifier.setSelectedCurrency,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          color: AppStyle.white,
                          elevation: 10,
                          child: SelectFromButton(
                            title: state.selectedCurrency?.title ??
                                (state.currencies.length == 1
                                    ? '${state.currencies.first.title}(${state.currencies.first.symbol})'
                                    : AppHelpers.getTranslation(
                                    TrKeys.selectCurrency)),
                          ),
                        ),
                        Visibility(
                          visible: state.selectCurrencyError != null,
                          child: Padding(
                            padding: EdgeInsets.only(top: 6.r, left: 4.r),
                            child: Text(
                              AppHelpers.getTranslation(
                                  state.selectCurrencyError ?? ""),
                              style: GoogleFonts.inter(
                                  color: AppStyle.red, fontSize: 14.sp),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  16.horizontalSpace,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (state.orderType == TrKeys.delivery)
                          PopupMenuButton(
                            initialValue: state.selectedAddress?.address ?? "",
                            itemBuilder: (context) {
                              AppHelpers.showAlertDialog(
                                  width:
                                  MediaQuery.of(context).size.width - 30.w,
                                  context: context,
                                  child: SizedBox(
                                    child: (isDesktop())
                                        ? SelectAddressDesktopPage(
                                      location:
                                      state.selectedAddress?.location,
                                      onSelect: (address) {
                                        notifier.setSelectedAddress(
                                            address: address);
                                        ref
                                            .read(rightSideProvider
                                            .notifier)
                                            .fetchCarts(
                                            checkYourNetwork: () {
                                              AppHelpers.showSnackBar(
                                                context,
                                                AppHelpers.getTranslation(
                                                    TrKeys
                                                        .checkYourNetworkConnection),
                                              );
                                            },
                                            isNotLoading: true);
                                      },
                                    )
                                        : SelectAddressPage(
                                      location:
                                      state.selectedAddress?.location,
                                      onSelect: (address) {
                                        notifier.setSelectedAddress(
                                            address: address);
                                        ref
                                            .read(rightSideProvider
                                            .notifier)
                                            .fetchCarts(
                                            checkYourNetwork: () {
                                              AppHelpers.showSnackBar(
                                                context,
                                                AppHelpers.getTranslation(
                                                    TrKeys
                                                        .checkYourNetworkConnection),
                                              );
                                            },
                                            isNotLoading: true);
                                      },
                                    ),
                                  ),
                                  backgroundColor: AppStyle.white
                              );

                              return [];
                            },
                            onSelected: (s) => notifier.setSelectedAddress(),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            color: AppStyle.white,
                            elevation: 10,
                            child: SelectFromButton(
                              title: state.selectedAddress?.address ??
                                  AppHelpers.getTranslation(
                                      TrKeys.selectAddress),
                            ),
                          ),
                        if (state.orderType == TrKeys.delivery)
                          Visibility(
                            visible: state.selectAddressError != null,
                            child: Padding(
                              padding: EdgeInsets.only(top: 6.r, left: 4.r),
                              child: Text(
                                AppHelpers.getTranslation(
                                    state.selectAddressError ?? ""),
                                style: GoogleFonts.inter(
                                    color: AppStyle.red, fontSize: 14.sp),
                              ),
                            ),
                          ),
                        if (state.orderType == TrKeys.delivery)
                          26.verticalSpace,
                        PopupMenuButton<int>(
                          itemBuilder: (context) {
                            return state.payments.map((payment) {
                              return PopupMenuItem<int>(
                                value: payment.id,
                                child: Text(
                                  payment.tag == 'terminal'
                                      ? 'Card Terminal'
                                      : AppHelpers.getTranslation(
                                      payment.tag ?? ""),
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14.sp,
                                    color: AppStyle.black,
                                    letterSpacing: -14 * 0.02,
                                  ),
                                ),
                              );
                            }).toList();
                          },
                          onSelected: notifier.setSelectedPayment,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          color: AppStyle.white,
                          elevation: 10,
                          child: SelectFromButton(
                            title: AppHelpers.getTranslation(
                                state.selectedPayment?.isTerminal == true
                                    ? "terminal"
                                    : state.selectedPayment?.tag ??
                                    TrKeys.selectPayment),
                          ),
                        ),
                        Visibility(
                          visible: state.selectPaymentError != null,
                          child: Padding(
                            padding: EdgeInsets.only(top: 6.r, left: 4.r),
                            child: Text(
                              AppHelpers.getTranslation(
                                  state.selectPaymentError ?? ""),
                              style: GoogleFonts.inter(
                                  color: AppStyle.red, fontSize: 14.sp),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              16.verticalSpace,
              if (AppHelpers.isNumberRequiredToOrder() &&
                  state.selectedUser != null &&
                  (state.selectedUser?.phone?.isEmpty ?? true))
                Form(
                  key: formKey,
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          inputType: TextInputType.phone,
                          validator: (value) {
                            return AppValidators.emptyCheck(value);
                          },
                          onChanged: (p0) {
                            notifier.setPhone(p0);
                          },
                          label: AppHelpers.getTranslation(TrKeys.phoneNumber),
                        ),
                      ),
                    ],
                  ),
                ),
              12.verticalSpace,
              if (state.orderType == TrKeys.delivery)
                Row(
                  children: [
                    Expanded(
                      child: PopupMenuButton<int>(
                        itemBuilder: (context) {
                          AppHelpers.showAlertDialog(
                            width: MediaQuery.of(context).size.width / 3,
                            context: context,
                            backgroundColor: AppStyle.white,
                            child: CustomDatePicker(
                              range: state.orderDate != null ? [state.orderDate] : [],
                              onChange: (dates) {
                                if (dates.isNotEmpty && dates.first != null) {
                                  notifier.setDate(dates.first!);
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          );
                          return [];
                        },
                        onSelected: (s) {},
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        color: AppStyle.white,
                        elevation: 10,
                        child: SelectFromButton(
                          title: state.orderDate == null
                              ? AppHelpers.getTranslation(TrKeys.selectDeliveryDate)
                              : DateFormat("MMM dd").format(state.orderDate ?? DateTime.now()),
                        ),
                      ),
                    ),
                    16.horizontalSpace,
                    Expanded(
                      child: PopupMenuButton<int>(
                        itemBuilder: (context) {
                          showTimePicker(
                            context: context,
                            initialTime: state.orderTime ?? TimeOfDay.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  timePickerTheme: TimePickerThemeData(
                                    backgroundColor: AppStyle.white,
                                    hourMinuteTextStyle: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      letterSpacing: -0.3,
                                      color: AppStyle.black,
                                    ),
                                    dayPeriodTextStyle: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      letterSpacing: -0.3,
                                      color: AppStyle.black,
                                    ),
                                    helpTextStyle: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      letterSpacing: -0.3,
                                      color: AppStyle.black,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                  ),
                                  colorScheme: ColorScheme.light(
                                    primary: AppStyle.primary,
                                    onPrimary: AppStyle.white,
                                    surface: AppStyle.white,
                                    onSurface: AppStyle.black,
                                  ),
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      textStyle: GoogleFonts.inter(
                                        fontSize: 14.sp,
                                        letterSpacing: -0.3,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      foregroundColor: AppStyle.black,
                                    ),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          ).then((time) {
                            if (time != null) {
                              notifier.setTime(time);
                            }
                          });
                          return [];
                        },
                        onSelected: (s) {},
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        color: AppStyle.white,
                        elevation: 10,
                        child: SelectFromButton(
                          title: state.orderTime == null
                              ? AppHelpers.getTranslation(TrKeys.selectDeliveryTime)
                              : "${state.orderTime?.format(context)}",
                        ),
                      ),
                    ),
                  ],
                ),
              if (state.orderType == TrKeys.delivery) 24.verticalSpace,
              const Divider(),
              24.verticalSpace,
              Text(
                AppHelpers.getTranslation(TrKeys.shippingInformation),
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, fontSize: 22.r),
              ),
              16.verticalSpace,
              Row(
                children: [
                  ...listOfType.map((e) => Expanded(
                    child: InkWell(
                      onTap: () {
                        notifier.setSelectedOrderType(e);
                        if (state.orderType.toLowerCase() !=
                            e.toString().toLowerCase()) {
                          ref.read(rightSideProvider.notifier).fetchCarts(
                              checkYourNetwork: () {
                                AppHelpers.showSnackBar(
                                  context,
                                  AppHelpers.getTranslation(
                                      TrKeys.checkYourNetworkConnection),
                                );
                              },
                              isNotLoading: true);
                        }
                      },
                      child: AnimationButtonEffect(
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 4.r),
                          decoration: BoxDecoration(
                            color: state.orderType.toLowerCase() ==
                                e.toString().toLowerCase()
                                ? AppStyle.primary
                                : AppStyle.editProfileCircle,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 10.r),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppStyle.transparent,
                                    shape: BoxShape.circle,
                                    border:
                                    Border.all(color: AppStyle.black),
                                  ),
                                  padding: EdgeInsets.all(6.r),
                                  child: e == TrKeys.delivery
                                      ? Icon(
                                    FlutterRemix.takeaway_fill,
                                    size: 18.sp,
                                  )
                                      : e == TrKeys.pickup
                                      ? SvgPicture.asset(
                                      "assets/svg/pickup.svg")
                                      : SvgPicture.asset(
                                      "assets/svg/dine.svg"),
                                ),
                                8.horizontalSpace,
                                Text(
                                  AppHelpers.getTranslation(e),
                                  style: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )),
                ],
              ),
              12.verticalSpace,
              const Divider(),
              20.verticalSpace,
              _priceInformation(
                state: state,
                notifier: notifier,
                bag: bag,
                context: context,
                ref: ref,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priceInformation({
    required RightSideState state,
    required RightSideNotifier notifier,
    required BagData bag,
    required BuildContext context,
    required WidgetRef ref,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppHelpers.getTranslation(TrKeys.subtotal),
              style: GoogleFonts.inter(
                color: AppStyle.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              NumberFormat.currency(
                symbol: bag.selectedCurrency?.symbol ??
                    LocalStorage.getSelectedCurrency().symbol,
              ).format(state.paginateResponse?.price ?? 0),
              style: GoogleFonts.inter(
                color: AppStyle.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        12.verticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppHelpers.getTranslation(TrKeys.tax),
              style: GoogleFonts.inter(
                color: AppStyle.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              AppHelpers.numberFormat(
                state.paginateResponse?.totalTax,
                symbol: bag.selectedCurrency?.symbol,
              ),
              style: GoogleFonts.inter(
                color: AppStyle.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        12.verticalSpace,
        if (state.paginateResponse?.serviceFee != null)
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppHelpers.getTranslation(TrKeys.serviceFee),
                    style: GoogleFonts.inter(
                      color: AppStyle.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.4,
                    ),
                  ),
                  Text(
                    AppHelpers.numberFormat(
                      state.paginateResponse?.serviceFee,
                      symbol: bag.selectedCurrency?.symbol,
                    ),
                    style: GoogleFonts.inter(
                      color: AppStyle.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              12.verticalSpace,
            ],
          ),
        if (state.orderType == TrKeys.delivery)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppHelpers.getTranslation(TrKeys.deliveryFee),
                style: GoogleFonts.inter(
                  color: AppStyle.black,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                AppHelpers.numberFormat(
                  state.paginateResponse?.deliveryFee,
                  symbol: bag.selectedCurrency?.symbol,
                ),
                style: GoogleFonts.inter(
                  color: AppStyle.black,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        if (state.orderType == TrKeys.delivery) 12.verticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppHelpers.getTranslation(TrKeys.discount),
              style: GoogleFonts.inter(
                color: AppStyle.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              "-${AppHelpers.numberFormat(
                state.paginateResponse?.totalDiscount,
                symbol: bag.selectedCurrency?.symbol,
              )}",
              style: GoogleFonts.inter(
                color: AppStyle.red,
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        12.verticalSpace,
        if (state.paginateResponse?.couponPrice != 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppHelpers.getTranslation(TrKeys.promoCode),
                style: GoogleFonts.inter(
                  color: AppStyle.black,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                "-${AppHelpers.numberFormat(
                  state.paginateResponse?.couponPrice,
                  symbol: bag.selectedCurrency?.symbol,
                )}",
                style: GoogleFonts.inter(
                  color: AppStyle.red,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        const Divider(),
        20.verticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 186.w,
              child: LoginButton(
                title: AppHelpers.getTranslation(TrKeys.placeOrder),
                onPressed: () async {
                  if (!canPlaceOrder(context, state)) {
                    return;
                  }


                  // Place the order
                  notifier.placeOrder(
                    context: context,
                    checkYourNetwork: () {
                      AppHelpers.showSnackBar(
                        context,
                        AppHelpers.getTranslation(
                            TrKeys.checkYourNetworkConnection),
                      );
                    },
                    openSelectDeliveriesDrawer: () {
                      ref
                          .read(mainProvider.notifier)
                          .setPriceDate(state.paginateResponse);
                      context.maybePop();
                    },
                  );
                },
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppHelpers.getTranslation(TrKeys.totalPrice),
                  style: GoogleFonts.inter(
                    color: AppStyle.black,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  AppHelpers.numberFormat(
                    state.paginateResponse?.totalPrice,
                    symbol: bag.selectedCurrency?.symbol,
                  ),
                  style: GoogleFonts.inter(
                    color: AppStyle.black,
                    fontSize: 30.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

