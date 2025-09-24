import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/core/utils/utils.dart';
import 'package:admin_desktop/src/models/data/order_data.dart';
import 'package:admin_desktop/src/presentation/components/custom_scaffold.dart';
import 'package:admin_desktop/src/presentation/components/filter_screen.dart';
import 'package:admin_desktop/src/presentation/pages/main/riverpod/provider/main_provider.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/order_detail/order_detail.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/orders_table/orders/accepted/accepted_orders_provider.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/orders_table/orders/canceled/canceled_orders_provider.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/orders_table/orders/cooking/cooking_orders_provider.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/orders_table/orders/delivered/delivered_orders_provider.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/orders_table/orders/new/new_orders_provider.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/orders_table/orders/on_a_way/on_a_way_orders_provider.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/orders_table/orders/ready/ready_orders_provider.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/orders_table/widgets/board_view.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/orders_table/widgets/list_view.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/orders_table/widgets/start_end_date.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/orders_table/widgets/view_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/theme.dart';
import 'order_table_riverpod/order_table_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class OrdersTablesPage extends ConsumerStatefulWidget {
  const OrdersTablesPage({super.key});

  @override
  ConsumerState<OrdersTablesPage> createState() => _OrdersTablesState();
}

class _OrdersTablesState extends ConsumerState<OrdersTablesPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _previousAcceptedCount = 0;
  int _previousNewCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeOrderCounts();
      _refreshAllOrders();
    });
  }

  void _initializeOrderCounts() {
    final acceptedOrders = ref.read(acceptedOrdersProvider).orders;
    final newOrders = ref.read(newOrdersProvider).orders;
    _previousAcceptedCount = acceptedOrders.length;
    _previousNewCount = newOrders.length;
  }

  void _refreshAllOrders() {
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

  void _checkAndPlaySound() {
    final acceptedOrders = ref.read(acceptedOrdersProvider).orders;
    final newOrders = ref.read(newOrdersProvider).orders;

    if (acceptedOrders.length > _previousAcceptedCount || newOrders.length > _previousNewCount) {
      _audioPlayer.play(AssetSource('audio/notification.wav'));
    }

    _previousAcceptedCount = acceptedOrders.length;
    _previousNewCount = newOrders.length;
  }

  @override
  Widget build(BuildContext context) {
    final listAccepts = ref.watch(acceptedOrdersProvider).orders;
    final listNew = ref.watch(newOrdersProvider).orders;
    final listOnAWay = ref.watch(onAWayOrdersProvider).orders;
    final listReady = ref.watch(readyOrdersProvider).orders;
    final listDelivered = ref.watch(deliveredOrdersProvider).orders;
    final listCancel = ref.watch(canceledOrdersProvider).orders;
    final listCooking = ref.watch(cookingOrdersProvider).orders;
    final notifier = ref.read(orderTableProvider.notifier);
    final state = ref.watch(orderTableProvider);
    final stateMain = ref.watch(mainProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPlaySound();
    });

    return CustomScaffold(
        body: (c) => stateMain.selectedOrder != null
            ? OrderDetailPage(order: stateMain.selectedOrder ?? OrderData())
            : SafeArea(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                    vertical: 10.r,
                    horizontal: 16.r
                ),
                decoration: const BoxDecoration(color: AppStyle.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                ),
              ),
              Expanded(
                child: !state.isListView
                    ? BoardViewMode(
                  listAccepts: listAccepts,
                  listNew: listNew,
                  listOnAWay: listOnAWay,
                  listReady: listReady,
                  listCanceled: listCancel,
                  listDelivered: listDelivered,
                  listCooking: listCooking,
                )
                    : ListViewMode(
                  listAccepts: listAccepts,
                  listNew: listNew,
                  listOnAWay: listOnAWay,
                  listReady: listReady,
                  listCanceled: listCancel,
                  listDelivered: listDelivered,
                  listCooking: listCooking,
                ),
              ),
            ],
          ),
        )
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
