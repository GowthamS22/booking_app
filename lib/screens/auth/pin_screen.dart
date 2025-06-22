import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:get/get.dart';

import '../../config/constants.dart';
import '../../config/palette.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/number_pad_widget.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({Key? key}) : super(key: key);

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthController authController = Get.put(AuthController());
  TextEditingController pinController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: MediaQuery.of(context).size.width / 2,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bg/intro_bg.png'),
                  fit: BoxFit.fill,
                ),
              ),
              child: Container(
                padding: EdgeInsets.all(100),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'Dropin \nBooking \nSystem',
                    style: GoogleFonts.getFont(
                      'Poppins',
                      fontSize: 30 * ffem,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width / 2,
              height: MediaQuery.of(context).size.height,
              color: Colors.white,
              child: Container(
                padding: EdgeInsets.all(80),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Please Enter your PIN',
                        style: GoogleFonts.getFont(
                          'Poppins',
                          fontSize: 15 * ffem,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 50),
                      Container(
                        width: (MediaQuery.of(context).size.width / 2) / 1.8,
                        child: PinCodeTextField(
                          controller: pinController,
                          appContext: context,
                          pastedTextStyle: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                          length: 4,
                          obscureText: true,
                          obscuringCharacter: ' ',
                          blinkWhenObscuring: false,
                          animationType: AnimationType.fade,
                          validator: (v) {
                            if (v!.length < 4) {
                              //return "I'm from validator";
                            } else {
                              return null;
                            }
                          },
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.circle,
                            borderRadius: BorderRadius.circular(
                              0,
                            ), // Set border radius to 0 for sharp corners
                            borderWidth: 0,
                            fieldHeight: 20,
                            fieldWidth: 20,
                            activeFillColor: Colors.green,
                            selectedFillColor: Colors.green,
                            inactiveFillColor: Colors.white,
                          ),
                          cursorColor: Colors.black,
                          animationDuration: const Duration(milliseconds: 300),
                          enableActiveFill: true,
                          keyboardType: TextInputType.none,
                          boxShadows: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                          onCompleted: (v) {
                            debugPrint("Completed");
                            setState(() {
                              authController.pinLoading.value = true;
                            });
                            authController
                                .pinLogin(memberPin: pinController.text)
                                .then((value) {
                                  if (authController.pin == '' ||
                                      authController.pin == null) {
                                    pinController.clear();
                                  }
                                });
                          },
                          // onTap: () {
                          //   print("Pressed");
                          // },
                          onChanged: (value) {},
                          beforeTextPaste: (text) {
                            debugPrint("Allowing to paste $text");
                            //if you return true then it will show the paste confirmation dialog. Otherwise if false, then nothing will happen.
                            //but you can show anything you want here, like your pop up saying wrong paste format or etc
                            return true;
                          },
                        ),
                      ),
                      SizedBox(height: 20),
                      Obx(
                        () =>
                            authController.pinLoading == false
                                ? Container()
                                : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Please Wait...  ',
                                      style: TextStyle(fontSize: 15 * ffem),
                                    ),
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Palette.primaryColor,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                      NumberPadWidget(
                        onNumberTap: (number) {
                          if (pinController.text.length < 4) {
                            setState(() {
                              pinController.text += number;
                            });
                          }
                        },
                        onBackspaceTap: () {
                          setState(() {
                            if (pinController.text.isNotEmpty) {
                              pinController.text = pinController.text.substring(
                                0,
                                pinController.text.length - 1,
                              );
                            }
                          });
                        },
                        submitForm: () {},
                      ),
                      SizedBox(height: 30),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Forgot PIN?',
                          style: GoogleFonts.getFont(
                            'Mulish',
                            fontSize: 15 * ffem,
                            color: Colors.grey,
                            letterSpacing: 3.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
