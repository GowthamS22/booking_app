class CategoryModal {
  String? id;
  DateTime? createdAt;
  String? name;
  int? active;
  int? displayOrder;

  CategoryModal({
    this.id,
    this.createdAt,
    this.name,
    this.active,
    this.displayOrder,
  });

  factory CategoryModal.fromJson(Map<String, dynamic> json) {
    return CategoryModal(
      id: json['id'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      name: json['name'] as String?,
      active: json['status'] == null ? null : (json['status'] ? 1 : 0),
      displayOrder: json['display_order'] as int?,
    );
  }
}

// class CategoryModal {
//   String? id;
//   Timestamp? createdAt;
//   String? name;
//   num? active;
//   num? displayOrder;

//   CategoryModal({
//     this.name,this.createdAt,
//     this.id,this.displayOrder,this.active,
//   });

//   factory CategoryModal.fromDocumentSnapshot(DocumentSnapshot data){
//     return
//       CategoryModal(
//         createdAt: data['createdAt'],
//         name: data['name'],
//         displayOrder: data['displayOrder'],
//         active: data['active'],
//         id: data.id,
//       );
//   }

// }
