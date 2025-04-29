import 'package:get/get.dart';

import '../screens/screens.dart';

class Routes {
  static final routes = [
    GetPage(
      name: '/',
      page: () => Root(),
    ),
    GetPage(
      name: '/dashboard',
      page: () => Root(),
    ),
  ];
}