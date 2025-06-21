import 'package:booking_app/models/order.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrdersListController extends GetxController {
  final supabase = Supabase.instance.client;
  static OrdersListController instance = Get.find();

  final _orders = <Orders>[].obs;
  final _isLoading = false.obs;
  final _error = ''.obs;

  List<Orders> get orders => _orders.toList();
  bool get isLoading => _isLoading.value;
  String get error => _error.value;

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug                  = preferences.getString('centerSlug');
    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('orders')
          .select('*')
          .order('created_at', ascending: false);
      _orders.assignAll(
        (response as List).map((json) => Orders.fromJson(json)).toList(),
      );
      print(_orders);
    } catch (e) {
      _error.value = 'Failed to load orders: ${e.toString()}';
      print('Error fetching orders: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> refreshOrders() async {
    await fetchOrders();
  }

  Future<List<Orders>> searchOrders(String query) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug                  = preferences.getString('centerSlug');
    try {
      final response = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('orders')
          .select('*')
          .ilike('customer_name', '%$query%')
          .order('created_at', ascending: false);

      return (response as List).map((json) => Orders.fromJson(json)).toList();
    } catch (e) {
      print('Error searching orders: $e');
      return [];
    }
  }

}