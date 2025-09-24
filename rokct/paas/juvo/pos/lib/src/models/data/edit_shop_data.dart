import 'translation.dart';
import 'location.dart';
import 'shop_delivery.dart';

class EditShopData {
  EditShopData({
    int? id,
    String? uuid,
    int? userId,
    num? tax,
    num? price,
    num? perKm,
    num? deliveryRange,
    num? percentage,
    Location? location,
    String? phone,
    String? openTime,
    String? closeTime,
    String? backgroundImg,
    String? logoImg,
    num? minAmount,
    String? status,
    String? statusNote,
    num? ratingAvg,
    String? createdAt,
    String? updatedAt,
    dynamic deletedAt,
    Translation? translation,
    Seller? seller,
    DeliveryTime? deliveryTime,
    List<ShopDelivery>? deliveries,
    List<ShopWorkingDays>? shopWorkingDays,
    List<CategoryData>? categoryData,
    List<ShopTag>? shopTag,
  }) {
    _id = id;
    _price = price;
    _perKm = perKm;
    _deliveryTime = deliveryTime;
    _uuid = uuid;
    _userId = userId;
    _tax = tax;
    _deliveryRange = deliveryRange;
    _percentage = percentage;
    _location = location;
    _phone = phone;
    _showType = showType;
    _open = open;
    _visibility = visibility;
    _openTime = openTime;
    _closeTime = closeTime;
    _backgroundImg = backgroundImg;
    _logoImg = logoImg;
    _minAmount = minAmount;
    _status = status;
    _statusNote = statusNote;
    _ratingAvg = ratingAvg;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _deletedAt = deletedAt;
    _translation = translation;
    _seller = seller;
    _deliveries = deliveries;
    _shopWorkingDays = shopWorkingDays;
    _categoryData = categoryData;
    _shopTag = shopTag;
  }

  EditShopData.fromJson(dynamic json) {
    _id = json['id'];
    _uuid = json['uuid'];
    _userId = json['user_id'];
    _tax = json['tax'];
    _price = json['price'];
    _perKm = json['price_per_km'];
    _deliveryRange = json['delivery_range'];
    _percentage = json['percentage'];
    _location =
    json['location'] != null ? Location.fromJson(json['location']) : null;
    _phone = json['phone'];
    _openTime = json['open_time'];
    _closeTime = json['close_time'];
    _backgroundImg = json['background_img'];
    _logoImg = json['logo_img'];
    _minAmount = json['min_amount'];
    _status = json['status'];
    _statusNote = json['status_note'];
    _ratingAvg = json['rating_avg'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
    _deletedAt = json['deleted_at'];
    _translation = json['translation'] != null
        ? Translation.fromJson(json['translation'])
        : null;
    _seller = json['seller'] != null ? Seller.fromJson(json['seller']) : null;
    _deliveryTime = json['delivery_time'] != null ? DeliveryTime.fromJson(json['delivery_time']) : null;
    if (json['deliveries'] != null) {
      _deliveries = [];
      json['deliveries'].forEach((v) {
        _deliveries?.add(ShopDelivery.fromJson(v));
      });
    }
    if (json['shop_working_days'] != null) {
      _shopWorkingDays = [];
      json['shop_working_days'].forEach((v) {
        _shopWorkingDays?.add(ShopWorkingDays.fromJson(v));
      });
    }
    if (json['categories'] != null) {
      _categoryData = [];
      json['categories'].forEach((v) {
        _categoryData?.add(CategoryData.fromJson(v));
      });
    }
    if (json['tags'] != null) {
      _shopTag = [];
      json['tags'].forEach((v) {
        _shopTag?.add(ShopTag.fromJson(v));
      });
    }
  }

  int? _id;
  String? _uuid;
  int? _userId;
  num? _tax;
  num? _price;
  num? _perKm;
  num? _deliveryRange;
  num? _percentage;
  Location? _location;
  String? _phone;
  bool? _showType;
  bool? _open;
  bool? _visibility;
  String? _openTime;
  String? _closeTime;
  String? _backgroundImg;
  String? _logoImg;
  num? _minAmount;
  String? _status;
  String? _statusNote;
  num? _ratingAvg;
  String? _createdAt;
  String? _updatedAt;
  dynamic _deletedAt;
  Translation? _translation;
  Seller? _seller;
  DeliveryTime? _deliveryTime;
  List<ShopDelivery>? _deliveries;
  List<ShopWorkingDays>? _shopWorkingDays;
  List<CategoryData>? _categoryData;
  List<ShopTag>? _shopTag;


  EditShopData copyWith({
    int? id,
    String? uuid,
    int? userId,
    num? tax,
    num? price,
    num? perKm,
    num? deliveryRange,
    num? percentage,
    Location? location,
    String? phone,
    bool? showType,
    bool? open,
    bool? visibility,
    String? openTime,
    String? closeTime,
    String? backgroundImg,
    String? logoImg,
    num? minAmount,
    String? status,
    String? statusNote,
    num? ratingAvg,
    String? createdAt,
    String? updatedAt,
    dynamic deletedAt,
    Translation? translation,
    Seller? seller,
    DeliveryTime? deliveryTime,
    List<ShopDelivery>? deliveries,
    List<ShopWorkingDays>? shopWorkingDays,
    List<CategoryData>? categoryData,
    List<ShopTag>? shopTag,
  }) =>
      EditShopData(
        id: id ?? _id,
        uuid: uuid ?? _uuid,
        userId: userId ?? _userId,
        tax: tax ?? _tax,
        price: price ?? _price,
        perKm: perKm ?? _perKm,
        deliveryRange: deliveryRange ?? _deliveryRange,
        percentage: percentage ?? _percentage,
        location: location ?? _location,
        phone: phone ?? _phone,
        openTime: openTime ?? _openTime,
        closeTime: closeTime ?? _closeTime,
        backgroundImg: backgroundImg ?? _backgroundImg,
        logoImg: logoImg ?? _logoImg,
        minAmount: minAmount ?? _minAmount,
        status: status ?? _status,
        statusNote: statusNote ?? _statusNote,
        ratingAvg: ratingAvg ?? _ratingAvg,
        createdAt: createdAt ?? _createdAt,
        updatedAt: updatedAt ?? _updatedAt,
        deletedAt: deletedAt ?? _deletedAt,
        translation: translation ?? _translation,
        seller: seller ?? _seller,
        deliveryTime: deliveryTime ?? _deliveryTime,
        deliveries: deliveries ?? _deliveries,
        shopWorkingDays: shopWorkingDays ?? _shopWorkingDays,
        categoryData: categoryData ?? _categoryData,
        shopTag: shopTag ?? _shopTag,
      );

  int? get id => _id;

  String? get uuid => _uuid;

  int? get userId => _userId;

  num? get tax => _tax;

  num? get price => _price;

  num? get perKm => _perKm;

  num? get deliveryRange => _deliveryRange;

  num? get percentage => _percentage;

  Location? get location => _location;

  String? get phone => _phone;

  bool? get showType => _showType;

  bool? get open => _open;

  bool? get visibility => _visibility;

  String? get openTime => _openTime;

  String? get closeTime => _closeTime;

  String? get backgroundImg => _backgroundImg;

  String? get logoImg => _logoImg;

  num? get minAmount => _minAmount;

  String? get status => _status;

  String? get statusNote => _statusNote;

  num? get ratingAvg => _ratingAvg;

  String? get createdAt => _createdAt;

  String? get updatedAt => _updatedAt;

  dynamic get deletedAt => _deletedAt;

  Translation? get translation => _translation;

  Seller? get seller => _seller;

  DeliveryTime? get deliveryTime => _deliveryTime;

  List<ShopDelivery>? get deliveries => _deliveries;

  List<ShopWorkingDays>? get shopWorkingDays => _shopWorkingDays;

  List<CategoryData>? get categoryData => _categoryData;

  List<ShopTag>? get shopTag => _shopTag;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['uuid'] = _uuid;
    map['user_id'] = _userId;
    map['tax'] = _tax;
    map['delivery_range'] = _deliveryRange;
    map['percentage'] = _percentage;
    if (_location != null) {
      map['location'] = _location?.toJson();
    }
    map['phone'] = _phone;
    map['show_type'] = _showType;
    map['open'] = _open;
    map['visibility'] = _visibility;
    map['open_time'] = _openTime;
    map['close_time'] = _closeTime;
    map['background_img'] = _backgroundImg;
    map['logo_img'] = _logoImg;
    map['min_amount'] = _minAmount;
    map['status'] = _status;
    map['status_note'] = _statusNote;
    map['rating_avg'] = _ratingAvg;
    map['created_at'] = _createdAt;
    map['updated_at'] = _updatedAt;
    map['deleted_at'] = _deletedAt;
    if (_translation != null) {
      map['translation'] = _translation?.toJson();
    }
    if (_seller != null) {
      map['seller'] = _seller?.toJson();
    }
    if (_deliveries != null) {
      map['deliveries'] = _deliveries?.map((v) => v.toJson()).toList();
    }
    if (_shopWorkingDays != null) {
      map['shop_working_days'] = _shopWorkingDays?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class Seller {
  Seller({
    int? id,
    String? firstname,
    String? lastname,
    String? role,
  }) {
    _id = id;
    _firstname = firstname;
    _lastname = lastname;
    _role = role;
  }

  Seller.fromJson(dynamic json) {
    _id = json['id'];
    _firstname = json['firstname'];
    _lastname = json['lastname'];
    _role = json['role'];
  }

  int? _id;
  String? _firstname;
  String? _lastname;
  String? _role;

  Seller copyWith({
    int? id,
    String? firstname,
    String? lastname,
    String? role,
  }) =>
      Seller(
        id: id ?? _id,
        firstname: firstname ?? _firstname,
        lastname: lastname ?? _lastname,
        role: role ?? _role,
      );

  int? get id => _id;

  String? get firstname => _firstname;

  String? get lastname => _lastname;

  String? get role => _role;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['firstname'] = _firstname;
    map['lastname'] = _lastname;
    map['role'] = _role;
    return map;
  }
}

class DeliveryTime {
  DeliveryTime({
    String? from,
    String? to,
    String? type,
  }) {
    _from = from;
    _to = to;
    _type = type;
  }

  DeliveryTime.fromJson(dynamic json) {
    _from = json['from'];
    _to = json['to'];
    _type = json['type'];
  }

  String? _from;
  String? _to;
  String? _type;

  DeliveryTime copyWith({
    String? from,
    String? to,
    String? type,
  }) =>
      DeliveryTime(
        from: from ?? _from,
        to: to ?? _to,
        type: type ?? _type,
      );

  String? get from => _from;

  String? get to => _to;

  String? get type => _type;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['firstname'] = _from;
    map['lastname'] = _to;
    map['role'] = _type;
    return map;
  }
}

class ShopWorkingDays {
  ShopWorkingDays({
    String? day,
    String? from,
    String? to,
    bool? disabled,
  }) {
    _day = day;
    _from = from;
    _to = to;
    _disabled = disabled;
  }

  ShopWorkingDays.fromJson(dynamic json) {
    _day = json['day'];
    _from = json['from'];
    _to = json['to'];
    _disabled = json['disabled'];
  }

  String? _day;
  String? _from;
  String? _to;
  bool? _disabled;

  ShopWorkingDays copyWith({
    String? day,
    String? from,
    String? to,
    bool? disabled,
  }) =>
      ShopWorkingDays(
        day: day ?? _day,
        from: from ?? _from,
        to: to ?? _to,
        disabled: disabled ?? _disabled,
      );


  String? get day => _day;

  String? get from => _from;

  String? get to => _to;

  bool? get disabled => _disabled;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['day'] = _day;
    map['from'] = _from;
    map['to'] = _to;
    map['disabled'] = _disabled;
    return map;
  }
}

class CategoryData {
  CategoryData({
    int? id,
    String? uuid,
    String? keywords,
    int? parentId,
    String? type,
    String? img,
    bool? active,
    Translation? translation,
  }) {
    _id = id;
    _uuid = uuid;
    _keywords = keywords;
    _parentId = parentId;
    _type = type;
    _img = img;
    _active = active;
    _translation = translation;
  }

  CategoryData.fromJson(dynamic json) {
    _id = json['id'];
    _uuid = json['uuid'];
    _keywords = json['keywords'];
    _parentId = json['parent_id'];
    _type = json['type'];
    _img = json['img'];
    _active = json['active'];
    _translation = json['translation'] != null
        ? Translation.fromJson(json['translation'])
        : null;
  }

  int? _id;
  String? _uuid;
  String? _keywords;
  int? _parentId;
  String? _type;
  String? _img;
  bool? _active;
  Translation? _translation;

  CategoryData copyWith({
    int? id,
    String? uuid,
    String? keywords,
    int? parentId,
    String? type,
    String? img,
    bool? active,
    Translation? translation,
  }) =>
      CategoryData(
        id: id ?? _id,
        uuid: uuid ?? _uuid,
        keywords: keywords ?? _keywords,
        parentId: parentId ?? _parentId,
        type: type ?? _type,
        img: img ?? _img,
        active: active ?? _active,
        translation: translation ?? _translation,
      );

  int? get id => _id;

  String? get uuid => _uuid;

  String? get keywords => _keywords;

  int? get parentId => _parentId;

  String? get type => _type;

  String? get img => _img;

  bool? get active => _active;

  Translation? get translation => _translation;


  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['uuid'] = _uuid;
    map['keywords'] = _keywords;
    map['parent_id'] = _parentId;
    map['type'] = _type;
    map['img'] = _img;
    map['active'] = _active;
    if (_translation != null) {
      map['translation'] = _translation?.toJson();
    }
    return map;
  }
}

class ShopTag {
  ShopTag({
    int? id,
    String? img,
    Translation? translation,
    List<String>? locales,
  }) {
    _id = id;
    _img = img;
    _translation = translation;
    _locales = locales;
  }

  ShopTag.fromJson(dynamic json) {
    _id = json['id'];
    _img = json['img'];
    _translation = json['translation'] != null
        ? Translation.fromJson(json['translation'])
        : null;
    _locales = json['locales'] != null ? json['locales'].cast<String>() : [];
  }

  int? _id;
  String? _img;
  Translation? _translation;
  List<String>? _locales;

  ShopTag copyWith({
    int? id,
    String? img,
    Translation? translation,
    List<String>? locales,
  }) =>
      ShopTag(
        id: id ?? _id,
        img: img ?? _img,
        translation: translation ?? _translation,
        locales: locales ?? _locales,
      );

  int? get id => _id;

  String? get img => _img;

  Translation? get translation => _translation;

  List<String>? get locales => _locales;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['img'] = _img;
    if (_translation != null) {
      map['translation'] = _translation?.toJson();
    }
    map['locales'] = _locales;
    return map;
  }
}


