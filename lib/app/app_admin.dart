import 'package:booking_app/config/palette.dart';
import 'package:booking_app/screens/closecash/closecash.dart';
import 'package:booking_app/screens/customer/membership.dart';
import 'package:booking_app/screens/dashboard/dashboardScreen.dart';
import 'package:booking_app/widgets/sidebar_menu.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../screens/screens.dart';
import '../controllers/auth_controller.dart';
import '../controllers/default_controller.dart';
import '../screens/setting/printer_screen.dart';
import '../screens/shopping/shopping.dart';
import '../widgets/app_scaffold.dart';

class AppAdmin extends StatefulWidget {
  const AppAdmin({Key? key}) : super(key: key);

  @override
  State<AppAdmin> createState() => _AppAdminState();
}

class _AppAdminState extends State<AppAdmin> {
  final authController = Get.find<AuthController>();
  final defaultController = Get.put(DefaultController());

  @override
  void initState() {
    super.initState();
    defaultController.tabIndex.value = 0; // Always reset to dashboard
  }

  Widget _getScreenForIndex(int index) {
    switch (index) {
      case 0:
        return DashboardScreen();
      case 1:
        return ShoppingScreen();
      case 2:
        return MembershipScreen();
      case 3:
        return PrinterScreen();
      case 4:
        return CloseCash();
      default:
        return DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.lightGrey,
      body: GetBuilder<DefaultController>(
        init: defaultController,
        builder: (controller) {
          return AppScaffold(
            sidebar: SidebarMenu(authController: authController),
            body: _getScreenForIndex(controller.tabIndex.value),
          );
        },
      ),
    );
  }
}
