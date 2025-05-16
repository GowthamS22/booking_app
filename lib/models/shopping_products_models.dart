import 'package:get/get.dart';

class ProductsModal {
  String? categoryId;
  DateTime? createdAt;
  String? description;
  String? imageUrl;
  String? name;
  num? price;
  num? salePrice;
  bool? status;
  num? stocks;
  num? discountPercentage;
  Rx<num>? count;

  ProductsModal({
    this.name,
    this.imageUrl,
    this.price,
    this.description,
    this.createdAt,
    this.status,
    this.categoryId,
    this.salePrice,
    this.stocks,
    this.discountPercentage,
    this.count,
  });

  factory ProductsModal.fromJson(Map<String, dynamic> jsonData) {
    final price = num.tryParse(jsonData['price'].toString()) ?? 0;
    final sale = num.tryParse(jsonData['sale_price']?.toString() ?? '0') ?? 0;
    final salePrice = sale == 0 ? price : sale;

    final subtractedValue = price - salePrice;
    final discount = price > 0 ? (subtractedValue / price) * 100 : 0;

    return ProductsModal(
      categoryId: jsonData['category_id'],
      createdAt:
          jsonData['created_at'] != null
              ? DateTime.parse(jsonData['created_at'])
              : null,
      description: jsonData['description'],
      imageUrl: jsonData['image_url'],
      name: jsonData['name'],
      price: price,
      salePrice: salePrice,
      status: jsonData['status'],
      stocks: jsonData['stock'],
      discountPercentage: discount,
      count: Rx(1),
    );
  }
}




// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart';
// class ProductsModal {
//   String? categoryId;
//   Timestamp? createdAt;
//   String? description;
//   String? imageUrl;
//   String? name;
//   num? price;
//   num? salePrice;
//   bool? status;
//   num? stocks;
//   num? discountPercentage;
//   Rx<num>? count;

//   ProductsModal({
//     this.name,this.imageUrl,this.price,this.description,this.createdAt,this.status,this.categoryId,
//   this.salePrice,this.stocks,this.discountPercentage,this.count
// });

//   factory ProductsModal.fromDocumentSnapshot(DocumentSnapshot jsonData){
//     // print('check the created date ${jsonData['categoryId']}');
//     // print('check the created date ${jsonData['createdAt']}');
//     // print('check the created date ${jsonData['description']}');
//     // print('check the created date ${jsonData['imageUrl']}');
//     // print('check the created date ${jsonData['name']}');
//     // print('check the created date ${jsonData['price']}');
//     // print('check the created date ${jsonData['salePrice']}');
//     // print('check the created date ${jsonData['status']}');
//     // print('check the created date ${jsonData['stock']}');

//     num subtractedValue = num.parse(jsonData['price'].toString()) - num.parse((jsonData['salePrice']??'0'  ).toString());
//     // print('check the created date ${subtractedValue}');
//     num? subtractedPrice = (subtractedValue/jsonData['price']);
//     num? discountPercentage = (subtractedPrice * 100);
//     // print('check the salePrice ${jsonData['salePrice']}');
//     return
//       ProductsModal(
//             categoryId: jsonData['categoryId'],
//             createdAt: jsonData['createdAt'],
//             description: jsonData['description'],
//           imageUrl: jsonData['imageUrl'],
//           name: jsonData['name'],
//           price: jsonData['price'],
//           salePrice: jsonData['salePrice']??jsonData['price']  ,
//           // salePrice: jsonData['salePrice']== null?jsonData['price'] : jsonData['salePrice'] ,
//           status: jsonData['status'],
//           stocks: jsonData['stock'],
//         discountPercentage: discountPercentage,
//         count: Rx(01),
//         );
//   }

// }