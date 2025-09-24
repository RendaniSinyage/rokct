import 'package:admin_desktop/src/presentation/theme/theme.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/core/utils/app_helpers.dart';
import '../../../../../../../../components/components.dart';
import '../../riverpod/discount/add_discount/add_discount_provider.dart';
import '../../riverpod/discount/edit_discount/edit_discount_provider.dart';
import '../../riverpod/stock/stock_provider.dart';
import 'product_selection_item.dart';

class MultiSelectionWidget extends ConsumerStatefulWidget {
  final bool isEdit;

  const MultiSelectionWidget({super.key, this.isEdit = false});

  @override
  ConsumerState<MultiSelectionWidget> createState() =>
      _MultiSelectionWidgetState();
}

class _MultiSelectionWidgetState extends ConsumerState<MultiSelectionWidget> {
  late RefreshController _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(stockProvider.notifier).initialFetchStocks(),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _refreshController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stockState = ref.watch(stockProvider);
    final stockEvent = ref.read(stockProvider.notifier);
    final addDiscountEvent = ref.read(addDiscountProvider.notifier);
    final editDiscountEvent = ref.read(editDiscountProvider.notifier);
    final addDiscountState = ref.watch(addDiscountProvider);
    final editDiscountState = ref.watch(editDiscountProvider);
    return Column(
      children: [
        Expanded(
          child: stockState.isLoading
              ? const Loading()
              : SmartRefresher(
            controller: _refreshController,
            enablePullUp: true,
            onRefresh: () => stockEvent.refreshStocks(
              refreshController: _refreshController,
            ),
            onLoading: () => stockEvent.fetchMoreStocks(
              refreshController: _refreshController,
            ),
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: stockState.stocks.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return FoodProductItem(
                  stockData: stockState.stocks[index],
                  isSelected: widget.isEdit
                      ? editDiscountState.stocks.any((element) =>
                  element.id == stockState.stocks[index].id)
                      : addDiscountState.stocks.any((element) =>
                  element.id == stockState.stocks[index].id),
                  onTap: () {
                    widget.isEdit
                        ? editDiscountEvent.setDiscountProducts(
                        stockState.stocks[index])
                        : addDiscountEvent.setDiscountProducts(
                        stockState.stocks[index]);
                  },
                );
              },
            ),
          ),
        ),
        Row(
          children: [
            ConfirmButton(
              border: AppStyle.primary,
              title: AppHelpers.getTranslation(TrKeys.save),
              onTap: () => context.maybePop(),
            ),
          ],
        ),
      ],
    );
  }
}

