import 'package:booking_app/screens/dashboard/Tabbar/dashboard_view_screen.dart';
import 'package:booking_app/screens/dashboard/Tabbar/pending_payment.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/default_controller.dart';
import 'Tabbar/active_tab_screen.dart';
import 'Tabbar/all_booking_tab_screen.dart';
import 'Tabbar/court_view_screen.dart';
import 'Tabbar/schedule_tab_screen.dart';
import 'Tabbar/upcoming_tab_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final defaultController = Get.find<DefaultController>();

  String? staffName;

  @override
  void initState() {
    super.initState();
    _loadCenterSlug();
    // Start refresh when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      defaultController.startAutoRefresh();
    });
  }

  @override
  void dispose() {
    // Stop refresh when leaving screen
    defaultController.stopAutoRefresh();
    super.dispose();
  }

  Future<void> _loadCenterSlug() async {
    final preferences = await SharedPreferences.getInstance();
    setState(() {
      staffName = preferences.getString('userName');
    });
  }

  Widget _buildPendingPaymentTab() {
    return Obx(
      () => Tab(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Pending Payment'),
            if (defaultController.pendingPaymentCount.value > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 30, minHeight: 25),
                child: Text(
                  defaultController.pendingPaymentCount.value > 99
                      ? '99'
                      : defaultController.pendingPaymentCount.value.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 22),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      // appBar: AppBar(
      //   automaticallyImplyLeading: false,
      //   elevation: 0,
      //   toolbarHeight: 80,
      //   backgroundColor: Colors.white,
      //   titleSpacing: 0,
      //   title: Container(
      //     margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
      //     child: TabBar(
      //       controller: defaultController.dashboardTabController,
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
      //       tabs: const [Tab(text: 'Active'), Tab(text: 'Upcoming')],
      //     ),
      //   ),

      // actions: [
      //   Container(
      //     margin: const EdgeInsets.only(top: 16, right: 8),
      //     child: ElevatedButton.icon(
      //       onPressed: () {
      //         Get.to(NewBookingScreen(type: 'New', selectedBSlots: []));
      //       },
      //       icon: Icon(Icons.add_circle_outline, color: Colors.white),
      //       label: Text(
      //         'Add Booking',
      //         style: GoogleFonts.poppins(
      //           fontWeight: FontWeight.w500,
      //           color: Colors.white,
      //         ),
      //       ),
      //       style: ElevatedButton.styleFrom(
      //         backgroundColor: Palette.primaryColor,
      //         shape: RoundedRectangleBorder(
      //           borderRadius: BorderRadius.circular(30),
      //         ),
      //         padding: const EdgeInsets.symmetric(
      //           horizontal: 20,
      //           vertical: 12,
      //         ),
      //       ),
      //     ),
      //   ),
      //   Container(
      //     padding: EdgeInsets.symmetric(horizontal: 5, vertical: 15),
      //     child: TextButton(
      //       onPressed: () {
      //         authController.logOut();
      //       },
      //       style: ButtonStyle(
      //         backgroundColor: WidgetStatePropertyAll(Colors.white),
      //         padding: WidgetStatePropertyAll(
      //           EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      //         ),
      //         shape: WidgetStatePropertyAll(
      //           RoundedRectangleBorder(
      //             borderRadius: BorderRadius.circular(50),
      //           ),
      //         ),
      //       ),
      //       child: Row(
      //         children: [
      //           Icon(Icons.logout, size: 20, color: Colors.grey),
      //           SizedBox(width: 5),
      //           Text(
      //             'Logout',
      //             style: TextStyle(fontSize: 15, color: Palette.darkGrey),
      //           ),
      //         ],
      //       ),
      //     ),
      //   ),
      //   SizedBox(width: 20),
      // ],
      // ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width / 1.7,
                  height: MediaQuery.of(context).size.height * .06,
                  //    margin: const EdgeInsets.only(left: 16, top: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 5,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  // margin: const EdgeInsets.only(right: 16),
                  child: TabBar(
                    controller: defaultController.dashboardTabController,
                    onTap: (index) {
                      defaultController.dashboardTabController?.animateTo(
                        index,
                      );
                    },
                    //isScrollable: true,
                    indicator: BoxDecoration(
                      color: Colors.indigo.shade500,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    indicatorPadding: EdgeInsets.all(4),
                    // labelPadding: const EdgeInsets.symmetric(horizontal: 24),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey.shade400,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade50,
                    ),
                    unselectedLabelStyle: GoogleFonts.inter(
                      fontSize: 23,
                      fontWeight: FontWeight.w500,
                    ),

                    dividerColor: Colors.transparent,
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    tabs: [
                      Tab(text: 'Court View'),
                      Tab(text: 'Active'),
                      Tab(text: 'Upcoming'),
                      _buildPendingPaymentTab(),
                      //Tab(text: 'Pending Payment'),
                      // Tab(text: 'Scheduled'),
                      //Tab(text: 'All Booking'),
                      //Tab(text: 'Dashboard'),
                    ],
                  ),
                ),

                Spacer(),
                Text(
                  DateFormat('MMM d, yyyy EEEE').format(DateTime.now()),
                  style: GoogleFonts.inter(
                    color: Colors.black,
                    fontSize: 23,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 10),
                CircleAvatar(
                  radius: 25,
                  backgroundImage: AssetImage("assets/images/pic/Avatar.png"),
                ),
                SizedBox(width: 10),
                Text(
                  '${staffName}',
                  style: GoogleFonts.inter(
                    color: Colors.black,
                    fontSize: 23,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(width: 10),
            Expanded(
              child: TabBarView(
                controller: defaultController.dashboardTabController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  CourtViewScreen(),
                  ActiveTabScreen(),
                  UpcomingTabScreen(),
                  PendingPayment(),
                  //ScheduledTabScreen(),
                  //AllBookingTabScreen(),
                  //DashboardTabViewScreen()
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
