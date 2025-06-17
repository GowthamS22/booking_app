import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DayChips extends StatelessWidget {
  final List<String> selectedDays;

  const DayChips({Key? key, required this.selectedDays}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          selectedDays.map((day) {
            return Chip(
              label: Text(
                day,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.indigo.shade500,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.indigo.shade500),
              ),
              backgroundColor: Colors.indigo.shade50,
            );
          }).toList(),
    );
  }
}
