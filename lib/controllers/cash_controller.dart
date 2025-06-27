import 'package:booking_app/config/constants.dart';
import 'package:booking_app/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CashController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current opening balance
  Future<double> getOpeningBalance() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug                  = preferences.getString('centerSlug');
    final String schema                 = '${centerSlug}_prod_schema';
    try {
      final response = await _supabase
          .schema(schema)
          .from('open_close_cash')
          .select('opening_balance')
          .eq('status', 'Current')
          .single();
      return (double.parse(response['opening_balance']) as num).toDouble();
    } catch (e) {
      Get.snackbar('Error', 'No active cash session found');
      return 0.0;
    }
  }

  // Close cash - update existing record
  Future<bool> closeCash({
    required double closingAmount,
    required double cashSales,
    required double eftposSales,
    double? eftposFromDevice,
    double? otherSpend,
    String? cashDifferenceReason,
    String? eftposDifferenceReason,
    String? otherSpendReason,
  }) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug                  = preferences.getString('centerSlug');
    final String schema                 = '${centerSlug}_prod_schema';
    String? userId                      = preferences.getString('userId');
    try {
      // Get current open cash record
      final currentRecord = await _supabase
          .schema(schema)
          .from('open_close_cash')
          .select()
          .eq('status', 'Current')
          .single();

      // Update with closing information
      await _supabase
          .schema(schema)
          .from('open_close_cash')
          .update({
            'closing_data': {
              'closing_balance': closingAmount,
              'closed_at': DateTime.now().toIso8601String(),
              'status': 'Closed',
              'cash_sales': cashSales,
              'eftpos_sales': eftposSales,
              'eftpos_from_device': eftposFromDevice,
              'other_spend': otherSpend,
              'cash_difference_reason': cashDifferenceReason,
              'eftpos_difference_reason': eftposDifferenceReason,
              'other_spend_reason': otherSpendReason,
              'closed_by': userId,
            },
            'status': 'Completed'
          })
          .eq('id', currentRecord['id']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('openCloseId');
      await prefs.remove('pin');
      authController.pin.value =  '';
      authController.openCloseId = '';
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to close cash: ${e.toString()}');
      return false;
    }
  }

  // Get sales totals (cash and EFTPOS)
  Future<Map<String, double>> getSalesTotals() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug                  = preferences.getString('centerSlug');
    final String schema                 = '${centerSlug}_prod_schema';
    try {
      // Get current open cash record to know when the session started
      final openRecord = await _supabase
          .schema(schema)
          .from('open_close_cash')
          .select('created_at')
          .eq('status', 'Current')
          .single();

      // Query orders since the cash was opened
      final response = await _supabase
          .schema(schema)
          .from('orders')
          .select('payment_type, total_amount')
          .gte('created_at', openRecord['created_at'])
          .eq('status', 'Completed');

      double cashTotal = 0;
      double eftposTotal = 0;
      double onAccountTotal = 0;

      for (var order in response) {
        switch (order['payment_type']) {
          case 'Cash':
            cashTotal += (order['total_amount'] as num).toDouble();
            break;
          case 'EFTPOS':
            eftposTotal += (order['total_amount'] as num).toDouble();
            break;
          case 'OnAccount':
            onAccountTotal += (order['total_amount'] as num).toDouble();
            break;
        }
      }

      return {
        'cashTotal': cashTotal,
        'eftposTotal': eftposTotal,
        'onAccountTotal': onAccountTotal,
      };
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch sales totals: ${e.toString()}');
      return {
        'cashTotal': 0.0,
        'eftposTotal': 0.0,
        'onAccountTotal': 0.0,
      };
    }
  }

  // Check if cash is already open
  Future<bool> isCashOpen() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug                  = preferences.getString('centerSlug');
    final String schema                 = '${centerSlug}_prod_schema';
    try {
      final response = await _supabase
          .schema(schema)
          .from('open_close_cash')
          .select()
          .eq('status', 'Current');

      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<double> getOrdersAndBookingsTotal() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug = preferences.getString('centerSlug');
    final String schema = '${centerSlug}_prod_schema';

    double ordersTotal = 0.0;
    double bookingsTotal = 0.0;

    try {
      // Get Orders Total
      final ordersResponse = await _supabase
          .schema(schema)
          .from('orders')
          .select('total')
          .eq('status', 'Completed')
          .eq('closed', false);

      final orders = ordersResponse as List<dynamic>;
      ordersTotal = orders.fold<double>(
        0.0,
            (sum, order) => sum + double.tryParse(order['total'].toString())!,
      );
    } catch (e) {
      showCustomSnackbar('Error', 'Failed to fetch orders total', Colors.orange);
    }

    try {
      // Get Bookings Total
      final bookingsResponse = await _supabase
          .schema(schema)
          .from('bookings')
          .select('grand_total');

      final bookings = bookingsResponse as List<dynamic>;
      bookingsTotal = bookings.fold<double>(
        0.0,
            (sum, booking) => sum + double.tryParse(booking['grand_total'].toString())!,
      );
    } catch (e) {
      showCustomSnackbar('Error', 'Failed to fetch bookings total', Colors.orange);
    }

    return ordersTotal + bookingsTotal;
  }

  Future<Map<String, double>> getTotalsByPaymentType() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug = preferences.getString('centerSlug');
    final String schema = '${centerSlug}_prod_schema';

    Map<String, double> result = {
      'Cash': 0.0,
      'EFTPOS': 0.0,
      'On Acc. / Void': 0.0,
    };

    double safeParse(dynamic value) {
      return double.tryParse(value.toString()) ?? 0.0;
    }

    try {
      for (String paymentType in ['Cash', 'EFTPOS', 'On Acc. / Void']) {
        double ordersTotal = 0.0;
        double bookingsTotal = 0.0;

        // Orders
        final ordersResponse = await _supabase
            .schema(schema)
            .from('orders')
            .select('total')
            .eq('order_status', 'Completed')
            .eq('closed', false)
            .eq('payment_type', paymentType);

        final orders = ordersResponse as List<dynamic>;
        ordersTotal = orders.fold<double>(
          0.0,
              (sum, order) => sum + safeParse(order['total']),
        );

        // Bookings
        final bookingsResponse = await _supabase
            .schema(schema)
            .from('bookings')
            .select('grand_total')
            .eq('payment_type', paymentType);

        final bookings = bookingsResponse as List<dynamic>;
        bookingsTotal = bookings.fold<double>(
          0.0,
              (sum, booking) => sum + safeParse(booking['grand_total']),
        );

        result[paymentType] = ordersTotal + bookingsTotal;
      }
    } catch (e) {
      showCustomSnackbar('Error', 'Failed to fetch totals by payment type', Colors.orange);
    }

    return result;
  }




}