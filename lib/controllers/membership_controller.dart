import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../config/constants.dart';
import '../config/palette.dart';
import '../models/booking_model.dart';
import '../models/membership_plan.dart';
import '../models/user.dart';

class MembershipController extends GetxController {
  final supabase = Supabase.instance.client;
  RxBool isLoading = false.obs;
  RxBool tableLoading = true.obs;

  RxList<Map<String, dynamic>> customers = <Map<String, dynamic>>[].obs;
  List<User> users = [];
  List<User> filteredUsers = [];
  bool sortAscending = true;
  int sortColumnIndex = 1;

  RxBool editLoading = false.obs;
  RxBool cancelLoading = false.obs;
  RxBool paymentLoading = false.obs;
  RxBool cancelSlotIsLoading = false.obs;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  String? selectedMembershipplan;

  RxBool buyNowLoading = false.obs;
  var membershipList = <MembershipPlan>[].obs;
  List currentPlan = [];
  List selectedPlan = [];
  String? centerSlug;
  var selectedBooking = <Booking>[].obs;
  var selectedUser = <User>[].obs;
  var selectedBookingSlots = <BookingSlot>[].obs;
  var actionBookingSlots = <BookingSlot>[].obs;

  final int _itemsPerPage = 10;
  DocumentSnapshot? _lastDocument;

  final List<String> dateOptions = [
    'Today',
    'Yesterday',
    'Tomorrow',
    'Last 7 Days',
    'Select Date',
  ];
  RxString selectedDateOption = 'Today'.obs;
  DateTime selectedDate = DateTime.now();

  // Fetch membership plan details (id and name) where status is true
  RxList<Map<String, dynamic>> membershipPlans = <Map<String, dynamic>>[].obs;

  Future<void> fetchMembershipPlanDetails() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    String? centerSlug           = pref.getString('centerSlug');
    try {
      final response = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('membershipplan')
          .select('*')
          .order('price');

      if (response.isEmpty) {
        print('No membership plans found');
        membershipPlans.clear();
      }

      membershipPlans.assignAll(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      print('Error fetching membership plans: $e');
      // Handle error, e.g., show a snackbar
      showCustomSnackbar(
        'Error',
        'Failed to load membership plans: $e',
        Colors.red,
      );
    } finally {
      update();
    }
  }

  @override
  void onInit() {
    //fetchMembershipList();
    // _loadCenterSlug();
    super.onInit();
  }

  void filterUsers(String query) {
    filteredUsers =
        users.where((user) {
          final name = '${user.firstName} ${user.lastName ?? ''}'.toLowerCase();
          final mobile = user.mobile!.toLowerCase();
          return name.contains(query.toLowerCase()) ||
              mobile.contains(query.toLowerCase());
        }).toList();
    update();
  }

  void onSortCustomerColumn(int columnIndex, bool ascending) {
    if (columnIndex == 0) {
      users.sort(
            (item1, item2) =>
            compareString(ascending, item1.firstName, item2.firstName),
      );
      filteredUsers.sort(
            (item1, item2) =>
            compareString(ascending, item1.firstName, item2.firstName),
      );
    } else if (columnIndex == 1) {
      users.sort(
            (item1, item2) => compareString(ascending, item1.mobile, item2.mobile),
      );
      filteredUsers.sort(
            (item1, item2) => compareString(ascending, item1.mobile, item2.mobile),
      );
    }
    sortColumnIndex = columnIndex;
    sortAscending = ascending;
    update();
  }

  int compareString(bool ascending, var val1, var val2) =>
      ascending
          ? Comparable.compare(val1, val2)
          : Comparable.compare(val2, val1);

  Future<void> fetchCustomerDetails({bool? hasMembership}) async {
    try {
      final SharedPreferences preferences = await SharedPreferences.getInstance();
      String? centerSlug = preferences.getString('centerSlug');

      isLoading.value = true;

      var query = supabase
          .schema('${centerSlug}_prod_schema')
          .from('customers')
          .select('''
            id,
            first_name,
            last_name,
            mobile,
            membershipplan (
              id,
              name
            ),
            bookings (
              id
            ),
            booking_slots_payments (
              paid_amount
            )
          ''')
          .eq('status', true)
          .not('membershipplan_id', 'is', null);

      final response = await query;

      final data = response as List<dynamic>;

      final result = data.map((customer) {
        final bookingList = customer['bookings'] as List<dynamic>? ?? [];
        final paymentList = customer['booking_slots_payments'] as List<dynamic>? ?? [];

        final totalBookings = bookingList.length;
        final totalSpent = paymentList.fold<double>(
          0.0,
              (sum, p) => sum + (p['paid_amount'] as num?)!.toDouble() ?? 0.0,
        );

        return {
          'id': customer['id'],
          'name': '${customer['first_name']}',
          'mobile': customer['mobile'],
          'membership': customer['membershipplan']?['name'] ?? 'N/A',
          'totalBookings': totalBookings,
          'totalSpent': totalSpent.toStringAsFixed(2),
        };
      }).toList();

      customers.value = result;
    } catch (e) {
      print('Error fetching customers: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Add new customer
  Future<Map<String, dynamic>?> addCustomer({
    required String firstName,
    required String mobile,
    String? membershipPlanId,
  }) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug = preferences.getString('centerSlug');

    try {
      final response = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('customers')
          .insert({
            'first_name': firstName,
            'mobile': mobile,
            'membershipplan_id': membershipPlanId,
            'status': true,
          })
          .select('*')
          .single();

      await fetchCustomerDetails();
      return response;
    } catch (e) {
      print('Error adding customer: $e');
      return null;
    }
  }

  // Add new customer
  Future<bool> updateCustomer({
    required String customerId,
    required String name,
    required String mobile,
    String? membershipPlanId,
  }) async {

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug                  = preferences.getString('centerSlug');

    try {
      await supabase
          .schema('${centerSlug}_prod_schema')
          .from('customers')
          .update({
            'first_name': name,
            'mobile': mobile,
            'membershipplan_id': membershipPlanId,
            'status': true,
          })
          .eq('id', customerId);

      await fetchCustomerDetails();
      showCustomSnackbar('Success', 'Customer Updated Successfully', Colors.green);
      return true;
    } catch (e) {
      print('Error adding customer: $e');
      return false;
    }
  }

  // Soft delete customer by setting status to false
  Future<void> softDeleteCustomer(String customerId) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug                  = preferences.getString('centerSlug');
    try {
      await supabase
          .schema('${centerSlug}_prod_schema')
          .from('customers')
          .update({'status': false})
          .eq('id', customerId);
      // Optionally refresh the customer list
      await fetchCustomerDetails();
    } catch (e) {
      print('Error soft deleting customer: $e');
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
        .or('first_name.ilike.%$query%,mobile.ilike.%$query%') // Dynamic search on name or mobile
        .limit(10); // Pagination or limit to reduce data size

    return response.map((user) {
      final plan = user['membershipplan'];
      final membershipData = user['membership_data'] as Map<String, dynamic>?;
      // Use purchased_date from membership_data if available, otherwise fall back to null
      DateTime? startDate = membershipData != null
          ? DateTime.tryParse(membershipData['purchased_date']?.toString() ?? '')
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