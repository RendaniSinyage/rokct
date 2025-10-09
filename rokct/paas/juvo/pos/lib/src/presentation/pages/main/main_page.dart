// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:admin_desktop/src/core/routes/app_router.dart';
import 'package:admin_desktop/src/presentation/components/custom_scaffold.dart';
import 'package:admin_desktop/src/presentation/pages/main/riverpod/notifier/main_notifier.dart';
import 'package:admin_desktop/src/presentation/pages/main/riverpod/state/main_state.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/customers/customers_page.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/customers/riverpod/notifier/customer_notifier.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/customers/riverpod/provider/customer_provider.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/kitchen/kitchen_page.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/kitchen/riverpod/kitchen_provider.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/notifications/riverpod/notification_provider.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/post_page.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/tables/tables_page.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/orders_table/orders_table.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/sale_history/sale_history.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/income/income_page.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/JuvoONE/widgets/dashboard/dashboard_page.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:auto_route/auto_route.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proste_indexed_stack/proste_indexed_stack.dart';
import 'package:remixicon/remixicon.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import '../../../../generated/assets.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/utils.dart';
import '../../components/api_status_indicator.dart';
import '../../components/buttons/refresh/refresh_button.dart';
import '../../components/buttons/refresh/start_end_date_button.dart';
import '../../components/buttons/refresh/view_mode_button.dart';
import '../../components/components.dart';
import '../../theme/theme.dart';
import 'riverpod/provider/main_provider.dart';
import 'widgets/JuvoONE/components/cash_drawer_button.dart';
import 'widgets/JuvoONE/components/close_shift_dialog.dart';
import 'widgets/JuvoONE/components/dynamic_header.dart';
import 'widgets/JuvoONE/components/notification_icon.dart';
import 'widgets/JuvoONE/components/quick_sale.dart';
//import 'widgets/JuvoONE/widgets/maintenance_dialog.dart';
import 'widgets/JuvoONE/widgets/dashboard/dashboard_entry.dart';
import 'widgets/JuvoONE/widgets/expenses/add_expense.dart';
import 'widgets/JuvoONE/widgets/roSystem/maintenance/maintenance_alerts.dart';
import 'widgets/JuvoONE/widgets/weather/weather_widget.dart';
import 'widgets/inventory/inventory_page.dart';
import 'widgets/parcels/parcels_page.dart';
import 'widgets/orders_table/orders/accepted/accepted_orders_provider.dart';
import 'widgets/orders_table/orders/new/new_orders_provider.dart';
import 'widgets/orders_table/orders/on_a_way/on_a_way_orders_provider.dart';
import 'widgets/orders_table/orders/ready/ready_orders_provider.dart';
import 'widgets/orders_table/orders/cooking/cooking_orders_provider.dart';
import 'widgets/orders_table/orders/delivered/delivered_orders_provider.dart';
import 'widgets/orders_table/orders/canceled/canceled_orders_provider.dart';
import 'widgets/right_side/riverpod/right_side_provider.dart';
import 'widgets/settings/settings_dialog.dart';

@RoutePage()
class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage>
    with SingleTickerProviderStateMixin {
  final user = LocalStorage.getUser();
  Timer? _idleTimer;
  static final Duration _idleTimeout = AppConstants.idleTimeout;
  bool _isIdle = false;
  bool _showSearch = false;
  final bool _isHovering = false;
  bool _showJuvoONEAnimation = true;
  final bool _showNotification = false;
  final bool _showMaintenanceAlert = false;
  Timer? _notificationTimer;
  Timer? _hideTimer;
  bool _showWeatherIcon = false;
  Timer? _weatherTimer;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _floatController = TextEditingController();
  final bool _hasShownFloatDialog = false;

  bool get _isDesktop {
    return !kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
  }

  bool _userHasShop() {
    final userData = LocalStorage.getUser();
    return userData?.shop != null;
  }

  bool _shouldShowStoreFeatures() {
    final userData = LocalStorage.getUser();
    // Show for admins regardless of shop, or for other roles if they have a shop
    return userData?.role == 'admin' || _userHasShop();
  }

  late List<IndexedStackChild> list = [
    IndexedStackChild(child: const PostPage(), preload: true),
    IndexedStackChild(child: const OrdersTablesPage()),
    IndexedStackChild(child: const CustomersPage(), preload: true),
    IndexedStackChild(child: const TablesPage()),
    IndexedStackChild(child: const SaleHistory()),
    IndexedStackChild(child: const InComePage()),
    IndexedStackChild(child: const ParcelsPage()),
    if (AppConstants.enableJuvoONE) ...[
      IndexedStackChild(child: const InventoryPage()),
      IndexedStackChild(child: const DashboardEntry(), preload: true)
    ],
  ];

  late List<IndexedStackChild> listKitchen = [
    IndexedStackChild(child: const KitchenPage(), preload: true),
  ];

  late List<IndexedStackChild> listWaiter = [
    IndexedStackChild(child: const PostPage(), preload: true),
    IndexedStackChild(child: const OrdersTablesPage()),
    IndexedStackChild(child: const TablesPage()),
  ];

  late List<IndexedStackChild> listAdmin = [
    IndexedStackChild(child: const OrdersTablesPage()),
    IndexedStackChild(child: const CustomersPage(), preload: true),
    if (AppConstants.enableJuvoONE) ...[
      IndexedStackChild(child: const DashboardEntry(), preload: true)
    ],
  ];

  Timer? timer;
  int time = 0;
  final player = AudioPlayer();

  bool get kIsMobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  Future playMusic() async {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      await player.play(AssetSource("audio/notification.wav"));
    });
  }

  Future<void> _showFloatAmountDialog() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasShownDialog = prefs.getBool('has_shown_float_dialog') ?? false;

    if (!hasShownDialog && user?.role != TrKeys.cooker) {
      // Changed this line to use hasShownDialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(
            AppHelpers.getTranslation(TrKeys.openingDrawerAmount),
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppStyle.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _floatController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: AppStyle.black),
                decoration: InputDecoration(
                  hintText: AppHelpers.getTranslation(TrKeys.amount),
                  hintStyle: TextStyle(color: AppStyle.black.withOpacity(0.5)),
                  border: const OutlineInputBorder(),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppStyle.black),
                  ),
                  prefix: Text(
                    '${LocalStorage.getSelectedCurrency().symbol} ',
                    style: TextStyle(color: AppStyle.black),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              12.verticalSpace,
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.enableJuvoONE
                            ? AppStyle.blueBonus
                            : AppStyle.brandGreen,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      onPressed: () async {
                        if (_floatController.text.isNotEmpty) {
                          double amount = double.parse(_floatController.text);
                          await LocalStorage.setFloatAmount(amount);
                          await prefs.setBool(
                              'has_shown_float_dialog', true); // Save the flag
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        }
                      },
                      child: Text(
                        AppHelpers.getTranslation(TrKeys.confirm),
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: AppStyle.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          backgroundColor: AppStyle.white,
        ),
      );
    }
  }

  void _performSearch(String value, BuildContext context) {
    final trimmedValue = value.trim();
    final state = ref.watch(mainProvider);
    final customerNotifier = ref.read(customerProvider.notifier);
    final notifier = ref.read(mainProvider.notifier);

    if (user?.role == TrKeys.seller) {
      if (state.selectIndex == 0) {
        notifier.setProductsQuery(context, trimmedValue);
      } else if (state.selectIndex == 2) {
        customerNotifier.searchUsers(context, trimmedValue);
      } else if (state.selectIndex == 1) {
        _updateOrdersSearch(trimmedValue);
      }
    } else if (user?.role == TrKeys.cooker) {
      ref.read(kitchenProvider.notifier).setOrdersQuery(context, trimmedValue);
    } else if (user?.role == TrKeys.waiter) {
      if (state.selectIndex == 0) {
        notifier.setProductsQuery(context, trimmedValue);
      } else if (state.selectIndex == 1) {
        _updateOrdersSearch(trimmedValue);
      }
    }
  }

  void _updateOrdersSearch(String value) {
    ref.read(newOrdersProvider.notifier).setOrdersQuery(context, value);
    ref.read(acceptedOrdersProvider.notifier).setOrdersQuery(context, value);
    ref.read(cookingOrdersProvider.notifier).setOrdersQuery(context, value);
    ref.read(readyOrdersProvider.notifier).setOrdersQuery(context, value);
    ref.read(onAWayOrdersProvider.notifier).setOrdersQuery(context, value);
    ref.read(deliveredOrdersProvider.notifier).setOrdersQuery(context, value);
    ref.read(canceledOrdersProvider.notifier).setOrdersQuery(context, value);
  }

  Future<void> saveWindowState() async {
    final prefs = await SharedPreferences.getInstance();
    final isMaximized = await windowManager.isMaximized();
    await prefs.setBool('wasMaximized', isMaximized);
  }

  void _handleSearch({bool isClosing = false}) {
    if (isClosing) {
      final state = ref.read(mainProvider);

      if (user?.role == TrKeys.seller) {
        if (state.selectIndex == 0) {
          ref.read(mainProvider.notifier).clearSearch(context);
        } else if (state.selectIndex == 2) {
          ref.read(customerProvider.notifier).clearSearch(context);
        } else if (state.selectIndex == 1) {
          _clearOrdersSearch();
        }
      } else if (user?.role == TrKeys.cooker) {
        ref.read(kitchenProvider.notifier).clearSearch(context);
      } else if (user?.role == TrKeys.waiter) {
        if (state.selectIndex == 0) {
          ref.read(mainProvider.notifier).clearSearch(context);
        } else if (state.selectIndex == 1) {
          _clearOrdersSearch();
        }
      }
      _searchController.clear();
    } else {
      Future.delayed(const Duration(milliseconds: 50), () {
        _searchFocusNode.requestFocus();
      });
    }

    setState(() {
      _showSearch = !_showSearch;
    });
  }

  void _clearOrdersSearch() {
    ref.read(newOrdersProvider.notifier).clearSearch(context);
    ref.read(acceptedOrdersProvider.notifier).clearSearch(context);
    ref.read(readyOrdersProvider.notifier).clearSearch(context);
    ref.read(onAWayOrdersProvider.notifier).clearSearch(context);
    ref.read(deliveredOrdersProvider.notifier).clearSearch(context);
    ref.read(canceledOrdersProvider.notifier).clearSearch(context);
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS) &&
        user?.role == TrKeys.seller &&
        AppConstants.enableJuvoONE) {
      setState(() {
        _isIdle = false;
      });
      _idleTimer = Timer(_idleTimeout, _onIdle);
    }
  }

  void _onIdle() {
    if (mounted &&
        ref.read(mainProvider).selectIndex != 7 &&
        AppConstants.enableJuvoONE) {
      setState(() {
        _isIdle = true;
      });
      ref.read(mainProvider.notifier).changeIndex(7);
    }
  }

  notif() async {
    await FirebaseMessaging.instance.requestPermission(
      sound: true,
      alert: true,
      badge: false,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (AppConstants.playMusicOnOrderStatusChange) {
        player.play(AssetSource("audio/notification.wav"));
      }
      if (mounted) {
        AppHelpers.showSnackBar(
          context,
          "${AppHelpers.getTranslation(TrKeys.id)} #${message.notification?.title} ${message.notification?.body}",
        );
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    _idleTimer?.cancel();
    _weatherTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _floatController.dispose();
    if (AppConstants.enableJuvoONE) {
      WidgetsBinding.instance
          .removeObserver(_ActivityObserver(onActivity: _resetIdleTimer));
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _weatherTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _showWeatherIcon = true;
        });
      }
    });

    //_checkMaintenance();
    notif();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _showFloatAmountDialog();
      // _showFloatAmountDialog();

      if (user?.role == TrKeys.seller) {
        ref.read(mainProvider.notifier)
          ..fetchProducts(
            checkYourNetwork: () {
              AppHelpers.showSnackBar(
                context,
                AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
              );
            },
          )
          ..fetchCategories(
            context: context,
            checkYourNetwork: () {
              AppHelpers.showSnackBar(
                context,
                AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
              );
            },
          )
          ..fetchUserDetail(context)
          ..changeIndex(0);
        ref.read(rightSideProvider.notifier).fetchUsers(
          checkYourNetwork: () {
            AppHelpers.showSnackBar(
              context,
              AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
            );
          },
        );

        if (AppConstants.enableJuvoONE) {
          _resetIdleTimer();
        }
      } else if (user?.role == TrKeys.cooker) {
        ref.read(mainProvider.notifier)
          ..fetchUserDetail(context)
          ..changeIndex(0);
      } else {
        ref.read(mainProvider.notifier)
          ..fetchProducts(
            checkYourNetwork: () {
              AppHelpers.showSnackBar(
                context,
                AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
              );
            },
          )
          ..fetchCategories(
            context: context,
            checkYourNetwork: () {
              AppHelpers.showSnackBar(
                context,
                AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
              );
            },
          )
          ..fetchUserDetail(context)
          ..changeIndex(0);
      }

      if (mounted) {
        Timer.periodic(
          AppConstants.refreshTime,
          (s) {
            ref.read(notificationProvider.notifier).fetchCount(context);
          },
        );
      }
    });

    if (AppConstants.enableJuvoONE) {
      WidgetsBinding.instance
          .addObserver(_ActivityObserver(onActivity: _resetIdleTimer));
    }

    _showJuvoONEAnimation = AppConstants.enableJuvoONE;
  }

  bool _shouldShowSearch(MainState state, String? userRole) {
    if (userRole == TrKeys.seller) {
      return state.selectIndex < 4;
    } else if (userRole == TrKeys.waiter) {
      return state.selectIndex < 2;
    }
    return true;
  }

  String _getSearchHintText(MainState state) {
    if (state.selectIndex == 0) {
      return AppHelpers.getTranslation(TrKeys.searchProducts);
    } else if (state.selectIndex == 1) {
      return AppHelpers.getTranslation(TrKeys.searchOrders);
    } else if (state.selectIndex == 2 && user?.role == TrKeys.seller) {
      return AppHelpers.getTranslation(TrKeys.searchCustomers);
    } else {
      return AppHelpers.getTranslation(TrKeys.searchProducts);
    }
  }

  PreferredSizeWidget customAppBar(
      MainNotifier notifier, CustomerNotifier customerNotifier) {
    final state = ref.watch(mainProvider);
    final userRole = user?.role;

    if (!_shouldShowSearch(state, userRole)) {
      return AppBar(
        backgroundColor: AppStyle.white,
        automaticallyImplyLeading: false,
        elevation: 0.5,
        title: Row(
          children: [
            DynamicHeaderComponent(
              selectIndex: state.selectIndex,
              userRole: userRole ?? '',
            ),
            if (kIsMobile) const Spacer() else 12.horizontalSpace,
            if (_showWeatherIcon && _userHasShop()) ...[
              FutureBuilder<bool>(
                future: AppConnectivity.connectivity(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data == true) {
                    return const WeatherWidget();
                  }
                  return const SizedBox.shrink();
                },
              )
            ],
            const Spacer(),
            if (state.selectIndex == 0 && user?.role != TrKeys.cooker) ...[
              const CashDrawerButton(),
              //16.horizontalSpace
            ],
            const VerticalDivider(),
            const StartEndDateButton(),
            const RefreshButton(
              tooltip: 'Refresh',
              color: AppStyle.black,
              size: 24,
            ),
            16.horizontalSpace,
            ViewModeButton(),
            const VerticalDivider(),
            if (state.selectIndex == 0 ||
                state.selectIndex == 7 &&
                    AppConstants.enableJuvoONE &&
                    user?.role != TrKeys.cooker &&
                    _userHasShop()) ...[
              const MaintenanceAlert(),
            ],
            if (state.selectIndex == 0 &&
                user?.role != TrKeys.cooker &&
                AppConstants.enableJuvoONE) ...[
              _buildSettingsAndNotifications()
            ],
            SizedBox(width: 5.w),
            const ApiStatusIndicator(),
            SizedBox(width: 12.w),
            if (_isDesktop) _buildWindowControls(),
          ],
        ),
      );
    }

    return AppBar(
      backgroundColor: AppStyle.white,
      automaticallyImplyLeading: false,
      elevation: 0.5,
      title: Row(
        children: [
          DynamicHeaderComponent(
            selectIndex: state.selectIndex,
            userRole: userRole ?? '',
          ),
          if (kIsMobile) const Spacer() else 12.horizontalSpace,
          if (_showWeatherIcon && _userHasShop()) ...[
            FutureBuilder<bool>(
              future: AppConnectivity.connectivity(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data == true) {
                  return const WeatherWidget();
                }
                return const SizedBox
                    .shrink(); // Returns an empty widget when no connection
              },
            )
          ],
          30.horizontalSpace,
          Expanded(
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _handleSearch(isClosing: _showSearch),
                  child: Icon(
                    _showSearch ? Remix.close_line : Remix.search_2_line,
                    size: 20.r,
                    color: AppStyle.black,
                  ),
                ),
                17.horizontalSpace,
                Expanded(
                  flex: 2,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _showSearch ? double.infinity : 0,
                    child: _showSearch
                        ? TextFormField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: (value) =>
                                _performSearch(value, context),
                            cursorColor: AppStyle.black,
                            cursorWidth: 1.r,
                            decoration: InputDecoration.collapsed(
                              hintText: _getSearchHintText(state),
                              hintStyle: GoogleFonts.inter(
                                fontWeight: FontWeight.w500,
                                fontSize: 18.sp,
                                color: AppStyle.black.withOpacity(0.3),
                                letterSpacing: -14 * 0.02,
                              ),
                            ),
                          )
                        : const SizedBox(),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (state.selectIndex == 0 &&
              user?.role != TrKeys.cooker &&
              AppConstants.enableJuvoONE &&
              _shouldShowStoreFeatures()) ...[
            QuickSale(key: QuickSale.globalKey),
            const VerticalDivider(),
            AddExpense()
          ],
          if (state.selectIndex == 0 && user?.role != TrKeys.cooker) ...[
            const CashDrawerButton(),
            // 16.horizontalSpace
          ],
          const VerticalDivider(),
          const StartEndDateButton(),
          const RefreshButton(
            tooltip: 'Refresh',
            color: AppStyle.black,
            size: 24,
          ),
          16.horizontalSpace,
          ViewModeButton(),
          const VerticalDivider(),
          if (state.selectIndex == 0 ||
              state.selectIndex == 7 &&
                  AppConstants.enableJuvoONE &&
                  user?.role != TrKeys.cooker &&
                  _userHasShop()) ...[
            const MaintenanceAlert(),
          ],
          if (state.selectIndex == 0 &&
              user?.role != TrKeys.cooker &&
              AppConstants.enableJuvoONE) ...[_buildSettingsAndNotifications()],
          SizedBox(width: 5.w),
          const ApiStatusIndicator(),
          SizedBox(width: 12.w),
          if (_isDesktop) _buildWindowControls(),
        ],
      ),
    );
  }

  Widget _buildSettingsAndNotifications() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            AppHelpers.showAlertDialog(
              context: context,
              height: MediaQuery.of(context).size.height - 30.h,
              child: user!.role != TrKeys.cooker
                  ? const SettingsMenu()
                  : const SizedBox.shrink(),
            );
          },
          child: Stack(
            children: [
              /*Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  border: Border.all(color: AppStyle.black, width: 2.w),
                  shape: BoxShape.circle,
                ),
                child: CommonImage(
                  width: 40,
                  height: 40,
                  radius: 20,
                  imageUrl: LocalStorage.getUser()?.img,
                  userData: LocalStorage.getUser(),
                ),*/
              const Icon(Remix.settings_3_line, color: AppStyle.black),
              // ),
            ],
          ),
        ),
        if (ref
                    .watch(notificationProvider)
                    .countOfNotifications
                    ?.notification !=
                null &&
            ref
                    .watch(notificationProvider)
                    .countOfNotifications!
                    .notification! >
                0) ...[5.horizontalSpace, const NotificationIcon()],
      ],
    );
  }

  Widget _buildWindowControls() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          color: AppStyle.black,
          onPressed: () async {
            await windowManager.minimize();
          },
        ),
        IconButton(
          icon: const Icon(Icons.crop_square),
          color: AppStyle.black,
          onPressed: () async {
            if (await windowManager.isMaximized()) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
            await saveWindowState();
            setState(() {});
          },
        ),
        IconButton(
          icon: const Icon(Icons.close),
          color: AppStyle.black,
          onPressed: () async {
            await saveWindowState();
            await windowManager.close();
          },
        ),
      ],
    );
  }

  AppBar idleAppBar() {
    return AppBar(
      backgroundColor: AppStyle.white,
      automaticallyImplyLeading: false,
      elevation: 0.5,
      title: Row(
        children: [
          SizedBox(width: 16.w),
          WeatherWidget(),
          Spacer(),
          ApiStatusIndicator(),
          SizedBox(width: 12.w),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mainProvider);
    final customerNotifier = ref.read(customerProvider.notifier);
    final notifier = ref.read(mainProvider.notifier);

    final isAdmin = user?.role == 'admin';

    if (AppConstants.keepPlayingOnNewOrder) {
      ref.listen(newOrdersProvider, (previous, next) async {
        if (next.orders.isEmpty) {
          await player.stop();
          timer?.cancel();
        }

        if (time != 0 && next.orders.isNotEmpty) {
          await playMusic();
        }
        time++;
      });
    }

    return RawKeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKey: (RawKeyEvent event) {
        // Emergency logout with Ctrl+L
        if (event is RawKeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.keyL &&
            (event.isControlPressed || event.isMetaPressed)) {
          // Force logout
          context.replaceRoute(const LoginRoute());
          LocalStorage.clearStore();
        }
      },
      child: Listener(
        onPointerHover: (PointerHoverEvent event) {
          if (_isIdle && AppConstants.enableJuvoONE) {
            _resetIdleTimer();
          }
        },
        child: MouseRegion(
          onHover: (_) {
            if (_isIdle && AppConstants.enableJuvoONE) {
              _resetIdleTimer();
            }
          },
          child: GestureDetector(
            onTap: AppConstants.enableJuvoONE ? _resetIdleTimer : null,
            onPanDown:
                AppConstants.enableJuvoONE ? (_) => _resetIdleTimer() : null,
            child: SafeArea(
              child: CustomScaffold(
                extendBody: true,
                appBar: (colors) => (AppConstants.enableJuvoONE && _isIdle)
                    ? idleAppBar()
                    : customAppBar(notifier, customerNotifier),
                backgroundColor: AppStyle.bg,
                body: (c) => Directionality(
                  textDirection: LocalStorage.getLangLtr()
                      ? TextDirection.ltr
                      : TextDirection.rtl,
                  child: KeyboardDismisser(
                    child: Row(
                      children: [
                        if (!_isIdle || !AppConstants.enableJuvoONE)
                          isAdmin
                              ? bottomLeftNavigationBarAdmin(state)
                              : user?.role == TrKeys.seller
                                  ? bottomLeftNavigationBar(state)
                                  : user?.role == TrKeys.cooker
                                      ? bottomLeftNavigationBarKitchen(state)
                                      : bottomLeftNavigationBarWaiter(state),
                        Expanded(
                          child: ProsteIndexedStack(
                            index: state.selectIndex,
                            children: isAdmin
                                ? listAdmin
                                : user?.role == TrKeys.seller
                                    ? list
                                    : user?.role == TrKeys.cooker
                                        ? listKitchen
                                        : listWaiter,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget bottomLeftNavigationBarAdmin(MainState state) {
    return Container(
      height: double.infinity,
      width: 40,
      color: AppStyle.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          24.verticalSpace,
          Container(
            decoration: BoxDecoration(
              color: state.selectIndex == 0
                  ? (AppConstants.enableJuvoONE
                      ? AppStyle.blueBonus
                      : AppStyle.brandGreen)
                  : AppStyle.transparent,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: IconButton(
              onPressed: () {
                ref.read(mainProvider.notifier).changeIndex(0);
              },
              icon: Icon(
                state.selectIndex == 0
                    ? Remix.shopping_bag_2_fill
                    : Remix.shopping_bag_2_line,
                color: state.selectIndex == 0 ? AppStyle.white : AppStyle.black,
              ),
            ),
          ),
          12.verticalSpace,
          Container(
            decoration: BoxDecoration(
              color: state.selectIndex == 1
                  ? (AppConstants.enableJuvoONE
                      ? AppStyle.blueBonus
                      : AppStyle.brandGreen)
                  : AppStyle.transparent,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: IconButton(
              onPressed: () {
                ref.read(mainProvider.notifier).changeIndex(1);
              },
              icon: Icon(
                state.selectIndex == 1
                    ? Remix.user_search_fill
                    : Remix.user_search_line,
                color: state.selectIndex == 1 ? AppStyle.white : AppStyle.black,
              ),
            ),
          ),
          if (AppConstants.enableJuvoONE) ...[
            12.verticalSpace,
            Container(
              decoration: BoxDecoration(
                color: state.selectIndex == 2
                    ? AppStyle.brandGreen
                    : AppStyle.transparent,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: IconButton(
                onPressed: () {
                  ref.read(mainProvider.notifier).changeIndex(2);
                },
                icon: Icon(
                  state.selectIndex == 2
                      ? Remix.drop_fill
                      : Remix.blur_off_fill,
                  color:
                      state.selectIndex == 2 ? AppStyle.white : AppStyle.black,
                ),
              ),
            ),
          ],
          const Spacer(),
          IconButton(
            onPressed: () {
              context.replaceRoute(const LoginRoute());
              LocalStorage.clearStore();
            },
            icon: const Icon(
              Remix.logout_circle_line,
              color: AppStyle.red,
            ),
          ),
          32.verticalSpace,
        ],
      ),
    );
  }

  Widget bottomLeftNavigationBar(MainState state) {
    return Container(
      height: double.infinity,
      width: 40,
      color: AppStyle.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          24.verticalSpace,
          Container(
            decoration: BoxDecoration(
              color: state.selectIndex == 0
                  ? (AppConstants.enableJuvoONE
                      ? AppStyle.blueBonus
                      : AppStyle.brandGreen)
                  : AppStyle.transparent,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: IconButton(
              onPressed: () {
                ref.read(mainProvider.notifier).changeIndex(0);
              },
              icon: Icon(
                state.selectIndex == 0 ? Remix.home_fill : Remix.home_line,
                color: state.selectIndex == 0 ? AppStyle.white : AppStyle.black,
              ),
            ),
          ),
          12.verticalSpace,
          Container(
            decoration: BoxDecoration(
              color: state.selectIndex == 1
                  ? (AppConstants.enableJuvoONE
                      ? AppStyle.blueBonus
                      : AppStyle.brandGreen)
                  : AppStyle.transparent,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: IconButton(
              onPressed: () {
                ref.read(mainProvider.notifier).changeIndex(1);
              },
              icon: Icon(
                state.selectIndex == 1
                    ? Remix.shopping_bag_2_fill
                    : Remix.shopping_bag_2_line,
                color: state.selectIndex == 1 ? AppStyle.white : AppStyle.black,
              ),
            ),
          ),
          12.verticalSpace,
          Container(
            decoration: BoxDecoration(
              color: state.selectIndex == 2
                  ? (AppConstants.enableJuvoONE
                      ? AppStyle.blueBonus
                      : AppStyle.brandGreen)
                  : AppStyle.transparent,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: IconButton(
              onPressed: () {
                ref.read(mainProvider.notifier).changeIndex(2);
              },
              icon: Icon(
                state.selectIndex == 2
                    ? Remix.user_search_fill
                    : Remix.user_search_line,
                color: state.selectIndex == 2 ? AppStyle.white : AppStyle.black,
              ),
            ),
          ),
          12.verticalSpace,
          Container(
            decoration: BoxDecoration(
              color: state.selectIndex == 3
                  ? (AppConstants.enableJuvoONE
                      ? AppStyle.blueBonus
                      : AppStyle.brandGreen)
                  : AppStyle.transparent,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: IconButton(
              onPressed: () {
                ref.read(mainProvider.notifier).changeIndex(3);
              },
              icon: SvgPicture.asset(
                state.selectIndex == 3
                    ? Assets.svgSelectTable
                    : Assets.svgTable,
                color: state.selectIndex == 3 ? AppStyle.white : AppStyle.black,
              ),
            ),
          ),
          12.verticalSpace,
          Container(
            decoration: BoxDecoration(
              color: state.selectIndex == 4
                  ? AppStyle.brandGreen
                  : AppStyle.transparent,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: IconButton(
              onPressed: () {
                ref.read(mainProvider.notifier).changeIndex(4);
              },
              icon: Icon(
                state.selectIndex == 4
                    ? Remix.money_dollar_circle_fill
                    : Remix.money_dollar_circle_line,
                color: state.selectIndex == 4 ? AppStyle.white : AppStyle.black,
              ),
            ),
          ),
          12.verticalSpace,
          Container(
            decoration: BoxDecoration(
              color: state.selectIndex == 5
                  ? AppStyle.brandGreen
                  : AppStyle.transparent,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: IconButton(
              onPressed: () {
                ref.read(mainProvider.notifier).changeIndex(5);
              },
              icon: Icon(
                state.selectIndex == 5
                    ? Remix.pie_chart_fill
                    : Remix.pie_chart_line,
                color: state.selectIndex == 5 ? AppStyle.white : AppStyle.black,
              ),
            ),
          ),
          12.verticalSpace,
          Container(
            decoration: BoxDecoration(
              color: state.selectIndex == 6
                  ? (AppConstants.enableJuvoONE
                      ? AppStyle.blueBonus
                      : AppStyle.brandGreen)
                  : AppStyle.transparent,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: IconButton(
              onPressed: () {
                ref.read(mainProvider.notifier).changeIndex(6);
              },
              icon: Icon(
                state.selectIndex == 6
                    ? Remix.truck_fill
                    : Remix.truck_line,
                color: state.selectIndex == 6 ? AppStyle.white : AppStyle.black,
              ),
            ),
          ),
          if (AppConstants.enableJuvoONE && AppConstants.isDemo) ...[
            12.verticalSpace,
            Container(
              decoration: BoxDecoration(
                color: state.selectIndex == 6
                    ? AppStyle.brandGreen
                    : AppStyle.transparent,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: IconButton(
                onPressed: () {
                  ref.read(mainProvider.notifier).changeIndex(6);
                },
                icon: Icon(
                  state.selectIndex == 6
                      ? Remix.drop_fill
                      : Remix.blur_off_fill,
                  color:
                      state.selectIndex == 6 ? AppStyle.white : AppStyle.black,
                ),
              ),
            ),
          ],
          if (AppConstants.enableJuvoONE && !AppConstants.isDemo) ...[
            12.verticalSpace,
            Container(
              decoration: BoxDecoration(
                color: state.selectIndex == 6
                    ? AppStyle.brandGreen
                    : AppStyle.transparent,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: IconButton(
                onPressed: () {
                  ref.read(mainProvider.notifier).changeIndex(6);
                },
                icon: Icon(
                  state.selectIndex == 6 ? Remix.bread_fill : Remix.bread_fill,
                  color:
                      state.selectIndex == 6 ? AppStyle.white : AppStyle.black,
                ),
              ),
            ),
            12.verticalSpace,
            Container(
              decoration: BoxDecoration(
                color: state.selectIndex == 7
                    ? AppStyle.brandGreen
                    : AppStyle.transparent,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: IconButton(
                onPressed: () {
                  ref.read(mainProvider.notifier).changeIndex(7);
                },
                icon: Icon(
                  state.selectIndex == 7
                      ? Remix.drop_fill
                      : Remix.blur_off_fill,
                  color:
                      state.selectIndex == 7 ? AppStyle.white : AppStyle.black,
                ),
              ),
            ),
          ],
          const Spacer(),
          // Replace the existing logout IconButton with this new implementation:

          IconButton(
            onPressed: () async {
              final float = LocalStorage.getFloatAmount();
              final needsToCloseShift = LocalStorage.needsToCloseShift();

              if (float > 0 || needsToCloseShift) {
                if (context.mounted) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => CloseShiftDialog(
                      onLogout: () {
                        context.replaceRoute(const LoginRoute());
                        ref.read(newOrdersProvider.notifier).stopTimer();
                        ref.read(acceptedOrdersProvider.notifier).stopTimer();
                        ref.read(cookingOrdersProvider.notifier).stopTimer();
                        ref.read(readyOrdersProvider.notifier).stopTimer();
                        ref.read(onAWayOrdersProvider.notifier).stopTimer();
                        ref.read(deliveredOrdersProvider.notifier).stopTimer();
                        ref.read(canceledOrdersProvider.notifier).stopTimer();
                        LocalStorage.clearStore();
                      },
                    ),
                  );
                }
              } else {
                context.replaceRoute(const LoginRoute());
                ref.read(newOrdersProvider.notifier).stopTimer();
                ref.read(acceptedOrdersProvider.notifier).stopTimer();
                ref.read(cookingOrdersProvider.notifier).stopTimer();
                ref.read(readyOrdersProvider.notifier).stopTimer();
                ref.read(onAWayOrdersProvider.notifier).stopTimer();
                ref.read(deliveredOrdersProvider.notifier).stopTimer();
                ref.read(canceledOrdersProvider.notifier).stopTimer();
                LocalStorage.clearStore();
              }
            },
            icon: const Icon(
              Remix.logout_circle_line,
              color: AppStyle.red,
            ),
          ),
          32.verticalSpace,
        ],
      ),
    );
  }

  Widget bottomLeftNavigationBarKitchen(MainState state) {
    return Container(
      height: double.infinity,
      width: 50,
      color: AppStyle.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          12.verticalSpace,
          Container(
            decoration: BoxDecoration(
              color: state.selectIndex == 0
                  ? AppStyle.brandGreen
                  : AppStyle.transparent,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: IconButton(
              onPressed: () {
                ref.read(mainProvider.notifier).changeIndex(0);
              },
              icon: SvgPicture.asset(
                state.selectIndex == 0
                    ? Assets.svgSelectKitchen
                    : Assets.svgKitchen,
                color: state.selectIndex == 0 ? AppStyle.white : AppStyle.black,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              context.replaceRoute(const LoginRoute());
              ref.read(kitchenProvider.notifier).stopTimer();
              LocalStorage.clearStore();
            },
            icon: const Icon(
              Remix.logout_circle_line,
              color: AppStyle.red,
            ),
          ),
          32.verticalSpace,
        ],
      ),
    );
  }

  Widget bottomLeftNavigationBarWaiter(MainState state) {
    return Container(
      height: double.infinity,
      width: 50,
      color: AppStyle.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          24.verticalSpace,
          Container(
            decoration: BoxDecoration(
              color: state.selectIndex == 0
                  ? AppStyle.brandGreen
                  : AppStyle.transparent,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: IconButton(
              onPressed: () {
                ref.read(mainProvider.notifier).changeIndex(0);
              },
              icon: Icon(
                state.selectIndex == 0 ? Remix.home_fill : Remix.home_line,
                color: state.selectIndex == 0 ? AppStyle.white : AppStyle.black,
              ),
            ),
          ),
          12.verticalSpace,
          Container(
            decoration: BoxDecoration(
              color: state.selectIndex == 1
                  ? AppStyle.brandGreen
                  : AppStyle.transparent,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: IconButton(
              onPressed: () {
                ref.read(mainProvider.notifier).changeIndex(1);
              },
              icon: Icon(
                state.selectIndex == 1
                    ? Remix.shopping_bag_fill
                    : Remix.shopping_bag_line,
                color: state.selectIndex == 1 ? AppStyle.white : AppStyle.black,
              ),
            ),
          ),
          12.verticalSpace,
          Container(
            decoration: BoxDecoration(
              color: state.selectIndex == 2
                  ? (AppConstants.enableJuvoONE
                      ? AppStyle.blueBonus
                      : AppStyle.brandGreen)
                  : AppStyle.transparent,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: IconButton(
              onPressed: () {
                ref.read(mainProvider.notifier).changeIndex(2);
              },
              icon: SvgPicture.asset(
                state.selectIndex == 2
                    ? Assets.svgSelectTable
                    : Assets.svgTable,
                color: state.selectIndex == 2 ? AppStyle.white : AppStyle.black,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              context.replaceRoute(const LoginRoute());
              ref.read(newOrdersProvider.notifier).stopTimer();
              ref.read(acceptedOrdersProvider.notifier).stopTimer();
              ref.read(cookingOrdersProvider.notifier).stopTimer();
              ref.read(readyOrdersProvider.notifier).stopTimer();
              ref.read(onAWayOrdersProvider.notifier).stopTimer();
              ref.read(deliveredOrdersProvider.notifier).stopTimer();
              ref.read(canceledOrdersProvider.notifier).stopTimer();
              LocalStorage.clearStore();
            },
            icon: const Icon(
              Remix.logout_circle_line,
              color: AppStyle.red,
            ),
          ),
          32.verticalSpace,
        ],
      ),
    );
  }
}

class _ActivityObserver extends WidgetsBindingObserver {
  final VoidCallback onActivity;

  _ActivityObserver({required this.onActivity});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onActivity();
    }
  }
}

