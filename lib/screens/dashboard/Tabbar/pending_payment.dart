import 'dart:convert';

import 'package:booking_app/config/constants.dart';
import 'package:booking_app/config/palette.dart';
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
                                            child: booking.paymentStatus?.toLowerCase() == 'paid' 
                                              ? SizedBox.shrink() // Hide button for paid bookings
                                              : SizedBox(
                                                  width: 120,
                                                  height: 50,
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
      final bookingInfo = await bookingController.getBookingInfo(bookingNo: booking.bookingNo);

      if (bookingInfo == null) {
        print('❌ Booking info not found for ${booking.bookingNo}');
        _showPaymentOptionsDialog(booking, null);
        return;
      }

      final hasMultipleCourts = _hasMultipleCourts(bookingInfo);
      final hasMembership     = _hasMembership(bookingInfo);
      final hasOrder          = _hasOrder(bookingInfo);

      print('🔍 Payment action check - Multiple courts: $hasMultipleCourts, Has membership: $hasMembership, Has order: $hasOrder');

      if (hasMultipleCourts || hasMembership || hasOrder) {
        _showPaymentOptionsDialog(booking, bookingInfo);
      } else {
        _processIndividualCourtPayment(booking);
      }
    } catch (e) {
      print('Error checking payment options: $e');
      _showPaymentOptionsDialog(booking, null);
    }
  }

  bool _hasMultipleCourts(Map<String, dynamic> bookingInfo) {
    try {
      final bookingData = bookingInfo['booking'];
      final cartItems = bookingData['bcart_items'];

      if (cartItems == null || cartItems.isEmpty) return false;

      final List<dynamic> jsonList = jsonDecode(cartItems);
      final Set<String> uniqueCourts = {
        for (final item in jsonList) if (item['courtName'] != null) item['courtName'].toString()
      };

      print('🏟️ Booking ${bookingData['booking_no']} has ${uniqueCourts.length} unique courts.');
      return uniqueCourts.length > 1;
    } catch (e) {
      print('Error checking multiple courts: $e');
      return false;
    }
  }

  bool _hasMembership(Map<String, dynamic> bookingInfo) {
    try {

      final membershipData = bookingInfo['membership_data'];
      final hasMembership  = bookingInfo['membership_data']!=null ? bookingInfo['membership_data']['status']==true ? false : true : false;
      if (hasMembership) {
        print('👑 Has membership: ${membershipData['membership_data']}');
      } else {
        print('❌ No membership');
      }
      return hasMembership;
    } catch (e) {
      print('Error checking membership: $e');
      return false;
    }
  }

  bool _hasOrder(Map<String, dynamic> bookingInfo) {
    try {
      return bookingInfo['orders'] != null;
    } catch (e) {
      print('Error checking order: $e');
      return false;
    }
  }

  void _showPaymentOptionsDialog(BookingModel booking, Map<String, dynamic>? bookingInfo) {
    if (!mounted) return;

    final hasMembership = bookingInfo != null && _hasMembership(bookingInfo);
    final hasOrder      = bookingInfo != null && _hasOrder(bookingInfo);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payment Options', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Text('Choose how you would like to pay:', style: GoogleFonts.inter(fontSize: 22)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.sports_tennis, color: Colors.blue, size: 35),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${booking.sportname} - ${booking.courtName}${booking.platformId}',
                        style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.grey.shade600, size: 35),
                    const SizedBox(width: 8),
                    Text('${booking.startTimeFormatted} - ${booking.endTimeFormatted}', style: GoogleFonts.inter(fontSize: 22)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.attach_money, color: Colors.green, size: 35),
                    const SizedBox(width: 8),
                    Text(
                      'Court Amount: \$${booking.grandTotal!.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                    ),
                  ],
                ),
                if (hasMembership) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(LucideIcons.crown, color: Colors.amber, size: 35),
                      const SizedBox(width: 8),
                      Text('Membership included', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.amber.shade700)),
                    ],
                  ),
                ],
                if (hasOrder) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(LucideIcons.shoppingCart, color: Palette.newColor, size: 35),
                      const SizedBox(width: 8),
                      Text('Order included', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: Palette.newColor)),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 22)),
                      style: ElevatedButton.styleFrom(backgroundColor: Palette.newColorbg, minimumSize: const Size(200, 55)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _processIndividualCourtPayment(booking);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade500, minimumSize: const Size(200, 55)),
                      child: Text('Pay This Court Only', style: GoogleFonts.inter(color: Colors.white, fontSize: 22)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _processFullBookingPayment(booking);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade500, minimumSize: const Size(200, 55)),
                      child: Text('Pay Full Booking', style: GoogleFonts.inter(color: Colors.white, fontSize: 22)),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }



  //Old Code
  // void _handlePaymentActionOld(BookingModel booking) async {
  //   try {
  //     // Check if this booking has multiple courts OR has membership
  //     final bool hasMultipleCourts = await _checkIfBookingHasMultipleCourts(booking);
  //     final bool hasMembership     = await _checkIfBookingHasMembership(booking);
  //     final bool hasOrder          = await _checkIfBookingHasOrder(booking);
  //
  //     print('🔍 Payment action check - Multiple courts: $hasMultipleCourts, Has membership: $hasMembership');
  //
  //     if (hasMultipleCourts || hasMembership || hasOrder) {
  //       // Show dialog for payment options
  //       _showPaymentOptionsDialog(booking);
  //     } else {
  //       // Go directly to individual court checkout for single court without membership
  //       _processIndividualCourtPayment(booking);
  //     }
  //   } catch (e) {
  //     print('Error checking payment options: $e');
  //     // Fallback to showing dialog
  //     _showPaymentOptionsDialog(booking);
  //   }
  // }
  //
  // Future<bool> _checkIfBookingHasMultipleCourts(BookingModel booking) async {
  //   try {
  //     // Get the full booking information to check court count
  //     final bookingInfo = await bookingController.getBookingInfo(bookingNo: booking.bookingNo);
  //
  //     if (bookingInfo == null) {
  //       print('Could not retrieve booking info for ${booking.bookingNo}');
  //       return false; // Default to single court if we can't determine
  //     }
  //
  //     // Parse the booking cart items to count unique courts
  //     final bookingData = bookingInfo['booking'];
  //     final cartItems = bookingData['bcart_items'];
  //
  //     if (cartItems == null || cartItems.isEmpty) {
  //       print('No cart items found for booking ${booking.bookingNo}');
  //       return false;
  //     }
  //
  //     // Parse the cart items JSON and count unique courts
  //     final List<dynamic> jsonList = jsonDecode(cartItems);
  //     final Set<String> uniqueCourts = <String>{};
  //
  //     for (final item in jsonList) {
  //       final courtName = item['courtName'];
  //       if (courtName != null) {
  //         uniqueCourts.add(courtName.toString());
  //       }
  //     }
  //
  //     final courtCount = uniqueCourts.length;
  //     print('🏟️ Booking ${booking.bookingNo} has $courtCount unique courts: ${uniqueCourts.join(', ')}');
  //
  //     // Return true if more than 1 court
  //     return courtCount > 1;
  //
  //   } catch (e) {
  //     print('Error checking court count for booking ${booking.bookingNo}: $e');
  //     return false; // Default to single court if error occurs
  //   }
  // }
  //
  // Future<bool> _checkIfBookingHasMembership(BookingModel booking) async {
  //   try {
  //     // Get the full booking information to check for membership
  //     final bookingInfo = await bookingController.getBookingInfo(bookingNo: booking.bookingNo);
  //
  //     if (bookingInfo == null) {
  //       print('Could not retrieve booking info for ${booking.bookingNo}');
  //       return false;
  //     }
  //
  //     // Check if membership_data exists and is not null
  //     final hasMembership = bookingInfo['membership_data']!=null ? bookingInfo['membership_data']['status'] : false;
  //
  //     if (hasMembership) {
  //       final membershipData = bookingInfo['membership_data'];
  //       print('👑 Booking ${booking.bookingNo} has membership: ${membershipData['membership_data']}');
  //     } else {
  //       print('❌ Booking ${booking.bookingNo} has no membership');
  //     }
  //
  //     return hasMembership;
  //
  //   } catch (e) {
  //     print('Error checking membership for booking ${booking.bookingNo}: $e');
  //     return false;
  //   }
  // }
  //
  // Future<bool> _checkIfBookingHasOrder(BookingModel booking) async {
  //   try {
  //     // Get the full booking information to check for membership
  //     final bookingInfo = await bookingController.getBookingInfo(bookingNo: booking.bookingNo);
  //
  //     if (bookingInfo == null) {
  //       print('Could not retrieve booking info for ${booking.bookingNo}');
  //       return false;
  //     }
  //
  //     // Check if membership_data exists and is not null
  //     final hasOrder = bookingInfo['orders'] != null;
  //
  //     return hasOrder;
  //
  //   } catch (e) {
  //     print('Error checking membership for booking ${booking.bookingNo}: $e');
  //     return false;
  //   }
  // }
  //
  // void _showPaymentOptionsDialogOld(BookingModel booking) async {
  //
  //   // Check if membership is included
  //   final bool hasMembership = await _checkIfBookingHasMembership(booking);
  //   final bool hasOrder      = await _checkIfBookingHasOrder(booking);
  //
  //   if (!mounted) return;
  //
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         backgroundColor: Colors.white,
  //         content: SizedBox(
  //           width: MediaQuery.of(context).size.width * 0.40, // 85% of screen width
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 'Payment Options',
  //                 style: GoogleFonts.inter(
  //                   fontSize: 24,
  //                   fontWeight: FontWeight.w600,
  //                 ),
  //               ),
  //               const SizedBox(height: 10),
  //               Text(
  //                 'Choose how you would like to pay:',
  //                 style: GoogleFonts.inter(fontSize: 22),
  //               ),
  //               const SizedBox(height: 20),
  //               Row(
  //                 children: [
  //                   Icon(Icons.sports_tennis, color: Colors.blue, size: 35,),
  //                   const SizedBox(width: 8),
  //                   Expanded(
  //                     child: Text(
  //                       '${booking.sportname} - ${booking.courtName}${booking.platformId}',
  //                       style: GoogleFonts.inter(
  //                         fontSize: 22,
  //                         fontWeight: FontWeight.w500,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 20),
  //               Row(
  //                 children: [
  //                   Icon(Icons.access_time, color: Colors.grey.shade600, size: 35,),
  //                   const SizedBox(width: 8),
  //                   Text(
  //                     '${booking.startTimeFormatted} - ${booking.endTimeFormatted}',
  //                     style: GoogleFonts.inter(fontSize: 22),
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 20),
  //               Row(
  //                 children: [
  //                   Icon(Icons.attach_money, color: Colors.green, size: 35,),
  //                   const SizedBox(width: 8),
  //                   Text(
  //                     'Court Amount: \$${booking.grandTotal!.toStringAsFixed(2)}',
  //                     style: GoogleFonts.inter(
  //                       fontSize: 22,
  //                       fontWeight: FontWeight.w600,
  //                       color: Colors.green.shade700,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               if (hasMembership) ...[
  //                 const SizedBox(height: 20),
  //                 Row(
  //                   children: [
  //                     Icon(LucideIcons.crown, color: Colors.amber, size: 35,),
  //                     const SizedBox(width: 8),
  //                     Text(
  //                       'Membership included',
  //                       style: GoogleFonts.inter(
  //                         fontSize: 22,
  //                         fontWeight: FontWeight.w600,
  //                         color: Colors.amber.shade700,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //               if (hasOrder) ...[
  //                 const SizedBox(height: 20),
  //                 Row(
  //                   children: [
  //                     Icon(LucideIcons.shoppingCart, color: Palette.newColor, size: 35,),
  //                     const SizedBox(width: 8),
  //                     Text(
  //                       'Order included',
  //                       style: GoogleFonts.inter(
  //                         fontSize: 22,
  //                         fontWeight: FontWeight.w600,
  //                         color: Palette.newColor,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //               const SizedBox(height: 20),
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 spacing: 20,
  //                 children: [
  //                   TextButton(
  //                     onPressed: () {
  //                       Navigator.of(context).pop();
  //                     },
  //                     child: Text(
  //                       'Cancel',
  //                       style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 22),
  //                     ),
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: Palette.newColorbg,
  //                       minimumSize: const Size(200, 55),
  //                     ),
  //                   ),
  //                   ElevatedButton(
  //                     onPressed: () {
  //                       Navigator.of(context).pop();
  //                       _processIndividualCourtPayment(booking);
  //                     },
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: Colors.blue.shade500,
  //                       minimumSize: const Size(200, 55),
  //                     ),
  //                     child: Text(
  //                       'Pay This Court Only',
  //                       style: GoogleFonts.inter(color: Colors.white, fontSize: 22),
  //                     ),
  //                   ),
  //                   ElevatedButton(
  //                     onPressed: () {
  //                       Navigator.of(context).pop();
  //                       _processFullBookingPayment(booking);
  //                     },
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: Colors.green.shade500,
  //                       minimumSize: const Size(200, 55),
  //                     ),
  //                     child: Text(
  //                       'Pay Full Booking',
  //                       style: GoogleFonts.inter(color: Colors.white, fontSize: 22),
  //                     ),
  //                   ),
  //                 ],
  //               )
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
  //Old Code



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
          if (mounted) {
            _showSnackbar('This court has already been paid for.', Colors.orange);
          }
          return;
        }

        // Navigate to checkout page for individual court payment
        if (mounted) {
          await _navigateToIndividualCourtCheckout(booking, courtInfo);
        }
      } else {
        if (mounted) {
          _showSnackbar('Could not retrieve court information for payment.', Colors.red);
        }
      }
    } catch (e) {
      print('❌ Error in _processIndividualCourtPayment: $e');
      if (mounted) {
        _showSnackbar('Error processing payment: $e', Colors.red);
      }
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
          
          // Check if this is a peak hour slot
          final hour = startTime.hour;
          final isPeakHour = (hour >= 17 && hour < 21); // 5 PM to 9 PM is peak
          
          subSlots.add(BookingSubSlotInfo(
            startTime: DateFormat('HH:mm').format(startTime),
            endTime: DateFormat('HH:mm').format(endTime),
            price: price,
            isPeak: isPeakHour,
          ));
        }
        
        // Create BookingInfo for this court

        String? courtName = '';
        final SharedPreferences preferences = await SharedPreferences.getInstance();
        final sportsList = jsonDecode(preferences.getString('sportsWithPlatforms') ?? '[]');

        Map<String, dynamic>? matchedSport;
        Map<String, dynamic>? matchedPlatformStatus;

        for (final sport in sportsList) {
          // ✅ Match sport by name first
          if (sport['sport_name']?.toString().toLowerCase() == booking.sportname?.toLowerCase()) {
            final platformStatusList = sport['platform_status'] as List<dynamic>?;

            if (platformStatusList != null) {
              for (final platformStatus in platformStatusList) {
                // ✅ Then match platform ID
                if (platformStatus['platform_id'].toString() == booking.platformId.toString()) {
                  matchedSport = sport;
                  matchedPlatformStatus = platformStatus;
                  break;
                }
              }
            }

            if (matchedSport != null) break; // stop if found
          }
        }

        if (matchedSport != null && matchedPlatformStatus != null) {
          courtName = '${matchedSport['platform_name']} ${matchedPlatformStatus['platform_id']}';
          print('✅ Court Name: $courtName');
        } else {
          print('⚠️ Platform not found for sport: ${booking.sportname}, platformId: ${booking.platformId}');
        }

        //final courtName = booking.courtName ?? 'Court ${booking.platformId}';
        individualCourtBookings.add(BookingInfo(
          courtName: courtName,
          courtId: booking.courtId,
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
      if (mounted) {
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
      }
      
    } catch (e) {
      print('Error navigating to individual court checkout: $e');
      if (mounted) {
        _showSnackbar('Error opening checkout: $e', Colors.red);
      }
    }
  }

  void _processFullBookingPayment(BookingModel booking) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('shopping_cart');
      double totalAmount = 0;
      
      await bookingController.getBookingInfo(bookingNo: booking.bookingNo).then((value) async {
        if (value != null) {
          print('📊 Full booking data structure keys: ${value.keys}');
          print('📊 Booking data keys: ${value['booking'].keys}');
          
          // Debug the raw booking data first
          print('📊 Raw booking grand_total: ${value['booking']['grand_total']}');
          print('📊 Booking ID: ${value['booking']['id']}');
          
          // Use the raw grand_total directly since BookingWithAll might not parse it correctly
          totalAmount = value['booking']['grand_total'] != null 
              ? double.parse(value['booking']['grand_total'].toString()) 
              : 0.0;
          
          final bookingData = BookingWithAll.fromJson(value['booking']);
          final orderData = value['order'] != null ? Orders.fromJson(value['order']) : value['order'];
          final userData = value['customer'];
          
          // Add order total if there are products
          if (orderData != null && value['order']['total'] != null) {
            totalAmount += double.parse(value['order']['total'].toString());
          }
          
          print('💰 Total calculation: Booking GT=${bookingData.grandTotal}, Raw GT=${value['booking']['grand_total']}, Order=${orderData != null ? value['order']['total'] : 0}, Final Total=$totalAmount');

          if (orderData != null) {
            await prefs.setString('shopping_cart', jsonEncode(value['order']['cart_items']));
          }

          // Handle potential null bcart_items or reconstruct from booking_slots
          List<BookingInfo> bookings = [];
          if (value['booking']['bcart_items'] != null && value['booking']['bcart_items'].toString().isNotEmpty) {
            List<dynamic> jsonList = jsonDecode(value['booking']['bcart_items']);
            bookings = jsonList.map((b) => BookingInfo.fromJson(b)).toList();
          } else if (value['booking']['booking_slots'] != null) {
            // Reconstruct booking info from booking_slots if bcart_items is empty
            try {
              final bookingSlots = value['booking']['booking_slots'] as List<dynamic>;
              Map<String, List<BookingSubSlotInfo>> courtSubSlots = {};
              
              for (final slot in bookingSlots) {
                // Safely access nested properties
                final platformStatus = slot['platform_status'];
                final courtName = platformStatus != null && platformStatus['court_name'] != null 
                    ? platformStatus['court_name'].toString() 
                    : 'Court';
                
                // Safely parse times
                final startTimeStr = slot['start_time']?.toString();
                final endTimeStr = slot['end_time']?.toString();
                if (startTimeStr == null || endTimeStr == null) continue;
                
                final startTime = DateTime.parse(startTimeStr);
                final endTime = DateTime.parse(endTimeStr);
                // Get the original price from the slot
                final price = slot['price'] != null ? (slot['price'] as num).toDouble() : 0.0;
                print('🎾 Court: $courtName, Time: $startTimeStr-$endTimeStr, Price: $price');
                
                if (!courtSubSlots.containsKey(courtName)) {
                  courtSubSlots[courtName] = [];
                }
                
                courtSubSlots[courtName]!.add(BookingSubSlotInfo(
                  startTime: DateFormat('HH:mm').format(startTime),
                  endTime: DateFormat('HH:mm').format(endTime),
                  price: price,
                  isPeak: slot['is_peak'] ?? false,
                ));
              }
              
              // Create BookingInfo for each court
              final bookingDateStr = value['booking']['booking_date']?.toString();
              final bookingDate = bookingDateStr != null 
                  ? DateTime.parse(bookingDateStr) 
                  : DateTime.now();
                  
              courtSubSlots.forEach((courtName, subSlots) {
                bookings.add(BookingInfo(
                  courtName: courtName,
                  courtId: null, // Court ID not available in this context
                  selectedDateTime: bookingDate,
                  bookingId: value['booking']['id'],
                  subSlots: subSlots,
                ));
              });
            } catch (e) {
              print('Error reconstructing booking slots: $e');
            }
          }

          String membershipID = '';
          String membershipName = '';
          bool isMembershipApplied = false;
          double membershipPrice = 0;

          if (value['membership_data'] != null && value['membership_data']['status']==false) {
            try {
              final membershipPlanId = value['membership_data']['membershipplan_id']?.toString();
              if (membershipPlanId != null && membershipPlanId.isNotEmpty) {
                await bookingController.getMembershipDetails(membershipId: membershipPlanId).then((membershipInfo) {
                  if (membershipInfo != null && membershipInfo['membership'] != null) {
                    // Don't add membership price to totalAmount as it's already included in bookingData.grandTotal
                    membershipID = membershipInfo['membership']['id']?.toString() ?? '';
                    membershipName = membershipInfo['membership']['name']?.toString() ?? '';
                    isMembershipApplied = true;
                    final priceStr = membershipInfo['membership']['price']?.toString();
                    membershipPrice = priceStr != null ? double.tryParse(priceStr) ?? 0.0 : 0.0;
                  }
                });
              }
            } catch (e) {
              print('Error processing membership data: $e');
            }
          }

          if (mounted) {
            print('🎯 Navigating to checkout with: totalAmount=$totalAmount, bookings=${bookings.length}, membership=$isMembershipApplied');
            
            // For existing bookings with membership already paid, we need to handle it specially
            // The membership is included in the total but we want to show it in the UI
            Get.to(CheckoutScreen(
              type: 'ExistingBooking',
              customerName: booking.customerName!,
              mobileno: booking.customerMobile!,
              selectedDateTime: DateTime.now(),
              billAmount: totalAmount,
              bookings: bookings,
              membershipID: membershipID,
              membershipName: membershipName,
              isMembershipApplied: membershipID.isNotEmpty, // Show membership if it exists
              membershipPrice: membershipPrice, // Keep the actual price for display
              exbookingId: bookingData.id,
              exorderId: orderData != null ? orderData.id : null,
              exuserId: userData['id'],
              forpayment: 'existing-order-payment',
              // Note: The total already includes membership, checkout screen should handle this
            ));
          }
        }
      });
    } catch (e) {
      if (mounted) {
        _showSnackbar('Error processing full booking payment: $e', Colors.red);
      }
    }
  }

  String _extractCourtIdFromBooking(BookingModel booking) {
    // Return the actual court_id from the database, not platformId
    print('Extracting court ID: courtId=${booking.courtId}, platformId=${booking.platformId}');
    return booking.courtId ?? booking.platformId ?? '';
  }

  void _showSnackbar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
