import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dio/dio.dart';

import '../../../../../../../core/handlers/handlers.dart';
import '../../../../../../../core/routes/app_router.dart';
import '../../../../../../../core/utils/local_storage.dart';
import '../../../../../../components/custom_scaffold.dart';
import '../../../../../../theme/theme.dart';
import '../../riverpod/provider/wateros_orders_provider.dart';
import '../roSystem/maintenance/maintenance_service.dart';
import '../roSystem/repository/energy_api.dart';
import '../roSystem/repository/tanks_api.dart';
import 'dashboard_page.dart';
import 'shop_dashboard_card.dart';

// Provider to store the list of shops with their dashboard summaries
final shopsDashboardProvider = StateNotifierProvider<ShopsDashboardNotifier, AsyncValue<List<ShopDashboardSummary>>>((ref) {
  return ShopsDashboardNotifier();
});

// Provider to track the currently selected shop
final selectedShopProvider = StateProvider<int?>((ref) => null);

// NEW: Provider to control whether to show grid or dashboard
final showDashboardProvider = StateProvider<bool>((ref) => false);

// Model for shop dashboard summary data
class ShopDashboardSummary {
  final int id;
  final String name;
  //final String logoImg;
  final Map<String, dynamic>? tankStatuses;
  final int? orderCount;
  final double? systemEfficiency;
  final double? usageThisMonth;
  final double? lastMonthUsage;

  ShopDashboardSummary({
    required this.id,
    required this.name,
    //this.logoImg = '',
    this.tankStatuses,
    this.orderCount,
    this.systemEfficiency,
    this.usageThisMonth,
    this.lastMonthUsage,
  });

  factory ShopDashboardSummary.fromJson(Map<String, dynamic> json) {
    return ShopDashboardSummary(
      id: _parseId(json['id']),
      name: (json['name'] ?? 'Unknown Shop').toString(),
      //logoImg: (json['logo_img'] ?? '').toString(),
      tankStatuses: _parseTankStatuses(json['tank_statuses']),
      orderCount: _parseIntOrNull(json['order_count']),
      systemEfficiency: _parseDoubleOrNull(json['system_efficiency']),
      usageThisMonth: _parseDoubleOrNull(json['usage_this_month']),
      lastMonthUsage: _parseDoubleOrNull(json['last_month_usage']),
    );
  }

  // Helper methods for safe parsing
  static int _parseId(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static int? _parseIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _parseDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static Map<String, dynamic>? _parseTankStatuses(dynamic tankStatuses) {
    if (tankStatuses == null) return null;
    return tankStatuses is Map
        ? Map<String, dynamic>.from(tankStatuses)
        : null;
  }
}

// Notifier for shop dashboard data
class ShopsDashboardNotifier extends StateNotifier<AsyncValue<List<ShopDashboardSummary>>> {
  ShopsDashboardNotifier() : super(const AsyncValue.loading()) {
    fetchShopsDashboard();
  }

  Future<void> fetchShopsDashboard() async {
    try {
      state = const AsyncValue.loading();

      final httpService = HttpService();
      final dio = httpService.client(requireAuth: true);

      final response = await dio.get('/api/v1/dashboard/admin/shops/dashboard/summary');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> rawShopData = responseData['data'];

          // Process shops with error handling
          final List<ShopDashboardSummary> shops = await Future.wait(
              rawShopData.map((shopData) async {
                try {
                  final shop = ShopDashboardSummary.fromJson(shopData);
                  return await _enrichWithEfficiency(shop);
                } catch (e) {
                  if (kDebugMode) {
                    print('Error processing shop data: $e');
                  }
                  return ShopDashboardSummary(
                    id: ShopDashboardSummary._parseId(shopData['id']),
                    name: (shopData['name'] ?? 'Error Shop').toString(),
                  );
                }
              })
          );

          state = AsyncValue.data(shops);
        } else {
          state = AsyncValue.error(
            responseData['message'] ?? 'Failed to load shops',
            StackTrace.current,
          );
        }
      } else {
        state = AsyncValue.error(
          'Failed to load shops: ${response.statusCode}',
          StackTrace.current,
        );
      }
    } on DioException catch (e) {
      state = AsyncValue.error(
        'Network error: ${e.message}',
        StackTrace.current,
      );
    } catch (e, stackTrace) {
      state = AsyncValue.error(
        'Unexpected error: ${e.toString()}',
        stackTrace,
      );
    }
  }

  Future<ShopDashboardSummary> _enrichWithEfficiency(ShopDashboardSummary shop) async {
    // If efficiency is already set, return the shop as-is
    if (shop.systemEfficiency != null) return shop;

    try {
      final httpService = HttpService();
      final dio = httpService.client(requireAuth: true);

      final response = await dio.get('/api/v1/rest/resources/ro-systems/${shop.id}');

      if (response.statusCode == 200 && response.data['data'] != null) {
        final roSystem = response.data['data'];

        // Calculate efficiency
        final efficiency = _calculateSystemEfficiency(roSystem);

        // Return a new object with the calculated efficiency
        return ShopDashboardSummary(
          id: shop.id,
          name: shop.name,
          //Img: shop.logoImg,
          tankStatuses: shop.tankStatuses,
          orderCount: shop.orderCount,
          systemEfficiency: efficiency,
          usageThisMonth: shop.usageThisMonth,
          lastMonthUsage: shop.lastMonthUsage,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating efficiency for shop ${shop.id}: $e');
      }
    }

    // Return original if something went wrong
    return shop;
  }

  double _calculateSystemEfficiency(Map<String, dynamic> roSystem) {
    try {
      final vessels = roSystem['vessels'] as List? ?? [];
      final filters = roSystem['filters'] as List? ?? [];
      final membraneCount = roSystem['membrane_count'] as int? ?? 0;
      final membraneInstallationDate = roSystem['membrane_installation_date'] != null
          ? DateTime.parse(roSystem['membrane_installation_date'])
          : DateTime.now();

      double totalEfficiency = 0.0;
      int componentCount = 0;

      // Vessel efficiency calculation
      for (var vessel in vessels) {
        final installationDate = vessel['installation_date'] != null
            ? DateTime.parse(vessel['installation_date'])
            : DateTime.now();
        final lastMaintenanceDate = vessel['last_maintenance_date'] != null
            ? DateTime.parse(vessel['last_maintenance_date'])
            : null;

        final vesselEfficiency = _calculateComponentEfficiency(
          installationDate: installationDate,
          lastMaintenanceDate: lastMaintenanceDate,
        );

        totalEfficiency += vesselEfficiency;
        componentCount++;
      }

      // Filter efficiency calculation
      for (var filter in filters) {
        final installationDate = filter['installation_date'] != null
            ? DateTime.parse(filter['installation_date'])
            : DateTime.now();

        final filterEfficiency = _calculateComponentEfficiency(
          installationDate: installationDate,
          replacementLifespan: _getFilterLifespan(filter['location']),
        );

        totalEfficiency += filterEfficiency;
        componentCount++;
      }

      // Membrane efficiency
      if (membraneCount > 0) {
        final membraneEfficiency = _calculateComponentEfficiency(
          installationDate: membraneInstallationDate,
          replacementLifespan: 730, // 2 years for membranes
        );

        totalEfficiency += membraneEfficiency;
        componentCount++;
      }

      return componentCount > 0 ? (totalEfficiency / componentCount) : 0.0;
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating system efficiency: $e');
      }
      return 0.0;
    }
  }

  double _calculateComponentEfficiency({
    required DateTime installationDate,
    DateTime? lastMaintenanceDate,
    int? replacementLifespan,
  }) {
    final now = DateTime.now();
    final daysSinceInstallation = now.difference(installationDate).inDays;

    double baseEfficiency = 100.0;
    if (replacementLifespan != null) {
      baseEfficiency = 100.0 * (1 - (daysSinceInstallation / replacementLifespan)).clamp(0.0, 1.0);
    }

    // Maintenance boost if applicable
    if (lastMaintenanceDate != null) {
      final daysSinceMaintenance = now.difference(lastMaintenanceDate).inDays;
      const maintenanceEffectDays = 30; // Maintenance improves efficiency for 30 days
      const maintenanceBoost = 20.0; // Maintenance can boost efficiency by 20%

      if (daysSinceMaintenance <= maintenanceEffectDays) {
        final maintenanceMultiplier = 1 + (maintenanceBoost / 100) *
            (1 - daysSinceMaintenance / maintenanceEffectDays);
        baseEfficiency = (baseEfficiency * maintenanceMultiplier).clamp(0.0, 100.0);
      }
    }

    return baseEfficiency;
  }

  int _getFilterLifespan(String? location) {
    switch (location) {
      case 'pre':
        return 90; // 3 months
      case 'ro':
        return 180; // 6 months
      case 'post':
        return 90; // 3 months
      default:
        return 180; // Default to RO filter lifespan
    }
  }

  Future<void> refresh() async {
    await fetchShopsDashboard();
  }
}

class ShopsDashboardGrid extends ConsumerStatefulWidget {
  const ShopsDashboardGrid({super.key});

  @override
  ConsumerState<ShopsDashboardGrid> createState() => _ShopsDashboardGridState();
}

class _ShopsDashboardGridState extends ConsumerState<ShopsDashboardGrid> {
  bool _isCheckingUserShop = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserShop();
    });
  }

  // Check if user belongs to a single shop and navigate directly if they do
  Future<void> _checkUserShop() async {
    try {
      final userData = LocalStorage.getUser();
      if (userData?.shop?.id != null) {
        final shopId = userData!.shop!.id;

        // Set the selected shop ID in provider
        ref.read(selectedShopProvider.notifier).state = shopId;

        // NEW: Set to show dashboard instead of grid
        ref.read(showDashboardProvider.notifier).state = true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking user shop: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isCheckingUserShop = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopsAsync = ref.watch(shopsDashboardProvider);

    // Still checking user shop status
    if (_isCheckingUserShop) {
      return Scaffold(
        backgroundColor: AppStyle.bg,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return CustomScaffold(
        body: (c) => Padding(
          padding: REdgeInsets.symmetric(horizontal: 16),
          child: shopsAsync.when(
            data: (shops) {
              if (shops.isEmpty) {
                return Center(
                  child: Text(
                    'No shops found',
                    style: TextStyle(
                      color: AppStyle.black,
                      fontSize: 16.sp,
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => ref.read(shopsDashboardProvider.notifier).refresh(),
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : 2,
                      crossAxisSpacing: 12.r, // Reduced spacing
                      mainAxisSpacing: 12.r, // Reduced spacing
                      childAspectRatio: 2, // Adjusted ratio for better fit and less white space
                    ),
                    itemCount: shops.length,
                    itemBuilder: (context, index) {
                      final shop = shops[index];
                      return ShopDashboardCard(
                        shop: shop,
                        onTap: () async {
                          // Show a loading indicator
                          final overlay = _showLoadingOverlay(context);

                          try {
                            // Start preloading data in parallel
                            final shopId = shop.id;

                            // Set the selected shop ID first
                            ref.read(selectedShopProvider.notifier).state = shopId;

                            // Preload orders data
                            final ordersFuture = ref.read(waterosOrdersProvider.notifier).fetchOrders(shopId);

                            // Preload tanks data
                            final tanksFuture = TankApiService.getTanksByShopId(shopId);

                            // Preload RO system data
                            final roSystemFuture = MaintenanceService.getROSystemByShopId(shopId);

                            // Preload energy consumption data
                            final energyFuture = EnergyService().fetchEnergyConsumption(shopId);

                            // Wait for all preloading to complete
                            await Future.wait([
                              ordersFuture,
                              tanksFuture.then((tanks) {
                                // Cache the tanks data in a provider if needed
                              }).catchError((e) {
                                if (kDebugMode) {
                                  print('Error preloading tanks: $e');
                                }
                                // Continue despite errors
                                return null;
                              }),
                              roSystemFuture.then((roSystem) {
                                // Cache the RO system data if needed
                              }).catchError((e) {
                                if (kDebugMode) {
                                  print('Error preloading RO system: $e');
                                }
                                // Continue despite errors
                                return null;
                              }),
                              energyFuture.then((energyData) {
                                // Cache the energy data if needed
                              }).catchError((e) {
                                if (kDebugMode) {
                                  print('Error preloading energy data: $e');
                                }
                                // Continue despite errors
                                return null;
                              }),
                            ]);

                            // Remove loading overlay
                            overlay.remove();

                            // Now show the dashboard
                            ref.read(showDashboardProvider.notifier).state = true;
                          } catch (e) {
                            // Remove loading overlay in case of error
                            overlay.remove();

                            // Show error message
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error loading dashboard data: ${e.toString()}'),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }

                            if (kDebugMode) {
                              print('Error preloading dashboard data: $e');
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: $error',
                    style: TextStyle(
                      color: AppStyle.red,
                      fontSize: 16.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () => ref.read(shopsDashboardProvider.notifier).refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
// Add this helper method to show a loading overlay
OverlayEntry _showLoadingOverlay(BuildContext context) {
  final overlay = OverlayEntry(
    builder: (context) => Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading dashboard data...'),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Overlay.of(context).insert(overlay);
  return overlay;
}
