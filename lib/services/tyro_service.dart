import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class TyroService {
  final String apiKey;
  final String merchantId;
  final String baseUrl;
  final bool isTestMode;

  TyroService({
    required this.apiKey,
    required this.merchantId,
    this.baseUrl = 'https://api.tyro.com/v1',
    this.isTestMode = false,
  });

  Future<Map<String, dynamic>> initiatePayment({
    required double amount,
    required String reference,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'X-Merchant-Id': merchantId,
        },
        body: jsonEncode({
          'amount': (amount * 100).toInt(), // Convert to cents
          'currency': 'AUD',
          'reference': reference,
          'description': description ?? 'Booking Payment',
          'test': isTestMode,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to initiate payment: ${response.body}');
      }
    } catch (e) {
      debugPrint('Tyro payment error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPaymentStatus(String paymentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payments/$paymentId'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'X-Merchant-Id': merchantId,
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get payment status: ${response.body}');
      }
    } catch (e) {
      debugPrint('Tyro status check error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> refundPayment({
    required String paymentId,
    required double amount,
    String? reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments/$paymentId/refunds'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'X-Merchant-Id': merchantId,
        },
        body: jsonEncode({
          'amount': (amount * 100).toInt(), // Convert to cents
          'reason': reason ?? 'Customer request',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to process refund: ${response.body}');
      }
    } catch (e) {
      debugPrint('Tyro refund error: $e');
      rethrow;
    }
  }
} 