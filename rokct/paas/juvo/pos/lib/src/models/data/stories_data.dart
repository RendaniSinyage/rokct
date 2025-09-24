
import 'product_data.dart';
import 'shop_data.dart';

class StoriesData {
  int? id;
  List<String>? fileUrls;
  ProductData? product;
  ShopData? shop;

  StoriesData({
    this.id,
    this.fileUrls,
    this.product,
    this.shop,
  });

  StoriesData copyWith({
    int? id,
    List<String>? fileUrls,
    ProductData? product,
    ShopData? shop,
  }) =>
      StoriesData(
        id: id ?? this.id,
        fileUrls: fileUrls ?? this.fileUrls,
        product: product ?? this.product,
        shop: shop ?? this.shop,
      );

  factory StoriesData.fromJson(Map<String, dynamic> json) => StoriesData(
    id: json["id"],
    fileUrls: json["file_urls"] == null ? [] : List<String>.from(json["file_urls"]!.map((x) => x)),
    product: json["product"] == null ? null : ProductData.fromJson(json["product"]),
    shop: json["shop"] == null ? null : ShopData.fromJson(json["shop"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "file_urls": fileUrls == null ? [] : List<dynamic>.from(fileUrls!.map((x) => x)),
    "product": product?.toJson(),
    "shop": shop?.toJson(),
  };
}


