import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:get/get.dart';
import 'package:booking_app/controllers/order_controller.dart';
import 'package:booking_app/models/booking_model.dart';

class AllBookingTabScreen extends StatefulWidget {
  const AllBookingTabScreen({super.key});

  @override
  State<AllBookingTabScreen> createState() => _AllBookingTabScreenState();
}

class _AllBookingTabScreenState extends State<AllBookingTabScreen> {
  final OrderController bookingController = Get.put(OrderController());
  bool isGridView = false;
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
        //final isTablet = constraints.maxWidth >= 600;

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
                      "All Bookings",
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "Complete list of all booked slots",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Spacer(),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.chevron_left, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Today',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.chevron_right, size: 22),
                    ],
                  ),
                ),
                const SizedBox(width: 80),
                Expanded(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.3,
                    child: TextField(
                      style: GoogleFonts.roboto(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'search "john"',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 08,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(LucideIcons.filter, size: 20),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 44,
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
                          width: 44,
                          alignment: Alignment.center,
                          child: Icon(
                            LucideIcons.layoutGrid,
                            size: 20,
                            color:
                                isGridView ? Colors.indigoAccent : Colors.grey,
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
                          width: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Icon(
                            LucideIcons.layoutList,
                            size: 20,
                            color:
                                !isGridView ? Colors.indigoAccent : Colors.grey,
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

                final bookings = bookingController.bookings;

                if (bookings.isEmpty) {
                  return const Center(child: Text("No bookings available."));
                }

                return isGridView
                    ? GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.1,
                          ),
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final b = bookings[index];
                        return GestureDetector(
                          // onTap:
                          //     () => showDialog(
                          //       context: context,
                          //       builder:
                          //           (_) => BookingDetailsDialog(booking: b),
                          //     ),
                          child: bookingsCard(booking: b),
                        );
                      },
                    )
                    : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.shade400,
                          ), // Outer border
                          borderRadius: BorderRadius.circular(8),
                        ),
                        width: MediaQuery.of(context).size.width / 1.1,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            columnSpacing: 30,
                            dataRowHeight: 60,
                            headingRowHeight: 50,
                            // headingRowColor: WidgetStateProperty.all(
                            //   Colors.blue.shade50,
                            // ),
                            dataRowColor: WidgetStateProperty.resolveWith(
                              (states) => Colors.grey.shade50,
                            ),
                            showCheckboxColumn: false,
                            columns: [
                              DataColumn(
                                label: Checkbox(
                                  value: selectAll,
                                  onChanged: (value) {
                                    setState(() {
                                      selectAll = value ?? false;
                                      selectedRows = List.generate(
                                        bookings.length,
                                        (_) => selectAll,
                                      );
                                    });
                                  },
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Booking ID',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Customer',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Date & Time',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Game & Court',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Remaining',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Amount',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DataColumn(label: Text('')),
                            ],
                            rows:
                                bookings.isEmpty
                                    ? []
                                    : List.generate(bookings.length, (index) {
                                      final b = bookings[index];
                                      final remaining =
                                          b.endTime!
                                              .difference(DateTime.now())
                                              .inMinutes;
                                      final isEndingSoon = remaining <= 15;
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Checkbox(
                                              value:
                                                  index < selectedRows.length
                                                      ? selectedRows[index]
                                                      : false,

                                              onChanged: (value) {
                                                setState(() {
                                                  selectedRows[index] =
                                                      value ?? false;
                                                  selectAll = selectedRows
                                                      .every(
                                                        (isChecked) =>
                                                            isChecked,
                                                      );
                                                });
                                              },
                                            ),
                                          ),
                                          DataCell(
                                            Tooltip(
                                              message: b.bookingNo,
                                              child: Text(
                                                b.bookingNo!.toString(),
                                                style: GoogleFonts.inter(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              b.customerName.toString(),
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Center(
                                                  child: Text(
                                                    DateFormat(
                                                      'dd MMM, yyyy',
                                                    ).format(b.startTime!),
                                                    style: GoogleFonts.inter(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  '${DateFormat('hh:mm a').format(b.startTime!)} - ${DateFormat('hh:mm a').format(b.endTime!)}',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          DataCell(
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  b.serviceName ?? '',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                                Text(
                                                  b.courtName ?? '',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          DataCell(
                                            Chip(
                                              label: Text(
                                                '${remaining > 0 ? remaining : 0} mins',
                                                style: GoogleFonts.inter(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              side: BorderSide(
                                                color:
                                                    isEndingSoon
                                                        ? Colors.red
                                                        : Colors.blue,
                                              ),
                                              backgroundColor:
                                                  isEndingSoon
                                                      ? Colors.red.shade100
                                                      : Colors.blue.shade100,
                                              labelStyle: TextStyle(
                                                color:
                                                    isEndingSoon
                                                        ? Colors.red
                                                        : Colors.blue,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              "\$ ${b.grandTotal!.toStringAsFixed(2)}",
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            ElevatedButton(
                                              onPressed: () {
                                                if (b.paymentStatus != 'Paid') {
                                                  //CheckoutScreen(type: 'New');
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                disabledMouseCursor:
                                                    b.paymentStatus == 'Paid'
                                                        ? SystemMouseCursors
                                                            .forbidden
                                                        : SystemMouseCursors
                                                            .click,
                                                backgroundColor:
                                                    b.paymentStatus == 'Paid'
                                                        ? Colors.green.shade50
                                                        : Colors.blue.shade50,
                                                foregroundColor:
                                                    b.paymentStatus == 'Paid'
                                                        ? Colors.green
                                                        : Colors.blue,
                                              ),
                                              child:
                                                  b.paymentStatus != 'Paid'
                                                      ? Text(
                                                        "Pay",
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      )
                                                      : Text(
                                                        "Paid",
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                          ),
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

  Color getProgressColor(int duration) {
    if (duration <= 30) return Colors.pinkAccent.shade400;
    if (duration <= 59) return Colors.orange.shade400;
    return Colors.red.shade400;
  }

  Widget bookingsCard({required BookingModel booking}) {
    final duration = booking.endTime!.difference(booking.startTime!).inMinutes;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.15,
                width: MediaQuery.of(context).size.width * 0.12,
                child: CircularProgressIndicator(
                  value: duration / 60, // adjust denominator as needed
                  color: getProgressColor(duration),
                  // value: 0.5, // Default progress
                  // color: Colors.blue.shade400,
                  strokeWidth: 10,
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "${duration.toString().padLeft(2, '0')}:00\nmins",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            booking.customerName ?? '',
            style: GoogleFonts.inter(
              fontSize: 17,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            booking.courtName ?? '',
            style: GoogleFonts.inter(fontSize: 15, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '${booking.startTime!.hour}:${booking.startTime!.minute.toString().padLeft(2, '0')} - ${booking.endTime!.hour}:${booking.endTime!.minute.toString().padLeft(2, '0')}',
            style: GoogleFonts.inter(fontSize: 15, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
