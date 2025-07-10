import 'package:booking_app/models/order.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SimpleController extends GetxController {
  final supabase = Supabase.instance.client;

  // RxList to hold multiple orders
  final RxList<Orders> orders = <Orders>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Note: onInit shouldn't be async - move async operations elsewhere
  }

  Future<void> fetchOrders({String? bookingId}) async {
    try {
      if (bookingId == null) {
        throw Exception('Booking ID cannot be null');
      }

      final SharedPreferences preferences = await SharedPreferences.getInstance();
      String? centerSlug = preferences.getString('centerSlug');

      if (centerSlug == null) {
        throw Exception('Center slug not found in preferences');
      }

      final response = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('orders')
          .select('*')
          .eq('booking_id', bookingId);

      if (response != null && response is List) {
        // Clear existing orders and add new ones
        orders.assignAll(response.map((orderJson) => Orders.fromJson(orderJson)).toList());
      }

      update();

    } catch (e) {
      // Handle errors appropriately
      print(e.toString());
      //Get.snackbar('Error', 'Failed to fetch orders: ${e.toString()}');
      orders.clear(); // Clear orders on error
    }
  }
}