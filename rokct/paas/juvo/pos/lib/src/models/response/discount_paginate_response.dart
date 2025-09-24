import 'dart:convert';
import '../data/discount_data.dart';
import '../data/meta.dart';

DiscountPaginateResponse discountPaginateResponseFromJson(String str) =>
    DiscountPaginateResponse.fromJson(json.decode(str));

String discountPaginateResponseToJson(DiscountPaginateResponse data) =>
    json.encode(data.toJson());

class DiscountPaginateResponse {
  List<DiscountData>? data;
  Meta? meta;

  DiscountPaginateResponse({
    this.data,
    this.meta
  });

  DiscountPaginateResponse copyWith({
    List<DiscountData>? data,
    Meta? meta,
  }) =>
      DiscountPaginateResponse(
        data: data ?? this.data,
        meta: meta ?? this.meta
      );

  factory DiscountPaginateResponse.fromJson(Map<String, dynamic> json) =>
      DiscountPaginateResponse(
        data: json["data"] == null
            ? []
            : List<DiscountData>.from(
                json["data"]!.map((x) => DiscountData.fromJson(x))),
          meta : json['meta'] != null ? Meta.fromJson(json['meta']) : null
      );

  Map<String, dynamic> toJson() => {
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

