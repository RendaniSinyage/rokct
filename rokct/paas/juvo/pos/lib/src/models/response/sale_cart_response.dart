import 'sale_history_response.dart';

class SaleCartResponse {
  double? deliveryFee;
  double? cash;
  double? other;
  List<SaleHistoryModel>? sales;

  SaleCartResponse({
    this.deliveryFee,
    this.cash,
    this.other,
    this.sales,
  });

  double getNonCashTotal(List<SaleHistoryModel> saleHistory) {
    double total = 0;

    for (var sale in saleHistory) {
      if (sale.transactions?.isNotEmpty == true) {
        bool isNonCash = sale.transactions!.any((transaction) =>
        transaction.paymentSystem?.tag?.toLowerCase() != 'cash');

        if (isNonCash && sale.totalPrice != null) {
          total += sale.totalPrice!;
        }
      }
    }
    return total;
  }

  SaleCartResponse copyWith({
    double? deliveryFee,
    double? cash,
    double? other,
    List<SaleHistoryModel>? sales,
  }) =>
      SaleCartResponse(
        deliveryFee: deliveryFee ?? this.deliveryFee,
        cash: cash ?? this.cash,
        other: other ?? this.other,
        sales: sales ?? this.sales,
      );

  factory SaleCartResponse.fromJson(Map<String, dynamic> json) => SaleCartResponse(
    deliveryFee: json["delivery_fee"]?.toDouble(),
    cash: json["cash"]?.toDouble(),
    other: json["other"]?.toDouble(),
    sales: json["sales"] == null ? [] : List<SaleHistoryModel>.from(
        json["sales"].map((x) => SaleHistoryModel.fromJson(x))
    ),
  );

  Map<String, dynamic> toJson() => {
    "delivery_fee": deliveryFee,
    "cash": cash,
    "other": other,
    "sales": sales == null ? [] : List<dynamic>.from(sales!.map((x) => x.toJson())),
  };
}
