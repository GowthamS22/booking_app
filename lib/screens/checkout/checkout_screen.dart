// ignore_for_file: must_be_immutable

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/getx_binding.dart';
import '../../config/constants.dart';
import '../../config/google-fonts.dart';
import '../../config/palette.dart';
import '../../controllers/checkout_controller.dart';
import '../../controllers/customer_controller.dart';
import '../../controllers/new_booking_controller.dart';
import '../../controllers/default_controller.dart';
import '../../models/booking_model.dart';
import '../../widgets/checkout_number_pad.dart';

class CheckoutScreen extends StatefulWidget {
  final String type;
  final String customerName;
  final String mobileno;
  final DateTime selectedDateTime;
  final double billAmount;
  final List<BookingInfo> bookings;
  const CheckoutScreen({
    Key? key,
    required this.type,
    required this.customerName,
    required this.mobileno,
    required this.selectedDateTime,
    required this.billAmount,
    required this.bookings,
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

  TextEditingController notesController = TextEditingController();
  TextEditingController promoCodeController = TextEditingController();

  TextEditingController paidAmountController = TextEditingController();
  TextEditingController balanceAmountController = TextEditingController();

  // String? _selectedPaymentType = 'Credit Card';
  Map<String, List<BookingInfo>> groupedBookings = {};
  double totalPaid = 0.0;
  String customAmountString = '';
  final List<String> paymentMethods = [
    'CASH',
    'EFTPOS',
    'On Account/Void',
    // 'MIXED',
  ];
  String selectedMethod = 'CASH';

  void _addPayment(double amount) {
    setState(() {
      totalPaid += amount;
    });
  }

  List<List<String>> keys = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', '⌫'],
  ];
  @override
  void initState() {
    // TODO: implement initState
    for (var booking in widget.bookings) {
      groupedBookings.putIfAbsent(booking.courtName, () => []).add(booking);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: CheckoutController(),
      builder: (controller) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Scaffold(
            appBar: AppBar(
              elevation: 0,
              toolbarHeight: 80,
              backgroundColor: Colors.white,
              titleSpacing: 0,
              automaticallyImplyLeading: false,
              //leadingWidth: MediaQuery.of(context).size.width / 2.1,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(width: 22 * ffem),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white, // Navy blue
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade500),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
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
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Create new booking based on selected courts',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Items count
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade500),
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.layoutDashboard),
                        SizedBox(width: 5),
                        Text(
                          'Dashboard',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 30),
                ],
              ),
            ),

            backgroundColor: Palette.white,
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Divider(color: Colors.grey.shade300, thickness: 1),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildCartItems(),
                              SizedBox(width: 20),
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
          )?['id']; // Find the court ID based on the name

      if (courtId == null) {
        print('Warning: Could not find court ID for ${bookingInfo.courtName}');
        continue; // Skip if court ID is not found
      }

      for (final subSlotInfo in bookingInfo.subSlots) {
        final individualSlot = BookingSlot(
          serviceId: newBookingController.selectedServiceId.value,
          courtId: courtId,
          startTime: parseDateTime(
            bookingInfo.selectedDateTime,
            subSlotInfo.startTime,
          ),
          endTime: parseDateTime(
            bookingInfo.selectedDateTime,
            subSlotInfo.endTime,
          ),
          price: subSlotInfo.price,
          slotType: null,
          repeatDays: null,
          repeatEnd: bookingInfo.repeatUntil,
          repeatId: null,
          repeatGroupId: null,
          status: 'Selected',
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
        height: MediaQuery.of(context).size.height * .80,
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer Info',
                style: GoogleFonts.inter(
                  color: Palette.black,
                  fontSize: 14,
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
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Gold',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.mobileno,
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade600,
                          fontSize: 14,
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
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('h:mm a').format(widget.selectedDateTime),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),
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
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Time Slots for this Court
                            ...courtBookings.map((booking) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                              fontSize: 14,
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
                                              fontSize: 13,
                                              color:
                                                  subSlot.isPeak
                                                      ? Colors.orange.shade700
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
                                              fontSize: 14,
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

              const SizedBox(height: 16),

              // Cart Items
              ...[
                ['Yung Corck', '12', '25.00'],
                ['Energy Drink', '12', '25.00'],
                ['Protein Bar', '24', '45.00'],
                ['Vegan Snack Mix', '12', '30.00'],
                ['Herbal Tea', '20', '20.00'],
                ['Electrolyte Powder', '10', '15.00'],
                ['Organic Nut Butter', '8', '40.00'],
                ['Chia Seed Pudding', '12', '18.00'],
              ].map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item[0], style: GoogleFonts.inter(fontSize: 14)),
                      Row(
                        children: [
                          Text(
                            'x${item[1]}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '\$${item[2]}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
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
      flex: 2,
      child: ListView(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: [
          Column(
            children: [
              _buildAmountSummary(checkoutController),

              SizedBox(height: 30),
              Container(
                width: MediaQuery.of(context).size.width / 10.0,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade500),
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.edit3),

                    SizedBox(width: 20),
                    Text(
                      'Notes',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: MediaQuery.of(context).size.width / 2.2,

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Payment Methods
                    _buildPaymentOptions(),
                    if (selectedMethod == 'CASH') ...[
                      SizedBox(height: 10),
                      _buildCashButtons(),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle "Pay Now"
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
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
                          fontSize: 16,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (totalPaid != '' && totalPaid > 0) {
                          if (double.parse(balanceAmountController.text) <= 0) {
                            setState(() {
                              checkoutController.checkoutPayBtn.value = true;
                            });

                            if (widget.type == 'Membership') {
                              checkoutController.makeMembershipPayment(
                                userId:
                                    customerController
                                        .selectedPlan[0]['userId'],
                                userMembershipId:
                                    customerController
                                        .selectedPlan[0]['userMembershipId'],
                                paymentType: selectedMethod,
                                promoCode: promoCodeController.text,
                                notes: notesController.text,
                                total: double.parse(
                                  customerController.selectedPlan[0]['price']
                                      .toString(),
                                ),
                                paid: totalPaid,
                                // paid: double.parse(paidAmountController.text),
                                balance: double.parse(
                                  balanceAmountController.text,
                                ),
                              );
                            } else if (widget.type == 'ExistingBooking') {
                              populateCartWithSubSlots(widget.bookings);
                              checkoutController.makeBookingPayment(
                                bookingSlots:
                                    defaultController.actionBookingSlots
                                        .where(
                                          (slot) =>
                                              slot.paymentStatus != "Paid",
                                        )
                                        .toList(),
                                paymentType: selectedMethod,
                                promoCode: promoCodeController.text,
                                notes: notesController.text,
                                paid: totalPaid,
                                // paid: double.parse(paidAmountController.text),
                                balance: double.parse(
                                  balanceAmountController.text,
                                ),
                              );
                            } else if (widget.type == 'New') {
                              if (controller.userData.value.id != null) {
                                populateCartWithSubSlots(widget.bookings);
                                checkoutController.processFinalCheckout(
                                  userId: controller.userData.value.id,
                                  name: controller.nameController.text,
                                  email: controller.userData.value.email,
                                  mobile: controller.userData.value.mobile,
                                  paymentType: selectedMethod,
                                  promoCode: promoCodeController.text,
                                  notes: notesController.text,
                                  paid: totalPaid,
                                  // paid: double.parse(paidAmountController.text),
                                  balance: double.parse(
                                    balanceAmountController.text,
                                  ),
                                  bookingId: controller.bookingId,
                                );
                              } else {
                                checkoutController
                                    .registerUser(
                                      mobile: widget.mobileno,
                                      firstName: widget.customerName,
                                    )
                                    .then((value) {
                                      populateCartWithSubSlots(widget.bookings);
                                      checkoutController.processFinalCheckout(
                                        userId:
                                            checkoutController
                                                .userData
                                                .value
                                                .id,
                                        name: controller.nameController.text,
                                        email: controller.userData.value.email,
                                        mobile:
                                            controller.userData.value.mobile,
                                        paymentType: selectedMethod,
                                        promoCode: promoCodeController.text,
                                        notes: notesController.text,
                                        paid: totalPaid,
                                        // paid: double.parse(
                                        //   paidAmountController.text,
                                        // ),
                                        balance: double.parse(
                                          balanceAmountController.text,
                                        ),
                                        bookingId: controller.bookingId,
                                      );
                                    });
                              }
                            } else if (widget.type == 'Product') {
                              checkoutController.productsPayment(
                                paymentType: selectedMethod,
                                promoCode: promoCodeController.text,
                                notes: notesController.text,
                                paid: totalPaid,
                                // paid: double.parse(paidAmountController.text),
                                balance: double.parse(
                                  balanceAmountController.text,
                                ),
                                products: shoppingController.productsCartModal,
                              );
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
                        backgroundColor: Colors.green.shade500,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Obx(
                        () =>
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
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),
                  ),
                ],
              ),

              // Container(
              //   width: MediaQuery.of(context).size.width / 2.2,
              //   child: _payBtn,
              // ),
              SizedBox(height: 10),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSummary(CheckoutController checkoutController) {
    final double billAmount = widget.billAmount;
    final double totalPaid = this.totalPaid;
    final double balance = billAmount - totalPaid;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _amountColumn('Bill Amount', billAmount),

        _amountColumn('Total Paid', totalPaid),

        _amountColumn('Balance', balance, isBalance: true),
      ],
    );
  }

  Widget _amountColumn(String label, double amount, {bool isBalance = false}) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '${amount.abs().toStringAsFixed(2)}',
          style: GoogleFonts.inter(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: isBalance && amount != 0 ? Colors.red : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children:
          paymentMethods.map((method) {
            final isSelected = selectedMethod == method;
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.white : Colors.grey[100],
                side: BorderSide(
                  color:
                      isSelected
                          ? Colors.indigo.shade500
                          : Colors.grey.shade400,
                ),
                minimumSize: Size(50, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade400, width: 1),
                ),
              ),
              onPressed: () {
                setState(() => selectedMethod = method);
              },
              child: Text(
                method,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color:
                      isSelected
                          ? Colors.indigo.shade500
                          : Colors.grey.shade400,
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildCashButtons() {
    final cashAmounts = [5, 10, 20, 50, 100];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ...cashAmounts.map(
              (amt) => ElevatedButton(
                onPressed: () => _addPayment(amt.toDouble()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(50, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                child: Text(
                  '\$$amt',
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade800,
                    fontSize: 14,
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
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        ...keys.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:
                  row.map((key) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (key == '⌫') {
                            if (customAmountString.isNotEmpty) {
                              customAmountString = customAmountString.substring(
                                0,
                                customAmountString.length - 1,
                              );
                            }
                          } else if (key == '.') {
                            if (!customAmountString.contains('.')) {
                              customAmountString += '.';
                            }
                          } else {
                            if (customAmountString == '0') {
                              customAmountString = key; // replace initial 0
                            } else {
                              customAmountString += key;
                            }
                          }

                          totalPaid =
                              double.tryParse(customAmountString) ?? 0.0;
                        });
                      },
                      child: Container(
                        width: 80,
                        height: 60,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child:
                            key == '⌫'
                                ? const Icon(Icons.backspace_outlined)
                                : Text(
                                  key,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                      ),
                    );
                  }).toList(),
            ),
          );
        }).toList(),
      ],
    );
  }
}
