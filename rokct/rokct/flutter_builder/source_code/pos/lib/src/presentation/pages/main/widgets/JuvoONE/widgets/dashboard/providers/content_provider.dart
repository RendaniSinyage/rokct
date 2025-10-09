
// Provider to manage the current content of DashboardEntry
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shop_dashboard_grid.dart';

final dashboardContentProvider = StateNotifierProvider<DashboardContentNotifier, Widget>((ref) {
  return DashboardContentNotifier();
});

class DashboardContentNotifier extends StateNotifier<Widget> {
  DashboardContentNotifier() : super(const ShopsDashboardGrid());

  void changeContent(Widget newContent) {
    state = newContent;
  }
}

// Provider to manage dashboard view mode
final dashboardViewModeProvider = StateNotifierProvider<DashboardViewModeNotifier, int>((ref) {
  return DashboardViewModeNotifier();
});

class DashboardViewModeNotifier extends StateNotifier<int> {
  DashboardViewModeNotifier() : super(0);

  void changeViewMode(int mode) {
    state = mode;
  }
}
