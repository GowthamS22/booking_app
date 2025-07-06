import 'dart:convert';

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

  Future<void> fetchBookingsOld(String filterType) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug                  = preferences.getString('centerSlug');
    try {
      isLoading.value = true;
      error.value = '';

      final now = DateTime.now();
      final nowStr = _formatDateTime(now);

      var query = supabase
          .schema('${centerSlug}_prod_schema')
          .from('booking_slots')
          .select('''
          start_time,
          end_time,
          booking_id,
          court_id,
          service_id,
          is_extended_booking,
          status,
          price,
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
            ),
            closed,
            is_cancelled,
            is_showoff,
            bcart_items
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
        // Fetch all slots for today
        final todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
        final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        query = query
            .eq('status', 'Booked')
            .eq('bookings.closed', false)
            .eq('bookings.is_cancelled', false)
            .eq('bookings.is_showoff', false)
            .gte('start_time', todayStart.toIso8601String())
            .lte('end_time', todayEnd.toIso8601String());
      } else if (filterType == 'upcoming') {
        query = query
            .eq('bookings.is_cancelled', false)
            .eq('bookings.is_showoff', false)
            .eq('bookings.closed', false)
            .eq('status', 'Booked')
            .gt('start_time', nowStr);
      } else if (filterType == 'scheduled') {
        final future = _formatDateTime(now.add(Duration(days: 90)));
        query = query
            .eq('bookings.closed', false)
            .eq('status', 'Booked')
            .gt('start_time', nowStr)
            .lte('start_time', future);
      } else if (filterType == 'all') {
        query = query
            .eq('bookings.closed', false)
            .inFilter('status', ['Booked', 'Cancelled', 'No Show']);
      } else if (filterType == 'unpaid') {
        // Filter by payment_status in the bookings table - only show today's unpaid bookings
        final todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
        final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        query = query
            .eq('bookings.is_cancelled', false)
            .eq('bookings.is_showoff', false)
            .eq('bookings.closed', false)
            .not('bookings.payment_status', 'in', ['Paid', 'paid'])
            .gte('start_time', todayStart.toIso8601String())
            .lte('end_time', todayEnd.toIso8601String());
      } else if (filterType == 'paid') {
        // Add a new filter for paid bookings if needed
        query = query
            .eq('bookings.closed', false)
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
          .schema('${centerSlug}_prod_schema')
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


      final ordersResponse1 = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('orders')
          .select('booking_id, total, order_status')
      //.eq('order_status', 'Pending')
          .inFilter('booking_id', bookingIds);

      final ordersData1 = ordersResponse1 as List<dynamic>;

      // Create a map of booking_id to sum of order totals
      final ordersMap1 = <String, double>{};
      for (final order1 in ordersData1) {
        final bookingId = order1['booking_id']?.toString();
        if (bookingId != null) {
          final total = (order1['total'] as num?)?.toDouble() ?? 0.0;
          ordersMap1.update(bookingId, (value) => value + total, ifAbsent: () => total);
        }
      }

      // Process each booking slot to include orders total
      final processedData = data.map((item) {
        final bookingId = item['booking_id']?.toString();
        final ordersTotal = bookingId != null ? ordersMap[bookingId] ?? 0.0 : 0.0;
        final ordersTotal1 = bookingId != null ? ordersMap1[bookingId] ?? 0.0 : 0.0;

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
          if(filterType == 'unpaid') {

            // final membershipCarData = await supabase
            //     .schema('${centerSlug}_prod_schema')
            //     .from('membership_data')
            //     .select('customer_id, price, status')
            //     .eq('customer_id', newItem['bookings']['customer_id'])
            //     .eq('status', true)
            //     .maybeSingle();
            //
            // if(membershipCarData!=null) {
            //   finalGrandTotal += double.parse(membershipCarData['price'].toString());
            // }

            newItem['bookings']['grand_total'] = finalGrandTotal + ordersTotal;
          } else {
            newItem['bookings']['grand_total'] = bookingGrandTotal + ordersTotal1;
          }
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

      // STEP 2: Merge consecutive time slots and calculate individual court amounts
      final List<Map<String, dynamic>> merged = [];
      for (final item in processedData) {
        if (merged.isEmpty) {
          // For the first item, set the individual court price
          item['individual_court_amount'] = (item['price'] as num?)?.toDouble() ?? 0.0;
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
          // Extend time and add to the individual court amount
          last['end_time'] = item['end_time'];
          final lastAmount = (last['individual_court_amount'] as num?)?.toDouble() ?? 0.0;
          final currentAmount = (item['price'] as num?)?.toDouble() ?? 0.0;
          last['individual_court_amount'] = lastAmount + currentAmount;
        } else {
          // New booking slot, set individual court price
          item['individual_court_amount'] = (item['price'] as num?)?.toDouble() ?? 0.0;
          merged.add(item);
        }
      }

      // For 'Active', only show merged blocks that are currently active
      List<Map<String, dynamic>> filteredMerged = merged;
      if (filterType == 'Active') {
        final now = DateTime.now();
        filteredMerged = merged.where((item) {
          final start = DateTime.parse(item['start_time']);
          final end = DateTime.parse(item['end_time']);
          return start.isBefore(now) && end.isAfter(now);
        }).toList();
      }

      // ✅ STEP 3: Sort by time descending for upcoming, unpaid, all tabs; by booking_no for active tab
      if (filterType == 'Active') {
        // For Active tab, sort by booking_no ascending  
        filteredMerged.sort((a, b) {
          final aNo = (a['bookings']?['booking_no'] ?? '').toString();
          final bNo = (b['bookings']?['booking_no'] ?? '').toString();
          return aNo.compareTo(bNo);
        });
      } else {
        // For upcoming, unpaid, all tabs, sort by start_time descending (newest first)
        filteredMerged.sort((a, b) {
          final aTime = DateTime.parse(a['start_time']);
          final bTime = DateTime.parse(b['start_time']);
          return bTime.compareTo(aTime); // Reversed for descending order
        });
      }

      // ✅ STEP 4: Format & map to model
      final result =
      filteredMerged.map((e) {
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

  Future<void> fetchBookings(String filterType) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug = preferences.getString('centerSlug');
    try {
      isLoading.value = true;
      error.value = '';

      final now = DateTime.now();
      final nowStr = _formatDateTime(now);

      var query = supabase
          .schema('${centerSlug}_prod_schema')
          .from('booking_slots')
          .select('''
          start_time,
          end_time,
          booking_id,
          court_id,
          service_id,
          is_extended_booking,
          status,
          price,
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
            ),
            closed,
            is_cancelled,
            is_showoff,
            bcart_items
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
        // Fetch all slots for today
        final todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
        final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        query = query
            .eq('status', 'Booked')
            .eq('bookings.closed', false)
            .eq('bookings.is_cancelled', false)
            .eq('bookings.is_showoff', false)
            .gte('start_time', todayStart.toIso8601String())
            .lte('end_time', todayEnd.toIso8601String());
      } else if (filterType == 'upcoming') {
        query = query
            .eq('bookings.is_cancelled', false)
            .eq('bookings.is_showoff', false)
            .eq('bookings.closed', false)
            .eq('status', 'Booked')
            .gt('start_time', nowStr);
      } else if (filterType == 'scheduled') {
        final future = _formatDateTime(now.add(Duration(days: 90)));
        query = query
            .eq('bookings.closed', false)
            .eq('status', 'Booked')
            .gt('start_time', nowStr)
            .lte('start_time', future);
      } else if (filterType == 'all') {
        query = query
            .eq('bookings.closed', false)
            .inFilter('status', ['Booked', 'Cancelled', 'No Show']);
      } else if (filterType == 'unpaid') {
        // Filter by payment_status in the bookings table - only show today's unpaid bookings
        final todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
        final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        query = query
            .eq('bookings.is_cancelled', false)
            .eq('bookings.is_showoff', false)
            .eq('bookings.closed', false)
            .not('bookings.payment_status', 'in', ['Paid', 'paid'])
            .gte('start_time', todayStart.toIso8601String())
            .lte('end_time', todayEnd.toIso8601String());
      } else if (filterType == 'paid') {
        // Add a new filter for paid bookings if needed
        query = query
            .eq('bookings.closed', false)
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
          .schema('${centerSlug}_prod_schema')
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

      final ordersResponse1 = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('orders')
          .select('booking_id, total, order_status')
          .inFilter('booking_id', bookingIds);

      final ordersData1 = ordersResponse1 as List<dynamic>;

      // Create a map of booking_id to sum of order totals
      final ordersMap1 = <String, double>{};
      for (final order1 in ordersData1) {
        final bookingId = order1['booking_id']?.toString();
        if (bookingId != null) {
          final total = (order1['total'] as num?)?.toDouble() ?? 0.0;
          ordersMap1.update(bookingId, (value) => value + total, ifAbsent: () => total);
        }
      }

      // Process each booking slot to include orders total
      final processedData = await Future.wait(data.map((item) async {
        final bookingId = item['booking_id']?.toString();
        final ordersTotal = bookingId != null ? ordersMap[bookingId] ?? 0.0 : 0.0;
        final ordersTotal1 = bookingId != null ? ordersMap1[bookingId] ?? 0.0 : 0.0;

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

          if (filterType == 'unpaid') {
            // Check for active membership first
            var membershipCarData = await supabase
                .schema('${centerSlug}_prod_schema')
                .from('membership_data')
                .select('customer_id, price, status')
                .eq('customer_id', newItem['bookings']['customer_id'])
                .eq('status', true)
                .maybeSingle();

            // If no active membership found, check for pending membership (Pay Later bookings)
            if (membershipCarData == null) {
              membershipCarData = await supabase
                  .schema('${centerSlug}_prod_schema')
                  .from('membership_data')
                  .select('customer_id, price, status')
                  .eq('customer_id', newItem['bookings']['customer_id'])
                  .eq('status', false)
                  .maybeSingle();
            }

            // If still no membership found, check for string status 'pending'
            // if (membershipCarData == null) {
            //   try {
            //     membershipCarData = await supabase
            //         .schema('${centerSlug}_prod_schema')
            //         .from('membership_data')
            //         .select('customer_id, price, status')
            //         .eq('customer_id', newItem['bookings']['customer_id'])
            //         .eq('status', 'pending')
            //         .maybeSingle();
            //   } catch (e) {
            //     print('Skipping string status query due to type mismatch: $e');
            //   }
            // }

            if (membershipCarData != null) {
              finalGrandTotal += double.parse(membershipCarData['price'].toString());
            }

            newItem['bookings']['grand_total'] = finalGrandTotal + ordersTotal;
          } else {
            newItem['bookings']['grand_total'] = bookingGrandTotal + ordersTotal1;
          }
        }

        return newItem;
      }));

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

      // STEP 2: Merge consecutive time slots and calculate individual court amounts
      final List<Map<String, dynamic>> merged = [];
      for (final item in processedData) {
        if (merged.isEmpty) {
          // For the first item, set the individual court price
          item['individual_court_amount'] = (item['price'] as num?)?.toDouble() ?? 0.0;
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
          // Extend time and add to the individual court amount
          last['end_time'] = item['end_time'];
          final lastAmount = (last['individual_court_amount'] as num?)?.toDouble() ?? 0.0;
          final currentAmount = (item['price'] as num?)?.toDouble() ?? 0.0;
          last['individual_court_amount'] = lastAmount + currentAmount;
        } else {
          // New booking slot, set individual court price
          item['individual_court_amount'] = (item['price'] as num?)?.toDouble() ?? 0.0;
          merged.add(item);
        }
      }

      // For 'Active', only show merged blocks that are currently active
      List<Map<String, dynamic>> filteredMerged = merged;
      if (filterType == 'Active') {
        final now = DateTime.now();
        filteredMerged = merged.where((item) {
          final start = DateTime.parse(item['start_time']);
          final end = DateTime.parse(item['end_time']);
          return start.isBefore(now) && end.isAfter(now);
        }).toList();
      }

      // ✅ STEP 3: Sort by time descending for upcoming, unpaid, all tabs; by booking_no for active tab
      if (filterType == 'Active') {
        // For Active tab, sort by booking_no ascending  
        filteredMerged.sort((a, b) {
          final aNo = (a['bookings']?['booking_no'] ?? '').toString();
          final bNo = (b['bookings']?['booking_no'] ?? '').toString();
          return aNo.compareTo(bNo);
        });
      } else {
        // For upcoming, unpaid, all tabs, sort by start_time descending (newest first)
        filteredMerged.sort((a, b) {
          final aTime = DateTime.parse(a['start_time']);
          final bTime = DateTime.parse(b['start_time']);
          return bTime.compareTo(aTime); // Reversed for descending order
        });
      }

      // ✅ STEP 4: Format & map to model
      final result = filteredMerged
          .map((e) {
        e['start_time_formatted'] = format12Hour(e['start_time']);
        e['end_time_formatted'] = format12Hour(e['end_time']);
        return BookingModel.fromJson(e);
      })
          .toList();

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

      // Check for active membership first
      var membershipDataResponse = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('membership_data')
          .select('*')
          .eq('customer_id', userResponse!['id'])
          .eq('status', true)
          .maybeSingle();

      // If no active membership found, check for pending membership (Pay Later bookings)
      if (membershipDataResponse == null) {
        membershipDataResponse = await supabase
            .schema('${centerSlug}_prod_schema')
            .from('membership_data')
            .select('*')
            .eq('customer_id', userResponse['id'])
            .eq('status', false)
            .maybeSingle();
      }

      // If still no membership found, check for string status 'pending'
      // if (membershipDataResponse == null) {
      //   try {
      //     membershipDataResponse = await supabase
      //         .schema('${centerSlug}_prod_schema')
      //         .from('membership_data')
      //         .select('*')
      //         .eq('customer_id', userResponse['id'])
      //         .eq('status', 'pending')
      //         .maybeSingle();
      //   } catch (e) {
      //     print('Skipping string status query due to type mismatch: $e');
      //   }
      // }

      // Return a combined object
      return {
        'booking': updatedBookingResponse,
        'order': orderResponse,
        'customer': userResponse,
        'membership_data': membershipDataResponse
      };

    } catch (e) {
      showCustomSnackbar('Failed', '${e.toString()}', Palette.dangerTxt);
      return null;
    }
  }

  Future<Map<String, dynamic>?> getIndividualCourtInfo({
    String? bookingNo,
    String? courtId,
    DateTime? startTime,
    DateTime? endTime,
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
          .select('*, booking_slots(*), booking_payments(*)')
          .eq('booking_no', bookingNo)
          .maybeSingle();

      if (bookingResponse == null) {
        throw Exception("Booking not found");
      }

      final bookingId = bookingResponse['id'];
      final customerId = bookingResponse['customer_id'];

      // Get customer info
      final userResponse = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('customers')
          .select('*, membershipplan(*)')
          .eq('id', customerId)
          .maybeSingle();

      // Get specific court slots for this court and time range
      var query = supabase
          .schema('${centerSlug}_prod_schema')
          .from('booking_slots')
          .select('*')
          .eq('booking_id', bookingId);
      
      if (courtId != null) {
        query = query.eq('court_id', courtId);
      }
      
      print('🔍 Querying booking slots: bookingId=$bookingId, courtId=$courtId, startTime=${startTime!.toIso8601String()}, endTime=${endTime!.toIso8601String()}');
      
      // First get ALL slots for this booking to debug
      final allSlotsForBooking = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('booking_slots')
          .select('*')
          .eq('booking_id', bookingId)
          .order('start_time');
          
      print('🔍 ALL slots for this booking: ${allSlotsForBooking.length}');
      for (final slot in allSlotsForBooking) {
        print('  - Slot: ${slot['start_time']} to ${slot['end_time']}, court: ${slot['court_id']}, price: ${slot['price']}');
      }
      
      // Now query for specific court and time range
      final courtSlots = await query
          .gte('start_time', startTime.toIso8601String())
          .lte('end_time', endTime.toIso8601String())
          .order('start_time');
          
      print('📊 Found ${courtSlots.length} court slots matching criteria');

      // Calculate total amount for this specific court
      double courtTotal = 0.0;
      for (final slot in courtSlots) {
        courtTotal += (slot['price'] as num).toDouble();
      }

      // Check if any payments have been made for these specific slots
      final paidSlots = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('booking_slots_payments')
          .select('*, booking_slots(*)')
          .eq('booking_id', bookingId)
          .inFilter('booking_slots_id', courtSlots.map((s) => s['id']).toList());

      double paidAmount = 0.0;
      for (final payment in paidSlots) {
        paidAmount += (payment['paid_amount'] as num).toDouble();
      }

      final remainingAmount = courtTotal - paidAmount;

      // Get membership data if applicable - check for active membership first
      var membershipDataResponse = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('membership_data')
          .select('*')
          .eq('customer_id', customerId)
          .eq('status', true)
          .maybeSingle();

      // If no active membership found, check for pending membership (Pay Later bookings)
      if (membershipDataResponse == null) {
        membershipDataResponse = await supabase
            .schema('${centerSlug}_prod_schema')
            .from('membership_data')
            .select('*')
            .eq('customer_id', customerId)
            .eq('status', false)
            .maybeSingle();
      }

      // If still no membership found, check for string status 'pending'
      // if (membershipDataResponse == null) {
      //   try {
      //     membershipDataResponse = await supabase
      //         .schema('${centerSlug}_prod_schema')
      //         .from('membership_data')
      //         .select('*')
      //         .eq('customer_id', customerId)
      //         .eq('status', 'pending')
      //         .maybeSingle();
      //   } catch (e) {
      //     print('Skipping string status query due to type mismatch: $e');
      //   }
      // }

      return {
        'booking': bookingResponse,
        'customer': userResponse,
        'court_slots': courtSlots,
        'court_total': courtTotal,
        'paid_amount': paidAmount,
        'remaining_amount': remainingAmount,
        'membership_data': membershipDataResponse,
      };

    } catch (e) {
      print('❌ getIndividualCourtInfo error: $e');
      print('Parameters: bookingNo=$bookingNo, courtId=$courtId, startTime=$startTime, endTime=$endTime');
      showCustomSnackbar('Failed', 'Error getting court info: ${e.toString()}', Palette.dangerTxt);
      return null;
    }
  }

  Future<Map<String, dynamic>?> getMembershipDetails({
    String? membershipId,
  }) async {
    try {
      final SharedPreferences preferences = await SharedPreferences.getInstance();
      String? centerSlug = preferences.getString('centerSlug');

      if (centerSlug == null || membershipId == null) {
        throw Exception("Missing centerSlug or bookingNo");
      }

      // Fetch membership details
      final membershipResponse = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('membershipplan')
          .select('*')
          .eq('id', membershipId)
          .maybeSingle(); // use maybeSingle to avoid throwing if no match

      if (membershipResponse == null) {
        throw Exception("Booking not found");
      }

      return {
        'membership': membershipResponse,
      };

    } catch (e) {
      showCustomSnackbar('Failed', '${e.toString()}', Palette.dangerTxt);
      return null;
    }
  }

}
