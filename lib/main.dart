import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toastification/toastification.dart';

import 'app/getx_binding.dart';
import 'components/nonetwork_widget.dart';
import 'controllers/auth_controller.dart';
import 'firebase_options.dart';
import 'screens/checkout/checkoutScreen.dart';
import 'screens/screens.dart';
import 'config/routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SharedPreferences preferences = await SharedPreferences.getInstance();
  await Supabase.initialize(
    url: 'https://idtzbhdgpiirgjjugxfc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlkdHpiaGRncGlpcmdqanVneGZjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0NDg2MzUyMiwiZXhwIjoyMDYwNDM5NTIyfQ.iIeI6EYpO0S2R5jVZnou5xRFEzg_QoGzICS938-MKzw',
    authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
  );
  //Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // SystemChrome.setEnabledSystemUIMode(
  //   SystemUiMode.manual,
  //   overlays: [SystemUiOverlay.bottom],
  // );
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

  // This widget is the root of your application.
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

    final Connectivity connectivity = Connectivity();

    return StreamBuilder<List<ConnectivityResult>>(
      stream:
          connectivity.onConnectivityChanged, // Listen to connectivity changes
      //initialData: ConnectivityResult.wifi, // Provide initial data
      builder: (context, snapshot) {
        final isConnected = snapshot.data != ConnectivityResult.none;
        print(isConnected);
        return ToastificationWrapper(
          child: GetMaterialApp(
            debugShowCheckedModeBanner: false,
            initialBinding: InitialBinding(),
            smartManagement: SmartManagement.keepFactory,
            theme: ThemeData(
              //backgroundColor: Colors.white,
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
            //home: PaymentScreen(),
            // home: CheckoutScreen(
            //   billAmount: 10,
            //   customerName: 'Jamuna',
            //   type: '',
            //   mobileno: '',
            //   selectedDateTime: DateTime.now(),
            //   bookings: [],
            //   membershipID: '',
            //   membershipName: '',
            //   isMembershipApplied: null,
            //   membershipPrice: 0,
            // ),
            home: isConnected ? Root() : NetworkScreen(),
          ),
        );
      },
    );
  }
}
