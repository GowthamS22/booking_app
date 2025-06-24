// booking_card_widget.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/booking_model.dart';

class BookingCardWidget extends StatelessWidget {
  final BookingModel booking;

  const BookingCardWidget({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
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
      width: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade500),
        boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12)],
      ),
      child: Stack(
        children: [
          // Top left icon
          if (booking.isExtendedBooking == true)
            Positioned(
              top: 0,
              left: 0,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.purple.shade50,
                child: Icon(Icons.sync_alt, size: 28, color: Colors.purple),
              ),
            ),

          // Top right icon
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color:
                    booking.paymentStatus == 'Paid'
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color:
                      booking.paymentStatus == 'Paid'
                          ? Colors.green.shade200
                          : Colors.red.shade200,
                ), // Rounded square
              ),
              child: Icon(
                Icons.attach_money,
                size: 28,
                color:
                    booking.paymentStatus == 'Paid' ? Colors.green : Colors.red,
              ),
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              //mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CustomPaint(
                    painter: CircleProgressPainter(
                      progress: progress,
                      progressColor: _getProgressColor(remaining),
                      backgroundColor: getBackgroundColor(remaining),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            remaining.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'mins',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  booking.customerName.toString(),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${booking.sportname} - ${booking.courtName}${booking.platformId}',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    color: Colors.grey.shade600,
                  ),
                ),

                Text(
                  '${booking.startTimeFormatted} - ${booking.endTimeFormatted}',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (booking.isExtendedBooking == true) ...[
                  //SizedBox(height: 2),
                  Text(
                    'Extended Booking',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: Colors.indigo.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(int remaining) {
    if (remaining > 30) return Colors.green.shade500;
    if (remaining > 15) return Colors.orange.shade500;
    return Colors.red.shade500;
  }

  Color getBackgroundColor(int remaining) {
    if (remaining > 30) return Colors.green.shade100;
    if (remaining > 15) return Colors.orange.shade100;
    return Colors.red.shade100;
  }
}

class CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;

  CircleProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 10.0;
    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 1.8;

    final bgPaint =
        Paint()
          ..color = backgroundColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final fgPaint =
        Paint()
          ..color = progressColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    double startAngle = -pi / 2;
    double sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
