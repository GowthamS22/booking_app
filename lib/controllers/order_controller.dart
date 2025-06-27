import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/palette.dart';
import '../models/booking_model.dart';

import 'package:intl/intl.dart';

class OrderController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  var bookings = <BookingModel>[].obs;
  var isLoading = false.obs;
  var error = ''.obs;

  String _formatDateTime(DateTime dt) {
    return dt.toIso8601String().split('.').first.replaceFirst('T', ' ');
  }

  String format12Hour(String isoTime) {
    final formatter = DateFormat('hh:mm a');
    return formatter.format(DateTime.parse(isoTime));
  }

  Future<void> fetchBookings(String filterType) async {
    try {
      isLoading.value = true;
      error.value = '';

      final now = DateTime.now();
      final nowStr = _formatDateTime(now);

      var query = supabase
          .schema('s22_prod_schema')
          .from('booking_slots')
          .select('''
          start_time,
          end_time,
          booking_id,
          court_id,
          service_id,
          is_extended_booking,
          status,
          bookings (
            booking_no,
            grand_total,
            customer_id,
            payment_status,
            customers (
              first_name,
              last_name,
              mobile
            ),
            booking_payments (
              total
            )
          ),
          platform_status!court_id (
            platform_id,
            sport_id,
            sports (
              platform_name,
              sport_name
            )
          )
        ''');

      if (filterType == 'Active') {
        final minute = now.minute;
        final slotStart = DateTime(
          now.year,
          now.month,
          now.day,
          now.hour,
          minute < 30 ? 0 : 30,
        );
        final slotEnd = slotStart.add(Duration(minutes: 30));
        query = query
            .eq('status', 'Booked')
            .lte('start_time', slotStart.toIso8601String())
            .gte('end_time', slotEnd.toIso8601String());
      } else if (filterType == 'upcoming') {
        query = query.eq('status', 'Booked').gt('start_time', nowStr);
      } else if (filterType == 'scheduled') {
        final future = _formatDateTime(now.add(Duration(days: 90)));
        query = query
            .eq('status', 'Booked')
            .gt('start_time', nowStr)
            .lte('start_time', future);
      } else if (filterType == 'all') {
        query = query.inFilter('status', ['Booked', 'Cancelled', 'No Show']);
      } else if (filterType == 'unpaid') {
        // Filter by payment_status in the bookings table
        query = query.neq('bookings.payment_status', 'Paid');
      } else if (filterType == 'paid') {
        // Add a new filter for paid bookings if needed
        query = query
            .eq('bookings.payment_status', 'Paid')
            .eq('status', 'Booked');
      }

      final response = await query;
      final data = response as List<dynamic>;

      print('✅ Filter returned ${data.length} slots');

      if (data.isEmpty) {
        showCustomSnackbar('$filterType Booking', 'No data found', Colors.red);
        bookings.value = [];
        return;
      }

      // Get all unique booking_ids to fetch their orders
      final bookingIds = data
          .map((item) => item['booking_id']?.toString())
          .where((id) => id != null)
          .toSet()
          .toList();

      // Fetch all orders for these bookings
      final ordersResponse = await supabase
          .schema('s22_prod_schema')
          .from('orders')
          .select('booking_id, total, order_status')
          .eq('order_status', 'Pending')
          .inFilter('booking_id', bookingIds);

      final ordersData = ordersResponse as List<dynamic>;

      // Create a map of booking_id to sum of order totals
      final ordersMap = <String, double>{};
      for (final order in ordersData) {
        final bookingId = order['booking_id']?.toString();
        if (bookingId != null) {
          final total = (order['total'] as num?)?.toDouble() ?? 0.0;
          ordersMap.update(bookingId, (value) => value + total, ifAbsent: () => total);
        }
      }

      // Process each booking slot to include orders total
      final processedData = data.map((item) {
        final bookingId = item['booking_id']?.toString();
        final ordersTotal = bookingId != null ? ordersMap[bookingId] ?? 0.0 : 0.0;

        // Create a deep copy of the item
        final newItem = Map<String, dynamic>.from(item);
        if (newItem['bookings'] != null) {
          newItem['bookings'] = Map<String, dynamic>.from(newItem['bookings']);
          final bookingGrandTotal = (newItem['bookings']['grand_total'] as num?)?.toDouble() ?? 0.0;

          // Calculate grand total from booking_payments if they exist
          final List<dynamic> bookingPayments = newItem['bookings']['booking_payments'] ?? [];
          double finalGrandTotal = bookingGrandTotal;

          if (bookingPayments.isNotEmpty) {
            final double paymentsTotal = bookingPayments.fold(0.0, (sum, payment) {
              return sum + (payment['total'] as num).toDouble();
            });
            finalGrandTotal = bookingGrandTotal - paymentsTotal;
          }

          newItem['bookings']['grand_total'] = finalGrandTotal + ordersTotal;
        }

        return newItem;
      }).toList();

      // STEP 1: Sort by all relevant fields
      processedData.sort((a, b) {
        int cmp = (a['bookings']?['customer_id'] ?? '').toString().compareTo((b['bookings']?['customer_id'] ?? '').toString());
        if (cmp != 0) return cmp;
        cmp = (a['booking_id'] ?? '').toString().compareTo((b['booking_id'] ?? '').toString());
        if (cmp != 0) return cmp;
        cmp = (a['court_id'] ?? '').toString().compareTo((b['court_id'] ?? '').toString());
        if (cmp != 0) return cmp;
        cmp = (a['service_id'] ?? '').toString().compareTo((b['service_id'] ?? '').toString());
        if (cmp != 0) return cmp;
        cmp = (a['status'] ?? '').toString().compareTo((b['status'] ?? '').toString());
        if (cmp != 0) return cmp;
        return DateTime.parse(a['start_time']).compareTo(DateTime.parse(b['start_time']));
      });

      // STEP 2: Merge consecutive time slots
      final List<Map<String, dynamic>> merged = [];
      for (final item in processedData) {
        if (merged.isEmpty) {
          merged.add(item);
          continue;
        }

        final last = merged.last;

        final isSameBooking =
            last['booking_id'] == item['booking_id'] &&
            last['court_id'] == item['court_id'] &&
            last['service_id'] == item['service_id'] &&
            last['status'] == item['status'] &&
            (last['bookings']?['customer_id'] == item['bookings']?['customer_id']);

        final lastEnd = DateTime.parse(last['end_time']);
        final currStart = DateTime.parse(item['start_time']);

        if (isSameBooking && lastEnd == currStart) {
          // Extend time
          last['end_time'] = item['end_time'];
        } else {
          merged.add(item);
        }
      }

      // ✅ STEP 3: Sort by booking_no ascending
      merged.sort((a, b) {
        final aNo = (a['bookings']?['booking_no'] ?? '').toString();
        final bNo = (b['bookings']?['booking_no'] ?? '').toString();
        return aNo.compareTo(bNo);
      });

      // ✅ STEP 4: Format & map to model
      final result =
          merged.map((e) {
            e['start_time_formatted'] = format12Hour(e['start_time']);
            e['end_time_formatted'] = format12Hour(e['end_time']);
            return BookingModel.fromJson(e);
          }).toList();

      bookings.value = result;
    } catch (e) {
      print('❌ Error: $e');
      error.value = 'Failed to fetch bookings: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> getBookingInfo({
    String? bookingNo,
  }) async {
    try {
      final SharedPreferences preferences = await SharedPreferences.getInstance();
      String? centerSlug = preferences.getString('centerSlug');

      if (centerSlug == null || bookingNo == null) {
        throw Exception("Missing centerSlug or bookingNo");
      }

      // Fetch booking details
      final bookingResponse = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('bookings')
          .select('*, booking_slots(*, platform_status!booking_slots_court_id_fkey(*, sports(sport_name))), booking_payments(*), booking_slots_payments(*)')
          .eq('booking_no', bookingNo)
          .maybeSingle(); // use maybeSingle to avoid throwing if no match

      if (bookingResponse == null) {
        throw Exception("Booking not found");
      }

      final bookingId   = bookingResponse['id'];
      final customerId  = bookingResponse['customer_id'];
      final originalGrandTotal = (bookingResponse['grand_total'] as num?)?.toDouble() ?? 0.0;

      // Calculate grand total from booking_payments if they exist
      final List<dynamic> bookingPayments = bookingResponse['booking_payments'] ?? [];
      double finalGrandTotal = originalGrandTotal;

      if (bookingPayments.isNotEmpty) {
        final double paymentsTotal = bookingPayments.fold(0.0, (sum, payment) {
          return sum + (payment['total'] as num).toDouble();
        });
        finalGrandTotal = originalGrandTotal - paymentsTotal;
      }

      // Update the booking response with the appropriate grand total
      final updatedBookingResponse = {
        ...bookingResponse,
        'grand_total': finalGrandTotal,
      };

      final userResponse = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('customers')
          .select('*, membershipplan(*)')
          .eq('id', customerId!)
          .maybeSingle();

      // Fetch related order
      final orderResponse = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('orders')
          .select('*')
          .eq('order_status','Pending')
          .eq('booking_id', bookingId)
          .maybeSingle();

      // Return a combined object
      return {
        'booking': updatedBookingResponse,
        'order': orderResponse,
        'customer': userResponse,
      };

    } catch (e) {
      showCustomSnackbar('Failed', '${e.toString()}', Palette.dangerTxt);
      return null;
    }
  }



}
