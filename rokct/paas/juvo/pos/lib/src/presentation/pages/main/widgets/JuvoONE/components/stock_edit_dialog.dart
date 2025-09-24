import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../core/constants/constants.dart';
import '../../../../../../core/utils/utils.dart';
import '../../../../../../models/data/addons_data.dart';
import '../../../../../../models/models.dart';
import '../../../../../theme/theme.dart';
import '../../../riverpod/provider/main_provider.dart';
import '../../inventory/provider/products_repository_provider.dart';
import '../utils/stock_helpers.dart';

class StockEditDialog extends ConsumerStatefulWidget {
  final ProductData product;
  final Stocks? stock;

  const StockEditDialog({
    super.key,
    required this.product,
    this.stock,
  });

  @override
  ConsumerState<StockEditDialog> createState() => _StockEditDialogState();
}

class _StockEditDialogState extends ConsumerState<StockEditDialog> {
  final Map<String, Map<String, dynamic>> stockStateMap = {};
  late List<StockEditController> stockControllers;
  bool isLoading = false;
  Map<String, List<Extras>> selectedExtras = {};
  List<Stocks> localStocks = [];

  String _getStockKey(Stocks stock) {
    return '${stock.extras?.map((e) => "${e.group?.id}-${e.value}").join("-")}-${stock.product?.translation?.title}';
  }


  @override
  void initState() {
    super.initState();
    initializeStockControllers();
  }


  void initializeStockControllers() {
    stockControllers = [];
    Map<String, Stocks> stockMap = {};

    if (widget.stock != null) {
      // When editing a single stock
      var key = '${widget.stock!.extras?.map((e) => e.value).join("-")}-${widget.stock!.product?.translation?.title}';
      stockMap[key] = _createStockCopy(widget.stock!);
    } else {
      // When creating new or editing multiple, group stocks by their extras combination
      for (var stock in (widget.product.stocks ?? [])) {
        var key = '${stock.extras?.map((e) => e.value).join("-")}-${stock.product?.translation?.title}';
        stockMap[key] = _createStockCopy(stock);
      }
    }

    // Create controllers for each stock
    localStocks = stockMap.values.toList();
    stockControllers = localStocks.map((stock) => StockEditController(
      quantityController: TextEditingController(text: stock.quantity?.toString() ?? '0'),
      priceController: TextEditingController(text: stock.price?.toString() ?? '0'),
      extrasControllers: _createExtrasControllers(stock.extras ?? []),
      addonControllers: _createAddonControllers(stock.addons ?? []),
    )).toList();

    // Initialize selected extras
    _initializeSelectedExtras();
  }

  void _saveStockState(Stocks stock, StockEditController controller) {
    final key = _getStockKey(stock);
    stockStateMap[key] = {
      'quantity': controller.quantityController.text,
      'price': controller.priceController.text,
      'addons': controller.addonControllers.map((ac) => {
        'id': ac.addon.id,
        'quantity': ac.quantityController.text,
        'price': ac.priceController.text,
        'active': ac.isEnabled,
      }).toList(),
    };
  }

  List<ExtrasEditController> _createExtrasControllers(List<Extras> extras) {
    // Ensure we create controllers for all extras
    return extras.map((extra) => ExtrasEditController(
      title: extra.group?.translation?.title ?? '',
      value: extra.value ?? '',
      groupId: extra.group?.id,
    )).toList();
  }

  List<AddonEditController> _createAddonControllers(List<Addons> addons) {
    // Create controllers for all addons, including inactive ones
    return addons.map((addon) => AddonEditController(
      quantityController: TextEditingController(
          text: addon.quantity?.toString() ?? '1'
      ),
      priceController: TextEditingController(
          text: addon.price?.toString() ?? '0'
      ),
      isEnabled: addon.active ?? false,
      addon: addon,
    )).toList();
  }

  Stocks _createStockCopy(Stocks original) {
    return Stocks(
      id: original.id,
      countableId: original.countableId,
      price: original.price,
      quantity: original.quantity,
      discount: original.discount,
      tax: original.tax,
      totalPrice: original.totalPrice,
      img: original.img,
      sku: original.sku,
      translation: original.translation,
      extras: original.extras?.map((e) => Extras(
        id: e.id,
        extraGroupId: e.extraGroupId,
        value: e.value,
        group: e.group != null ? Group(
          id: e.group!.id,
          type: e.group!.type,
          active: e.group!.active,
          translation: e.group!.translation,
        ) : null,
      )).toList(),
      addons: original.addons?.map((a) => Addons(
        id: a.id,
        stockId: a.stockId,
        addonId: a.addonId,
        product: a.product,
        price: a.price,
        quantity: a.quantity,
        active: a.active,
        stocks: a.stocks,
      )).toList(),
      product: original.product,
    );
  }

  void _initializeSelectedExtras() {
    selectedExtras.clear();
    // Initialize from all stocks to ensure we capture all extras
    for (var stock in localStocks) {
      for (var extra in stock.extras ?? []) {
        if (extra.group?.id != null) {
          final groupId = extra.group!.id.toString();
          if (!selectedExtras.containsKey(groupId)) {
            selectedExtras[groupId] = [];
          }
          if (!selectedExtras[groupId]!.any((e) => e.value == extra.value)) {
            selectedExtras[groupId]!.add(extra);
          }
        }
      }
    }
  }

  void _handleExtraSelected(String groupId, Extras extra) {
    setState(() {
      if (!selectedExtras.containsKey(groupId)) {
        selectedExtras[groupId] = [];
      }

      var existingIndex = selectedExtras[groupId]!.indexWhere((e) => e.value == extra.value);
      if (existingIndex != -1) {
        selectedExtras[groupId]!.removeAt(existingIndex);
        if (selectedExtras[groupId]!.isEmpty) {
          selectedExtras.remove(groupId);
        }
      } else {
        selectedExtras[groupId]!.add(extra);
      }
    });
    _updateStocksBasedOnExtras();
  }

  void _updateStocksBasedOnExtras() {
    Map<String, Stocks> existingStockMap = {};

    // Create a map of existing stocks by their extras combination
    for (var stock in localStocks) {
      String key = '${stock.extras?.map((e) => e.value).join("-")}-${stock.product?.translation?.title}';
      existingStockMap[key] = stock;
    }

    if (selectedExtras.isEmpty) {
      setState(() {
        // Preserve existing stocks if they have no extras
        localStocks = existingStockMap.values.where((s) => s.extras?.isEmpty ?? true).toList();
        if (localStocks.isEmpty) {
          // If no stocks without extras exist, create default ones
          localStocks = [
            Stocks(
              price: 0,
              quantity: 0,
              addons: widget.product.addons?.map((a) => Addons(
                id: a.id,
                stockId: a.stockId,
                addonId: a.addonId,
                product: a.product,
                price: a.price,
                quantity: 1,
                active: false,
                stocks: a.stocks,
              )).toList(),
            )
          ];
        }
        stockControllers = localStocks.map((stock) => _createDefaultControllerFromStock(stock)).toList();
      });
      return;
    }

    // Get all combinations of selected extras
    List<List<Extras>> combinations = StockHelpers.cartesian(
      selectedExtras.values.toList(),
    );

    setState(() {
      // Create or update stocks for each combination
      localStocks = combinations.map((extras) {
        String key = '${extras.map((e) => e.value).join("-")}-${widget.product.translation?.title}';
        var existingStock = existingStockMap[key];

        if (existingStock != null) {
          // Use existing stock values
          return _createStockCopy(existingStock);
        } else {
          // Create new stock with default values
          return Stocks(
            price: 0,
            quantity: 0,
            extras: extras,
            addons: widget.product.addons?.map((a) => Addons(
              id: a.id,
              stockId: a.stockId,
              addonId: a.addonId,
              product: a.product,
              price: a.price,
              quantity: 1,
              active: false,
              stocks: a.stocks,
            )).toList(),
          );
        }
      }).toList();

      // Update controllers
      stockControllers = localStocks.map((stock) => StockEditController(
        quantityController: TextEditingController(text: stock.quantity?.toString() ?? '0'),
        priceController: TextEditingController(text: stock.price?.toString() ?? '0'),
        extrasControllers: _createExtrasControllers(stock.extras ?? []),
        addonControllers: _createAddonControllers(stock.addons ?? []),
      )).toList();
    });
  }

  StockEditController _createDefaultControllerFromStock(Stocks stock) {
    return StockEditController(
      quantityController: TextEditingController(text: stock.quantity?.toString() ?? '0'),
      priceController: TextEditingController(text: stock.price?.toString() ?? '0'),
      extrasControllers: [],
      addonControllers: _createAddonControllers(stock.addons ?? []),
    );
  }

  bool _areExtrasEqual(List<Extras> extras1, List<Extras> extras2) {
    if (extras1.length != extras2.length) return false;
    return extras1.every((e1) => extras2.any((e2) =>
    e1.group?.id == e2.group?.id && e1.value == e2.value
    ));
  }

  StockEditController _createDefaultController() {
    return StockEditController(
      quantityController: TextEditingController(text: '0'),
      priceController: TextEditingController(text: '0'),
      extrasControllers: [],
      addonControllers: _createAddonControllers(widget.product.addons ?? []),
    );
  }

  void _handleSave() async {
    if (widget.product.uuid == null) return;

    // Create new stocks with updated values
    List<Stocks> updatedStocks = [];
    for (var i = 0; i < localStocks.length; i++) {
      final controller = stockControllers[i];
      final originalStock = localStocks[i];

      // Create updated addons list
      List<Addons> updatedAddons = [];
      for (var j = 0; j < (originalStock.addons?.length ?? 0); j++) {
        if (j < controller.addonControllers.length) {
          final addonController = controller.addonControllers[j];
          final originalAddon = originalStock.addons![j];

          updatedAddons.add(Addons(
            id: originalAddon.id,
            stockId: originalAddon.stockId,
            addonId: originalAddon.addonId,
            product: originalAddon.product,
            price: double.tryParse(addonController.priceController.text) ?? 0,
            quantity: int.tryParse(addonController.quantityController.text) ?? 0,
            active: addonController.isEnabled,
            stocks: originalAddon.stocks,
          ));
        }
      }

      // Create new stock with updated values
      updatedStocks.add(Stocks(
        id: originalStock.id,
        countableId: originalStock.countableId,
        price: double.tryParse(controller.priceController.text) ?? 0,
        quantity: int.tryParse(controller.quantityController.text) ?? 0,
        discount: originalStock.discount,
        tax: originalStock.tax,
        totalPrice: originalStock.totalPrice,
        img: originalStock.img,
        sku: originalStock.sku,
        translation: originalStock.translation,
        extras: originalStock.extras,
        addons: updatedAddons,
        product: originalStock.product,
      ));
    }

    // Validate stocks before saving
    for (var stock in updatedStocks) {
      if (!StockHelpers.isValidStock(stock)) {
        AppHelpers.showSnackBar(
          context,
          AppHelpers.getTranslation(TrKeys.invalidStockData),
        );
        return;
      }
    }

    setState(() => isLoading = true);

    final response = await ref.read(productsRepositoryProvider).updateStocks(
      stocks: updatedStocks,
      deletedStocks: [],
      uuid: widget.product.uuid!,
    );

    setState(() => isLoading = false);

    response.when(
      success: (data) {
        // Update all stocks in state
        for (var stock in updatedStocks) {
          ref.read(mainProvider.notifier).updateProductStock(
            widget.product.uuid!,
            stock,
          );
        }

        AppHelpers.showSnackBar(
          context,
          AppHelpers.getTranslation(TrKeys.successfullyUpdated),
        );
        Navigator.pop(context);
      },
      failure: (error) {
        AppHelpers.showSnackBar(
          context,
          error.toString(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
          width: 600.w,
          padding: EdgeInsets.all(16.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Stock',
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              20.verticalSpace,

              // Show extras selection if product has any extras
              if (widget.product.stocks?.any((s) => s.extras?.isNotEmpty == true) ?? false)
                ExtrasSelectionWidget(
                  stocks: widget.product.stocks ?? [],  // Use all product stocks to show all possible extras
                  selectedExtras: selectedExtras,
                  onExtraSelected: _handleExtraSelected,
                ),

              // Stocks list with expanded height
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: stockControllers.length,
                  itemBuilder: (context, index) => StockEditItem(
                    controller: stockControllers[index],
                    stock: localStocks[index],
                    onStockChanged: () => setState(() {}),
                  ),
                ),
              ),

              20.verticalSpace,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(fontSize: 16.sp),
                    ),
                  ),
                  8.horizontalSpace,
                  ElevatedButton(
                    onPressed: isLoading ? null : _handleSave,
                    child: isLoading
                        ? SizedBox(
                      width: 20.r,
                      height: 20.r,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                        : Text(
                      'Save',
                      style: GoogleFonts.inter(fontSize: 16.sp),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
  }
}

class StockEditController {
  final TextEditingController quantityController;
  final TextEditingController priceController;
  final List<ExtrasEditController> extrasControllers;
  final List<AddonEditController> addonControllers;

  StockEditController({
    required this.quantityController,
    required this.priceController,
    this.extrasControllers = const [],
    this.addonControllers = const [],
  });

  void dispose() {
    quantityController.dispose();
    priceController.dispose();
    for (var controller in addonControllers) {
      controller.dispose();
    }
  }
}

class ExtrasEditController {
  final String title;
  final String value;
  final int? groupId;

  ExtrasEditController({
    required this.title,
    required this.value,
    this.groupId,
  });
}

class AddonEditController {
  final TextEditingController quantityController;
  final TextEditingController priceController;
  bool isEnabled;
  final Addons addon;

  AddonEditController({
    required this.quantityController,
    required this.priceController,
    required this.isEnabled,
    required this.addon,
  });

  void dispose() {
    quantityController.dispose();
    priceController.dispose();
  }
}

class StockEditItem extends StatelessWidget {
  final StockEditController controller;
  final Stocks stock;
  final VoidCallback onStockChanged;

  const StockEditItem({
    super.key,
    required this.controller,
    required this.stock,
    required this.onStockChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.r),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppStyle.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppStyle.shimmerBase),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show extras combination
          if (stock.extras?.isNotEmpty == true)
            Wrap(
              spacing: 8.r,
              runSpacing: 8.r,
              children: stock.extras!.map((extra) => Chip(
                label: Text('${extra.group?.translation?.title}: ${extra.value}'),
              )).toList(),
            ),

          16.verticalSpace,

          // Stock quantity and price
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.quantityController,
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => onStockChanged(),
                ),
              ),
              16.horizontalSpace,
              Expanded(
                child: TextField(
                  controller: controller.priceController,
                  decoration: InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => onStockChanged(),
                ),
              ),
            ],
          ),

          // Addons section
          if (controller.addonControllers.isNotEmpty) ...[
            16.verticalSpace,
            Text(
              'Addons',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            8.verticalSpace,
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.addonControllers.length,
              itemBuilder: (context, index) => AddonEditItem(
                controller: controller.addonControllers[index],
                onChanged: onStockChanged,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AddonEditItem extends StatelessWidget {
  final AddonEditController controller;
  final VoidCallback onChanged;

  const AddonEditItem({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.r),
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: AppStyle.shimmerBase.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Checkbox(
            value: controller.isEnabled,
            onChanged: (value) {
              controller.isEnabled = value ?? false;
              onChanged();
            },
          ),
          8.horizontalSpace,
          Expanded(
            flex: 2,
            child: Text(
              controller.addon.product?.translation?.title ?? '',
              style: GoogleFonts.inter(fontSize: 14.sp),
            ),
          ),
          8.horizontalSpace,
          Expanded(
            child: TextField(
              controller: controller.quantityController,
              decoration: InputDecoration(
                labelText: 'Qty',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => onChanged(),
            ),
          ),
          8.horizontalSpace,
          Expanded(
            child: TextField(
              controller: controller.priceController,
              decoration: InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => onChanged(),
            ),
          ),
        ],
      ),
    );
  }
}

class ExtrasSelectionWidget extends StatelessWidget {
  final List<Stocks> stocks;
  final Map<String, List<Extras>> selectedExtras;
  final Function(String, Extras) onExtraSelected;

  const ExtrasSelectionWidget({
    super.key,
    required this.stocks,
    required this.selectedExtras,
    required this.onExtraSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (stocks.isEmpty) return const SizedBox.shrink();

    final stock = stocks.first;
    if (stock.extras?.isEmpty ?? true) return const SizedBox.shrink();

    // Group extras by group ID
    final Map<int, List<Extras>> groupedExtras = {};
    final Map<int, String> groupTitles = {};

    // Collect all unique extras from all stocks
    for (var stock in stocks) {
      for (var extra in stock.extras ?? []) {
        if (extra.group?.id != null) {
          final groupId = extra.group!.id!;
          if (!groupedExtras.containsKey(groupId)) {
            groupedExtras[groupId] = [];
            groupTitles[groupId] = extra.group?.translation?.title ?? '';
          }
          if (!groupedExtras[groupId]!.any((e) => e.value == extra.value)) {
            groupedExtras[groupId]!.add(extra);
          }
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Extras',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        12.verticalSpace,
        ...groupedExtras.entries.map((entry) {
          final groupId = entry.key;
          final extras = entry.value;
          final groupTitle = groupTitles[groupId] ?? '';

          return Container(
            margin: EdgeInsets.only(bottom: 16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupTitle,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                8.verticalSpace,
                Wrap(
                  spacing: 8.r,
                  runSpacing: 8.r,
                  children: extras.map((extra) {
                    final isSelected = selectedExtras[groupId.toString()]?.any(
                          (e) => e.id == extra.id && e.value == extra.value,
                    ) ?? false;

                    return FilterChip(
                      label: Text(extra.value ?? ''),
                      selected: isSelected,
                      onSelected: (_) => onExtraSelected(groupId.toString(), extra),
                      backgroundColor: AppStyle.white,
                      selectedColor: AppStyle.primary,
                      labelStyle: GoogleFonts.inter(
                        color: isSelected ? AppStyle.white : AppStyle.black,
                        fontSize: 14.sp,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        side: BorderSide(
                          color: isSelected ? AppStyle.primary : AppStyle.shimmerBase,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }).toList(),
        20.verticalSpace,
      ],
    );
  }
}
