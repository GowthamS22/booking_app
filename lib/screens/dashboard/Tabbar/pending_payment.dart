import 'dart:convert';

import 'package:booking_app/config/constants.dart';
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
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PendingPayment extends StatefulWidget {
  const PendingPayment({Key? key}) : super(key: key);

  @override
  State<PendingPayment> createState() => _PendingPaymentState();
}

class _PendingPaymentState extends State<PendingPayment> {
  final OrderController bookingController = Get.put(OrderController());
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
                                                onPressed: () async {
                                                  final prefs = await SharedPreferences.getInstance();
                                                  await prefs.remove('shopping_cart');
                                                  double totalAmount = 0;
                                                  await bookingController.getBookingInfo(bookingNo: booking.bookingNo).then((value) async {
                                                    if (value != null) {
                                                      final bookingData = BookingWithAll.fromJson(value['booking']);
                                                      final orderData   = value['order'] != null ? Orders.fromJson(value['order']) : value['order'];
                                                      final userData    = value['customer'];
                                                      totalAmount = (bookingData.grandTotal ?? 0) + (orderData!=null ? double.parse(value['order']['total'].toString()) ?? 0 : 0);

                                                      if(orderData!=null) {
                                                        await prefs.setString('shopping_cart', jsonEncode(value['order']['cart_items']));
                                                      }

                                                      List<dynamic> jsonList = jsonDecode(value['booking']['bcart_items']);
                                                      List<BookingInfo> bookings = jsonList.map((b) => BookingInfo.fromJson(b)).toList();

                                                      String membershipID       = '';
                                                      String membershipName     = '';
                                                      bool isMembershipApplied  = false;
                                                      double membershipPrice    = 0;

                                                      if(value['membership_data']!=null) {
                                                        await bookingController.getMembershipDetails(membershipId: value['membership_data']['membershipplan_id']).then((membershipInfo) {
                                                          if(membershipInfo!=null) {
                                                            totalAmount += double.parse(membershipInfo['membership']['price'].toString());

                                                            membershipID         = membershipInfo['membership']['id'];
                                                            membershipName       = membershipInfo['membership']['name'];
                                                            isMembershipApplied  = true;
                                                            membershipPrice      = double.parse(membershipInfo['membership']['price'].toString());

                                                          }
                                                        },);
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
                                                        exorderId: orderData!=null ? orderData.id: null,
                                                        exuserId: userData['id'],
                                                        forpayment: 'existing-order-payment',
                                                      ));
                                                    }
                                                  },);
                                                },
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
}
