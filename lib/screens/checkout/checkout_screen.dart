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
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';

import '../../config/constants.dart';
import '../../config/palette.dart';
import '../../controllers/checkout_controller.dart';
import '../../controllers/customer_controller.dart';
import '../../controllers/new_booking_controller.dart';
import '../../controllers/default_controller.dart';
import '../../controllers/cart_controller.dart' as cart;
import '../../controllers/membership_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/booking_model.dart';
import '../../widgets/number_pad_widget.dart';

class CheckoutScreen extends StatefulWidget {
  final String type;
  final String customerName;
  final String mobileno;
  final DateTime selectedDateTime;
  final double billAmount;
  final List<BookingInfo> bookings;
  final String? membershipID;
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
    this.membershipID,
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
  final CheckoutController checkoutController = Get.put(CheckoutController());
  final AuthController authController = Get.put(AuthController());
  final supabase = Supabase.instance.client;
  
  bool isLoading = false;

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
  
  // Track if user has existing membership
  bool userHasExistingMembership = false;
  String? existingMembershipName;
  Map<String, dynamic>? existingMembershipPlan;
  String? existingMembershipId;

  double get cartItemsTotal => cartItems.fold(0,(sum, item) => sum + double.parse(item.product.price) * item.quantity,);
  
  // Calculate the actual total including bookings, cart items, and membership
  double get courtBookingTotal {
    double total = 0;
    for (var booking in widget.bookings) {
      for (var subSlot in booking.subSlots) {
        total += subSlot.price;
      }
    }
    return total;
  }

  double get actualTotal {
    double total = courtBookingTotal + cartItemsTotal;
    
    // Add membership fee if applied
    if (isMembershipApplied && selectedMembershipPrice != null) {
      total += selectedMembershipPrice!;
    }
    
    return total;
  }

  // Calculate membership discount based on booking amount
  void _calculateMembershipDiscount() {
    print('_calculateMembershipDiscount called - userHasExistingMembership: $userHasExistingMembership, isMembershipApplied: $isMembershipApplied');
    print('selectedMembershipName: $selectedMembershipName, selectedMembershipPrice: $selectedMembershipPrice');
    print('widget.membershipName: ${widget.membershipName}, widget.isMembershipApplied: ${widget.isMembershipApplied}');
    print('existingMembershipPlan: $existingMembershipPlan');
    
    if (userHasExistingMembership || isMembershipApplied || widget.isMembershipApplied == true) {
      // Calculate discount based on peak_price and non_peak_price
      _calculatePriceBasedDiscount();
    } else {
      print('No membership detected, clearing discount');
      // Clear discount if no membership
      setState(() {
        membershipDiscountAmount = 0.0;
        isMembershipDiscountApplied = false;
      });
    }
  }
  
  void _calculatePriceBasedDiscount() {
    print('Calculating price-based discount using peak/non-peak prices');
    print('existingMembershipPlan: $existingMembershipPlan');
    print('selectedMembershipId: $selectedMembershipId');
    print('existingMembershipId: $existingMembershipId');
    
    // First, we need to get the membership plan details
    final membershipId = selectedMembershipId ?? existingMembershipId;
    if (membershipId == null && existingMembershipPlan == null) {
      print('No membership ID or plan available');
      return;
    }
    
    // Calculate total discount by comparing regular prices with member prices
    double totalDiscount = 0.0;
    
    // Go through each booking slot and calculate the discount
    print('Total bookings: ${widget.bookings.length}');
    for (final booking in widget.bookings) {
      print('Booking court: ${booking.courtName}, subSlots: ${booking.subSlots.length}');
      for (final subSlot in booking.subSlots) {
        final regularPrice = subSlot.price;
        double memberPrice = regularPrice;
        
        print('Processing slot: ${subSlot.startTime}-${subSlot.endTime}, isPeak: ${subSlot.isPeak}, regularPrice: $regularPrice');
        
        // Get the member price based on peak/non-peak
        if (existingMembershipPlan != null) {
          print('Using existing membership plan');
          if (subSlot.isPeak && existingMembershipPlan!['peak_price'] != null) {
            final peakPriceStr = existingMembershipPlan!['peak_price']?.toString() ?? '';
            memberPrice = double.tryParse(peakPriceStr) ?? regularPrice;
            print('Peak price from plan: $peakPriceStr -> $memberPrice');
          } else if (!subSlot.isPeak && existingMembershipPlan!['non_peak_price'] != null) {
            final nonPeakPriceStr = existingMembershipPlan!['non_peak_price']?.toString() ?? '';
            memberPrice = double.tryParse(nonPeakPriceStr) ?? regularPrice;
            print('Non-peak price from plan: $nonPeakPriceStr -> $memberPrice');
          } else {
            print('No matching peak/non-peak price in plan');
          }
          
          // Calculate the discount for this slot
          final slotDiscount = regularPrice - memberPrice;
          if (slotDiscount > 0) {
            totalDiscount += slotDiscount;
            print('✓ Discount applied: $slotDiscount');
          } else {
            print('✗ No discount: memberPrice ($memberPrice) >= regularPrice ($regularPrice)');
          }
        } else {
          print('No existing membership plan available');
        }
      }
    }
    
    // If we still don't have the plan details but have an ID, fetch it
    if (existingMembershipPlan == null && membershipId != null) {
      membershipController.fetchMembershipPlanDetails().then((_) {
        final plan = membershipController.membershipPlans.firstWhere(
          (p) => p['id'] == membershipId,
          orElse: () => {},
        );
        
        if (plan.isNotEmpty) {
          print('Found membership plan: $plan');
          
          // Store peak/non-peak prices
          if (plan['peak_price'] != null) {
            selectedMembershipPeakPrice = double.tryParse(plan['peak_price'].toString());
          }
          if (plan['non_peak_price'] != null) {
            selectedMembershipNonPeakPrice = double.tryParse(plan['non_peak_price'].toString());
          }
          
          // Recalculate discount with the fetched plan
          totalDiscount = 0.0;
          for (final booking in widget.bookings) {
            for (final subSlot in booking.subSlots) {
              final regularPrice = subSlot.price;
              double memberPrice = regularPrice;
              
              if (subSlot.isPeak && selectedMembershipPeakPrice != null) {
                memberPrice = selectedMembershipPeakPrice!;
              } else if (!subSlot.isPeak && selectedMembershipNonPeakPrice != null) {
                memberPrice = selectedMembershipNonPeakPrice!;
              }
              
              final slotDiscount = regularPrice - memberPrice;
              if (slotDiscount > 0) {
                totalDiscount += slotDiscount;
                print('Slot: ${subSlot.startTime}-${subSlot.endTime}, isPeak: ${subSlot.isPeak}, Regular: $regularPrice, Member: $memberPrice, Discount: $slotDiscount');
              }
            }
          }
          
          setState(() {
            membershipDiscountAmount = totalDiscount;
            isMembershipDiscountApplied = totalDiscount > 0;
          });
          print('Total membership discount: $totalDiscount');
        }
      });
    } else {
      setState(() {
        membershipDiscountAmount = totalDiscount;
        isMembershipDiscountApplied = totalDiscount > 0;
      });
      print('Total membership discount: $totalDiscount');
    }
  }
  
  void _applyNameBasedDiscount(String membershipName, double bookingTotal) {
    print('Applying name-based discount for $membershipName');
    
    // Default discounts based on membership tier
    double discountPercentage = 0.0;
    if (membershipName.toLowerCase().contains('platinum')) {
      discountPercentage = 20.0;
    } else if (membershipName.toLowerCase().contains('gold')) {
      discountPercentage = 15.0;
    } else if (membershipName.toLowerCase().contains('silver')) {
      discountPercentage = 10.0;
    } else if (membershipName.toLowerCase().contains('bronze')) {
      discountPercentage = 5.0;
    }
    
    if (discountPercentage > 0 && bookingTotal > 0) {
      final discount = bookingTotal * (discountPercentage / 100);
      print('Applying $discountPercentage% discount on $bookingTotal: $discount');
      setState(() {
        membershipDiscountAmount = discount;
        isMembershipDiscountApplied = true;
      });
    } else {
      print('No discount applied - discountPercentage: $discountPercentage, bookingTotal: $bookingTotal');
    }
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
      // Only set membership ID if it's not null and not empty
      selectedMembershipId = (widget.membershipID != null && widget.membershipID!.isNotEmpty) ? widget.membershipID : null;
      selectedMembershipName = widget.membershipName;
      selectedMembershipPrice = widget.membershipPrice;
      
      // If membership is from widget, we should mark as having membership
      if (isMembershipApplied) {
        userHasExistingMembership = true;
      }
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
    
    // Fetch user data to check for existing membership
    _fetchUserData();
    
    // Calculate membership discount immediately if we have membership from widget
    if (widget.membershipName != null && widget.membershipName!.isNotEmpty) {
      // Calculate immediately for widget-based membership
      _calculateMembershipDiscount();
    } else {
      // Calculate after delay for user-based membership
      Future.delayed(Duration(milliseconds: 500), () {
        _calculateMembershipDiscount();
      });
    }
    
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
    } catch (err) { // Renamed 'e' to 'err'
      print('Error loading cart items: $err');
    }
  }

  Future<void> _clearCartAfterPayment() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('shopping_cart');
  }
  
  void _clearAllStateAfterSuccessfulPayment() {
    // Clear cart items
    cartController.clearCart();
    cartItems.clear();
    
    // Clear booking selections
    newBookingController.clearSelectedSlots();
    newBookingController.cartItems.clear();
    
    // Clear text controllers
    newBookingController.mobileNumberController.clear();
    newBookingController.nameController.clear();
    
    // Reset checkout state
    setState(() {
      totalPaid = 0.0;
      customAmountString = '';
      selectedAmount = '';
    });
    
    print('All state cleared after successful payment');
  }
  
  Future<void> _fetchUserData() async {
    try {
      final SharedPreferences preferences = await SharedPreferences.getInstance();
      String? centerSlug = preferences.getString('centerSlug');
      
      // Get user data by mobile number directly
      final userResponse = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('customers')
          .select('*, membershipplan:membershipplan_id(*)')
          .eq('mobile', widget.mobileno)
          .limit(1)
          .maybeSingle();
      
      if (userResponse != null) {
        // Check if user has existing membership
        final membershipPlanId = userResponse['membershipplan_id'];
        if (membershipPlanId != null && membershipPlanId.toString().isNotEmpty) {
          setState(() {
            userHasExistingMembership = true;
            existingMembershipId = membershipPlanId.toString();
            // Get membership name and details from the joined data
            if (userResponse['membershipplan'] != null) {
              existingMembershipName = userResponse['membershipplan']['name'];
              // Store the full membership plan data for discount calculation
              existingMembershipPlan = userResponse['membershipplan'];
            }
          });
          // Calculate discount after state is updated
          _calculateMembershipDiscount();
        }
      }
    } catch (err) { // Renamed 'e' to 'err'
      print('Error fetching user data: $err');
    }
  }

  void showCancelBookingConfirmationDialog() {
    _showCancelBookingDialog();
  }
  
  Future<String> _getPrinterInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // First, try to migrate printers from storeDetails if needed
      await _migratePrintersIfNeeded(prefs);
      
      final pairedPrintersJson = prefs.getString('paired_printers');
      
      if (pairedPrintersJson == null || pairedPrintersJson.isEmpty) {
        return '';
      }
      
      final List<dynamic> pairedPrinters = jsonDecode(pairedPrintersJson);
      if (pairedPrinters.isEmpty) {
        return '';
      }
      
      // Show all configured printers
      final printerInfo = pairedPrinters.map((p) { // Renamed 'printer' to 'p'
        return '${p['name']} (${p['ip']}:${p['port']})';
      }).join(', ');
      
      return printerInfo;
    } catch (err) { // Renamed 'e' to 'err'
      print('Error getting printer info: $err');
      return 'Error loading printer info';
    }
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
          final List<Map<String, dynamic>> simplePrinters = printers.map((p) { // Renamed 'printer' to 'p'
            return {
              'name': p['name'] ?? 'Unknown Printer',
              'ip': p['ip'] ?? '',
              'port': p['port'] ?? '9100',
            };
          }).toList();
          
          await prefs.setString('paired_printers', jsonEncode(simplePrinters));
          print('Successfully migrated ${simplePrinters.length} printers from storeDetails to paired_printers');
        }
      }
    } catch (err) { // Renamed 'e' to 'err'
      print('Error migrating printers: $err');
    }
  }
  
  Future<void> _testPrint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // First, try to migrate printers from storeDetails if needed
      await _migratePrintersIfNeeded(prefs);
      
      final pairedPrintersJson = prefs.getString('paired_printers');
      
      if (pairedPrintersJson == null || pairedPrintersJson.isEmpty) {
        showCustomSnackbar('Error', 'No printers configured', Colors.red);
        return;
      }
      
      final List<dynamic> pairedPrinters = jsonDecode(pairedPrintersJson);
      if (pairedPrinters.isEmpty) {
        showCustomSnackbar('Error', 'No printers configured', Colors.red);
        return;
      }
      
      // Test print on first printer
      final printerInfo = pairedPrinters[0]; // Renamed 'printer' to 'printerInfo'
      final printerIp = printerInfo['ip'];
      final printerPort = int.parse(printerInfo['port']);
      
      final profile = await CapabilityProfile.load();
      final networkPrinter = NetworkPrinter(PaperSize.mm80, profile);
      final PosPrintResult res = await networkPrinter.connect(printerIp, port: printerPort);
      
      if (res == PosPrintResult.success) {
        // Print test receipt
        networkPrinter.text('=== TEST PRINT ===', styles: PosStyles(align: PosAlign.center, bold: true));
        networkPrinter.text('Printer: ${printerInfo['name']}', styles: PosStyles(align: PosAlign.center));
        networkPrinter.text('IP: $printerIp:$printerPort', styles: PosStyles(align: PosAlign.center));
        networkPrinter.text('Time: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}', styles: PosStyles(align: PosAlign.center));
        networkPrinter.text('Status: Connected Successfully', styles: PosStyles(align: PosAlign.center));
        networkPrinter.feed(2);
        networkPrinter.cut();
        networkPrinter.disconnect();
        
        showCustomSnackbar('Success', 'Test print sent to ${printerInfo['name']}', Colors.green);
      } else {
        showCustomSnackbar('Error', 'Failed to connect to printer: ${res.msg}', Colors.red);
      }
    } catch (err) { // Renamed 'e' to 'err'
      print('Test print error: $err');
      showCustomSnackbar('Error', 'Test print failed: $err', Colors.red);
    }
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
                  } catch (err) { // Renamed 'e' to 'err'
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
    // Use selected membership name if available, otherwise use existing membership, then widget membership name
    final membershipName = selectedMembershipName ?? existingMembershipName ?? widget.membershipName ?? '';
    
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
            // Clear cart and selected slots when going back
            cartController.clearCart();
            newBookingController.clearSelectedSlots();
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
                                buildCartItems(controller),
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
          // authController is not defined in this scope.
          // updatedBy: authController.userId.toString(),
          // userId: authController.userId.toString(),
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

  Widget buildCartItems(CheckoutController checkoutController,) {
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
                            Row(
                              children: [
                                Text(
                                  widget.customerName,
                                  style: GoogleFonts.inter(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                // Show crown icon if user has membership
                                if (userHasExistingMembership || isMembershipApplied) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: backgroundColor ?? Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: borderColor ?? Colors.blue.shade500,
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.workspace_premium,
                                      size: 20,
                                      color: textColor ?? Colors.blue.shade800,
                                    ),
                                  ),
                                ],
                              ],
                            ),
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
                                          // Remove membership using comprehensive clearing method
                                          _clearAllMembershipState();
                                          
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
                      // Add a more prominent Remove Membership button below
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        child: ElevatedButton.icon(
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
                                      // Remove membership using comprehensive clearing method
                                      _clearAllMembershipState();
                                      
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
                          icon: Icon(Icons.remove_circle, size: 24),
                          label: Text(
                            'Remove Membership',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                    
                    // Add Membership button when no membership is applied AND user doesn't have existing membership
                    if (!isMembershipApplied && !userHasExistingMembership) ...[
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
                    Expanded(
                      child: Text(
                        'Subtotal (ex GST)',
                        style: GoogleFonts.inter(
                          fontSize: 25,
                          color: Colors.grey.shade600,
                        ),
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
                    Expanded(
                      child: Text(
                        'Total (GST Inc)',
                        style: GoogleFonts.inter(
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '\$${actualTotal.toStringAsFixed(2)}',
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
                      Expanded(
                        child: Text(
                          'Membership Discount',
                          style: GoogleFonts.inter(
                            fontSize: 25,
                            color: Colors.green.shade600,
                          ),
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
                      Expanded(
                        child: Text(
                          'Manual Discount',
                          style: GoogleFonts.inter(
                            fontSize: 25,
                            color: Colors.red.shade600,
                          ),
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
                    Expanded(
                      child: Text(
                        'GST Included',
                        style: GoogleFonts.inter(
                          fontSize: 25,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Text(
                      '\$${((actualTotal - membershipDiscountAmount - manualDiscountAmount) / 11).toStringAsFixed(2)}',
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
                    Expanded(
                      child: Text(
                        'Grand Total',
                        style: GoogleFonts.inter(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '\$${(actualTotal - membershipDiscountAmount - manualDiscountAmount).toStringAsFixed(2)}',
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

  Widget buildCheckout(
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
                                // For EFTPOS, calculate the amount to be paid (includes membership)
                                double amountToPay = actualTotal - manualDiscountAmount;
                                totalPaid = amountToPay;
                                customAmountString = amountToPay.toString();
                                paidAmountController.text = amountToPay.toStringAsFixed(2);
                                setState(() {
                                  selectedMethod = method['label'];
                                });
                              } else if (method['label'] == 'Cash') {
                                totalPaid = 0.0;
                                customAmountString = '';
                                paidAmountController.text = '0.00';
                                setState(() {
                                  selectedMethod = method['label'];
                                });
                              } else {
                                totalPaid = actualTotal - manualDiscountAmount;
                                customAmountString =
                                    (actualTotal - manualDiscountAmount)
                                        .toString();
                                paidAmountController.text = (actualTotal - manualDiscountAmount).toStringAsFixed(2);
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
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
                                  if (receiptToggle)
                                    FutureBuilder<String>(
                                      future: _getPrinterInfo(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return CircularProgressIndicator();
                                        } else if (snapshot.hasError) {
                                          return Text('Error: ${snapshot.error}');
                                        } else {
                                          return Text(
                                            snapshot.data!.isNotEmpty
                                                ? 'Printer: ${snapshot.data}'
                                                : 'No printer configured',
                                            style: GoogleFonts.inter(
                                              fontSize: 18,
                                              color: snapshot.data!.isNotEmpty ? Colors.green : Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Handle Cancel
                              showCancelBookingConfirmationDialog();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade500,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontSize: 25,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Pay Later button - only show for new bookings or if customer wants to defer payment
                        if (widget.type != 'ExistingBooking' || widget.forpayment != 'individual-court-payment') ...[
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _handlePayLater();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade500,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Pay Later',
                                style: GoogleFonts.inter(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              // Validate payment amount
                              if (totalPaid < (actualTotal - membershipDiscountAmount - manualDiscountAmount)) {
                                showCustomSnackbar(
                                  'Insufficient Payment',
                                  'Please pay the full amount',
                                  Colors.red,
                                );
                                return;
                              }
                              
                              setState(() {
                                checkoutController.checkoutPayBtn.value = true;
                              });
                              
                              // Process the payment based on selected method
                              if (selectedMethod == 'EFTPOS') {
                                // For EFTPOS, process through Tyro
                                try {
                                  final prefs = await SharedPreferences.getInstance();
                                  final storeDetailsJson = prefs.getString('storeDetails');
                                  
                                  if (storeDetailsJson != null) {
                                    final storeDetails = jsonDecode(storeDetailsJson);
                                    final tyroConfig = storeDetails['tyro'] ?? {};
                                    
                                    if (tyroConfig['apiKey'] != null) {
                                      // Process EFTPOS payment
                                      final paymentResult = await paymentController.processPayment(
                                        context: context,
                                        amount: actualTotal - membershipDiscountAmount - manualDiscountAmount,
                                        reference: widget.exbookingId ?? 'NEW-${DateTime.now().millisecondsSinceEpoch}',
                                        apiKey: tyroConfig['apiKey'],
                                        merchantId: tyroConfig['merchantId'] ?? '',
                                        terminalId: tyroConfig['terminalId'] ?? '',
                                        integrationKey: tyroConfig['integrationKey'] ?? '',
                                        posProductVendor: tyroConfig['posProductVendor'] ?? 'Solution22',
                                        posProductName: tyroConfig['posProductName'] ?? 'DropIn Booking',
                                        posProductVersion: tyroConfig['posProductVersion'] ?? '1.0',
                                      );
                                      
                                      if (paymentResult['status'] == 'completed') {
                                        _handlePaymentSuccess();
                                      } else {
                                        setState(() {
                                          checkoutController.checkoutPayBtn.value = false;
                                        });
                                        showCustomSnackbar(
                                          'Payment Failed',
                                          'EFTPOS payment was not successful',
                                          Colors.red,
                                        );
                                      }
                                    } else {
                                      // No Tyro config, fallback to manual
                                      showCustomSnackbar(
                                        'EFTPOS Not Configured',
                                        'Processing as manual payment',
                                        Colors.orange,
                                      );
                                      _handlePaymentSuccess();
                                    }
                                  } else {
                                    // No store details, process as manual
                                    _handlePaymentSuccess();
                                  }
                                } catch (e) {
                                  setState(() {
                                    checkoutController.checkoutPayBtn.value = false;
                                  });
                                  print('EFTPOS payment error: $e');
                                  showCustomSnackbar(
                                    'Payment Error',
                                    'Failed to process EFTPOS payment: $e',
                                    Colors.red,
                                  );
                                }
                              } else {
                                // For Cash and On Account/Void
                                _handlePaymentSuccess();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade500,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Obx(() => checkoutController.checkoutPayBtn.value
                              ? const SizedBox(
                                  height: 30,
                                  width: 30,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : Text(
                                  'Pay Now',
                                  style: GoogleFonts.inter(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildAmountSummary(CheckoutController checkoutController) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Bill Amount Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Bill Amount',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${(actualTotal - membershipDiscountAmount - manualDiscountAmount).toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Divider
          Container(
            height: 40,
            width: 1,
            color: Colors.grey.shade300,
          ),
          
          // Total Paid Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Total Paid',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${totalPaid.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Divider
          Container(
            height: 40,
            width: 1,
            color: Colors.grey.shade300,
          ),
          
          // Balance Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Balance',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${(actualTotal - membershipDiscountAmount - manualDiscountAmount - totalPaid).toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4A90E2), // Nice blue color similar to screenshot
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSelector() {
    final double billAmount = actualTotal - membershipDiscountAmount - manualDiscountAmount;
    
    return Column(
      children: [
        // Quick amount buttons
        Container(
          margin: const EdgeInsets.only(bottom: 16, right: 15),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Amount',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickAmountButton('\$10', 10.0),
                  _buildQuickAmountButton('\$20', 20.0),
                  _buildQuickAmountButton('\$50', 50.0),
                  _buildQuickAmountButton('\$100', 100.0),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickAmountButton('Exact', billAmount),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _showCustomAmountDialog();
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: selectedAmount == 'custom' 
                            ? const Color(0xFFF0F4FF) 
                            : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selectedAmount == 'custom' 
                              ? const Color(0xFF6366F1) 
                              : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Custom',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: selectedAmount == 'custom'
                                ? const Color(0xFF6366F1)
                                : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          totalPaid = 0.0;
                          customAmountString = '';
                          paidAmountController.text = '0.00';
                          selectedAmount = '';
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.shade300,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Clear',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildQuickAmountButton(String label, double amount) {
    // Don't show selected state for amount buttons (only for Exact and Custom)
    final bool isSpecialButton = label == 'Exact' || label == 'Custom';
    final bool isSelected = isSpecialButton && selectedAmount == label;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (label == 'Exact') {
              // For Exact button, set the exact amount
              selectedAmount = label;
              totalPaid = amount;
              customAmountString = amount.toStringAsFixed(2);
              paidAmountController.text = totalPaid.toStringAsFixed(2);
            } else if (label == 'Custom') {
              // Custom button behavior is handled elsewhere
              selectedAmount = label;
            } else {
              // For amount buttons ($10, $20, etc), add to existing amount
              totalPaid += amount;
              customAmountString = totalPaid.toStringAsFixed(2);
              paidAmountController.text = totalPaid.toStringAsFixed(2);
              // Don't change selectedAmount for regular amount buttons
            }
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF0F4FF) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCustomAmountDialog() {
    String tempCustomAmount = totalPaid > 0 ? totalPaid.toStringAsFixed(2) : '';
    // Remove trailing zeros
    if (tempCustomAmount.contains('.')) {
      tempCustomAmount = tempCustomAmount.replaceAll(RegExp(r'\.?0+$'), '');
      if (tempCustomAmount.endsWith('.')) {
        tempCustomAmount = tempCustomAmount.substring(0, tempCustomAmount.length - 1);
      }
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Enter Custom Amount',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      '\$${tempCustomAmount.isEmpty ? '0.00' : (double.tryParse(tempCustomAmount) ?? 0.0).toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 280,
                    width: 300,
                    child: NumberPadWidget(
                      onNumberTap: (value) {
                        setDialogState(() {
                          if (value == '.') {
                            if (!tempCustomAmount.contains('.')) {
                              if (tempCustomAmount.isEmpty) {
                                tempCustomAmount = '0.';
                              } else {
                                tempCustomAmount += value;
                              }
                            }
                          } else {
                            if (tempCustomAmount == '0' && value == '0') {
                              return;
                            }
                            if (tempCustomAmount == '0' && value != '.') {
                              tempCustomAmount = value;
                            } else {
                              if (tempCustomAmount.contains('.')) {
                                final parts = tempCustomAmount.split('.');
                                if (parts.length > 1 && parts[1].length >= 2) {
                                  return;
                                }
                              }
                              tempCustomAmount += value;
                            }
                          }
                        });
                      },
                      onBackspaceTap: () {
                        setDialogState(() {
                          if (tempCustomAmount.isNotEmpty) {
                            tempCustomAmount = tempCustomAmount.substring(0, tempCustomAmount.length - 1);
                          }
                        });
                      },
                      submitForm: () {
                        // Apply the custom amount
                        setState(() {
                          if (tempCustomAmount.isEmpty || tempCustomAmount == '.') {
                            totalPaid = 0.0;
                            customAmountString = '';
                          } else {
                            totalPaid = double.tryParse(tempCustomAmount) ?? 0.0;
                            customAmountString = totalPaid.toStringAsFixed(2);
                          }
                          paidAmountController.text = totalPaid.toStringAsFixed(2);
                          selectedAmount = '';
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (tempCustomAmount.isEmpty || tempCustomAmount == '.') {
                        totalPaid = 0.0;
                        customAmountString = '';
                      } else {
                        totalPaid = double.tryParse(tempCustomAmount) ?? 0.0;
                        customAmountString = totalPaid.toStringAsFixed(2);
                      }
                      paidAmountController.text = totalPaid.toStringAsFixed(2);
                      selectedAmount = '';
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    'Apply',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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

  void _showDiscountDialog(CheckoutController checkoutController) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Apply Discount',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: discountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Discount Value',
                  hintText: 'Enter amount or percentage',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    manualDiscountValue = double.tryParse(value) ?? 0.0;
                    _calculateManualDiscount();
                  });
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Flat'),
                      value: 'flat',
                      groupValue: manualDiscountType,
                      onChanged: (value) {
                        setState(() {
                          manualDiscountType = value!;
                          _calculateManualDiscount();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Percentage'),
                      value: 'percentage',
                      groupValue: manualDiscountType,
                      onChanged: (value) {
                        setState(() {
                          manualDiscountType = value!;
                          _calculateManualDiscount();
                        });
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Checkbox(
                    value: isManualBookingOnlyDiscount,
                    onChanged: (value) {
                      setState(() {
                        isManualBookingOnlyDiscount = value!;
                        _calculateManualDiscount();
                      });
                    },
                  ),
                  Text('Apply to booking only'),
                ],
              ),
              Text('Calculated Discount: \$${manualDiscountAmount.toStringAsFixed(2)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isManualDiscountApplied = manualDiscountAmount > 0;
                });
                Navigator.of(context).pop();
              },
              child: Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  void _calculateManualDiscount() {
    double totalForDiscount = isManualBookingOnlyDiscount ? courtBookingTotal : (courtBookingTotal + cartItemsTotal);
    if (manualDiscountType == 'percentage') {
      manualDiscountAmount = totalForDiscount * (manualDiscountValue / 100);
    } else {
      manualDiscountAmount = manualDiscountValue;
    }
    // Ensure discount doesn't exceed the total
    if (manualDiscountAmount > totalForDiscount) {
      manualDiscountAmount = totalForDiscount;
    }
  }

  void _clearAllMembershipState() {
    setState(() {
      isMembershipApplied = false;
      selectedMembershipId = null;
      selectedMembershipName = null;
      selectedMembershipPrice = null;
      selectedMembershipPeakPrice = null;
      selectedMembershipNonPeakPrice = null;
      membershipDiscountAmount = 0.0;
      isMembershipDiscountApplied = false;
      userHasExistingMembership = false;
      existingMembershipId = null;
      existingMembershipName = null;
    });
  }

  Widget _buildMembershipPanel() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Membership Plans',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isMembershipPanelOpen = false;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (membershipController.isLoading.value) {
              return Center(child: CircularProgressIndicator());
            }
            if (membershipController.membershipPlans.isEmpty) {
              return Center(child: Text('No membership plans available.'));
            }
            return ListView.builder(
              itemCount: membershipController.membershipPlans.length,
              itemBuilder: (context, index) {
                final plan = membershipController.membershipPlans[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan['name'] ?? 'N/A',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Price: \$${(plan['price'] ?? 0.0).toStringAsFixed(2)}',
                          style: GoogleFonts.inter(fontSize: 18),
                        ),
                        if (plan['peak_price'] != null || plan['non_peak_price'] != null) ...[
                          Text(
                            'Member Rates:',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          if (plan['peak_price'] != null)
                            Text(
                              'Peak: \$${plan['peak_price']}',
                              style: GoogleFonts.inter(fontSize: 16),
                            ),
                          if (plan['non_peak_price'] != null)
                            Text(
                              'Off-Peak: \$${plan['non_peak_price']}',
                              style: GoogleFonts.inter(fontSize: 16),
                            ),
                        ] else ...[
                          Text(
                            'Discount: ${plan['discount_value'] ?? 0}${plan['discount_type'] == 'percentage' ? '%' : ''} ${plan['discount_type'] ?? ''}',
                            style: GoogleFonts.inter(fontSize: 18),
                          ),
                        ],
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isMembershipApplied = true;
                              selectedMembershipId = plan['id'];
                              selectedMembershipName = plan['name'];
                              selectedMembershipPrice = (plan['price'] as num?)?.toDouble() ?? 0.0;
                              
                              // Store peak and non-peak prices
                              if (plan['peak_price'] != null) {
                                selectedMembershipPeakPrice = double.tryParse(plan['peak_price'].toString());
                              }
                              if (plan['non_peak_price'] != null) {
                                selectedMembershipNonPeakPrice = double.tryParse(plan['non_peak_price'].toString());
                              }
                              
                              _calculateMembershipDiscount();
                              _isMembershipPanelOpen = false;
                            });
                          },
                          child: Text('Select Plan'),
                        ),
                      ],
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

  void _showCancelBookingDialog() {
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
                  } catch (err) { // Renamed 'e' to 'err'
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

  void showCustomSnackbar(String title, String message, Color color) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: color,
      colorText: Colors.white,
      margin: const EdgeInsets.all(10),
      borderRadius: 10,
      isDismissible: true,
      duration: const Duration(seconds: 3),
    );
  }
  
  void _handlePaymentSuccess() async {
    try {
      setState(() {
        isLoading = true;
      });
      
      final SharedPreferences preferences = await SharedPreferences.getInstance();
      String? centerSlug = preferences.getString('centerSlug');
      
      // Update booking payment status if we have exbookingId
      if (widget.exbookingId != null) {
        // Update booking payment status
        await supabase
            .schema('${centerSlug}_prod_schema')
            .from('bookings')
            .update({
              'payment_status': 'Paid',
              'payment_type': selectedMethod,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', widget.exbookingId!);
            
        print('Updated booking ${widget.exbookingId} payment status to paid');
        
        // Create a booking payment record
        try {
          // Get booking details first
          final bookingData = await supabase
              .schema('${centerSlug}_prod_schema')
              .from('bookings')
              .select('customer_id, grand_total')
              .eq('id', widget.exbookingId!)
              .single();
              
          if (bookingData != null) {
            await supabase
                .schema('${centerSlug}_prod_schema')
                .from('booking_payments')
                .insert({
                  'booking_id': widget.exbookingId,
                  'customer_id': bookingData['customer_id'],
                  'total': bookingData['grand_total'],
                  'paid_amount': totalPaid,
                  'payment_type': selectedMethod,
                  'payment_via': selectedMethod,
                  'status': 'completed',
                  'notes': notesController.text.isNotEmpty ? notesController.text : null,
                  'created_by': authController.userId.value,
                });
            print('Created booking payment record for booking ${widget.exbookingId}');
          }
        } catch (e) {
          print('Warning: Could not create booking_payments record: $e');
        }
        
        // Update all booking slots payment status
        try {
          await supabase
              .schema('${centerSlug}_prod_schema')
              .from('booking_slots')
              .update({
                'payment_status': 'Paid',
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('booking_id', widget.exbookingId!);
          print('Updated booking slots payment status for booking ${widget.exbookingId}');
        } catch (e) {
          print('Warning: Could not update booking_slots: $e');
        }
        
        // If there's a membership associated with this booking, update its status
        final bookingData = await supabase
            .schema('${centerSlug}_prod_schema')
            .from('bookings')
            .select('customer_id')
            .eq('id', widget.exbookingId!)
            .single();
            
        if (bookingData != null && bookingData['customer_id'] != null) {
          // Check if customer has a pending membership in membership_data
          final membershipData = await supabase
              .schema('${centerSlug}_prod_schema')
              .from('membership_data')
              .select('*')
              .eq('customer_id', bookingData['customer_id'])
              .eq('status', false) // status is boolean, false means pending
              .maybeSingle();
              
          if (membershipData != null) {
            try {
              // Update membership status to active
              await supabase
                  .schema('${centerSlug}_prod_schema')
                  .from('membership_data')
                  .update({
                    'status': true, // true means active
                  })
                  .eq('id', membershipData['id']);
                  
              print('Updated membership_data ${membershipData['id']} to active');
              
              // Update customer's membership_data_id if needed
              await supabase
                  .schema('${centerSlug}_prod_schema')
                  .from('customers')
                  .update({
                    'membership_data_id': membershipData['id'],
                    'membershipplan_id': membershipData['membershipplan_id'],
                  })
                  .eq('id', bookingData['customer_id']);
                  
              print('Updated customer ${bookingData['customer_id']} membership references');
              
              // Create membership payment record
              try {
                await supabase
                    .schema('${centerSlug}_prod_schema')
                    .from('membershippayment')
                    .insert({
                      'membershipid': membershipData['id'],
                      'paymenttype': selectedMethod,
                      'total': double.tryParse(membershipData['price'] ?? '0') ?? 0.0,
                      'paidamount': double.tryParse(membershipData['price'] ?? '0') ?? 0.0,
                      'status': true,
                      'notes': 'Membership payment processed with booking ${widget.exbookingId}',
                    });
                print('Created membership payment record for membership ${membershipData['id']}');
              } catch (e) {
                print('Warning: Could not create membership payment record: $e');
              }
            } catch (e) {
              print('Warning: Could not update membership_data: $e');
            }
          }
        }
      }
      
      // Update order payment status if we have exorderId  
      if (widget.exorderId != null) {
        try {
          await supabase
              .schema('${centerSlug}_prod_schema')
              .from('orders')
              .update({
                'payment_status': 'Paid',
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', widget.exorderId!);
              
          print('Updated order ${widget.exorderId} payment status to paid');
        } catch (e) {
          print('Warning: Could not update order: $e');
        }
      }
      
      // If this is a new booking (not from pending payment)
      if (widget.exbookingId == null && widget.bookings.isNotEmpty) {
        // Create payment record for new booking
        // This should be handled by the booking creation logic
        print('New booking payment - should be handled by booking creation');
      }
      
      setState(() {
        isLoading = false;
        checkoutController.checkoutPayBtn.value = false;
      });
      
      // Clear all state after successful payment
      _clearAllStateAfterSuccessfulPayment();
      
      // Clear the cart
      await _clearCartAfterPayment();
      
      // Show success dialog
      newBookingController.showBookingSuccessAlert();
      
      // Wait for dialog to be visible
      await Future.delayed(const Duration(seconds: 2));
      
      // Navigate to dashboard
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/dashboard',
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      setState(() {
        isLoading = false;
        checkoutController.checkoutPayBtn.value = false;
      });
      print('Error handling payment success: $e');
      showCustomSnackbar(
        'Error',
        'Payment successful but error occurred: $e',
        Colors.orange,
      );
    }
  }
  
  void _handlePayLater() async {
    // Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirm Pay Later',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.type == 'ExistingBooking' 
                  ? 'This booking will remain in the unpaid list. The customer can pay later at their convenience.'
                  : 'The booking will be confirmed but payment will be pending. You can collect payment later.',
                style: GoogleFonts.inter(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Amount pending: \$${(actualTotal - membershipDiscountAmount - manualDiscountAmount).toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade500,
              ),
              child: Text(
                'Confirm Pay Later',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
    
    if (confirmed == true) {
      try {
        setState(() {
          isLoading = true;
        });
        
        // For existing bookings, just navigate back without changing payment status
        if (widget.type == 'ExistingBooking') {
          showCustomSnackbar(
            'Pay Later',
            'Booking remains unpaid. Customer can pay later.',
            Colors.orange,
          );
          
          // Navigate back to dashboard after a short delay
          await Future.delayed(const Duration(seconds: 1));
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/dashboard',
            (Route<dynamic> route) => false,
          );
        } else {
          // For new bookings, we need to process it differently
          // The booking creation happens in new_booking_screen.dart
          // Here we just need to navigate back with a flag indicating pay later
          
          // Clear any payment state
          setState(() {
            totalPaid = 0.0;
            selectedMethod = '';
          });
          
          // Show success message
          showCustomSnackbar(
            'Pay Later Selected',
            'Please complete the booking to save with pending payment',
            Colors.orange,
          );
          
          // Navigate back to the new booking screen with pay later flag
          Navigator.of(context).pop({'payLater': true, 'notes': notesController.text});
        }
        
        setState(() {
          isLoading = false;
        });
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        showCustomSnackbar(
          'Error',
          'Failed to process pay later: $e',
          Colors.red,
        );
      }
    }
  }
}
