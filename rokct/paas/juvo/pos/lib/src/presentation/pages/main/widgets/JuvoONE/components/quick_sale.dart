import 'dart:async';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../core/constants/constants.dart';
import '../../../../../../core/utils/utils.dart';
import '../../../../../../models/models.dart';
import '../../../../../../models/data/location_data.dart';
import '../../../../../components/components.dart';
import '../../../../../theme/theme.dart';
import '../../right_side/riverpod/right_side_provider.dart';
import '../../orders_table/orders/delivered/delivered_orders_provider.dart';
import '../../right_side/riverpod/right_side_state.dart';
import '../riverpod/provider/quickOrdersRepositoryProvider.dart';

class QuickSale extends ConsumerStatefulWidget {
  static final GlobalKey<_QuickSaleState> globalKey =
  GlobalKey<_QuickSaleState>();

  const QuickSale({super.key = null}) : super();

  @override
  ConsumerState<QuickSale> createState() => _QuickSaleState();
}

class _CheckIconButton extends StatelessWidget {
  final UserData? selectedUser;
  final bool isProcessing;
  final VoidCallback onPressed;
  final bool isNoUserMode;
  final bool isEnabled;

  const _CheckIconButton({
    required this.selectedUser,
    required this.isProcessing,
    required this.onPressed,
    this.isNoUserMode = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isClickable = !isProcessing && isEnabled;
    return IconButton(
      onPressed: isClickable ? onPressed : null,
      icon: Icon(
        Icons.check_circle,
        color: isClickable ? AppStyle.black : AppStyle.black.withOpacity(0.3),
        size: 24,
      ),
    );
  }
}

class _QuickSaleState extends ConsumerState<QuickSale> {
  bool _showDropdown = false;
  bool _isProcessing = false;
  int _tapCount = 1;
  Timer? _userSelectionTimer;
  Timer? _autoSelectTimer;
  List<int> _noUserStockIds = [];
  bool _isNoUserMode = false;
  bool _showingThankYou = false;

  @override
  void initState() {
    super.initState();
    _initializeNoUserStockIds();
  }

  void _initializeNoUserStockIds() {
    _noUserStockIds = AppConstants.quickSaleNoUserStockIds;
    _tapCount = 1;
  }

  void showThankYou() {
    setState(() {
      _showingThankYou = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showingThankYou = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _userSelectionTimer?.cancel();
    _autoSelectTimer?.cancel();
    super.dispose();
  }

  Future<int> _getNextOrderNumber(int userId) async {
    final deliveredOrders = ref.read(deliveredOrdersProvider).orders;

    final latestOrder = deliveredOrders
        .where((order) =>
    order.userId == userId &&
        order.note != null &&
        !order.note!.contains('no_user_order'))
        .sorted((a, b) => (b.toJson()[AppConstants.dateAt] as String)
        .compareTo(a.toJson()[AppConstants.dateAt] as String))
        .firstOrNull;

    if (latestOrder != null && latestOrder.note != null) {
      final parts = latestOrder.note!.split('|');
      if (parts.length > 1) {
        final orderNumber = int.tryParse(parts.last.trim()) ?? 0;
        if (orderNumber >= AppConstants.quickSaleCouponTapCount) {
          return 1;
        }
        return orderNumber + 1;
      }
      final orderNumber = int.tryParse(latestOrder.note!.trim()) ?? 0;
      if (orderNumber >= AppConstants.quickSaleCouponTapCount) {
        return 1;
      }
      return orderNumber + 1;
    }
    return 1;
  }

  void _handleUserQuery(String query, BuildContext context) {
    final rightSideNotifier = ref.read(rightSideProvider.notifier);
    rightSideNotifier.setUsersQuery(context, query);

    // Cancel existing timers
    _userSelectionTimer?.cancel();
    _autoSelectTimer?.cancel();

    // Only proceed with auto-selection if the query is numeric and at least 3 digits
    if (query.length >= 3 && int.tryParse(query) != null) {
      _autoSelectTimer = Timer(const Duration(seconds: 3), () {
        final users = ref.read(rightSideProvider).users;
        try {
          final userIndex = users.indexWhere(
                (user) => user.id.toString() == query,
          );

          if (userIndex != -1) {
            rightSideNotifier.setSelectedUser(context, userIndex);
            _checkUserOrderHistory(users[userIndex]);

            // First close dropdown
            setState(() {
              _isNoUserMode = false;
              _showDropdown = false;
            });

            // Wait for UI to update then click again
            Future.delayed(const Duration(milliseconds: 100), () {
              setState(() {
                _showDropdown = true;
              });
            });
          } else {
            setState(() {
              _isNoUserMode = true;
            });
          }
        } catch (e) {
          setState(() {
            _isNoUserMode = true;
          });
        }
      });
    }

    // Regular search behavior
    _userSelectionTimer = Timer(const Duration(milliseconds: 300), () {
      final selectedUser = ref.read(rightSideProvider).selectedUser;
      if (selectedUser != null) {
        _checkUserOrderHistory(selectedUser);
        setState(() {
          _isNoUserMode = false;
        });
      } else {
        setState(() {
          _isNoUserMode = true;
        });
      }
    });
  }

  Future<void> _checkUserOrderHistory(UserData user) async {
    if (user.id == null) return;

    setState(() {
      _isProcessing = true;
    });

    final ordersResult = await ref.read(ordersRepositoryProvider).getUserDeliveredOrders(
      userId: user.id!,
      page: 1,
    );

    ordersResult.when(
        success: (response) {
          // Get delivered orders from the response
          final deliveredOrders = response.data?.orders ?? [];

          // Find the latest order with the note
          final latestOrder = deliveredOrders
              .where((order) =>
          order.note != null &&
              !order.note!.contains('no_user_order'))
              .toList()
              .firstWhereOrNull((order) {
            if (order.note == null || !order.note!.contains('|')) return false;
            final numberPart = order.note!.split('|').last.trim();
            return int.tryParse(numberPart) != null;
          });

          // Calculate next number
          int nextNumber = 1;
          if (latestOrder?.note != null) {
            final numberPart = latestOrder!.note!.split('|').last.trim();
            final orderNumber = int.tryParse(numberPart) ?? 0;
            nextNumber = orderNumber >= AppConstants.quickSaleCouponTapCount ? 1 : orderNumber + 1;
          }

          setState(() {
            _tapCount = nextNumber;
            _isProcessing = false;
          });
        },
      failure: (error) {
        setState(() {
          _isProcessing = false;
        });
        if (context.mounted) {
          AppHelpers.showSnackBar(
            context,
            AppHelpers.getTranslation(TrKeys.somethingWentWrongWithTheServer),
          );
        }
      },
    );
  }

  Color? _getCounterColor(int count) {
    if (count < 1 || count > 4) {
      return AppStyle.black.withOpacity(0.3);
    }

    switch (count) {
      case 1:
        return AppStyle.blueColor;
      case 2:
        return AppStyle.red;
      case 3:
        return AppStyle.green[700];
      case 4:
        return AppStyle.deepPurple;
      default:
        return AppStyle.black.withOpacity(0.3);
    }
  }

  Widget _buildCounter(UserData? selectedUser) {
    final bool isNoUserMode = selectedUser == null;
    final int maxCount = isNoUserMode
        ? _noUserStockIds.length
        : AppConstants.quickSaleCouponTapCount;

    return GestureDetector(
      onTap: () {
        setState(() {
          _tapCount = _tapCount >= maxCount ? 1 : _tapCount + 1;
        });
      },
      child: Container(
        width: 35.w,
        height: 35.h,
        margin: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(
          color: _getCounterColor(_tapCount),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: AppStyle.black,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            _tapCount.toString(),
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppStyle.black,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createOrder(BuildContext context) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final rightSideNotifier = ref.read(rightSideProvider.notifier);
      var currentState = ref.read(rightSideProvider);

      // Initialize required data
      if (currentState.payments.isEmpty) {
        await rightSideNotifier.fetchPayments(
          checkYourNetwork: () {
            AppHelpers.showSnackBar(
              context,
              AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
            );
          },
        );
      }

      if (currentState.currencies.isEmpty) {
        await rightSideNotifier.fetchCurrencies(
          checkYourNetwork: () {
            AppHelpers.showSnackBar(
              context,
              AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
            );
          },
        );
      }

      // Get updated state after fetching data
      currentState = ref.read(rightSideProvider);

      final cashPayment = currentState.payments.firstWhere(
            (payment) => payment.tag?.toLowerCase() == 'cash',
        orElse: () => currentState.payments.first,
      );

      final defaultCurrency = currentState.currencies.firstWhere(
            (element) => element.isDefault ?? false,
        orElse: () => currentState.currencies.first,
      );

      // Set required payment and currency for state without affecting bags
      rightSideNotifier.setSelectedPayment(cashPayment.id ?? 0);
      rightSideNotifier.setSelectedCurrency(defaultCurrency.id ?? 0);
      rightSideNotifier.setSelectedOrderType(TrKeys.pickup);

      final now = DateTime.now();
      final currentTime = TimeOfDay.now();

      String? couponCode;
      int currentStockId;

      if (_isNoUserMode) {
        if (_tapCount > _noUserStockIds.length) {
          throw Exception('Invalid tap count for no-user order');
        }
        currentStockId = _noUserStockIds[_tapCount - 1];
      } else {
        currentStockId = AppConstants.quickSaleStockId;
        if (_tapCount == AppConstants.quickSaleCouponTapCount) {
          couponCode = AppConstants.quickSaleCouponCode;
        }
      }

      final note = _isNoUserMode ? "no_user_order_$_tapCount" : _tapCount.toString();

      // Create a temporary BagData without storing it
      final tempBag = BagData(
          selectedPayment: cashPayment,
          selectedCurrency: defaultCurrency,
          bagProducts: [
            BagProductData(
              stockId: currentStockId,
              quantity: AppConstants.quickSaleDefaultQuantity,
            )
          ]
      );

      // Set the order note before creating the order
      rightSideNotifier.setNote(note);

      final orderBody = OrderBodyData(
        bagData: tempBag,
        phone: _isNoUserMode ? "" : (currentState.selectedUser?.phone ?? ""),
        note: note,
        userId: _isNoUserMode ? null : currentState.selectedUser?.id,
        deliveryFee: 0,
        deliveryType: TrKeys.pickup,
        location: LocationData(latitude: 0, longitude: 0),
        address: AddressModel(address: ""),
        deliveryDate: DateFormat('yyyy-MM-dd').format(now),
        deliveryTime: "${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}",
        currencyId: defaultCurrency.id ?? 0,
        rate: defaultCurrency.rate ?? 1,
        coupon: couponCode,
      );

      await rightSideNotifier.createOrder(
        context,
        orderBody,
        onSuccess: () {
          // Immediately clear the bag
          rightSideNotifier.removeOrderedBag(context);

          setState(() {
            _showDropdown = false;
            _tapCount = 1;
            _isNoUserMode = false;
            _showingThankYou = true;
          });

          if (!_isNoUserMode) {
            rightSideNotifier.removeSelectedUser();
          }

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _showingThankYou = false;
              });
            }
          });
        },
      );
    } catch (e) {
      AppHelpers.showSnackBar(
        context,
        AppHelpers.getTranslation(TrKeys.errorWithCreatingOrder),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _toggleDropdown() {
    setState(() {
      _showDropdown = !_showDropdown;
      if (!_showDropdown) {
        _tapCount = 1;
        ref.read(rightSideProvider.notifier).removeSelectedUser();
        _isNoUserMode = false;
      } else {
        _isNoUserMode = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final rightSideState = ref.watch(rightSideProvider);
    final selectedUser = rightSideState.selectedUser;

    ref.listen<RightSideState>(rightSideProvider, (previous, next) {
      if (previous?.selectedUser?.id != next.selectedUser?.id) {
        if (next.selectedUser != null) {
          _checkUserOrderHistory(next.selectedUser!);
          setState(() {
            _isNoUserMode = false;

          });
        } else {
          setState(() {
            _isNoUserMode = true;
          });
        }
      }
    });

    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.r),
        color: _showDropdown ? AppStyle.primary : AppStyle.dontHaveAccBtnBack,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(children: [
            _showDropdown
                ? IconButton(
              onPressed: _isProcessing ? null : _toggleDropdown,
              icon: Icon(Remix.close_line,
                  color: AppStyle.black, size: 24),
            )
                : MaterialButton(
              onPressed: _isProcessing ? null : _toggleDropdown,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StreamBuilder<String>(
                          stream: Stream.periodic(
                              const Duration(milliseconds: 150),
                                  (count) {
                                if (_showingThankYou) {
                                  return AppHelpers.getTranslation(
                                      TrKeys.thankYouForOrder);
                                }
                                const text = "QUICKSALE";
                                if (count < 33) return text;
                                int backspaceCount = count - 33;
                                if (backspaceCount >= text.length)
                                  return "";
                                return text.substring(
                                    0, text.length - backspaceCount - 1);
                              }).take(42),
                          initialData: _showingThankYou
                              ? AppHelpers.getTranslation(
                              TrKeys.thankYouForOrder)
                              : "QUICKSALE",
                          builder: (context, snapshot) {
                            return snapshot.data!.isEmpty
                                ? Icon(Remix.shopping_bag_4_fill,
                                size: 24, color: AppStyle.black)
                                : RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                    snapshot.data!.length >= 5
                                        ? snapshot.data!
                                        .substring(0, 5)
                                        : snapshot.data!,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16.sp,
                                      color: AppStyle.black,
                                    ),
                                  ),
                                  if (snapshot.data!.length > 5)
                                    TextSpan(
                                      text: snapshot.data!
                                          .substring(5),
                                      style: GoogleFonts.inter(
                                        fontWeight:
                                        FontWeight.w500,
                                        fontSize: 16.sp,
                                        color: AppStyle.black,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (_isProcessing)
              const Positioned.fill(
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(AppStyle.blueBonus),
                    ),
                  ),
                ),
              ),
          ],
          ),
          if (_showDropdown)
            Row(
              children: [
                SizedBox(
                  width: 200,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppStyle.unselectedBottomBarBack,
                        width: 1.r,
                      ),
                    ),
                    alignment: Alignment.center,
                    padding: EdgeInsets.only(left: 16.r),
                    child: CustomDropdown(
                      hintText: AppHelpers.getTranslation(TrKeys.selectUser),
                      searchHintText:
                      AppHelpers.getTranslation(TrKeys.searchUser),
                      dropDownType: DropDownType.users,
                      onChanged: (value) => _handleUserQuery(value, context),
                      initialValue: selectedUser?.firstname ?? '',
                    ),
                  ),
                ),
                _buildCounter(selectedUser),
                _CheckIconButton(
                  selectedUser: selectedUser,
                  isProcessing: _isProcessing,
                  isNoUserMode: _isNoUserMode,
                  isEnabled: _isNoUserMode || selectedUser != null,
                  onPressed: () => _createOrder(context),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
