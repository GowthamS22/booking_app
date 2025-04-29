
import 'package:badminton_app/config/palette.dart';
import 'package:badminton_app/widgets/sidebar_menu.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../components/nonetwork_widget.dart';
import '../screens/screens.dart';
import '../controllers/auth_controller.dart';
import '../controllers/default_controller.dart';
import '../screens/shopping/shopping.dart';
import '../widgets/app_scaffold.dart';

class AppAdmin extends StatefulWidget {
  const AppAdmin({Key? key}) : super(key: key);

  @override
  State<AppAdmin> createState() => _AppAdminState();
}

class _AppAdminState extends State<AppAdmin> {
  final authController    = Get.find<AuthController>();
  final defaultController = Get.put(DefaultController());
  final screenSize     = MediaQuery.of(Get.context!).size.width;
  RxList<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),

  ].obs;

@override
  void initState() {
    // TODO: implement initState

 // Future.delayed(Duration(milliseconds: 1000),() {
 //   if (defaultController.serviceList.length > 0) {
 //     print('checking whether the data is getting');
 //     // for (var service in defaultController.serviceList) {
 //     //   _widgetOptions.add(ServiceScreen(serviceId: service['id'],));
 //     // }
 //   }
 // }
 // ).then((value) =>  );


    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final authController    = Get.find<AuthController>();
    //final defaultController = Get.put(DefaultController());
    final screenSize     = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Palette.lightGrey,
      body: GetBuilder(
        init: DefaultController(),
        builder: (controller) {

          List<Widget> _widgetOptions = <Widget>[
            DashboardScreen(),
          ];

          if(controller.serviceList.length > 0) {
            for(var service in controller.serviceList) {
              _widgetOptions.add(ServiceScreen(serviceId: service['id'],serviceName: service['name'],));
            }
            _widgetOptions.add( ShoppingScreen());
            _widgetOptions.add(CustomerScreen());
            _widgetOptions.add(ReportScreen());
            _widgetOptions.add(SettingScreen());
          }

          return AppScaffold(
            sidebar: SidebarMenu(authController: authController),
            body: _widgetOptions[controller.tabIndex.value],
          );
        },
      ),
    );
  }
}



