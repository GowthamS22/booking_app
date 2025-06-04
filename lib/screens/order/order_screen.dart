// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../../controllers/default_controller.dart';
// import '../dashboard/Tabbar/active_tab_screen.dart';
// import '../dashboard/Tabbar/all_booking_tab_screen.dart';
// import '../dashboard/Tabbar/schedule_tab_screen.dart';
// import '../dashboard/Tabbar/upcoming_tab_screen.dart';

// class OrderScreen extends StatefulWidget {
//   const OrderScreen({super.key});

//   @override
//   State<OrderScreen> createState() => _OrderScreenState();
// }

// class _OrderScreenState extends State<OrderScreen> {
//   final defaultController = Get.find<DefaultController>();
//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 4,
//       child: Scaffold(
//         backgroundColor: Colors.grey.shade200,
//         body: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 width: MediaQuery.of(context).size.width / 2.3,
//                 //    margin: const EdgeInsets.only(left: 16, top: 16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(20),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.grey.shade300,
//                       blurRadius: 5,
//                       spreadRadius: 1,
//                       offset: const Offset(0, 3),
//                     ),
//                   ],
//                 ),
//                 // margin: const EdgeInsets.only(left: 16, right: 16),
//                 child: TabBar(
//                   controller: defaultController.tabController,

//                   indicator: BoxDecoration(
//                     color: Colors.indigo.shade500,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   labelPadding: const EdgeInsets.symmetric(horizontal: 24),
//                   labelColor: Colors.white,
//                   unselectedLabelColor: Colors.black,
//                   indicatorSize: TabBarIndicatorSize.tab,
//                   labelStyle: GoogleFonts.inter(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                   ),
//                   dividerColor: Colors.transparent,
//                   overlayColor: WidgetStateProperty.all(Colors.transparent),
//                   tabs: const [
//                     Tab(text: 'Active'),
//                     Tab(text: 'Upcoming'),
//                     Tab(text: 'Scheduled'),
//                     Tab(text: 'All Booking'),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: TabBarView(
//                   controller: defaultController.tabController,
//                   physics: NeverScrollableScrollPhysics(),
//                   children: [
//                     ActiveTabScreen(),
//                     UpcomingTabScreen(),
//                     ScheduledTabScreen(),
//                     AllBookingTabScreen(),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
