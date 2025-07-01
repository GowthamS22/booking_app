// ignore_for_file: must_be_immutable
import 'dart:convert';

import 'package:booking_app/controllers/payment_controller.dart';
import 'package:booking_app/models/products.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/getx_binding.dart';
import '../../config/constants.dart';
import '../../config/palette.dart';
import '../../controllers/checkout_controller.dart';
import '../../controllers/customer_controller.dart';
import '../../controllers/new_booking_controller.dart';
import '../../controllers/default_controller.dart';
import '../../models/booking_model.dart';

class CheckoutScreen extends StatefulWidget {
  final String type;
  final String customerName;
  final String mobileno;
  final DateTime selectedDateTime;
  final double billAmount;
  final List<BookingInfo> bookings;
  final String membershipID;
  final String? membershipName;
  final bool? isMembershipApplied;
  final double? membershipPrice;
  final String? exbookingId;
  final String? exorderId;
  final String? exuserId;
  CheckoutScreen({
    Key? key,
    required this.type,
    required this.customerName,
    required this.mobileno,
    required this.selectedDateTime,
    required this.billAmount,
    required this.bookings,
    required this.membershipID,
    required this.membershipName,
    required this.isMembershipApplied,
    required this.membershipPrice,
    this.exbookingId,
    this.exorderId,
    this.exuserId
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final NewBookingController newBookingController = Get.put(
    NewBookingController(),
  ); //Get.find();
  final DefaultController defaultController = Get.put(DefaultController());
  final CustomerController customerController = Get.put(CustomerController());
  final PaymentController paymentController = Get.put(PaymentController());

  TextEditingController notesController = TextEditingController();
  TextEditingController promoCodeController = TextEditingController();

  TextEditingController paidAmountController = TextEditingController();
  TextEditingController balanceAmountController = TextEditingController();

  // String? _selectedPaymentType = 'Credit Card';
  bool receiptToggle = true;
  Map<String, List<BookingInfo>> groupedBookings = {};
  double totalPaid = 0.0;
  String customAmountString = '';
  // final List<String> paymentMethods = [
  //   'CASH',
  //   'EFTPOS',
  //   'On Account/Void',
  //   // 'MIXED',
  // ];
  String selected = 'EPTPOS';
  String selectedAmount = '';
  final List<Map<String, dynamic>> paymentMethods = [
    {'label': 'EFTPOS', 'image': 'assets/images/pic/EFTPOS.png'},
    {'label': 'On Acc. / Void', 'image': 'assets/images/pic/account.png'},
    {'label': 'Cash', 'image': 'assets/images/pic/cash.png'},
  ];

  String selectedMethod = 'CASH';

  void _addPayment(double amount) {
    setState(() {
      totalPaid = amount;
    });
  }

  List<String> keys = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '.',
    '0',
    '⌫',
  ];

  List<CartItem> cartItems = []; // Add this line

  double discountAmount = 0.0;
  bool isDiscountApplied = false;
  TextEditingController discountController = TextEditingController();

  double get cartItemsTotal => cartItems.fold(0,(sum, item) => sum + double.parse(item.product.price) * item.quantity,);

  @override
  void initState() {
    _loadCartItems(); // Add this line
    // TODO: implement initState
    for (var booking in widget.bookings) {
      groupedBookings.putIfAbsent(booking.courtName, () => []).add(booking);
    }
    super.initState();
  }

  Future<void> _loadCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString('shopping_cart');
      if (cartJson != null) {
        final List<dynamic> cartData = jsonDecode(cartJson);
        setState(() {
          cartItems = cartData.map((json) => CartItem.fromJson(json)).toList();
        });
      }
    } catch (e) {
      print('Error loading cart items: $e');
    }
  }

  Future<void> _clearCartAfterPayment() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('shopping_cart');
  }

  void showCancelBookingConfirmationDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text("Confirm", style: TextStyle(fontSize: 25),),
        content: const Text(
          "Are you sure you want to cancel this booking and go to the Dashboard?",
          style: TextStyle(fontSize: 22),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 20,
            children: [
              TextButton(
                onPressed: () {
                  Get.back(); // Close dialog
                },
                child: const Text("No", style: TextStyle(fontSize: 22),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  minimumSize: const Size(200, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final defaultController = Get.find<DefaultController>();
                  defaultController.tabIndex.value = 0;
                  defaultController.dashboardTabController?.index = 0;
                  Get.offAllNamed('/');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size(200, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Yes", style: TextStyle(fontSize: 22, color: Colors.white),),
              ),
            ],
          )
        ],
      ),
      barrierDismissible: false,
    );
  }

  Color? borderColor;
  Color? backgroundColor;
  Color? textColor;
  @override
  Widget build(BuildContext context) {
    if (widget.membershipName.toString().toLowerCase().contains('gold')) {
      borderColor = Colors.amber.shade500;
      backgroundColor = Colors.amber.shade50;
      textColor = Colors.amber.shade800;
    } else if (widget.membershipName.toString().toLowerCase().contains(
      'platinum',
    )) {
      borderColor = Colors.indigo.shade500;
      backgroundColor = Colors.indigo.shade50;
      textColor = Colors.indigo.shade700;
    }
    return GetBuilder(
      init: CheckoutController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            toolbarHeight: 100,
            titleSpacing: 0,
            automaticallyImplyLeading: false,
            //leadingWidth: MediaQuery.of(context).size.width / 2.1,
            title: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  //SizedBox(width: 22 * ffem),
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white, // Navy blue
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade500),
                    ),
                    child: IconButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Container(
                        child: Row(
                          spacing: 10,
                          children: [
                            Icon(Icons.arrow_back, color: Colors.black, size: 35,),
                            Text('Go back', style: TextStyle(fontSize: 23),)
                          ],
                        ),
                      ),
                      onPressed: () => Get.back(result: true),
                    ),
                  ),
                  SizedBox(width: 18 * ffem),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Payment',
                        style: GoogleFonts.inter(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Create new booking based on selected courts',
                        style: GoogleFonts.inter(
                          fontSize: 23,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Items count
                  GestureDetector(
                    onTap: () {
                      showCancelBookingConfirmationDialog();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade500),
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.layoutDashboard, size: 40),
                          const SizedBox(width: 10),
                          Text(
                            'Dashboard',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade900,
                              fontSize: 25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  //SizedBox(width: 30),
                ],
              ),
            ),
          ),
          //backgroundColor: Palette.white,
          body: SingleChildScrollView(
            child: Column(
              children: [
                //Divider(color: Colors.grey.shade300, thickness: 1),
                Container(
                  decoration: BoxDecoration(
                    //color: Colors.white,
                    //border: Border.all(color: Colors.grey.shade300),
                    //borderRadius: BorderRadius.circular(10)
                  ),
                  //margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  //padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          spacing: 20,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildCartItems(),
                            buildCheckout(newBookingController, controller),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // Add this function to CheckoutController

  void populateCartWithSubSlots(List<BookingInfo> bookings) {
    newBookingController.cartItems.clear(); // Clear any existing items

    for (final bookingInfo in bookings) {
      final courtId =
          newBookingController.courtList.firstWhere(
            (court) => court['name'] == bookingInfo.courtName,
            orElse: () => {},
          )['id']; // Find the court ID based on the name

      if (courtId == null) {
        print('Warning: Could not find court ID for ${bookingInfo.courtName}');
        continue; // Skip if court ID is not found
      }

      for (final subSlotInfo in bookingInfo.subSlots) {
        final startTime = parseDateTime(
          widget.selectedDateTime,
          subSlotInfo.startTime,
        );
        final endTime = parseDateTime(
          widget.selectedDateTime,
          subSlotInfo.endTime,
        );
        print('selectedDateTime: ${widget.selectedDateTime}');
        final individualSlot = BookingSlot(
          serviceId: newBookingController.selectedServiceId.value,
          courtId: courtId,
          court: bookingInfo.courtName,
          date: widget.selectedDateTime, // Set the date to match the startTime
          startTime: startTime,
          endTime: endTime,
          price: subSlotInfo.price,
          slotType: null,
          repeatDays: null,
          repeatEnd: bookingInfo.repeatUntil,
          repeatId: null,
          repeatGroupId: null,
          status: 'Selected',
          bookingId: widget.bookings.first.bookingId,
          paymentStatus: 'paid',
          name: widget.customerName,
          mobile: widget.mobileno,
          service: newBookingController.selectedService.value,
          updatedAt: DateTime.now(),
          updatedBy: authController.userId.toString(),
          userId: authController.userId.toString(),
        );
        newBookingController.cartItems.add(individualSlot);
      }
      print("SelectedSlots  : ${newBookingController.cartItems}");
    }
  }

  // Helper function to combine DateTime and a HH:mm time string
  DateTime parseDateTime(DateTime date, String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  Widget buildCartItems() {
    return Expanded(
      flex: 2,
      child: Container(
        height: MediaQuery.of(context).size.height * .88,
        margin: const EdgeInsets.only(bottom: 10, top: 10, left: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Info',
                      style: GoogleFonts.inter(
                        color: Palette.black,
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and Badge
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.customerName,
                              style: GoogleFonts.inter(
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const SizedBox(height: 4),
                            Text(
                              widget.mobileno,
                              style: GoogleFonts.inter(
                                color: Colors.grey.shade600,
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        // Date and Time
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat(
                                'd MMM yyyy',
                              ).format(widget.selectedDateTime),
                              style: GoogleFonts.inter(
                                fontSize: 25,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('h:mm a').format(DateTime.now()),
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    Divider(thickness: 1, color: Colors.grey.shade300),

                    // Court Info
                    Column(
                      children:
                          groupedBookings.entries.map((entry) {
                            String courtName = entry.key;
                            List<BookingInfo> courtBookings = entry.value;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Court Name Header
                                  Text(
                                    courtName,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 22,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Time Slots for this Court
                                  ...courtBookings.map((booking) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Display individual sub-slots
                                        ...booking.subSlots.map((subSlot) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 4,
                                              left: 8,
                                            ), // Add some left padding for sub-slots
                                            child: Row(
                                              children: [
                                                Text(
                                                  '${subSlot.startTime} - ${subSlot.endTime}',
                                                  style: GoogleFonts.inter(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 22,
                                                    color:
                                                        Colors
                                                            .green, // Adjust color as needed
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  subSlot.isPeak
                                                      ? '(Peak Hour)'
                                                      : '(Non-Peak Hour)',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 22,
                                                    color:
                                                        subSlot.isPeak
                                                            ? Colors
                                                                .orange
                                                                .shade700
                                                            : Colors
                                                                .grey
                                                                .shade600, // Adjust color as needed
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  '\$${subSlot.price.toStringAsFixed(2)}',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 23,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                    );
                                  }).toList(),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                    if (widget.isMembershipApplied == true) ...[
                      Container(
                        width: MediaQuery.of(context).size.width / 2.5,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: borderColor!),
                        ),

                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${widget.membershipName} Membership' ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 23,
                                color: textColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            // Text(
                            //   membershipValidityDate != null
                            //       ? '$membershipPlan :(${membershipValidityDate!.difference(DateTime.now()).inDays > 0 ? 'Valid for ${membershipValidityDate!.difference(DateTime.now()).inDays} days' : 'Expired'})'
                            //       : '$membershipPlan : (No Validity Info)',
                            //   style: GoogleFonts.inter(
                            //     fontSize: 14,
                            //     fontWeight: FontWeight.w700,
                            //     color: textColor,
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 8),
                    Container(
                      width: MediaQuery.of(context).size.width / 2.5,
                      height: MediaQuery.of(context).size.height / 1.5,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Column(
                        children: [
                          Row(
                            spacing: 35,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Item',
                                      style: GoogleFonts.inter(
                                        fontSize: 25,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              Container(
                                width: 110,
                                child: Text(
                                  'Qty.',
                                  style: GoogleFonts.inter(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),

                              Container(
                                width: 110,
                                child: Text(
                                  'Price',
                                  style: GoogleFonts.inter(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),

                          Divider(thickness: 1, color: Colors.grey.shade300),

                          // Display cart items if they exist
                          if (cartItems.isNotEmpty) ...[
                            ...cartItems.map((item) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  spacing: 30,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.product.name,
                                            style: GoogleFonts.inter(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          // if (item.product.description != null && item.product.description!.isNotEmpty)
                                          //   Text(
                                          //     item.product.description!,
                                          //     style: GoogleFonts.inter(
                                          //       fontSize: 12,
                                          //       color: Colors.grey.shade600,
                                          //     ),
                                          //     maxLines: 1,
                                          //     overflow: TextOverflow.ellipsis,
                                          //   ),
                                        ],
                                      ),
                                    ),

                                    Container(
                                      width: 110,
                                      child: Text(
                                        'x${item.quantity}',
                                        style: GoogleFonts.inter(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),

                                    Container(
                                      width: 110,
                                      child: Text(
                                        '\$${(double.parse(item.product.price) * item.quantity).toStringAsFixed(2)}',
                                        style: GoogleFonts.inter(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),

                            // const SizedBox(height: 16),
                            // Divider(thickness: 1, color: Colors.grey.shade300),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Totals section that will stick to the bottom
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(color: Colors.grey.shade300, thickness: 3),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: GoogleFonts.inter(
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '\$${(widget.billAmount - discountAmount).toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (isDiscountApplied) const SizedBox(height: 4),
                if (isDiscountApplied)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Discount',
                        style: GoogleFonts.inter(
                          fontSize: 25,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '\$${(discountAmount).toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 25,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'GST Incl',
                      style: GoogleFonts.inter(
                        fontSize: 25,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '\$${((widget.billAmount - discountAmount) * 0.1).toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 25,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Grand Total',
                      style: GoogleFonts.inter(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '\$${(widget.billAmount - discountAmount).toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  buildCheckout(
    NewBookingController controller,
    CheckoutController checkoutController,
  ) {
    if (paidAmountController.text.length > 0) {
      double paid = double.parse(paidAmountController.text);
      if (paid > 0) {
        double balance = checkoutController.grandtotalPrice - paid;
        balanceAmountController.text = balance.toStringAsFixed(2);
      }
    } else {
      balanceAmountController.text = checkoutController.grandtotalPrice
          .toStringAsFixed(2);
    }
    return Expanded(
      flex: 3,
      child: ListView(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.14,
                margin: const EdgeInsets.only(
                  // left: 15,
                  bottom: 10,
                  top: 10,
                  right: 15,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: _buildAmountSummary(checkoutController),
              ),
              // SizedBox(height: ),
              // Container(
              //   margin: const EdgeInsets.only(bottom: 10, top: 10, right: 15),
              //   padding: const EdgeInsets.all(16),
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: BorderRadius.circular(12),
              //     border: Border.all(color: Colors.grey.shade300),
              //   ),
              //   child: Row(
              //     children: [
              //       Icon(LucideIcons.edit3),

              //       SizedBox(width: 20),
              //       Text(
              //         'Notes',
              //         style: GoogleFonts.inter(
              //           fontWeight: FontWeight.w500,
              //           color: Colors.grey.shade900,
              //           fontSize: 16,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              // SizedBox(height: 20),
              // Container(
              //   height: MediaQuery.of(context).size.height * 0.09,
              //   margin: const EdgeInsets.only(bottom: 10, top: 10, right: 15),
              //   padding: const EdgeInsets.all(16),
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: BorderRadius.circular(12),
              //     border: Border.all(color: Colors.grey.shade300, width: 2),
              //   ),
              //   child: _buildPaymentOptions(),
              // ),
              Container(
                height: MediaQuery.of(context).size.height * 0.16,

                margin: const EdgeInsets.only(bottom: 10, top: 10, right: 15),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: Row(
                  children:
                      paymentMethods.map((method) {
                        final isSelected = selectedMethod == method['label'];

                        return Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              if (method['label'] == 'EFTPOS') {
                                totalPaid = widget.billAmount - discountAmount;
                                customAmountString =
                                    (widget.billAmount - discountAmount)
                                        .toString();
                                setState(() {
                                  selectedMethod = method['label'];
                                });
                              } else if (method['label'] == 'Cash') {
                                totalPaid = 0.0;
                                customAmountString = '';
                                setState(() {
                                  selectedMethod = method['label'];
                                });
                              } else {
                                totalPaid = widget.billAmount - discountAmount;
                                customAmountString =
                                    (widget.billAmount - discountAmount)
                                        .toString();
                                setState(() {
                                  selectedMethod = method['label'];
                                });
                              }
                              // setState(() {

                              //   selected = method['label'];
                              // });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? const Color(0xFFF0F4FF)
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? const Color(0xFF6366F1)
                                          : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    method['image'],
                                    width:
                                        MediaQuery.of(context).size.width / 2,
                                    height:
                                        MediaQuery.of(context).size.height *
                                        .07,
                                    color:
                                        isSelected
                                            ? Colors.indigo.shade500
                                            : Colors.grey.shade600,
                                  ),
                                  // const SizedBox(height: 10),
                                  Text(
                                    method['label'],
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 25,
                                      color:
                                          isSelected
                                              ? Colors.indigo.shade500
                                              : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
              if (selectedMethod == 'EFTPOS') ...[
                SizedBox(height: 10),
                Obx(() {
                  final controller = Get.find<CheckoutController>();
                  return Column(
                    children: [
                      if (controller.isProcessingPayment.value)
                        CircularProgressIndicator(),
                      if (controller.paymentStatus.value.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            controller.paymentStatus.value,
                            style: GoogleFonts.inter(
                              fontSize: 25,
                              color:
                                  controller.paymentStatus.value.contains(
                                        'failed',
                                      )
                                      ? Colors.red
                                      : Colors.green,
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ],

              // Payment Methods
              if (selectedMethod == 'Cash') ...[
                SizedBox(height: 10),
                _buildAmountSelector(),
              ],

              Container(
                margin: const EdgeInsets.only(top: 16, right: 15),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Discount Notes Input
                    if (isDiscountApplied)
                      TextField(
                        controller: notesController,
                        decoration: InputDecoration(
                          hintText: "Discount Notes",
                          hintStyle: GoogleFonts.inter(
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w500,
                            fontSize: 25,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        style: TextStyle(fontSize: 25),
                      ),
                    if (isDiscountApplied) const SizedBox(height: 16),

                    // Buttons Row
                    Padding(
                      padding: const EdgeInsets.all(0.0),
                      child: Row(
                        children: [
                          if(widget.type=='Product') ...[

                          // Discount Applied
                          if (isDiscountApplied)
                            Expanded(
                              child: Container(
                                height:
                                    MediaQuery.of(context).size.height * .05,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F4FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '\$${(discountAmount ?? 0).toStringAsFixed(2)} Discount Applied',
                                  style: GoogleFonts.inter(
                                    color: Colors.indigo.shade500,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 25,
                                  ),
                                ),
                              ),
                            ),
                          if (isDiscountApplied) const SizedBox(width: 12),

                          // Remove Discount
                          if (isDiscountApplied)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    discountAmount = 0.0;
                                    isDiscountApplied = false;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                child: Text(
                                  'Remove Discount',
                                  style: GoogleFonts.inter(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 25,
                                  ),
                                ),
                              ),
                            ),
                          if (isDiscountApplied) const SizedBox(width: 12),

                          if (!isDiscountApplied)
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    () =>
                                        _showDiscountDialog(checkoutController),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF0F4FF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                child: Text(
                                  'Apply Discount',
                                  style: GoogleFonts.inter(
                                    color: Colors.indigo.shade500,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 25,
                                  ),
                                ),
                              ),
                            ),
                          if (!isDiscountApplied) const SizedBox(width: 12),

                          ],

                          // Receipt Toggle
                          Expanded(
                            child: Container(
                              height: MediaQuery.of(context).size.height * .06,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Receipt',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 25,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  Switch(
                                    value: receiptToggle,
                                    activeColor: const Color(0xFF6366F1),
                                    onChanged: (value) {
                                      setState(() {
                                        receiptToggle = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              //Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final result = await _showCancelBookingDialog();
                          if (result == true) {
                            // User cancelled, so clear selection here
                            controller.clearSelectedSlots();
                            setState(() {});
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 44),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 25,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Obx(() {
                        final isProcessing =
                            checkoutController.isProcessingPayment.value;
                        return ElevatedButton(
                          onPressed:
                              isProcessing
                                  ? null
                                  : () async {
                                    if (totalPaid > 0) {
                                      if (double.parse(
                                            balanceAmountController.text,
                                          ) <=
                                          0 && totalPaid >= widget.billAmount) {
                                        setState(() {
                                          checkoutController
                                              .checkoutPayBtn
                                              .value = true;
                                        });

                                        if (isDiscountApplied) {
                                          if (notesController.text == null ||
                                              notesController.text == '' ||
                                              notesController.text.isEmpty) {
                                            showCustomSnackbar(
                                              'Warning',
                                              'Please enter the discount notes',
                                              Colors.orange,
                                            );
                                            setState(() {
                                              checkoutController
                                                  .checkoutPayBtn
                                                  .value = false;
                                            });
                                            return;
                                          }
                                        }

                                        try {
                                          // Continue with existing payment processing
                                          if (widget.type == 'Membership') {

                                            final prefs = await SharedPreferences.getInstance();
                                            String? paymentDevices = prefs.getString('paymentDevices');
                                            final Map<String, dynamic> paymentDeviceData = jsonDecode(paymentDevices!,);

                                            double? overallTotal  = widget.billAmount;

                                            if (selectedMethod == 'EFTPOS') {
                                              final total = overallTotal;
                                              await paymentController.processPayment(
                                                context: context,
                                                amount: total.toDouble(),
                                                reference: controller.bookingId,
                                                apiKey: paymentDeviceData['api_key'], // Get from secure storage
                                                merchantId: paymentDeviceData['merchant_id'],
                                                terminalId: paymentDeviceData['terminal_id'],
                                                integrationKey: paymentDeviceData['integration_key'],
                                                posProductVendor: paymentDeviceData['product_vendor'],
                                                posProductName: paymentDeviceData['product_name'],
                                                posProductVersion: paymentDeviceData['product_version'],
                                              ).then((value) async {

                                                await checkoutController.processMembershipPayment(
                                                  userId: widget.exuserId,
                                                  paymentType: selectedMethod,
                                                  notes: notesController.text,
                                                  paid: totalPaid,
                                                  balance: double.parse(balanceAmountController.text,),
                                                  isMembershipApplied: widget.isMembershipApplied,
                                                  membershipId:widget.membershipID,
                                                );

                                              });
                                            }  else {

                                              await checkoutController.processMembershipPayment(
                                                userId: widget.exuserId,
                                                paymentType: selectedMethod,
                                                notes: notesController.text,
                                                paid: totalPaid,
                                                balance: double.parse(balanceAmountController.text,),
                                                isMembershipApplied: widget.isMembershipApplied,
                                                membershipId:widget.membershipID,
                                              );

                                            }

                                          } else if (widget.type == 'ExistingBooking') {

                                            final prefs = await SharedPreferences.getInstance();
                                            String? paymentDevices = prefs.getString('paymentDevices');
                                            final Map<String, dynamic> paymentDeviceData = jsonDecode(paymentDevices!,);

                                            double? itemSubTotal  = cartItemsTotal;
                                            double? itemTotal     = cartItemsTotal - discountAmount;
                                            double? bookingTotal  = widget.billAmount - itemTotal;
                                            double? overallTotal  = itemTotal + bookingTotal;

                                            if (selectedMethod == 'EFTPOS') {
                                              final total = overallTotal;
                                              await paymentController.processPayment(
                                                context: context,
                                                amount: total.toDouble(),
                                                reference: controller.bookingId,
                                                apiKey: paymentDeviceData['api_key'], // Get from secure storage
                                                merchantId: paymentDeviceData['merchant_id'],
                                                terminalId: paymentDeviceData['terminal_id'],
                                                integrationKey: paymentDeviceData['integration_key'],
                                                posProductVendor: paymentDeviceData['product_vendor'],
                                                posProductName: paymentDeviceData['product_name'],
                                                posProductVersion: paymentDeviceData['product_version'],
                                                ).then((value) async {

                                                await checkoutController.makeBookingPayment(
                                                  bookingId: widget.exbookingId,
                                                  orderId: widget.exorderId,
                                                  userId: widget.exuserId,
                                                  paymentType: selectedMethod,
                                                  promoCode: promoCodeController.text,
                                                  notes: notesController.text,
                                                  paid: totalPaid,
                                                  balance: double.parse(balanceAmountController.text,),
                                                  printReceipt: widget.exorderId != null ? false : true,
                                                );

                                                if(widget.exorderId!=null && widget.exorderId!='') {
                                                  checkoutController.productsPayment(
                                                    order_id: widget.exorderId,
                                                    price: itemSubTotal,
                                                    taxes: (itemTotal) * 0.1,
                                                    surcharge: 0,
                                                    discount: discountAmount,
                                                    billAmount: itemTotal,
                                                    paidAmount: totalPaid,
                                                    balanceAmount: double.parse(balanceAmountController.text,),
                                                    paymentType: selectedMethod,
                                                    paymentNotes: notesController.text,
                                                    receiptToggle: receiptToggle,
                                                    printBoth: true,
                                                  );
                                                }

                                              });
                                            }  else {

                                              await checkoutController.makeBookingPayment(
                                                bookingId: widget.exbookingId,
                                                orderId: widget.exorderId,
                                                userId: widget.exuserId,
                                                paymentType: selectedMethod,
                                                promoCode: promoCodeController.text,
                                                notes: notesController.text,
                                                paid: totalPaid,
                                                balance: double.parse(balanceAmountController.text,),
                                                printReceipt: widget.exorderId != null ? false : true,
                                              );

                                              if(widget.exorderId!=null && widget.exorderId!='') {
                                                checkoutController.productsPayment(
                                                  order_id: widget.exorderId,
                                                  price: itemSubTotal,
                                                  taxes: (itemTotal) * 0.1,
                                                  surcharge: 0,
                                                  discount: discountAmount,
                                                  billAmount: itemTotal,
                                                  paidAmount: totalPaid,
                                                  balanceAmount: double.parse(balanceAmountController.text,),
                                                  paymentType: selectedMethod,
                                                  paymentNotes: notesController.text,
                                                  receiptToggle: receiptToggle,
                                                  printBoth: true,
                                                );
                                              }

                                            }


                                          } else if (widget.type == 'New') {

                                            final prefs = await SharedPreferences.getInstance();
                                            String? paymentDevices = prefs.getString('paymentDevices');
                                            final Map<String, dynamic> paymentDeviceData = jsonDecode(paymentDevices!,);

                                            double? itemSubTotal  = cartItemsTotal;
                                            double? itemTotal     = cartItemsTotal - discountAmount;
                                            double? bookingTotal  = widget.billAmount - itemTotal;
                                            double? overallTotal  = itemTotal + bookingTotal;

                                            String? orderId = '';
                                            //double? total   = 0;

                                            //Create order if the cart items are exist
                                            if(cartItems.length > 0) {
                                              await checkoutController.createTempOrder(total:(itemTotal)!,).then((value) {
                                                orderId = value['id'];
                                                //total = value['total'];
                                              },);
                                            }

                                            if (selectedMethod == 'EFTPOS') {
                                              final total = overallTotal;
                                              try {
                                                  await paymentController.processPayment(
                                                    context: context,
                                                    amount: total.toDouble(),
                                                    reference: controller.bookingId,
                                                    apiKey: paymentDeviceData['api_key'], // Get from secure storage
                                                    merchantId: paymentDeviceData['merchant_id'],
                                                    terminalId: paymentDeviceData['terminal_id'],
                                                    integrationKey: paymentDeviceData['integration_key'],
                                                    posProductVendor: paymentDeviceData['product_vendor'],
                                                    posProductName: paymentDeviceData['product_name'],
                                                    posProductVersion: paymentDeviceData['product_version'],
                                                  ).then((value) async {

                                                    if (controller.userData.value.id != null) {

                                                      populateCartWithSubSlots(widget.bookings,);
                                                      await checkoutController.processFinalCheckout(
                                                        userId: controller.userData.value.id,
                                                        name: controller.nameController.text,
                                                        email: controller.userData.value.email,
                                                        mobile: controller.userData.value.mobile,
                                                        paymentType: selectedMethod,
                                                        promoCode: promoCodeController.text,
                                                        notes: notesController.text,
                                                        paid: totalPaid,
                                                        balance: double.parse(balanceAmountController.text,),
                                                        bookingId: controller.bookingId,
                                                        isMembershipApplied: widget.isMembershipApplied,
                                                        membershipId:widget.membershipID,
                                                        printReceipt: receiptToggle==true ? orderId=='' ? true : false : false,
                                                        orderId: orderId,
                                                      );

                                                    } else {

                                                      await checkoutController.registerUser(
                                                        mobile: widget.mobileno,
                                                        firstName: widget.customerName,
                                                        membershipId: widget.membershipID,
                                                      ).then((value) {
                                                        populateCartWithSubSlots(widget.bookings,);
                                                        checkoutController.processFinalCheckout(
                                                          userId: checkoutController.userData.value.id,
                                                          name: controller.nameController.text,
                                                          email: controller.userData.value.email,
                                                          mobile: controller.userData.value.mobile,
                                                          paymentType: selectedMethod,
                                                          promoCode: promoCodeController.text,
                                                          notes: notesController.text,
                                                          paid: totalPaid,
                                                          balance: double.parse(balanceAmountController.text,),
                                                          bookingId: controller.bookingId,
                                                          isMembershipApplied: widget.isMembershipApplied,
                                                          membershipId: widget.membershipID,
                                                          printReceipt: receiptToggle==true ? orderId=='' ? true : false : false,
                                                          orderId: orderId,
                                                        );
                                                      });
                                                    }

                                                    if(orderId!=null && orderId!='') {
                                                      checkoutController.productsPayment(
                                                        order_id: orderId,
                                                        price: itemSubTotal,
                                                        taxes: (itemTotal) * 0.1,
                                                        surcharge: 0,
                                                        discount: discountAmount,
                                                        billAmount: itemTotal,
                                                        paidAmount: totalPaid,
                                                        balanceAmount: double.parse(balanceAmountController.text,),
                                                        paymentType: selectedMethod,
                                                        paymentNotes: notesController.text,
                                                        receiptToggle: receiptToggle,
                                                        printBoth: true,
                                                      );
                                                    }

                                                  });
                                              } catch (e) {
                                                Get.snackbar(
                                                  'Error',
                                                  paymentController.paymentError.value,
                                                  backgroundColor: Colors.red,
                                                );
                                              }

                                            } else {

                                              if (controller.userData.value.id != null) {
                                                populateCartWithSubSlots(widget.bookings,);
                                                await checkoutController.processFinalCheckout(
                                                  userId: controller.userData.value.id,
                                                  name: controller.nameController.text,
                                                  email: controller.userData.value.email,
                                                  mobile: controller.userData.value.mobile,
                                                  paymentType: selectedMethod,
                                                  promoCode: promoCodeController.text,
                                                  notes: notesController.text,
                                                  paid: totalPaid,
                                                  balance: double.parse(balanceAmountController.text,),
                                                  bookingId: controller.bookingId,
                                                  isMembershipApplied: widget.isMembershipApplied,
                                                  membershipId:widget.membershipID,
                                                  printReceipt: receiptToggle==true ? orderId=='' ? true : false : false,
                                                  orderId: orderId,
                                                );
                                              } else {
                                                await checkoutController.registerUser(
                                                  mobile: widget.mobileno,
                                                  firstName: widget.customerName,
                                                  membershipId: widget.membershipID,
                                                ).then((value) {
                                                  populateCartWithSubSlots(widget.bookings,);
                                                  checkoutController.processFinalCheckout(
                                                    userId: checkoutController.userData.value.id,
                                                    name: controller.nameController.text,
                                                    email: controller.userData.value.email,
                                                    mobile: controller.userData.value.mobile,
                                                    paymentType: selectedMethod,
                                                    promoCode: promoCodeController.text,
                                                    notes: notesController.text,
                                                    paid: totalPaid,
                                                    balance: double.parse(balanceAmountController.text,),
                                                    bookingId: controller.bookingId,
                                                    isMembershipApplied: widget.isMembershipApplied,
                                                    membershipId: widget.membershipID,
                                                    printReceipt: receiptToggle==true ? orderId=='' ? true : false : false,
                                                    orderId: orderId,
                                                  );
                                                });
                                              }

                                              if(orderId!=null && orderId!='') {
                                                checkoutController.productsPayment(
                                                  order_id: orderId,
                                                  price: itemSubTotal,
                                                  taxes: (itemTotal) * 0.1,
                                                  surcharge: 0,
                                                  discount: discountAmount,
                                                  billAmount: itemTotal,
                                                  paidAmount: totalPaid,
                                                  balanceAmount: double.parse(balanceAmountController.text,),
                                                  paymentType: selectedMethod,
                                                  paymentNotes: notesController.text,
                                                  receiptToggle: receiptToggle,
                                                  printBoth: true,
                                                );
                                              }

                                            }

                                          } else if (widget.type == 'Product') {

                                            final prefs = await SharedPreferences.getInstance();
                                            String? paymentDevices = prefs.getString('paymentDevices');
                                            final Map<String, dynamic> paymentDeviceData = jsonDecode(paymentDevices!,);

                                            checkoutController.createTempOrder(total:(widget.billAmount - discountAmount)!,).then((value) async {
                                                  final orderId = value['id'];
                                                  final total = value['total'];
                                                  if (selectedMethod == 'EFTPOS') {
                                                    try {
                                                      // print(orderId);
                                                      // print(total);
                                                      // print(paymentDeviceData);
                                                      await paymentController.processPayment(
                                                            context: context,
                                                            amount: total.toDouble(),
                                                            reference: orderId,
                                                            apiKey: paymentDeviceData['api_key'], // Get from secure storage
                                                            merchantId: paymentDeviceData['merchant_id'],
                                                            terminalId: paymentDeviceData['terminal_id'],
                                                            integrationKey: paymentDeviceData['integration_key'],
                                                            posProductVendor: paymentDeviceData['product_vendor'],
                                                            posProductName: paymentDeviceData['product_name'],
                                                            posProductVersion: paymentDeviceData['product_version'],
                                                          ).then((value) {
                                                            checkoutController.productsPayment(
                                                              order_id: orderId,
                                                              price: widget.billAmount - discountAmount,
                                                              taxes: (widget.billAmount - discountAmount) * 0.1,
                                                              surcharge: 0,
                                                              discount: discountAmount,
                                                              billAmount: widget.billAmount,
                                                              paidAmount: totalPaid,
                                                              balanceAmount: double.parse(balanceAmountController.text,),
                                                              paymentType: selectedMethod,
                                                              paymentNotes: notesController.text,
                                                              paymentResponse: value.toString(),
                                                              receiptToggle: receiptToggle,
                                                            );
                                                          });

                                                      if (paymentController.paymentStatus.value == 'Payment successful') {
                                                        print(
                                                          'Payment Successful via Tyro',
                                                        );
                                                      }
                                                    } catch (e) {
                                                      Get.snackbar(
                                                        'Error',
                                                        paymentController.paymentError.value,
                                                        backgroundColor: Colors.red,
                                                      );
                                                    }
                                                  } else {
                                                    checkoutController.productsPayment(
                                                      order_id: orderId,
                                                      price: widget.billAmount - discountAmount,
                                                      taxes: (widget.billAmount - discountAmount) * 0.1,
                                                      surcharge: 0,
                                                      discount: discountAmount,
                                                      billAmount: widget.billAmount - discountAmount,
                                                      paidAmount: totalPaid,
                                                      balanceAmount: double.parse(balanceAmountController.text,),
                                                      paymentType: selectedMethod,
                                                      paymentNotes: notesController.text,
                                                      receiptToggle: receiptToggle,
                                                    );
                                                  }
                                                });
                                          }
                                          //Checkout End

                                        } catch (e) {
                                          showCustomSnackbar(
                                            'Error',
                                            e.toString(),
                                            Colors.red,
                                          );
                                        } finally {
                                          setState(() {
                                            checkoutController.checkoutPayBtn.value = false;
                                          });
                                        }
                                      } else {
                                        showCustomSnackbar(
                                          'Warning',
                                          'Invalid Amount',
                                          Colors.orange,
                                        );
                                      }
                                    } else {
                                      showCustomSnackbar(
                                        'Warning',
                                        'Please enter the Paid Amount',
                                        Colors.orange,
                                      );
                                    }
                                  },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 44),
                            backgroundColor: Colors.green.shade500,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child:
                              checkoutController.checkoutPayBtn.value
                                  ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    'Pay Now',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 25,
                                      color: Colors.white,
                                    ),
                                  ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showDiscountDialog(
    CheckoutController checkoutController,
  ) async {
    discountController.clear();

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          // Use insetPadding to control the dialog's position and size
          insetPadding: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth:
                  MediaQuery.of(context).size.width *
                  0.3, // 70% of screen width
              maxWidth:
                  MediaQuery.of(context).size.width * 0.3, // Optional max width
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Apply Discount',
                    style: GoogleFonts.inter(
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Enter discount amount (max \$${widget.billAmount.toStringAsFixed(2)})',
                    style: GoogleFonts.inter(fontSize: 22),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: discountController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    decoration: InputDecoration(
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                      hintText: '0.00',
                    ),
                    style: GoogleFonts.inter(fontSize: 25),
                  ),
                  SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Palette.newColorbg,
                            minimumSize: const Size(
                              0,
                              60,
                            ), // 0 width means expand
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Palette.newColor),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              color: Palette.newColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final enteredAmount =
                                double.tryParse(discountController.text) ?? 0.0;
                            if (enteredAmount > 0 &&
                                enteredAmount <= widget.billAmount) {
                              setState(() {
                                discountAmount = enteredAmount;
                                isDiscountApplied = true;
                              });
                              Navigator.pop(context);
                            } else {
                              showCustomSnackbar(
                                'Invalid Amount',
                                'Discount must be between 0 and ${widget.billAmount.toStringAsFixed(2)}',
                                Colors.red,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Palette.newColor,
                            minimumSize: const Size(
                              0,
                              60,
                            ), // 0 width means expand
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Apply',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAmountSummary(CheckoutController checkoutController) {
    // Calculate total from cart items

    final double cartTotal = cartItems.fold(
      0,
      (sum, item) =>
          sum + (double.tryParse(item.product.price) ?? 0) * item.quantity,
    );

    final double billAmount = widget.billAmount - discountAmount;
    final double totalPaid = this.totalPaid;
    final double balance = billAmount - totalPaid;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _amountColumn('Bill Amount', billAmount),
          _divider(),
          _amountColumn('Total Paid', totalPaid),
          _divider(),
          _amountColumn('Balance', balance, isBalance: true),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 2,
    height: MediaQuery.of(context).size.height * .13,
    color: Colors.grey.shade300,
  );

  Widget _amountColumn(String label, double amount, {bool isBalance = false}) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
            fontSize: 25,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '${amount.abs().toStringAsFixed(2)}',
          style: GoogleFonts.inter(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color:
                isBalance && amount != 0
                    ? Colors.indigo.shade500
                    : Colors.black,
          ),
        ),
      ],
    );
  }

  // Widget _buildPaymentOptions() {
  //   return Column(
  //     children: [
  //       Row(
  //         crossAxisAlignment: CrossAxisAlignment.center,
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children:
  //             paymentMethods.map((method) {
  //               final isSelected = selectedMethod == method;
  //               return Container(
  //                 height: MediaQuery.of(context).size.height * 0.07,
  //                 width: MediaQuery.of(context).size.width * 0.08,
  //                 color: Colors.amber,
  //               );
  //             }).toList(),
  //       ),
  //       if (selectedMethod == 'EFTPOS') ...[
  //         SizedBox(height: 20),
  //         Obx(() {
  //           final controller = Get.find<CheckoutController>();
  //           return Column(
  //             children: [
  //               if (controller.isProcessingPayment.value)
  //                 CircularProgressIndicator(),
  //               if (controller.paymentStatus.value.isNotEmpty)
  //                 Padding(
  //                   padding: const EdgeInsets.symmetric(vertical: 8.0),
  //                   child: Text(
  //                     controller.paymentStatus.value,
  //                     style: GoogleFonts.inter(
  //                       fontSize: 14,
  //                       color:
  //                           controller.paymentStatus.value.contains('failed')
  //                               ? Colors.red
  //                               : Colors.green,
  //                     ),
  //                   ),
  //                 ),
  //             ],
  //           );
  //         }),
  //       ],
  //     ),
  //   );
  // }
  Widget _buildAmountSelector() {
    final List<String> row1 = ['\$10', '\$20', '\$50'];
    final List<String> row2 = ['\$100', 'Exact', 'Custom'];

    Widget buildAmountButton(String amount) {
      final bool isSelected = amount == selectedAmount;

      return GestureDetector(
        onTap: () async {
          setState(() {
            selectedAmount = amount;
          });

          // Safely parse numeric values
          if (amount.startsWith('\$')) {
            final parsed = double.tryParse(amount.replaceAll('\$', ''));
            if (parsed != null) {
              _addPayment(parsed); // Your custom function
            }
          } else if (amount == 'Custom') {
            await _showCustomAmountDialog();
            setState(() {}); // Rebuild to reflect updated totalPaid
          } else if (amount == 'Exact') {
            setState(() {
              totalPaid = widget.billAmount - discountAmount;
              customAmountString =
                  (widget.billAmount - discountAmount).toString();
            });
          }
        },
        child: Container(
          width: MediaQuery.of(context).size.width / 5.7,
          height: MediaQuery.of(context).size.height * .08,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF0F4FF) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  isSelected ? const Color(0xFF6366F1) : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            amount,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.indigo.shade500 : Colors.grey.shade700,
              fontSize: 25,
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10, top: 10, right: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  row1
                      .map(
                        (amount) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: buildAmountButton(amount),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  row2
                      .map(
                        (amount) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: buildAmountButton(amount),
                        ),
                      )
                      .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashButtons() {
    final cashAmounts = ['\$10', '\$20', '\$50', '\$100', 'Exact', 'Custom'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ...cashAmounts.map(
              (amt) => ElevatedButton(
                onPressed: () => _addPayment(double.parse(amt)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(50, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade300, width: 2),
                  ),
                ),
                child: Text(
                  '\$$amt',
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade800,
                    fontSize: 25,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedMethod = 'CASH';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                minimumSize: Size(50, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              child: Text(
                'Custom',
                style: GoogleFonts.inter(
                  color: Colors.grey.shade800,
                  fontSize: 25,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),

        // SizedBox(height: 16),
        // ...keys.map((key) {
        //   return Padding(
        //     padding: const EdgeInsets.symmetric(vertical: 4),
        //     child: GestureDetector(
        //       onTap: () {
        //         setState(() {
        //           if (key == '⌫') {
        //             if (customAmountString.isNotEmpty) {
        //               customAmountString = customAmountString
        //                   .substring(
        //                     0,
        //                     customAmountString.length - 1,
        //                   );
        //             }
        //           } else if (key == '.') {
        //             if (!customAmountString.contains('.')) {
        //               customAmountString += '.';
        //             }
        //           } else {
        //             if (customAmountString == '0') {
        //               customAmountString = key; // replace initial 0
        //             } else {
        //               customAmountString += key;
        //             }
        //           }

        //           totalPaid =
        //               double.tryParse(customAmountString) ?? 0.0;
        //         });
        //       },
        //       child: Container(
        //         width: 100,
        //         height: 60,
        //         alignment: Alignment.center,
        //         decoration: BoxDecoration(
        //           border: Border.all(color: Colors.grey.shade300),
        //           borderRadius: BorderRadius.circular(10),
        //           color: Colors.white,
        //         ),
        //         child:
        //             key == '⌫'
        //                 ? const Icon(Icons.backspace_outlined)
        //                 : Text(
        //                   key,
        //                   style: GoogleFonts.inter(
        //                     fontSize: 24,
        //                     fontWeight: FontWeight.w500,
        //                   ),
        //                 ),
        //       ),
        //     ),
        //   );
        // }).toList(),
      ],
    );
  }

  Future<void> _showCustomAmountDialog() async {
    String input = '';
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void onKeyTap(String key) {
              setState(() {
                if (key == '⌫') {
                  if (input.isNotEmpty) {
                    input = input.substring(0, input.length - 1);
                  }
                } else if (key == '.') {
                  if (!input.contains('.')) {
                    input += '.';
                  }
                } else {
                  if (input == '0') {
                    input = key;
                  } else {
                    input += key;
                  }
                }
              });
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text(
                'Enter Amount',
                style: GoogleFonts.inter(
                  color: Colors.grey.shade700,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height * .05,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.grey.shade100,
                    ),
                    child: Text(
                      input.isEmpty ? '0' : input,
                      style: GoogleFonts.inter(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * .50,
                    width: MediaQuery.of(context).size.width * .30,
                    child: GridView.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.5,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        ...[
                          '1',
                          '2',
                          '3',
                          '4',
                          '5',
                          '6',
                          '7',
                          '8',
                          '9',
                          '.',
                          '0',
                          '⌫',
                        ].map(
                          (key) => SizedBox(
                            height: MediaQuery.of(context).size.height / 2,
                            child: ElevatedButton(
                              onPressed: () => onKeyTap(key),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                backgroundColor: Colors.grey[200],
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child:
                                  key == '⌫'
                                      ? const Icon(
                                        Icons.backspace_outlined,
                                        size: 25,
                                      )
                                      : Text(
                                        key,
                                        style: GoogleFonts.inter(
                                          fontSize: 25,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 90,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    final parsed = double.tryParse(input);
                    if (parsed != null && parsed > 0) {
                      print(parsed);
                      setState(() {
                        totalPaid = parsed;
                        customAmountString = parsed.toString();
                      });
                      Navigator.of(context).pop();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 100,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade500,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Text(
                      'Ok',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool?> _showCancelBookingDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Center(
            child: Text(
              'Cancel Booking',

              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
          ),
          content: Text(
            'Are you sure you want to cancel the booking? \nAll entered details will be cleared.',
            style: GoogleFonts.inter(fontSize: 22),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'No',
                style: GoogleFonts.inter(
                  fontSize: 25,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Clear all booking details
                newBookingController.clearSelectedSlots();
                newBookingController.mobileNumberController.clear();
                newBookingController.nameController.clear();
                newBookingController.serviceController.clear();
                newBookingController.bookingdateController.clear();
                notesController.clear();
                promoCodeController.clear();
                paidAmountController.clear();
                balanceAmountController.clear();
                setState(() {
                  totalPaid = 0.0;
                  customAmountString = '';
                  selectedAmount = '';
                  selectedMethod = 'CASH';
                  discountAmount = 0.0;
                  isDiscountApplied = false;
                  receiptToggle = true;
                });
                // Ensure UI refresh before navigating away
                setState(() {});
                Navigator.of(context).pop(); // Close dialog
                Navigator.pop(context); // Return to booking screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Yes',
                style: GoogleFonts.inter(
                  fontSize: 25,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
