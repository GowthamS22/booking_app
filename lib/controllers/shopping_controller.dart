import 'package:badminton_app/models/shopping_category_models.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shopping_products_models.dart';
import 'package:uuid/uuid.dart';
class ShoppingController extends GetxController  with GetSingleTickerProviderStateMixin{
  static ShoppingController instance = Get.find();
  late TabController tabController;
  var showNoItemsFound = false.obs;

  RxString uuid = Uuid().v1().obs;
  RxList<ProductsModal> productsList = RxList([]);
  RxList<CategoryModal> categoryList = RxList([]);
  RxList<ProductsModal> productsCartModal = RxList([]);
  List<String> list = <String>['H to L','L to H','A to Z','Z to A'];
  // List<ProductsModal> get products => productsList;
  List<CategoryModal> get category => categoryList;
  String? get  categoryNameFirst => categoryList.first.id;
  Rx<double>? get  totalPrice => productsCartModal.fold(Rx(0.0), (previousValue, element) => previousValue! + element.salePrice!.toDouble() * element.count!.value);

 Stream<List<ProductsModal>> getProducts(String cat){
   productsList.clear();

    return
      FirebaseFirestore.instance
          .collection('shop_1')
          .doc('products')
          .collection('product').where('categoryId',isEqualTo: cat).snapshots().map((QuerySnapshot query) {
            List<ProductsModal> val = [];
            // print('checking the category name inside the query $categoryName');
            query.docs.forEach((element) {
              val.add(ProductsModal.fromDocumentSnapshot(element));
            });

            print('checking the added cat ${val.length}');
            if(val.length <=0){
              showNoItemsFound.value = true;
              print('checking the added showNoItemsFound.value ${showNoItemsFound.value}');
              update();
            }

            return val;
      });
  }
 Stream<List<CategoryModal>> getCategory(){
    return
      FirebaseFirestore.instance
          .collection('shop_1')
          .doc('categories')
          .collection('category').orderBy('displayOrder').snapshots().map((QuerySnapshot query) {
            List<CategoryModal> val = [];
            query.docs.forEach((element) {
              val.add(CategoryModal.fromDocumentSnapshot(element));
            });
            return val;
      });
  }
  @override
  void onInit()  {
    // TODO: implement onInit
    categoryList.bindStream(getCategory());
    // categoryName = categoryNameFirst;
   Future.delayed(Duration(milliseconds: 500),(){
     tabController =  TabController(vsync: this,
         length: categoryList.length); // Number of tabs
     tabController.addListener(() {
       productsList.bindStream(
           getProducts(
               categoryList[tabController.index].id!));


       // if(productsList.length == 0) {
       //   print('checking the length ${productsList.length}');
       //   showNoItemsFound.value = true;
       //   print('checking the showNoItemsFound ${showNoItemsFound.value}');
       //   update();
       // }

       // Future.delayed(Duration(milliseconds: 1500),(){
       //
       //   if(productsList.length <= 0) {
       //     print('checking the length ${productsList.length}');
       //     showNoItemsFound.value = true;
       //     print('checking the showNoItemsFound ${showNoItemsFound.value}');
       //     update();
       //   }
       //   else
       //     print('checking the length else ${productsList.length}');
       // });

     });
   });
   Future.delayed(Duration(milliseconds: 1000),(){

     productsList.bindStream(getProducts(categoryNameFirst!));
   });
    super.onInit();
  }


  @override
  void onClose() {
    // TODO: implement onClose
    tabController.dispose();
    super.onClose();
  }

}


