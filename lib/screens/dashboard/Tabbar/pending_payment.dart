import 'dart:convert';

import 'package:booking_app/config/constants.dart';
import 'package:booking_app/controllers/checkout_controller.dart';
import 'package:booking_app/controllers/new_booking_controller.dart';
import 'package:booking_app/controllers/order_controller.dart';
import 'package:booking_app/models/booking_model.dart';
import 'package:booking_app/models/booking_with_all.dart';
import 'package:booking_app/models/order.dart';
import 'package:booking_app/models/user.dart';
import 'package:booking_app/screens/checkout/checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PendingPayment extends StatefulWidget {
  const PendingPayment({Key? key}) : super(key: key);

  @override
  State<PendingPayment> createState() => _PendingPaymentState();
}

class _PendingPaymentState extends State<PendingPayment> {
  final OrderController bookingController = Get.put(OrderController());
  final CheckoutController checkoutController = Get.put(CheckoutController());
  final NewBookingController newBookingController = Get.find<NewBookingController>();
  bool isGridView = false;
  String selectedFilter = 'All';
  final List<String> filterOptions = [
    'All',
    'Yesterday',
    'Today',
    'Previous Day',
  ];
  List<bool> selectedRows = [];
  bool selectAll = false;
  final TextEditingController _searchController = TextEditingController();
  List bookingsFiltered = [];

  @override
  void initState() {
    super.initState();
    selectedRows = List.generate(
      bookingController.bookings.length,
      (_) => false,
    );
    bookingsFiltered = bookingController.bookings;
  }

  void filterBookings() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      bookingsFiltered = bookingController.bookings;
    } else {
      bookingsFiltered = bookingController.bookings.where((booking) {
        final name = (booking.customerName ?? '').toLowerCase();
        final mobile = (booking.customerMobile ?? '').toLowerCase();
        return name.contains(query) || mobile.contains(query);
      }).toList();
    }
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (bookingController.bookings.isNotEmpty && selectedRows.length != bookingController.bookings.length) {
      setState(() {
        selectedRows = List.generate(
          bookingController.bookings.length,
          (_) => false,
        );
        selectAll = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: LayoutBuilder(
        builder: (context, constraints) {
          //final isTablet = constraints.maxWidth >= 600;

          return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pending Payment Bookings",
                      style: GoogleFonts.inter(
                        fontSize: 25,
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Spacer(),
                Expanded(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.2,
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.roboto(fontSize: 25),
                      decoration: InputDecoration(
                        hintText: 'search "john"',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 25,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w400,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 15,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.grey.shade500,
                            width: 1.5,
                          ),
                        ),
                        isDense: true,
                      ),
                      onChanged: (_) => filterBookings(),
                    ),
                  ),
                ),
                // const SizedBox(width: 20),
                // SizedBox(
                //   width: MediaQuery.of(context).size.width / 8,
                //   child: DropdownButtonFormField<String>(
                //     value: selectedFilter,
                //     items:
                //     filterOptions.map((String item) {
                //       return DropdownMenuItem<String>(
                //         value: item,
                //         // enabled: !isDisabled,
                //         child: Text(
                //           item,
                //           style: GoogleFonts.inter(
                //             fontSize: 15 * ffem,
                //             color: Colors.black,
                //           ),
                //         ),
                //       );
                //     }).toList(),
                //     onChanged: (value) async {},
                //     onSaved: (value) {},
                //     decoration: InputDecoration(
                //       hintText: 'All',
                //       hintStyle: GoogleFonts.inter(
                //         fontSize: 22,
                //         color: Colors.white,
                //         fontWeight: FontWeight.w500,
                //       ),
                //       contentPadding: const EdgeInsets.symmetric(
                //         horizontal: 8,
                //         vertical: 7,
                //       ),
                //       filled: true,
                //       fillColor: Colors.white,
                //       border: OutlineInputBorder(
                //         borderRadius: BorderRadius.circular(10),
                //         borderSide: BorderSide(color: Colors.grey.shade200),
                //       ),
                //       enabledBorder: OutlineInputBorder(
                //         borderRadius: BorderRadius.circular(8),
                //         borderSide: BorderSide(color: Colors.grey.shade300),
                //       ),
                //       focusedBorder: OutlineInputBorder(
                //         borderRadius: BorderRadius.circular(8),
                //         borderSide: BorderSide(
                //           color: Colors.grey.shade500,
                //           width: 1.5,
                //         ),
                //       ),
                //       isDense: true,
                //     ),
                //     style: GoogleFonts.inter(
                //       fontSize: 22,
                //       color: Colors.grey.shade900,
                //       fontWeight: FontWeight.w500,
                //     ),
                //   ),
                // ),
                // const SizedBox(width: 10),
                // Container(
                //   height: 44,
                //   width: 44,
                //   decoration: BoxDecoration(
                //     color: Colors.white,
                //     borderRadius: BorderRadius.circular(12),
                //     border: Border.all(color: Colors.grey.shade300),
                //   ),
                //   child: const Icon(LucideIcons.filter, size: 20),
                // ),
                // const SizedBox(width: 10),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Obx(() {
                if (bookingController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (bookingController.error.isNotEmpty) {
                  return Center(child: Text(bookingController.error.value));
                }

                //final bookings = bookingController.bookings;
                final bookings = bookingsFiltered.where((p0) => (p0.customerName!=null && p0.bookingStatus!='Cancelled')).toList();

                if (bookings.isEmpty) {
                  return Center(
                    child: Text(
                      "No bookings available.",
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    // Custom Header Row
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                'Cust.Name & Mobile',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                'Sport & Court',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                'Timing',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                'Amount (\$)',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Booking Status',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Action',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height - 200,

                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: bookings.length,
                            itemBuilder: (context, index) {
                              final booking = bookings[index];
                              final b = bookings[index];
                              final remaining = b.endTime!.difference(DateTime.now()).inMinutes;
                              final isEndingSoon = remaining <= 15;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 10,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                      children: [
                                        // Customer & Mobile
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                                mainAxisAlignment:
                                                MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    booking.customerName!,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 22,
                                                      fontWeight:
                                                      FontWeight.w500,
                                                      color:
                                                      Colors.grey.shade900,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  if (booking.isExtendedBooking == true)
                                                    const Icon(
                                                      Icons.repeat,
                                                      size: 30,
                                                      color: Colors.purple,
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                booking.customerMobile!,
                                                style: GoogleFonts.inter(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Sport & Court
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                booking.sportname!,
                                                style: GoogleFonts.inter(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey.shade900,
                                                ),
                                              ),
                                              // Text(
                                              //   booking.bookingNo! ?? '',
                                              //   style: GoogleFonts.inter(
                                              //     fontSize: 22,
                                              //     fontWeight: FontWeight.w500,
                                              //     color: Colors.grey.shade500,
                                              //   ),
                                              // ),
                                              Text(
                                                '${booking.courtName}${booking.platformId}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Date & Time
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                booking.bookingDateFormatted,
                                                //   DateFormat(
                                                //     'dd MMMM yyyy',
                                                //   ).format(
                                                //  booking.bookingDateFormatted,
                                                //   ),
                                                style: GoogleFonts.inter(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              Center(
                                                child: Text(
                                                  '${booking.startTimeFormatted} - ${booking.endTimeFormatted}',
                                                  //'${DateFormat('hh:mm a').format(booking.startTime!)} - ${DateFormat('hh:mm a').format(booking.endTime!)}',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Center(
                                            child: Text(
                                              "\$ ${b.grandTotal!.toStringAsFixed(2)}",
                                              style: GoogleFonts.inter(
                                                fontSize: 23,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey.shade900,
                                              ),
                                            ),
                                          ),
                                        ),
                                        //Pay Button
                                        Expanded(
                                          child: Align(
                                            alignment: Alignment.center,
                                            child: Chip(
                                              label: Text(
                                                (booking.bookingStatus?.toLowerCase() == 'booked') ? (booking.paymentStatus ?.toLowerCase() == 'paid' ? 'Paid' : 'Pending') : (booking.bookingStatus ?? ''),
                                                style: GoogleFonts.inter(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w600,
                                                  color: getStatusTextColor(
                                                    booking.bookingStatus,
                                                  ),
                                                ),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                BorderRadius.circular(15),
                                                side: BorderSide(
                                                  color: getStatusBorderColor(
                                                    booking.bookingStatus,
                                                  ),
                                                ),
                                              ),
                                              backgroundColor:
                                              getStatusBackgroundColor(
                                                booking.bookingStatus,
                                              ),
                                              labelStyle: GoogleFonts.inter(
                                                color: getStatusTextColor(
                                                  booking.bookingStatus,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Align(
                                            alignment: Alignment.center,
                                            child: SizedBox(
                                              width: 120,
                                              height: 40,
                                              child: ElevatedButton(
                                                onPressed: () => _handlePaymentAction(booking),
                                                child: Text('Pay', style: TextStyle(fontSize: 22, color: Colors.white)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green.shade500,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Divider between rows
                                  const Divider(height: 1),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        );
      },
    ),
    );
  }

  Color getStatusBorderColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'booked':
        return Colors.green.shade500;
      case 'no show':
        return Colors.grey.shade500;
      case 'cancelled':
        return Colors.red.shade500;
      default:
        return Colors.grey.shade300;
    }
  }

  Color getStatusBackgroundColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'booked':
        return Colors.green.shade50;
      case 'no show':
        return Colors.grey.shade100;
      case 'cancelled':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  Color getStatusTextColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'booked':
        return Colors.green.shade500;
      case 'no show':
        return Colors.grey.shade700;
      case 'cancelled':
        return Colors.red.shade500;
      default:
        return Colors.grey.shade500;
    }
  }

  void _handlePaymentAction(BookingModel booking) async {
    try {
      // Check if this booking has multiple courts
      final bool hasMultipleCourts = await _checkIfBookingHasMultipleCourts(booking);
      
      if (hasMultipleCourts) {
        // Show dialog for multiple courts
        _showPaymentOptionsDialog(booking);
      } else {
        // Go directly to individual court checkout for single court
        _processIndividualCourtPayment(booking);
      }
    } catch (e) {
      print('Error checking multiple courts: $e');
      // Fallback to showing dialog
      _showPaymentOptionsDialog(booking);
    }
  }

  Future<bool> _checkIfBookingHasMultipleCourts(BookingModel booking) async {
    try {
      // Get the full booking information to check court count
      final bookingInfo = await bookingController.getBookingInfo(bookingNo: booking.bookingNo);
      
      if (bookingInfo == null) {
        print('Could not retrieve booking info for ${booking.bookingNo}');
        return false; // Default to single court if we can't determine
      }
      
      // Parse the booking cart items to count unique courts
      final bookingData = bookingInfo['booking'];
      final cartItems = bookingData['bcart_items'];
      
      if (cartItems == null || cartItems.isEmpty) {
        print('No cart items found for booking ${booking.bookingNo}');
        return false;
      }
      
      // Parse the cart items JSON and count unique courts
      final List<dynamic> jsonList = jsonDecode(cartItems);
      final Set<String> uniqueCourts = <String>{};
      
      for (final item in jsonList) {
        final courtName = item['courtName'];
        if (courtName != null) {
          uniqueCourts.add(courtName.toString());
        }
      }
      
      final courtCount = uniqueCourts.length;
      print('🏟️ Booking ${booking.bookingNo} has $courtCount unique courts: ${uniqueCourts.join(', ')}');
      
      // Return true if more than 1 court
      return courtCount > 1;
      
    } catch (e) {
      print('Error checking court count for booking ${booking.bookingNo}: $e');
      return false; // Default to single court if error occurs
    }
  }

  void _showPaymentOptionsDialog(BookingModel booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Payment Options',
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
                'Choose how you would like to pay:',
                style: GoogleFonts.inter(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.sports_tennis, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${booking.sportname} - ${booking.courtName}${booking.platformId}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '${booking.startTimeFormatted} - ${booking.endTimeFormatted}',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_money, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Court Amount: \$${booking.grandTotal!.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processIndividualCourtPayment(booking);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade500,
              ),
              child: Text(
                'Pay This Court Only',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processFullBookingPayment(booking);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade500,
              ),
              child: Text(
                'Pay Full Booking',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _processIndividualCourtPayment(BookingModel booking) async {
    try {
      print('🚀 Starting individual court payment for booking: ${booking.bookingNo}');
      print('📋 Booking details: courtId=${booking.courtId}, platformId=${booking.platformId}, startTime=${booking.startTime}, endTime=${booking.endTime}');
      
      final extractedCourtId = _extractCourtIdFromBooking(booking);
      print('🔧 Extracted court ID: $extractedCourtId');
      
      // Get individual court information
      final courtInfo = await bookingController.getIndividualCourtInfo(
        bookingNo: booking.bookingNo,
        courtId: extractedCourtId,
        startTime: booking.startTime,
        endTime: booking.endTime,
      );

      print('📊 Court info result: ${courtInfo != null ? 'SUCCESS' : 'NULL'}');
      if (courtInfo != null) {
        print('💰 Remaining amount: ${courtInfo['remaining_amount']}');
        final remainingAmount = courtInfo['remaining_amount'] as double;
        
        if (remainingAmount <= 0) {
          _showSnackbar('This court has already been paid for.', Colors.orange);
          return;
        }

        // Navigate to checkout page for individual court payment
        await _navigateToIndividualCourtCheckout(booking, courtInfo);
      } else {
        _showSnackbar('Could not retrieve court information for payment.', Colors.red);
      }
    } catch (e) {
      print('❌ Error in _processIndividualCourtPayment: $e');
      _showSnackbar('Error processing payment: $e', Colors.red);
    }
  }

  Future<void> _navigateToIndividualCourtCheckout(BookingModel booking, Map<String, dynamic> courtInfo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('shopping_cart'); // Clear any existing cart
      
      final bookingData = courtInfo['booking'];
      final customerData = courtInfo['customer'];
      final courtSlots = courtInfo['court_slots'] as List<dynamic>;
      final remainingAmount = courtInfo['remaining_amount'] as double;
      
      // Create BookingInfo for this individual court
      List<BookingInfo> individualCourtBookings = [];
      
      if (courtSlots.isNotEmpty) {
        // Group slots by time to create sub-slots
        List<BookingSubSlotInfo> subSlots = [];
        
        for (final slot in courtSlots) {
          final startTime = DateTime.parse(slot['start_time']);
          final endTime = DateTime.parse(slot['end_time']);
          final price = (slot['price'] as num).toDouble();
          
          subSlots.add(BookingSubSlotInfo(
            startTime: DateFormat('HH:mm').format(startTime),
            endTime: DateFormat('HH:mm').format(endTime),
            price: price,
            isPeak: false, // Set this based on your business logic
          ));
        }
        
        // Create BookingInfo for this court
        final courtName = booking.courtName ?? 'Court ${booking.platformId}';
        individualCourtBookings.add(BookingInfo(
          courtName: courtName,
          selectedDateTime: booking.startTime ?? DateTime.now(),
          bookingId: bookingData['id'],
          subSlots: subSlots,
        ));
      }
      
      // Check for membership if applicable
      String membershipID = '';
      String membershipName = '';
      bool isMembershipApplied = false;
      double membershipPrice = 0;
      double totalAmount = remainingAmount;
      
      if (courtInfo['membership_data'] != null) {
        final membershipData = courtInfo['membership_data'];
        await bookingController.getMembershipDetails(membershipId: membershipData['membershipplan_id']).then((membershipInfo) {
          if (membershipInfo != null) {
            membershipID = membershipInfo['membership']['id'];
            membershipName = membershipInfo['membership']['name'];
            isMembershipApplied = true;
            membershipPrice = double.parse(membershipInfo['membership']['price'].toString());
            totalAmount += membershipPrice;
          }
        });
      }
      
      // Navigate to checkout screen
      Get.to(CheckoutScreen(
        type: 'ExistingBooking', // Use ExistingBooking type for proper payment handling
        customerName: booking.customerName!,
        mobileno: booking.customerMobile!,
        selectedDateTime: booking.startTime ?? DateTime.now(),
        billAmount: totalAmount,
        bookings: individualCourtBookings,
        membershipID: membershipID,
        membershipName: membershipName,
        isMembershipApplied: isMembershipApplied,
        membershipPrice: membershipPrice,
        exbookingId: bookingData['id'],
        exorderId: null, // No order for individual court payments
        exuserId: customerData['id'],
        forpayment: 'individual-court-payment',
      ));
      
    } catch (e) {
      print('Error navigating to individual court checkout: $e');
      _showSnackbar('Error opening checkout: $e', Colors.red);
    }
  }

  void _processFullBookingPayment(BookingModel booking) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('shopping_cart');
      double totalAmount = 0;
      
      await bookingController.getBookingInfo(bookingNo: booking.bookingNo).then((value) async {
        if (value != null) {
          final bookingData = BookingWithAll.fromJson(value['booking']);
          final orderData = value['order'] != null ? Orders.fromJson(value['order']) : value['order'];
          final userData = value['customer'];
          totalAmount = (bookingData.grandTotal ?? 0) + (orderData != null ? double.parse(value['order']['total'].toString()) ?? 0 : 0);

          if (orderData != null) {
            await prefs.setString('shopping_cart', jsonEncode(value['order']['cart_items']));
          }

          List<dynamic> jsonList = jsonDecode(value['booking']['bcart_items']);
          List<BookingInfo> bookings = jsonList.map((b) => BookingInfo.fromJson(b)).toList();

          String membershipID = '';
          String membershipName = '';
          bool isMembershipApplied = false;
          double membershipPrice = 0;

          if (value['membership_data'] != null) {
            await bookingController.getMembershipDetails(membershipId: value['membership_data']['membershipplan_id']).then((membershipInfo) {
              if (membershipInfo != null) {
                totalAmount += double.parse(membershipInfo['membership']['price'].toString());
                membershipID = membershipInfo['membership']['id'];
                membershipName = membershipInfo['membership']['name'];
                isMembershipApplied = true;
                membershipPrice = double.parse(membershipInfo['membership']['price'].toString());
              }
            });
          }

          Get.to(CheckoutScreen(
            type: 'ExistingBooking',
            customerName: booking.customerName!,
            mobileno: booking.customerMobile!,
            selectedDateTime: DateTime.now(),
            billAmount: totalAmount,
            bookings: bookings,
            membershipID: membershipID,
            membershipName: membershipName,
            isMembershipApplied: isMembershipApplied,
            membershipPrice: membershipPrice,
            exbookingId: bookingData.id,
            exorderId: orderData != null ? orderData.id : null,
            exuserId: userData['id'],
            forpayment: 'existing-order-payment',
          ));
        }
      });
    } catch (e) {
      _showSnackbar('Error processing full booking payment: $e', Colors.red);
    }
  }

  String _extractCourtIdFromBooking(BookingModel booking) {
    // Return the actual court_id from the database, not platformId
    print('Extracting court ID: courtId=${booking.courtId}, platformId=${booking.platformId}');
    return booking.courtId ?? booking.platformId ?? '';
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
