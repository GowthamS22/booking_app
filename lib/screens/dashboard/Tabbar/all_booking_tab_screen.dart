import 'package:booking_app/config/palette.dart';
import 'package:booking_app/models/booking_with_all.dart';
import 'package:booking_app/models/order.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:booking_app/controllers/order_controller.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants.dart';

class AllBookingTabScreen extends StatefulWidget {
  const AllBookingTabScreen({super.key});

  @override
  State<AllBookingTabScreen> createState() => _AllBookingTabScreenState();
}

class _AllBookingTabScreenState extends State<AllBookingTabScreen> {
  final OrderController bookingController = Get.put(OrderController());
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
      bookingsFiltered =
          bookingController.bookings.where((booking) {
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
    if (bookingController.bookings.isNotEmpty &&
        selectedRows.length != bookingController.bookings.length) {
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
            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "All Bookings",
                      style: GoogleFonts.inter(
                        fontSize: 23,
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      "Bookings scheduled to being soon",
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                Spacer(),
                Expanded(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.3,
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.roboto(fontSize: 22),
                      decoration: InputDecoration(
                        hintText: 'search "john"',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 22,
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
                // Expanded(
                //   child: SizedBox(
                //     width: MediaQuery.of(context).size.width * 0.3,
                //     child: TextField(
                //       style: GoogleFonts.roboto(fontSize: 14),
                //       decoration: InputDecoration(
                //         hintText: 'Search "john"',
                //         hintStyle: GoogleFonts.inter(
                //           fontSize: 22,
                //           color: Colors.grey.shade400,
                //           fontWeight: FontWeight.w400,
                //         ),
                //         contentPadding: const EdgeInsets.symmetric(
                //           horizontal: 16,
                //           vertical: 15,
                //         ),
                //         filled: true,
                //         fillColor: Colors.white,
                //         border: OutlineInputBorder(
                //           borderRadius: BorderRadius.circular(10),
                //           borderSide: BorderSide(color: Colors.grey.shade200),
                //         ),
                //         enabledBorder: OutlineInputBorder(
                //           borderRadius: BorderRadius.circular(8),
                //           borderSide: BorderSide(color: Colors.grey.shade300),
                //         ),
                //         focusedBorder: OutlineInputBorder(
                //           borderRadius: BorderRadius.circular(8),
                //           borderSide: BorderSide(
                //             color: Colors.grey.shade500,
                //             width: 1.5,
                //           ),
                //         ),
                //         isDense: true,
                //       ),
                //       onChanged: (_) => filterBookings(),
                //     ),
                //   ),
                // ),
                //const SizedBox(width: 20),
                // SizedBox(
                //   width: MediaQuery.of(context).size.width / 8,
                //   child: DropdownButtonFormField<String>(
                //     value: selectedFilter,
                //     items:
                //         filterOptions.map((String item) {
                //           return DropdownMenuItem<String>(
                //             value: item,
                //             // enabled: !isDisabled,
                //             child: Text(
                //               item,
                //               style: GoogleFonts.inter(
                //                 fontSize: 15 * ffem,
                //                 color: Colors.black,
                //               ),
                //             ),
                //           );
                //         }).toList(),
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

                final bookings = bookingsFiltered;

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
                              final remaining =
                                  b.endTime!
                                      .difference(DateTime.now())
                                      .inMinutes;
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
                                                    booking.customerName ?? '',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          Colors.grey.shade900,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  if (booking
                                                          .isExtendedBooking ==
                                                      true)
                                                    const Icon(
                                                      Icons.repeat,
                                                      size: 30,
                                                      color: Colors.purple,
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                booking.customerMobile ?? '',
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
                                                booking.sportname ?? '',
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
                                              "\$ ${b.grandTotal?.toStringAsFixed(2)}",
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
                                                (booking.bookingStatus
                                                            ?.toLowerCase() ==
                                                        'booked')
                                                    ? (booking.paymentStatus
                                                                ?.toLowerCase() ==
                                                            'paid'
                                                        ? 'Paid'
                                                        : 'Pending')
                                                    : (booking.bookingStatus ??
                                                        ''),
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
                                            child: ElevatedButton(
                                              child: Text('View', style: TextStyle(color: Palette.newColor, fontSize: 22),),
                                              onPressed: () {
                                                openBookingDetailsDrawer(
                                                    context,
                                                    b.bookingNo,
                                                    '${booking.startTimeFormatted} - ${booking.endTimeFormatted}',
                                                    booking.sportname,
                                                    '${booking.courtName}${booking.platformId}',
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Palette.newColorbg,
                                                minimumSize: const Size(100, 50),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(50),
                                                  side: BorderSide(color: Palette.newColor)
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
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

  Future<void> openBookingDetailsDrawer(BuildContext context, bookingNo, timing, sportName, courtName) async {

    final bookingInfo = await bookingController.getBookingInfo(bookingNo: bookingNo);
    final booking     = BookingWithAll.fromJson(bookingInfo?['booking']);
    print(bookingInfo?['customer']);

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Customer Add',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(anim1),
          child: Align(
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.4,
              child: Material(
                color: Colors.white,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(anim1),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: Material(
                            color: Colors.white,
                            child: Container(
                              color: Colors.white,
                              height: MediaQuery.of(context).size.height,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// Header
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            bookingInfo?['customer']['first_name'],
                                            style: GoogleFonts.inter(
                                              fontSize: 23,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            bookingInfo?['customer']['mobile'],
                                            style: GoogleFonts.inter(
                                              fontSize: 22,
                                              color: Colors.grey.shade500,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 32),

                                  /// Booking Details
                                  Text(
                                    "Booking Details",
                                    //"Booking Details : ${booking.id}",
                                    style: GoogleFonts.inter(
                                      fontSize: 22,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    "Current booking informations",
                                    style: GoogleFonts.inter(
                                      fontSize: 22,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  Container(
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Booking ${booking.bookingNo ?? 'N/A'}",
                                          style: GoogleFonts.inter(
                                            fontSize: 22,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          spacing: 150,
                                          children: [
                                            Column(
                                              spacing: 20,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                bookingDetailRow(
                                                  LucideIcons.gamepad2,
                                                  "Sport",
                                                  sportName ?? 'N/A',
                                                ),
                                                bookingDetailRow(
                                                  LucideIcons.clock,
                                                  "Time",
                                                  '${timing}',
                                                ),
                                              ],
                                            ),
                                            Column(
                                              spacing: 20,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                bookingDetailRow(
                                                  LucideIcons.scanLine,
                                                  "Court",
                                                  courtName,
                                                ),
                                                bookingDetailRow(
                                                  LucideIcons.timer,
                                                  "Duration",
                                                  '',
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Divider(color: Colors.grey.shade300, thickness: 2, height: 20,),
                                        // Padding(
                                        //   padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        //   child: Row(
                                        //     children: [
                                        //       Expanded(
                                        //         child: Text(
                                        //           'Total:',
                                        //           style: const TextStyle(
                                        //             fontSize: 22,
                                        //           ),
                                        //         ),
                                        //       ),
                                        //       Container(
                                        //         width: 150,
                                        //         child: Text(
                                        //           '\$${booking.total?.toStringAsFixed(2)}',
                                        //           style: const TextStyle(
                                        //             fontSize: 22,
                                        //           ),
                                        //           textAlign: TextAlign.right,
                                        //         ),
                                        //       ),
                                        //     ],
                                        //   ),
                                        // ),
                                        // Padding(
                                        //   padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        //   child: Row(
                                        //     children: [
                                        //       Expanded(
                                        //         child: Text(
                                        //           'Sub Total:',
                                        //           style: const TextStyle(
                                        //             fontSize: 22,
                                        //           ),
                                        //         ),
                                        //       ),
                                        //       Container(
                                        //         width: 150,
                                        //         child: Text(
                                        //           '\$${booking.subTotal?.toStringAsFixed(2)}',
                                        //           style: const TextStyle(
                                        //             fontSize: 22,
                                        //           ),
                                        //           textAlign: TextAlign.right,
                                        //         ),
                                        //       ),
                                        //     ],
                                        //   ),
                                        // ),
                                        // Padding(
                                        //   padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        //   child: Row(
                                        //     children: [
                                        //       Expanded(
                                        //         child: Text(
                                        //           'Discount:',
                                        //           style: const TextStyle(
                                        //             fontSize: 22,
                                        //           ),
                                        //         ),
                                        //       ),
                                        //       Container(
                                        //         width: 150,
                                        //         child: Text(
                                        //           '\$${booking.discount?.toStringAsFixed(2)}',
                                        //           style: const TextStyle(
                                        //             fontSize: 22,
                                        //           ),
                                        //           textAlign: TextAlign.right,
                                        //         ),
                                        //       ),
                                        //     ],
                                        //   ),
                                        // ),
                                        // Padding(
                                        //   padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        //   child: Row(
                                        //     children: [
                                        //       Expanded(
                                        //         child: Text(
                                        //           'Grand Total:',
                                        //           style: const TextStyle(
                                        //             fontSize: 22,
                                        //           ),
                                        //         ),
                                        //       ),
                                        //       Container(
                                        //         width: 150,
                                        //         child: Text(
                                        //           '\$${booking.grandTotal?.toStringAsFixed(2)}',
                                        //           style: const TextStyle(
                                        //             fontSize: 22,
                                        //             color: Colors.green
                                        //           ),
                                        //           textAlign: TextAlign.right,
                                        //         ),
                                        //       ),
                                        //     ],
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  if(bookingInfo?['order']!=null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Purchase Details",
                                                    style: GoogleFonts.inter(
                                                      fontSize: 23,
                                                      color: Colors.black,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    "Current purchase items information",
                                                    style: GoogleFonts.inter(
                                                      fontSize: 18,
                                                      color: Colors.black54,
                                                      fontWeight: FontWeight.w400,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    "Order ID : ${bookingInfo?['order']['token_number']}",
                                                    style: GoogleFonts.inter(
                                                      fontSize: 23,
                                                      color: Colors.black,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    "Created by : Manager",
                                                    style: GoogleFonts.inter(
                                                      fontSize: 18,
                                                      color: Colors.black54,
                                                      fontWeight: FontWeight.w400,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          Obx(() {
                                            final Rx<Orders?> order = Rx<Orders?>(null);
                                            order.value = Orders.fromJson(bookingInfo?['order']);
                                            final cartItems = order.value?.cartItems ?? [];

                                            // Calculate total
                                            double total = cartItems.fold(0, (sum, item) => sum + (item.appliedPrice * item.quantity));

                                            return Column(
                                              children: [
                                                ListView.builder(
                                                  shrinkWrap: true,
                                                  physics: const NeverScrollableScrollPhysics(),
                                                  itemCount: cartItems.length,
                                                  itemBuilder: (_, index) {
                                                    final item = cartItems[index];
                                                    return Padding(
                                                      padding: const EdgeInsets.symmetric(
                                                        vertical: 8.0,
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              item.product.name,
                                                              style: const TextStyle(
                                                                fontSize: 22,
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                          Container(
                                                            width: 150,
                                                            child: Text(
                                                              'x${item.quantity}',
                                                              style: const TextStyle(fontSize: 22),
                                                              textAlign: TextAlign.right,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 10),
                                                          Container(
                                                            width: 150,
                                                            child: Text(
                                                              '\$${item.appliedPrice.toStringAsFixed(2)}',
                                                              style: const TextStyle(
                                                                fontSize: 22,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                              textAlign: TextAlign.right,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                                // Add total row
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          'Total:',
                                                          style: const TextStyle(
                                                            fontSize: 22,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        width: 150,
                                                        child: Text(
                                                          '\$${total.toStringAsFixed(2)}',
                                                          style: const TextStyle(
                                                            fontSize: 22,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.green, // You can customize this
                                                          ),
                                                          textAlign: TextAlign.right,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          }),
                                        ],
                                      ),
                                    )
                                  ]

                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget bookingDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 10,
      children: [
        Icon(icon, size: 50, color: Colors.grey[600]),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 22,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 22,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
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
