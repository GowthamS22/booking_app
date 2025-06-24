import 'package:booking_app/models/order.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SimpleController extends GetxController {
  final supabase = Supabase.instance.client;

  // Correct way to declare Rx variable for a single order
  final Rx<Orders?> order = Rx<Orders?>(null);

  @override
  void onInit() {
    super.onInit();
    // Note: onInit shouldn't be async - move async operations elsewhere
  }

  Future<void> fetchOrder({String? bookingId}) async {
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
          .eq('booking_id', bookingId)
          .single();
      if(response!=null) {
        // Update the Rx variable using .value
        order.value = Orders.fromJson(response);
        update();
      }

    } catch (e) {
      // Handle errors appropriately
      print(e.toString());
      //Get.snackbar('Error', 'Failed to fetch order: ${e.toString()}');
      order.value = null; // Reset order on error
    }
  }
}