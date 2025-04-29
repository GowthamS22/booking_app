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

  final _formKey = GlobalKey<FormState>();
  final AuthController authController  = Get.put(AuthController());
  TextEditingController cashController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    Widget _startBtn = Obx(() => authController.startLoading==false ?
    ElevatedButton(
      onPressed: () {
        if(cashController.text.isNotEmpty) {
          setState(() {
            authController.startLoading.value = true;
          });
          authController.validateOpenCashStatus().then((value) {
            if(value==true) {
              authController.addOpenCash(openingAmount: double.parse(cashController.text));
            }
          },);
        } else {
         showCustomSnackbar('Warning', 'Please Enter the Amount', Colors.orange);
        }
      },
      child: Text('Start',style: TextStyle(fontSize: 15*ffem),),
      style: ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(Palette.primaryColor),
          padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 12*ffem,horizontal: 80*ffem)),
          shape: MaterialStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10*ffem))
          )
      ),
    )
    :
    Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), color: Colors.grey,),
      height: 40 * ffem,
      width: MediaQuery.of(context).size.width / 5,
      child: Center(
        child: SizedBox(
          height: 30,
          width: 30,
          child: CircularProgressIndicator(
            color: Palette.primaryColor,
          ),
        ),
      ),
    )
    );

    return Scaffold(
      body: Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Opening Cash in Register',style: TextStyle(fontSize: 25*ffem,fontWeight: FontWeight.bold),),
                SizedBox(height: 30,),
                Container(
                  width: MediaQuery.of(context).size.width / 2,
                  child: Column(
                    children: [
                      Container(
                        child: TextFormField(
                          controller: cashController,
                          style: TextStyle(
                              fontSize: 40*ffem,
                              fontWeight: FontWeight.bold,
                              color: Palette.primaryColor
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.attach_money_sharp,size: 40*ffem,color: Palette.primaryColor),
                          ),
                        ),
                        width: MediaQuery.of(context).size.width / 3,
                      ),
                      SizedBox(height: 20,),
                      CheckoutNumberPad(
                        submitForm: () {

                        },
                        onBackspaceTap: () {
                          setState(() {
                            if (cashController.text.isNotEmpty) {
                              cashController.text = cashController.text.substring(0, cashController.text.length - 1);
                            }
                          });
                        },
                        onNumberTap: (number) {
                          setState(() {
                            if(number=='.') {
                              if(cashController.text.length > 0) {
                                cashController.text += number;
                              }
                            } else {
                              cashController.text += number;
                            }
                          });
                        },
                      ),
                      SizedBox(height: 20,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              authController.logOut();
                            },
                            child: Text('Logout',style: TextStyle(fontSize: 15*ffem),),
                            style: ButtonStyle(
                                backgroundColor: MaterialStatePropertyAll(Palette.mediumGrey),
                                padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 12*ffem,horizontal: 80*ffem)),
                                shape: MaterialStatePropertyAll(
                                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(10*ffem))
                                )
                            ),
                          ),
                          _startBtn
                        ],
                      )
                    ],
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
