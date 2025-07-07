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
    id: json["id"]?.toString() ?? '',
    categoryId: json["category_id"]?.toString() ?? '',
    name: json["name"]?.toString() ?? 'Unknown Product',
    description: json["description"]?.toString() ?? '',
    price: json["price"]?.toString() ?? '0',
    imageUrl: json["image_url"],
    displayOrder: json["display_order"]?.toString() ?? '0',
    status: json["status"] ?? true,
    createdAt: json["created_at"] != null 
        ? DateTime.parse(json["created_at"]) 
        : DateTime.now(),
    stock: json["stock"]?.toString() ?? '0',
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
    final product = Products.fromJson(json['product']);
    final quantity = json['quantity'] ?? 1;
    final item = CartItem(
      product: product,
      quantity: quantity,
    );
    // If appliedPrice is stored in JSON, use it, otherwise calculate it
    if (json.containsKey('appliedPrice') && json['appliedPrice'] != null) {
      item.appliedPrice = (json['appliedPrice'] as num).toDouble();
    }
    return item;
  }
}