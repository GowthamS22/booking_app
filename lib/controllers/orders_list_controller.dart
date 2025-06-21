import 'package:booking_app/models/booking_sample.dart';
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
  final isBookingLoading = false.obs;
  final currentBookings = <BookingSample>[].obs;
  final upcomingBookings = <BookingSample>[].obs;

  final selectedCurrentBooking = Rxn<BookingSample>();
  final selectedUpcomingBooking = Rxn<BookingSample>();

  void selectCurrentBooking(BookingSample? booking) {
    selectedCurrentBooking.value = booking;
    selectedUpcomingBooking.value = null; // Clear other selection
  }

  void selectUpcomingBooking(BookingSample? booking) {
    selectedUpcomingBooking.value = booking;
    selectedCurrentBooking.value = null; // Clear other selection
  }

  BookingSample? get selectedBooking => selectedCurrentBooking.value ?? selectedUpcomingBooking.value;

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

  Future<void> fetchBookingsForCourt({
    required String courtId,
    required DateTime currentTime,
  }) async {
    try {
      isBookingLoading(true);

      // Clear previous data
      currentBookings.clear();
      upcomingBookings.clear();

      // Get the current center schema from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final centerSlug = prefs.getString('centerSlug') ?? 's22';
      final schema = '${centerSlug}_prod_schema';

      // Fetch current bookings (slots that include the current time)
      final currentResponse = await supabase
          .schema(schema)
          .from('booking_slots')
          .select('''
            *, 
            bookings(*, customers(*))
          ''')
          .eq('court_id', courtId)
          .gte('end_time', currentTime.toIso8601String())
          .lte('start_time', currentTime.toIso8601String())
          .order('start_time', ascending: true);

      // Fetch upcoming bookings (slots that start after current time)
      final upcomingResponse = await supabase
          .schema(schema)
          .from('booking_slots')
          .select('''
            *, 
            bookings(*, customers(*))
          ''')
          .eq('court_id', courtId)
          .gt('start_time', currentTime.toIso8601String())
          .order('start_time', ascending: true)
          .limit(1); // Only get the next immediate booking

      print('Current ${currentResponse}');
      print('Upcoming ${upcomingResponse}');

      _processBookings(currentResponse, currentBookings);
      _processBookings(upcomingResponse, upcomingBookings);

    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch bookings: ${e.toString()}');
    } finally {
      isBookingLoading(false);
    }
  }

  void _processBookings(List<dynamic>? response, RxList<BookingSample> targetList) {
    if (response != null && response.isNotEmpty) {
      for (var slotData in response) {
        final bookingData = slotData['bookings'];
        if (bookingData != null) {
          final booking = BookingSample.fromJson(bookingData);
          booking.slots.add(BookingSampleSlot.fromJson(slotData));
          targetList.add(booking);
        }
      }
    }
  }



}