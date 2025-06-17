import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

import '../../models/booking_model.dart';

Widget bookingDetailRow(IconData icon, String label, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: Colors.grey[600]),
      const SizedBox(width: 6),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ],
  );
}

String formatRemainingTime(DateTime endTime) {
  final now = DateTime.now();
  if (endTime.isBefore(now)) return 'Expired';

  final duration = endTime.difference(now);
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

  return '${duration.inMinutes}:${seconds}';
}

// Helper function to parse time string into DateTime (replicated from court_view_screen.dart)
DateTime _parseTimeForExtension(String slot, DateTime selectedDate) {
  try {
    final parts = slot.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      hour,
      minute,
      0,
      0,
      0,
    );
  } catch (e) {
    print('Error parsing time for extension: $e');
    return DateTime.now(); // Fallback
  }
}

// Helper function to check if a slot is in the past (replicated from court_view_screen.dart)
bool _isSlotInPastForExtension(String slot, DateTime selectedBookingDate) {
  final now = DateTime.now();
  final slotTime = _parseTimeForExtension(slot, selectedBookingDate);

  // Check if the slot's date is before today
  if (slotTime.year < now.year ||
      (slotTime.year == now.year && slotTime.month < now.month) ||
      (slotTime.year == now.year &&
          slotTime.month == now.month &&
          slotTime.day < now.day)) {
    return true; // Slot is on a previous day
  }

  // If it's today, check time
  if (slotTime.year == now.year &&
      slotTime.month == now.month &&
      slotTime.day == now.day) {
    if (slotTime.hour < now.hour) {
      return true;
    } else if (slotTime.hour == now.hour && slotTime.minute < now.minute) {
      return true;
    }
  }
  return false;
}

Future<void> openExtendedbookingRightDrawer(
  BuildContext context,
  BookingSlot booking, {
  required dynamic controller,
  required double Function() updateTotalPrice,
  required void Function(double price, bool isApplied) onMembershipApplied,
}) async {
  final timeFormat = DateFormat('hh:mm a');
  final dateFormat = DateFormat('dd MMM yyyy');

  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Extended Timing',
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
    transitionBuilder: (context, anim1, anim2, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(anim1),
        child: Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: MediaQuery.of(context).size.width / 2.5,
            child: Material(
              color: Colors.white,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Container(
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
                                  booking.name ?? 'N/A',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  booking.mobile ?? 'N/A',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Remaining Time\n',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        booking.endTime != null
                                            ? formatRemainingTime(
                                              booking.endTime!,
                                            )
                                            : 'N/A',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            GestureDetector(
                              onTap: () {
                                showCancelBookingDialog(context);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  border: Border.all(
                                    color: Colors.red.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'No show',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(
                                      LucideIcons.userX,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),

                        /// Booking Details
                        Text(
                          "Booking Details",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "Current booking informations",
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
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
                                  fontSize: 14,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      bookingDetailRow(
                                        LucideIcons.gamepad2,
                                        "Sport",
                                        booking.service ?? 'N/A',
                                      ),
                                      const SizedBox(height: 12),
                                      bookingDetailRow(
                                        LucideIcons.clock,
                                        "Time",
                                        booking.startTime != null &&
                                                booking.endTime != null
                                            ? '${timeFormat.format(booking.startTime!)} - ${timeFormat.format(booking.endTime!)}'
                                            : 'N/A',
                                      ),
                                      const SizedBox(height: 12),
                                      bookingDetailRow(
                                        LucideIcons.timer,
                                        "Extended Time",
                                        "---",
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      bookingDetailRow(
                                        LucideIcons.scanLine,
                                        "Court",
                                        booking.court ?? 'N/A',
                                      ),
                                      const SizedBox(height: 12),
                                      bookingDetailRow(
                                        LucideIcons.timer,
                                        "Duration",
                                        booking.startTime != null &&
                                                booking.endTime != null
                                            ? '${booking.endTime!.difference(booking.startTime!).inMinutes} min'
                                            : 'N/A',
                                      ),
                                      const SizedBox(height: 12),
                                      bookingDetailRow(
                                        LucideIcons.dollarSign,
                                        "Payment",
                                        booking.paymentStatus ?? 'Unpaid',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: () {
                                  final endTime = booking.endTime;
                                  if (endTime == null) {
                                    showCourtUnavailableDialog(context);
                                    return;
                                  }
                                  final nextCalculatedStartTime = endTime.add(
                                    const Duration(minutes: 30),
                                  );
                                  final nextPotentialSlotStr = DateFormat(
                                    'HH:mm',
                                  ).format(nextCalculatedStartTime);

                                  final nextPotentialSlotDateTime =
                                      _parseTimeForExtension(
                                        nextPotentialSlotStr,
                                        booking.date!,
                                      );
                                  bool isNextSlotValidAndFuture =
                                      controller.timeSlots.contains(
                                        nextPotentialSlotStr,
                                      ) &&
                                      !_isSlotInPastForExtension(
                                        nextPotentialSlotStr,
                                        booking.date!,
                                      );

                                  if (!isNextSlotValidAndFuture) {
                                    showCourtUnavailableDialog(context);
                                    return;
                                  }

                                  // Now check if this specific next potential slot is already booked
                                  final isNextSlotBooked = controller
                                      .bookedSlots
                                      .any(
                                        (b) =>
                                            b.court == booking.court &&
                                            b.startTime != null &&
                                            // Compare the start time of booked slots with the the full DateTime of the next potential slot
                                            b.startTime!.year ==
                                                nextPotentialSlotDateTime
                                                    .year &&
                                            b.startTime!.month ==
                                                nextPotentialSlotDateTime
                                                    .month &&
                                            b.startTime!.day ==
                                                nextPotentialSlotDateTime.day &&
                                            b.startTime!.hour ==
                                                nextPotentialSlotDateTime
                                                    .hour &&
                                            b.startTime!.minute ==
                                                nextPotentialSlotDateTime
                                                    .minute,
                                      );
                                  if (isNextSlotBooked) {
                                    showCourtUnavailableDialog(context);
                                  } else {
                                    showCourtAvailableDialog(context);
                                  }
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFFF4F3FF),
                                  foregroundColor: const Color(0xFF6C63FF),
                                  side: const BorderSide(
                                    color: Color(0xFF6C63FF),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  minimumSize: const Size.fromHeight(40),
                                ),
                                child: Text(
                                  'Extend Time',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        Text(
                          "Purchase Details",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "Current purchase order informations",
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Order ID #${booking.bookingId ?? 'N/A'}",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    booking.startTime != null
                                        ? timeFormat.format(booking.startTime!)
                                        : 'N/A',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Court Booking",
                                      style: GoogleFonts.inter(fontSize: 12),
                                    ),
                                  ),
                                  Text(
                                    '1',
                                    style: GoogleFonts.inter(fontSize: 12),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '\$${booking.price?.toStringAsFixed(2) ?? '0.00'}',
                                    style: GoogleFonts.inter(fontSize: 12),
                                  ),
                                ],
                              ),
                              const Divider(),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Grand Total",
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '\$${booking.price?.toStringAsFixed(2) ?? '0.00'}',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade300,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  "Cancel",
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {},

                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  "Pay Now",
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

void showCancelBookingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure?',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This action will cancel the booking and\n'
              'free up the court for others. The\n'
              'customer will not be charged.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.grey.shade50,
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Add cancellation logic here
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade500,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      'Yes',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

void showCourtUnavailableDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Court Unavailable for Extension',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The selected court is already booked for the next slot. '
              'This session \n cannot be extended. You can either end this session now '
              'or move the \n customer to another available court.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.grey.shade50,
                      side: BorderSide(color: Colors.grey.shade200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // End Session Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: End session logic
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.shade500),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      'End Session',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: Colors.red.shade500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        showCourtAvailableDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade500,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(
                        'View Available Court',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
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
      );
    },
  );
}

void showCourtAvailableDialog(BuildContext context) {
  int selectedTimeIndex = 1;
  int selectedCourtIndex = 1;
  int selectedSlotIndex = 1;

  final times = ["30 mins", "60 mins", "90 mins", "120 mins"];
  final courts = ["Court 01", "Court 07", "Court 10", "Court 18"];
  final slots = [
    "04:00 PM - 05:00 PM",
    "07:00 PM - 08:00 PM",
    "08:30 PM - 09:30 PM",
  ];

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 600, // Set your desired dialog max width
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Available Courts",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Select any available court to contine the game",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Select Time
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Select Time",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: List.generate(times.length, (index) {
                          final isSelected = selectedTimeIndex == index;
                          return GestureDetector(
                            onTap:
                                () => setState(() => selectedTimeIndex = index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? Colors.indigo.shade500
                                        : Colors.indigo.shade50,
                                border: Border.all(
                                  color: Colors.indigo.shade200,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                times[index],
                                style: GoogleFonts.inter(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.indigo.shade500,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Select Court
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Select Court",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: List.generate(courts.length, (index) {
                          final isSelected = selectedCourtIndex == index;
                          return GestureDetector(
                            onTap:
                                () =>
                                    setState(() => selectedCourtIndex = index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade50,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                courts[index],
                                style: GoogleFonts.inter(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.grey.shade500,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Select Slot
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Select Slot",
                        style: GoogleFonts.inter(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: List.generate(slots.length, (index) {
                          final isSelected = selectedSlotIndex == index;
                          return GestureDetector(
                            onTap:
                                () => setState(() => selectedSlotIndex = index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? Colors.indigo.shade500
                                        : Colors.indigo.shade50,
                                border: Border.all(
                                  color: Colors.indigo.shade200,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                slots[index],
                                style: GoogleFonts.inter(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.indigo.shade500,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Buttons
                    Row(
                      children: [
                        // Cancel Button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.grey.shade200,
                              foregroundColor: Colors.black,
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context); // Confirm logic here
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade500,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              "Confirm",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );
}
