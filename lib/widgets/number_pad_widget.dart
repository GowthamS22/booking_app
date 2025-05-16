import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../config/constants.dart';

class NumberPadWidget extends StatelessWidget {
  final Function(String) onNumberTap;
  final Function() onBackspaceTap;
  final Function() submitForm;

  NumberPadWidget({required this.onNumberTap, required this.onBackspaceTap, required this.submitForm});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
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
          buildBackspaceButton(),
          buildNumberButton('0'),
          /*buildEmptyButton(),*/
        ],
      ),
    );
  }

  Widget buildNumberButton(String number) {
    return InkWell(
      onTap: () => onNumberTap(number),
      child: Container(
        alignment: Alignment.center,
        margin: EdgeInsets.all(8.0),
        child: Text(
          number,
          style: GoogleFonts.getFont(
              'Poppins',
              fontSize: 20*ffem,
              fontWeight: FontWeight.bold
          ),
        ),
      ),
    );
  }

  Widget buildEmptyButton() {
    return GestureDetector(
      onTap: submitForm,
      child: Container(
        alignment: Alignment.center,
        margin: EdgeInsets.all(8.0),
        child: Icon(
          Icons.subdirectory_arrow_right_outlined,
          size: 30.0,
        ),
      ),
    );
  }

  Widget buildBackspaceButton() {
    return GestureDetector(
      onTap: onBackspaceTap,
      child: Container(
        alignment: Alignment.center,
        margin: EdgeInsets.all(8.0),
        child: Icon(
          Icons.backspace,
          size: 30.0,
        ),
      ),
    );
  }
}
