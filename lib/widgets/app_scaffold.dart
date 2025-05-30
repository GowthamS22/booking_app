import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/constants.dart';
import '../config/palette.dart';
import '../controllers/auth_controller.dart';
import '../controllers/default_controller.dart';
import '../screens/booking/new_booking_screen.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({required this.sidebar, required this.body});
  final Widget sidebar;
  final Widget body;

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  final defaultController = Get.find<DefaultController>();
  final authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        widget.sidebar,
        Expanded(
          flex: 10,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Scaffold(
              //backgroundColor: Colors.grey,

              // appBar: AppBar(
              //   automaticallyImplyLeading: false,
              //   elevation: 0,
              //   toolbarHeight: 80,
              //   backgroundColor: Colors.white,
              //   titleSpacing: 0,
              //   title: Container(
              //     margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
              //     child: TabBar(
              //       controller: defaultController.tabController,
              //       isScrollable: true,
              //       indicator: BoxDecoration(
              //         color: Palette.primaryColor,
              //         borderRadius: BorderRadius.circular(20),
              //       ),
              //       labelPadding: const EdgeInsets.symmetric(horizontal: 24),
              //       labelColor: Colors.white,
              //       unselectedLabelColor: Colors.black,
              //       indicatorSize: TabBarIndicatorSize.tab,
              //       labelStyle: GoogleFonts.poppins(
              //         fontSize: 15,
              //         fontWeight: FontWeight.w500,
              //       ),
              //       dividerColor: Colors.transparent,
              //       overlayColor: WidgetStateProperty.all(Colors.transparent),
              //       tabs: const [
              //         Tab(text: 'Active'),
              //         Tab(text: 'Upcoming'),
              //         Tab(text: 'Scheduled'),
              //         Tab(text: 'All Booking'),
              //       ],
              //     ),
              //   ),
              //   actions: [
              //     Container(
              //       margin: const EdgeInsets.only(top: 16, right: 8),
              //       child: ElevatedButton.icon(
              //         onPressed: () {
              //           Get.to(
              //             NewBookingScreen(type: 'New', selectedBSlots: []),
              //           );
              //         },
              //         icon: Icon(
              //           Icons.add_circle_outline,
              //           color: Colors.white,
              //         ),
              //         label: Text(
              //           'Add Booking',
              //           style: GoogleFonts.poppins(
              //             fontWeight: FontWeight.w500,
              //             color: Colors.white,
              //           ),
              //         ),
              //         style: ElevatedButton.styleFrom(
              //           backgroundColor: Palette.primaryColor,
              //           shape: RoundedRectangleBorder(
              //             borderRadius: BorderRadius.circular(30),
              //           ),
              //           padding: const EdgeInsets.symmetric(
              //             horizontal: 20,
              //             vertical: 12,
              //           ),
              //         ),
              //       ),
              //     ),
              //     Container(
              //       padding: EdgeInsets.symmetric(
              //         horizontal: 5,
              //         vertical: 15,
              //       ),
              //       child: TextButton(
              //         onPressed: () {
              //           authController.logOut();
              //         },
              //         style: ButtonStyle(
              //           backgroundColor: WidgetStatePropertyAll(Colors.white),
              //           padding: WidgetStatePropertyAll(
              //             EdgeInsets.symmetric(vertical: 15, horizontal: 15),
              //           ),
              //           shape: WidgetStatePropertyAll(
              //             RoundedRectangleBorder(
              //               borderRadius: BorderRadius.circular(50),
              //             ),
              //           ),
              //         ),
              //         child: Row(
              //           children: [
              //             Icon(Icons.logout, size: 20, color: Colors.grey),
              //             SizedBox(width: 5),
              //             Text(
              //               'Logout',
              //               style: TextStyle(
              //                 fontSize: 15,
              //                 color: Palette.darkGrey,
              //               ),
              //             ),
              //           ],
              //         ),
              //       ),
              //     ),
              //     SizedBox(width: 20),
              //   ],
              // ),
              body: widget.body,
            ),
          ),
        ),
      ],
    );
  }
}
