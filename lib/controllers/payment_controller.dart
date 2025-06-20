import 'package:booking_app/services/tyro_payment_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaymentController extends GetxController {
  final RxBool isProcessing = false.obs;
  final RxString paymentStatus = ''.obs;
  final RxString paymentError = ''.obs;

  Future<void> processPayment({
    required BuildContext context,
    required double amount,
    required String reference,
    required String apiKey,
    required String merchantId,
    required String terminalId,
    required String integrationKey,
  }) async {
    try {
      isProcessing.value = true;
      paymentStatus.value = 'Processing payment...';
      paymentError.value = '';

      final result = await TyroPaymentService.processPayment(
        context: context,
        amount: amount,
        reference: reference,
        apiKey: apiKey,
        merchantId: merchantId,
        terminalId: terminalId,
        integrationKey: integrationKey,
      );

      if (result['status'] == 'success') {
        paymentStatus.value = 'Payment successful';
        // Handle successful payment logic
        await _savePaymentToDatabase(
          amount: amount,
          reference: reference,
          details: result,
        );
      } else {
        paymentStatus.value = 'Payment failed';
        paymentError.value = result['message'] ?? 'Unknown error';
        throw Exception(paymentError.value);
      }
    } catch (e) {
      paymentStatus.value = 'Payment error';
      paymentError.value = e.toString();
      rethrow;
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> _savePaymentToDatabase({
    required double amount,
    required String reference,
    required Map<String, dynamic> details,
  }) async {
    // Implement your database saving logic here
    // Example:
    // await FirebaseFirestore.instance.collection('payments').add({
    //   'amount': amount,
    //   'reference': reference,
    //   'status': 'completed',
    //   'timestamp': FieldValue.serverTimestamp(),
    //   'details': details,
    // });
  }
}