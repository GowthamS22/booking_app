import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io';

class TyroService {
  final String apiKey;
  final String merchantId;
  final String baseUrl;
  final bool isTestMode;

  TyroService({
    this.apiKey = 'd69af83751574e280f3f6738c5a9760f',
    this.merchantId = '1',
    this.isTestMode = true,
  }) : baseUrl = isTestMode 
          ? 'https://api-sandbox.tyro.com/v1'  // Updated to sandbox environment URL
          : 'https://api.tyro.com/v1';      // Production environment URL

  Future<bool> _checkInternetConnection() async {
    try {
      // Try to connect to Tyro's sandbox API instead of google.com
      final result = await InternetAddress.lookup('api-sandbox.tyro.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> initiatePayment({
    required double amount,
    required String reference,
    String? description,
  }) async {
    try {
      // Check internet connection first
      final hasInternet = await _checkInternetConnection();
      if (!hasInternet) {
        throw Exception('No internet connection available. Please check your network settings.');
      }

      final requestBody = {
        'amount': (amount * 100).toInt(), // Convert to cents
        'currency': 'AUD',
        'reference': reference,
        'description': description ?? 'Booking Payment',
        'test': isTestMode,
      };

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'X-Merchant-Id': merchantId,
        'Accept': 'application/json',
      };

      debugPrint('=== Tyro Payment Request ===');
      debugPrint('URL: ${baseUrl}/payments');
      debugPrint('Headers: ${jsonEncode(headers)}');
      debugPrint('Body: ${jsonEncode(requestBody)}');

      // Create HttpClient with custom settings
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 60)
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);

      final request = await client.postUrl(Uri.parse('$baseUrl/payments'));
      headers.forEach((key, value) {
        request.headers.set(key, value);
      });
      request.write(jsonEncode(requestBody));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      debugPrint('=== Tyro Payment Response ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Headers: ${response.headers}');
      debugPrint('Response Body: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(responseBody);
      } else {
        String errorMessage = 'Failed to initiate payment';
        try {
          final errorBody = jsonDecode(responseBody);
          errorMessage += ': ${errorBody['message'] ?? responseBody}';
        } catch (e) {
          errorMessage += ': $responseBody';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('=== Tyro Payment Error ===');
      debugPrint('Error Type: ${e.runtimeType}');
      debugPrint('Error Message: $e');
      if (e is SocketException) {
        debugPrint('Connection Error: ${e.message}');
        throw Exception('Network connection error. Please check your internet connection and try again.');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPaymentStatus(String paymentId) async {
    try {
      // Check internet connection first
      final hasInternet = await _checkInternetConnection();
      if (!hasInternet) {
        throw Exception('No internet connection available. Please check your network settings.');
      }

      final headers = {
        'Authorization': 'Bearer $apiKey',
        'X-Merchant-Id': merchantId,
        'Accept': 'application/json',
      };

      debugPrint('=== Tyro Status Check Request ===');
      debugPrint('URL: ${baseUrl}/payments/$paymentId');
      debugPrint('Headers: ${jsonEncode(headers)}');

      // Create HttpClient with custom settings
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 30)
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);

      final request = await client.getUrl(Uri.parse('$baseUrl/payments/$paymentId'));
      headers.forEach((key, value) {
        request.headers.set(key, value);
      });

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      debugPrint('=== Tyro Status Check Response ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Headers: ${response.headers}');
      debugPrint('Response Body: $responseBody');

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        String errorMessage = 'Failed to get payment status';
        try {
          final errorBody = jsonDecode(responseBody);
          errorMessage += ': ${errorBody['message'] ?? responseBody}';
        } catch (e) {
          errorMessage += ': $responseBody';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('=== Tyro Status Check Error ===');
      debugPrint('Error Type: ${e.runtimeType}');
      debugPrint('Error Message: $e');
      if (e is SocketException) {
        debugPrint('Connection Error: ${e.message}');
        throw Exception('Network connection error. Please check your internet connection and try again.');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> refundPayment({
    required String paymentId,
    required double amount,
    String? reason,
  }) async {
    try {
      // Check internet connection first
      final hasInternet = await _checkInternetConnection();
      if (!hasInternet) {
        throw Exception('No internet connection available. Please check your network settings.');
      }

      final requestBody = {
        'amount': (amount * 100).toInt(), // Convert to cents
        'reason': reason ?? 'Customer request',
      };

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'X-Merchant-Id': merchantId,
        'Accept': 'application/json',
      };

      debugPrint('=== Tyro Refund Request ===');
      debugPrint('URL: ${baseUrl}/payments/$paymentId/refunds');
      debugPrint('Headers: ${jsonEncode(headers)}');
      debugPrint('Body: ${jsonEncode(requestBody)}');

      // Create HttpClient with custom settings
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 30)
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);

      final request = await client.postUrl(Uri.parse('$baseUrl/payments/$paymentId/refunds'));
      headers.forEach((key, value) {
        request.headers.set(key, value);
      });
      request.write(jsonEncode(requestBody));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      debugPrint('=== Tyro Refund Response ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Headers: ${response.headers}');
      debugPrint('Response Body: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(responseBody);
      } else {
        String errorMessage = 'Failed to process refund';
        try {
          final errorBody = jsonDecode(responseBody);
          errorMessage += ': ${errorBody['message'] ?? responseBody}';
        } catch (e) {
          errorMessage += ': $responseBody';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('=== Tyro Refund Error ===');
      debugPrint('Error Type: ${e.runtimeType}');
      debugPrint('Error Message: $e');
      if (e is SocketException) {
        debugPrint('Connection Error: ${e.message}');
        throw Exception('Network connection error. Please check your internet connection and try again.');
      }
      rethrow;
    }
  }
}
