class ParcelOrderListData {
  String? name;
  String? status;
  String? deliveryDate;
  double? totalPrice;
  String? addressTo;

  ParcelOrderListData({
    this.name,
    this.status,
    this.deliveryDate,
    this.totalPrice,
    this.addressTo,
  });

  factory ParcelOrderListData.fromJson(Map<String, dynamic> json) {
    return ParcelOrderListData(
      name: json['name'],
      status: json['status'],
      deliveryDate: json['delivery_date'],
      totalPrice: (json['total_price'] as num?)?.toDouble(),
      addressTo: json['address_to'],
    );
  }
}