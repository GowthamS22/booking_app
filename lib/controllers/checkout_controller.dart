import 'dart:convert';

import 'package:booking_app/app/getx_binding.dart';
import 'package:booking_app/controllers/auth_controller.dart';
import 'package:booking_app/controllers/cart_controller.dart';
import 'package:booking_app/controllers/payment_controller.dart';
import 'package:booking_app/models/booking_with_all.dart';
import 'package:booking_app/models/order.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../config/constants.dart';
import '../config/palette.dart';
import '../models/booking_model.dart';
import '../models/user.dart';
import '../screens/service/tyro_screen.dart';
import 'customer_controller.dart';
import 'new_booking_controller.dart';
import 'default_controller.dart';

class CheckoutController extends GetxController {
  final supabase = Supabase.instance.client;
  RxBool isLoading = false.obs;
  RxBool checkoutPayBtn = false.obs;
  RxBool isProcessingPayment = false.obs;
  RxString paymentStatus = ''.obs;

  RxDouble discount = RxDouble(0.0);

  Rx<User> userData = User().obs;

  final NewBookingController newBookingController = Get.find();
  //final DefaultController defaultController = Get.find();
  final CustomerController customerController = Get.put(CustomerController());
  final PaymentController paymentController   = Get.put(PaymentController());
  final CartController cartController   = Get.put(CartController());
  final AuthController authController = Get.find<AuthController>();

  late TyroService tyroService;

  static const String _prefsCartKey = 'shopping_cart';
  static const String _prefsOrderNotesKey = 'order_notes';
  static const String _prefsOrderIdKey = 'order_id';

  @override
  void onInit() async {
    super.onInit();
  }

  void _printAlignedText(NetworkPrinter printer, String leftText, String rightText) {
    final totalWidth = 42;
    final leftWidth  = leftText.length;
    final rightWidth = rightText.length;
    final spaceWidth = totalWidth - leftWidth - rightWidth;

    final alignedText = '$leftText${' ' * spaceWidth}$rightText';
    printer.text(alignedText);
  }
  
  Future<void> _migratePrintersIfNeeded(SharedPreferences prefs) async {
    try {
      // Check if paired_printers already exists
      final pairedPrintersJson = prefs.getString('paired_printers');
      if (pairedPrintersJson != null && pairedPrintersJson.isNotEmpty) {
        return; // Already migrated
      }
      
      // Try to get printers from storeDetails
      final storeDetailsJson = prefs.getString('storeDetails');
      if (storeDetailsJson == null || storeDetailsJson.isEmpty) {
        return;
      }
      
      final storeDetails = jsonDecode(storeDetailsJson);
      if (storeDetails['printer'] != null && storeDetails['printer'] is List) {
        final List<dynamic> printers = storeDetails['printer'];
        if (printers.isNotEmpty) {
          // Migrate printers to paired_printers
          final List<Map<String, dynamic>> simplePrinters = printers.map((printer) {
            return {
              'name': printer['name'] ?? 'Unknown Printer',
              'ip': printer['ip'] ?? '',
              'port': printer['port'] ?? '9100',
            };
          }).toList();
          
          await prefs.setString('paired_printers', jsonEncode(simplePrinters));
          print('Successfully migrated ${simplePrinters.length} printers from storeDetails to paired_printers');
        }
      }
    } catch (e) {
      print('Error migrating printers: $e');
    }
  }

  void _printFormattedItemRow(NetworkPrinter printer, String name, String qty, String price, String total) {
    const firstLineChars = 20; // Number of characters to show on first line

    if (name.length <= firstLineChars) {
      // Single line if name is short
      printer.text('$name $qty $price $total');
    } else {
      // First line: first 15 chars + quantity + price + total
      final firstPart = name.substring(0, firstLineChars);
      printer.text('$firstPart $qty $price $total');

      // Second line: remaining characters
      final remainingPart = name.substring(firstLineChars);
      printer.text(remainingPart);
    }
  }

  Future<void> registerUser({
    String? email,
    String? firstName,
    String? lastName,
    String? address,
    String? mobile,
    String? postcode,
    String? password,
    String? aboutus,
    String? membershipId,
    BuildContext? context,
  }) async {

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug = preferences.getString('centerSlug');
    isLoading.value = true;

    try {
      final Map<String, dynamic> customerData = {
        'first_name': firstName,
        'mobile': mobile,
        'status': true,
      };
      
      // Only add membershipplan_id if membershipId is not null and not empty
      if (membershipId != null && membershipId.isNotEmpty && membershipId != 'null') {
        customerData['membershipplan_id'] = membershipId;
      }
      
      final response = await supabase
              .schema('${centerSlug}_prod_schema')
              .from('customers')
              .insert(customerData)
              .select('*')
              .single();
              
      if (response['id'] != null) {
        userData.value.id = response['id'];
        print('✅ User registered successfully with ID: ${response['id']}');
        showCustomSnackbar(
          'Success',
          'User registered successfully',
          Colors.green,
        );
      }
    } catch (e) {
      print('❌ Error registering user: $e');
      showCustomSnackbar('Error', e.toString(), Colors.red);
      rethrow; // Re-throw to allow calling code to handle the error
    } finally {
      isLoading.value = false;
    }
  }

  //On click Pay now
  Future<void> processFinalCheckout({
    String? userId,
    String? name,
    String? mobile,
    String? email,
    String? notes,
    String? promoCode,
    String? paymentType,
    double? paid,
    double? balance,
    String? bookingId,
    bool? isMembershipApplied,
    String? membershipId,
    bool? printReceipt,
    String? orderId,
  }) async {

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug = preferences.getString('centerSlug');
    // final cartJson     = preferences.getString('shopping_cart');
    // final orderNotes   = preferences.getString('order_notes');
    // final orderId      = preferences.getString('order_id');

    try {
      final validation = await bulkValidateSlots(selectedBSlots: newBookingController.cartItems,);
      if (!validation) {
        showCustomSnackbar(
          'Failed',
          'Some bookings are not Available',
          const Color.fromARGB(255, 96, 69, 67),
        );
        checkoutPayBtn.value = false;
        isLoading.value = false;
        update();
        return;
      }

      // Store membership details for processing after payment success
      Map<String, dynamic>? membershipDetails;
      if (isMembershipApplied == true && membershipId != null && membershipId!.isNotEmpty && membershipId != 'null' && userId != null) {
        print('Preparing membership for user: $userId with membership: $membershipId');
        
        final planDetails = await supabase
            .schema('${centerSlug}_prod_schema')
            .from('membershipplan')
            .select('*')
            .eq('id', membershipId)
            .single();

        membershipDetails = {
          'membershipId': membershipId,
          'userId': userId,
          'paymentType': paymentType,
          'paid': paid,
          'planDetails': planDetails,
        };
      }

      final bookingNumber = await getNextBookingNumber();

      // Insert Booking
      final bookingResponse = await supabase
              .schema('${centerSlug}_prod_schema')
              .from('bookings')
              .insert({
                'booking_no': 'BCK-2025-${bookingNumber}',
                'customer_id': userId,
                'sub_total': subTotal.toDouble(),
                'surcharge': 0.0,
                'grand_total': grandtotalPrice.toDouble(),
                'notes': notes,
                'discount': discount.value.toDouble(),
                'gst': gstPrice.toDouble(),
                'total': grandtotalPrice.toDouble(),
                'payment_type': paymentType,
                'payment_status': (grandtotalPrice <= paid!) ? 'Paid' : 'Partially',
                'status': 'Booked',
                'created_by': authController.userId.toString(),
                'updated_by': authController.userId.toString(),
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .select()
              .single();

      final bookingInserted = bookingResponse['id'];

      // Insert Payment
      final paymentResponse = await supabase
              .schema('${centerSlug}_prod_schema')
              .from('booking_payments')
              .insert({
                'booking_id': bookingInserted,
                'customer_id': userId,
                'total': grandtotalPrice.toDouble(),
                'paid_amount': paid,
                'payment_type': paymentType,
                'payment_via': 'APP',
                'payment_response': '',
                'status': true,
                'notes': notes,
                'created_by': authController.userId.toString(),
                'updated_by': authController.userId.toString(),
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .select()
              .single();

      final paymentInserted = paymentResponse['id'];
      try {
        // Insert booking slots and payments in a loop
        for (var slot in newBookingController.cartItems) {
          final bookingSlotsresponse =  await supabase
                  .schema('${centerSlug}_prod_schema')
                  .from('booking_slots')
                  .insert({
                    'booking_id': bookingInserted,
                    'service_id': slot.serviceId,
                    'court_id': slot.courtId,
                    'start_time': slot.startTime!.toIso8601String(),
                    'end_time': slot.endTime!.toIso8601String(),
                    'price': slot.price,
                    'slot_type': slot.slotType,
                    'repeat_days': slot.repeatDays.toString(),
                    'repeat_end_date': slot.repeatEnd?.toIso8601String(),
                    'repeat_id': slot.repeatId,
                    'repeat_group_id': slot.repeatGroupId,
                    'status': 'Booked',
                    'created_by': authController.userId.toString(),
                    'updated_by': authController.userId.toString(),
                    'created_at': DateTime.now().toIso8601String(),
                    'updated_at': DateTime.now().toIso8601String(),
                  })
                  .select();

          if (bookingSlotsresponse == null || bookingSlotsresponse.isEmpty) {
            print('❌ Insert failed or no data returned for booking_slots.');
            continue;
          }

          final bookingSlotsInserted = bookingSlotsresponse[0]['id'];
          print('✅ booking_slots inserted with ID: $bookingSlotsInserted');

          await supabase
              .schema('${centerSlug}_prod_schema')
              .from('booking_slots_payments')
              .insert({
                'booking_payments_id': paymentInserted,
                'booking_slots_id': bookingSlotsInserted,
                'booking_id': bookingInserted,
                'customer_id': userId,
                'payment_type': paymentType,
                'payment_via': 'APP',
                'payment_response': '',
                'total': slot.price,
                'paid_amount': slot.price,
                'status': 'paid',
                'created_by': authController.userId.toString(),
                'updated_by': authController.userId.toString(),
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .select();

          print(
            '✅ booking_slots_payments inserted for slot $bookingSlotsInserted',
          );
        }
      } catch (e) {
        print('❌ Exception during insert: $e');
      }

      // Process membership AFTER successful booking and payment creation
      if (membershipDetails != null) {
        try {
          print('Processing membership after successful booking creation...');
          
          // Determine if this is a "Pay Later" booking
          final isPayLaterBooking = (grandtotalPrice > paid!);
          
          await _processMembershipAfterBooking(
            membershipDetails: membershipDetails,
            isPayLaterBooking: isPayLaterBooking,
            centerSlug: centerSlug,
          );
          
          print('✅ Membership processed successfully');
        } catch (e) {
          print('❌ Error processing membership: $e');
          // Don't fail the entire booking for membership errors
          showCustomSnackbar('Warning', 'Booking created but membership processing failed', Colors.orange);
        }
      }

      if(printReceipt==true) {
        await printBookingReceipt(bookingId: bookingResponse['id']);
      }

      if(orderId!=null && orderId!='') {
        await mergeBookingtoOrder(
          order_id: orderId,
          customer_id: userId,
          booking_id: bookingResponse['id'],
          redirect: false
        );
      }

      newBookingController.cartItems.clear();
      newBookingController.clearSelectedSlots();
      
      // Reset all booking controller states - but don't clear text controllers
      // as they might be disposed
      newBookingController.selectedService.value = '';
      newBookingController.selectedServiceId.value = '';
      newBookingController.isLoading.value = false;
      newBookingController.checkout.value = false;
      newBookingController.confirmBtn.value = false;
      newBookingController.courtChangeBtn.value = false;
      newBookingController.cancelBookingbtn.value = false;
      newBookingController.selectedCourtSlots.clear();
      newBookingController.selectedCourt.value = null;
      newBookingController.update();

      showBookingSuccessAlert();

      isLoading.value = false;
      checkoutPayBtn.value = false;
      update();
      
      // Reset dashboard tab to Court View (index 0) before navigation
      final defaultController = Get.find<DefaultController>();
      defaultController.tabIndex.value = 0;
      defaultController.dashboardTabController?.index = 0;

      Future.delayed(Duration(seconds: 1), () {
        // Close all screens and go to dashboard
        Get.until((route) => route.isFirst);
        
        // Ensure we're on the dashboard with Court View tab
        final defaultController = Get.find<DefaultController>();
        defaultController.tabIndex.value = 0;
        defaultController.dashboardTabController?.animateTo(0);
        
        // Refresh the court view data
        newBookingController.fetchBookedSlots();
      });

    } catch (e) {
      print("e : $e");
      showCustomSnackbar('Failed', e.toString(), Palette.dangerTxt);
    }
  }

  Future<void> makeBookingPayment({
    String? bookingId,
    String? orderId,
    String? userId,
    String? notes,
    String? promoCode,
    String? paymentType,
    double? paid,
    double? balance,
    bool printReceipt = false,
    bool isMembershipApplied = false,
    String? membershipId,
    String? paymentMode, // Added to detect individual court payments
  }) async {
    try {
      // Check if this is an individual court payment
      if (paymentMode == 'individual-court-payment') {
        print('Processing individual court payment');
        await _processIndividualCourtPayment(
          bookingId: bookingId,
          orderId: orderId,
          userId: userId,
          notes: notes,
          promoCode: promoCode,
          paymentType: paymentType,
          paid: paid,
          balance: balance,
          printReceipt: printReceipt,
          isMembershipApplied: isMembershipApplied,
          membershipId: membershipId,
        );
        return;
      }
      
      // Continue with regular booking payment logic

      final SharedPreferences preferences = await SharedPreferences.getInstance();
      String? centerSlug = preferences.getString('centerSlug');

      // Store membership details for processing after successful payment
      Map<String, dynamic>? membershipDetails;
      if (isMembershipApplied == true && membershipId != null && membershipId.isNotEmpty && membershipId != 'null' && userId != null) {
        final planDetails = await supabase
            .schema('${centerSlug}_prod_schema')
            .from('membershipplan')
            .select('*')
            .eq('id', membershipId)
            .single();

        membershipDetails = {
          'membershipId': membershipId,
          'userId': userId,
          'paymentType': paymentType,
          'paid': paid,
          'planDetails': planDetails,
        };
      }

      // Insert Payment
      final paymentResponse = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('booking_payments')
          .insert({
            'booking_id': bookingId,
            'customer_id': userId,
            'total': grandtotalPrice,
            'paid_amount': paid,
            'payment_type': paymentType,
            'payment_via': 'APP',
            'payment_response': '',
            'status': true,
            'notes': notes,
            'created_by': authController.userId.toString(),
            'updated_by': authController.userId.toString(),
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final paymentInserted = paymentResponse['id'];

      try {

        final bookingSlotsResponse = await supabase
            .schema('${centerSlug}_prod_schema')
            .from('booking_slots')
            .select('*')
            .eq('booking_id', bookingId!);

        // Insert booking slots and payments in a loop
        if (bookingSlotsResponse != null && bookingSlotsResponse.isNotEmpty) {
          for (final slot in bookingSlotsResponse) {
            print('Inserting payment for slot ${slot['id']}');
            //Example data — customize as needed
            final response = await supabase
                .schema('${centerSlug}_prod_schema')
                .from('booking_slots_payments')
                .insert({
                  'booking_payments_id': paymentInserted,
                  'booking_slots_id': slot['id'],
                  'booking_id': bookingId!,
                  'customer_id': userId,
                  'payment_type': paymentType,
                  'payment_via': 'APP',
                  'payment_response': '',
                  'total': slot['price'],
                  'paid_amount': slot['price'],
                  'status': 'paid',
                  'created_by': authController.userId.toString(),
                  'updated_by': authController.userId.toString(),
                  'created_at': DateTime.now().toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                });

            if (response != null) {
              print('Successfully inserted payment for slot ${slot['id']}');
            } else {
              print('Insert returned null for slot ${slot['id']}');
            }
          }
        }

        final bookingUpdate = await supabase
            .schema('${centerSlug}_prod_schema')
            .from('bookings')
            .update({
              'notes': notes,
              'payment_type': paymentType,
              'payment_status': 'Paid',
              'status': 'Booked',
              'bcart_items': null,
            })
            .eq('id', bookingId!);

      } catch (e) {
        print('❌ Main error: $e');
      }

      // Process membership AFTER successful payment
      if (membershipDetails != null) {
        try {
          print('Processing membership after successful payment...');
          
          // This is immediate payment (not Pay Later)
          await _processMembershipAfterBooking(
            membershipDetails: membershipDetails,
            isPayLaterBooking: false, // Always immediate payment in makeBookingPayment
            centerSlug: centerSlug,
          );
          
          print('✅ Membership processed successfully after payment');
        } catch (e) {
          print('❌ Error processing membership after payment: $e');
          // Don't fail the entire payment for membership errors
          showCustomSnackbar('Warning', 'Payment successful but membership processing failed', Colors.orange);
        }
      } else {
        // Check if there's a pending membership for this customer that needs to be activated
        try {
          await activatePendingMembership(customerId: userId!);
        } catch (e) {
          print('❌ Error activating pending membership: $e');
          // Don't fail the payment for membership activation errors
        }
      }

      if(printReceipt==true) {
        await printBookingReceipt(bookingId: bookingId!);
      }

      newBookingController.cartItems.clear();
      newBookingController.clearSelectedSlots();
      
      // Set flag to indicate booking completed
      newBookingController.bookingJustCompleted.value = true;
      
      // Refresh booked slots to show the new booking
      await newBookingController.fetchBookedSlots();

      showBookingSuccessAlert();

      isLoading.value = false;
      update();

      Future.delayed(Duration(seconds: 1), () {
        final defaultController = Get.find<DefaultController>();
        defaultController.tabIndex.value = 0; // Reset to Dashboard
        defaultController.dashboardTabController?.index = 0;
        Get.offAllNamed('/');
      },);

    } catch (e) {
      showCustomSnackbar('Failed', '${e.toString()}', Palette.dangerTxt);
      rethrow;
    }
  }

  Future<void> processMembershipPayment({
    String? userId,
    String? notes,
    String? paymentType,
    double? total,
    double? paid,
    double? balance,
    bool? isMembershipApplied,
    String? membershipId,
  }) async {

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug = preferences.getString('centerSlug');

    try {
        if (isMembershipApplied == true && membershipId != null && membershipId!.isNotEmpty && membershipId != 'null' && userId != null) {
          print('Processing membership payment for user: $userId with membership: $membershipId');
          
          final planDetails = await supabase
              .schema('${centerSlug}_prod_schema')
              .from('membershipplan')
              .select('*')
              .eq('id', membershipId)
              .single();

          final membershipPayment = await supabase
              .schema('${centerSlug}_prod_schema')
              .from('membershippayment')
              .insert({
                'membershipid': membershipId,
                'customers_id': userId,
                'paymenttype': paymentType,
                'total': total,
                'paidamount': paid,
                'status': true,
                'paymentresponse': '',
                'notes': '',
                'createdby': authController.userId.toString(),
              });

          final membershipData = await supabase
              .schema('${centerSlug}_prod_schema')
              .from('membership_data')
              .insert({
                'membershipplan_id': membershipId,
                'customer_id': userId, // Use userId parameter instead of userData.value.id
                'name': planDetails['name'],
                'price': planDetails['price'],
                'billing_cycle': planDetails['billing_cycle'],
                'description': planDetails['description'],
                'peak_price': planDetails['peak_price'],
                'non_peak_price': planDetails['non_peak_price'],
                'swap_time': planDetails['swap_time'],
                'highlights': planDetails['highlights'],
                'validity': planDetails['validity'],
                'status': false,
              })
              .select('*')
              .single();

          final currentDate = DateTime.now().toIso8601String(); // Gets current date in ISO format

          await supabase
              .schema('${centerSlug}_prod_schema')
              .from('customers')
              .update({
                  'membershipplan_id': membershipId,
                  'membership_data': {
                    'purchased_date': currentDate,
                    'plan_details': planDetails, // Include the plan details if needed
                  },
                  'membership_data_id': membershipData['id']
              })
              .eq('id', userId);
              
          print('Successfully updated membership in processMembershipPayment for customer: $userId');
        }

        isLoading.value = false;
        update();
        showCustomSnackbar('Success', 'Membership Added Successfully', Colors.green);
        Future.delayed(Duration(seconds: 1), () {
        // Close all screens and go to dashboard
        Get.until((route) => route.isFirst);
        
        // Ensure we're on the dashboard with Court View tab
        final defaultController = Get.find<DefaultController>();
        defaultController.tabIndex.value = 0;
        defaultController.dashboardTabController?.animateTo(0);
        
        // Refresh the court view data
        newBookingController.fetchBookedSlots();
      });

    } catch (e) {
      print("e : $e");
      showCustomSnackbar('Failed', e.toString(), Palette.dangerTxt);
    }
  }

  /// Process membership creation after successful booking/payment
  Future<void> _processMembershipAfterBooking({
    required Map<String, dynamic> membershipDetails,
    required bool isPayLaterBooking,
    required String? centerSlug,
  }) async {
    final membershipId = membershipDetails['membershipId'];
    final userId = membershipDetails['userId'];
    final paymentType = membershipDetails['paymentType'];
    final paid = membershipDetails['paid'];
    final planDetails = membershipDetails['planDetails'];

    print('Creating membership payment record...');
    
    // Create membership payment record
    final membershipPayment = await supabase
        .schema('${centerSlug}_prod_schema')
        .from('membershippayment')
        .insert({
          'membershipid': membershipId,
          'customers_id': userId,
          'paymenttype': paymentType,
          'total': planDetails['price'].toDouble(),
          'paidamount': paid,
          'status': isPayLaterBooking ? false : true, // false for Pay Later, true for immediate payment
          'paymentresponse': '',
          'notes': '',
          'createdby': authController.userId.toString(),
        });

    print('Creating membership data record...');
    
    // Create membership data record
    final membershipData = await supabase
        .schema('${centerSlug}_prod_schema')
        .from('membership_data')
        .insert({
          'membershipplan_id': membershipId,
          'customer_id': userId,
          'name': planDetails['name'],
          'price': planDetails['price'],
          'billing_cycle': planDetails['billing_cycle'],
          'description': planDetails['description'],
          'peak_price': planDetails['peak_price'],
          'non_peak_price': planDetails['non_peak_price'],
          'swap_time': planDetails['swap_time'],
          'highlights': planDetails['highlights'],
          'validity': planDetails['validity'],
          'status': isPayLaterBooking ? false : true, // false for Pay Later, true for immediate payment
        })
        .select('*')
        .single();

    print('Updating customer record with membership...');
    
    // Update customer record with membership
    final currentDate = DateTime.now().toIso8601String();
    await supabase
        .schema('${centerSlug}_prod_schema')
        .from('customers')
        .update({
          'membershipplan_id': membershipId,
          'membership_data': {
            'purchased_date': currentDate,
            'plan_details': planDetails,
            'status': isPayLaterBooking ? 'pending' : 'active',
          },
          'membership_data_id': membershipData['id'],
        })
        .eq('id', userId);

    print('✅ Membership processed: ${isPayLaterBooking ? "PENDING (Pay Later)" : "ACTIVE (Paid)"}');
  }

  /// Activate pending membership after Pay Later booking is paid
  Future<void> activatePendingMembership({required String customerId}) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug = preferences.getString('centerSlug');

    if (centerSlug == null) {
      print('❌ centerSlug is null');
      return;
    }

    try {
      print('🔄 Activating pending membership for customer: $customerId');

      // Update membership payment status to paid
      // First try updating with status = false
      await supabase
          .schema('${centerSlug}_prod_schema')
          .from('membershippayment')
          .update({'status': true})
          .eq('customers_id', customerId)
          .eq('status', false);
      
      // Then try updating with status = 'pending'
      await supabase
          .schema('${centerSlug}_prod_schema')
          .from('membershippayment')
          .update({'status': true})
          .eq('customers_id', customerId)
          .eq('status', 'pending');

      // Update membership data status to active
      // First try updating with status = false
      await supabase
          .schema('${centerSlug}_prod_schema')
          .from('membership_data')
          .update({'status': true})
          .eq('customer_id', customerId)
          .eq('status', false);
      
      // Then try updating with status = 'pending'
      await supabase
          .schema('${centerSlug}_prod_schema')
          .from('membership_data')
          .update({'status': true})
          .eq('customer_id', customerId)
          .eq('status', 'pending');

      // Update customer membership status to active
      final customerData = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('customers')
          .select('membership_data')
          .eq('id', customerId)
          .maybeSingle();

      if (customerData != null) {
        final membershipData = customerData['membership_data'] as Map<String, dynamic>?;
        if (membershipData != null && 
            (membershipData['status'] == 'pending' || membershipData['status'] == false)) {
          final updatedMembershipData = Map<String, dynamic>.from(membershipData);
          updatedMembershipData['status'] = 'active';
          
          await supabase
              .schema('${centerSlug}_prod_schema')
              .from('customers')
              .update({'membership_data': updatedMembershipData})
              .eq('id', customerId);
        }
      }

      print('✅ Pending membership activated successfully');
    } catch (e) {
      print('❌ Error activating pending membership: $e');
      throw e;
    }
  }

  /// Clean up pending membership records when user removes membership from checkout
  Future<bool> cleanupPendingMembership({String? customerId}) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug = preferences.getString('centerSlug');

    if (centerSlug == null || customerId == null) {
      print('❌ centerSlug or customerId is null');
      return false;
    }

    try {
      print('🧹 Cleaning up pending membership records for customer: $customerId');
      print('🔍 Using centerSlug: $centerSlug');
      
      // First, let's check ALL membership_data records for this customer
      final allMembershipData = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('membership_data')
          .select('id, status, customer_id, created_at')
          .eq('customer_id', customerId);
          
      print('📊 ALL membership_data records for customer: $allMembershipData');
      
      // Check if there are pending membership_data records
      final pendingMembershipData = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('membership_data')
          .select('id, status')
          .eq('customer_id', customerId)
          .eq('status', false);
          
      print('Found ${pendingMembershipData.length} pending membership_data records: $pendingMembershipData');
      
      if (pendingMembershipData.isNotEmpty) {
        // Delete pending membership data
        final deleteResult = await supabase
            .schema('${centerSlug}_prod_schema')
            .from('membership_data')
            .delete()
            .eq('customer_id', customerId)
            .eq('status', false)
            .select();
            
        print('Deleted membership_data records: $deleteResult');
      } else {
        print('⚠️ No pending membership_data records found to delete');
      }

      // Delete pending membership payments if they exist
      try {
        await supabase
            .schema('${centerSlug}_prod_schema')
            .from('membershippayment')
            .delete()
            .eq('customers_id', customerId)
            .eq('status', false);
        print('Deleted pending membership payments');
      } catch (e) {
        print('No membership payments to delete or error: $e');
      }

      // First check current customer data
      final currentCustomerData = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('customers')
          .select('id, membershipplan_id, membership_data, membership_data_id')
          .eq('id', customerId)
          .maybeSingle();
          
      print('🔍 Current customer data before cleanup: $currentCustomerData');
      
      // Clear membership references from customer record including membership_data column
      final updateResult = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('customers')
          .update({
            'membershipplan_id': null,
            'membership_data': null,  // Clear the membership_data JSON column
            'membership_data_id': null,
          })
          .eq('id', customerId)
          .select();
          
      print('Updated customer record to clear all membership references: $updateResult');

      print('✅ Pending membership records cleaned up');
      return true;
    } catch (e) {
      print('❌ Error cleaning up pending membership: $e');
      return false;
    }
  }

  /// Clean up orphaned membership records from abandoned checkout sessions
  /// This can be called periodically to clean up the database
  Future<void> cleanupOrphanedMemberships() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug = preferences.getString('centerSlug');

    if (centerSlug == null) {
      print('❌ centerSlug is null');
      return;
    }

    try {
      print('🧹 Cleaning up orphaned membership records...');
      
      // Find membership records that are older than 24 hours and still pending
      final twentyFourHoursAgo = DateTime.now().subtract(Duration(hours: 24)).toIso8601String();
      
      // Get orphaned membership payments with status = false
      final orphanedPaymentsFalse = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('membershippayment')
          .select('id, customers_id')
          .eq('status', false)
          .lt('created_at', twentyFourHoursAgo);
      
      // Get orphaned membership payments with status = 'pending'
      final orphanedPaymentsPending = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('membershippayment')
          .select('id, customers_id')
          .eq('status', 'pending')
          .lt('created_at', twentyFourHoursAgo);
      
      // Combine both lists
      final orphanedPayments = [...orphanedPaymentsFalse, ...orphanedPaymentsPending];

      // Get orphaned membership data with status = false
      final orphanedDataFalse = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('membership_data')
          .select('id, customer_id')
          .eq('status', false)
          .lt('created_at', twentyFourHoursAgo);
      
      // Get orphaned membership data with status = 'pending'
      final orphanedDataPending = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('membership_data')
          .select('id, customer_id')
          .eq('status', 'pending')
          .lt('created_at', twentyFourHoursAgo);
      
      // Combine both lists
      final orphanedData = [...orphanedDataFalse, ...orphanedDataPending];

      if (orphanedPayments.isNotEmpty) {
        print('Found ${orphanedPayments.length} orphaned membership payments');
        
        // Delete orphaned payments with status = false
        await supabase
            .schema('${centerSlug}_prod_schema')
            .from('membershippayment')
            .delete()
            .eq('status', false)
            .lt('created_at', twentyFourHoursAgo);
        
        // Delete orphaned payments with status = 'pending'
        await supabase
            .schema('${centerSlug}_prod_schema')
            .from('membershippayment')
            .delete()
            .eq('status', 'pending')
            .lt('created_at', twentyFourHoursAgo);
      }

      if (orphanedData.isNotEmpty) {
        print('Found ${orphanedData.length} orphaned membership data records');
        
        // Delete orphaned data with status = false
        await supabase
            .schema('${centerSlug}_prod_schema')
            .from('membership_data')
            .delete()
            .eq('status', false)
            .lt('created_at', twentyFourHoursAgo);
        
        // Delete orphaned data with status = 'pending'
        await supabase
            .schema('${centerSlug}_prod_schema')
            .from('membership_data')
            .delete()
            .eq('status', 'pending')
            .lt('created_at', twentyFourHoursAgo);
      }

      // Clean up customer records with pending membership status
      final customersWithPendingMembership = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('customers')
          .select('id, membership_data')
          .not('membership_data', 'is', null);

      for (final customer in customersWithPendingMembership) {
        final membershipData = customer['membership_data'] as Map<String, dynamic>?;
        if (membershipData != null && 
            (membershipData['status'] == 'pending' || membershipData['status'] == false)) {
          // Check if the pending membership is old
          final purchaseDate = DateTime.tryParse(membershipData['purchased_date'] ?? '');
          if (purchaseDate != null && purchaseDate.isBefore(DateTime.now().subtract(Duration(hours: 24)))) {
            await supabase
                .schema('${centerSlug}_prod_schema')
                .from('customers')
                .update({
                  'membershipplan_id': null,
                  'membership_data': null,
                  'membership_data_id': null,
                })
                .eq('id', customer['id']);
          }
        }
      }

      print('✅ Orphaned membership records cleaned up');
    } catch (e) {
      print('❌ Error cleaning up orphaned memberships: $e');
    }
  }

  /// Manual cleanup for specific customer (for debugging orphaned records)
  Future<bool> debugCleanupCustomerMembership({String? customerId}) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug = preferences.getString('centerSlug');

    if (centerSlug == null || customerId == null) {
      print('❌ centerSlug or customerId is null');
      return false;
    }

    try {
      print('🔍 Debug: Checking customer membership records for ID: $customerId');
      
      // Check current membership records
      final membershipPayments = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('membershippayment')
          .select('*')
          .eq('customers_id', customerId);
      
      final membershipData = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('membership_data')
          .select('*')
          .eq('customer_id', customerId);
      
      final customerData = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('customers')
          .select('membershipplan_id, membership_data, membership_data_id')
          .eq('id', customerId)
          .maybeSingle();

      print('📊 Found ${membershipPayments.length} membership payments');
      print('📊 Found ${membershipData.length} membership data records');
      print('📊 Customer record: $customerData');
      
      // STEP 1: Clear customer membership fields FIRST (to remove foreign key references)
      if (customerData != null && (customerData['membershipplan_id'] != null || customerData['membership_data'] != null)) {
        print('🔗 Clearing customer foreign key references first...');
        await supabase
            .schema('${centerSlug}_prod_schema')
            .from('customers')
            .update({
              'membershipplan_id': null,
              'membership_data': null,
              'membership_data_id': null,
            })
            .eq('id', customerId);
        print('✅ Cleared customer membership fields');
      }
      
      // STEP 2: Delete membership_data records (now safe from foreign key constraints)
      if (membershipData.isNotEmpty) {
        print('🗑️ Deleting membership data records...');
        await supabase
            .schema('${centerSlug}_prod_schema')
            .from('membership_data')
            .delete()
            .eq('customer_id', customerId);
        print('✅ Deleted ${membershipData.length} membership data records');
      }
      
      // STEP 3: Delete membership payment records
      if (membershipPayments.isNotEmpty) {
        print('🗑️ Deleting membership payment records...');
        await supabase
            .schema('${centerSlug}_prod_schema')
            .from('membershippayment')
            .delete()
            .eq('customers_id', customerId);
        print('✅ Deleted ${membershipPayments.length} membership payments');
      }

      showCustomSnackbar('Success', 'Customer membership records cleaned up', Colors.green);
      return true;
    } catch (e) {
      print('❌ Error cleaning up customer membership: $e');
      showCustomSnackbar('Error', 'Failed to clean up customer membership: $e', Colors.red);
      return false;
    }
  }

  Future<bool> removeMembership({String? membershipId, String? customerId}) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug = preferences.getString('centerSlug');

    if (centerSlug == null || customerId == null) {
      print('❌ centerSlug or customerId is null');
      return false;
    }

    try {
      await supabase
          .schema('${centerSlug}_prod_schema')
          .from('membershippayment')
          .delete()
          .eq('customer_id', customerId)
          .eq('status', true);

      showCustomSnackbar('Success', 'Deleted membership payments', Colors.green);
      return true;
    } catch (e) {
      print('❌ Error deleting membership payment: $e');
      return false;
    }
  }


  double get membershipAmount {
    double val =
        customerController.selectedPlan.length > 0
            ? double.parse(
              customerController.selectedPlan[0]['price'].toString(),
            )
            : 0;
    return val;
  }

  double get totalAmount {
    double val = newBookingController.cartItems.fold(0, (
      double sum,
      BookingSlot bookingSlot,
    ) {
      return sum + (bookingSlot.price ?? 0);
    });
    return val + membershipAmount;
    //     return val + membershipAmount;
  }

  double get gstPrice {
    // For GST inclusive prices, GST = (Total - Discount) / 11
    // This assumes 10% GST rate (10/110 = 1/11)
    var discountedTotal = totalAmount - discount.value;
    return discountedTotal / 11;
  }

  double get totalPrice {
    return totalAmount - discount.value;
  }

  double get grandtotalPrice {
    // Since prices are GST inclusive, grand total is just total minus discount
    return totalAmount - discount.value;
  }

  double get subTotal {
    // Subtotal should be the GST exclusive amount
    return totalAmount - (totalAmount / 11);
  }

  Future<void> printBookingReceiptWithCart({
    required String bookingId,
    List<dynamic>? cartItems,
  }) async {
    // Call the original method and pass cart items
    return printBookingReceipt(bookingId: bookingId, cartItems: cartItems);
  }

  Future<void> printBookingReceipt({
    required String bookingId,
    List<dynamic>? cartItems,
  }) async {

    SharedPreferences prefs               = await SharedPreferences.getInstance();
    String? centerSlug                    = prefs.getString('centerSlug');
    String? storeDetails                  = prefs.getString('storeDetails');
    final Map<String, dynamic> storeData  = jsonDecode(storeDetails!);
    
    // First, try to migrate printers from storeDetails if needed
    await _migratePrintersIfNeeded(prefs);
    
    // Get printer details from the new format used by settings
    final pairedPrintersJson = prefs.getString('paired_printers');
    if (pairedPrintersJson == null || pairedPrintersJson.isEmpty) {
      print('No paired printers found');
      showCustomSnackbar('Printer Error', 'No printers configured. Please check settings.', Colors.red);
      return;
    }
    
    final List<dynamic> pairedPrinters = jsonDecode(pairedPrintersJson);
    if (pairedPrinters.isEmpty) {
      print('No paired printers found in list');
      showCustomSnackbar('Printer Error', 'No printers configured. Please check settings.', Colors.red);
      return;
    }
    
    // Use the first printer in the list
    final printerConfig = pairedPrinters[0];
    final String printerIp = printerConfig['ip'];
    final int printerPort = int.parse(printerConfig['port']);

    final response = await supabase
        .schema('${centerSlug}_prod_schema')
        .from('bookings')
        .select('*, customers(*, membership_data!membership_data_customer_id_fkey(*)), booking_slots(*, platform_status!booking_slots_court_id_fkey(*, sports(sport_name))), booking_payments(*), booking_slots_payments(*)')
        .eq('id', bookingId)
        .single();

    final booking = BookingWithAll.fromJson(response);

    try {
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(PaperSize.mm80, profile);
      final PosPrintResult res = await printer.connect(printerIp, port: printerPort);
      if (res == PosPrintResult.success) {

        final orderDate = DateFormat('dd/MM/yyyy hh:mm:ss a').format(DateTime.now());

        printer.setStyles(PosStyles(align: PosAlign.center, bold: true));
        printer.text('Tax Invoice / Receipt \n', styles: PosStyles(align: PosAlign.center,width: PosTextSize.size2,height: PosTextSize.size2));
        printer.setStyles(PosStyles(align: PosAlign.center));
        printer.text('${storeData['name']} \n', styles: PosStyles(align: PosAlign.center,width: PosTextSize.size2,height: PosTextSize.size2));
        printer.text('${storeData['address']}', styles: PosStyles(align: PosAlign.center));
        printer.text('PH: ${storeData['mobile']}', styles: PosStyles(align: PosAlign.center));
        printer.text('WEBSITE: ${storeData['website']}', styles: PosStyles(align: PosAlign.center));
        printer.text('ABN: ${storeData['abn']}', styles: PosStyles(align: PosAlign.center));
        printer.text('Booking Date: $orderDate \n', styles: PosStyles(align: PosAlign.center));
        printer.text('Booking No: #${booking.bookingNo}', styles: PosStyles(align: PosAlign.center,width: PosTextSize.size2,height: PosTextSize.size2));
        printer.text('--------------------------------------------');

        //Header for table
        printer.setStyles(PosStyles(align: PosAlign.left, bold: true));
        printer.text('Item                    Qty    Price   Total');
        printer.setStyles(PosStyles(align: PosAlign.left));
        printer.text('--------------------------------------------');

        // Group slots by court and sport, then merge consecutive time slots
        final mergedSlots = _mergeConsecutiveSlots(booking.bookingSlots ?? []);

        // Print each merged slot
        for (var slotGroup in mergedSlots) {
          final firstSlot = slotGroup.first;
          final lastSlot = slotGroup.last;
          final duration = slotGroup.length * 30; // Each slot is 30 minutes
          final totalPrice = slotGroup.fold(0, (sum, slot) => sum + (slot.price ?? 0));

          final itemName = '${firstSlot.platformStatus?.sports?.sportName} - Court ${firstSlot.platformStatus?.platformId}'
              .padRight(20);
          final itemQuantity = '${slotGroup.length}'.padLeft(4); // Number of 30-min slots
          final itemPrice = '\$${(firstSlot.price ?? 0).toStringAsFixed(2)}'.padLeft(7); // Price per 30-min
          final itemTotal = '\$${totalPrice.toStringAsFixed(2)}'.padLeft(8); // Total for all slots

          printer.text('$itemName $itemQuantity $itemPrice $itemTotal');
          _printAlignedTextBooking(
              printer,
              '${DateFormat('hh:mm a').format(firstSlot.startTime!)} - ${DateFormat('hh:mm a').format(lastSlot.endTime!)} (${duration} mins)',
              ''
          );
        }
        
        // Print cart items if they exist
        print('📦 Cart items parameter: ${cartItems?.length ?? 0} items');
        if (cartItems != null && cartItems.isNotEmpty) {
          print('📦 Printing ${cartItems.length} cart items in receipt');
          printer.text(''); // Add spacing
          printer.text('Shop Items', styles: PosStyles(align: PosAlign.left, bold: true));
          printer.text('--------------------------------------------');
          
          for (var item in cartItems) {
            print('Processing cart item: ${item.runtimeType}');
            // Handle different types of cart items (could be Map or CartItem object)
            String itemName = '';
            int quantity = 1;
            double price = 0.0;
            
            if (item is Map) {
              print('  Item is Map: $item');
              itemName = item['product']?['name'] ?? 'Unknown Item';
              quantity = item['quantity'] ?? 1;
              price = double.tryParse(item['product']?['price']?.toString() ?? '0') ?? 0.0;
              print('  Parsed from Map - Name: $itemName, Qty: $quantity, Price: $price');
            } else {
              // Assuming it's a CartItem object
              try {
                print('  Item is CartItem object');
                itemName = item.product.name;
                quantity = item.quantity;
                price = double.parse(item.product.price);
                print('  Parsed from CartItem - Name: $itemName, Qty: $quantity, Price: $price');
              } catch (e) {
                print('Error parsing cart item: $e');
                continue;
              }
            }
            
            final shopItemName = itemName.padRight(20);
            final shopItemQuantity = quantity.toString().padLeft(4);
            final shopItemPrice = '\$${price.toStringAsFixed(2)}'.padLeft(7);
            final shopItemTotal = '\$${(price * quantity).toStringAsFixed(2)}'.padLeft(8);
            
            printer.text('$shopItemName $shopItemQuantity $shopItemPrice $shopItemTotal');
          }
        }
        
        // Check if there's a membership payment with this booking
        bool hasMembershipPayment = false;
        double membershipAmount = 0.0;
        String membershipName = '';
        
        // First check if membership payment was processed with this booking
        try {
          final membershipPaymentResponse = await supabase
              .schema('${centerSlug}_prod_schema')
              .from('membershippayment')
              .select('*')
              .eq('notes', 'Membership payment processed with booking $bookingId')
              .maybeSingle();
              
          if (membershipPaymentResponse != null && membershipPaymentResponse['membershipid'] != null) {
            // Get membership_data using the membershipid
            try {
              final membershipDataResponse = await supabase
                  .schema('${centerSlug}_prod_schema')
                  .from('membership_data')
                  .select('*')
                  .eq('id', membershipPaymentResponse['membershipid'])
                  .maybeSingle();
                  
              if (membershipDataResponse != null) {
                hasMembershipPayment = true;
                membershipAmount = double.tryParse(membershipDataResponse['price']?.toString() ?? '0') ?? 0.0;
                membershipName = membershipDataResponse['name'] ?? 'Membership';
                
                // Print membership line item
                final membershipItemName = membershipName.padRight(20);
                final membershipQuantity = '1'.padLeft(4);
                final membershipPrice = '\$${membershipAmount.toStringAsFixed(2)}'.padLeft(7);
                final membershipTotal = '\$${membershipAmount.toStringAsFixed(2)}'.padLeft(8);
                
                printer.text('$membershipItemName $membershipQuantity $membershipPrice $membershipTotal');
                printer.text('Membership payment', styles: PosStyles(align: PosAlign.left));
              }
            } catch (e) {
              print('Could not get membership data: $e');
            }
          }
        } catch (e) {
          print('Could not check membership payment: $e');
        }

        printer.text('--------------------------------------------');

        // Calculate cart items total
        double cartItemsTotal = 0.0;
        if (cartItems != null && cartItems.isNotEmpty) {
          for (var item in cartItems) {
            if (item is Map) {
              int quantity = item['quantity'] ?? 1;
              double price = double.tryParse(item['product']?['price']?.toString() ?? '0') ?? 0.0;
              cartItemsTotal += price * quantity;
            } else {
              try {
                cartItemsTotal += double.parse(item.product.price) * item.quantity;
              } catch (e) {
                print('Error calculating cart item total: $e');
              }
            }
          }
        }

        // Calculate GST correctly for receipt (GST inclusive pricing)
        final totalWithMembership = (booking.grandTotal ?? 0) + membershipAmount + cartItemsTotal;
        final correctGST = totalWithMembership / 11;
        final subTotal = totalWithMembership - correctGST;
        
        _printAlignedText(printer, 'Sub-Total:', '\$${subTotal.toStringAsFixed(2)}');
        _printAlignedText(printer, 'GST Incl.:', '\$${correctGST.toStringAsFixed(2)}');
        _printAlignedText(printer, 'Payment Method:', '${booking.paymentType}');
        _printAlignedText(printer, 'Total Amount:', '\$${totalWithMembership.toStringAsFixed(2)}');
        _printAlignedText(printer, 'Paid Amount:', '\$${totalWithMembership.toStringAsFixed(2)}');
        _printAlignedText(printer, 'Balance Amount:', '\$0.00');

        printer.text('--------------------------------------------');
        printer.text('THANK YOU! HAVE A NICE DAY!', styles: PosStyles(align: PosAlign.center));
        printer.cut();
        if(booking.paymentType=='Cash') {
          printer.drawer(pin: PosDrawer.pin2);
        }
        printer.disconnect();

      } else {
        print('Failed to connect to the printer');
      }
    } catch (e) {
      print('Error during printing: $e');
    }

  }

  Future<void> printOrderAndBooking({
    required String order_id,
    required Orders order,
  }) async {

    SharedPreferences prefs               = await SharedPreferences.getInstance();
    String? centerSlug                    = prefs.getString('centerSlug');
    String? storeDetails                  = prefs.getString('storeDetails');
    final Map<String, dynamic> storeData  = jsonDecode(storeDetails!);
    
    // First, try to migrate printers from storeDetails if needed
    await _migratePrintersIfNeeded(prefs);
    
    // Get printer details from the new format used by settings
    final pairedPrintersJson = prefs.getString('paired_printers');
    if (pairedPrintersJson == null || pairedPrintersJson.isEmpty) {
      print('No paired printers found');
      showCustomSnackbar('Printer Error', 'No printers configured. Please check settings.', Colors.red);
      return;
    }
    
    final List<dynamic> pairedPrinters = jsonDecode(pairedPrintersJson);
    if (pairedPrinters.isEmpty) {
      print('No paired printers found in list');
      showCustomSnackbar('Printer Error', 'No printers configured. Please check settings.', Colors.red);
      return;
    }
    
    // Use the first printer in the list
    final printerConfig = pairedPrinters[0];
    final String printerIp = printerConfig['ip'];
    final int printerPort = int.parse(printerConfig['port']);

    final response = await supabase
        .schema('${centerSlug}_prod_schema')
        .from('bookings')
        .select('*, booking_slots(*, platform_status!booking_slots_court_id_fkey(*, sports(sport_name))), booking_payments(*), booking_slots_payments(*)')
        .eq('id', order.bookingId)
        .single();

    final booking = BookingWithAll.fromJson(response);

    try {
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(PaperSize.mm80, profile);
      final PosPrintResult res = await printer.connect(printerIp, port: printerPort);
      if (res == PosPrintResult.success) {

        final orderDate = DateFormat('dd/MM/yyyy hh:mm:ss a').format(DateTime.now());

        printer.setStyles(PosStyles(align: PosAlign.center, bold: true));
        printer.text('Tax Invoice / Receipt \n', styles: PosStyles(align: PosAlign.center,width: PosTextSize.size2,height: PosTextSize.size2));
        printer.setStyles(PosStyles(align: PosAlign.center));
        printer.text('${storeData['name']} \n', styles: PosStyles(align: PosAlign.center,width: PosTextSize.size2,height: PosTextSize.size2));
        printer.text('${storeData['address']}', styles: PosStyles(align: PosAlign.center));
        printer.text('PH: ${storeData['mobile']}', styles: PosStyles(align: PosAlign.center));
        printer.text('WEBSITE: ${storeData['website']}', styles: PosStyles(align: PosAlign.center));
        printer.text('ABN: ${storeData['abn']}', styles: PosStyles(align: PosAlign.center));
        printer.text('Booking Date: $orderDate \n', styles: PosStyles(align: PosAlign.center));
        printer.text('Booking No: #${booking.bookingNo}', styles: PosStyles(align: PosAlign.center,width: PosTextSize.size2,height: PosTextSize.size2));
        printer.text('--------------------------------------------');

        //Header for table
        printer.setStyles(PosStyles(align: PosAlign.left, bold: true));
        printer.text('Item                    Qty    Price   Total');
        printer.setStyles(PosStyles(align: PosAlign.left));
        printer.text('--------------------------------------------');

        // Group slots by court and sport, then merge consecutive time slots
        final mergedSlots = _mergeConsecutiveSlots(booking.bookingSlots ?? []);

        // Print each merged slot
        for (var slotGroup in mergedSlots) {
          final firstSlot = slotGroup.first;
          final lastSlot = slotGroup.last;
          final duration = slotGroup.length * 30; // Each slot is 30 minutes
          final totalPrice = slotGroup.fold(0, (sum, slot) => sum + (slot.price ?? 0));

          final itemName = '${firstSlot.platformStatus?.sports?.sportName} - Court ${firstSlot.platformStatus?.platformId}'
              .padRight(20);
          final itemQuantity = '${slotGroup.length}'.padLeft(4); // Number of 30-min slots
          final itemPrice = '\$${(firstSlot.price ?? 0).toStringAsFixed(2)}'.padLeft(7); // Price per 30-min
          final itemTotal = '\$${totalPrice.toStringAsFixed(2)}'.padLeft(8); // Total for all slots

          printer.text('$itemName $itemQuantity $itemPrice $itemTotal');
          _printAlignedTextBooking(
              printer,
              '${DateFormat('hh:mm a').format(firstSlot.startTime!)} - ${DateFormat('hh:mm a').format(lastSlot.endTime!)} (${duration} mins)',
              ''
          );
        }

        //Cart items
        for (var item in order.cartItems!) {
          final itemName      = item.product.name.padRight(20);
          final itemQuantity  = item.quantity.toString().padLeft(4);
          final itemPrice     = ('\$${(double.parse(item.product.price) ?? 0).toStringAsFixed(2)}').padLeft(7);
          final itemTotal     = ('\$${(item.appliedPrice ?? 0).toStringAsFixed(2)}').padLeft(8);

          //printer.text('$itemName $itemQuantity $itemPrice $itemTotal');
          _printFormattedItemRow(printer, itemName, itemQuantity, itemPrice, itemTotal);
        }

        printer.text('--------------------------------------------');

        double? discount   = order.billDetails?.discount;
        double? grandtotal = (booking.grandTotal ?? 0) + (order.billDetails?.billAmount ?? 0);
        double? paidamount = (order.billDetails?.paidAmount ?? 0);
        double? balance    = 0 + (order.billDetails?.balanceAmount ?? 0);
        double? surcharge  = (booking.surcharge ?? 0) + (order.billDetails?.surcharge ?? 0);
        
        // Calculate GST correctly for combined receipt (GST inclusive pricing)
        final bookingGST = (booking.grandTotal ?? 0) / 11;
        final orderGST = (order.billDetails?.billAmount ?? 0) / 11;
        final totalGST = bookingGST + orderGST;
        
        final bookingSubTotal = (booking.grandTotal ?? 0) - bookingGST;
        final orderSubTotal = (order.billDetails?.billAmount ?? 0) - orderGST;
        final totalSubTotal = bookingSubTotal + orderSubTotal;

        if ((order.billDetails?.discount ?? 0) > 0) {
          _printAlignedText(printer, 'Discount:', '\$${(discount ?? 0).toStringAsFixed(2)}');
        }
        _printAlignedText(printer, 'Sub-Total:', '\$${totalSubTotal.toStringAsFixed(2)}');
        _printAlignedText(printer, 'GST Incl.:', '\$${totalGST.toStringAsFixed(2)}');
        if ((order.billDetails?.surcharge ?? 0) > 0) {
          _printAlignedText(printer, 'Surcharge:', '\$${(surcharge ?? 0).toStringAsFixed(2)}');
        }
        _printAlignedText(printer, 'Payment Method:', '${booking.paymentType}');
        _printAlignedText(printer, 'Total Amount:', '\$${(grandtotal ?? 0).toStringAsFixed(2)}');
        _printAlignedText(printer, 'Paid Amount:', '\$${(paidamount ?? 0).toStringAsFixed(2)}');
        _printAlignedText(printer, 'Balance Amount:', '\$${(balance ?? 0).abs().toStringAsFixed(2)}');

        printer.text('--------------------------------------------');
        printer.text('THANK YOU! HAVE A NICE DAY!', styles: PosStyles(align: PosAlign.center));
        printer.cut();
        if(booking.paymentType=='Cash') {
          printer.drawer(pin: PosDrawer.pin2);
        }
        printer.disconnect();

      } else {
        print('Failed to connect to the printer');
      }
    } catch (e) {
      print('Error during printing: $e');
    }

  }

  Future<int> getNextBookingNumber() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug                  = preferences.getString('centerSlug');
    final response = await supabase
        .schema('${centerSlug}_prod_schema')
        .rpc('increment_booking_counter')
        .select()
        .single();
    return response['current_token'] as int;
  }

  // Helper function to merge consecutive time slots for the same court and sport
  List<List<BookingSlotNew>> _mergeConsecutiveSlots(List<BookingSlotNew> slots) {
    if (slots.isEmpty) return [];

    // First group by courtId
    final Map<String, List<BookingSlotNew>> slotsByCourt = {};
    for (final slot in slots) {
      slotsByCourt.putIfAbsent(slot.courtId ?? '', () => []).add(slot);
    }

    List<List<BookingSlotNew>> mergedSlots = [];

    // Process each court's slots separately
    for (final courtSlots in slotsByCourt.values) {
      // Sort slots by start time for this court
      courtSlots.sort((a, b) => a.startTime!.compareTo(b.startTime!));

      List<BookingSlotNew> currentGroup = [courtSlots.first];

      for (int i = 1; i < courtSlots.length; i++) {
        final currentSlot = courtSlots[i];
        final lastInGroup = currentGroup.last;

        // Only merge if consecutive time slots for same court
        if (currentSlot.startTime == lastInGroup.endTime) {
          currentGroup.add(currentSlot);
        } else {
          mergedSlots.add(currentGroup);
          currentGroup = [currentSlot];
        }
      }
      mergedSlots.add(currentGroup);
    }

    return mergedSlots;
  }

  void _printAlignedTextBooking(NetworkPrinter printer, String leftText, String rightText) {
    printer.text(
      '$leftText${' '}$rightText',
      styles: PosStyles(align: PosAlign.left),
    );
  }


  //Product payment section

  Future<PostgrestMap> createTempOrder({
    double? total,
  }) async {
    try {
      final SharedPreferences preferences = await SharedPreferences.getInstance();
      String? centerSlug = preferences.getString('centerSlug');
      final cartJson     = preferences.getString('shopping_cart');
      final orderNotes   = preferences.getString('order_notes');
      final orderId      = preferences.getString('order_id');

      final orderResponse = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('orders')
          .insert({
            'token_number': orderId,
            'order_date': DateFormat('yyyy-MM-dd').format(DateTime.now()), // <-- 'MM' for month, not 'mm'
            'order_type': 'product',
            'cart_items': jsonDecode(cartJson!),
            'total': total,
            'order_status': 'Pending',
            'notes': orderNotes,
          })
          .select()
          .single();

      return orderResponse;

    } catch (e) {
      showCustomSnackbar('Failed', '${e.toString()}', Palette.dangerTxt);
      rethrow; // Optional: Let the caller handle the exception
    }
  }

  Future<void> printProductReceipt({
    required String orderNo,
    required Orders order,
  }) async {

    SharedPreferences prefs               = await SharedPreferences.getInstance();
    String? storeDetails                  = prefs.getString('storeDetails');
    final Map<String, dynamic> storeData  = jsonDecode(storeDetails!);
    
    // First, try to migrate printers from storeDetails if needed
    await _migratePrintersIfNeeded(prefs);
    
    // Get printer details from the new format used by settings
    final pairedPrintersJson = prefs.getString('paired_printers');
    if (pairedPrintersJson == null || pairedPrintersJson.isEmpty) {
      print('No paired printers found');
      showCustomSnackbar('Printer Error', 'No printers configured. Please check settings.', Colors.red);
      return;
    }
    
    final List<dynamic> pairedPrinters = jsonDecode(pairedPrintersJson);
    if (pairedPrinters.isEmpty) {
      print('No paired printers found in list');
      showCustomSnackbar('Printer Error', 'No printers configured. Please check settings.', Colors.red);
      return;
    }
    
    // Use the first printer in the list
    final printerConfig = pairedPrinters[0];
    final String printerIp = printerConfig['ip'];
    final int printerPort = int.parse(printerConfig['port']);

    try {
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(PaperSize.mm80, profile);
      final PosPrintResult res = await printer.connect(printerIp, port: printerPort);
      if (res == PosPrintResult.success) {

        final orderDate = DateFormat('dd/MM/yyyy hh:mm:ss a').format(DateTime.now());

        printer.setStyles(PosStyles(align: PosAlign.center, bold: true));
        printer.text('Tax Invoice / Receipt \n', styles: PosStyles(align: PosAlign.center,width: PosTextSize.size2,height: PosTextSize.size2));
        printer.setStyles(PosStyles(align: PosAlign.center));
        printer.text('${storeData['name']} \n', styles: PosStyles(align: PosAlign.center,width: PosTextSize.size2,height: PosTextSize.size2));
        printer.text('${storeData['address']}', styles: PosStyles(align: PosAlign.center));
        printer.text('PH: ${storeData['mobile']}', styles: PosStyles(align: PosAlign.center));
        printer.text('WEBSITE: ${storeData['website']}', styles: PosStyles(align: PosAlign.center));
        printer.text('ABN: ${storeData['abn']}', styles: PosStyles(align: PosAlign.center));
        printer.text('Order Date: $orderDate \n', styles: PosStyles(align: PosAlign.center));
        printer.text('Order ID: #${order.tokenNumber}', styles: PosStyles(align: PosAlign.center,width: PosTextSize.size2,height: PosTextSize.size2));
        printer.text('--------------------------------------------');

        // Header for table
        printer.setStyles(PosStyles(align: PosAlign.left, bold: true));
        printer.text('Item                    Qty    Price   Total');
        printer.setStyles(PosStyles(align: PosAlign.left));
        printer.text('--------------------------------------------');

        // Print each item in table format
        for (var item in order.cartItems!) {
          final itemName      = item.product.name.padRight(20);
          final itemQuantity  = item.quantity.toString().padLeft(4);
          final itemPrice     = ('\$${(double.parse(item.product.price) ?? 0).toStringAsFixed(2)}').padLeft(7);
          final itemTotal     = ('\$${(item.appliedPrice ?? 0).toStringAsFixed(2)}').padLeft(8);

          //printer.text('$itemName $itemQuantity $itemPrice $itemTotal');
          _printFormattedItemRow(printer, itemName, itemQuantity, itemPrice, itemTotal);

          // if (item['options'] != null) {
          //   for (var option in item['options']) {
          //     final optionText  = ' - ${option['name']}';
          //     final optionPrice = option['price'].toStringAsFixed(2);
          //     //printer.text('$optionText $optionPrice');
          //     _printAlignedText(printer, optionText, '\$${optionPrice}');
          //   }
          // }
          //
          // if (item['discount'] != null && item['discount'] > 0) {
          //   final itemDiscount = (item['price'] + (item['options']?.fold(0.0, (prev, opt) => prev + opt['price']) ?? 0.0) - item['appliedPrice']).toStringAsFixed(2);
          //   //printer.text(' - Discount ${item['discount']}% $itemDiscount');
          //   _printAlignedText(printer, ' - Discount ${item['discount']}%', '\$${itemDiscount}');
          // }
        }

        printer.text('--------------------------------------------');

        // Calculate GST correctly for products receipt (GST inclusive pricing)
        final productGST = (order.billDetails?.billAmount ?? 0) / 11;
        final productSubTotal = (order.billDetails?.billAmount ?? 0) - productGST;
        
        if ((order.billDetails?.discount ?? 0) > 0) {
          _printAlignedText(printer, 'Discount:', '\$${(order.billDetails?.discount ?? 0).toStringAsFixed(2)}');
        }
        _printAlignedText(printer, 'Sub-Total:', '\$${productSubTotal.toStringAsFixed(2)}');
        _printAlignedText(printer, 'GST Incl.:', '\$${productGST.toStringAsFixed(2)}');
        if ((order.billDetails?.surcharge ?? 0) > 0) {
          _printAlignedText(printer, 'Surcharge:', '\$${(order.billDetails?.surcharge ?? 0).toStringAsFixed(2)}');
        }
        _printAlignedText(printer, 'Payment Method:', '${order.billDetails?.paymentType}');
        _printAlignedText(printer, 'Total Amount:', '\$${(order.billDetails?.billAmount ?? 0).toStringAsFixed(2)}');
        _printAlignedText(printer, 'Paid Amount:', '\$${(order.billDetails?.paidAmount ?? 0).toStringAsFixed(2)}');
        _printAlignedText(printer, 'Balance Amount:', '\$${(order.billDetails?.balanceAmount ?? 0).abs().toStringAsFixed(2)}');

        printer.text('--------------------------------------------');
        printer.text('THANK YOU! HAVE A NICE DAY!', styles: PosStyles(align: PosAlign.center));
        printer.cut();
        if(order.billDetails?.paymentType=='CASH') {
         printer.drawer(pin: PosDrawer.pin2);
        }
        printer.disconnect();

      } else {
        print('Failed to connect to the printer');
      }
    } catch (e) {
      print('Error during printing: $e');
    }

  }

  Future<void> productsPayment({
    String? order_id,
    double? price,
    double? taxes,
    double? surcharge,
    double? discount,
    double? billAmount,
    double? paidAmount,
    double? balanceAmount,
    String? paymentType,
    String? paymentNotes,
    String? paymentResponse,
    bool? receiptToggle,
    bool? printBoth,
    String? customerId,
  }) async {
    try {

      final SharedPreferences preferences = await SharedPreferences.getInstance();
      String? centerSlug                  = preferences.getString('centerSlug');
      final cartJson                      = preferences.getString('shopping_cart');

      // Get the next token number
      final tokenNumber = await getNextTokenNumber();

      // Convert to 2 decimal places
      double to2(double? value) => value != null ? double.parse(value.toStringAsFixed(2)) : 0.0;

      final Map<String, dynamic> updateData = {
        'token_number': tokenNumber,
        'cart_items': jsonDecode(cartJson!),
        'bill_details': {
          'order_id': order_id!,
          'price': to2(price),
          'taxes': to2(taxes),
          'surcharge': to2(surcharge),
          'discount': to2(discount),
          'billAmount': to2(billAmount),
          'paidAmount': to2(paidAmount),
          'balanceAmount': to2(balanceAmount),
          'paymentType': paymentType,
          'paymentNotes': paymentNotes,
        },
        'transaction_data': paymentResponse,
        'payment_response': paymentResponse,
        'total': to2(billAmount),
        'paid_amount': to2(paidAmount),
        'payment_type': paymentType,
        'payment_via': 'App',
        'order_status': 'Completed',
      };

      // Conditionally add customer_id if not null
      if (customerId != null) {
        updateData['customer_id'] = customerId;
      }

      final response = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('orders')
          .update(updateData)
          .eq('id', order_id!)
          .select('*')
          .single();

      if(receiptToggle==true) {
        if(printBoth==true) {
          await printOrderAndBooking(order_id: order_id, order: Orders.fromJson(response));
        } else {
          // Status Alert
          //showPaymentSuccessAlert();
          await printProductReceipt(orderNo: response['token_number'], order: Orders.fromJson(response));
        }
      } else {
        showPaymentSuccessAlert();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsCartKey);
      await prefs.remove(_prefsOrderNotesKey);
      await prefs.remove(_prefsOrderIdKey);

      // Update the Page
      isLoading.value = false;
      update();

      // Redirect
      Future.delayed(Duration(seconds: 1), () {
        final defaultController = Get.find<DefaultController>();
        defaultController.tabIndex.value = 1; // Reset to Dashboard
        Get.offAllNamed('/');
      });

    } catch (e) {
      showCustomSnackbar('Failed', '${e.toString()}', Palette.dangerTxt);
    }
  }

  Future<void> mergeBookingtoOrder({
    String? order_id,
    String? booking_id,
    String? customer_id,
    bool redirect = true,
  }) async {
    try {
      final SharedPreferences preferences = await SharedPreferences.getInstance();
      String? centerSlug                  = preferences.getString('centerSlug');

      final response = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('orders')
          .update({
            'booking_id': booking_id,
            'customer_id': customer_id,
          })
          .eq('id', order_id!)
          .select()
          .single();

      if(redirect==true) {

        update();
        showCustomSnackbar('Success', 'Order Merged to the Booking', Palette.newColor);
        // Redirect
        Future.delayed(Duration(seconds: 1), () {
          Get.offAllNamed('/');
        });

      }

    } catch (e) {
      showCustomSnackbar('Failed', '${e.toString()}', Palette.dangerTxt);
    }
  }

  Future<void> productsPaymentOnly({
    String? order_id,
    double? price,
    double? taxes,
    double? surcharge,
    double? discount,
    double? billAmount,
    double? paidAmount,
    double? balanceAmount,
    String? paymentType,
    String? paymentNotes,
    String? paymentResponse,
    bool? receiptToggle,
    bool? printBoth,
    String? customerId,
  }) async {
    try {

      final SharedPreferences preferences = await SharedPreferences.getInstance();
      String? centerSlug                  = preferences.getString('centerSlug');
      final cartJson                      = preferences.getString('shopping_cart');

      // Get the next token number
      final tokenNumber = await getNextTokenNumber();

      // Convert to 2 decimal places
      double to2(double? value) => value != null ? double.parse(value.toStringAsFixed(2)) : 0.0;

      final Map<String, dynamic> updateData = {
        'token_number': tokenNumber,
        'cart_items': jsonDecode(cartJson!),
        'bill_details': {
          'order_id': order_id!,
          'price': to2(price),
          'taxes': to2(taxes),
          'surcharge': to2(surcharge),
          'discount': to2(discount),
          'billAmount': to2(billAmount),
          'paidAmount': to2(paidAmount),
          'balanceAmount': to2(balanceAmount),
          'paymentType': paymentType,
          'paymentNotes': paymentNotes,
        },
        'transaction_data': paymentResponse,
        'payment_response': paymentResponse,
        'total': to2(billAmount),
        'paid_amount': to2(paidAmount),
        'payment_type': paymentType,
        'payment_via': 'App',
        'order_status': 'Completed',
      };

      // Conditionally add customer_id if not null
      if (customerId != null) {
        updateData['customer_id'] = customerId;
      }

      final response = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('orders')
          .update(updateData)
          .eq('id', order_id!)
          .select('*')
          .single();

      update();

    } catch (e) {
      showCustomSnackbar('Failed', '${e.toString()}', Palette.dangerTxt);
    }
  }

  Future<int> getNextTokenNumber() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug                  = preferences.getString('centerSlug');
    final response = await supabase
        .schema('${centerSlug}_prod_schema')
        .rpc('increment_token_counter')
        .select()
        .single();
    return response['current_token'] as int;
  }

  //Product payment section

  void showBookingSuccessAlert() {
    Get.dialog(
      Theme(
        data: ThemeData(
          // Set the overlay color of the AlertDialog
          //backgroundColor: Palette.lightGrey,
          hoverColor: MaterialStateColor.resolveWith((states) {
            return Palette
                .lightGrey; // Replace with the desired color and opacity
          }),
        ),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.all(40),
          //title: Center(child: Text('Booking Success',style: TextStyle(color: Palette.primaryColor,fontSize: 40),)),
          content: Container(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/icons/check.png', // Replace this with the path to your image
                  height: 200,
                  width: 200,
                ),
                SizedBox(height: 35),
                Text('Your booking has been successful!', style: TextStyle(fontSize: 30),),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showPaymentSuccessAlert() {
    Get.dialog(
      Theme(
        data: ThemeData(
          hoverColor: MaterialStateColor.resolveWith((states) { return Palette.lightGrey; }),
        ),
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: EdgeInsets.all(40),
          //title: Center(child: Text('Booking Success',style: TextStyle(color: Palette.primaryColor,fontSize: 40),)),
          content: Container(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/icons/check.png', // Replace this with the path to your image
                  height: 200,
                  width: 200,
                ),
                SizedBox(height: 35),
                Text('Payment Success!!', style: TextStyle(fontSize: 30)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _processIndividualCourtPayment({
    String? bookingId,
    String? orderId,
    String? userId,
    String? notes,
    String? promoCode,
    String? paymentType,
    double? paid,
    double? balance,
    bool printReceipt = false,
    bool isMembershipApplied = false,
    String? membershipId,
  }) async {
    try {
      print('💳 Starting individual court payment processing...');
      print('📋 Parameters: bookingId=$bookingId, userId=$userId, paymentType=$paymentType, paid=$paid');
      
      final SharedPreferences preferences = await SharedPreferences.getInstance();
      String? centerSlug = preferences.getString('centerSlug');
      
      if (centerSlug == null || bookingId == null || userId == null) {
        throw Exception('Missing required parameters for individual court payment');
      }

      print('🔍 Getting individual court data for booking: $bookingId');
      // Get the court information that was set up during checkout navigation
      final individualCourtData = await _getIndividualCourtDataFromCheckout(bookingId, centerSlug);
      
      if (individualCourtData == null) {
        throw Exception('Could not find individual court data for payment');
      }
      
      print('✅ Successfully retrieved individual court data');
      print('🏟️ Court slots count: ${(individualCourtData['court_slots'] as List).length}');

      final courtSlots = individualCourtData['court_slots'] as List<dynamic>;
      final bookingData = individualCourtData['booking'];
      
      // Create payment record
      final paymentResponse = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('booking_payments')
          .insert({
            'booking_id': bookingId,
            'customer_id': userId,
            'total': paid ?? 0,
            'paid_amount': paid ?? 0,
            'payment_type': paymentType ?? 'Cash',
            'payment_via': 'APP',
            'payment_response': '',
            'status': true,
            'notes': notes ?? 'Individual court payment',
            'created_by': authController.userId.toString(),
            'updated_by': authController.userId.toString(),
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      print('Payment record created: ${paymentResponse['id']}');

      // Create payment records for individual court slots
      for (final slot in courtSlots) {
        await supabase
            .schema('${centerSlug}_prod_schema')
            .from('booking_slots_payments')
            .insert({
              'booking_payments_id': paymentResponse['id'],
              'booking_slots_id': slot['id'],
              'booking_id': bookingId,
              'customer_id': userId,
              'payment_type': paymentType ?? 'Cash',
              'payment_via': 'APP',
              'payment_response': '',
              'total': slot['price'],
              'paid_amount': slot['price'],
              'status': 'paid',
              'created_by': authController.userId.toString(),
              'updated_by': authController.userId.toString(),
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
      }

      // Check if all slots for this booking are now paid
      final allBookingSlots = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('booking_slots')
          .select('*')
          .eq('booking_id', bookingId);

      final paidSlots = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('booking_slots_payments')
          .select('booking_slots_id')
          .eq('booking_id', bookingId)
          .eq('status', 'paid');

      final paidSlotIds = paidSlots.map((slot) => slot['booking_slots_id']).toSet();
      final allSlotIds = allBookingSlots.map((slot) => slot['id']).toSet();
      
      final allPaid = allSlotIds.every((id) => paidSlotIds.contains(id));
      final anyPaid = paidSlotIds.isNotEmpty;

      // Update booking payment status
      String bookingPaymentStatus;
      if (allPaid) {
        bookingPaymentStatus = 'Paid';
      } else if (anyPaid) {
        bookingPaymentStatus = 'Partially Paid';
      } else {
        bookingPaymentStatus = 'Pending';
      }

      await supabase
          .schema('${centerSlug}_prod_schema')
          .from('bookings')
          .update({
            'payment_status': bookingPaymentStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookingId);

      print('Individual court payment processed successfully');

      // Print receipt if required
      if (printReceipt) {
        await _printIndividualCourtReceipt(
          bookingData: bookingData,
          courtSlots: courtSlots,
          paymentData: paymentResponse,
          centerSlug: centerSlug,
        );
      }

      // Show success message
      Get.snackbar(
        'Success',
        'Individual court payment processed successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Navigate back to dashboard
      Get.offAllNamed('/');
      
    } catch (e) {
      print('Error processing individual court payment: $e');
      Get.snackbar(
        'Error',
        'Failed to process payment: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      throw e;
    }
  }

  Future<Map<String, dynamic>?> _getIndividualCourtDataFromCheckout(String bookingId, String centerSlug) async {
    try {
      print('🔍 _getIndividualCourtDataFromCheckout: bookingId=$bookingId, centerSlug=$centerSlug');
      
      // Get booking data
      print('📋 Fetching booking data...');
      final bookingResponse = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('bookings')
          .select('*, customers(*)')
          .eq('id', bookingId)
          .single();
      
      print('✅ Booking data retrieved successfully');

      // Get all booking slots for this booking (individual court payment will target specific slots)
      print('🏟️ Fetching booking slots...');
      final bookingSlots = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('booking_slots')
          .select('*')
          .eq('booking_id', bookingId);

      print('📊 Found ${bookingSlots.length} booking slots');
      
      if (bookingSlots.isEmpty) {
        print('⚠️ No booking slots found for booking $bookingId');
        return null;
      }

      return {
        'booking': bookingResponse,
        'customer': bookingResponse['customers'],
        'court_slots': bookingSlots,
      };
      
    } catch (e) {
      print('❌ Error getting individual court data: $e');
      print('🔧 Error type: ${e.runtimeType}');
      if (e.toString().contains('404')) {
        print('🚨 404 Error - Resource not found. Check booking ID: $bookingId');
      }
      return null;
    }
  }

  Future<void> _printIndividualCourtReceipt({
    required Map<String, dynamic> bookingData,
    required List<dynamic> courtSlots,
    required Map<String, dynamic> paymentData,
    required String centerSlug,
  }) async {
    try {
      // Calculate totals
      double subtotal = 0;
      for (final slot in courtSlots) {
        subtotal += (slot['price'] as num).toDouble();
      }
      
      double correctGST = subtotal / 11;
      double totalAmount = subtotal;

      // Get store details
      final storeResponse = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('store_details')
          .select()
          .limit(1)
          .single();

      // Format receipt content
      String receiptContent = '''
===========================================
${storeResponse['name'] ?? 'Store Name'}
${storeResponse['address'] ?? 'Store Address'}
${storeResponse['phone'] ?? 'Store Phone'}
===========================================

INDIVIDUAL COURT PAYMENT RECEIPT

Booking No: ${bookingData['booking_no'] ?? 'N/A'}
Customer: ${bookingData['customers']['first_name'] ?? 'N/A'}
Mobile: ${bookingData['customers']['mobile'] ?? 'N/A'}
Date: ${DateTime.now().toString().split(' ')[0]}
Time: ${DateTime.now().toString().split(' ')[1].substring(0, 5)}

-------------------------------------------
COURT DETAILS:
''';

      // Add court slot details
      for (final slot in courtSlots) {
        final startTime = DateTime.parse(slot['start_time']);
        final endTime = DateTime.parse(slot['end_time']);
        
        receiptContent += '''
Court: ${slot['court_name'] ?? 'Court ${slot['court_id']}'}
Time: ${startTime.toString().split(' ')[1].substring(0, 5)} - ${endTime.toString().split(' ')[1].substring(0, 5)}
Price: \$${(slot['price'] as num).toStringAsFixed(2)}
''';
      }

      receiptContent += '''
-------------------------------------------
PAYMENT SUMMARY:
Subtotal: \$${subtotal.toStringAsFixed(2)}
GST: \$${correctGST.toStringAsFixed(2)}
Total: \$${totalAmount.toStringAsFixed(2)}

Payment Method: ${paymentData['payment_type'] ?? 'Cash'}
Amount Paid: \$${(paymentData['amount'] as num).toStringAsFixed(2)}
${paymentData['notes'] != null ? 'Notes: ${paymentData['notes']}' : ''}

-------------------------------------------
Thank you for your payment!
===========================================
''';

      // Print receipt using existing print infrastructure
      await _printUsingPrinter(receiptContent);
      
    } catch (e) {
      print('Error printing individual court receipt: $e');
    }
  }

  Future<bool> bulkValidateSlots({List<BookingSlot>? selectedBSlots}) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug = preferences.getString('centerSlug');
    
    if (centerSlug == null || selectedBSlots == null || selectedBSlots.isEmpty) {
      return false;
    }
    
    try {
      final futures = selectedBSlots.map((item) {
        return supabase
            .schema('${centerSlug}_prod_schema')
            .from('booking_slots')
            .select('id')
            .eq('service_id', item.serviceId!)
            .eq('court_id', item.courtId!)
            .eq('start_time', item.startTime!.toIso8601String())
            .eq('status', 'Booked');
      }).toList();

      final responses = await Future.wait(futures);

      final matchingRowCount = responses.fold<int>(
        0,
        (count, response) => count + (response.isNotEmpty ? response.length : 0),
      );

      return matchingRowCount == 0;
    } catch (e) {
      print('Error validating slots: $e');
      return false;
    }
  }

  Future<void> _printUsingPrinter(String receiptContent) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // First, try to migrate printers from storeDetails if needed
      await _migratePrintersIfNeeded(prefs);
      
      // Get printer details from the new format used by settings
      final pairedPrintersJson = prefs.getString('paired_printers');
      if (pairedPrintersJson == null || pairedPrintersJson.isEmpty) {
        print('No paired printers found');
        showCustomSnackbar('Printer Error', 'No printers configured. Please check settings.', Colors.red);
        return;
      }
      
      final List<dynamic> pairedPrinters = jsonDecode(pairedPrintersJson);
      if (pairedPrinters.isEmpty) {
        print('No paired printers found in list');
        showCustomSnackbar('Printer Error', 'No printers configured. Please check settings.', Colors.red);
        return;
      }
      
      // Use the first printer in the list
      final printerConfig = pairedPrinters[0];
      final String printerIp = printerConfig['ip'];
      final int printerPort = int.parse(printerConfig['port']);

      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(PaperSize.mm80, profile);
      final PosPrintResult res = await printer.connect(printerIp, port: printerPort);
      
      if (res == PosPrintResult.success) {
        // Split content by lines and print each line
        final lines = receiptContent.split('\n');
        for (final line in lines) {
          if (line.trim().isEmpty) {
            printer.feed(1);
          } else if (line.contains('=')) {
            printer.text(line, styles: PosStyles(align: PosAlign.center));
          } else if (line.contains('INDIVIDUAL COURT PAYMENT RECEIPT') || 
                     line.contains('PAYMENT SUMMARY:') || 
                     line.contains('COURT DETAILS:')) {
            printer.text(line, styles: PosStyles(align: PosAlign.center, bold: true));
          } else {
            printer.text(line, styles: PosStyles(align: PosAlign.left));
          }
        }
        
        printer.cut();
        printer.disconnect();
        
        print('Individual court receipt printed successfully');
      } else {
        print('Failed to connect to the printer');
        showCustomSnackbar('Printer Error', 'Failed to connect to printer', Colors.red);
      }
    } catch (e) {
      print('Error during printing: $e');
      showCustomSnackbar('Printer Error', 'Error printing receipt: $e', Colors.red);
    }
  }
}
