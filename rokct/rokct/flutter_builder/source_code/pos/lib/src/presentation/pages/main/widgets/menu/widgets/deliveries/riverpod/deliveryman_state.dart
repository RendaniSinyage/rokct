import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../../../../../models/data/user_data.dart';
part 'deliveryman_state.freezed.dart';

@freezed
class DeliverymanState with _$DeliverymanState {
  const factory DeliverymanState({
    @Default(false) bool isLoading,
    @Default(false) bool isUpdate,
    @Default(true) bool hasMore,
    @Default([]) List<UserData> users,
    @Default(-1) int statusIndex,
  }) = _DeliverymanState;

  const DeliverymanState._();
}

