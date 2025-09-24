import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:admin_desktop/src/models/models.dart';
part 'add_discount_state.freezed.dart';

@freezed
class AddDiscountState with _$AddDiscountState {
  const factory AddDiscountState({
    @Default("fix") String type,
    @Default(true) bool active,
    @Default(0) int price,
    String? imageFile,
    @Default([]) List<Stocks> stocks,
    @Default(false) bool isLoading,
    DateTime? startDate,
    DateTime? endDate,
    TextEditingController? dateController,
  }) = _AddDiscountState;

  const AddDiscountState._();
}

