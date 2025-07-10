import 'package:booking_app/config/palette.dart';
import 'package:booking_app/controllers/simple_controller.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import '../../models/booking_model.dart';
import '../../controllers/new_booking_controller.dart';
import '../checkout/checkout_screen.dart' as checkout;

bool isBookingEnded(DateTime? endTime) {
  if (endTime == null) return true;
  return DateTime.now().isAfter(endTime);
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

String formatRemainingTime(DateTime startTime, DateTime endTime) {
  final now = DateTime.now();

  if (now.isBefore(startTime)) {
    // Not started yet
    final duration = startTime.difference(now);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;

    return hours > 0
        ? 'Starts in $hours:$minutes:$seconds'
        : 'Starts in $minutes:$seconds';
  } else if (now.isAfter(endTime)) {
    return 'Ended'; // Already finished
  } else {
    final duration = endTime.difference(now);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return hours > 0
        ? '$hours:$minutes:$seconds' // e.g. 1:04:01
        : '$minutes:$seconds';      // e.g. 04:01
  }
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
      required Map<String, Map<String, dynamic>> slotInfoMap,
      required double Function() updateTotalPrice,
      required void Function(double price, bool isApplied) onMembershipApplied,
      required DateTime mergedStartTime,
      required DateTime mergedEndTime,
      required VoidCallback onRefresh,
    }) async {
  final timeFormat = DateFormat('hh:mm a');
  final dateFormat = DateFormat('dd MMM yyyy');
  final bookingEnded = isBookingEnded(mergedEndTime);

  final SimpleController simpleController = Get.put(SimpleController());
  simpleController.fetchOrders(bookingId: booking.bookingId);

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
        final List<int> possibleDurations = [30, 60, 90, 120];
        final List<int> availableDurations = [];
        final endTime = mergedEndTime;
        if (endTime == null || bookingEnded) return availableDurations;

        // Helper: is slot booked by this booking
        bool isSlotBookedByMe(DateTime checkTime) {
          return controller.bookedSlots.any(
                (b) =>
            b.court == booking.court &&
                b.startTime != null &&
                b.startTime!.year == checkTime.year &&
                b.startTime!.month == checkTime.month &&
                b.startTime!.day == checkTime.day &&
                b.startTime!.hour == checkTime.hour &&
                b.startTime!.minute == checkTime.minute &&
                b.bookingId == booking.bookingId,
          );
        }

        // Helper: is slot booked by anyone
        bool isSlotBookedByAnyone(DateTime checkTime) {
          return controller.bookedSlots.any(
                (b) =>
            b.court == booking.court &&
                b.startTime != null &&
                b.startTime!.year == checkTime.year &&
                b.startTime!.month == checkTime.month &&
                b.startTime!.day == checkTime.day &&
                b.startTime!.hour == checkTime.hour &&
                b.startTime!.minute == checkTime.minute,
          );
        }

        for (int duration in possibleDurations) {
          bool isDurationAvailable = true;
          for (int i = 0; i < duration; i += 30) {
            final checkTime = endTime.add(Duration(minutes: i));
            final checkTimeStr = DateFormat('HH:mm').format(checkTime);

            // Check if this slot exists in the timeSlots
            bool isSlotValid = controller.timeSlots.contains(checkTimeStr);

            // Check if this slot is booked by anyone (except the current booking)
            bool isSlotBooked = controller.bookedSlots.any(
                  (b) =>
              b.court == booking.court &&
                  b.startTime != null &&
                  b.startTime!.year == checkTime.year &&
                  b.startTime!.month == checkTime.month &&
                  b.startTime!.day == checkTime.day &&
                  b.startTime!.hour == checkTime.hour &&
                  b.startTime!.minute == checkTime.minute &&
                  b.bookingId !=
                      booking.bookingId, // Only allow if it's the same booking
            );

            // Debug print for each slot
            print(
              'Checking duration $duration: $checkTimeStr valid=$isSlotValid booked=$isSlotBooked',
            );

            if (!isSlotValid || isSlotBooked) {
              isDurationAvailable = false;
              break; // Stop checking this duration if any slot is not available
            }
          }
          if (isDurationAvailable) {
            availableDurations.add(duration);
          }
          // Do NOT break here! Continue checking other durations.
        }
        print('Available durations: $availableDurations');
        return availableDurations;
      }

      final List<int> durations = calculateAvailableDurations();

      // Add a ValueNotifier for payment status
      final ValueNotifier<String> paymentStatus = ValueNotifier<String>(
        booking.paymentStatus ?? 'Unpaid',
      );

      Widget buildExtendTimeButtons() {
        return ValueListenableBuilder<int?>(
          valueListenable: selectedDuration,
          builder: (context, duration, child) {
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

            // Use isExtensionConfirmed to control what is shown
            return ValueListenableBuilder<bool>(
              valueListenable: isExtensionConfirmed,
              builder: (context, confirmed, child) {
                if (!confirmed) {
                  // Show time options and Confirm button
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                isNextSlotAvailable.value = false;
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade300,
                                foregroundColor: Colors.white,
                                minimumSize: Size.fromHeight(60),
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
                                paymentStatus.value = 'Unpaid';
                                controller.extendBooking(
                                  originalBookingSlot: booking,
                                  extensionInMinutes: selectedDuration.value,
                                  slotInfoMap: slotInfoMap,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo.shade500,
                                foregroundColor: Colors.white,
                                minimumSize: Size.fromHeight(60),
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
                } else {
                  // After confirmation: show only the green booking extended message
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.checkCheck,
                        color: Colors.green.shade500,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Booking extended",
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                }
              },
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
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
                                        mergedEndTime != null
                                            ? formatRemainingTime(mergedStartTime, mergedEndTime)
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
                                if (!bookingEnded)
                                  GestureDetector(
                                    onTap: () {
                                      showNoShowDialog(
                                        context,
                                        booking.bookingId ?? '',
                                        controller,
                                        onRefresh: onRefresh,
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
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
                              ],
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
                                            booking.service ?? 'N/A',
                                          ),
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
                                          ValueListenableBuilder<bool>(
                                            valueListenable: isExtensionConfirmed,
                                            builder: (context, confirmed, child) {
                                              return bookingDetailRow(
                                                LucideIcons.timer,
                                                "Extended Time",
                                                confirmed &&
                                                    selectedDuration.value != null
                                                    ? "${selectedDuration.value} mins"
                                                    : "---",
                                              );
                                            },
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
                                            booking.court ?? 'N/A',
                                          ),
                                          bookingDetailRow(
                                            LucideIcons.timer,
                                            "Duration",
                                            mergedStartTime != null &&
                                                mergedEndTime != null
                                                ? '${mergedEndTime.difference(mergedStartTime.toLocal()).inMinutes} min'
                                                : 'N/A',
                                          ),
                                          ValueListenableBuilder<String>(
                                            valueListenable: paymentStatus,
                                            builder: (context, status, child) {
                                              return bookingDetailRow(
                                                LucideIcons.dollarSign,
                                                "Payment",
                                                status,
                                              );
                                            },
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
                                          : !bookingEnded
                                          ? TextButton(
                                        onPressed: () {
                                          final availableDurations =
                                          calculateAvailableDurations();
                                          if (availableDurations.isEmpty) {
                                            showCourtUnavailableDialog(
                                              context,
                                              controller: controller,
                                              originalBookingId:
                                              booking.bookingId.toString(),
                                              slotInfoMap: slotInfoMap,
                                              onRefresh: () {},
                                            );
                                            return;
                                          }
                                          isNextSlotAvailable.value = true;
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
                                      )
                                          : SizedBox.shrink();
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            if (simpleController.orders.isNotEmpty)
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
                                  const SizedBox(height: 20),
                                  Obx(() {
                                    return Column(
                                      children: simpleController.orders.map((order) {
                                        return Container(
                                          padding: const EdgeInsets.all(12),
                                          margin: EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade300),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (simpleController.orders.length > 1) ...[
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
                                                          order.createdAt != null
                                                              ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(order.createdAt.toString()))
                                                              : '',
                                                          style: const TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 20,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.end,
                                                      children: [
                                                        Text(
                                                          "Order ID : ${order.tokenNumber ?? ''}",
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
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 20),
                                              ], // Only show order header if multiple orders
                                              ...order.cartItems!.map((item) {
                                                return Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                                              }).toList(),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  }),
                                ],
                              ),

                          ],
                        ),
                      ),
                    ),

                    if (!bookingEnded)
                      Row(
                        spacing: 20,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade300,
                                foregroundColor: Colors.white,
                                minimumSize: Size.fromHeight(60),
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
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                showCancelDialog(
                                  context,
                                  booking.bookingId ?? '',
                                  controller as NewBookingController,
                                  onRefresh: onRefresh,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade50,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 60),
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
                          ),
                        ],
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
    NewBookingController controller, {
      required VoidCallback onRefresh,
    }) {

  final TextEditingController reasonController = TextEditingController(); // Step 1

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
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
          TextField(
            style: TextStyle(fontSize: 22),
            controller: reasonController, // Step 2
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Reason for cancellation',
              hintStyle: GoogleFonts.inter(
                color: Colors.grey[500],
                fontSize: 22,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
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
                    final reason = reasonController.text.trim(); // Step 3
                    if(reason.isEmpty) {
                      showCustomSnackbar('Warning', 'Cancellation reason required', Colors.orange);
                      return;
                    }
                    await controller.cancelBooking(bookingId, reason); // Step 4
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Close drawer
                    onRefresh(); // Call the refresh callback
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

void showNoShowDialog(
    BuildContext context,
    String bookingId,
    NewBookingController controller, {
      required VoidCallback onRefresh,
    }) {
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
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Close drawer
                    onRefresh(); // Call the refresh callback
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
      required NewBookingController controller,
      required String originalBookingId,
      required Map<String, Map<String, dynamic>> slotInfoMap,
      required VoidCallback onRefresh,
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
                          originalBookingId: originalBookingId,
                          slotInfoMap: slotInfoMap,
                          onRefresh: onRefresh,
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
      required String originalBookingId,
      required Map<String, Map<String, dynamic>> slotInfoMap,
      required VoidCallback onRefresh,
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
        final nowWithBuffer = DateTime.now().add(Duration(minutes: 5));

        // Skip if slot is in the past or within 5 minutes from now
        if (_isSlotInPastForExtension(timeSlot, currentDate) ||
            slotTime.isBefore(nowWithBuffer)) {
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
      final nowWithBuffer = DateTime.now().add(Duration(minutes: 5));

      // Skip if slot is in the past or within 5 minutes from now
      if (_isSlotInPastForExtension(timeSlot, currentDate) ||
          slotTime.isBefore(nowWithBuffer)) {
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

          // Assume courts is a List<String> of court names
          final int courtsPerRow = (availableCourts.length / 2).ceil();
          final List<String> firstRowCourts =
          availableCourts.take(courtsPerRow).toList();
          final List<String> secondRowCourts =
          availableCourts.skip(courtsPerRow).toList();

          // Assume slots is a List<String> of slot times
          final int slotsPerRow = 5; // Adjust as needed
          final int maxRows = 3;
          final List<List<String>> slotRows = [];
          for (
          int i = 0;
          i < availableSlots.length && slotRows.length < maxRows;
          i += slotsPerRow
          ) {
            slotRows.add(availableSlots.skip(i).take(slotsPerRow).toList());
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
              constraints: BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Available Courts",
                      style: GoogleFonts.inter(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Select any available court to continue the game",
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),

                    // Select Time
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Select Time",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 22,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 25,
                        runSpacing: 25,
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
                                  fontSize: 22,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Select Court
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Select Court",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 22,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No courts available for ${times[selectedTimeIndex]}',
                                style: GoogleFonts.inter(
                                  color: Colors.red.shade600,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      // Two rows of square, horizontally scrollable, selectable tiles (4 per row)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // First row
                          SizedBox(
                            height: 48, // Adjust for square
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: firstRowCourts.length,
                              separatorBuilder: (_, __) => SizedBox(width: 16),
                              itemBuilder: (context, index) {
                                final court = firstRowCourts[index];
                                final isSelected = selectedCourtIndex == index;
                                return _buildCourtTile(
                                  court,
                                  isSelected: isSelected,
                                  onTap: () {
                                    setState(() {
                                      selectedCourtIndex = index;
                                      selectedSlotIndex = 0;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 15),
                          // Second row
                          SizedBox(
                            height: 48,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: secondRowCourts.length,
                              separatorBuilder: (_, __) => SizedBox(width: 16),
                              itemBuilder: (context, index) {
                                final court = secondRowCourts[index];
                                final isSelected =
                                    selectedCourtIndex == index + courtsPerRow;
                                return _buildCourtTile(
                                  court,
                                  isSelected: isSelected,
                                  onTap: () {
                                    setState(() {
                                      selectedCourtIndex = index + courtsPerRow;
                                      selectedSlotIndex = 0;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 15),

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
                      const SizedBox(height: 12),
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
                      else ...[
                        // Three rows of horizontally scrollable, selectable slot tiles (5 per row)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(slotRows.length, (rowIndex) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: SizedBox(
                                height: 48,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: slotRows[rowIndex].length,
                                  separatorBuilder:
                                      (_, __) => SizedBox(width: 8),
                                  itemBuilder: (context, index) {
                                    final slot = slotRows[rowIndex][index];
                                    final isSelected =
                                        selectedSlotIndex ==
                                            index + rowIndex * slotsPerRow;
                                    return _buildSlotTile(
                                      slot,
                                      isSelected: isSelected,
                                      onTap: () {
                                        setState(() {
                                          selectedSlotIndex =
                                              index + rowIndex * slotsPerRow;
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
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
                              minimumSize: Size.fromHeight(60),
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
                            onPressed: () async {
                              // Preconditions
                              if (selectedTimeIndex == null ||
                                  availableCourts.isEmpty ||
                                  availableSlots.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Please select duration, court, and start time.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              final int selectedMinutes =
                              timeDurations[selectedTimeIndex];
                              final String selectedCourtName =
                              availableCourts[selectedCourtIndex];
                              final String selectedCourtId =
                              controller.courtList.firstWhere(
                                    (c) => c['name'] == selectedCourtName,
                              )['id'];
                              final String selectedSlotText =
                              availableSlots[selectedSlotIndex];
                              // Parse start and end time from slot text, e.g. "16:00 - 16:30"
                              final times = selectedSlotText.split(' - ');
                              final DateTime startTime = DateFormat(
                                'hh:mm a',
                              ).parse(times[0]);
                              final DateTime endTime = DateFormat(
                                'hh:mm a',
                              ).parse(times[1]);
                              final DateTime bookingDate = DateTime(
                                controller.selectedDate.year,
                                controller.selectedDate.month,
                                controller.selectedDate.day,
                                startTime.hour,
                                startTime.minute,
                              );

                              // Call controller logic
                              await controller.extendBookingDifferentCourt(
                                bookingId: originalBookingId,
                                courtId: selectedCourtId,
                                serviceId: controller.selectedServiceId.value,
                                startTime: bookingDate,
                                duration: selectedMinutes,
                                slotInfoMap: slotInfoMap,
                              );

                              // Close both dialogs (court available + right-side popup)
                              Navigator.of(
                                context,
                              ).pop(); // Closes court available dialog
                              Navigator.of(
                                context,
                              ).pop(); // Closes right-side popup
                              onRefresh(); // Refresh parent UI
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              availableCourts.isNotEmpty &&
                                  availableSlots.isNotEmpty
                                  ? Colors.green.shade500
                                  : Colors.grey.shade300,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              minimumSize: Size.fromHeight(60),
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

Widget _buildCourtTile(
    String court, {
      required bool isSelected,
      required VoidCallback onTap,
    }) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      // width: 80,
      // height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.shade500 : Colors.green.shade50,
        border: Border.all(color: Colors.green.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        court,
        style: GoogleFonts.inter(
          color: isSelected ? Colors.white : Colors.green.shade500,
          fontWeight: FontWeight.w600,
          fontSize: 22,
        ),
      ),
    ),
  );
}

Widget _buildSlotTile(
    String slot, {
      required bool isSelected,
      required VoidCallback onTap,
    }) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      // width: 110,
      // height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
      decoration: BoxDecoration(
        color: isSelected ? Colors.indigo.shade500 : Colors.indigo.shade50,
        border: Border.all(color: Colors.indigo.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        slot,
        style: GoogleFonts.inter(
          color: isSelected ? Colors.white : Colors.indigo.shade500,
          fontWeight: FontWeight.w600,
          fontSize: 22,
        ),
      ),
    ),
  );
}