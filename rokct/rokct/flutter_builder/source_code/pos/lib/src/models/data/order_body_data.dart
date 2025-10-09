import 'package:admin_desktop/src/core/utils/local_storage.dart';
import 'package:admin_desktop/src/models/data/bag_data.dart';
import 'package:admin_desktop/src/models/data/location_data.dart';

import '../../core/constants/constants.dart';

class OrderBodyData {
  final String? note;
  final int? userId;
  final num? deliveryFee;
  final int? currencyId;
  final int? tableId;
  final num? rate;
  final String deliveryType;
  final String? phone;
  final String? coupon;
  final LocationData? location;
  final AddressModel address;
  final String deliveryDate;
  final String deliveryTime;
  final BagData bagData;

  OrderBodyData({
    this.currencyId,
    this.rate,
    this.userId,
    this.deliveryFee,
    this.tableId,
    required this.deliveryType,
    required this.phone,
    this.coupon,
    this.location,
    required this.address,
    required this.deliveryDate,
    required this.deliveryTime,
    this.note,
    required this.bagData,
  });

  Map toJson() {
    Map newMap = {};
    List<Map<String, dynamic>> products = [];
    for (BagProductData stock in bagData.bagProducts ?? []) {
      List<Map<String, dynamic>> addons = [];
      for (BagProductData addon in stock.carts ?? []) {
        addons.add({
          'stock_id': addon.stockId,
          'quantity': addon.quantity,
        });
      }
      products.add({
        'stock_id': stock.stockId,
        'quantity': stock.quantity,
        if (addons.isNotEmpty) 'addons': addons,
      });
    }
    newMap["currency_id"] = currencyId;
    newMap["rate"] = rate;
    if (phone?.isNotEmpty ?? false) newMap['phone'] = phone;
    newMap["shop_id"] = LocalStorage.getUser()?.role == TrKeys.waiter
        ? LocalStorage.getUser()?.invite?.shopId ?? 0
        : LocalStorage.getUser()?.shop?.id ?? 0;
    if (userId != null && userId != 0) newMap["user_id"] = userId;
    if (deliveryFee != 0) newMap["delivery_fee"] = deliveryFee;
    newMap["delivery_type"] = deliveryType.toLowerCase();
    if (coupon != null && (coupon?.isNotEmpty ?? false)) {
      newMap["coupon"] = coupon;
    }
    if (note != null && (note?.isNotEmpty ?? false)) newMap["note"] = note;
    if (location != null) newMap["location"] = location?.toJson();
    newMap["address"] = address.toJson();
    if (tableId != null) newMap["table_id"] = tableId;
    newMap["delivery_date"] = deliveryDate;
    newMap["delivery_time"] = deliveryTime;
    newMap['products'] = products;
    return newMap;
  }
}

class AddressModel {
  final String? address;
  final String? office;
  final String? house;
  final String? floor;

  AddressModel({
    this.address,
    this.office,
    this.house,
    this.floor,
  });

  Map toJson() {
    return {
      "address": address,
      "office": office,
      "house": house,
      "floor": floor
    };
  }

  factory AddressModel.fromJson(Map? data) {
    return AddressModel(
      address: data?["address"],
      office: data?["office"],
      house: data?["house"],
      floor: data?["floor"],
    );
  }
}

class ProductOrder {
  final int stockId;
  final num price;
  final int quantity;
  final num tax;
  final num discount;
  final num totalPrice;

  ProductOrder({
    required this.stockId,
    required this.price,
    required this.quantity,
    required this.tax,
    required this.discount,
    required this.totalPrice,
  });

  @override
  String toString() {
    return "{\"stock_id\":$stockId, \"price\":$price, \"qty\":$quantity, \"tax\":$tax, \"discount\":$discount, \"total_price\":$totalPrice}";
  }
}

