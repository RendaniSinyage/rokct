
import '../data/single_discount_detail_data.dart';

class DiscountDetail {
  DateTime? timestamp;
  bool? status;
  String? message;
  SingleDiscountDetailData? data;

  DiscountDetail({
    this.timestamp,
    this.status,
    this.message,
    this.data,
  });

  DiscountDetail copyWith({
    DateTime? timestamp,
    bool? status,
    String? message,
    SingleDiscountDetailData? data,
  }) =>
      DiscountDetail(
        timestamp: timestamp ?? this.timestamp,
        status: status ?? this.status,
        message: message ?? this.message,
        data: data ?? this.data,
      );

  factory DiscountDetail.fromJson(Map<String, dynamic> json) => DiscountDetail(
        timestamp: json["timestamp"] == null
            ? null
            : DateTime.parse(json["timestamp"]),
        status: json["status"],
        message: json["message"],
        data: json["data"] == null
            ? null
            : SingleDiscountDetailData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "timestamp": timestamp?.toIso8601String(),
        "status": status,
        "message": message,
        "data": data?.toJson(),
      };
}

