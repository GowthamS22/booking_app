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

  CartItem({required this.product, this.quantity = 1});

  // Serialization methods
  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Products.fromJson(json['product']),
      quantity: json['quantity'],
    );
  }
}