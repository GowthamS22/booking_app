// booking_card_widget.dart
import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/booking_model.dart';

class BookingCardWidget extends StatefulWidget {
  final BookingModel booking;

  const BookingCardWidget({super.key, required this.booking});

  @override
  State<BookingCardWidget> createState() => _BookingCardWidgetState();
}

class _BookingCardWidgetState extends State<BookingCardWidget> {
  Timer? _timer;
  Duration remainingDuration = Duration.zero;
  double progress = 0.0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    // Update immediately
    _updateTime();

    // Then update every second for smooth countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateTime();
      } else {
        timer.cancel();
      }
    });
  }

  void _updateTime() {
    final totalDuration = widget.booking.endTime!.difference(widget.booking.startTime!);
    final now = DateTime.now();

    if (now.isBefore(widget.booking.startTime!)) {
      remainingDuration = totalDuration;
      progress = 0.0;
    } else if (now.isAfter(widget.booking.endTime!)) {
      remainingDuration = Duration.zero;
      progress = 1.0;
    } else {
      remainingDuration = widget.booking.endTime!.difference(now);
      final elapsedDuration = now.difference(widget.booking.startTime!);
      progress = (elapsedDuration.inSeconds / totalDuration.inSeconds).clamp(0.0, 1.0);
    }

    if (mounted) {
      setState(() {});
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final Color progressColor = _getProgressColor(remainingDuration.inMinutes);

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
          if (widget.booking.isExtendedBooking == true)
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
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 40,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.booking.paymentStatus == 'Paid'
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.booking.paymentStatus == 'Paid'
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                  ), // Rounded square
                ),
                child: Icon(
                  Icons.attach_money,
                  size: 35,
                  color: widget.booking.paymentStatus == 'Paid'
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CustomPaint(
                    painter: CircleProgressPainter(
                      progress: progress,
                      progressColor: _getProgressColor(remainingDuration.inMinutes),
                      backgroundColor: getBackgroundColor(remainingDuration.inMinutes),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${remainingDuration.inMinutes > 0 ? remainingDuration.inMinutes : 0} mins',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'remaining',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.booking.customerName.toString(),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${widget.booking.sportname} - ${widget.booking.courtName}${widget.booking.platformId}',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    color: Colors.grey.shade600,
                  ),
                ),

                Text(
                  '${widget.booking.startTimeFormatted} - ${widget.booking.endTimeFormatted}',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (widget.booking.isExtendedBooking == true) ...[
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

  Color _getProgressColor(int remainingMinutes) {
    if (remainingMinutes > 30) return Colors.green.shade500;
    if (remainingMinutes > 15) return Colors.orange.shade500;
    return Colors.red.shade500;
  }

  Color getBackgroundColor(int remainingMinutes) {
    if (remainingMinutes > 30) return Colors.green.shade100;
    if (remainingMinutes > 15) return Colors.orange.shade100;
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

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
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