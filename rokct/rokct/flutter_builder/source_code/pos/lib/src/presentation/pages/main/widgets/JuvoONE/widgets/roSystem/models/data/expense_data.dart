class Expense {
  final int? id;
  final int shopId;
  final String? itemCode;
  final double qty;
  final double price;
  final String description;
  final String? note;
  final int? meterId;
  final double? kwh;
  final double? litres;
  final String status;
  final int? typeId;
  final String? supplier;
  final String? invoiceNumber;
  final DateTime? createdAt;

  Expense({
    this.id,
    required this.shopId,
    this.itemCode,
    this.qty = 1.0,
    required this.price,
    required this.description,
    this.note,
    this.meterId,
    this.kwh,
    this.litres,
    this.status = 'progress',
    this.typeId,
    this.supplier,
    this.invoiceNumber,
    this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      shopId: json['shop_id'],
      itemCode: json['item_code'],
      qty: (json['qty'] as num?)?.toDouble() ?? 1.0,
      price: (json['price'] as num).toDouble(),
      description: json['description'],
      note: json['note'],
      meterId: json['meter_id'],
      kwh: (json['kwh'] as num?)?.toDouble(),
      litres: (json['litres'] as num?)?.toDouble(),
      status: json['status'] ?? 'progress',
      typeId: json['type_id'],
      supplier: json['supplier'],
      invoiceNumber: json['invoice_number'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shop_id': shopId,
      'item_code': itemCode,
      'qty': qty,
      'price': price,
      'description': description,
      'note': note,
      'meter_id': meterId,
      'kwh': kwh,
      'litres': litres,
      'status': status,
      'type_id': typeId,
      'supplier': supplier,
      'invoice_number': invoiceNumber,
    };
  }
}
class ExpenseType {
  final int id;
  final String name;

  ExpenseType({
    required this.id,
    required this.name,
  });

  factory ExpenseType.fromJson(Map<String, dynamic> json) {
    return ExpenseType(
      id: json['id'],
      name: json['name'],
    );
  }
}

