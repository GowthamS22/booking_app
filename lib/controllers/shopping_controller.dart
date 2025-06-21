import 'package:booking_app/models/shopping_category_models.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shopping_products_models.dart';
import 'package:uuid/uuid.dart';

class ShoppingController extends GetxController {

}
//     with GetSingleTickerProviderStateMixin {
//   final supabase = Supabase.instance.client;
//   static ShoppingController instance = Get.find();
//   TabController? tabController;
//   var showNoItemsFound = false.obs;
//
//   RxString uuid = Uuid().v1().obs;
//   //RxList<ProductsModal> productsList = RxList([]);
//   RxList<ProductsModal> productsList = <ProductsModal>[].obs;
//   // RxList<CategoryModal> categoryList = RxList([]);
//   RxList<CategoryModal> categoryList = <CategoryModal>[].obs;
//   RxList<ProductsModal> productsCartModal = RxList([]);
//   List<String> list = <String>['H to L', 'L to H', 'A to Z', 'Z to A'];
//   // List<ProductsModal> get products => productsList;
//   List<CategoryModal> get category => categoryList;
//   String? get categoryNameFirst => categoryList.first.id;
//   Rx<double>? get totalPrice => productsCartModal.fold(
//     Rx(0.0),
//     (previousValue, element) =>
//         previousValue! + element.salePrice!.toDouble() * element.count!.value,
//   );
//   Stream<List<ProductsModal>> getProducts(String cat) {
//     return supabase
//         .schema('s22_prod_schema')
//         .from('products')
//         .stream(primaryKey: ['id'])
//         .eq('category_id', cat)
//         .map((data) {
//           print("📦 Received ${data.length} categories from Supabase");
//           final val = data.map((item) => ProductsModal.fromJson(item)).toList();
//           print('val :  $val');
//           if (val.isEmpty) {
//             showNoItemsFound.value = true;
//             print('No products found for category $cat');
//             update();
//           }
//
//           return val;
//         });
//   }
//
//   // Stream<List<ProductsModal>> getProducts(String cat) {
//   //   productsList.clear();
//
//   //   return supabase
//   //       .schema('s22_prod_schema')
//   //       .from('products')
//   //       .stream(primaryKey: ['id'])
//   //       .eq('category_id', cat)
//   //       .map((data) {
//   //         List<ProductsModal> val =
//   //             data.map((item) => ProductsModal.fromJson(item)).toList();
//
//   //         print('checking the added cat ${val.length}');
//   //         if (val.isEmpty) {
//   //           showNoItemsFound.value = true;
//   //           print(
//   //             'checking the added showNoItemsFound.value ${showNoItemsFound.value}',
//   //           );
//   //           update();
//   //         }
//
//   //         return val;
//   //       });
//   // }
//
//   Stream<List<CategoryModal>> getCategory() {
//     return supabase
//         .schema('s22_prod_schema')
//         .from('categories')
//         .stream(primaryKey: ['id'])
//         .eq('status', true)
//         .order('display_order')
//         .map((data) {
//           print("📦 Received ${data.length} categories from Supabase");
//           final val = data.map((item) => CategoryModal.fromJson(item)).toList();
//           print('value: $val');
//           return val;
//         });
//   }
//
//   //  Stream<List<CategoryModal>> getCategory(){
//   //     return
//   //       FirebaseFirestore.instance
//   //           .collection('shop_1')
//   //           .doc('categories')
//   //           .collection('category').orderBy('displayOrder').snapshots().map((QuerySnapshot query) {
//   //             List<CategoryModal> val = [];
//   //             query.docs.forEach((element) {
//   //               val.add(CategoryModal.fromDocumentSnapshot(element));
//   //             });
//   //             return val;
//   //       });
//   //   }
//   @override
//   void onInit() {
//     // TODO: implement onInit
//     categoryList.bindStream(getCategory());
//     // Only run when categoryList gets data (and only once)
//     ever(categoryList, (List<CategoryModal> list) {
//       if (list.isNotEmpty && tabController == null) {
//         tabController = TabController(length: list.length, vsync: this);
//
//         tabController!.addListener(() {
//           final index = tabController!.index;
//           if (index < categoryList.length) {
//             final catId = categoryList[index].id!;
//             productsList.bindStream(getProducts(catId));
//           }
//         });
//
//         // Load initial products
//         productsList.bindStream(getProducts(list.first.id!));
//         update(); // Trigger rebuild for UI
//       }
//     });
//
//     super.onInit();
//   }
//
//   @override
//   void onClose() {
//     // TODO: implement onClose
//     tabController!.dispose();
//     super.onClose();
//   }
// }
 // categoryName = categoryNameFirst;
    // Future.delayed(Duration(milliseconds: 500), () {
    //   tabController = TabController(
    //     vsync: this,
    //     length: categoryList.length,
    //   ); // Number of tabs
    //   tabController!.addListener(() {
    //     productsList.bindStream(
    //       getProducts(categoryList[tabController!.index].id!),
    //     );

    //     // if(productsList.length == 0) {
    //     //   print('checking the length ${productsList.length}');
    //     //   showNoItemsFound.value = true;
    //     //   print('checking the showNoItemsFound ${showNoItemsFound.value}');
    //     //   update();
    //     // }

    //     // Future.delayed(Duration(milliseconds: 1500),(){
    //     //
    //     //   if(productsList.length <= 0) {
    //     //     print('checking the length ${productsList.length}');
    //     //     showNoItemsFound.value = true;
    //     //     print('checking the showNoItemsFound ${showNoItemsFound.value}');
    //     //     update();
    //     //   }
    //     //   else
    //     //     print('checking the length else ${productsList.length}');
    //     // });
    //   });
    // });
    // Future.delayed(Duration(milliseconds: 1000), () {
    //   productsList.bindStream(getProducts(categoryNameFirst!));
    // });