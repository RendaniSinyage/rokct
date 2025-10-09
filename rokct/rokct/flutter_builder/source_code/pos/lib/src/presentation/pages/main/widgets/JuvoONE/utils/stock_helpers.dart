import 'package:admin_desktop/src/models/data/product_data.dart';

import '../../../../../../models/data/addons_data.dart';

class StockHelpers {
  /// Creates all possible combinations of extras
  static List<List<Extras>> cartesian(List<List<dynamic>> args) {
    List<List<Extras>> r = [];
    int max = args.length - 1;

    void helper(List<Extras> arr, int i) {
      for (int j = 0, l = args[i].length; j < l; j++) {
        List<Extras> a = List.from(arr);
        a.add(args[i][j]);
        if (i == max) {
          r.add(a);
        } else {
          helper(a, i + 1);
        }
      }
    }

    helper([], 0);
    return r;
  }

  /// Creates a new stock based on an existing one
  static Stocks createStockFromTemplate(Stocks template, {
    int? id,
    num? price,
    int? quantity,
    List<Extras>? extras,
    List<Addons>? addons,
  }) {
    return Stocks(
      id: id ?? template.id,
      countableId: template.countableId,
      price: price ?? template.price,
      quantity: quantity ?? template.quantity,
      tax: template.tax,
      extras: extras ?? template.extras,
      addons: addons ?? template.addons?.map((a) => Addons(
        id: a.id,
        stockId: a.stockId,
        addonId: a.addonId,
        product: a.product,
        price: a.price,
        quantity: a.quantity,
        active: a.active,
        stocks: a.stocks,
      )).toList(),
      product: template.product,
      translation: template.translation,
    );
  }

  /// Creates a new addon based on an existing one
  static Addons createAddonFromTemplate(Addons template, {
    int? quantity,
    num? price,
    bool? active,
  }) {
    return Addons(
      id: template.id,
      stockId: template.stockId,
      addonId: template.addonId,
      product: template.product,
      price: price ?? template.price,
      quantity: quantity ?? template.quantity,
      active: active ?? template.active,
      stocks: template.stocks,
    );
  }

  /// Calculates total price including enabled addons
  static double calculateTotalPrice(Stocks stock) {
    double basePrice = stock.price?.toDouble() ?? 0;
    double addonTotal = 0;

    for (var addon in stock.addons ?? []) {
      if (addon.active ?? false) {
        addonTotal += (addon.price?.toDouble() ?? 0) * (addon.quantity ?? 1);
      }
    }

    return basePrice + addonTotal;
  }

  /// Validates a stock's data
  static bool isValidStock(Stocks stock) {
    if (stock.price == null || stock.price! <= 0) return false;
    if (stock.quantity == null || stock.quantity! < 0) return false;

    // Validate addons if present
    if (stock.addons != null) {
      for (var addon in stock.addons!) {
        if (addon.price == null || addon.price! < 0) return false;
        if (addon.quantity == null || addon.quantity! < 0) return false;
      }
    }

    return true;
  }

  /// Gets a sorted, unique list of extras groups from a list of stocks
  static List<Group> getUniqueExtrasGroups(List<Stocks> stocks) {
    final Set<int> groupIds = {};
    final List<Group> groups = [];

    for (var stock in stocks) {
      for (var extra in stock.extras ?? []) {
        if (extra.group != null && !groupIds.contains(extra.group!.id)) {
          groupIds.add(extra.group!.id!);
          groups.add(extra.group!);
        }
      }
    }

    // Sort groups by title
    groups.sort((a, b) => (a.translation?.title ?? '').compareTo(b.translation?.title ?? ''));

    return groups;
  }

  /// Gets unique extras values for a specific group
  static List<Extras> getUniqueExtrasForGroup(List<Stocks> stocks, int groupId) {
    final Set<String> uniqueValues = {};
    final List<Extras> extras = [];

    for (var stock in stocks) {
      for (var extra in stock.extras ?? []) {
        if (extra.group?.id == groupId && !uniqueValues.contains(extra.value)) {
          uniqueValues.add(extra.value ?? '');
          extras.add(extra);
        }
      }
    }

    return extras;
  }

  /// Updates stock quantity and returns the new total
  static int updateStockQuantity(Stocks stock, int change) {
    final newQuantity = (stock.quantity ?? 0) + change;
    if (newQuantity < 0) return 0;
    return newQuantity;
  }
}
