import 'dart:convert';

import 'package:booking_app/app/getx_binding.dart';
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
      final response = await supabase
              .schema('${centerSlug}_prod_schema')
              .from('customers')
              .insert({
                'first_name': firstName,
                'mobile': mobile,
                'status': true,
              })
              .select('*')
              .single();
      if (response['id'] != null) {
        userData.value.id = response['id'];
        showCustomSnackbar(
          'Success',
          'User registered successfully',
          Colors.green,
        );
      }
    } catch (e) {
      showCustomSnackbar('Error', e.toString(), Colors.red);
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

      if (isMembershipApplied == true && membershipId != null && membershipId!.isNotEmpty && userId != null) {
        print('Processing membership update for user: $userId with membership: $membershipId');
        
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
              'total': planDetails['price'].toDouble(),
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
              'customer_id': userData.value.id.toString(),
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
                // Add any other membership data fields you want to include
              },
              'membership_data_id': membershipData['id'],
            })
            .eq('id', userId);
            
        print('Successfully updated membership for customer: $userId');
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
  }) async {
    try {

      final SharedPreferences preferences = await SharedPreferences.getInstance();
      String? centerSlug = preferences.getString('centerSlug');

      if (isMembershipApplied == true && membershipId != null && userId != null) {

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
              'total': planDetails['price'].toDouble(),
              'paidamount': paid,
              'status': true,
              'paymentresponse': '',
              'notes': '',
              'createdby': authController.userId.toString(),
            });

        final membershipData = await supabase
            .schema('${centerSlug}_prod_schema')
            .from('membership_data')
            .update({
              'status': false
            })
            .eq('customer_id', userId)
            .eq('status', true)
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
                // Add any other membership data fields you want to include
              },
              'membership_data_id': membershipData['id']
            })
            .eq('id', userId);
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

      if(printReceipt==true) {
        await printBookingReceipt(bookingId: bookingId!);
      }

      newBookingController.cartItems.clear();
      newBookingController.clearSelectedSlots();

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
        if (isMembershipApplied == true && membershipId != null && membershipId!.isNotEmpty && userId != null) {
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
                'customer_id': userData.value.id.toString(),
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

  Future<void> printBookingReceipt({
    required String bookingId,
  }) async {

    SharedPreferences prefs               = await SharedPreferences.getInstance();
    String? centerSlug                    = prefs.getString('centerSlug');
    String? storeDetails                  = prefs.getString('storeDetails');
    final Map<String, dynamic> storeData  = jsonDecode(storeDetails!);
    
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

        // Header for table
        // printer.setStyles(PosStyles(align: PosAlign.left, bold: true));
        // printer.text('Item                    Qty    Price   Total');
        // printer.setStyles(PosStyles(align: PosAlign.left));
        // printer.text('--------------------------------------------');
        //
        // // Print each item in table format
        // for (var slot in booking.bookingSlots!) {
        //   final itemName      = ('${slot.platformStatus?.sports?.sportName} - Court ${slot.platformStatus?.platformId!}').padRight(20);
        //   final itemQuantity  = ('1').toString().padLeft(4);
        //   final itemPrice     = ('\$${(slot.price ?? 0).toStringAsFixed(2)}').padLeft(7);
        //   final itemTotal     = ('\$${(slot.price ?? 0).toStringAsFixed(2)}').padLeft(8);
        //
        //   printer.text('$itemName $itemQuantity $itemPrice $itemTotal');
        //   _printAlignedText(printer, '${DateFormat('hh:mm a').format(slot.startTime!)} - ${DateFormat('hh:mm a').format(slot.endTime!)}', '');
        //
        //   // if (item['options'] != null) {
        //   //   for (var option in item['options']) {
        //   //     final optionText  = ' - ${option['name']}';
        //   //     final optionPrice = option['price'].toStringAsFixed(2);
        //   //     //printer.text('$optionText $optionPrice');
        //   //     _printAlignedText(printer, optionText, '\$${optionPrice}');
        //   //   }
        //   // }
        //   //
        //   // if (item['discount'] != null && item['discount'] > 0) {
        //   //   final itemDiscount = (item['price'] + (item['options']?.fold(0.0, (prev, opt) => prev + opt['price']) ?? 0.0) - item['appliedPrice']).toStringAsFixed(2);
        //   //   //printer.text(' - Discount ${item['discount']}% $itemDiscount');
        //   //   _printAlignedText(printer, ' - Discount ${item['discount']}%', '\$${itemDiscount}');
        //   // }
        // }

        printer.text('--------------------------------------------');

        // if ((order.billDetails?.discount ?? 0) > 0) {
        //   _printAlignedText(printer, 'Discount:', '\$${(order.billDetails?.discount ?? 0).toStringAsFixed(2)}');
        // }
        _printAlignedText(printer, 'Sub-Total:', '\$${(booking.total ?? 0).toStringAsFixed(2)}');
        _printAlignedText(printer, 'GST Incl.:', '\$${(booking.gst ?? 0).toStringAsFixed(2)}');
        // if ((order.billDetails?.surcharge ?? 0) > 0) {
        //   _printAlignedText(printer, 'Surcharge:', '\$${(order.billDetails?.surcharge ?? 0).toStringAsFixed(2)}');
        // }
        _printAlignedText(printer, 'Payment Method:', '${booking.paymentType}');
        _printAlignedText(printer, 'Total Amount:', '\$${(booking.grandTotal ?? 0).toStringAsFixed(2)}');
        _printAlignedText(printer, 'Paid Amount:', '\$${(booking.grandTotal ?? 0).toStringAsFixed(2)}');
        _printAlignedText(printer, 'Balance Amount:', '\$${(0 ?? 0).abs().toStringAsFixed(2)}');

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
        double? subtotal   = (booking.total ?? 0) + (order.billDetails?.price ?? 0);
        double? gst        = (booking.gst ?? 0) + (order.billDetails?.taxes ?? 0);
        double? surcharge  = (booking.surcharge ?? 0) + (order.billDetails?.surcharge ?? 0);
        double? grandtotal = (booking.grandTotal ?? 0) + (order.billDetails?.billAmount ?? 0);
        double? paidamount = (order.billDetails?.paidAmount ?? 0);
        double? balance    = 0 + (order.billDetails?.balanceAmount ?? 0);


        if ((order.billDetails?.discount ?? 0) > 0) {
          _printAlignedText(printer, 'Discount:', '\$${(discount ?? 0).toStringAsFixed(2)}');
        }
        _printAlignedText(printer, 'Sub-Total:', '\$${(subtotal ?? 0).toStringAsFixed(2)}');
        _printAlignedText(printer, 'GST Incl.:', '\$${(gst ?? 0).toStringAsFixed(2)}');
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

        if ((order.billDetails?.discount ?? 0) > 0) {
          _printAlignedText(printer, 'Discount:', '\$${(order.billDetails?.discount ?? 0).toStringAsFixed(2)}');
        }
        _printAlignedText(printer, 'Sub-Total:', '\$${(order.billDetails?.price ?? 0).toStringAsFixed(2)}');
        _printAlignedText(printer, 'GST Incl.:', '\$${(order.billDetails?.taxes ?? 0).toStringAsFixed(2)}');
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
          showPaymentSuccessAlert();
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

  /*void printBookingReceipt({List<BookingSlot>? bookingSlotItems}) async {

    List<BookingSlot> listItems = [];
    for(var item in bookingSlotItems!) {
      listItems.add(BookingSlot(
          id: item.id,
          userId: item.userId,
          name: item.name,
          mobile: item.mobile,
          bookingId: item.bookingId,
          subBookingId: item.subBookingId,
          date: item.date,
          price: item.price,
          service: item.service,
          serviceId: item.serviceId,
          court: item.court,
          courtId: item.courtId,
          startTime: item.startTime,
          endTime: item.endTime,
          slotType: item.slotType,
          repeatDays: item.repeatDays,
          repeatEnd: item.repeatEnd,
          repeatId: item.repeatId,
          repeatGroupId: item.repeatGroupId,
          paymentStatus: item.paymentStatus,
          status: item.status,
          createdAt: item.createdAt,
          updatedAt: item.updatedAt,
          createdBy: item.createdBy,
          updatedBy: item.updatedBy
      ));
    }

    List<BookingSlot> mergedSlots = mergeBookingSlots(listItems);
    mergedSlots.removeWhere((bookingSlot) => (bookingSlot.slotType=='Repeat-Item'));

    double bookingTotal = bookingSlotItems.fold(0, (double sum, BookingSlot bookingSlot) {
      return sum + (bookingSlot.price ?? 0);
    });

    final profile     = await CapabilityProfile.load();
    final printer     = NetworkPrinter(PaperSize.mm80, profile);
    var storeName     = 'My Store';
    var storeAddress  = '123 Main Street, City';
    var storeMobile   = 'Phone: 123-456-7890';
    var imageUrl      = '';
    var abn           = '';
    var email         = '@email.com';

    var dateAndTime     = DateFormat('yMd').format(DateTime.now());
    dynamic currentTime = DateFormat('hh:mm:ss').format(DateTime.now());

    DocumentReference docRef = FirebaseFirestore.instance
        .collection(authController.centerSlug.toString())
        .doc('admins');
    await docRef.get().then((value) {
      storeName     = value.get('name');
      storeAddress  = value.get('address');
      storeMobile   = 'Phone : ${value.get('phone')}';
      imageUrl      = value.get('imageUrl');
      email         = value.get('email');
      abn           = 'ABN : ${value.get('abn')}';
    });

    for(var printerIPs in settingController.printerList){
      final printerIp          = '${printerIPs.printerIP}';
      final PosPrintResult res = await printer.connect(printerIp, port: printerIPs.printerPort!);
      if (res != PosPrintResult.success) {
        showCustomSnackbar('Printer Error', 'Failed to connect to the printer.', Colors.red);
        return;
      }


      //current date
      printer.row([
        PosColumn(
          text: '${dateAndTime}',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '',
          width: 6,
          styles: PosStyles(align: PosAlign.center, underline: false,
          ),
        ),
        PosColumn(
          text: '${currentTime}',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
      ]);
      printer.feed(1);

      // Print header with store information
      printer.row([
        PosColumn(
          text: '',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '$storeName',
          width: 6,
          styles: PosStyles(align: PosAlign.center, underline: false,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
        ),
        PosColumn(
          text: '',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
      ]);
      printer.feed(1);

      printer.row([
        PosColumn(
          text: '',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '$storeAddress',
          width: 6,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
      ]);

      printer.row([
        PosColumn(
          text: '',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '$abn',
          width: 6,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
      ]);
      printer.row([
        PosColumn(
          text: '',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '$storeMobile',
          width: 6,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
      ]);

      printer.feed(1);
      printer.hr();


      if(mergedSlots.length> 0){
        // Print products text
        printer.text('Bookings#', styles: PosStyles(align: PosAlign.right),linesAfter: 1);
      }

      // Print order items
      for (var item in mergedSlots) {

        printer.row([
          PosColumn(
            text: '${item.court}',
            width: 6,
            styles: PosStyles(align: PosAlign.center, underline: false,),
          ),
          PosColumn(
            text: '${DateFormat('hh:mm ').format(item.startTime!)} ${DateFormat('hh:mm a').format(item.endTime!)}',
            width: 3,
            styles: PosStyles(align: PosAlign.center, underline: false),
          ),
          PosColumn(
            text: '${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(item.price)}',
            width: 3,
            styles: PosStyles(align: PosAlign.center, underline: false),
          ),
        ]);
        printer.emptyLines(1);

      }

      printer.feed(1);
      printer.hr();


      // Print total
      printer.row([
        PosColumn(
          text: '',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: 'Total : ',
          width: 6,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(bookingTotal)}',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
      ]);

      printer.feed(1);
      printer.hr();

      // static text
      printer.row([
        PosColumn(
          text: '',
          width: 1,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: 'Thank You For Your Business!!',
          width: 10,
          styles: PosStyles(align: PosAlign.center, underline: false,
            height: PosTextSize.size2,
            width: PosTextSize.size1,
          ),
        ),
        PosColumn(
          text: '',
          width: 1,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
      ]);

      printer.cut();
      printer.disconnect();
      printer.drawer();

      showCustomSnackbar('Print Successful', 'The receipt has been printed successfully.', Colors.green);

    }

  }*/

  List<BookingSlot> mergeBookingSlots(List<BookingSlot> cartItemsMrg) {
    if (cartItemsMrg.isEmpty) return [];

    // Sort the cartItemsMrg based on court, date, startTime, and endTime
    cartItemsMrg.sort((a, b) {
      int courtComparison = a.court!.compareTo(b.court!);
      if (courtComparison != 0) {
        return courtComparison;
      }

      int dateComparison = a.date!.compareTo(b.date!);
      if (dateComparison != 0) {
        return dateComparison;
      }

      int startTimeComparison = a.startTime!.compareTo(b.startTime!);
      if (startTimeComparison != 0) {
        return startTimeComparison;
      }

      return a.endTime!.compareTo(b.endTime!);
    });

    List<BookingSlot> mergedSlots = [];
    BookingSlot currentSlot = cartItemsMrg[0];

    for (int i = 1; i < cartItemsMrg.length; i++) {
      BookingSlot nextSlot = cartItemsMrg[i];

      // Check if the next slot can be merged with the current slot
      if (nextSlot.courtId == currentSlot.courtId &&
          nextSlot.date == currentSlot.date &&
          nextSlot.startTime!.difference(currentSlot.endTime!) ==
              Duration(minutes: 0) &&
          nextSlot.serviceId == currentSlot.serviceId &&
          nextSlot.subBookingId == currentSlot.subBookingId &&
          nextSlot.repeatGroupId == currentSlot.repeatGroupId) {
        // Extend the current slot's endTime and add price
        currentSlot.endTime = nextSlot.endTime;
        currentSlot.price = (currentSlot.price ?? 0) + (nextSlot.price ?? 0);
      } else {
        // Cannot merge, add the current slot to the mergedSlots list
        mergedSlots.add(currentSlot);
        currentSlot = nextSlot; // Update the current slot to the next slot
      }
    }

    // Add the last slot to the mergedSlots list
    mergedSlots.add(currentSlot);

    return mergedSlots;
  }

  Future<bool> bulkValidateSlots({List<BookingSlot>? selectedBSlots}) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug                  = preferences.getString('centerSlug');
    final futures =
        selectedBSlots!.map((item) {
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

    return matchingRowCount == 0 ? true : false;
  }
}
