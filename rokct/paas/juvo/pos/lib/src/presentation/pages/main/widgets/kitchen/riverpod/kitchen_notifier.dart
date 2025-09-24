import 'dart:async';
import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/core/utils/app_helpers.dart';
import 'package:admin_desktop/src/models/data/order_data.dart';
import 'package:admin_desktop/src/repository/repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'kitchen_state.dart';

class KitchenNotifier extends StateNotifier<KitchenState> {
  final OrdersRepository _ordersRepository;
  int _page = 0;
  Timer? _searchProductsTimer;
  Timer? _refreshTimer;
  bool _isAutoDeselect = true;

  KitchenNotifier(this._ordersRepository) : super(const KitchenState());

  void setAutoDeselect(bool value) {
    _isAutoDeselect = value;
  }

  void clearSelectedOrder() {
    state = state.copyWith(
      selectOrder: null,
      selectIndex: -1,
    );
  }

  void changeType(String type) {
    state = state.copyWith(
      selectType: type,
      orders: [],
      selectOrder: null,
      selectIndex: -1,
    );
    fetchOrders(isRefresh: true);
  }

  Future<void> updateOrderDetailStatus({
    required String status,
    required int? id,
    VoidCallback? success,
  }) async {
    if (state.isUpdatingStatus) return;
    state = state.copyWith(isUpdatingStatus: true);

    try {
      final response = await _ordersRepository.updateOrderDetailStatus(
        status: status,
        orderId: id,
      );

      response.when(
        success: (data) async {
          await fetchOrderDetails();
          await _checkAndUpdateOrderStatus();
          success?.call();

          // Refresh the orders list to update timers
          fetchOrders(isRefresh: true);
        },
        failure: (failure) {
          debugPrint('===> update order detail status fail $failure');
          fetchOrderDetails();
        },
      );
    } finally {
      state = state.copyWith(isUpdatingStatus: false);
    }
  }

  Future<void> _checkAndUpdateOrderStatus() async {
    if (state.selectOrder == null) return;

    final details = state.selectOrder!.details ?? [];
    if (details.isEmpty) return;

    final allDetailsCanceled = details.every((detail) =>
    detail.status == TrKeys.canceled
    );

    if (allDetailsCanceled && state.selectOrder?.status != TrKeys.canceled) {
      await changeStatus(status: TrKeys.canceled);
      return;
    }

    if (!allDetailsCanceled) {
      if (state.selectOrder?.status == TrKeys.cooking) {
        final allDetailsReady = details.every((detail) =>
        detail.status == TrKeys.ready ||
            detail.status == TrKeys.canceled ||
            detail.status == TrKeys.ended
        );

        if (allDetailsReady) {
          await changeStatus(status: TrKeys.ready);
          return;
        }
      }

      if (state.selectOrder?.status == TrKeys.ready) {
        final allDetailsEnded = details.every((detail) =>
        detail.status == TrKeys.ended
        );

        if (allDetailsEnded) {
          final deliveryType = state.selectOrder?.deliveryType?.toLowerCase() ?? "";

          if (deliveryType == TrKeys.pickup.toLowerCase() ||
              deliveryType == TrKeys.dine.toLowerCase()) {
            await changeStatus(status: TrKeys.delivered);
          } else if (deliveryType == TrKeys.delivery.toLowerCase()) {
            await changeStatus(status: TrKeys.onAWay);
          }
        }
      }
    }
  }

  void changeDetailStatus(String status) {
    state = state.copyWith(detailStatus: status);
  }

  void clearSearch(BuildContext context) {
    state = state.copyWith(query: '');
    setOrdersQuery(context, '');
  }

  Future<void> selectIndex(int index) async {
    if (index < 0 || index >= state.orders.length) {
      clearSelectedOrder();
      return;
    }

    _isAutoDeselect = true;
    state = state.copyWith(
      selectIndex: index,
      selectOrder: state.orders[index],
    );
    await fetchOrderDetails();
  }

  Future<void> setOrder(OrderData order) async {
    _isAutoDeselect = false;
    final index = state.orders.indexWhere((o) => o.id == order.id);
    if (index != -1) {
      state = state.copyWith(
        selectIndex: index,
        selectOrder: order,
      );
      await fetchOrderDetails();
    }
  }

  Future<void> fetchOrderDetails() async {
    if (state.selectOrder?.id == null) return;

    final response = await _ordersRepository.getOrderDetailsKitchen(
        orderId: state.selectOrder?.id
    );

    response.when(
      success: (data) async {
        state = state.copyWith(selectOrder: data.data);

        final details = data.data?.details ?? [];
        final allDetailsCanceled = details.every((detail) =>
        detail.status == TrKeys.canceled
        );

        if (allDetailsCanceled && data.data?.status != TrKeys.canceled) {
          await changeStatus(status: TrKeys.canceled);
          return;
        }

        if (_isAutoDeselect &&
            data.data?.status != TrKeys.canceled && (
            data.data?.status == TrKeys.onAWay ||
                data.data?.status == TrKeys.delivered
        )) {
          clearSelectedOrder();
        }
      },
      failure: (e) {
        debugPrint('===> fetch order details fail $e');
      },
    );
  }

  void setOrdersQuery(BuildContext context, String query) {
    if (state.query == query) return;

    _searchProductsTimer?.cancel();
    state = state.copyWith(query: query.trim());

    _searchProductsTimer = Timer(
      const Duration(milliseconds: 500),
          () {
        state = state.copyWith(
          hasMore: true,
          orders: [],
          selectOrder: null,
          selectIndex: -1,
        );
        _page = 0;
        fetchOrders(
          isRefresh: true,
          checkYourNetwork: () {
            AppHelpers.showSnackBar(
              context,
              AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
            );
          },
        );
      },
    );
  }

  Future<void> fetchOrders({
    bool isRefresh = false,
    VoidCallback? checkYourNetwork,
  }) async {
    if (isRefresh) {
      _refreshTimer?.cancel();
      _page = 0;
    }

    if (!state.hasMore && !isRefresh) return;

    state = state.copyWith(isLoading: true);

    try {
      final response = await _ordersRepository.getKitchenOrders(
        status: state.selectType,
        page: isRefresh ? 1 : ++_page,
        search: state.query.isEmpty ? null : state.query,
      );

      response.when(
        success: (data) {
          final List<OrderData> newOrders = data.orders ?? [];

          if (isRefresh) {
            // Update existing orders if they exist in the new data
            final List<OrderData> updatedOrders = [];
            if (state.orders.isNotEmpty) {
              for (var order in newOrders) {
                final existingIndex = state.orders.indexWhere((o) => o.id == order.id);
                if (existingIndex != -1) {
                  // Preserve the selected state if this was the selected order
                  if (state.selectOrder?.id == order.id) {
                    state = state.copyWith(selectOrder: order);
                  }
                }
                updatedOrders.add(order);
              }
            } else {
              updatedOrders.addAll(newOrders);
            }

            state = state.copyWith(
              hasMore: newOrders.length >= 6,
              isLoading: false,
              orders: updatedOrders,
              selectOrder: _isAutoDeselect ? null : state.selectOrder,
              selectIndex: _isAutoDeselect ? -1 : state.selectIndex,
            );

            if (newOrders.isNotEmpty && _isAutoDeselect) {
              selectIndex(0);
              _setupRefreshTimer();
            } else if (newOrders.isEmpty) {
              clearSelectedOrder();
            }
          } else {
            final List<OrderData> updatedOrders = [...state.orders];
            for (OrderData element in newOrders) {
              if (!updatedOrders.map((item) => item.id).contains(element.id)) {
                updatedOrders.add(element);
              }
            }

            state = state.copyWith(
              hasMore: newOrders.length >= 6,
              isLoading: false,
              orders: updatedOrders,
            );
          }
        },
        failure: (failure) {
          if (!isRefresh) _page--;
          if (_page == 0) {
            state = state.copyWith(isLoading: false);
          }
          checkYourNetwork?.call();
        },
      );
    } catch (e) {
      debugPrint('===> fetch orders error $e');
      state = state.copyWith(isLoading: false);
      checkYourNetwork?.call();
    }
  }

  void _setupRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(AppConstants.refreshTime, (timer) async {
      final response = await _ordersRepository.getKitchenOrders(
        status: state.selectType,
        page: 1,
        search: state.query.isEmpty ? null : state.query,
      );

      response.when(
        success: (data) {
          final orders = data.orders ?? [];

          // Update existing orders while preserving selected state
          final List<OrderData> updatedOrders = [];
          for (var order in orders) {
            if (state.selectOrder?.id == order.id) {
              state = state.copyWith(selectOrder: order);
            }
            updatedOrders.add(order);
          }

          state = state.copyWith(orders: updatedOrders);

          if (_isAutoDeselect && state.selectIndex >= orders.length) {
            selectIndex(orders.isEmpty ? -1 : 0);
          } else if (state.selectOrder != null) {
            final updatedOrder = orders.firstWhere(
                  (order) => order.id == state.selectOrder!.id,
              orElse: () => state.selectOrder!,
            );
            state = state.copyWith(selectOrder: updatedOrder);
          }
        },
        failure: (f) {
          debugPrint('===> refresh timer fetch fail $f');
        },
      );
    });
  }

  Future<void> changeStatus({String? status}) async {
    if (state.selectOrder == null) return;

    final newStatus = status ?? AppHelpers.getOrderStatusText(
      AppHelpers.getOrderStatus(state.selectOrder?.status, isNextStatus: true),
    );

    try {
      if (newStatus == TrKeys.ready &&
          state.selectOrder?.status == TrKeys.cooking) {
        final details = state.selectOrder?.details ?? [];
        final hasReadyItems = details.any((detail) =>
        detail.status == TrKeys.ready ||
            detail.status == TrKeys.ended
        );

        if (!hasReadyItems) {
          return;
        }
      }

      if (newStatus == TrKeys.cooking) {
        await _updateAllDetailsToCooking();
      } else if (newStatus == TrKeys.canceled) {
        await _updateAllDetailsToCanceled();
      }

      final updatedOrder = state.selectOrder!.copyWith(status: newStatus);

      await _ordersRepository.updateOrderStatusKitchen(
        status: AppHelpers.getOrderStatus(newStatus),
        orderId: updatedOrder.id,
      );

      if (_isAutoDeselect && newStatus != TrKeys.canceled) {
        clearSelectedOrder();
      } else {
        state = state.copyWith(selectOrder: updatedOrder);
      }

      // Refresh orders to update all timers and states
      await fetchOrders(isRefresh: true);

    } catch (e) {
      debugPrint('===> change status error $e');
      await fetchOrderDetails();
    }
  }

  Future<void> _updateAllDetailsToCooking() async {
    final orderDetails = state.selectOrder?.details;
    if (orderDetails == null) return;

    for (final detail in orderDetails) {
      if (detail.status != TrKeys.canceled && detail.status != TrKeys.ended) {
        final response = await _ordersRepository.updateOrderDetailStatus(
          status: TrKeys.cooking,
          orderId: detail.id,
        );
        response.when(
          success: (_) {},
          failure: (e) => debugPrint('===> update detail to cooking fail $e'),
        );
      }
    }
    await fetchOrderDetails();
  }

  Future<void> _updateAllDetailsToCanceled() async {
    final orderDetails = state.selectOrder?.details;
    if (orderDetails == null) return;

    bool anyUpdated = false;
    for (final detail in orderDetails) {
      if (detail.status != TrKeys.canceled) {
        anyUpdated = true;
        final response = await _ordersRepository.updateOrderDetailStatus(
          status: TrKeys.canceled,
          orderId: detail.id,
        );
        response.when(
          success: (_) {},
          failure: (e) => debugPrint('===> update detail to canceled fail $e'),
        );
      }
    }

    if (anyUpdated) {
      await fetchOrderDetails();
    }
  }

  void stopTimer() {
    _refreshTimer?.cancel();
    _searchProductsTimer?.cancel();
  }

  @override
  void dispose() {
    stopTimer();
    super.dispose();
  }
}
