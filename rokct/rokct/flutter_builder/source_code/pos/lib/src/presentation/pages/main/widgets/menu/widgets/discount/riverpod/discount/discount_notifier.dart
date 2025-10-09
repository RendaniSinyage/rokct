import 'dart:async';
import '../../../../../../../../../models/data/discount_data.dart';
import '../../../../../../../../../repository/discount_repository.dart';
import 'discount_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DiscountNotifier extends StateNotifier<DiscountState> {
  final DiscountsRepository _discountRepository;
  int _page = 0;

  DiscountNotifier(this._discountRepository) : super(const DiscountState());

  Future<void> fetchDiscounts({
    required BuildContext context,
    bool? isRefresh,
  }) async {
    if (isRefresh ?? false) {
      _page = 0;
      state = state.copyWith(discounts: [], isLoading: true, hasMore: true);
    }
    final res = await _discountRepository.getAllDiscounts(page: ++_page);
    res.when(success: (data) {
      List<DiscountData> list = List.from(state.discounts);
      list.addAll(data.data ?? []);
      state = state.copyWith(
          isLoading: false,
          discounts: list,
          hasMore: list.length < (data.meta?.total ?? 0),
      );
      if (isRefresh ?? false) {
        return;
      } else if (data.data?.isEmpty ?? true) {

        return;
      }
      return;
    },
      failure: (failure) {
        state = state.copyWith(isLoading: false);
        debugPrint('==> error with fetch discount  $failure');
      },
    );
  }
  Future<void> deleteDiscount(BuildContext context, int? id) async {
    state = state.copyWith(isLoading: true);
    final response = await _discountRepository.deleteDiscount(id);
    response.when(
      success: (success) {
        List<DiscountData> list = List.from(state.discounts);
        list.removeWhere((element) => element.id == id);
        state = state.copyWith(discounts: list);
      },
      failure: (failure) {
        state = state.copyWith(isLoading: false);
        debugPrint('==> error with delete discount  $failure');
      },
    );
    state = state.copyWith(isLoading: false);
  }
}

