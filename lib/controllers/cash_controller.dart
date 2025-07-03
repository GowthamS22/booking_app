import 'package:booking_app/config/constants.dart';
import 'package:booking_app/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CashController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Loading states
  var isLoadingOpeningBalance = false.obs;
  var isLoadingSalesTotals = false.obs;
  var isClosingCash = false.obs;

  // Get current opening balance
  Future<double> getOpeningBalance() async {
    isLoadingOpeningBalance.value = true;
    try {
      final SharedPreferences preferences = await SharedPreferences.getInstance();
      String? centerSlug = preferences.getString('centerSlug');
      final String schema = '${centerSlug}_prod_schema';
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
    } finally {
      isLoadingOpeningBalance.value = false;
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
    isClosingCash.value = true;
    try {
      final SharedPreferences preferences = await SharedPreferences.getInstance();
      String? centerSlug = preferences.getString('centerSlug');
      final String schema = '${centerSlug}_prod_schema';
      String? userId = preferences.getString('userId');

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
      authController.pin.value = '';
      authController.openCloseId = '';
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to close cash: ${e.toString()}');
      return false;
    } finally {
      isClosingCash.value = false;
    }
  }

  // Get sales totals (cash and EFTPOS)
  Future<Map<String, double>> getTotalsByPaymentType() async {
    isLoadingSalesTotals.value = true;
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
        double membershipTotal = 0.0;

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
            .eq('payment_type', paymentType)
            .eq('payment_status', 'Paid')
            .eq('closed', false);

        final bookings = bookingsResponse as List<dynamic>;
        bookingsTotal = bookings.fold<double>(
          0.0,
              (sum, booking) => sum + safeParse(booking['grand_total']),
        );

        // Membership
        final membershipResponse = await _supabase
            .schema(schema)
            .from('membershippayment')
            .select('total')
            .eq('paymenttype', paymentType)
            .eq('closed', false);

        final memberships = membershipResponse as List<dynamic>;
        membershipTotal = memberships.fold<double>(
          0.0,
              (sum, membership) => sum + safeParse(membership['total']),
        );

        result[paymentType] = ordersTotal + bookingsTotal + membershipTotal;
      }
    } catch (e) {
      showCustomSnackbar('Error', 'Failed to fetch totals by payment type', Colors.orange);
    } finally {
      isLoadingSalesTotals.value = false;
    }

    return result;
  }

  void showCustomSnackbar(String title, String message, Color color) {
    Get.snackbar(
      title,
      message,
      backgroundColor: color,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}