import 'package:booking_app/controllers/PosOrderController.dart';
import 'package:booking_app/controllers/cart_controller.dart';
import 'package:booking_app/controllers/shopping_controller.dart';
import 'package:get/get.dart';

import '../controllers/setting_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ShoppingController(), fenix: true);
    Get.lazyPut(() => PrinterController(), fenix: true);
    Get.lazyPut(() => PosOrderController(), fenix: true);
    Get.lazyPut(() => CartController(), fenix: true);
  }
}

//ShoppingController shoppingController = ShoppingController.instance;
PrinterController printerController = PrinterController.instance;
