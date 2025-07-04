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
      final centerSlug = prefs.getString('centerSlug');
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

  Future<List<Map<String, dynamic>>> fetchUserSuggestions(String query) async {
    if (query.isEmpty) return [];

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug = preferences.getString('centerSlug');

    final response = await supabase
        .schema('${centerSlug}_prod_schema')
        .from('customers')
        .select('''
        id,
        mobile,
        first_name,
        membershipplan_id,
        membership_data,
        created_at,
        status,
        membershipplan (
          name,
          price,
          billing_cycle,
          peak_price,
          non_peak_price,
          validity
        )
      ''')
        .eq('status',true)
        .or(
      'first_name.ilike.%$query%,mobile.ilike.%$query%',
    ) // Dynamic search on name or mobile
        .limit(10); // Pagination or limit to reduce data size

    return response.map((user) {
      final plan = user['membershipplan'];
      final membershipData = user['membership_data'] as Map<String, dynamic>?;
      // Use purchased_date from membership_data if available, otherwise fall back to null
      DateTime? startDate =
      membershipData != null
          ? DateTime.tryParse(
        membershipData['purchased_date']?.toString() ?? '',
      )
          : null;
      DateTime? endDate;
      if (startDate != null && plan != null && plan['validity'] != null) {
        final billingCycle = plan['billing_cycle']?.toString().toLowerCase();
        final validity = int.tryParse(plan['validity'].toString()) ?? 0;

        if (billingCycle == 'month') {
          endDate = startDate.add(Duration(days: validity));
        } else if (billingCycle == 'year') {
          endDate = DateTime(
            startDate.year,
            startDate.month + validity,
            startDate.day,
          );
        }
      }

      return {
        'id': user['id'] ?? '',
        'name': user['first_name'] ?? '',
        'mobile': user['mobile'] ?? '',
        'membership_plan': plan?['name'] ?? '',
        'price': plan?['price']?.toString() ?? '',
        'billing_cycle': plan?['billing_cycle'] ?? '',
        'peak_price': plan?['peak_price']?.toString() ?? '',
        'non_peak_price': plan?['non_peak_price']?.toString() ?? '',
        'validity_start': startDate?.toIso8601String() ?? '',
        'validity_end': endDate?.toIso8601String() ?? '',
        'membershipplan_id': user['membershipplan_id'] ?? '',
      };
    }).toList();
  }

}