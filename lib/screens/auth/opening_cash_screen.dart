import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/constants.dart';
import '../../config/palette.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/checkout_number_pad.dart';

class OpeningCashScreen extends StatefulWidget {
  const OpeningCashScreen({Key? key}) : super(key: key);

  @override
  State<OpeningCashScreen> createState() => _OpeningCashScreenState();
}

class _OpeningCashScreenState extends State<OpeningCashScreen> {
  final AuthController authController = Get.put(AuthController());
  TextEditingController cashController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    Widget _startBtn = Obx(
      () =>
          authController.startLoading == false
              ? ElevatedButton(
                onPressed: () {
                  if (cashController.text.isNotEmpty) {
                    setState(() {
                      authController.startLoading.value = true;
                    });
                    authController.validateOpenCashStatus().then((value) {
                      if (value == true) {
                        authController.addOpenCash(
                          openingAmount: double.parse(cashController.text),
                        );
                      }
                    });
                  } else {
                    showCustomSnackbar(
                      'Warning',
                      'Please Enter the Amount',
                      Colors.orange,
                    );
                  }
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    Colors.indigo.shade500,
                  ),
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(
                      vertical: 10 * ffem,
                      horizontal: 50 * ffem,
                    ),
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10 * ffem),
                    ),
                  ),
                ),
                child: Text(
                  'Start',
                  style: GoogleFonts.poppins(
                    fontSize: 15 * ffem,
                    color: Colors.white,
                  ),
                ),
              )
              : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: Colors.grey,
                ),
                height: 40 * ffem,
                width: MediaQuery.of(context).size.width / 6,
                child: Center(
                  child: SizedBox(
                    height: 30,
                    width: 30,
                    child: CircularProgressIndicator(
                      color: Colors.indigo.shade500,
                    ),
                  ),
                ),
              ),
    );

    return Scaffold(
      body: Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 30),
                  Text(
                    'Opening Cash in Register',
                    style: GoogleFonts.poppins(
                      fontSize: 25 * ffem,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 30),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 3,
                    child: Column(
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 4,
                          child: TextFormField(
                            controller: cashController,
                            style: GoogleFonts.poppins(
                              fontSize: 40 * ffem,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade500,
                            ),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.attach_money_sharp,
                                size: 40 * ffem,
                                color: Colors.indigo.shade500,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 50),
                        ..._buildKeypad(setState, (val) {
                          setState(() {
                            //  if (cashController.text.isNotEmpty) {
                            //     cashController.text  = cashController.text.substring(
                            //       0,
                            //       cashController.text.length - 1,
                            //     );
                            //   }
                            //  else {
                            //   cashController.text += val;
                            // }
                            if (val == '⌫') {
                              if (cashController.text.isNotEmpty) {
                                cashController.text = cashController.text
                                    .substring(
                                      0,
                                      cashController.text.length - 1,
                                    );
                              }
                            } else {
                              cashController.text += val;
                            }
                          });
                        }),
                        // CheckoutNumberPad(
                        //   submitForm: () {},
                        //   onBackspaceTap: () {
                        //     setState(() {
                        //       if (cashController.text.isNotEmpty) {
                        //         cashController.text = cashController.text
                        //             .substring(
                        //               0,
                        //               cashController.text.length - 1,
                        //             );
                        //       }
                        //     });
                        //   },
                        //   onNumberTap: (number) {
                        //     setState(() {
                        //       if (number == '.') {
                        //         if (cashController.text.length > 0) {
                        //           cashController.text += number;
                        //         }
                        //       } else {
                        //         cashController.text += number;
                        //       }
                        //     });
                        //   },
                        // ),
                        SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                authController.logOut();
                              },
                              style: ButtonStyle(
                                backgroundColor: WidgetStatePropertyAll(
                                  Colors.white54,
                                ),
                                padding: WidgetStatePropertyAll(
                                  EdgeInsets.symmetric(
                                    vertical: 10 * ffem,
                                    horizontal: 50 * ffem,
                                  ),
                                ),
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      10 * ffem,
                                    ),
                                  ),
                                ),
                              ),
                              child: Text(
                                'Logout',
                                style: GoogleFonts.poppins(
                                  fontSize: 16 * ffem,
                                  color: Colors.indigo.shade500,
                                ),
                              ),
                            ),
                            SizedBox(width: 20),
                            _startBtn,
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildKeypad(
    void Function(void Function()) setState,
    Function(String) onPressed,
  ) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '⌫'],
    ];

    return keys.map((row) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            row.map((key) {
              return Padding(
                padding: const EdgeInsets.all(6.0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width / 10,
                  height: 80,
                  child: ElevatedButton(
                    onPressed: () => onPressed(key),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade500,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(color: Colors.grey.shade400, width: 1),
                      ),
                    ),
                    child: Text(
                      key,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      );
    }).toList();
  }
}
