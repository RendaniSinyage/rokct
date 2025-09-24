import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import '../../../../core/utils/app_connectivity.dart';
import '../../../../core/utils/app_helpers.dart';
import '../../../pages/main/riverpod/provider/main_provider.dart';
import '../../../pages/main/widgets/JuvoONE/widgets/dashboard/shop_dashboard_grid.dart';
import '../../../pages/main/widgets/income/riverpod/income_provider.dart';
import '../../../pages/main/widgets/kitchen/riverpod/kitchen_provider.dart';
import '../../../pages/main/widgets/orders_table/orders/accepted/accepted_orders_provider.dart';
import '../../../pages/main/widgets/orders_table/orders/canceled/canceled_orders_provider.dart';
import '../../../pages/main/widgets/orders_table/orders/cooking/cooking_orders_provider.dart';
import '../../../pages/main/widgets/orders_table/orders/delivered/delivered_orders_provider.dart';
import '../../../pages/main/widgets/orders_table/orders/new/new_orders_provider.dart';
import '../../../pages/main/widgets/orders_table/orders/on_a_way/on_a_way_orders_provider.dart';
import '../../../pages/main/widgets/orders_table/orders/ready/ready_orders_provider.dart';
import '../../../pages/main/widgets/tables/riverpod/tables_provider.dart';
import '../../../theme/theme.dart';
import '../../components.dart';
import '../../../../core/utils/local_storage.dart';
import '../../../../core/constants/constants.dart';

final refreshStateProvider = StateNotifierProvider<RefreshStateNotifier, bool>((ref) {
  return RefreshStateNotifier();
});

class RefreshStateNotifier extends StateNotifier<bool> {
  RefreshStateNotifier() : super(false);

  void setLoading(bool isLoading) {
    state = isLoading;
  }
}

final refreshCallbackProvider = StateProvider<Future<void> Function()?>(
      (ref) => null,
);

class RefreshButton extends ConsumerStatefulWidget {
  final Color? color;
  final double? size;
  final String? tooltip;
  final VoidCallback? onBeforeRefresh;
  final VoidCallback? onAfterRefresh;

  const RefreshButton({
    super.key,
    this.color,
    this.size,
    this.tooltip,
    this.onBeforeRefresh,
    this.onAfterRefresh,
  });

  @override
  ConsumerState<RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends ConsumerState<RefreshButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isLoading = ref.watch(refreshStateProvider);
    if (isLoading) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.reset();
    }
  }

  Future<void> _refreshKitchenOrders() async {
    ref.read(kitchenProvider.notifier).fetchOrders(isRefresh: true);
  }

  Future<void> _refreshAllOrders() async {
    ref.read(newOrdersProvider.notifier).fetchNewOrders(isRefresh: true);
    ref.read(acceptedOrdersProvider.notifier).fetchAcceptedOrders(isRefresh: true);
    if (LocalStorage.getUser()?.role != TrKeys.waiter) {
      ref.read(onAWayOrdersProvider.notifier).fetchOnAWayOrders(isRefresh: true);
    }
    ref.read(readyOrdersProvider.notifier).fetchReadyOrders(isRefresh: true);
    ref.read(deliveredOrdersProvider.notifier).fetchDeliveredOrders(isRefresh: true);
    ref.read(canceledOrdersProvider.notifier).fetchCanceledOrders(isRefresh: true);
    ref.read(cookingOrdersProvider.notifier).fetchCookingOrders(isRefresh: true);
  }

  Future<void> _refreshTablesPage() async {
    ref.read(tablesProvider.notifier).refresh();
  }

  Future<void> _refreshIncomePage() async {
    final event = ref.read(incomeProvider.notifier);
    event
      ..fetchIncomeCarts()
      ..fetchIncomeCharts()
      ..fetchIncomeStatistic()
      ..fetchExpenseData();
  }

  Future<void> _refreshProductsPage() async {
    ref.read(mainProvider.notifier).fetchProducts(
      isRefresh: true,
      checkYourNetwork: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection)),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  bool _shouldShowRefreshButton() {
    final currentIndex = ref.watch(mainProvider).selectIndex;
    final userRole = LocalStorage.getUser()?.role;

    switch (userRole) {
      case TrKeys.seller:
      // Show for seller in these pages
        return [0, 1, 3, 5, 6, 7].contains(currentIndex);
      case TrKeys.cooker:
      // Show for cooker in the kitchen page
        return currentIndex == 0;
      case TrKeys.waiter:
      // Show for waiter in these pages
        return [0, 1, 2].contains(currentIndex);
      case 'admin':
      // Show for admin in these pages
        return [0, 1, 2].contains(currentIndex);
      default:
        return false;
    }
  }

  Future<void> _handleRefresh() async {
    final refreshCallback = ref.read(refreshCallbackProvider);
    final currentIndex = ref.read(mainProvider).selectIndex;
    final userRole = LocalStorage.getUser()?.role;

    // Check connectivity first
    final hasConnectivity = await AppConnectivity.connectivity();
    if (!hasConnectivity) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No internet connection'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    widget.onBeforeRefresh?.call();
    ref.read(refreshStateProvider.notifier).setLoading(true);
    _controller.repeat();

    try {
      // Admin role handling
      if (userRole == 'admin') {
        switch (currentIndex) {
          case 0: // Orders Tables for admin
            await _refreshAllOrders();
            break;
          case 1: // Customers page for admin
          // Refresh customers logic could be added here
            break;
          case 2: // Dashboard for admin
            if (refreshCallback != null) {
              await refreshCallback();
            }
            // Additionally, refresh shops dashboard if available
            try {
              final shopsDashboardNotifier = ref.read(shopsDashboardProvider.notifier);
              await shopsDashboardNotifier.refresh();
            } catch (e) {
              if (kDebugMode) {
                print('Error refreshing shops dashboard: $e');
              }
            }
            break;
          default:
            break;
        }
      }
      // Seller role handling
      else if (userRole == TrKeys.seller) {
        switch (currentIndex) {
          case 0: // Post page - Products
            await _refreshProductsPage();
            break;
          case 1: // Orders Tables
            await _refreshAllOrders();
            break;
          case 3: // Tables page
            await _refreshTablesPage();
            break;
          case 5: // Income page
            await _refreshIncomePage();
            break;
          case 6: // Inventory page
            await _refreshProductsPage();
            break;
          case 7: // Dashboard page
            if (refreshCallback != null) {
              await refreshCallback();
            }
            break;
        }
      }
      // Cooker role handling
      else if (userRole == TrKeys.cooker) {
        if (currentIndex == 0) {
          await _refreshKitchenOrders();
        }
      }
      // Waiter role handling
      else if (userRole == TrKeys.waiter) {
        switch (currentIndex) {
          case 0: // Post page - Products
            await _refreshProductsPage();
            break;
          case 1: // Orders Tables
            await _refreshAllOrders();
            break;
          case 2: // Tables page
            await _refreshTablesPage();
            break;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        ref.read(refreshStateProvider.notifier).setLoading(false);
        _controller.stop();
        _controller.reset();
        widget.onAfterRefresh?.call();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(refreshStateProvider);

    if (!_shouldShowRefreshButton()) {
      return const SizedBox.shrink();
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimationButtonEffect(
        child: Tooltip(
          message: widget.tooltip ?? 'Refresh',
          child: IconButton(
            onPressed: isLoading ? null : _handleRefresh,
            icon: RotationTransition(
              turns: _controller,
              child: Icon(
                Remix.refresh_line,
                color: isLoading
                    ? AppStyle.grey[400]
                    : _isHovered
                    ? widget.color ?? AppStyle.brandGreen
                    : widget.color ?? AppStyle.black,
                size: widget.size ?? 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

mixin RefreshablePageMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  Future<void> onRefresh();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(refreshCallbackProvider.notifier).state = onRefresh;
    });
  }

  @override
  void dispose() {
    ref.read(refreshCallbackProvider.notifier).state = null;
    super.dispose();
  }
}
