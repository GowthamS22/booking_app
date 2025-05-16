import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/palette.dart';

class ReasonForDifference extends StatelessWidget {
  const ReasonForDifference({
    Key? key,
    //required this.closing,
    //required this.authController,
    required this.salesHeading,
    required this.cashHeading,
    required this.cashAmount,
    required this.salesAmount,
    required this.textEditingController,
    required this.textBorderColor,
  }) : super(key: key);

  //final ClosingTillController closing;
  //final AuthController authController;
  final String salesHeading, cashHeading;
  final double salesAmount, cashAmount;
  final TextEditingController textEditingController;
  final Color textBorderColor;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(15.0),
      padding: const EdgeInsets.all(3.0),
      decoration:
      BoxDecoration(border: Border.all(color: Palette.primaryColor)),
      child: Column(
        children: [
          ListTile(
            leading: Text(
              salesHeading,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            trailing: Text(
              '\$ ${salesAmount.toStringAsFixed(2)}',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          ListTile(
            leading: Text(
              cashHeading,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            trailing: Text(
              '\$ ${cashAmount.toStringAsFixed(2)}',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.all(10),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                  color: textBorderColor, // set border color
                  width: 1.0), // set border width
              borderRadius: BorderRadius.all(
                  Radius.circular(10.0)), // set rounded corner radius
            ),
            child: TextField(
              controller: textEditingController,
              // onChanged: (String val){
              //   closing.textBorderColor.value = Colors.blue;
              //   },
              inputFormatters:  [ FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9 .]'))],
              decoration: InputDecoration(
                hintText: ' REASON FOR  DIFFERENCE IN AMOUNT...',
                border: InputBorder.none,
              ),
            ),
          )
        ],
      ),
    );
  }
}