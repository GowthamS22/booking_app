import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../config/constants.dart';

class NumberPadWidget extends StatefulWidget {
  final Function(String) onNumberTap;
  final Function() onBackspaceTap;
  final Function() submitForm;

  NumberPadWidget({
    required this.onNumberTap,
    required this.onBackspaceTap,
    required this.submitForm,
  });

  @override
  State<NumberPadWidget> createState() => _NumberPadWidgetState();
}

class _NumberPadWidgetState extends State<NumberPadWidget> {
  // Track scale for each button by index
  final Map<int, double> _scales = {};
  final double _pressedScale = 0.85;
  final double _normalScale = 1.0;
  final Duration _duration = Duration(milliseconds: 90);

  @override
  void initState() {
    super.initState();
    // Initialize all scales to normal
    for (int i = 0; i < 12; i++) {
      _scales[i] = _normalScale;
    }
  }

  void _animateButton(int index, VoidCallback onTap) async {
    setState(() {
      _scales[index] = _pressedScale;
    });
    await Future.delayed(_duration);
    setState(() {
      _scales[index] = _normalScale;
    });
    onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 2, // Make buttons less wide
        crossAxisSpacing: 4, // Reduced space between columns
        mainAxisSpacing: 20,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          buildNumberButton('1', 0),
          buildNumberButton('2', 1),
          buildNumberButton('3', 2),
          buildNumberButton('4', 3),
          buildNumberButton('5', 4),
          buildNumberButton('6', 5),
          buildNumberButton('7', 6),
          buildNumberButton('8', 7),
          buildNumberButton('9', 8),
          buildBackspaceButton(9),
          buildNumberButton('0', 10),
          /*buildEmptyButton(),*/
        ],
      ),
    );
  }

  Widget buildNumberButton(String number, int index) {
    return AnimatedScale(
      scale: _scales[index] ?? _normalScale,
      duration: _duration,
      curve: Curves.easeOut,
      child: InkWell(
        onTap: () => _animateButton(index, () => widget.onNumberTap(number)),
        borderRadius: BorderRadius.circular(100),
        child: Container(
          alignment: Alignment.center,
          margin: EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0),
          child: Text(
            number,
            style: GoogleFonts.getFont(
              'Poppins',
              fontSize: 20 * ffem,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildEmptyButton() {
    return GestureDetector(
      onTap: widget.submitForm,
      child: Container(
        alignment: Alignment.center,
        margin: EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0),
        child: Icon(Icons.subdirectory_arrow_right_outlined, size: 30.0),
      ),
    );
  }

  Widget buildBackspaceButton(int index) {
    return AnimatedScale(
      scale: _scales[index] ?? _normalScale,
      duration: _duration,
      curve: Curves.easeOut,
      child: GestureDetector(
        onTap: () => _animateButton(index, widget.onBackspaceTap),
        child: Container(
          alignment: Alignment.center,
          margin: EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0),
          child: Icon(Icons.backspace, size: 30.0),
        ),
      ),
    );
  }
}
