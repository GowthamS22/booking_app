import 'package:booking_app/models/products.dart';
import 'package:get/get.dart';

class PosOrderController extends GetxController {
  final RxString orderId = ''.obs;
  final RxList<CartItem> cartItems = <CartItem>[].obs;
  final RxString orderNotes = ''.obs;
  final RxDouble total = 0.0.obs;

  void updateOrder(String id, List<CartItem> items, String notes, double totalAmount) {
    orderId.value = id;
    cartItems.assignAll(items);
    orderNotes.value = notes;
    total.value = totalAmount;
  }

  void clearOrder() {
    orderId.value = '';
    cartItems.clear();
    orderNotes.value = '';
    total.value = 0.0;
  }

  List<CartItem> get currentCart => cartItems.toList();
  String get currentOrderId => orderId.value;
  String get currentNotes => orderNotes.value;
  double get currentTotal => total.value;
}