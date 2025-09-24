import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../../../../../../models/data/product_data.dart';
part 'stock_state.freezed.dart';

@freezed
class StockState with _$StockState {
  const factory StockState({
    @Default(false) bool isLoading,
    @Default([]) List<Stocks> stocks,
  }) = _StockState;

  const StockState._();
}

