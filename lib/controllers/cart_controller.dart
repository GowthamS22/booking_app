// lib/controllers/cart_controller.dart
// import 'package:get/get.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:booking_app/models/products.dart';
// import 'dart:convert';
//
// class CartController extends GetxController {
//   static const String _prefsCartKey = 'shopping_cart';
//
//   final RxList<CartItem> _cartItems = <CartItem>[].obs;
//
//   List<CartItem> get cartItems => _cartItems;
//   double get total => _cartItems.fold(0, (sum, item) => sum + (double.parse(item.product.price) * item.quantity));
//
//   @override
//   void onInit() {
//     super.onInit();
//     loadCartFromPrefs();
//   }
//
//   Future<void> loadCartFromPrefs() async {
//     final prefs = await SharedPreferences.getInstance();
//     final cartJson = prefs.getString(_prefsCartKey);
//     if (cartJson != null) {
//       final List<dynamic> cartData = jsonDecode(cartJson);
//       _cartItems.assignAll(cartData.map((json) => CartItem.fromJson(json)));
//     }
//   }
//
//   Future<void> saveCartToPrefs() async {
//     final prefs = await SharedPreferences.getInstance();
//     final cartJson = jsonEncode(_cartItems.map((item) => item.toJson()).toList());
//     await prefs.setString(_prefsCartKey, cartJson);
//   }
//
//   void addToCart(Products product) {
//     final index = _cartItems.indexWhere((e) => e.product.id == product.id);
//     if (index != -1) {
//       _cartItems[index].quantity++;
//       _cartItems[index].updateAppliedPrice();
//     } else {
//       _cartItems.add(CartItem(product: product));
//     }
//     saveCartToPrefs();
//   }
//
//   void incrementQty(CartItem item) {
//     item.quantity++;
//     item.updateAppliedPrice();
//     saveCartToPrefs();
//   }
//
//   void decrementQty(CartItem item) {
//     if (item.quantity > 1) {
//       item.quantity--;
//       item.updateAppliedPrice();
//     } else {
//       _cartItems.remove(item);
//     }
//     saveCartToPrefs();
//   }
//
//   void removeItem(CartItem item) {
//     _cartItems.remove(item);
//     saveCartToPrefs();
//   }
//
//   void clearCart() {
//     _cartItems.clear();
//     saveCartToPrefs();
//   }
// }


import 'package:get/get.dart';
import 'package:booking_app/models/products.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartItem {
  final Products product;
  RxInt quantity;
  RxDouble appliedPrice;

  CartItem({
    required this.product,
    int? quantity,
    double? appliedPrice,
  })  : quantity = (quantity ?? 1).obs,
        appliedPrice = (appliedPrice ?? double.parse(product.price)).obs;

  void updateAppliedPrice() {
    appliedPrice.value = double.parse(product.price) * quantity.value;
  }

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'quantity': quantity.value,
    'appliedPrice': appliedPrice.value,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    product: Products.fromJson(json['product']),
    quantity: json['quantity'],
    appliedPrice: json['appliedPrice'],
  );
}

// controllers/cart_controller.dart


class CartController extends GetxController {
  static const String _prefsCartKey = 'shopping_cart';

  final RxList<CartItem> _cartItems = <CartItem>[].obs;

  List<CartItem> get cartItems => _cartItems;
  double get total => _cartItems.fold(0, (sum, item) => sum + item.appliedPrice.value);

  @override
  void onInit() {
    super.onInit();
    loadCartFromPrefs();
  }

  Future<void> loadCartFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString(_prefsCartKey);
    if (cartJson != null) {
      final List<dynamic> cartData = jsonDecode(cartJson);
      _cartItems.assignAll(cartData.map((json) => CartItem.fromJson(json)));
    }
  }

  Future<void> saveCartToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = jsonEncode(_cartItems.map((item) => item.toJson()).toList());
    await prefs.setString(_prefsCartKey, cartJson);
  }

  void addToCart(Products product) {
    final index = _cartItems.indexWhere((e) => e.product.id == product.id);
    if (index != -1) {
      _cartItems[index].quantity.value++;
      _cartItems[index].updateAppliedPrice();
    } else {
      _cartItems.add(CartItem(product: product));
    }
    saveCartToPrefs();
  }

  void incrementQty(CartItem item) {
    item.quantity.value++;
    item.updateAppliedPrice();
    saveCartToPrefs();
  }

  void decrementQty(CartItem item) {
    if (item.quantity.value > 1) {
      item.quantity.value--;
      item.updateAppliedPrice();
    } else {
      _cartItems.remove(item);
    }
    saveCartToPrefs();
  }

  void removeItem(CartItem item) {
    _cartItems.remove(item);
    saveCartToPrefs();
  }

  void clearCart() {
    _cartItems.clear();
    saveCartToPrefs();
  }
}