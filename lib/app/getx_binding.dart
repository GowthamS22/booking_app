import 'package:badminton_app/controllers/shopping_controller.dart';
import 'package:get/get.dart';

import '../controllers/setting_controller.dart';
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ShoppingController(), fenix: true);
    Get.lazyPut(() => SettingController(), fenix: true);
  }
}

ShoppingController shoppingController = ShoppingController.instance;
SettingController settingController = SettingController.instance;