import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/palette.dart';
import '../models/booking_model.dart';

class OrderController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  var bookings = <BookingModel>[].obs;
  var isLoading = false.obs;
  var error = ''.obs;
  String _formatDateTime(DateTime dt) {
    return dt.toIso8601String().split('.').first.replaceFirst('T', ' ');
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
        final now = DateTime.now();
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
            .lte('start_time', slotStart)
            .gte('end_time', slotEnd); //
      } else if (filterType == 'upcoming') {
        query = query.eq('status', 'Booked').gt('start_time', nowStr);
      } else if (filterType == 'scheduled') {
        final future = _formatDateTime(now.add(Duration(days: 90)));
        query = query
            .eq('status', 'Booked')
            .gt('start_time', nowStr)
            .lte('start_time', future);
      } else if (filterType == 'all') {
        query = query.eq('status', 'Booked');
      }

      final response = await query;
      final data = response as List;

      print('✅ Filter returned ${data.length} bookings');

      if (data.isEmpty) {
        showCustomSnackbar('$filterType Booking', 'No data found', Colors.red);
        bookings.value = [];
        return;
      }
      print(data);
      bookings.value = data.map((e) => BookingModel.fromJson(e)).toList();
    } catch (e) {
      print('❌ Error: $e');
      error.value = 'Failed to fetch bookings: $e';
    } finally {
      isLoading.value = false;
    }
  }
}
