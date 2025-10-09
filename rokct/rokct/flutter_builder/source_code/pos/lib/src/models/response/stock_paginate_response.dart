// To parse this JSON data, do
//
//     final stockPaginateResponse = stockPaginateResponseFromJson(jsonString);

import 'dart:convert';

import '../models.dart';

StockPaginateResponse stockPaginateResponseFromJson(String str) =>
    StockPaginateResponse.fromJson(json.decode(str));

String stockPaginateResponseToJson(StockPaginateResponse data) =>
    json.encode(data.toJson());

class StockPaginateResponse {
  List<Stocks>? data;

  StockPaginateResponse({
    this.data,
  });

  StockPaginateResponse copyWith({
    List<Stocks>? data,
  }) =>
      StockPaginateResponse(
        data: data ?? this.data,
      );

  factory StockPaginateResponse.fromJson(Map<String, dynamic> json) =>
      StockPaginateResponse(
        data: json["data"] == null
            ? []
            : List<Stocks>.from(json["data"]!.map((x) => Stocks.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

