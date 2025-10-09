import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter_beep/flutter_beep.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/core/utils/app_helpers.dart';
import 'package:admin_desktop/src/core/utils/local_storage.dart';
import 'package:admin_desktop/src/models/data/addons_data.dart';
import 'package:admin_desktop/src/presentation/components/buttons/animation_button_effect.dart';
import 'package:admin_desktop/src/presentation/components/common_image.dart';
import 'package:admin_desktop/src/presentation/pages/main/riverpod/notifier/main_notifier.dart';
import 'package:admin_desktop/src/presentation/pages/main/riverpod/provider/main_provider.dart';
import 'package:admin_desktop/src/presentation/pages/main/riverpod/state/main_state.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/order_calculate/price_info.dart';
import 'package:admin_desktop/src/core/utils/second_screen_service.dart';

import '../../../../../models/data/product_data.dart';
import '../../../../theme/theme.dart';
import '../right_side/riverpod/right_side_notifier.dart';
import '../right_side/riverpod/right_side_provider.dart';
import '../right_side/riverpod/right_side_state.dart';

class OrderCalculate extends ConsumerStatefulWidget {
  const OrderCalculate({super.key});

  @override
  ConsumerState<OrderCalculate> createState() => _OrderCalculateState();
}

class _OrderCalculateState extends ConsumerState<OrderCalculate> {
  late FocusNode _focusNode;
  bool _isDesktop = false;
  final List<AudioPlayer> _audioPlayers = [];
  int _currentPlayerIndex = 0;
  static const int _maxAudioPlayers = 5;
  bool _showAllItems = false;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  void _initializeState() {
    _focusNode = FocusNode();
    _isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    _initializeAudioPlayers();
    _setupInitialFocus();
  }

  void _initializeAudioPlayers() {
    if (_isDesktop) {
      for (int i = 0; i < _maxAudioPlayers; i++) {
        _audioPlayers.add(AudioPlayer());
      }
    }
  }

  void _setupInitialFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rightSideProvider.notifier).clearCalculate();
      FocusScope.of(context).requestFocus(_focusNode);
      ref.read(secondScreenProvider.notifier).updateState(
        SecondScreenState(
          isOrderCalculateActive: true,
          showBlankScreen: false,
        ),
      );
      _updateSecondScreen(ref.read(rightSideProvider));
    });
  }

  @override
  void dispose() {
    _cleanupResources();
    super.dispose();
  }

  void _cleanupResources() {
    _focusNode.dispose();
    for (var player in _audioPlayers) {
      player.dispose();
    }
    _resetSecondScreen();
  }

  void _resetSecondScreen() {
    ref.read(secondScreenProvider.notifier).updateState(
      SecondScreenState(
        isOrderCalculateActive: false,
        showBlankScreen: true,
      ),
    );
    ref.read(secondScreenServiceProvider).broadcastUpdate(ref.read(secondScreenProvider));
  }

  Future<void> _playTapSound() async {
    if (AppConstants.sound) {
      if (_isDesktop) {
        final player = _audioPlayers[_currentPlayerIndex];
        await player.play(AssetSource('sounds/tap.wav'));
        _currentPlayerIndex = (_currentPlayerIndex + 1) % _maxAudioPlayers;
      } else {
        await FlutterBeep.beep(false);
      }
    }
  }

  void _handleKeyPress(RawKeyEvent event, RightSideNotifier rightSideNotifier) {
    if (event is RawKeyDownEvent) {
      _playTapSound();
      if (_isDeleteKey(event)) {
        rightSideNotifier.clearCalculate();
      } else {
        _handleCharacterInput(event.character, rightSideNotifier);
      }
      _updateSecondScreen(rightSideNotifier.state);
    }
  }

  bool _isDeleteKey(RawKeyEvent event) {
    return event.logicalKey == LogicalKeyboardKey.backspace ||
        event.logicalKey == LogicalKeyboardKey.delete;
  }

  void _handleCharacterInput(String? character, RightSideNotifier rightSideNotifier) {
    if (character != null) {
      if (character == '.') {
        // Only add decimal if there isn't one already
        if (!rightSideNotifier.state.calculate.contains('.')) {
          rightSideNotifier.setCalculate(".");
        }
      } else {
        final int? number = int.tryParse(character);
        if (number != null) {
          final currentValue = rightSideNotifier.state.calculate;

          // If current value is "0" and a new number is typed, replace the "0"
          if (currentValue == "0") {
            rightSideNotifier.clearCalculate();
          }

          rightSideNotifier.setCalculate(number.toString());
        }
      }
    }
  }

  void _updateSecondScreen(RightSideState state) {
    final totalPrice = calculateTotalPrice(state);
    final amountReceived = double.tryParse(state.calculate) ?? 0;
    final change = amountReceived - totalPrice;

    final secondScreenState = SecondScreenState(
      totalPrice: totalPrice,
      amountReceived: amountReceived,
      change: change,
      currency: state.currencies.firstWhere((element) => element.isDefault ?? false).symbol ?? '',
      isOrderCalculateActive: true,
      showBlankScreen: false,
    );

    ref.read(secondScreenProvider.notifier).updateState(secondScreenState);
    ref.read(secondScreenServiceProvider).broadcastUpdate(secondScreenState);
  }

  double calculateTotalPrice(RightSideState state) {
    return state.paginateResponse?.stocks?.fold(0, (sum, stock) => sum! + (stock.totalPrice ?? 0)) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(mainProvider.notifier);
    final rightNotifier = ref.read(rightSideProvider.notifier);
    final state = ref.read(mainProvider);
    final stateRight = ref.watch(rightSideProvider);

    ref.listen(rightSideProvider, (previous, next) {
      _updateSecondScreen(next);
    });

    final secondScreenUrl = ref.watch(secondScreenServiceProvider).secondScreenUrl;

    return Scaffold(
      backgroundColor: AppStyle.mainBack,
      body: Column(
        children: [
          if (AppConstants.secondScreen && secondScreenUrl.isNotEmpty)
            _buildSecondScreenUrlDisplay(secondScreenUrl),
          Expanded(
            child: _buildMainContent(notifier, rightNotifier, state, stateRight),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondScreenUrlDisplay(String url) {
    return Padding(
      padding: EdgeInsets.all(8.r),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Second Screen URL: ',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          SelectableText(
            url,
            style: GoogleFonts.inter(color: AppStyle.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(
      MainNotifier notifier,
      RightSideNotifier rightNotifier,
      MainState state,
      RightSideState stateRight,
      ) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: (event) => _handleKeyPress(event, rightNotifier),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _informationWidget(notifier, rightNotifier, state, stateRight),
            16.horizontalSpace,
            calculator(stateRight, rightNotifier)
          ],
        ),
      ),
    );
  }

  Widget _informationWidget(
      MainNotifier notifier,
      RightSideNotifier rightSideNotifier,
      MainState state,
      RightSideState stateRight,
      ) {
    final items = stateRight.paginateResponse?.stocks ?? [];
    final displayCount = _showAllItems ? items.length : items.length.clamp(0, 3);

    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(notifier, rightSideNotifier),
            16.verticalSpace,
            _buildOrderDetails(stateRight, items, displayCount, rightSideNotifier, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(MainNotifier notifier, RightSideNotifier rightSideNotifier) {
    return Row(
      children: [
        InkWell(
          onTap: () => notifier.setPriceDate(null),
          child: Row(
            children: [
              Icon(
                FlutterRemix.arrow_left_s_line,
                size: 32.r,
                color: AppStyle.black,
              ),
              Text(
                AppHelpers.getTranslation(TrKeys.back),
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  color: AppStyle.black,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: () => rightSideNotifier.fetchCarts(),
          child: AnimationButtonEffect(
            child: Container(
              decoration: BoxDecoration(
                color: AppStyle.white,
                borderRadius: BorderRadius.circular(10.r),
              ),
              padding: EdgeInsets.all(8.r),
              child: Icon(
                FlutterRemix.restart_line,
                color: AppStyle.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetails(
      RightSideState stateRight,
      List<ProductData> items,
      int displayCount,
      RightSideNotifier rightSideNotifier,
      MainNotifier notifier,
      ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.r, horizontal: 16.r),
      decoration: BoxDecoration(
        color: AppStyle.white,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderHeader(stateRight),
          _buildItemsList(items, displayCount, stateRight),
          if (items.length > 3 && !_showAllItems)
            _buildViewMoreButton(items.length - 3),
          if (_showAllItems && items.length > 3)
            _buildViewLessButton(),
          const Divider(),
          PriceInfo(
            bag: stateRight.bags[stateRight.selectedBagIndex],
            state: stateRight,
            notifier: rightSideNotifier,
            mainNotifier: notifier,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHeader(RightSideState stateRight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppHelpers.getTranslation(TrKeys.order),
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 22.sp,
            color: AppStyle.black,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${stateRight.bags[stateRight.selectedBagIndex].selectedUser?.firstname ?? ""} "
                  "${stateRight.bags[stateRight.selectedBagIndex].selectedUser?.lastname ?? ""}",
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                color: AppStyle.icon,
              ),
            ),
            Text(
              stateRight.orderType,
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                color: AppStyle.icon,
              ),
            ),
          ],
        ),
        8.verticalSpace,
        const Divider(),
        8.verticalSpace,
        Text(
          AppHelpers.getTranslation(TrKeys.totalItem),
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 18.sp,
            color: AppStyle.black,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList(List<ProductData> items, int displayCount, RightSideState stateRight) {
    return ListView.builder(
      padding: EdgeInsets.only(top: 16.r),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: displayCount,
      itemBuilder: (context, index) {
        return _buildItemRow(items[index], stateRight);
      },
    );
  }

  Widget _buildItemRow(ProductData item, RightSideState stateRight) {
    return Padding(
        padding: EdgeInsets.only(bottom: 16.r),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Expanded(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text(
        item.stock?.product?.translation?.title ?? "",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
            color: AppStyle.black,
          ),
        ),
        ...(item.addons ?? []).map((addon) => Text(
        "${addon.product?.translation?.title ?? ""} (${intl.NumberFormat.currency(
        symbol: LocalStorage.getSelectedCurrency().symbol,
    ).format((addon.price ?? 0) / (addon.quantity ?? 1))} x ${(addon.quantity ?? 1)})",
          style: GoogleFonts.inter(
            fontSize: 15.sp,
            color: AppStyle.unselectedTab,
          ),
        )).toList(),
          ],
        ),
        ),
            Text(
              intl.NumberFormat.currency(
                symbol: LocalStorage.getSelectedCurrency().symbol,
              ).format(item.totalPrice ?? 0),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
                color: AppStyle.black,
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildViewMoreButton(int remainingCount) {
    return InkWell(
      onTap: () => setState(() => _showAllItems = true),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'View $remainingCount more item${remainingCount > 1 ? 's' : ''}',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppStyle.blue,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: AppStyle.blue,
              size: 20.r,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewLessButton() {
    return InkWell(
      onTap: () => setState(() => _showAllItems = false),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'View less',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppStyle.blue,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_up,
              color: AppStyle.blue,
              size: 20.r,
            ),
          ],
        ),
      ),
    );
  }

  Widget calculator(RightSideState stateRight, RightSideNotifier rightSideNotifier) {
    double enteredAmount = double.tryParse(stateRight.calculate) ?? 0;
    bool isAmountValid = enteredAmount > 0;

    return Expanded(
      child: Container(
        decoration: const BoxDecoration(color: AppStyle.white),
        padding: EdgeInsets.symmetric(vertical: 28.r, horizontal: 16.r),
        child: Column(
          children: [
            _buildCalculatorHeader(stateRight),
            16.verticalSpace,
            const Divider(),
            const Spacer(),
            _buildDisplayAmount(stateRight),
            const Spacer(),
            _buildNumPad(stateRight, rightSideNotifier),
            16.verticalSpace,
            _buildBottomButtons(stateRight, rightSideNotifier, isAmountValid, enteredAmount),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorHeader(RightSideState stateRight) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppHelpers.getTranslation(TrKeys.payableAmount),
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppStyle.black,
              ),
            ),
            6.verticalSpace,
            Text(
              AppHelpers.numberFormat(
                calculateTotalPrice(stateRight),
              ),
              style: GoogleFonts.inter(
                fontSize: 26.sp,
                fontWeight: FontWeight.w600,
                color: AppStyle.black,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (stateRight.selectedUser != null)
          _buildUserInfo(stateRight),
      ],
    );
  }

  Widget _buildUserInfo(RightSideState stateRight) {
    return Row(
      children: [
        CommonImage(
          imageUrl: stateRight.selectedUser?.img ?? "",
          width: 50,
          height: 50,
          radius: 25,
        ),
        16.horizontalSpace,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${stateRight.selectedUser?.firstname ?? ""} ${stateRight.selectedUser?.lastname ?? ""}",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 18.sp,
                color: AppStyle.black,
              ),
            ),
            Text(
              "#${AppHelpers.getTranslation(TrKeys.id)}${stateRight.selectedUser?.id ?? ""}",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
                color: AppStyle.icon,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDisplayAmount(RightSideState stateRight) {
    final displayValue = stateRight.calculate == "0" ? "0" : stateRight.calculate;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        border: Border.all(color: AppStyle.differborder),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          displayValue,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 24.sp,
            color: AppStyle.black.withOpacity(0.5),
          ),
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _buildNumPad(RightSideState stateRight, RightSideNotifier rightSideNotifier) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 12,
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 28.w,
        mainAxisSpacing: 24.h,
        mainAxisExtent: 78.r,
      ),
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () async {
            await _playTapSound();

            final currentValue = stateRight.calculate;
            String value = "";

            if (index == 11) {
              if (currentValue.length == 1) {
                rightSideNotifier.clearCalculate();
              } else if (currentValue.isNotEmpty) {
                value = "-1";
                rightSideNotifier.setCalculate(value);
              }
            } else {
              // Handle number input
              if (index == 9) {
                if (currentValue == "0") {
                  value = "0";
                } else {
                  value = "00";
                }
              } else if (index == 10) {
                value = "0";
              } else {
                value = (index + 1).toString();
              }

              rightSideNotifier.setCalculate(value);
            }

            _updateSecondScreen(stateRight);
          },
          child: AnimationButtonEffect(
            child: Container(
              decoration: BoxDecoration(
                color: AppStyle.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Center(
                child: index == 11
                    ? Icon(
                  FlutterRemix.delete_back_2_line,
                  color: AppStyle.red,
                )
                    : Text(
                  index == 9 ? "00" : index == 10 ? "0" : (index + 1).toString(),
                  style: GoogleFonts.inter(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w600,
                    color: AppStyle.black.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomButtons(
      RightSideState stateRight,
      RightSideNotifier rightSideNotifier,
      bool isAmountValid,
      double enteredAmount,
      ) {
    return Row(
      children: [
        _buildDecimalButton(stateRight, rightSideNotifier),
        28.horizontalSpace,
        _buildOkButton(stateRight, isAmountValid, enteredAmount),
      ],
    );
  }

  Widget _buildDecimalButton(RightSideState stateRight, RightSideNotifier rightSideNotifier) {
    return Expanded(
      flex: 1,
      child: InkWell(
        onTap: () async {
          await _playTapSound();
          if (!stateRight.calculate.contains('.')) {
            rightSideNotifier.setCalculate(".");
          }
          _updateSecondScreen(stateRight);
        },
        child: AnimationButtonEffect(
          child: Container(
            height: 78.r,
            decoration: BoxDecoration(
              color: AppStyle.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Center(
              child: Text(
                ".",
                style: GoogleFonts.inter(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w600,
                  color: AppStyle.black.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOkButton(RightSideState stateRight, bool isAmountValid, double enteredAmount) {
    return Expanded(
      flex: 2,
      child: AnimationButtonEffect(
        child: InkWell(
          onTap: isAmountValid
              ? () async {
            await _playTapSound();
           // _handlePaymentConfirmation(stateRight, enteredAmount);
          }
              : null,
          child: Container(
            height: 78.r,
            decoration: BoxDecoration(
              color: AppStyle.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Center(
              child: Text(
                AppHelpers.getTranslation(TrKeys.ok),
                style: GoogleFonts.inter(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w600,
                  color: AppStyle.black.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handlePaymentConfirmation(RightSideState stateRight, double enteredAmount) {
    final secondScreenState = ref.read(secondScreenProvider);
    final updatedState = secondScreenState.copyWith(
      paymentConfirmed: true,
      totalPrice: calculateTotalPrice(stateRight),
      amountReceived: enteredAmount,
      change: enteredAmount - calculateTotalPrice(stateRight),
      showBlankScreen: false,
    );

    ref.read(rightSideProvider.notifier).clearCalculate();
    ref.read(secondScreenProvider.notifier).updateState(updatedState);
    ref.read(secondScreenServiceProvider).broadcastUpdate(updatedState);

    Future.delayed(const Duration(seconds: 5), () {
      ref.read(secondScreenProvider.notifier).updateState(
        SecondScreenState(
          showBlankScreen: true,
        ),
      );
      ref.read(secondScreenServiceProvider).broadcastUpdate(
        ref.read(secondScreenProvider),
      );
    });
  }
}
