import '../models.dart';

class SingleDiscountDetailData {
  int? id;
  int? shopId;
  String? type;
  DateTime? start;
  DateTime? end;
  bool? active;
  DateTime? createdAt;
  DateTime? updatedAt;
  List<Stocks>? stocks;
  List<Galleries>? galleries;

  SingleDiscountDetailData({
    this.id,
    this.shopId,
    this.type,
    this.start,
    this.end,
    this.active,
    this.createdAt,
    this.updatedAt,
    this.stocks,
    this.galleries,
  });

  SingleDiscountDetailData copyWith({
    int? id,
    int? shopId,
    String? type,
    DateTime? start,
    DateTime? end,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Stocks>? stocks,
    List<Galleries>? galleries,
  }) =>
      SingleDiscountDetailData(
        id: id ?? this.id,
        shopId: shopId ?? this.shopId,
        type: type ?? this.type,
        start: start ?? this.start,
        end: end ?? this.end,
        active: active ?? this.active,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        stocks: stocks ?? this.stocks,
        galleries: galleries ?? this.galleries,
      );

  factory SingleDiscountDetailData.fromJson(Map<String, dynamic> json) =>
      SingleDiscountDetailData(
        id: json["id"],
        shopId: json["shop_id"],
        type: json["type"],
        start: json["start"] == null ? null : DateTime.parse(json["start"]),
        end: json["end"] == null ? null : DateTime.parse(json["end"]),
        active: json["active"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
        stocks: json["stocks"] == null
            ? []
            : List<Stocks>.from(json["stocks"]!.map((x) => Stocks.fromJson(x))),
        galleries: json["galleries"] == null
            ? []
            : List<Galleries>.from(
                json["galleries"]!.map((x) => Galleries.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "shop_id": shopId,
        "type": type,
        "start":
            "${start!.year.toString().padLeft(4, '0')}-${start!.month.toString().padLeft(2, '0')}-${start!.day.toString().padLeft(2, '0')}",
        "end":
            "${end!.year.toString().padLeft(4, '0')}-${end!.month.toString().padLeft(2, '0')}-${end!.day.toString().padLeft(2, '0')}",
        "active": active,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "stocks": stocks == null
            ? []
            : List<dynamic>.from(stocks!.map((x) => x.toJson())),
        "galleries": galleries == null
            ? []
            : List<dynamic>.from(galleries!.map((x) => x.toJson())),
      };
}

