
/*
import 'package:admin_desktop/src/core/utils/utils.dart';

import '../models.dart';

class Stock {
  Stock({
    int? id,
    int? countableId,
    num? price,
    num? discount,
    int? quantity,
    int? cartCount,
    num? tax,
    bool? bonus,
    bool? shopBonus,
    num? totalPrice,
    String? countableType,
    String? sku,
    ProductData? product,
    List<Extras>? extras,
    List<Group>? localGroups,
    Stock? stock,
    ProductData? countable,
    List<AddonData>? addons,
    List<AddonData>? localAddons,
  }) {
    _id = id;
    _countableId = countableId;
    _price = price;
    _discount = discount;
    _quantity = quantity;
    _cartCount = cartCount;
    _tax = tax;
    _bonus = bonus;
    _totalPrice = totalPrice;
    _product = product;
    _extras = extras;
    _localGroups = localGroups;
    _countableType = countableType;
    _stock = stock;
    _countable = countable;
    _sku = sku;
    _addons = addons;
    _localAddons = localAddons;
    _shopBonus = shopBonus;
  }

  Stock.fromJson(dynamic json) {
    _id = json['id'];
    _countableId = json['countable_id'];
    _price = json['price'];
    if (json['bonus'].runtimeType == bool) _bonus = json['bonus'];
    _discount = json['discount'];
    _quantity = json['quantity'];
    _sku = json['sku'];
    _cartCount = json['cart_count'] ?? 0;
    _tax = json['tax'];
    _totalPrice = json['total_price'];
    _shopBonus = json['bonus_shop']?.toString().toBool();
    _product =
        json['product'] != null ? ProductData.fromJson(json['product']) : null;
    if (json['stock_extras'] != null) {
      _extras = [];
      json['stock_extras'].forEach((v) {
        _extras?.add(Extras.fromJson(v));
      });
    }

    if (json['extras'] != null) {
      _extras = [];
      json['extras'].forEach((v) {
        _extras?.add(Extras.fromJson(v));
      });
    }

    _localGroups = [];
    _countableType = json['countable_type'];
    _stock = json['stock'] != null ? Stock.fromJson(json['stock']) : null;
    _countable = json['countable'] != null
        ? ProductData.fromJson(json['countable'])
        : null;
    if (json['addons'] != null) {
      _addons = [];
      json['addons'].forEach((v) {
        _addons?.add(AddonData.fromJson(v));
      });
    }
    if (json['addons'] != null) {
      _localAddons = [];
      json['addons'].forEach((v) {
        _localAddons?.add(AddonData.fromJson(v));
      });
    }
  }

  int? _id;
  int? _countableId;
  num? _price;
  num? _discount;
  int? _quantity;
  int? _cartCount;
  num? _tax;
  num? _totalPrice;
  bool? _bonus;
  bool? _shopBonus;
  ProductData? _product;
  List<Extras>? _extras;
  List<Group>? _localGroups;
  String? _countableType;
  String? _sku;
  Stock? _stock;
  ProductData? _countable;
  List<AddonData>? _addons;
  List<AddonData>? _localAddons;

  Stock copyWith({
    int? id,
    int? countableId,
    num? price,
    num? discount,
    int? quantity,
    int? cartCount,
    num? tax,
    bool? bonus,
    bool? shopBonus,
    num? totalPrice,
    ProductData? product,
    List<Extras>? extras,
    List<Group>? localGroups,
    bool isInitial = false,
    String? countableType,
    String? sku,
    Stock? stock,
    ProductData? countable,
    List<AddonData>? addons,
    List<AddonData>? localAddons,
  }) =>
      Stock(
          id: id ?? _id,
          bonus: bonus ?? _bonus,
          countableId: countableId ?? _countableId,
          price: isInitial ? num.tryParse('') : (price ?? _price),
          discount: isInitial ? num.tryParse('') : (discount ?? _discount),
          quantity: isInitial ? int.tryParse('') : (quantity ?? _quantity),
          cartCount: cartCount ?? _cartCount,
          tax: tax ?? _tax,
          totalPrice: totalPrice ?? _totalPrice,
          product: product ?? _product,
          extras: extras ?? _extras,
          localGroups: localGroups ?? _localGroups,
          countableType: countableType ?? _countableType,
          stock: stock ?? _stock,
          countable: countable ?? _countable,
          addons: addons ?? _addons,
          localAddons: localAddons ?? _localAddons,
          shopBonus: shopBonus ?? _shopBonus,
          sku: sku ?? _sku);

  int? get id => _id;

  int? get countableId => _countableId;

  num? get price => _price;

  num? get discount => _discount;

  int? get quantity => _quantity;

  int? get cartCount => _cartCount;

  bool? get bonus => _bonus;

  bool? get shopBonus => _shopBonus;

  num? get tax => _tax;

  num? get totalPrice => _totalPrice;

  ProductData? get product => _product;

  List<Extras>? get extras => _extras;

  List<Group>? get localGroups => _localGroups;

  String? get countableType => _countableType;

  String? get sku => _sku;

  Stock? get stock => _stock;

  ProductData? get countable => _countable;

  List<AddonData>? get addons => _addons;

  List<AddonData>? get localAddons => _localAddons;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['countable_id'] = _countableId;
    map['price'] = _price;
    map['bonus'] = _bonus;
    map['bonus_shop'] = _shopBonus;
    map['discount'] = _discount;
    map['cart_count'] = _cartCount;
    map['quantity'] = _quantity;
    map['tax'] = _tax;
    map['total_price'] = _totalPrice;
    if (_product != null) {
      map['product'] = _product?.toJson();
    }
    map['countable_type'] = _countableType;
    if (_stock != null) {
      map['stock'] = _stock?.toJson();
    }
    if (_countable != null) {
      map['countable'] = _countable?.toJson();
    }
    if (_addons != null) {
      map['addons'] = _addons?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class AddonData {
  AddonData(
      {int? id,
      int? stockId,
      int? addonId,
      int? quantity,
      num? totalPrice,
      ProductData? product,
      Stock? stock,
      bool? active}) {
    _id = id;
    _stockId = stockId;
    _addonId = addonId;
    _totalPrice = totalPrice;
    _quantity = quantity;
    _product = product;
    _stock = stock;
    _active = active;
  }

  AddonData.fromJson(dynamic json) {
    _id = json['id'];
    _stockId = json['stock_id'];
    _addonId = json['addon_id'];
    _quantity = json['quantity'];
    _totalPrice = json["total_price"];
    _stock = json['stock'] != null ? Stock.fromJson(json['stock']) : null;
    _product =
        json['product'] != null ? ProductData.fromJson(json['product']) : null;
  }

  int? _id;
  int? _stockId;
  int? _addonId;
  int? _quantity;
  bool? _active;
  num? _totalPrice;
  ProductData? _product;
  Stock? _stock;

  AddonData copyWith({
    int? id,
    int? stockId,
    int? addonId,
    int? quantity,
    bool? active,
    num? totalPrice,
    Stock? stock,
    ProductData? product,
  }) =>
      AddonData(
        id: id ?? _id,
        stockId: stockId ?? _stockId,
        addonId: addonId ?? _addonId,
        quantity: quantity ?? _quantity,
        totalPrice: totalPrice ?? _totalPrice,
        stock: stock ?? _stock,
        active: active ?? _active,
        product: product ?? _product,
      );

  int? get id => _id;

  int? get stockId => _stockId;

  int? get addonId => _addonId;

  int? get quantity => _quantity;

  bool? get active => _active;

  set setActive(bool active) => _active = active;

  set setCount(int count) => _quantity = count;

  num? get totalPrice => _totalPrice;

  ProductData? get product => _product;

  Stock? get stock => _stock;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['stock_id'] = _stockId;
    map['addon_id'] = _addonId;
    if (_product != null) {
      map['product'] = _product?.toJson();
    }
    return map;
  }
}
*/
