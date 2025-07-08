import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sidebarx/sidebarx.dart';
import '../controllers/auth_controller.dart';
import '../controllers/default_controller.dart';

class SidebarMenu extends StatefulWidget {
  const SidebarMenu({Key? key, required this.authController}) : super(key: key);

  final AuthController authController;

  @override
  State<SidebarMenu> createState() => _SidebarMenuState();
}

class _SidebarMenuState extends State<SidebarMenu> {
  final defaultController = Get.find<DefaultController>();
  final authController = Get.find<AuthController>();
  final SidebarXController controller = SidebarXController(
    selectedIndex: 0,
    //extended: false,
  );

  @override
  Widget build(BuildContext context) {
    // Sidebar on the left

    return Center(
      child: SidebarX(
        controller: controller,
        theme: SidebarXTheme(
          width: 110,
          decoration: const BoxDecoration(color: Colors.white),
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemTextPadding: EdgeInsets.zero,
          // itemMargin: const EdgeInsets.symmetric(vertical: 5),
          selectedItemTextPadding: EdgeInsets.zero,
          textStyle: const TextStyle(color: Colors.transparent),
          selectedTextStyle: const TextStyle(color: Colors.transparent),
          iconTheme: const IconThemeData(color: Colors.grey, size: 33),
          itemDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10), // square
          ),
          hoverColor: Colors.transparent,
        ),
        extendedTheme: const SidebarXTheme(width: 120),
        toggleButtonBuilder: (context, extended) {
          return const SizedBox.shrink();
        },
        headerBuilder:
            (context, extended) => Column(
              children: [
                StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (context, snapshot) {
                    return Text(
                      TimeOfDay.now().format(context),
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
                SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Image.asset(
                    'assets/images/splash_logo.png', // Replace with your actual image path
                    width: 45,
                    height: 45,
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
        items: [
          SidebarXItem(
            onTap: () {
              defaultController.changeTabIndex(0);
            },
            iconWidget: Center(
              child: Container(
                width: 80,
                height: 70,
                decoration: BoxDecoration(
                  color:
                      controller.selectedIndex == 0
                          ? Color(0xFFEAEFFF)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.calendarPlus,
                  color:
                      controller.selectedIndex == 0
                          ? Colors.indigo
                          : Colors.grey,
                  size: 40,
                ),
              ),
            ),
          ),
          SidebarXItem(
            onTap: () {
              defaultController.changeTabIndex(1);
            },
            iconWidget: Center(
              child: Container(
                width: 80,
                height: 70,
                decoration: BoxDecoration(
                  color:
                      controller.selectedIndex == 1
                          ? Colors.indigo.shade50
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.shoppingCart,
                  color:
                      controller.selectedIndex == 1
                          ? Colors.indigo.shade900
                          : Colors.grey,
                  size: 40,
                ),
              ),
            ),
          ),
          // SidebarXItem(
          //   onTap: () {
          //     defaultController.changeTabIndex(2);
          //   },
          //   iconWidget: Center(
          //     child: Container(
          //       width: 80,
          //       height: 70,
          //       decoration: BoxDecoration(
          //         color: controller.selectedIndex == 2 ? Colors.indigo.shade50 : Colors.transparent,
          //         borderRadius: BorderRadius.circular(8),
          //       ),
          //       child: Icon(
          //         LucideIcons.crown,
          //         color: controller.selectedIndex == 2 ? Colors.indigo.shade900 : Colors.grey,
          //         size: 40,
          //       ),
          //     ),
          //   ),
          // ),
          SidebarXItem(
            onTap: () {
              defaultController.changeTabIndex(2);
            },
            iconWidget: Center(
              child: Container(
                width: 80,
                height: 70,
                decoration: BoxDecoration(
                  color: controller.selectedIndex == 2 ? Colors.indigo.shade50 : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.settings,
                  color: controller.selectedIndex == 2 ? Colors.indigo.shade900 : Colors.grey,
                  size: 40,
                ),
              ),
            ),
          ),
          SidebarXItem(
            onTap: () {
              defaultController.changeTabIndex(3);
            },
            iconWidget: Center(
              child: Container(
                width: 80,
                height: 70,
                decoration: BoxDecoration(
                  color: controller.selectedIndex == 3 ? Colors.indigo.shade50 : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.coins,
                  color: controller.selectedIndex == 3 ? Colors.indigo.shade900 : Colors.grey,
                  size: 40,
                ),
              ),
            ),
          ),
        ],
        footerBuilder:
            (context, extended) => Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: IconButton(
                onPressed: () {
                  authController.logOut();
                },
                icon: const Icon(LucideIcons.logOut, size: 40),
              ),
            ),
      ),
    );
  }
}
