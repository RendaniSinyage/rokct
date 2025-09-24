import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/roSystem/models/data/dummy_data.dart';
import '../models/resource_data.dart';

class ResourcesNotifier extends StateNotifier<AsyncValue<ResourceData?>> {
  ResourcesNotifier() : super(const AsyncValue.loading()) {
    _initializeWithDummyData();
  }

  void _initializeWithDummyData() {
    try {
      final data = ResourceData.fromJson(dummyData.first);
      state = AsyncValue.data(data);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> fetchResources() async {
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(seconds: 1)); // Simulating network delay
    try {
      final data = ResourceData.fromJson(dummyData.first);
      state = AsyncValue.data(data);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final resourcesProvider = StateNotifierProvider<ResourcesNotifier, AsyncValue<ResourceData?>>((ref) {
  return ResourcesNotifier();
});
