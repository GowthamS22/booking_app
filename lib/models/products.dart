class Products {
  String id;
  String categoryId;
  String name;
  String description;
  String price;
  dynamic imageUrl;
  String displayOrder;
  bool status;
  DateTime createdAt;
  String stock;

  Products({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.displayOrder,
    required this.status,
    required this.createdAt,
    required this.stock,
  });

  factory Products.fromJson(Map<String, dynamic> json) => Products(
    id: json["id"],
    categoryId: json["category_id"],
    name: json["name"],
    description: json["description"],
    price: json["price"],
    imageUrl: json["image_url"],
    displayOrder: json["display_order"],
    status: json["status"],
    createdAt: DateTime.parse(json["created_at"]),
    stock: json["stock"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "category_id": categoryId,
    "name": name,
    "description": description,
    "price": price,
    "image_url": imageUrl,
    "display_order": displayOrder,
    "status": status,
    "created_at": createdAt.toIso8601String(),
    "stock": stock,
  };
}

class CartItem {
  final Products product;
  int quantity;
  double appliedPrice;

  CartItem({required this.product, this.quantity = 1}) : appliedPrice = _parsePrice(product.price) * quantity;

  // Helper to convert String price (e.g., "$10.99") to double
  static double _parsePrice(String priceStr) {
    return double.tryParse(priceStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
  }

  // Update appliedPrice when quantity changes
  void updateAppliedPrice() {
    appliedPrice = _parsePrice(product.price) * quantity;
  }

  // Serialization methods
  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'quantity': quantity,
    'appliedPrice': appliedPrice,  // Now stored in JSON
  };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Products.fromJson(json['product']),
      quantity: json['quantity'],
    )..appliedPrice = json['appliedPrice'];
  }
}