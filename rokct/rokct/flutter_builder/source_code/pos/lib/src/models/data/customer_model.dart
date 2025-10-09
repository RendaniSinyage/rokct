import 'address_data.dart';

class CustomerModel {
  int? id;
  String? firstname;
  String? lastname;
  String? email;
  String? phone;
  String? password;
  String? role;
  String? imageUrl;
  List<AddressData>? addresses;

  CustomerModel({
    this.id,
    this.firstname,
    this.lastname,
    this.email,
    this.phone,
    this.role,
    this.password,
    this.imageUrl,
    this.addresses,
  });

  CustomerModel copyWith({
    int? id,
    String? firstname,
    String? lastname,
    String? email,
    String? phone,
    String? role,
    String? password,
    String? imageUrl,
    List<AddressData>? addresses,
  }) =>
      CustomerModel(
        id: id ?? this.id,
        firstname: firstname ?? this.firstname,
        lastname: lastname ?? this.lastname,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        role: role ?? this.role,
        password: password ?? this.password,
        imageUrl: imageUrl ?? this.imageUrl,
        addresses: addresses ?? this.addresses,
      );

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
        id: json["id"],
        firstname: json["firstname"],
        lastname: json["lastname"],
        email: json["email"],
        phone: json["phone"],
        role: json["role"],
        password: json["password"],
        imageUrl: json["img"],
        addresses: json["addresses"] == null
            ? []
            : List<AddressData>.from(
                json["addresses"].map((x) => AddressData.fromJson(x))),
      );

  Map<String, dynamic> toJson() {
    Map<String, dynamic> jsonMap = {
      "firstname": firstname,
      "email": email,
      "phone": phone,
      "role": role,
    };

    if (password != null) {
      jsonMap["password"] = password;
    }
    if (imageUrl != null) {
      jsonMap["imageUrl"] = imageUrl;
    }
    if (lastname != null) {
      jsonMap["lastname"] = lastname;
    }

    return jsonMap;
  }
}