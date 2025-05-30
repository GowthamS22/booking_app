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
          decoration: const BoxDecoration(color: Colors.white),
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemTextPadding: EdgeInsets.zero,
          itemMargin: const EdgeInsets.symmetric(vertical: 10),
          selectedItemTextPadding: EdgeInsets.zero,
          textStyle: const TextStyle(color: Colors.transparent),
          selectedTextStyle: const TextStyle(color: Colors.transparent),
          iconTheme: const IconThemeData(color: Colors.grey, size: 33),
          selectedIconTheme: const IconThemeData(
            color: Colors.indigoAccent,
            size: 28,
          ),
          selectedItemDecoration: BoxDecoration(
            color: Color(0xFFEAEFFF),
            borderRadius: BorderRadius.zero, // square shape
          ),
          itemDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(0), // square
          ),
          hoverColor: Colors.transparent,
        ),
        extendedTheme: const SidebarXTheme(width: 90),
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
                        fontSize: 14,
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
                    'assets/images/logo/fb.png', // Replace with your actual image path
                    width: 32,
                    height: 32,
                  ),
                ),
                SizedBox(height: 50),
              ],
            ),
        items: [
          SidebarXItem(
            onTap: () {
              defaultController.changeTabIndex(0);
            },

            iconWidget: Center(
              child: Icon(
                LucideIcons.layoutDashboard,
                color:
                    controller.selectedIndex == 0 ? Colors.indigo : Colors.grey,
              ),
            ),
          ),

          SidebarXItem(
            onTap: () {
              defaultController.changeTabIndex(1);
            },
            iconWidget: Icon(
              LucideIcons.calendar,
              color:
                  controller.selectedIndex == 1 ? Colors.indigo : Colors.grey,
            ),
          ),
          SidebarXItem(
            onTap: () {
              defaultController.changeTabIndex(2);
            },
            iconWidget: Icon(
              LucideIcons.shoppingCart,
              color:
                  controller.selectedIndex == 2 ? Colors.indigo : Colors.grey,
            ),
          ),
          SidebarXItem(
            onTap: () {
              defaultController.changeTabIndex(3);
            },
            iconWidget: Icon(
              LucideIcons.users,
              color:
                  controller.selectedIndex == 3 ? Colors.indigo : Colors.grey,
            ),
          ),
          SidebarXItem(
            onTap: () {
              defaultController.changeTabIndex(4);
            },
            iconWidget: Icon(
              LucideIcons.pieChart,
              color:
                  controller.selectedIndex == 4 ? Colors.indigo : Colors.grey,
            ),
          ),
          SidebarXItem(
            onTap: () {
              defaultController.changeTabIndex(5);
            },
            iconWidget: Icon(
              LucideIcons.settings,
              color:
                  controller.selectedIndex == 5 ? Colors.indigo : Colors.grey,
            ),
          ),
        ],
        footerBuilder:
            (context, extended) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: IconButton(
                onPressed: () {
                  authController.logOut();
                },
                icon: const Icon(LucideIcons.logOut),
              ),
            ),
      ),
    );

    // Expanded(
    //   flex: 1,
    //   child: Container(
    //     decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
    //     margin: EdgeInsets.all(15),
    //     child: Drawer(
    //       shape: RoundedRectangleBorder(
    //         borderRadius: BorderRadius.circular(15),
    //       ),
    //       child: ListView(
    //         children: [
    //           Container(
    //             height: 100,
    //             child: DrawerHeader(
    //               padding: EdgeInsets.all(10),
    //               margin: EdgeInsets.all(0),
    //               child: Column(
    //                 mainAxisAlignment: MainAxisAlignment.center,
    //                 children: [
    //                   Expanded(
    //                     child: ClipRRect(
    //                       //borderRadius: BorderRadius.circular(50.0),
    //                       child: CachedNetworkImage(
    //                         width: 150,
    //                         height: 100,
    //                         imageUrl: widget.authController.logoURL.toString(),
    //                         placeholder:
    //                             (context, url) => CircularProgressIndicator(),
    //                         errorWidget:
    //                             (context, url, error) => CircleAvatar(
    //                               radius: 50,
    //                               child: Icon(
    //                                 Icons.person_pin,
    //                                 size: 80,
    //                                 color: Colors.white,
    //                               ),
    //                             ),
    //                       ),
    //                     ),
    //                   ),
    //                 ],
    //               ),
    //             ),
    //           ),
    //           DrawerListTile(
    //             icon: Icons.dashboard,
    //             press: () {
    //               defaultController.changeTabIndex(0);
    //             },
    //             defaultController: defaultController,
    //             index: 0,
    //           ),
    //           /*(defaultController.serviceList.length > 0) ?
    //           ListView.builder(
    //             physics: NeverScrollableScrollPhysics(),
    //             scrollDirection: Axis.vertical,
    //             shrinkWrap: true,
    //             itemCount: defaultController.serviceList.length,
    //             itemBuilder: (context, index) {
    //               final service = defaultController.serviceList[index];
    //               return CustomDrawerListTile(
    //                 image: service['icon'],
    //                 press: () {
    //                   defaultController.changeTabIndex(index+1);
    //                 },
    //                 defaultController: defaultController,
    //                 index: index+1,
    //               );
    //             },
    //           )
    //           :
    //           Container(),*/
    //           (defaultController.serviceList.length > 0)
    //               ? DrawerListTile(
    //                 icon: Icons.shopping_bag,
    //                 press: () {
    //                   defaultController.changeTabIndex(
    //                     defaultController.serviceList.length + 1,
    //                   );
    //                 },
    //                 defaultController: defaultController,
    //                 index: defaultController.serviceList.length + 1,
    //               )
    //               : SizedBox.shrink(),
    //           DrawerListTile(
    //             icon: Icons.group,
    //             press: () {
    //               defaultController.changeTabIndex(
    //                 defaultController.serviceList.length + 2,
    //               );
    //             },
    //             defaultController: defaultController,
    //             index: defaultController.serviceList.length + 2,
    //           ),
    //           DrawerListTile(
    //             icon: Icons.list_alt,
    //             press: () {
    //               defaultController.changeTabIndex(
    //                 defaultController.serviceList.length + 3,
    //               );
    //             },
    //             defaultController: defaultController,
    //             index: defaultController.serviceList.length + 3,
    //           ),
    //           DrawerListTile(
    //             icon: Icons.settings,
    //             press: () {
    //               defaultController.changeTabIndex(
    //                 defaultController.serviceList.length + 4,
    //               );
    //             },
    //             defaultController: defaultController,
    //             index: defaultController.serviceList.length + 4,
    //           ),
    //         ],
    //       ),
    //     ),
    //   ),
    // );
  }
}

// class DrawerListTile extends StatelessWidget {
//   final IconData? icon;
//   final VoidCallback? press;
//   final defaultController;
//   final index;

//   const DrawerListTile({
//     Key? key,
//     this.icon,
//     this.press,
//     this.defaultController,
//     this.index,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // print('ffem $ffem check the ffem');
//     return Container(
//       margin: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
//       padding: EdgeInsets.symmetric(vertical: 15),
//       decoration: BoxDecoration(
//         // color:  Palette.primaryColor,
//         color:
//             index == defaultController.tabIndex.value
//                 ? Palette.primaryColor
//                 : Colors.white,
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: InkWell(
//         onTap: press,
//         child: Icon(
//           icon,
//           size: 30 * ffem,
//           color:
//               index == defaultController.tabIndex.value
//                   ? Palette.white
//                   : Color.fromARGB(255, 57, 99, 236),
//         ),
//       ),
//     );
//   }
// }

// class CustomDrawerListTile extends StatelessWidget {
//   final String? image;
//   final VoidCallback? press;
//   final defaultController;
//   final index;

//   const CustomDrawerListTile({
//     Key? key,
//     this.image,
//     this.press,
//     this.defaultController,
//     this.index,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
//       padding: EdgeInsets.symmetric(vertical: 5),
//       decoration: BoxDecoration(
//         color:
//             index == defaultController.tabIndex.value
//                 ? Palette.primaryColor
//                 : Palette.white,
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: ListTile(
//         onTap: press,
//         title: Image(
//           image: AssetImage(image.toString()),
//           // height: 20,
//           // width: 20,
//           color:
//               index == defaultController.tabIndex.value
//                   ? Palette.white
//                   : Palette.darkGrey,
//         ),
//       ),
//     );
//   }
// }
