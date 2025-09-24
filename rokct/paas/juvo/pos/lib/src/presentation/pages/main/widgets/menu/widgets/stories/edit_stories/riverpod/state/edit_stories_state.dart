import 'package:flutter/cupertino.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:admin_desktop/src/models/models.dart';
part 'edit_stories_state.freezed.dart';

@freezed
class EditStoriesState with _$EditStoriesState {
  const factory EditStoriesState({
    @Default(false) bool isLoading,
    @Default(null) ProductData? selectProduct,
    @Default([]) List<ProductData> products,
    @Default([]) List<String> images,
    @Default([]) List<String> listOfUrls,
    @Default(null) StoriesData? story,
    @Default(null) TextEditingController? textEditingController,
  }) = _EditStoriesState;

  const EditStoriesState._();
}

