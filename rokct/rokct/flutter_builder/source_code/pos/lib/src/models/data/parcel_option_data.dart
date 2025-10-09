class ParcelOptionData {
  String? name;
  String? title;
  String? description;
  double? price;

  ParcelOptionData({
    this.name,
    this.title,
    this.description,
    this.price,
  });

  factory ParcelOptionData.fromJson(Map<String, dynamic> json) {
    return ParcelOptionData(
      name: json['name'],
      title: json['title'],
      description: json['description'],
      price: (json['price'] as num?)?.toDouble(),
    );
  }
}