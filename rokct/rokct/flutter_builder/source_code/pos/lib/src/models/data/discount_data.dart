class DiscountData {
  int? id;
  int? shopId;
  String? type;
  int? price;
  DateTime? start;
  DateTime? end;
  bool? active;
  String? img;
  DateTime? createdAt;
  DateTime? updatedAt;

  DiscountData({
    this.id,
    this.shopId,
    this.type,
    this.price,
    this.start,
    this.end,
    this.active,
    this.img,
    this.createdAt,
    this.updatedAt,
  });

  DiscountData copyWith({
    int? id,
    int? shopId,
    String? type,
    int? price,
    DateTime? start,
    DateTime? end,
    bool? active,
    String? img,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      DiscountData(
        id: id ?? this.id,
        shopId: shopId ?? this.shopId,
        type: type ?? this.type,
        price: price ?? this.price,
        start: start ?? this.start,
        end: end ?? this.end,
        active: active ?? this.active,
        img: img ?? this.img,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory DiscountData.fromJson(Map<String, dynamic> json) => DiscountData(
        id: json["id"],
        shopId: json["shop_id"],
        type: json["type"],
        price: json["price"],
        start: json["start"] == null ? null : DateTime.parse(json["start"]),
        end: json["end"] == null ? null : DateTime.parse(json["end"]),
        active: json["active"],
        img: json["img"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "shop_id": shopId,
        "type": type,
        "price": price,
        "start":
            "${start!.year.toString().padLeft(4, '0')}-${start!.month.toString().padLeft(2, '0')}-${start!.day.toString().padLeft(2, '0')}",
        "end":
            "${end!.year.toString().padLeft(4, '0')}-${end!.month.toString().padLeft(2, '0')}-${end!.day.toString().padLeft(2, '0')}",
        "active": active,
        "img": img,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
      };
}

