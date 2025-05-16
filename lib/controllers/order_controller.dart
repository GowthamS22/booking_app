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
          bookings (
            booking_no,
            grand_total,
            customer_id,
            customers (
              first_name,
              last_name
            )
          ),
          courts (
            name
          ),
          services (
            name
          )
        ''');

      if (filterType == 'active') {
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
        print('🔍 Filtering Active from $slotStart to $slotEnd');

        query = query
            .eq('status', 'Booked')
            .lte('start_time', slotStart)
            .gte('end_time', slotEnd); //
      } else if (filterType == 'upcoming') {
        query = query.eq('status', 'Booked').gt('start_time', nowStr);
      } else if (filterType == 'scheduled') {
        final future = _formatDateTime(now.add(Duration(days: 7)));
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

      bookings.value = data.map((e) => BookingModel.fromJson(e)).toList();
    } catch (e) {
      print('❌ Error: $e');
      error.value = 'Failed to fetch bookings: $e';
    } finally {
      isLoading.value = false;
    }
  }
}
