import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../../../../models/data/product_data.dart';
import '../../../../../../../../../repository/stock_repository.dart';
import 'stock_state.dart';

class StockNotifier extends StateNotifier<StockState> {
  final StockRepository _stockRepository;
  int _page = 0;
  bool _hasMore = true;

  StockNotifier(this._stockRepository) : super(const StockState());

  Future<void> fetchMoreStocks({RefreshController? refreshController}) async {
    if (!_hasMore) {
      refreshController?.loadNoData();
      return;
    }
    final response = await _stockRepository.getStocks(
      page: ++_page,

    );
    response.when(
      success: (data) {
        List<Stocks> stocks = List.from(state.stocks);
        final List<Stocks> newStocks = data.data ?? [];
        stocks.addAll(newStocks);
        _hasMore = newStocks.length >= 10;
        refreshController?.loadComplete();
        state = state.copyWith(stocks: stocks);
      },
      failure: (fail) {
        debugPrint('===> fetch more stocks fail $fail');
        refreshController?.loadFailed();
      },
    );
  }

  Future<void> initialFetchStocks() async {
    if (state.stocks.isNotEmpty) {
      return;
    }
    _page = 0;
    _hasMore = true;
    state = state.copyWith(isLoading: true);
    final response = await _stockRepository.getStocks(page: ++_page);
    response.when(
      success: (data) {
        List<Stocks> stocks = data.data ?? [];
        _hasMore = stocks.length >= 10;
        state = state.copyWith(isLoading: false, stocks: stocks);
      },
      failure: (fail) {
        debugPrint('===> fetch stock fail $fail');
        state = state.copyWith(isLoading: false);
      },
    );
  }

  Future<void> refreshStocks({RefreshController? refreshController}) async {
    refreshController?.resetNoData();
    _hasMore = true;
    _page = 0;
    final response = await _stockRepository.getStocks(
      page: ++_page,
    );
    response.when(
      success: (data) {
        final List<Stocks> stocks = data.data ?? [];
        state = state.copyWith(stocks: stocks);
        _hasMore = stocks.length >= 10;
        refreshController?.refreshCompleted();
      },
      failure: (error) {
        debugPrint('===> initial fetch stocks fail $error');
        refreshController?.refreshFailed();
      },
    );
  }

}

