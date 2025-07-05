import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app/getx_binding.dart';
import 'components/nonetwork_widget.dart';
import 'controllers/auth_controller.dart';
import 'screens/checkout/checkoutScreen.dart';
import 'screens/screens.dart';
import 'config/routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SharedPreferences preferences = await SharedPreferences.getInstance();

  await Supabase.initialize(
    url: 'https://vtqqavkfkwbmtnyhunwh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ0cXFhdmtma3dibXRueWh1bndoIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MDc0NzE2MiwiZXhwIjoyMDY2MzIzMTYyfQ.-HWmlBsWK7luHN0b13iqGEw276hoXoeQ61nlVnjrGNQ',
    authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(MyApp(preferences: preferences));
  });
}

class MyApp extends StatefulWidget {
  final preferences;
  const MyApp({Key? key, this.preferences}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.put(AuthController());

    authController.centerName = RxString(
      widget.preferences.getString('centerName') ?? '',
    );
    authController.centerSlug = RxString(
      widget.preferences.getString('centerSlug') ?? '',
    );
    authController.emailID = RxString(
      widget.preferences.getString('emailID') ?? '',
    );
    authController.logoURL = RxString(
      widget.preferences.getString('logoURL') ?? '',
    );
    authController.pin = RxString(widget.preferences.getString('pin') ?? '');
    authController.userName = RxString(
      widget.preferences.getString('userName') ?? '',
    );
    authController.userId = RxString(
      widget.preferences.getString('userId') ?? '',
    );
    authController.staffID = RxString(
      widget.preferences.getString('staffID') ?? '',
    );
    authController.gst = RxString(widget.preferences.getString('gst') ?? '');
    authController.openCloseId = RxString(
      widget.preferences.getString('openCloseId') ?? '',
    );

    return ScreenUtilInit(
      designSize: const Size(1920, 1080), // Standard Full HD for 14 inch tablet
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return ToastificationWrapper(
          child: GetMaterialApp(
            debugShowCheckedModeBanner: false,
            initialBinding: InitialBinding(),
            smartManagement: SmartManagement.keepFactory,
            theme: ThemeData(
              textTheme: GoogleFonts.robotoTextTheme(Theme.of(context).textTheme),
            ),
            getPages: Routes.routes,
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              dragDevices: {
                PointerDeviceKind.mouse,
                PointerDeviceKind.touch,
                PointerDeviceKind.stylus,
                PointerDeviceKind.unknown,
              },
            ),
            home: Root(), // Changed from the connectivity check to directly show Root
          ),
        );
      },
    );
  }
}