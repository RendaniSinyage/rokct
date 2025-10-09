import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:audioplayers/audioplayers.dart';

import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/core/utils/app_helpers.dart';
import 'package:admin_desktop/src/core/utils/local_storage.dart';
import 'package:admin_desktop/src/models/data/bag_data.dart';
import 'package:admin_desktop/src/models/data/location_data.dart';
import 'package:admin_desktop/src/models/data/order_body_data.dart';
import 'package:admin_desktop/src/presentation/pages/main/riverpod/notifier/main_notifier.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/orders_table/orders/new/new_orders_provider.dart';
import 'package:admin_desktop/src/presentation/theme/app_style.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/JuvoONE/components/quick_sale.dart';

import '../../../../components/components.dart';
import '../orders_table/orders/accepted/accepted_orders_provider.dart';
import '../right_side/riverpod/right_side_notifier.dart';
import '../right_side/riverpod/right_side_state.dart';

class PriceInfo extends ConsumerStatefulWidget {
  final BagData bag;
  final RightSideState state;
  final RightSideNotifier notifier;
  final MainNotifier mainNotifier;

  const PriceInfo({
    super.key,
    required this.state,
    required this.notifier,
    required this.bag,
    required this.mainNotifier,
  });

  @override
  ConsumerState<PriceInfo> createState() => _PriceInfoState();
}

class _PriceInfoState extends ConsumerState<PriceInfo> {
  bool _showNeedFund = false;
  bool _showAllItems = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _playWrongSound() async {
    if (AppConstants.sound) {
      await _audioPlayer.play(AssetSource('sounds/wrong.wav'));
    }
  }

  @override
  Widget build(BuildContext context) {
    num totalPrice = widget.state.paginateResponse?.totalPrice ?? 0;
    double enteredAmount = double.tryParse(widget.state.calculate) ?? 0;
    double refundAmount = enteredAmount - totalPrice;
    bool showRefund = enteredAmount > 0;
    bool canConfirmOrder = showRefund && (refundAmount >= 0);
    bool needMoreFunds = enteredAmount < totalPrice;

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
          _handleConfirmOrder(canConfirmOrder);
        }
      },
      child: Column(
        children: [
          20.verticalSpace,
          _buildFeeRows(),
          20.verticalSpace,
          _buildTotalRow(TrKeys.totalPrice, totalPrice),
          if (showRefund && !needMoreFunds) ...[
            20.verticalSpace,
            _buildTotalRow(TrKeys.refund, refundAmount),
          ],
          if (_showNeedFund && needMoreFunds) ...[
            20.verticalSpace,
            Text(
              AppHelpers.getTranslation(TrKeys.needFund),
              style: GoogleFonts.inter(
                color: AppStyle.red,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
              ),
            ),
          ],
          32.verticalSpace,
          LoginButton(
            isLoading: widget.state.isOrderLoading,
            title: AppHelpers.getTranslation(TrKeys.confirmOrder),
            onPressed: () => _handleConfirmOrder(canConfirmOrder),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRows() {
    return Column(
      children: [
        _buildFeeRow(TrKeys.subtotal, widget.state.paginateResponse?.price ?? 0),
        _buildFeeRow(TrKeys.tax, widget.state.paginateResponse?.totalTax ?? 0),
        _buildFeeRow(TrKeys.serviceFee, widget.state.paginateResponse?.serviceFee ?? 0),
        _buildFeeRow(TrKeys.deliveryFee, widget.state.paginateResponse?.deliveryFee ?? 0),
        _buildFeeRow(TrKeys.discount, -(widget.state.paginateResponse?.totalDiscount ?? 0), isDiscount: true),
        if ((widget.state.paginateResponse?.couponPrice ?? 0) != 0)
          _buildFeeRow(TrKeys.promoCode, -(widget.state.paginateResponse?.couponPrice ?? 0), isDiscount: true),
      ],
    );
  }

  Widget _buildFeeRow(String key, num amount, {bool isDiscount = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppHelpers.getTranslation(key),
            style: GoogleFonts.inter(
              color: AppStyle.black,
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.4,
            ),
          ),
          Text(
            intl.NumberFormat.currency(
              symbol: widget.bag.selectedCurrency?.symbol ??
                  LocalStorage.getSelectedCurrency().symbol,
            ).format(amount),
            style: GoogleFonts.inter(
              color: isDiscount ? AppStyle.red : AppStyle.black,
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String key, num amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppHelpers.getTranslation(key),
          style: GoogleFonts.inter(
            color: AppStyle.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
        ),
        Text(
          intl.NumberFormat.currency(
            symbol: widget.bag.selectedCurrency?.symbol ??
                LocalStorage.getSelectedCurrency().symbol,
          ).format(amount),
          style: GoogleFonts.inter(
            color: AppStyle.black,
            fontSize: 22.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }

  void _handleConfirmOrder(bool canConfirmOrder) async {
    if (canConfirmOrder) {
      widget.notifier.createOrder(
        context,
        OrderBodyData(
          bagData: widget.bag,
          coupon: widget.state.coupon,
          phone: widget.state.selectedUser?.phone ?? "",
          note: widget.state.comment,
          userId: widget.state.selectedUser?.id ?? 0,
          deliveryFee: (widget.state.paginateResponse?.deliveryFee ?? 0),
          deliveryType: widget.state.orderType,
          location: widget.state.selectedAddress?.location ??
              LocationData(latitude: 0, longitude: 0),
          address: AddressModel(address: widget.state.selectedAddress?.address),
          deliveryDate: intl.DateFormat("yyyy-MM-dd")
              .format(widget.state.orderDate ?? DateTime.now()),
          deliveryTime: widget.state.orderTime != null
              ? (widget.state.orderTime!.hour.toString().length == 2
              ? "${widget.state.orderTime!.hour}:${widget.state.orderTime!.minute.toString().padLeft(2, '0')}"
              : "0${widget.state.orderTime!.hour}:${widget.state.orderTime!.minute.toString().padLeft(2, '0')}")
              : (TimeOfDay.now().hour.toString().length == 2
              ? "${TimeOfDay.now().hour}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}"
              : "0${TimeOfDay.now().hour}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}"),
          currencyId: widget.state.currencies
              .firstWhere((element) => element.isDefault ?? false)
              .id ??
              0,
          rate: widget.state.selectedCurrency?.rate ?? 0,
        ),
        onSuccess: () {
          ref.read(newOrdersProvider.notifier).fetchNewOrders(isRefresh: true);
          ref.read(acceptedOrdersProvider.notifier).fetchAcceptedOrders(isRefresh: true);
          widget.mainNotifier.setPriceDate(null);

          // Show thank you in QuickSale button
          QuickSale.globalKey.currentState?.showThankYou();

          // Only show dialog if not in JuvoONE mode or if cooker
          final user = LocalStorage.getUser();
          if (user?.role == TrKeys.cooker || !AppConstants.enableJuvoONE) {
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (BuildContext dialogContext) {
                Future.delayed(const Duration(seconds: 5), () {
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                });

                return AlertDialog(
                  content: Container(
                    width: 200.w,
                    height: 200.w,
                    padding: EdgeInsets.all(30.r),
                    decoration: BoxDecoration(
                      color: AppStyle.white,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppStyle.primary,
                            shape: BoxShape.circle,
                          ),
                          padding: EdgeInsets.all(12.r),
                          child: Icon(
                            Icons.check,
                            size: 56.r,
                            color: AppStyle.black,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          AppHelpers.getTranslation(TrKeys.thankYouForOrder),
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 22.r,
                              color: AppStyle.black
                          ),
                          textAlign: TextAlign.center,
                        )
                      ],
                    ),
                  ),
                  backgroundColor: AppStyle.transparent,
                );
              },
            );
          }
        },
      );
    } else {
      await _playWrongSound();
      setState(() {
        _showNeedFund = true;
      });
    }
  }
}
