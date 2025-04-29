import 'package:cloud_firestore/cloud_firestore.dart';
class CategoryModal {
  String? id;
  Timestamp? createdAt;
  String? name;
  num? active;
  num? displayOrder;

  CategoryModal({
    this.name,this.createdAt,
    this.id,this.displayOrder,this.active,
  });

  factory CategoryModal.fromDocumentSnapshot(DocumentSnapshot data){
    return
      CategoryModal(
        createdAt: data['createdAt'],
        name: data['name'],
        displayOrder: data['displayOrder'],
        active: data['active'],
        id: data.id,
      );
  }

}