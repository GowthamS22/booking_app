class Category {
  String id;
  String name;
  bool status;
  int? displayOrder;
  DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    required this.status,
    required this.displayOrder,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json["id"],
    name: json["name"],
    status: json["status"],
    displayOrder: json["display_order"],
    createdAt: DateTime.parse(json["created_at"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "status": status,
    "display_order": displayOrder,
    "created_at": createdAt.toIso8601String(),
  };
}
