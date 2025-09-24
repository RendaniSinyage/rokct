import 'dart:async';
import 'dart:math' show max;
import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../../core/constants/constants.dart';
import '../../../../../../../core/utils/utils.dart';
import '../../../../../../../models/data/order_data.dart';
import '../../../../../../../models/models.dart';
import '../../../../../../../repository/repository.dart';
import '../../../../../../components/buttons/refresh/refresh_button.dart';
import '../../../../../../components/custom_scaffold.dart';
import '../../../../../../theme/theme.dart';
import '../roSystem/models/data/energy_data.dart';
import '../roSystem/models/data/ro_system_model.dart';
import '../roSystem/models/data/tank_models.dart';
import '../roSystem/repository/energy_api.dart';
import '../roSystem/repository/tanks_api.dart';
import '../../riverpod/provider/wateros_orders_provider.dart';
import '../cards.dart';
import '../roSystem/maintenance/maintenance_service.dart';
import '../roSystem/setup_dialog.dart';
import '../roSystem/tanks/tank_setup_dialog.dart';
import 'providers/tanks_data_provider.dart';
import 'shop_dashboard_grid.dart';

@RoutePage()
class DashboardPage extends ConsumerStatefulWidget {
  final int? shopId;
  final VoidCallback? onBackToGrid;

  const DashboardPage({super.key, this.shopId,  this.onBackToGrid});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> with RefreshablePageMixin {
  late ShopsRepository _shopsRepository;

  // State variables
  bool _isLoadingTanks = false;
  bool usingFallbackData = false;
  bool showFullStats = false;
  bool showFullConfig = false;
  String? error;
  String? _tankError;
  DateTime? _lastSuccessfulUpdate;
  int? _shopId;

  // Data states
  EnergyConsumptionData? _energyData;
  ShopData? shopData;
  ROSystem? _roSystem;
  List<Tank> _tanks = [];
  double _systemEfficiency = 0.0;
  final Key _usageStatsKey = UniqueKey();

  // Usage stats
  int totalMonthlyUsage = 0;
  Map<String, int> usageStats = {
    'today': 0,
    'week': 0,
    'month': 0,
    'lastMonth': 0,
  };

  // Tank selection state
  Map<String, int?> selectedTanks = {
    TankType.raw.toString().split('.').last: null,
    TankType.purified.toString().split('.').last: null,
  };

  Timer? _refreshTimer;
  Timer? _retryTimer;
  final _retryInterval = const Duration(seconds: 30);
  static const _maxRetryAttempts = 3;


  @override
  void initState() {
    super.initState();
    _shopsRepository = GetIt.instance<ShopsRepository>();

    // Ensure we get a shop ID from one of these sources
    _shopId = widget.shopId;
    _shopId ??= ref.read(selectedShopProvider);

    // If still null, try to get current user's shop
    if (_shopId == null) {
      _getCurrentUserShop();
    }

    // Check for cached data
    if (_shopId != null) {
      _loadCachedData();
    }

    _startRefreshTimer();
    onRefresh();
  }

  // Add this method to load data from cache
  void _loadCachedData() {
    final tanksCache = ref.read(tanksDataProvider);
    final roSystemCache = ref.read(roSystemDataProvider);
    final energyCache = ref.read(energyDataProvider);

    // Load tanks data from cache if available
    if (tanksCache.containsKey(_shopId!) && tanksCache[_shopId!]!.isNotEmpty) {
      setState(() {
        _tanks = tanksCache[_shopId!]!;
        _isLoadingTanks = false;
      });
    }

    // Load RO system data from cache if available
    if (roSystemCache.containsKey(_shopId!) && roSystemCache[_shopId!] != null) {
      setState(() {
        _roSystem = roSystemCache[_shopId!];
      });
    }

    // Load energy data from cache if available
    if (energyCache.containsKey(_shopId!) && energyCache[_shopId!] != null) {
      setState(() {
        _energyData = energyCache[_shopId!];
      });
    }

    // Update last successful update timestamp
    if (_tanks.isNotEmpty || _roSystem != null || _energyData != null) {
      setState(() {
        _lastSuccessfulUpdate = DateTime.now();
      });
    }
  }

  Future<void> _getCurrentUserShop() async {
    try {
      final userData = LocalStorage.getUser();
      if (userData?.shop?.id != null) {
        setState(() {
          _shopId = userData!.shop!.id;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current user shop: $e');
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setupOrdersListener();
  }

  void _setupOrdersListener() {
    ref.listenManual(waterosOrdersProvider, (previous, next) {
      if (!mounted) return;

      // Skip if we're still loading
      if (next.isLoading) return;

      // Skip if there's an error
      if (next.hasError) {
        if (kDebugMode) {
          print('Error in orders data: ${next.error}');
        }
        return;
      }

      // Skip if there's no previous data to compare against
      if (previous == null || previous.value == null || next.value == null) return;

      try {
        // Check if there's been a meaningful change
        bool hasStatusChange = false;
        bool hasNewOrders = previous.value!.length != next.value!.length;

        if (!hasNewOrders) {
          // Create maps for quick lookup of orders by ID
          final prevOrderMap = {for (var order in previous.value!) order.id: order};
          final nextOrderMap = {for (var order in next.value!) order.id: order};

          // Check only for status changes in existing orders
          for (final order in next.value!) {
            final prevOrder = prevOrderMap[order.id];
            if (prevOrder != null && prevOrder.status != order.status) {
              hasStatusChange = true;
              break;
            }
          }
        }

        // Only update if we have new orders or status changes
        if (hasNewOrders || hasStatusChange) {
          if (mounted) {
            setState(() {
              _lastSuccessfulUpdate = DateTime.now();
              error = null;
            });

            // Only fetch tanks data as it's affected by order changes
            _fetchTanks().then((newTanks) {
              if (mounted) {
                setState(() {
                  _tanks = newTanks;
                });
              }
            }).catchError((e) {
              if (kDebugMode) {
                print('Error updating tanks after order change: $e');
              }
            });
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error processing orders update: $e');
        }
        // Don't update error state for listener issues to avoid triggering retries
      }
    });
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
        AppConstants.dashboardFetchTime,
            (_) => _backgroundRefresh()
    );
  }

  void _startRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(_retryInterval, (timer) async {
      if (_tanks.isEmpty && timer.tick <= _maxRetryAttempts) {
        if (kDebugMode) {
          print('Retry attempt ${timer.tick}');
        }
        await _backgroundRefresh();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _fetchEnergyData() async {
    try {
      final energyService = EnergyService();
      final data = await energyService.fetchEnergyConsumption(_shopId);

      // Update cache
      if (_shopId != null) {
        ref.read(energyDataProvider.notifier).update((state) {
          final newState = Map<int, EnergyConsumptionData?>.from(state);
          newState[_shopId!] = data;
          return newState;
        });
      }

      if (!mounted) return;
      setState(() {
        _energyData = data;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching energy data: $e');
      }
      // Don't update state if there's an error - keep existing data
    }
  }

  Future<void> _backgroundRefresh() async {
    if (!mounted || _shopId == null) return;

    try {
      // Shop Data
      try {
        final newShopData = await _fetchShopData();
        if (mounted) setState(() => shopData = newShopData);
      } catch (e) {
        if (kDebugMode) print('Error fetching shop data: $e');
      }

      // Tanks
      try {
        final newTanks = await _fetchTanks();
        if (mounted) setState(() => _tanks = newTanks);
      } catch (e) {
        if (kDebugMode) print('Error fetching tanks: $e');
      }

      // Orders
      try {
        await ref.read(waterosOrdersProvider.notifier).fetchOrders(_shopId);
      } catch (e) {
        if (kDebugMode) print('Error fetching orders: $e');
      }

      // RO System
      try {
        await _fetchROSystemData();
      } catch (e) {
        if (kDebugMode) print('Error fetching RO system: $e');
      }

      // Energy Data
      try {
        await _fetchEnergyData();
      } catch (e) {
        if (kDebugMode) print('Error fetching energy data: $e');
      }

      if (mounted) {
        setState(() {
          usingFallbackData = false;
          error = null;
          _tankError = null;
          _lastSuccessfulUpdate = DateTime.now();
        });
      }

    } catch (e) {
      if (kDebugMode) {
        print('Background refresh error: $e');
      }
      if (!mounted) return;

      // Only update error state if we have no existing data
      if (_tanks.isEmpty) {
        setState(() {
          error = 'Error updating dashboard: $e';
        });
        _startRetryTimer();
      }
    }
  }

  @override
  Future<void> onRefresh() async {
    if (!mounted || _shopId == null) return;

    setState(() {
      error = null;
      if (_tanks.isEmpty) {
        _isLoadingTanks = true;
      }
    });

    try {
      // Fetch data independently to maintain state
      final shopDataFuture = _fetchShopData();
      final tanksFuture = _fetchTanks();
      final ordersFuture = ref.read(waterosOrdersProvider.notifier).fetchOrders(_shopId);

      // Execute async operations that modify state directly
      // We don't include these in Future.wait since they update state internally
      await Future.wait([
        _fetchROSystemData(),
        _fetchEnergyData()
      ]);

      // Now get results from the others
      if (mounted) {
        final shopData = await shopDataFuture;
        final tanks = await tanksFuture;
        await ordersFuture;

        setState(() {
          this.shopData = shopData;
          _tanks = tanks;
          usingFallbackData = false;
          error = null;
          _isLoadingTanks = false;
          _lastSuccessfulUpdate = DateTime.now();
        });
      }
    } catch (e) {
      if (!mounted) return;

      if (_tanks.isEmpty) {
        setState(() {
          error = 'Error refreshing dashboard: $e';
          _isLoadingTanks = false;
        });
        _startRetryTimer();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating some data: $e'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<ShopData?> _fetchShopData() async {
    if (_shopId == null) return null;

    final shopDataResult = await _shopsRepository.getShopDataById(_shopId!);
    return shopDataResult.when(
      success: (editShopData) => ShopData(
        id: editShopData.id,
        translation: editShopData.translation,
        logoImg: editShopData.logoImg,
      ),
      failure: (err) => throw Exception(err),
    );
  }

// Also update the fetch methods to update the cache
  Future<List<Tank>> _fetchTanks() async {
    if (_shopId == null) return [];

    try {
      final tanks = await TankApiService.getTanksByShopId(_shopId!);
      if (!mounted) return tanks;

      // Update cache
      ref.read(tanksDataProvider.notifier).update((state) {
        final newState = Map<int, List<Tank>>.from(state);
        newState[_shopId!] = tanks;
        return newState;
      });

      setState(() {
        _tankError = null;
      });
      return tanks;
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching tanks: $e");
      }
      if (!mounted) rethrow;

      setState(() {
        _tankError = e.toString();
      });
      rethrow;
    }
  }

  Future<void> _fetchROSystemData() async {
    if (_shopId == null) return;

    try {
      final system = await MaintenanceService.getROSystemByShopId(_shopId!);

      // Get efficiency from shop dashboard API
      double efficiency = 0.0;
      final shopData = ref.read(shopsDashboardProvider);
      if (shopData.hasValue) {
        final shop = shopData.value!.firstWhere(
              (s) => s.id == _shopId,
          orElse: () => ShopDashboardSummary(id: 0, name: ''),
        );
        if (shop.id != 0 && shop.systemEfficiency != null) {
          efficiency = shop.systemEfficiency!;
        }
      }

      // Update cache
      ref.read(roSystemDataProvider.notifier).update((state) {
        final newState = Map<int, ROSystem?>.from(state);
        newState[_shopId!] = system;
        return newState;
      });

      if (!mounted) return;

      // Update state with data
      setState(() {
        _roSystem = system;
        _systemEfficiency = efficiency;

        // Also update total monthly usage from API
        final shop = shopData.value?.firstWhere(
              (s) => s.id == _shopId,
          orElse: () => ShopDashboardSummary(id: 0, name: '', ),
        );
        if (shop?.id != 0 && shop?.usageThisMonth != null) {
          totalMonthlyUsage = shop!.usageThisMonth!.toInt();
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching RO system data: $e");
      }
    }
  }

  double calculateWaterLevel(Tank tank) {
    try {
      if (tank.type == TankType.raw) {
        // For raw tanks, use the tank status
        return switch (tank.status) {
          TankStatus.full => tank.capacity,
          TankStatus.empty => 0,
          TankStatus.halfEmpty => tank.capacity * 0.5,
          TankStatus.quarterEmpty => tank.capacity * 0.75
        };
      } else {
        // For purified tanks
        // First, check if we have data from the API
        final shopData = ref.read(shopsDashboardProvider);
        if (shopData.hasValue) {
          final shop = shopData.value!.firstWhere(
                (s) => s.id == _shopId,
            orElse: () => ShopDashboardSummary(id: 0, name: '', ),
          );

          if (shop.id != 0 && shop.tankStatuses != null &&
              shop.tankStatuses!.containsKey('purified') &&
              shop.tankStatuses!['purified']['tanks'] != null) {

            final purifiedTanks = shop.tankStatuses!['purified']['tanks'];

            if (tank.number == 'ALL') {
              // For the "ALL" view, sum up total capacity and remaining from all tanks
              double totalCapacity = 0.0;
              double totalRemaining = 0.0;

              if (purifiedTanks is Map) {
                purifiedTanks.forEach((key, tankInfo) {
                  if (tankInfo['total_capacity'] != null) {
                    totalCapacity += (tankInfo['total_capacity'] as num).toDouble();
                  }
                  if (tankInfo['remaining_capacity'] != null) {
                    totalRemaining += (tankInfo['remaining_capacity'] as num).toDouble();
                  }
                });
              }

              return totalRemaining;
            } else {
              // For individual tanks, get the specific tank's remaining capacity
              if (purifiedTanks is Map && purifiedTanks[tank.number] != null) {
                final tankInfo = purifiedTanks[tank.number];
                if (tankInfo['remaining_capacity'] != null) {
                  return (tankInfo['remaining_capacity'] as num).toDouble();
                }
              }
            }
          }
        }

        // Fallback calculation if API data is not available
        if (tank.lastFull != null) {
          final usageThisMonth = usageStats['month'] ?? 0;
          return max(0, tank.capacity - usageThisMonth);
        }

        return tank.capacity * 0.5; // Default if we don't have any data
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating water level: $e');
      }
      return tank.capacity * 0.5; // Fallback
    }
  }

// Helper to get month usage from shop data
  double? getUsageThisMonth() {
    final shopData = ref.read(shopsDashboardProvider);
    if (!shopData.hasValue) return null;

    final shop = shopData.value!.firstWhere(
          (s) => s.id == _shopId,
      orElse: () => ShopDashboardSummary(id: 0, name: '', ),
    );

    return shop.id != 0 ? shop.usageThisMonth : null;
  }

// Helper method to get purified tank info from the API response
  Map<String, dynamic>? _getPurifiedTankInfo(int tankId) {
    try {
      final shopData = ref.read(shopsDashboardProvider);
      if (!shopData.hasValue) return null;

      // Find current shop - fixed to handle the return type correctly
      final currentShop = shopData.value!.firstWhere(
            (s) => s.id == _shopId,
        orElse: () => ShopDashboardSummary(
            id: 0,
            name: '',
            //logoImg: ''
        ), // Return empty shop object instead of null
      );

      // Skip if it's the empty/default shop
      if (currentShop.id == 0) return null;

      // Get purified tanks info
      final purifiedTanks = currentShop.tankStatuses?['purified']?['tanks'];
      if (purifiedTanks == null) return null;

      // If it's a map with numbered keys
      if (purifiedTanks is Map) {
        // Try to find our tank by ID in the values
        for (final tankInfo in purifiedTanks.values) {
          if (tankInfo['id'] == tankId) {
            return tankInfo;
          }
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting purified tank info: $e');
      }
      return null;
    }
  }


  int calculateUsage(List<OrderData> orders, DateTime start, DateTime end) {
    try {
      return orders
          .where((order) =>
      order.updatedAt != null &&
          order.updatedAt!.isAfter(start) &&
          order.updatedAt!.isBefore(end))
          .fold(0, (sum, order) => sum + _calculateOrderUsage(order));
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating usage: $e');
      }
      return 0;
    }
  }

  int _calculateOrderUsage(OrderData order) {
    try {
      return order.details?.fold(0, (sum, detail) {
        final stockId = detail.stockId.toString();
        final litres = AppConstants.stockIds[stockId];
        if (litres != null && detail.quantity != null) {
          return sum! + (litres * detail.quantity!).round();
        }
        return sum;
      }) ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating order usage: $e');
      }
      return 0;
    }
  }

  Future<void> _handleSystemSetup() async {
    await showDialog(
      context: context,
      builder: (context) => const SystemSetupDialog(),
    );
    await onRefresh();
  }

  Future<void> _showTankSetupDialog(Tank? tank, TankType type) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TankSetupDialog(
        initialTank: tank,
        defaultType: type,
      ),
    );

    if (result == true) {
      await _fetchTanks();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If no shop is selected, redirect to shop grid
    if (_shopId == null && widget.onBackToGrid != null) {
    // Call the callback instead of navigating to ShopsDashboardGrid
      widget.onBackToGrid!();
    return Container(); // Just a placeholder
    }

    if (error != null && _tanks.isEmpty) {
      return _buildErrorDisplay();
    }

    return CustomScaffold(
      body: (colors) => Padding(
        padding: REdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // NEW: Add this section to include a back button
            if (widget.onBackToGrid != null)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: widget.onBackToGrid,
                      tooltip: 'Back to shops grid',
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Shop Dashboard',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppStyle.black,
                      ),
                    ),
                  ],
                ),
              ),

            // EXISTING CONTENT: Wrap your existing content in an Expanded widget
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(
                              width: (constraints.maxWidth - 32) / 3,
                              child: _buildTank(TankType.raw),
                            ),
                            SizedBox(
                              width: (constraints.maxWidth - 32) / 3,
                              child: _buildROSystemMonitor(),
                            ),
                            SizedBox(
                              width: (constraints.maxWidth - 32) / 3,
                              child: _buildTank(TankType.purified),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorDisplay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            error ?? 'An error occurred',
            style: const TextStyle(color: AppStyle.red),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: onRefresh,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingDisplay() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildTank(TankType type) {
    if (_isLoadingTanks && _tanks.isEmpty) {
      return _buildLoadingDisplay();
    }

    if (_tankError != null && _tanks.isEmpty) {
      return Center(
        child: Text(_tankError!, style: const TextStyle(color: Colors.red)),
      );
    }

    final tanks = _tanks.where((tank) => tank.type == type).toList();

    if (tanks.isEmpty) {
      return _buildEmptyTankDisplay(type);
    }

    return _buildTankDisplay(tanks, type);
  }

  Widget _buildEmptyTankDisplay(TankType type) {
    return CustomCard(
      backgroundColor: type == TankType.raw
          ? AppStyle.grey[400]
          : AppStyle.blue[900]?.withOpacity(0.9),
      child: Column(
        children: [
          CustomCardHeader(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  type == TankType.raw ? 'Raw Water' : 'Purified Water',
                  style:  TextStyle(
                    color: AppStyle.black,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => _showTankSetupDialog(null, type),
                  icon: const Icon(Icons.add),
                  tooltip: 'Add new tank',
                ),
              ],
            ),
          ),
          // Rest of empty tank display implementation...
        ],
      ),
    );
  }

  Widget _buildTankDisplay(List<Tank> tanks, TankType type) {
    final tankNumbers = tanks.map((tank) => int.parse(tank.number)).toList();
    final selectedTankIndex = selectedTanks[type.toString().split('.').last];

    Tank getSelectedTankData() {
      if (selectedTankIndex != null && selectedTankIndex < tanks.length) {
        return tanks[selectedTankIndex];
      }

      // Calculate aggregated data for all tanks
      final totalCapacity = tanks.fold<double>(0, (sum, tank) => sum + tank.capacity);
      final totalWaterLevel = tanks.fold<double>(0, (sum, tank) => sum + calculateWaterLevel(tank));

      return Tank(
        shopId: tanks.first.shopId,
        number: 'ALL',
        type: type,
        capacity: totalCapacity,
        status: _calculateAggregateStatus(tanks),
        pumpStatus: _calculateAggregatePumpStatus(tanks),
        waterQuality: _calculateAverageWaterQuality(tanks),
      );
    }

    final selectedTankData = getSelectedTankData();

    return CustomCard(
      backgroundColor: type == TankType.raw
          ? AppStyle.grey[400]
          : AppStyle.blue[900]?.withOpacity(0.9),
      child: Column(
        children: [
          CustomCardHeader(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  type == TankType.raw ? 'Raw Water' : 'Purified Water',
                  style: TextStyle(
                    color: AppStyle.black,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => _showTankSetupDialog(null, type),
                  icon: const Icon(Icons.add),
                  color: AppStyle.black,
                  tooltip: 'Add new tank',
                ),
              ],
            ),
          ),
          CustomCardContent(
            child: Column(
              children: [
                WaterTank(
                  level: calculateWaterLevel(selectedTankData),
                  capacity: selectedTankData.capacity,
                  type: selectedTankData.type.toString().split('.').last,
                  width: 300.w,
                  tankNumbers: tankNumbers,
                  selectedTank: selectedTankIndex ?? -1,
                  onTankSelected: (index) {
                    setState(() {
                      if (index == selectedTankIndex) {
                        selectedTanks[type.toString().split('.').last] = null;
                      } else {
                        selectedTanks[type.toString().split('.').last] = index;
                      }
                    });
                  },
                  tankId: selectedTankData.id,
                  onStatusChanged: () async {
                    await _fetchTanks();  // Fetch updated tank data
                    setState(() {
                      // Force UI update for water levels
                      _lastSuccessfulUpdate = DateTime.now();
                    });
                    // Refresh orders data since it affects water level calculations
                    await _backgroundRefresh();
                  },
                ),
                SizedBox(height: 16.h),
                PumpStatus(
                  isOn: selectedTankData.pumpStatus['isOn'] as bool? ?? false,
                  flowRate: (selectedTankData.pumpStatus['flowRate'] as num?)?.toDouble() ?? 0.0,
                  tankId: selectedTankIndex != null ? tanks[selectedTankIndex].id : null,
                  currentLevel: calculateWaterLevel(selectedTankData),
                  capacity: selectedTankData.capacity,
                  tanks: _tanks,
                  calculateWaterLevel: calculateWaterLevel,
                  onStatusChanged: () async {
                    // Fetch updated tank data
                    try {
                      final updatedTanks = await _fetchTanks();
                      if (mounted) {
                        setState(() {
                          _tanks = updatedTanks;
                        });
                      }
                    } catch (e) {
                      if (kDebugMode) {
                        print('Error refreshing tanks after pump status change: $e');
                      }
                    }
                  },
                ),
                WaterQuality(
                  ph: (selectedTankData.waterQuality['ph'] as num?)?.toDouble() ?? 0.0,
                  tds: (selectedTankData.waterQuality['tds'] as num?)?.toInt() ?? 0,
                  temperature: (selectedTankData.waterQuality['temperature'] as num?)?.toDouble() ?? 0.0,
                  hardness: (selectedTankData.waterQuality['hardness'] as num?)?.toInt() ?? 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TankStatus _calculateAggregateStatus(List<Tank> tanks) {
    final statusCounts = {
      TankStatus.full: 0,
      TankStatus.empty: 0,
      TankStatus.halfEmpty: 0,
      TankStatus.quarterEmpty: 0,
    };

    for (var tank in tanks) {
      statusCounts[tank.status] = (statusCounts[tank.status] ?? 0) + 1;
    }

    if (statusCounts[TankStatus.empty]! > tanks.length / 2) {
      return TankStatus.empty;
    } else if (statusCounts[TankStatus.full]! > tanks.length / 2) {
      return TankStatus.full;
    } else if (statusCounts[TankStatus.halfEmpty]! > tanks.length / 2) {
      return TankStatus.halfEmpty;
    } else {
      return TankStatus.quarterEmpty;
    }
  }

  Map<String, dynamic> _calculateAggregatePumpStatus(List<Tank> tanks) {
    bool isAnyPumpOn = tanks.any((tank) => tank.pumpStatus['isOn'] == true);
    double totalFlowRate = tanks.fold(0.0, (sum, tank) =>
    sum + ((tank.pumpStatus['flowRate'] as num?)?.toDouble() ?? 0.0));

    return {
      'isOn': isAnyPumpOn,
      'flowRate': totalFlowRate
    };
  }

  Map<String, dynamic> _calculateAverageWaterQuality(List<Tank> tanks) {
    var sumPh = 0.0;
    var sumTds = 0;
    var sumTemp = 0.0;
    var sumHardness = 0;
    var count = 0;

    for (var tank in tanks) {
      final quality = tank.waterQuality;
      if (quality.isNotEmpty) {
        sumPh += (quality['ph'] as num?)?.toDouble() ?? 0.0;
        sumTds += (quality['tds'] as num?)?.toInt() ?? 0;
        sumTemp += (quality['temperature'] as num?)?.toDouble() ?? 0.0;
        sumHardness += (quality['hardness'] as num?)?.toInt() ?? 0;
        count++;
      }
    }

    if (count == 0) return {};

    return {
      'ph': sumPh / count,
      'tds': sumTds ~/ count,
      'temperature': sumTemp / count,
      'hardness': sumHardness ~/ count,
    };
  }

  Widget _buildROSystemMonitor() {
    bool isROSystemRunning = _tanks
        .where((tank) => tank.type == TankType.raw)
        .any((tank) => tank.pumpStatus['isOn'] == true);

    return _buildCustomCard(
      'RO System Monitor',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Status: ',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: AppStyle.grey[800],
                        ),
                      ),
                      Text(
                        isSystemConfigured() ? "Active" : "Not Configured",
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: isSystemConfigured() ? AppStyle.green : AppStyle.red,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8.w,
                            height: 8.h,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isROSystemRunning ? AppStyle.green : AppStyle.red,
                            ),
                          ),
                          Text(
                            isROSystemRunning ? "Running" : "Stopped",
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: isROSystemRunning ? AppStyle.green : AppStyle.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'System Efficiency: ',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: AppStyle.grey[800],
                        ),
                      ),
                      Text(
                        '${_systemEfficiency.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: _systemEfficiency >= 50 ? AppStyle.blue : AppStyle.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                color: AppStyle.black,
                onPressed: _handleSystemSetup,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildSystemDetails(),
          SizedBox(height: 16.h),
          _buildEfficiencyBreakdown(),
          SizedBox(height: 16.h),
          EnergyConsumption(
            dailyAverage: _energyData?.dailyAverage ?? 0.0,
            thisMonth: _energyData?.thisMonth ?? 0.0,
            lastMonth: _energyData?.lastMonth ?? 0.0,
          ),
          SizedBox(height: 16.h),
          EnvironmentalImpact(totalUsage: totalMonthlyUsage),
        ],
      ),
    );
  }

  Widget _buildCustomCard(String title, Widget content) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomCardHeader(
            child: Text(
              title,
              style: TextStyle(
                  color: AppStyle.black,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold
              ),
            ),
          ),
          CustomCardContent(child: content),
        ],
      ),
    );
  }

  Widget _buildSystemDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'System Configuration',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppStyle.grey[800],
              ),
            ),
            IconButton(
              icon: Icon(
                showFullConfig ? Icons.expand_less : Icons.expand_more,
                color: AppStyle.grey[600],
              ),
              onPressed: () => setState(() => showFullConfig = !showFullConfig),
            ),
          ],
        ),
        if (showFullConfig) ...[
          SizedBox(height: 8.h),
          _buildDetailItem(
              'MegaChar Vessels',
              _roSystem?.vessels
                  .where((v) => v.type == 'megaChar')
                  .length
                  .toString() ??
                  '0'),
          _buildDetailItem(
              'Softener Vessels',
              _roSystem?.vessels
                  .where((v) => v.type == 'softener')
                  .length
                  .toString() ??
                  '0'),
          _buildDetailItem(
              'RO Membranes',
              _roSystem?.membraneCount.toString() ?? '0'
          ),
          _buildDetailItem(
              'Pre Filters',
              _roSystem?.filters
                  .where((f) => f.location == FilterLocation.pre)
                  .length
                  .toString() ??
                  '0'),
          _buildDetailItem(
              'RO Filters',
              _roSystem?.filters
                  .where((f) => f.location == FilterLocation.ro)
                  .length
                  .toString() ??
                  '0'),
          _buildDetailItem(
              'Post Filters',
              _roSystem?.filters
                  .where((f) => f.location == FilterLocation.post)
                  .length
                  .toString() ??
                  '0'),
        ],
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: AppStyle.grey[400],
          ),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
              color: AppStyle.grey[600],
              fontSize: 14.sp,
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            value,
            style: TextStyle(
              color: AppStyle.grey[800],
              fontWeight: FontWeight.w500,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  bool isSystemConfigured() {
    return _roSystem != null &&
        _roSystem!.vessels.isNotEmpty &&
        _roSystem!.filters.any((f) => f.location == FilterLocation.ro);
  }

  Widget _buildEfficiencyBreakdown() {
    if (_roSystem == null) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Efficiency Breakdown',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppStyle.grey[800],
              ),
            ),
            IconButton(
              icon: Icon(
                showFullStats ? Icons.expand_less : Icons.expand_more,
                color: AppStyle.grey[600],
              ),
              onPressed: () => setState(() => showFullStats = !showFullStats),
            ),
          ],
        ),
        if (showFullStats) ...[
          SizedBox(height: 8.h),
          ..._roSystem!.vessels.map((vessel) => _buildEfficiencyItem(
            '${vessel.type == 'megaChar' ? 'MegaChar' : 'Softener'} ${vessel.id}',
            ROSystemEfficiency.calculateComponentEfficiency(
              installationDate: vessel.installationDate,
              lastMaintenanceDate: vessel.lastMaintenanceDate,
            ),
          )),
          ..._roSystem!.filters.map((filter) => _buildEfficiencyItem(
            '${_getFilterLocationName(filter.location)}: ${_getFilterTypeName(filter.type)}',
            ROSystemEfficiency.calculateComponentEfficiency(
              installationDate: filter.installationDate,
              replacementLifespan: ROSystemEfficiency.getFilterLifespan(filter.location),
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildEfficiencyItem(String label, double efficiency) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppStyle.grey[700],
              fontSize: 14.sp,
            ),
          ),
          Row(
            children: [
              Container(
                width: 100.w,
                height: 6.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: AppStyle.grey[200],
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: efficiency / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: _getEfficiencyColor(efficiency),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '${efficiency.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: AppStyle.grey[700],
                  fontWeight: FontWeight.w500,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFilterLocationName(FilterLocation location) {
    switch (location) {
      case FilterLocation.pre:
        return 'Pre Filter';
      case FilterLocation.ro:
        return 'RO Filter';
      case FilterLocation.post:
        return 'Post Filter';
    }
  }

  String _getFilterTypeName(FilterType type) {
    switch (type) {
      case FilterType.sediment:
        return 'Sediment';
      case FilterType.carbonBlock:
        return 'Carbon Block';
      case FilterType.birm:
        return 'Birm';
    }
  }

  Color _getEfficiencyColor(double efficiency) {
    if (efficiency >= 90) return AppStyle.green;
    if (efficiency >= 70) return AppStyle.blue;
    if (efficiency >= 50) return Colors.orange;
    return AppStyle.red;
  }
}
