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
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/getx_binding.dart';
import '../../config/constants.dart';
import '../../config/palette.dart';
import '../../controllers/checkout_controller.dart';
import '../../controllers/customer_controller.dart';
import '../../controllers/new_booking_controller.dart';
import '../../controllers/default_controller.dart';
import '../../controllers/cart_controller.dart' as cart;
import '../../controllers/membership_controller.dart';
import '../../models/booking_model.dart';
import '../../widgets/number_pad_widget.dart';

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
  final String? forpayment;
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
    this.exuserId,
    required this.forpayment,
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
  final cart.CartController cartController = Get.put(cart.CartController());
  final MembershipController membershipController = Get.put(MembershipController());

  TextEditingController notesController = TextEditingController();
  TextEditingController promoCodeController = TextEditingController();

  TextEditingController paidAmountController = TextEditingController();
  TextEditingController balanceAmountController = TextEditingController();

  // String? _selectedPaymentType = 'Credit Card';
  bool receiptToggle = false;
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

  // Manual discount state
  double manualDiscountAmount = 0.0;
  bool isManualDiscountApplied = false;
  TextEditingController discountController = TextEditingController();
  String manualDiscountType = 'flat'; // 'flat' or 'percentage'
  double manualDiscountValue = 0.0; // The raw value entered (e.g., 10 for 10% or $10)
  bool isManualBookingOnlyDiscount = false; // Whether manual discount applies only to booking
  
  // Membership discount state
  double membershipDiscountAmount = 0.0;
  bool isMembershipDiscountApplied = false;
  
  // Combined discount for display
  double get discountAmount => manualDiscountAmount + membershipDiscountAmount;
  bool get isDiscountApplied => isManualDiscountApplied || isMembershipDiscountApplied;

  // Local membership state
  late bool isMembershipApplied;
  String? selectedMembershipId;
  String? selectedMembershipName;
  double? selectedMembershipPrice;
  double? selectedMembershipPeakPrice;
  double? selectedMembershipNonPeakPrice;
  
  // Slide panel state
  bool _isMembershipPanelOpen = false;

  double get cartItemsTotal => cartItems.fold(0,(sum, item) => sum + double.parse(item.product.price) * item.quantity,);
  
  // Calculate the actual total including bookings, cart items, and membership
  double get actualTotal {
    double total = widget.billAmount + cartItemsTotal;
    if (isMembershipApplied && selectedMembershipPrice != null) {
      total += selectedMembershipPrice!;
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    
    // Initialize membership state from widget
    // Only apply membership if it has a valid name and price
    if (widget.membershipName != null && 
        widget.membershipName!.isNotEmpty && 
        widget.membershipPrice != null && 
        widget.membershipPrice! > 0) {
      isMembershipApplied = widget.isMembershipApplied ?? false;
      selectedMembershipId = widget.membershipID;
      selectedMembershipName = widget.membershipName;
      selectedMembershipPrice = widget.membershipPrice;
    } else {
      // No valid membership data, ensure it's cleared
      isMembershipApplied = false;
      selectedMembershipId = null;
      selectedMembershipName = null;
      selectedMembershipPrice = null;
    }
    
    // Reset discount states on init
    membershipDiscountAmount = 0.0;
    isMembershipDiscountApplied = false;
    manualDiscountAmount = 0.0;
    isManualDiscountApplied = false;
    
    _loadCartItems();
    
    for (var booking in widget.bookings) {
      groupedBookings.putIfAbsent(booking.courtName, () => []).add(booking);
    }
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
    _showCancelBookingDialog();
  }
  
  void showCancelBookingConfirmationDialog_old() {
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
                  // Clear all booking and cart state
                  newBookingController.clearSelectedSlots();
                  cartController.clearCart();
                  
                  // Reset any other state that might be stuck
                  newBookingController.mobileNumberController.clear();
                  newBookingController.nameController.clear();
                  newBookingController.selectedService.value = '';
                  newBookingController.selectedServiceId.value = '';
                  newBookingController.isLoading.value = false;  // Reset loading state
                  newBookingController.checkout.value = false;  // Reset checkout state
                  newBookingController.confirmBtn.value = false;  // Reset confirm button state
                  newBookingController.courtChangeBtn.value = false;  // Reset court change button
                  newBookingController.cancelBookingbtn.value = false;  // Reset cancel button
                  newBookingController.selectedCourtSlots.clear();  // Clear slots again
                  newBookingController.selectedCourt.value = null;  // Clear court
                  newBookingController.update();
                  
                  // Reset checkout controller state
                  final checkoutController = Get.find<CheckoutController>();
                  checkoutController.checkoutPayBtn.value = false;
                  checkoutController.isLoading.value = false;
                  checkoutController.update();
                  
                  // Reset customer controller state if exists
                  try {
                    final customerController = Get.find<CustomerController>();
                    customerController.isLoading.value = false;
                    customerController.update();
                  } catch (e) {
                    // CustomerController might not be initialized
                  }
                  
                  final defaultController = Get.find<DefaultController>();
                  defaultController.tabIndex.value = 0;
                  defaultController.dashboardTabController?.index = 0;
                  
                  // Force clean navigation with a small delay to ensure state is cleared
                  Future.delayed(Duration(milliseconds: 100), () {
                    Get.offAllNamed('/');
                  });
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
  
  String _getDiscountDisplayText() {
    if (isMembershipDiscountApplied && isManualDiscountApplied) {
      return 'Membership + Manual Discount';
    } else if (isMembershipDiscountApplied) {
      return 'Membership Discount Applied';
    } else if (isManualDiscountApplied) {
      return 'Discount Applied';
    }
    return '';
  }
  
  void _updateMembershipColors() {
    // Use selected membership name if available, otherwise use widget membership name
    final membershipName = selectedMembershipName ?? widget.membershipName ?? '';
    
    if (membershipName.toString().toLowerCase().contains('gold')) {
      borderColor = Colors.amber.shade500;
      backgroundColor = Colors.amber.shade50;
      textColor = Colors.amber.shade800;
    } else if (membershipName.toString().toLowerCase().contains('silver')) {
      borderColor = Colors.grey.shade500;
      backgroundColor = Colors.grey.shade100;
      textColor = Colors.grey.shade800;
    } else if (membershipName.toString().toLowerCase().contains('bronze')) {
      borderColor = Colors.orange.shade500;
      backgroundColor = Colors.orange.shade50;
      textColor = Colors.orange.shade800;
    } else if (membershipName.toString().toLowerCase().contains('platinum')) {
      borderColor = Colors.indigo.shade500;
      backgroundColor = Colors.indigo.shade50;
      textColor = Colors.indigo.shade700;
    } else {
      borderColor = Colors.blue.shade500;
      backgroundColor = Colors.blue.shade50;
      textColor = Colors.blue.shade800;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    _updateMembershipColors();
    return GetBuilder(
      init: CheckoutController(),
      builder: (controller) {
        return WillPopScope(
          onWillPop: () async {
            // Clear cart when going back
            cartController.clearCart();
            return true;
          },
          child: Scaffold(
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
                      onPressed: () {
                        // Clear cart when going back
                        cartController.clearCart();
                        Get.back(result: true);
                      },
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
          body: Stack(
            children: [
              // Main content
              SingleChildScrollView(
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
              
              // Overlay when panel is open (must come before panel in stack)
              if (_isMembershipPanelOpen)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isMembershipPanelOpen = false;
                      });
                    },
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ),
                ),
              
              // Slide-in membership panel (must come after overlay in stack)
              AnimatedPositioned(
                duration: Duration(milliseconds: 300),
                right: _isMembershipPanelOpen ? 0 : -500,
                top: 0,
                bottom: 0,
                width: 500,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(-5, 0),
                      ),
                    ],
                  ),
                  child: _buildMembershipPanel(),
                ),
              ),
            ],
          ),
        ),  // End of Scaffold
        );  // End of WillPopScope
      },  // End of GetBuilder builder
    );  // End of GetBuilder
  }  // End of build method

  // Add this function to CheckoutController

  void populateCartWithSubSlots(List<BookingInfo> bookings) {
    newBookingController.cartItems.clear(); // Clear any existing items

    for (final bookingInfo in bookings) {
      final courtId =
          newBookingController.courtList.firstWhere(
            (court) => court['name'] == bookingInfo.courtName,
            orElse: () => {},
          )?['id']; // Find the court ID based on the name

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
            Flexible(
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
                    if (isMembershipApplied == true && selectedMembershipName != null) ...[
                      const SizedBox(height: 8),
                      Divider(thickness: 1, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      // Membership item aligned like other items
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: backgroundColor?.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: borderColor ?? Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          spacing: 30,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${selectedMembershipName} Membership',
                                    style: GoogleFonts.inter(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w500,
                                      color: textColor ?? Colors.black,
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
                                'x1',
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
                                '\$${(selectedMembershipPrice ?? 0.0).toStringAsFixed(2)}',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            
                            // Delete membership button
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red.shade600,
                                size: 24,
                              ),
                              onPressed: () {
                                // Show confirmation dialog
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(
                                      'Remove Membership',
                                      style: GoogleFonts.inter(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    content: Text(
                                      'Are you sure you want to remove the ${selectedMembershipName} membership?',
                                      style: GoogleFonts.inter(fontSize: 20),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(
                                          'Cancel',
                                          style: GoogleFonts.inter(fontSize: 20),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          // Remove membership
                                          setState(() {
                                            isMembershipApplied = false;
                                            selectedMembershipId = null;
                                            selectedMembershipName = null;
                                            selectedMembershipPrice = null;
                                            selectedMembershipPeakPrice = null;
                                            selectedMembershipNonPeakPrice = null;
                                            
                                            // Reset colors
                                            _updateMembershipColors();
                                            
                                            // Remove membership discount only
                                            isMembershipDiscountApplied = false;
                                            membershipDiscountAmount = 0.0;
                                            
                                            // Recalculate totals
                                            totalPaid = actualTotal - discountAmount;
                                            paidAmountController.text = totalPaid.toStringAsFixed(2);
                                          });
                                          
                                          Navigator.pop(context);
                                          
                                          // Show success message
                                          showCustomSnackbar(
                                            'Membership Removed',
                                            'Membership has been removed from the booking',
                                            Colors.green,
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red.shade600,
                                        ),
                                        child: Text(
                                          'Remove',
                                          style: GoogleFonts.inter(
                                            fontSize: 20,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Add Membership button when no membership is applied
                    if (!isMembershipApplied) ...[
                      const SizedBox(height: 8),
                      Divider(thickness: 1, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            print('Opening membership panel...');
                            setState(() {
                              _isMembershipPanelOpen = true;
                            });
                            membershipController.fetchMembershipPlanDetails();
                          },
                          icon: Icon(Icons.card_membership, size: 24),
                          label: Text(
                            'Add Membership',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
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
                              
                              // Space for delete button
                              SizedBox(width: 48),
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
                                    
                                    // Delete button
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: Colors.red.shade600,
                                        size: 24,
                                      ),
                                      onPressed: () {
                                        // Show confirmation dialog
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(
                                              'Remove Item',
                                              style: GoogleFonts.inter(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            content: Text(
                                              'Are you sure you want to remove ${item.product.name} from cart?',
                                              style: GoogleFonts.inter(fontSize: 20),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: Text(
                                                  'Cancel',
                                                  style: GoogleFonts.inter(fontSize: 20),
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  // Update cart in controller first
                                                  // Find the matching item in the controller's cart
                                                  final controllerItem = cartController.cartItems.firstWhere(
                                                    (controllerCartItem) => controllerCartItem.product.id == item.product.id,
                                                  );
                                                  cartController.removeItem(controllerItem);
                                                  
                                                  // Remove item from cart and recalculate totals
                                                  setState(() {
                                                    cartItems.removeWhere((cartItem) => 
                                                      cartItem.product.id == item.product.id
                                                    );
                                                    
                                                    // Recalculate manual discount if it's not booking-only
                                                    if (!isManualBookingOnlyDiscount && manualDiscountValue > 0) {
                                                      if (manualDiscountType == 'percentage') {
                                                        // Recalculate percentage discount based on new cart total
                                                        manualDiscountAmount = cartItemsTotal * (manualDiscountValue / 100);
                                                      }
                                                      // For flat discount, the amount stays the same
                                                    }
                                                    
                                                    // Update payment controllers
                                                    totalPaid = (actualTotal - discountAmount);
                                                    paidAmountController.text = totalPaid.toStringAsFixed(2);
                                                    balanceAmountController.text = '0.00';
                                                  });
                                                  
                                                  // Close dialog
                                                  Navigator.pop(context);
                                                  
                                                  // Show success message
                                                  showCustomSnackbar(
                                                    'Item Removed',
                                                    '${item.product.name} has been removed from cart',
                                                    Colors.green,
                                                  );
                                                  
                                                  // If cart is now empty and no bookings, go back
                                                  if (cartItems.isEmpty && widget.bookings.isEmpty) {
                                                    Navigator.pop(context);
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red.shade600,
                                                ),
                                                child: Text(
                                                  'Remove',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 20,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
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
                // Subtotal (excluding GST)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal (ex GST)',
                      style: GoogleFonts.inter(
                        fontSize: 25,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '\$${(actualTotal - actualTotal / 11).toStringAsFixed(2)}',
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
                      'Total (GST Inc)',
                      style: GoogleFonts.inter(
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '\$${(actualTotal).toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (isDiscountApplied) const SizedBox(height: 4),
                if (isMembershipDiscountApplied)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Membership Discount',
                        style: GoogleFonts.inter(
                          fontSize: 25,
                          color: Colors.green.shade600,
                        ),
                      ),
                      Text(
                        '-\$${(membershipDiscountAmount).toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 25,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                if (isMembershipDiscountApplied && isManualDiscountApplied) 
                  const SizedBox(height: 4),
                if (isManualDiscountApplied)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Manual Discount',
                        style: GoogleFonts.inter(
                          fontSize: 25,
                          color: Colors.red.shade600,
                        ),
                      ),
                      Text(
                        '-\$${(manualDiscountAmount).toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 25,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'GST Included',
                      style: GoogleFonts.inter(
                        fontSize: 25,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '\$${((actualTotal - discountAmount) / 11).toStringAsFixed(2)}',
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
                      '\$${(actualTotal - discountAmount).toStringAsFixed(2)}',
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
                                totalPaid = actualTotal - discountAmount;
                                customAmountString =
                                    (actualTotal - discountAmount)
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
                                totalPaid = actualTotal - discountAmount;
                                customAmountString =
                                    (actualTotal - discountAmount)
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
                          // Discount buttons - always show for admin override capability
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
                                  _getDiscountDisplayText(),
                                  style: GoogleFonts.inter(
                                    color: Colors.indigo.shade500,
                                    fontWeight: FontWeight.w600,
                                    fontSize: _getDiscountDisplayText().length > 20 ? 20 : 25,
                                  ),
                                ),
                              ),
                            ),
                          if (isDiscountApplied) const SizedBox(width: 12),

                          // Remove Manual Discount
                          if (isManualDiscountApplied)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    manualDiscountAmount = 0.0;
                                    isManualDiscountApplied = false;
                                    manualDiscountType = 'flat';
                                    manualDiscountValue = 0.0;
                                    isManualBookingOnlyDiscount = false;
                                    discountController.clear();
                                    // Don't clear notes - they might be needed
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
                                  'Remove Manual Discount',
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
                  spacing: 20,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final result = await _showCancelBookingDialog();
                          if (result == true) {
                            // User cancelled, so clear selection here
                            controller.clearSelectedSlots();
                            // Also clear cart items
                            Get.find<cart.CartController>().clearCart();
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
                    if(widget.forpayment=='new-booking-payment' ) ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {

                            if (controller.userData.value.id != null) {
                              populateCartWithSubSlots(widget.bookings);
                              controller.processCheckout(
                                name: controller.nameController.text,
                                email: controller.userData.value.email,
                                mobile: controller.userData.value.mobile,
                                bookingId: controller.bookingId,
                                paymentType: 'Pending', // Set payment type as Pending
                                promoCode: '',
                                notes: 'Payment pending - Pay Later option selected',
                                bookings: widget.bookings,
                              );
                              Navigator.pop(context);
                            } else {
                              // Create new user and then create booking with pending payment
                              controller.registerUser(
                                mobile: widget.mobileno,
                                firstName: widget.customerName,
                              ).then((value) {
                                // Create booking with pending payment
                                populateCartWithSubSlots(widget.bookings);
                                controller.processCheckout(
                                  name: controller.nameController.text,
                                  email: controller.userData.value.email,
                                  mobile: controller.userData.value.mobile,
                                  paymentType: 'Pending', // Set payment type as Pending
                                  promoCode: '',
                                  notes: 'Payment pending - Pay Later option selected',
                                  bookingId: controller.bookingId,
                                  bookings: widget.bookings,
                                );
                              });
                              Navigator.pop(context);
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
                            'Pay Later',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 25,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ),
                    ],
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
                                      print(widget.billAmount);
                                      print(discountAmount);
                                      if (double.parse(balanceAmountController.text,) <= 0 && totalPaid >= (actualTotal - discountAmount)) {
                                        setState(() {
                                          checkoutController.checkoutPayBtn.value = true;
                                        });

                                        if (isDiscountApplied) {
                                          // Check if it's only manual discount that needs notes
                                          if (isManualDiscountApplied && (notesController.text == null ||
                                              notesController.text == '' ||
                                              notesController.text.isEmpty)) {
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
                                          // Auto-fill notes for membership discount if not provided
                                          if (isMembershipDiscountApplied && notesController.text.isEmpty) {
                                            notesController.text = 'Membership Discount';
                                          }
                                        }

                                        try {
                                          // Continue with existing payment processing
                                          if (widget.type == 'Membership') {

                                            final prefs = await SharedPreferences.getInstance();
                                            String? paymentDevices = prefs.getString('paymentDevices');
                                            final Map<String, dynamic> paymentDeviceData = jsonDecode(paymentDevices!,);

                                            double? overallTotal  = actualTotal;
                                            final total           = overallTotal;

                                            if (selectedMethod == 'EFTPOS') {

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
                                                  total: total.toDouble(),
                                                  paid: totalPaid,
                                                  balance: double.parse(balanceAmountController.text,),
                                                  isMembershipApplied: isMembershipApplied || (selectedMembershipId != null && selectedMembershipId!.isNotEmpty),
                                                  membershipId: selectedMembershipId ?? '',
                                                );

                                              });

                                            }  else {

                                              await checkoutController.processMembershipPayment(
                                                userId: widget.exuserId,
                                                paymentType: selectedMethod,
                                                notes: notesController.text,
                                                total: total.toDouble(),
                                                paid: totalPaid,
                                                balance: double.parse(balanceAmountController.text,),
                                                isMembershipApplied: widget.isMembershipApplied,
                                                membershipId: selectedMembershipId ?? '',
                                              );

                                            }

                                          } else if (widget.type == 'ExistingBooking') {

                                            final prefs = await SharedPreferences.getInstance();
                                            String? paymentDevices = prefs.getString('paymentDevices');
                                            final Map<String, dynamic> paymentDeviceData = jsonDecode(paymentDevices!,);

                                            double? itemSubTotal  = cartItemsTotal;
                                            double? bookingSubTotal = widget.billAmount - cartItemsTotal;
                                            double? itemTotal;
                                            double? bookingTotal;
                                            double? overallTotal;
                                            
                                            // Calculate booking total with membership discount
                                            bookingTotal = bookingSubTotal - membershipDiscountAmount;
                                            
                                            // Apply manual discount based on its type
                                            if (isManualBookingOnlyDiscount) {
                                              // Manual discount applies only to booking
                                              bookingTotal -= manualDiscountAmount;
                                              itemTotal = cartItemsTotal;
                                            } else {
                                              // Manual discount applies to cart items
                                              itemTotal = cartItemsTotal - manualDiscountAmount;
                                            }
                                            
                                            overallTotal = itemTotal + bookingTotal;

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
                                                    taxes: (itemTotal ?? 0) * 0.1,
                                                    surcharge: 0,
                                                    discount: discountAmount,
                                                    billAmount: itemTotal,
                                                    paidAmount: totalPaid,
                                                    balanceAmount: double.parse(balanceAmountController.text,),
                                                    paymentType: selectedMethod,
                                                    paymentNotes: notesController.text,
                                                    receiptToggle: receiptToggle,
                                                    printBoth: true,
                                                    customerId: widget.exuserId
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
                                                  customerId: widget.exuserId
                                                );
                                              }

                                            }


                                          } else if (widget.type == 'New') {

                                            final prefs = await SharedPreferences.getInstance();
                                            String? paymentDevices = prefs.getString('paymentDevices');
                                            final Map<String, dynamic> paymentDeviceData = jsonDecode(paymentDevices!,);

                                            double? itemSubTotal  = cartItemsTotal;
                                            double? bookingSubTotal = widget.billAmount - cartItemsTotal;
                                            double? itemTotal;
                                            double? bookingTotal;
                                            double? overallTotal;
                                            
                                            // Calculate booking total with membership discount
                                            bookingTotal = bookingSubTotal - membershipDiscountAmount;
                                            
                                            // Apply manual discount based on its type
                                            if (isManualBookingOnlyDiscount) {
                                              // Manual discount applies only to booking
                                              bookingTotal -= manualDiscountAmount;
                                              itemTotal = cartItemsTotal;
                                            } else {
                                              // Manual discount applies to cart items
                                              itemTotal = cartItemsTotal - manualDiscountAmount;
                                            }
                                            
                                            overallTotal = itemTotal + bookingTotal;

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
                                                        membershipId: selectedMembershipId ?? '',
                                                        printReceipt: receiptToggle==true ? orderId=='' ? true : false : false,
                                                        orderId: orderId,
                                                      );

                                                    } else {

                                                      await checkoutController.registerUser(
                                                        mobile: widget.mobileno,
                                                        firstName: widget.customerName,
                                                        membershipId: selectedMembershipId ?? '',
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
                                                          membershipId: selectedMembershipId ?? '',
                                                          printReceipt: receiptToggle==true ? orderId=='' ? true : false : false,
                                                          orderId: orderId,
                                                        );
                                                      });
                                                    }

                                                    if(orderId!=null && orderId!='') {
                                                      checkoutController.productsPayment(
                                                        order_id: orderId,
                                                        price: itemSubTotal,
                                                        taxes: (itemTotal ?? 0) * 0.1,
                                                        surcharge: 0,
                                                        discount: discountAmount,
                                                        billAmount: itemTotal,
                                                        paidAmount: totalPaid,
                                                        balanceAmount: double.parse(balanceAmountController.text,),
                                                        paymentType: selectedMethod,
                                                        paymentNotes: notesController.text,
                                                        receiptToggle: receiptToggle,
                                                        printBoth: true,
                                                        customerId: checkoutController.userData.value.id
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
                                                  isMembershipApplied: isMembershipApplied || (selectedMembershipId != null && selectedMembershipId!.isNotEmpty),
                                                  membershipId: selectedMembershipId ?? '',
                                                  printReceipt: receiptToggle==true ? orderId=='' ? true : false : false,
                                                  orderId: orderId,
                                                );
                                              } else {
                                                await checkoutController.registerUser(
                                                  mobile: widget.mobileno,
                                                  firstName: widget.customerName,
                                                  membershipId: selectedMembershipId ?? '',
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
                                                    membershipId: selectedMembershipId ?? '',
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
                                                  customerId: checkoutController.userData.value.id
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
                                                          ).then((value) async {

                                                            if(widget.exuserId!=null && widget.exuserId!='') {

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
                                                                customerId: widget.exuserId,
                                                              );

                                                            } else {
                                                              await checkoutController.registerUser(
                                                                mobile: widget.mobileno,
                                                                firstName: widget.customerName,
                                                              ).then((userInfo) {

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
                                                                  customerId: checkoutController.userData.value.id,
                                                                );

                                                              });
                                                            }

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
                                                    if(widget.exuserId!=null && widget.exuserId!='') {
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
                                                        customerId: widget.exuserId,
                                                      );
                                                    } else {
                                                      await checkoutController.registerUser(
                                                        mobile: widget.mobileno,
                                                        firstName: widget.customerName,
                                                      ).then((userInfo) {

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
                                                          customerId: checkoutController.userData.value.id,
                                                        );

                                                      });
                                                    }

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
    );  // End of body Column
  }  // End of buildCheckout method

  Future<void> _showDiscountDialog(
    CheckoutController checkoutController,
  ) async {
    print('Enhanced discount dialog called'); // Debug print
    
    // No need to check for membership discount since both can be applied together
    // Manual discounts require admin approval anyway
    
    discountController.clear();
    String discountType = 'flat'; // 'flat' or 'percentage'
    bool isBookingOnly = false;
    double bookingTotal = 0;
    double productTotal = 0;
    
    // Calculate booking total and product total separately
    for (var booking in widget.bookings) {
      bookingTotal += booking.subSlots.fold(0.0, (sum, slot) => sum + slot.price);
    }
    productTotal = cartItems.fold(0, (sum, item) => 
        sum + (double.tryParse(item.product.price) ?? 0) * item.quantity);
    
    // Add membership if applied
    if (isMembershipApplied == true && selectedMembershipPrice != null) {
      productTotal += selectedMembershipPrice!;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              insetPadding: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width * 0.4,
                  maxWidth: MediaQuery.of(context).size.width * 0.4,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Apply Discount',
                        style: GoogleFonts.inter(
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 20),
                      
                      // Breakdown of amounts
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Booking Total:', style: GoogleFonts.inter(fontSize: 20)),
                                Text('\$${bookingTotal.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 20)),
                              ],
                            ),
                            if (productTotal > 0) ...[
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Product Total:', style: GoogleFonts.inter(fontSize: 20)),
                                  Text('\$${productTotal.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 20)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Discount Type Selection
                      Text('Discount Type', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w500)),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text('Flat Fee', style: GoogleFonts.inter(fontSize: 18)),
                              value: 'flat',
                              groupValue: discountType,
                              onChanged: (value) {
                                setState(() {
                                  discountType = value!;
                                  discountController.clear();
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text('Percentage', style: GoogleFonts.inter(fontSize: 18)),
                              value: 'percentage',
                              groupValue: discountType,
                              onChanged: (value) {
                                setState(() {
                                  discountType = value!;
                                  discountController.clear();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      // Apply to booking only checkbox (only show if there are products)
                      if (productTotal > 0)
                        CheckboxListTile(
                          title: Text('Apply to booking only', style: GoogleFonts.inter(fontSize: 18)),
                          subtitle: Text('Discount will not apply to products', style: GoogleFonts.inter(fontSize: 16, color: Colors.grey)),
                          value: isBookingOnly,
                          onChanged: (value) {
                            setState(() {
                              isBookingOnly = value!;
                            });
                          },
                        ),
                      
                      SizedBox(height: 20),
                      
                      // Discount Input
                      TextField(
                        controller: discountController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        decoration: InputDecoration(
                          prefixText: discountType == 'flat' ? '\$' : '',
                          suffixText: discountType == 'percentage' ? '%' : '',
                          border: OutlineInputBorder(),
                          hintText: discountType == 'flat' ? '0.00' : '0',
                          labelText: 'Discount Amount',
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
                                minimumSize: const Size(0, 60),
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
                              onPressed: () async {
                                final enteredValue = double.tryParse(discountController.text) ?? 0.0;
                                if (enteredValue <= 0) {
                                  showCustomSnackbar('Invalid Amount', 'Please enter a valid discount amount', Colors.red);
                                  return;
                                }
                                
                                double calculatedDiscount = 0;
                                double maxDiscount = isBookingOnly ? bookingTotal : actualTotal;
                                
                                if (discountType == 'percentage') {
                                  if (enteredValue > 100) {
                                    showCustomSnackbar('Invalid Percentage', 'Percentage cannot exceed 100%', Colors.red);
                                    return;
                                  }
                                  calculatedDiscount = maxDiscount * (enteredValue / 100);
                                } else {
                                  if (enteredValue > maxDiscount) {
                                    showCustomSnackbar('Invalid Amount', 'Discount cannot exceed \$${maxDiscount.toStringAsFixed(2)}', Colors.red);
                                    return;
                                  }
                                  calculatedDiscount = enteredValue;
                                }
                                
                                // Check if this is a booking discount that needs admin approval
                                bool needsAdminApproval = isBookingOnly || 
                                    (discountType == 'percentage' && enteredValue >= 100 && bookingTotal > 0);
                                
                                if (needsAdminApproval) {
                                  // Show admin PIN dialog
                                  final approved = await _showAdminPinDialog();
                                  print('Admin approval result: $approved');
                                  if (!approved) {
                                    return;
                                  }
                                }
                                
                                print('Applying discount: $calculatedDiscount, type: $discountType, value: $enteredValue');
                                
                                // Update the parent state, not the dialog state
                                this.setState(() {
                                  manualDiscountAmount = calculatedDiscount;
                                  isManualDiscountApplied = true;
                                  manualDiscountType = discountType;
                                  manualDiscountValue = enteredValue;
                                  isManualBookingOnlyDiscount = isBookingOnly;
                                });
                                
                                print('Discount applied: amount=$discountAmount, applied=$isDiscountApplied');
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Palette.newColor,
                                minimumSize: const Size(0, 60),
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

    // Calculate bill amount based on discount type
    final double billAmount;
    if (isManualBookingOnlyDiscount || isMembershipDiscountApplied) {
      // For booking-only discount, the total bill is unchanged for products
      // but reduced for the booking portion
      billAmount = widget.billAmount - discountAmount;
    } else {
      // For regular discount, it's applied to the full amount
      billAmount = widget.billAmount - discountAmount;
    }
    
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
              totalPaid = actualTotal - discountAmount;
              customAmountString =
                  (actualTotal - discountAmount).toString();
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

  Future<bool> _showAdminPinDialog() async {
    TextEditingController pinController = TextEditingController();
    bool isLoading = false;
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.4,
                padding: EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.shieldAlert,
                      size: 60,
                      color: Colors.orange.shade600,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Admin Approval Required',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Please enter the 4-digit admin PIN',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 30),
                    // PIN Code Field
                    Container(
                      width: 250,
                      child: PinCodeTextField(
                        controller: pinController,
                        appContext: context,
                        length: 4,
                        obscureText: true,
                        obscuringCharacter: '●',
                        blinkWhenObscuring: false,
                        animationType: AnimationType.fade,
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(8),
                          fieldHeight: 60,
                          fieldWidth: 50,
                          activeFillColor: Colors.white,
                          selectedFillColor: Colors.grey.shade100,
                          inactiveFillColor: Colors.grey.shade100,
                          activeColor: Palette.newColor,
                          selectedColor: Palette.newColor,
                          inactiveColor: Colors.grey.shade300,
                        ),
                        cursorColor: Colors.black,
                        animationDuration: const Duration(milliseconds: 300),
                        enableActiveFill: true,
                        keyboardType: TextInputType.none,
                        onCompleted: (value) async {
                          setState(() {
                            isLoading = true;
                          });
                          
                          try {
                            final prefs = await SharedPreferences.getInstance();
                            String? centerSlug = prefs.getString('centerSlug');
                            
                            final response = await Supabase.instance.client
                                .schema('${centerSlug}_prod_schema')
                                .from('store_details')
                                .select('admin_pin')
                                .single();
                            
                            final adminPin = response['admin_pin']?.toString() ?? '1234';
                            
                            if (value == adminPin) {
                              Navigator.of(context).pop(true);
                            } else {
                              setState(() {
                                isLoading = false;
                                pinController.clear();
                              });
                              showCustomSnackbar(
                                'Invalid PIN',
                                'The admin PIN you entered is incorrect',
                                Colors.red,
                              );
                            }
                          } catch (e) {
                            setState(() {
                              isLoading = false;
                              pinController.clear();
                            });
                            print('Error fetching admin PIN: $e');
                            showCustomSnackbar(
                              'Error',
                              'Failed to verify PIN. Please try again.',
                              Colors.red,
                            );
                          }
                        },
                        onChanged: (value) {},
                      ),
                    ),
                    SizedBox(height: 20),
                    if (isLoading)
                      CircularProgressIndicator(color: Palette.newColor)
                    else
                      NumberPadWidget(
                        onNumberTap: (number) {
                          if (pinController.text.length < 4) {
                            setState(() {
                              pinController.text += number;
                            });
                          }
                        },
                        onBackspaceTap: () {
                          setState(() {
                            if (pinController.text.isNotEmpty) {
                              pinController.text = pinController.text.substring(
                                0,
                                pinController.text.length - 1,
                              );
                            }
                          });
                        },
                        submitForm: () async {
                          if (pinController.text.length == 4) {
                            setState(() {
                              isLoading = true;
                            });
                            
                            try {
                              final prefs = await SharedPreferences.getInstance();
                              String? centerSlug = prefs.getString('centerSlug');
                              
                              final response = await Supabase.instance.client
                                  .schema('${centerSlug}_prod_schema')
                                  .from('store_details')
                                  .select('admin_pin')
                                  .single();
                              
                              final adminPin = response['admin_pin']?.toString() ?? '1234';
                              
                              if (pinController.text == adminPin) {
                                Navigator.of(context).pop(true);
                              } else {
                                setState(() {
                                  isLoading = false;
                                  pinController.clear();
                                });
                                showCustomSnackbar(
                                  'Invalid PIN',
                                  'The admin PIN you entered is incorrect',
                                  Colors.red,
                                );
                              }
                            } catch (e) {
                              setState(() {
                                isLoading = false;
                                pinController.clear();
                              });
                              print('Error fetching admin PIN: $e');
                              showCustomSnackbar(
                                'Error',
                                'Failed to verify PIN. Please try again.',
                                Colors.red,
                              );
                            }
                          }
                        },
                      ),
                    SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    return result ?? false;
  }

  Future<bool?> _showCancelBookingDialog() async {
    String title = '';
    String description = '';
    if(widget.forpayment=='product-only') {
      title = 'Cancel Order';
      description = 'Are you sure you want to cancel the order? \nAll entered details will be cleared.';
    } else if(widget.forpayment=='existing-order-payment') {
      title = 'Cancel Payment';
      description = 'Are you sure you want to cancel the payment?';
    } else if(widget.forpayment=='new-booking-payment') {
      title = 'Cancel Booking';
      description = 'Are you sure you want to cancel the booking? \nAll entered details will be cleared.';
    } else if(widget.forpayment=='membership-payment') {
      title = 'Cancel Membership';
      description = 'Are you sure you want to cancel the membership payment? \nAll entered details will be cleared.';
    }
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
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
          ),
          content: Text(
            description,
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
              onPressed: () async {
                // Clear cart when canceling
                cartController.clearCart();
                
                // Clear booking details
                newBookingController.clearSelectedSlots();
                newBookingController.mobileNumberController.clear();
                newBookingController.nameController.clear();
                
                // Close the dialog first
                Navigator.of(context).pop(true);
                
                // Then navigate based on the type
                if (widget.forpayment == 'new-booking-payment') {
                  // For new bookings, go back to court view
                  Navigator.of(context).pop();
                } else {
                  // For other types, go to dashboard
                  final defaultController = Get.find<DefaultController>();
                  defaultController.tabIndex.value = 0;
                  if (defaultController.dashboardTabController != null) {
                    defaultController.dashboardTabController!.index = 0;
                  }
                  // Navigate to root/dashboard
                  Get.offAllNamed('/');
                }
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
  
  Widget _buildMembershipPanel() {
    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Membership Plan',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 28),
                onPressed: () {
                  setState(() {
                    _isMembershipPanelOpen = false;
                  });
                },
              ),
            ],
          ),
        ),
        
        // Membership list
        Expanded(
          child: Obx(() {
            if (membershipController.membershipPlans.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.card_membership, size: 64, color: Colors.grey.shade400),
                    SizedBox(height: 16),
                    Text(
                      'No membership plans available',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              padding: EdgeInsets.all(20),
              itemCount: membershipController.membershipPlans.length,
              itemBuilder: (context, index) {
                final plan = membershipController.membershipPlans[index];
                final planName = plan['name'] ?? '';
                final planPrice = (plan['price'] ?? 0.0).toDouble();
                final planId = plan['id'] ?? '';
                final validDays = plan['valid_days'] ?? 0;
                final discount = plan['discount'] ?? 0;
                final peakPrice = (plan['peak_price'] ?? 0.0).toDouble();
                final nonPeakPrice = (plan['non_peak_price'] ?? 0.0).toDouble();
                
                // Determine color based on plan name
                Color? backgroundColor;
                Color? borderColor;
                Color? textColor;
                IconData planIcon = Icons.card_membership;
                
                if (planName.toString().toLowerCase().contains('gold')) {
                  backgroundColor = Colors.amber.shade50;
                  borderColor = Colors.amber.shade600;
                  textColor = Colors.amber.shade900;
                  planIcon = Icons.workspace_premium;
                } else if (planName.toString().toLowerCase().contains('silver')) {
                  backgroundColor = Colors.grey.shade100;
                  borderColor = Colors.grey.shade600;
                  textColor = Colors.grey.shade800;
                  planIcon = Icons.military_tech;
                } else if (planName.toString().toLowerCase().contains('bronze')) {
                  backgroundColor = Colors.orange.shade50;
                  borderColor = Colors.orange.shade600;
                  textColor = Colors.orange.shade900;
                  planIcon = Icons.shield;
                }
                
                return GestureDetector(
                  onTap: () {
                    print('Membership selected: $planName, Price: $planPrice');
                    
                    // Set selected membership
                    setState(() {
                      isMembershipApplied = true;
                      selectedMembershipId = planId;
                      selectedMembershipName = planName;
                      selectedMembershipPrice = planPrice;
                      selectedMembershipPeakPrice = peakPrice;
                      selectedMembershipNonPeakPrice = nonPeakPrice;
                      
                      // Update colors based on new membership
                      _updateMembershipColors();
                      
                      // Apply membership booking discount automatically
                      // For now, let's use the non-peak price as the discount amount
                      // You can add logic to determine peak vs non-peak based on time/date
                      if (nonPeakPrice > 0 || peakPrice > 0) {
                        isMembershipDiscountApplied = true;
                        // Use non-peak price, or peak price if non-peak is not available
                        membershipDiscountAmount = nonPeakPrice > 0 ? nonPeakPrice : peakPrice;
                      }
                      
                      // Update totals
                      totalPaid = actualTotal - discountAmount;
                      paidAmountController.text = totalPaid.toStringAsFixed(2);
                      
                      // Close panel
                      _isMembershipPanelOpen = false;
                    });
                    
                    // Force update the checkout controller
                    final checkoutController = Get.find<CheckoutController>();
                    checkoutController.update();
                    
                    print('After setState - isMembershipApplied: $isMembershipApplied, Name: $selectedMembershipName');
                    
                    // Show success message
                    showCustomSnackbar(
                      'Membership Added',
                      '$planName membership has been added to the booking',
                      Colors.green,
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 16),
                    child: Material(
                      color: backgroundColor ?? Colors.white,
                      elevation: 2,
                      shadowColor: borderColor?.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor ?? Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  planIcon,
                                  size: 32,
                                  color: textColor ?? Colors.black,
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        planName,
                                        style: GoogleFonts.inter(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: textColor ?? Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                                          SizedBox(width: 4),
                                          Text(
                                            'Valid for $validDays days',
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          if (discount > 0) ...[
                                            SizedBox(width: 16),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade100,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '${discount.toInt()}% OFF',
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green.shade800,
                                                ),
                                              ),
                                            ),
                                          ],
                                          if (nonPeakPrice > 0 || peakPrice > 0) ...[
                                            SizedBox(width: 8),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade100,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Booking Discount: \$${(nonPeakPrice > 0 ? nonPeakPrice : peakPrice).toStringAsFixed(2)}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue.shade800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: (textColor ?? Colors.black).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '\$${planPrice.toStringAsFixed(2)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: textColor ?? Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
  
  Future<void> _showMembershipSelectionDialog() async {
    // Fetch membership plans
    await membershipController.fetchMembershipPlanDetails();
    
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          insetPadding: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 600,
              maxHeight: 500,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select Membership Plan',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: Obx(() {
                      if (membershipController.membershipPlans.isEmpty) {
                        return Center(
                          child: Text(
                            'No membership plans available',
                            style: GoogleFonts.inter(fontSize: 20),
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        itemCount: membershipController.membershipPlans.length,
                        itemBuilder: (context, index) {
                          final plan = membershipController.membershipPlans[index];
                          final planName = plan['name'] ?? '';
                          final planPrice = (plan['price'] ?? 0.0).toDouble();
                          final planId = plan['id'] ?? '';
                          
                          // Determine color based on plan name
                          Color? backgroundColor;
                          Color? borderColor;
                          Color? textColor;
                          
                          if (planName.toString().toLowerCase().contains('gold')) {
                            backgroundColor = Colors.yellow.shade100;
                            borderColor = Colors.yellow.shade700;
                            textColor = Colors.yellow.shade900;
                          } else if (planName.toString().toLowerCase().contains('silver')) {
                            backgroundColor = Colors.grey.shade200;
                            borderColor = Colors.grey.shade600;
                            textColor = Colors.grey.shade800;
                          } else if (planName.toString().toLowerCase().contains('bronze')) {
                            backgroundColor = Colors.orange.shade100;
                            borderColor = Colors.orange.shade700;
                            textColor = Colors.orange.shade900;
                          }
                          
                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: borderColor ?? Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            color: backgroundColor ?? Colors.white,
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              title: Text(
                                planName,
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: textColor ?? Colors.black,
                                ),
                              ),
                              subtitle: Text(
                                'Valid for ${plan['valid_days'] ?? 0} days',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              trailing: Text(
                                '\$${planPrice.toStringAsFixed(2)}',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textColor ?? Colors.black,
                                ),
                              ),
                              onTap: () {
                                // Set selected membership
                                setState(() {
                                  isMembershipApplied = true;
                                  selectedMembershipId = planId;
                                  selectedMembershipName = planName;
                                  selectedMembershipPrice = planPrice;
                                  
                                  // Update totals
                                  totalPaid = actualTotal - discountAmount;
                                  paidAmountController.text = totalPaid.toStringAsFixed(2);
                                });
                                
                                Navigator.pop(context);
                                
                                // Show success message
                                showCustomSnackbar(
                                  'Membership Added',
                                  '$planName membership has been added to the booking',
                                  Colors.green,
                                );
                              },
                            ),
                          );
                        },
                      );
                    }),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            color: Colors.grey.shade700,
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
}
