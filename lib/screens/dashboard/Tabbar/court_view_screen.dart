import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../screens.dart';

class CourtViewScreen extends StatefulWidget {
  const CourtViewScreen({super.key});

  @override
  State<CourtViewScreen> createState() => _CourtViewScreenState();
}

class _CourtViewScreenState extends State<CourtViewScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Court Availability",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "View and manage court bookings",
                  style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
            Spacer(),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.chevron_right, size: 22),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 150),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.3,
                  child: DropdownButtonFormField<String>(
                    items:
                        [
                          'Badminton',
                          'Cricket',
                          'Table Tennis',
                          'Chess',
                          'Carrom',
                        ].map((String game) {
                          return DropdownMenuItem<String>(
                            value: game,
                            child: Text(
                              game,
                              style: GoogleFonts.roboto(fontSize: 15),
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      // Handle selected value
                      print('Selected game: $value');
                    },
                    decoration: InputDecoration(
                      hintText: 'Select game',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      isDense: true,
                    ),
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.indigo.shade500,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey),
              ),
              child: GestureDetector(
                onTap: () {
                  Get.to(NewBookingScreen(type: 'New', selectedBSlots: []));
                },
                child: Text(
                  'New Booking',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey),
              ),
              child: GestureDetector(
                onTap: () {
                  Get.to(NewBookingScreen(type: 'New', selectedBSlots: []));
                },
                child: Text(
                  'Clear Selection',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}
