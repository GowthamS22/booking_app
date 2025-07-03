import 'package:booking_app/screens/dashboard/Tabbar/active_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:get/get.dart';
import 'package:booking_app/controllers/order_controller.dart';
import 'package:booking_app/models/booking_model.dart';

import '../../../config/constants.dart';

class ActiveTabScreen extends StatefulWidget {
  const ActiveTabScreen({super.key});

  @override
  State<ActiveTabScreen> createState() => _ActiveTabScreenState();
}

class _ActiveTabScreenState extends State<ActiveTabScreen> {
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

  @override
  void initState() {
    super.initState();
    selectedRows = List.generate(
      bookingController.bookings.length,
      (_) => false,
    );
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // final isTablet = constraints.maxWidth >= 600;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Active Bookings",
                      style: GoogleFonts.inter(
                        fontSize: 25,
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      "Ongoing bookings in real-time",
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
                    ),
                  ),
                ),
                // const SizedBox(width: 20),
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
                //
                // const SizedBox(width: 10),
                // Container(
                //   height: 48,
                //   width: 48,
                //   decoration: BoxDecoration(
                //     color: Colors.white,
                //     borderRadius: BorderRadius.circular(12),
                //     border: Border.all(color: Colors.grey.shade300),
                //   ),
                //   child: const Icon(LucideIcons.filter, size: 32),
                // ),
                const SizedBox(width: 10),
                Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isGridView = true;
                          });
                        },
                        child: Container(
                          width: 70,
                          alignment: Alignment.center,
                          child: Icon(
                            LucideIcons.layoutGrid,
                            size: 40,
                            color:
                                isGridView
                                    ? Colors.indigo.shade500
                                    : Colors.grey.shade900,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isGridView = false;
                          });
                        },
                        child: Container(
                          width: 70,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Icon(
                            LucideIcons.layoutList,
                            size: 40,
                            color:
                                !isGridView
                                    ? Colors.indigo.shade500
                                    : Colors.grey.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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

                final bookings = bookingController.bookings.where((p0) => (p0.customerName!=null && p0.bookingStatus!='Cancelled'),).toList();

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

                return isGridView
                    ? GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 20,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          final b = bookings[index];
                          return GestureDetector(
                            child: BookingCardWidget(booking: b),
                          );
                        },
                      )
                    : Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Custom Header Row
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
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
                                        'Customer & Mobile',
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
                                        'Date & Time',
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
                                        'Remaining',
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
                                  // Expanded(
                                  //   child: Center(
                                  //     child: Text(
                                  //       '',
                                  //       style: GoogleFonts.inter(
                                  //         color: Colors.white,
                                  //         fontSize: 22,
                                  //         fontWeight: FontWeight.w500,
                                  //       ),
                                  //     ),
                                  //   ),
                                  // ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: SizedBox(
                                height:
                                    MediaQuery.of(context).size.height - 200,

                                child: ListView.builder(
                                  padding: const EdgeInsets.only(bottom: 50),
                                  shrinkWrap: true,
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
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
                                                          CrossAxisAlignment
                                                              .center,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          booking.customerName!,
                                                          style:
                                                              GoogleFonts.inter(
                                                                fontSize: 22,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color:
                                                                    Colors
                                                                        .grey
                                                                        .shade900,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),

                                                        if (booking
                                                                .isExtendedBooking ==
                                                            true)
                                                          const Icon(
                                                            Icons.repeat,
                                                            size: 30,
                                                            color:
                                                                Colors.purple,
                                                          ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      booking.customerMobile!,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 22,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade500,
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
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade900,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${booking.courtName}${booking.platformId}',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 22,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade500,
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
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      DateFormat(
                                                        'dd MMM, yyyy',
                                                      ).format(DateTime.now()),
                                                      style: GoogleFonts.inter(
                                                        fontSize: 22,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade900,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${DateFormat('hh:mm a').format(booking.startTime!)} - ${DateFormat('hh:mm a').format(booking.endTime!)}',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 22,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade500,
                                                      ),
                                                    ),
                                                    // Text(
                                                    //   '${DateFormat('hh:mm a').format(booking.extraStart)} - ${DateFormat('hh:mm a').format(booking.extraEnd)}',
                                                    //   style: GoogleFonts.inter(fontSize: 12, color: Colors.blue),
                                                    // ),
                                                  ],
                                                ),
                                              ),

                                              // Remaining Time
                                              Expanded(
                                                child: Align(
                                                  alignment: Alignment.center,
                                                  child: Chip(
                                                    label: Text(
                                                      '${remaining > 0 ? remaining : 0} mins',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 22,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color:
                                                            remaining <= 0
                                                                ? Colors
                                                                    .red
                                                                    .shade500
                                                                : remaining <=
                                                                    15
                                                                ? Colors
                                                                    .orange
                                                                    .shade500
                                                                : Colors
                                                                    .green
                                                                    .shade500,
                                                      ),
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ), // Adjust the radius as needed
                                                      side: BorderSide(
                                                        color:
                                                            remaining <= 0
                                                                ? Colors
                                                                    .red
                                                                    .shade500
                                                                : remaining <=
                                                                    15
                                                                ? Colors
                                                                    .orange
                                                                    .shade500
                                                                : Colors
                                                                    .green
                                                                    .shade500,
                                                      ),
                                                    ),
                                                    backgroundColor:
                                                        remaining <= 0
                                                            ? Colors.red.shade50
                                                            : remaining <= 15
                                                            ? Colors
                                                                .orange
                                                                .shade50
                                                            : Colors
                                                                .green
                                                                .shade50,
                                                    labelStyle:
                                                        GoogleFonts.inter(
                                                          color:
                                                              remaining <= 0
                                                                  ? Colors
                                                                      .red
                                                                      .shade500
                                                                  : remaining <=
                                                                      15
                                                                  ? Colors
                                                                      .orange
                                                                      .shade500
                                                                  : Colors
                                                                      .green
                                                                      .shade500,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Center(
                                                  child: Text(
                                                    "\$ ${b.grandTotal!.toStringAsFixed(2)}",
                                                    style: GoogleFonts.inter(
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          Colors.grey.shade900,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              //Pay Button
                                              // Expanded(
                                              //   child: Align(
                                              //     alignment: Alignment.center,
                                              //     child: Chip(
                                              //       label:
                                              //           b.paymentStatus !=
                                              //                   'Paid'
                                              //               ? Text(
                                              //                 "Pay",
                                              //                 style: GoogleFonts.inter(
                                              //                   fontSize: 22,
                                              //                   fontWeight:
                                              //                       FontWeight
                                              //                           .w500,
                                              //                 ),
                                              //               )
                                              //               : Text(
                                              //                 "Paid",
                                              //                 style: GoogleFonts.inter(
                                              //                   fontSize: 22,
                                              //                   fontWeight:
                                              //                       FontWeight
                                              //                           .w600,
                                              //                 ),
                                              //               ),
                                              //       shape: RoundedRectangleBorder(
                                              //         borderRadius:
                                              //             BorderRadius.circular(
                                              //               20,
                                              //             ), // Adjust the radius as needed
                                              //         side: BorderSide(
                                              //           color:
                                              //               Colors
                                              //                   .green
                                              //                   .shade500,
                                              //         ),
                                              //       ),
                                              //       backgroundColor:
                                              //           b.paymentStatus !=
                                              //                   'Paid'
                                              //               ? Colors
                                              //                   .green
                                              //                   .shade50
                                              //               : Colors
                                              //                   .green
                                              //                   .shade500,
                                              //       labelStyle:
                                              //           GoogleFonts.inter(
                                              //             color:
                                              //                 b.paymentStatus ==
                                              //                         'Paid'
                                              //                     ? Colors.white
                                              //                     : Colors
                                              //                         .green
                                              //                         .shade500,
                                              //           ),
                                              //     ),
                                              //   ),
                                              // ),
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
                          ],
                        ),
                      ),
                    );
              }),
            ),
          ],
        );
      },
    );
  }

  Color _getProgressColor(int remaining) {
    if (remaining <= 5) return Colors.red;
    if (remaining <= 15) return Colors.orange;
    return Colors.green;
  }

  Widget bookingsCard({required BookingModel booking}) {
    final totalDuration =
        booking.endTime!.difference(booking.startTime!).inMinutes;

    final now = DateTime.now();
    final elapsed =
        now.isBefore(booking.startTime!)
            ? 0
            : now.isAfter(booking.endTime!)
            ? totalDuration
            : now.difference(booking.startTime!).inMinutes;

    final remaining = (totalDuration - elapsed).clamp(0, totalDuration);
    final progress = (elapsed / totalDuration).clamp(0.0, 1.0);

    final Color progressColor = _getProgressColor(remaining);

    return Container(
      width: 180,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      color: progressColor,
                      strokeWidth: 10,
                      backgroundColor: Colors.grey.shade200,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${remaining.toString().padLeft(2, '0')}:00",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "mins",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.attach_money, color: Colors.red, size: 20),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            booking.customerName ?? '',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6),

          Text(
            '${booking.sportname ?? ''} - ${booking.courtName ?? ''}',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6),

          Text(
            '${DateFormat('hh:mm a').format(booking.startTime!)} - ${DateFormat('hh:mm a').format(booking.endTime!)}',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.blue),
          ),
        ],
      ),
    );
  }
}
