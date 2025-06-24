import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';

import '../../models/booking_model.dart';
import '../../controllers/new_booking_controller.dart';

Widget bookingDetailRow(IconData icon, String label, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 28, color: Colors.grey[600]),
      const SizedBox(width: 6),
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

// Helper function to check if a slot is in the past for extension (comparing against booking date)
bool _isSlotInPastForExtensionBooking(
  String slot,
  DateTime bookingDate,
  DateTime bookingEndTime,
) {
  final slotTime = _parseTimeForExtension(slot, bookingDate);

  // For extension, we compare against the booking's end time, not current time
  // A slot is "in the past" if it's before or equal to the booking's end time
  return slotTime.isBefore(bookingEndTime) ||
      slotTime.isAtSameMomentAs(bookingEndTime);
}

Future<void> openExtendedbookingRightDrawer(
  BuildContext context,
  BookingSlot booking, {
  required dynamic controller,
  required double Function() updateTotalPrice,
  required void Function(double price, bool isApplied) onMembershipApplied,
  required DateTime mergedStartTime,
  required DateTime mergedEndTime,
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
      // Create ValueNotifiers to maintain state across rebuilds
      final ValueNotifier<bool> isNextSlotAvailable = ValueNotifier<bool>(
        false,
      );
      final ValueNotifier<int?> selectedDuration = ValueNotifier<int?>(null);
      final ValueNotifier<bool> isExtensionConfirmed = ValueNotifier<bool>(
        false,
      );

      // Function to calculate available durations dynamically
      List<int> calculateAvailableDurations() {
        final List<int> possibleDurations = [30, 60, 90, 120]; // Up to 4 hours
        final List<int> availableDurations = [];

        final endTime = booking.endTime;
        if (endTime == null) return availableDurations;

        // Check each possible duration
        for (int duration in possibleDurations) {
          bool isDurationAvailable = true;

          // Check if this duration is available by checking each 30-minute slot
          for (int i = 30; i <= duration; i += 30) {
            final checkTime = endTime.add(Duration(minutes: i));
            final checkTimeStr = DateFormat('HH:mm').format(checkTime);

            bool isSlotValid =
                controller.timeSlots.contains(checkTimeStr) &&
                !_isSlotInPastForExtensionBooking(
                  checkTimeStr,
                  booking.date!,
                  endTime,
                );

            if (!isSlotValid) {
              isDurationAvailable = false;
              break;
            }
            final isSlotBooked = controller.bookedSlots.any(
              (b) =>
                  b.court == booking.court &&
                  b.startTime != null &&
                  b.startTime!.year == checkTime.year &&
                  b.startTime!.month == checkTime.month &&
                  b.startTime!.day == checkTime.day &&
                  b.startTime!.hour == checkTime.hour &&
                  b.startTime!.minute == checkTime.minute,
            );

            if (isSlotBooked) {
              isDurationAvailable = false;
              break;
            }
          }

          if (isDurationAvailable) {
            availableDurations.add(duration);
          } else {
            // If this duration is not available, stop checking longer durations
            break;
          }
        }

        return availableDurations;
      }

      final List<int> durations = calculateAvailableDurations();

      Widget buildExtendTimeButtons() {
        return ValueListenableBuilder<int?>(
          valueListenable: selectedDuration,
          builder: (context, duration, child) {
            // If no durations are available, show a message
            if (durations.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade600, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No extension time available for this court',
                        style: GoogleFonts.inter(
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w500,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cancel and Confirm Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Reset the state to show only the "Extend Time" button
                          isNextSlotAvailable.value = false;
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.white,
                          minimumSize: Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          isExtensionConfirmed.value = true;
                          controller.extendBooking(
                            originalBookingSlot: booking,
                            extensionInMinutes: selectedDuration.value,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade500,
                          foregroundColor: Colors.white,
                          minimumSize: Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          "Confirm",
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children:
                      durations.map((d) {
                        final isSelected = selectedDuration.value == d;
                        return TextButton(
                          onPressed: () {
                            selectedDuration.value = d;
                          },
                          style: TextButton.styleFrom(
                            backgroundColor:
                                isSelected
                                    ? Colors.indigo.shade500
                                    : Colors.indigo.shade50,
                            foregroundColor:
                                isSelected
                                    ? Colors.white
                                    : Colors.indigo.shade500,
                            side: BorderSide(
                              color: Colors.indigo.shade300,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 15,
                            ),
                          ),
                          child: Text(
                            "$d mins",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                              fontSize: 22,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
            );
          },
        );
      }

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
                              booking.name ?? 'N/A',
                              style: GoogleFonts.inter(
                                fontSize: 23,
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              booking.mobile ?? 'N/A',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                color: Colors.grey.shade500,
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
                                  fontSize: 23,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text:
                                    booking.endTime != null
                                        ? formatRemainingTime(booking.endTime!)
                                        : 'N/A',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        GestureDetector(
                          onTap: () {
                            showNoShowDialog(
                              context,
                              booking.bookingId ?? '',
                              controller,
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              border: Border.all(color: Colors.red.shade300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'No show',
                                  style: GoogleFonts.inter(
                                    fontSize: 22,
                                    color: Colors.red.shade500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(
                                  LucideIcons.userX,
                                  color: Colors.red,
                                  size: 23,
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
                      // "Booking Details",
                      "Booking Details : ${booking.id}",
                      style: GoogleFonts.inter(
                        fontSize: 12,
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
                              fontSize: 22,
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    mergedStartTime != null &&
                                            mergedEndTime != null
                                        ? '${timeFormat.format(mergedStartTime.toLocal())} - ${timeFormat.format(mergedEndTime.toLocal())}'
                                        : (booking.startTime != null &&
                                                booking.endTime != null
                                            ? '${timeFormat.format(booking.startTime!.toLocal())} - ${timeFormat.format(booking.endTime!.toLocal())}'
                                            : 'N/A'),
                                  ),
                                  const SizedBox(height: 12),
                                  ValueListenableBuilder<bool>(
                                    valueListenable: isExtensionConfirmed,
                                    builder: (context, confirmed, child) {
                                      return bookingDetailRow(
                                        LucideIcons.timer,
                                        "Extended Time",
                                        confirmed
                                            ? "${selectedDuration.value} mins"
                                            : "---",
                                      );
                                    },
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    mergedStartTime != null &&
                                            mergedEndTime != null
                                        ? '${mergedEndTime.difference(mergedStartTime.toLocal()).inMinutes} min'
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
                          ValueListenableBuilder<bool>(
                            valueListenable: isNextSlotAvailable,
                            builder: (context, isAvailable, child) {
                              return isAvailable
                                  ? buildExtendTimeButtons()
                                  : TextButton(
                                    onPressed: () {
                                      final endTime = booking.endTime;
                                      if (endTime == null) {
                                        showCourtUnavailableDialog(
                                          context,
                                          controller: controller,
                                        );
                                        return;
                                      }
                                      final nextCalculatedStartTime = endTime
                                          .add(const Duration(minutes: 30));
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
                                          !_isSlotInPastForExtensionBooking(
                                            nextPotentialSlotStr,
                                            booking.date!,
                                            booking.endTime!,
                                          );

                                      if (!isNextSlotValidAndFuture) {
                                        showCourtUnavailableDialog(
                                          context,
                                          controller: controller,
                                        );
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
                                                    nextPotentialSlotDateTime
                                                        .day &&
                                                b.startTime!.hour ==
                                                    nextPotentialSlotDateTime
                                                        .hour &&
                                                b.startTime!.minute ==
                                                    nextPotentialSlotDateTime
                                                        .minute,
                                          );
                                      if (isNextSlotBooked) {
                                        showCourtUnavailableDialog(
                                          context,
                                          controller: controller,
                                        );
                                      } else {
                                        isNextSlotAvailable.value = true;
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      backgroundColor: const Color(0xFFF4F3FF),
                                      foregroundColor: Colors.indigo.shade500,
                                      side: BorderSide(
                                        color: Colors.indigo.shade300,
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
                                        fontSize: 23,
                                        color: Colors.indigo.shade500,
                                      ),
                                    ),
                                  );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    Text(
                      "Purchase Details",
                      style: GoogleFonts.inter(
                        fontSize: 23,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "Current purchase order informations",
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Obx(() => ListView.builder(
                      itemCount: controller.bookedSlots.length,
                      itemBuilder: (context, index) {
                        final booking = controller.bookedSlots[index];
                        // ... build your booking item ...
                      },
                    )),
                    Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        showCancelDialog(
                          context,
                          booking.bookingId ?? '',
                          controller as NewBookingController,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.red.shade300),
                        ),
                      ),
                      child: Text(
                        "Cancel Booking",
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          color: Colors.red.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

void showCancelDialog(
  BuildContext context,
  String bookingId,
  NewBookingController controller,
) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder:
        (_) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cancel Booking?',
                style: GoogleFonts.inter(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Are you sure you want to cancel this booking?',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: Size.fromHeight(50),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'No',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await controller.cancelBooking(bookingId);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade500,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: Size.fromHeight(50),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Yes',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Reason for cancellation',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.grey[500],
                    fontSize: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
  );
}

void showNoShowDialog(
  BuildContext context,
  String bookingId,
  NewBookingController controller,
) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder:
        (_) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure?',
                style: GoogleFonts.inter(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'This action will cancel the booking and \nfree up the court for others. \nThe customer will not be charged.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: Size.fromHeight(50),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await controller.markNoShow(bookingId);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade500,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: Size.fromHeight(50),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Yes',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
  );
}

void showCourtUnavailableDialog(
  BuildContext context, {
  required dynamic controller,
}) {
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
                fontSize: 23,
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
                fontSize: 22,
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
                      minimumSize: Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        fontSize: 22,
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
                      minimumSize: Size.fromHeight(50),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      'End Session',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        fontSize: 22,
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
                        showCourtAvailableDialog(
                          context,
                          controller: controller,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade500,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: Size.fromHeight(50),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(
                        'View Available Court',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          fontSize: 22,
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

void showCourtAvailableDialog(
  BuildContext context, {
  required dynamic controller,
}) {
  int selectedTimeIndex = 0; // Default to 30 mins
  int selectedCourtIndex = 0;
  int selectedSlotIndex = 0;

  final times = ["30 mins", "60 mins", "90 mins", "120 mins"];
  final timeDurations = [30, 60, 90, 120]; // Corresponding durations in minutes

  // Get current date for filtering
  final currentDate = DateTime.now();

  // Function to get available courts for selected duration
  List<String> getAvailableCourts(int selectedDuration) {
    final availableCourts = <String>[];

    // Get all courts from controller
    for (var court in controller.courtList) {
      final courtName = court['name'] as String;
      bool isCourtAvailable = false;

      // Check if this court has any available slots for the selected duration
      for (String timeSlot in controller.timeSlots) {
        final slotTime = _parseTimeForExtension(timeSlot, currentDate);

        // Skip if slot is in the past
        if (_isSlotInPastForExtension(timeSlot, currentDate)) {
          continue;
        }

        // Check if this slot and subsequent slots for the duration are available
        bool isDurationAvailable = true;
        for (int i = 0; i < selectedDuration; i += 30) {
          final checkTime = slotTime.add(Duration(minutes: i));
          final checkTimeStr = DateFormat('HH:mm').format(checkTime);

          // Check if this time slot exists in available slots
          if (!controller.timeSlots.contains(checkTimeStr)) {
            isDurationAvailable = false;
            break;
          }

          // Check if this slot is already booked
          final isSlotBooked = controller.bookedSlots.any(
            (b) =>
                b.court == courtName &&
                b.startTime != null &&
                b.startTime!.year == checkTime.year &&
                b.startTime!.month == checkTime.month &&
                b.startTime!.day == checkTime.day &&
                b.startTime!.hour == checkTime.hour &&
                b.startTime!.minute == checkTime.minute,
          );

          if (isSlotBooked) {
            isDurationAvailable = false;
            break;
          }
        }

        if (isDurationAvailable) {
          isCourtAvailable = true;
          break;
        }
      }

      if (isCourtAvailable) {
        availableCourts.add(courtName);
      }
    }

    return availableCourts;
  }

  // Function to get available time slots for selected court and duration
  List<String> getAvailableTimeSlots(
    String selectedCourt,
    int selectedDuration,
  ) {
    final availableSlots = <String>[];
    final timeFormat = DateFormat('hh:mm a');

    for (String timeSlot in controller.timeSlots) {
      final slotTime = _parseTimeForExtension(timeSlot, currentDate);

      // Skip if slot is in the past
      if (_isSlotInPastForExtension(timeSlot, currentDate)) {
        continue;
      }

      // Check if this slot and subsequent slots for the duration are available
      bool isDurationAvailable = true;
      for (int i = 0; i < selectedDuration; i += 30) {
        final checkTime = slotTime.add(Duration(minutes: i));
        final checkTimeStr = DateFormat('HH:mm').format(checkTime);

        // Check if this time slot exists in available slots
        if (!controller.timeSlots.contains(checkTimeStr)) {
          isDurationAvailable = false;
          break;
        }

        // Check if this slot is already booked for the selected court
        final isSlotBooked = controller.bookedSlots.any(
          (b) =>
              b.court == selectedCourt &&
              b.startTime != null &&
              b.startTime!.year == checkTime.year &&
              b.startTime!.month == checkTime.month &&
              b.startTime!.day == checkTime.day &&
              b.startTime!.hour == checkTime.hour &&
              b.startTime!.minute == checkTime.minute,
        );

        if (isSlotBooked) {
          isDurationAvailable = false;
          break;
        }
      }

      if (isDurationAvailable) {
        final endTime = slotTime.add(Duration(minutes: selectedDuration));
        final slotText =
            '${timeFormat.format(slotTime)} - ${timeFormat.format(endTime)}';
        availableSlots.add(slotText);
      }
    }

    return availableSlots;
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          // Get available courts for current selected duration
          final availableCourts = getAvailableCourts(
            timeDurations[selectedTimeIndex],
          );

          // Get available time slots for selected court and duration
          final availableSlots =
              availableCourts.isNotEmpty
                  ? getAvailableTimeSlots(
                    availableCourts[selectedCourtIndex],
                    timeDurations[selectedTimeIndex],
                  )
                  : <String>[];

          // Reset indices if they're out of bounds
          if (selectedCourtIndex >= availableCourts.length) {
            selectedCourtIndex = 0;
          }
          if (selectedSlotIndex >= availableSlots.length) {
            selectedSlotIndex = 0;
          }

          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 10,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 600),
              child: Padding(
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
                      "Select any available court to continue the game",
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
                            onTap: () {
                              setState(() {
                                selectedTimeIndex = index;
                                selectedCourtIndex = 0;
                                selectedSlotIndex = 0;
                              });
                            },
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
                    if (availableCourts.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning,
                              color: Colors.red.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No courts available for ${times[selectedTimeIndex]}',
                                style: GoogleFonts.inter(
                                  color: Colors.red.shade600,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // First row with horizontal scroll (first 4 courts)
                          SizedBox(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount:
                                  availableCourts.length > 4
                                      ? 4
                                      : availableCourts.length,
                              itemBuilder: (context, index) {
                                final isSelected = selectedCourtIndex == index;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedCourtIndex = index;
                                      selectedSlotIndex = 0;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 15),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? Colors.green.shade500
                                              : Colors.green.shade50,
                                      border: Border.all(
                                        color: Colors.green.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      availableCourts[index],
                                      style: GoogleFonts.inter(
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.green.shade500,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Second row with horizontal scroll (courts 5-8)
                          if (availableCourts.length > 4) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 50,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount:
                                    availableCourts.length > 8
                                        ? 4
                                        : availableCourts.length - 4,
                                itemBuilder: (context, index) {
                                  final actualIndex = index + 4;
                                  final isSelected =
                                      selectedCourtIndex == actualIndex;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedCourtIndex = actualIndex;
                                        selectedSlotIndex = 0;
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 15),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? Colors.green.shade500
                                                : Colors.green.shade50,
                                        border: Border.all(
                                          color: Colors.green.shade300,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        availableCourts[actualIndex],
                                        style: GoogleFonts.inter(
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : Colors.green.shade500,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                          // Third row and beyond with wrap (courts 9+)
                          if (availableCourts.length > 8) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 15,
                              runSpacing: 10,
                              children: List.generate(
                                availableCourts.length - 8,
                                (index) {
                                  final actualIndex = index + 8;
                                  final isSelected =
                                      selectedCourtIndex == actualIndex;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedCourtIndex = actualIndex;
                                        selectedSlotIndex = 0;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? Colors.green.shade500
                                                : Colors.green.shade50,
                                        border: Border.all(
                                          color: Colors.green.shade300,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        availableCourts[actualIndex],
                                        style: GoogleFonts.inter(
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : Colors.green.shade500,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),

                    const SizedBox(height: 10),

                    // Select Slot
                    if (availableCourts.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Select Slot",
                          style: GoogleFonts.inter(
                            color: Colors.black,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      if (availableSlots.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            border: Border.all(color: Colors.orange.shade200),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info,
                                color: Colors.orange.shade600,
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'No time slots available for ${availableCourts[selectedCourtIndex]}',
                                  style: GoogleFonts.inter(
                                    color: Colors.orange.shade600,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: List.generate(availableSlots.length, (
                              index,
                            ) {
                              final isSelected = selectedSlotIndex == index;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedSlotIndex = index;
                                  });
                                },
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
                                    availableSlots[index],
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
                    ],

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
                              minimumSize: Size.fromHeight(50),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w500,
                                fontSize: 22,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                availableCourts.isNotEmpty &&
                                        availableSlots.isNotEmpty
                                    ? () {
                                      // TODO: Implement booking logic here
                                      // You can access:
                                      // - Selected duration: timeDurations[selectedTimeIndex]
                                      // - Selected court: availableCourts[selectedCourtIndex]
                                      // - Selected slot: availableSlots[selectedSlotIndex]
                                      Navigator.pop(context);
                                    }
                                    : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  availableCourts.isNotEmpty &&
                                          availableSlots.isNotEmpty
                                      ? Colors.green.shade500
                                      : Colors.grey.shade300,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              minimumSize: Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              "Confirm",
                              style: GoogleFonts.inter(
                                color:
                                    availableCourts.isNotEmpty &&
                                            availableSlots.isNotEmpty
                                        ? Colors.white
                                        : Colors.grey.shade500,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
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
