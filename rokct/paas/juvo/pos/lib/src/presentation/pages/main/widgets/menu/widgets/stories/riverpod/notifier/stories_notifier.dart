import 'package:admin_desktop/src/repository/stories_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:admin_desktop/src/core/utils/app_helpers.dart';
import '../../../../../../../../../models/data/stories_data.dart';
import '../state/stories_state.dart';

class StoriesNotifier extends StateNotifier<StoriesState> {
  final StoriesRepository _storiesRepository;
  int _page = 0;

  StoriesNotifier(this._storiesRepository) : super(const StoriesState());

  fetchStories({
    BuildContext? context,
    bool? isRefresh,
    RefreshController? controller,
  }) async {
    if (isRefresh ?? false) {
      controller?.resetNoData();
      _page = 0;
      state = state.copyWith(stories: [], isLoading: true);
    }
    final res = await _storiesRepository.getStories(
      page: ++_page,
    );
    res.when(success: (data) {
      List<StoriesData> list = List.from(state.stories);
      list.addAll(data.data ?? []);
      state = state.copyWith(isLoading: false, stories: list);
      if (isRefresh ?? false) {
        controller?.refreshCompleted();
        return;
      } else if (data.data?.isEmpty ?? true) {
        controller?.loadNoData();
        return;
      }
      controller?.loadComplete();
      return;
    }, failure: (failure) {
      state = state.copyWith(isLoading: false);
      debugPrint(" ==> fetch brands fail: $failure");
      if (context != null) {
        AppHelpers.showSnackBar(context, failure.toString());
      }
    });
  }

  deleteStories({BuildContext? context, int? id}) async {
    if (id == null) return;
    List<StoriesData> list = List.from(state.stories);
    list.removeWhere((element) => element.id == id);
    state = state.copyWith(stories: list);
    final res = await _storiesRepository.deleteStories(id);
    res.when(
        success: (data) {},
        failure: (failure) {
          state = state.copyWith(isLoading: false);
          debugPrint(" ==> delete stories fail: $failure");
          if (context != null) {
            AppHelpers.showSnackBar(context, failure.toString());
          }
        });
  }
}

