import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/constants.dart';

class NumberPadWidget extends StatefulWidget {
  final Function(String) onNumberTap;
  final Function() onBackspaceTap;
  final Function() submitForm;

  const NumberPadWidget({
    required this.onNumberTap,
    required this.onBackspaceTap,
    required this.submitForm,
    Key? key,
  }) : super(key: key);

  @override
  State<NumberPadWidget> createState() => _NumberPadWidgetState();
}

class _NumberPadWidgetState extends State<NumberPadWidget> {
  final Map<int, double> _scales = {};
  final double _pressedScale = 0.95;
  final double _normalScale = 1.0;
  final Duration _duration = const Duration(milliseconds: 50);

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 12; i++) {
      _scales[i] = _normalScale;
    }
  }

  void _animateButton(int index, VoidCallback onTap) async {
    setState(() => _scales[index] = _pressedScale);
    await Future.delayed(_duration);
    setState(() => _scales[index] = _normalScale);
    onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.8,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildButton('1', 0, onTap: () => widget.onNumberTap('1')),
          _buildButton('2', 1, onTap: () => widget.onNumberTap('2')),
          _buildButton('3', 2, onTap: () => widget.onNumberTap('3')),
          _buildButton('4', 3, onTap: () => widget.onNumberTap('4')),
          _buildButton('5', 4, onTap: () => widget.onNumberTap('5')),
          _buildButton('6', 5, onTap: () => widget.onNumberTap('6')),
          _buildButton('7', 6, onTap: () => widget.onNumberTap('7')),
          _buildButton('8', 7, onTap: () => widget.onNumberTap('8')),
          _buildButton('9', 8, onTap: () => widget.onNumberTap('9')),
          _buildIconButton(Icons.backspace, 9, onTap: widget.onBackspaceTap),
          _buildButton('0', 10, onTap: () => widget.onNumberTap('0')),
          _buildIconButton(Icons.check, 11,
            onTap: widget.submitForm,
            // color: Colors.white,
            // bgColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text, int index, {required VoidCallback onTap}) {
    return AnimatedScale(
      scale: _scales[index] ?? _normalScale,
      duration: _duration,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _animateButton(index, onTap),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 30,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, int index, {
    required VoidCallback onTap,
    Color color = Colors.black,
    Color bgColor = Colors.white,
  }) {
    return AnimatedScale(
      scale: _scales[index] ?? _normalScale,
      duration: _duration,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _animateButton(index, onTap),
          child: Center(
            child: Icon(icon, size: 35, color: color),
          ),
        ),
      ),
    );
  }
}