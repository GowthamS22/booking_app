import 'package:booking_app/config/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/palette.dart';

class CheckoutNumberPad extends StatelessWidget {
  final Function(String) onNumberTap;
  final Function() onBackspaceTap;
  final Function() submitForm;

  CheckoutNumberPad({
    required this.onNumberTap,
    required this.onBackspaceTap,
    required this.submitForm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      //width: MediaQuery.of(context).size.width / 2,
      child: GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 2.3,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: [
          buildNumberButton('1'),
          buildNumberButton('2'),
          buildNumberButton('3'),
          buildNumberButton('4'),
          buildNumberButton('5'),
          buildNumberButton('6'),
          buildNumberButton('7'),
          buildNumberButton('8'),
          buildNumberButton('9'),
          buildNumberButton('.'),
          buildNumberButton('0'),
          buildBackspaceButton(),
        ],
      ),
    );
  }

  Widget buildNumberButton(String number) {
    return InkWell(
      onTap: () => onNumberTap(number),
      child: Container(
        decoration: BoxDecoration(
          color: Palette.fieldBg,
          border: Border.all(color: Colors.indigo.shade500, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        margin: EdgeInsets.all(8.0),
        child: Text(
          number,
          style: GoogleFonts.poppins(
            fontSize: 20 * ffem,
            fontWeight: FontWeight.bold,
            color: Colors.indigo.shade500,
          ),
        ),
      ),
    );
  }

  Widget buildEmptyButton() {
    return GestureDetector(
      onTap: onBackspaceTap,
      child: Container(
        decoration: BoxDecoration(
          color: Palette.fieldBg,
          border: Border.all(color: Palette.primaryColor, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        margin: EdgeInsets.all(8.0),
        child: Text(
          '.',
          style: TextStyle(fontSize: 50, color: Colors.indigo.shade500),
        ),
      ),
    );
  }

  Widget buildBackspaceButton() {
    return GestureDetector(
      onTap: onBackspaceTap,
      child: Container(
        decoration: BoxDecoration(
          color: Palette.fieldBg,
          border: Border.all(color: Colors.indigo.shade500, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        margin: EdgeInsets.all(8.0),
        child: Icon(Icons.backspace, size: 30.0, color: Colors.indigo.shade500),
      ),
    );
  }
}
