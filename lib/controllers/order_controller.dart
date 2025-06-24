import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
      }

      final response = await query;
      final data = response as List<dynamic>;

      print('✅ Filter returned ${data.length} slots');

      if (data.isEmpty) {
        showCustomSnackbar('$filterType Booking', 'No data found', Colors.red);
        bookings.value = [];
        return;
      }

      // STEP 1: Sort by all relevant fields
      data.sort((a, b) {
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
      for (final item in data) {
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
}
