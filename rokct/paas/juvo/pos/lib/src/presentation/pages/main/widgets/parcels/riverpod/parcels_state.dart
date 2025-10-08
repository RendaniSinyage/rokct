import 'package:admin_desktop/src/models/data/parcel_order_list_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'parcels_state.freezed.dart';

@freezed
class ParcelsState with _$ParcelsState {
  const factory ParcelsState({
    @Default(false) bool isLoading,
    @Default([]) List<ParcelOrderListData> parcelOrders,
  }) = _ParcelsState;
}