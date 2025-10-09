import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../../core/utils/local_storage.dart';
import '../../riverpod/provider/wateros_orders_provider.dart';
import 'dashboard_page.dart';
import 'providers/content_provider.dart';
import 'shop_dashboard_grid.dart';
import 'dash_tabs.dart';


class DashboardEntry extends ConsumerStatefulWidget {
  const DashboardEntry({super.key});

  @override
  ConsumerState<DashboardEntry> createState() => _DashboardEntryState();
}

class _DashboardEntryState extends ConsumerState<DashboardEntry> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserShop();
  }

  Future<void> _checkUserShop() async {
    try {
      final userData = LocalStorage.getUser();

      if (userData?.shop?.id != null) {
        // Pre-fetch orders data for this shop
        await ref.read(waterosOrdersProvider.notifier).fetchOrders(userData!.shop!.id);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking user shop: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Watch the content from the provider
    final currentContent = ref.watch(dashboardContentProvider);

    return currentContent;
  }
}
