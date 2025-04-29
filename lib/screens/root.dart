import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../screens/screens.dart';
import '../app/app_admin.dart';

class Root extends GetWidget<AuthController> {
  const Root({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // CheckingTheEmail();
    if (Get.find<AuthController>().centerName.toString() != '') {

      if(Get.find<AuthController>().pin.toString() != '') {
        if(Get.find<AuthController>().openCloseId!=null && Get.find<AuthController>().openCloseId!='') {
          return AppAdmin();
        } else {
          return OpeningCashScreen();
        }
      } else {
        return PinScreen();
      }

    } else {

      return LoginScreen();

    }
  }
}