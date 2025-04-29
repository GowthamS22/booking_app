import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import '../config/constants.dart';
import '../config/palette.dart';
import '../controllers/auth_controller.dart';
import '../controllers/default_controller.dart';

class SidebarMenu extends StatefulWidget {

  const SidebarMenu({
    Key? key,
    required this.authController,
  }) : super(key: key);

  final AuthController authController;

  @override
  State<SidebarMenu> createState() => _SidebarMenuState();
}

class _SidebarMenuState extends State<SidebarMenu> {

  final defaultController = Get.find<DefaultController>();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15)
        ),
        margin: EdgeInsets.all(15),
        child: Drawer(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)
          ),
          child: ListView(
            children: [
              Container(
                height: 100,
                child: DrawerHeader(
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.all(0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          //borderRadius: BorderRadius.circular(50.0),
                          child: CachedNetworkImage(
                            width: 150,
                            height: 100,
                            imageUrl: widget.authController.logoURL.toString(),
                            placeholder: (context, url) => CircularProgressIndicator(),
                            errorWidget: (context, url, error) =>
                                CircleAvatar(
                                  radius: 50,
                                  child: Icon(Icons.person_pin, size: 80, color: Colors.white),
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DrawerListTile(
                icon: Icons.dashboard,
                press: () {
                  defaultController.changeTabIndex(0);
                },
                defaultController: defaultController,
                index: 0,
              ),
              /*(defaultController.serviceList.length > 0) ?
              ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                itemCount: defaultController.serviceList.length,
                itemBuilder: (context, index) {
                  final service = defaultController.serviceList[index];
                  return CustomDrawerListTile(
                    image: service['icon'],
                    press: () {
                      defaultController.changeTabIndex(index+1);
                    },
                    defaultController: defaultController,
                    index: index+1,
                  );
                },
              )
              :
              Container(),*/
              (defaultController.serviceList.length > 0) ?
              DrawerListTile(
                icon: Icons.shopping_bag,
                press: () {
                  defaultController.changeTabIndex(defaultController.serviceList.length + 1);
                },
                defaultController: defaultController,
                index: defaultController.serviceList.length + 1,
              ) :
              SizedBox.shrink(),
              DrawerListTile(
                icon: Icons.group,
                press: () {
                  defaultController.changeTabIndex(defaultController.serviceList.length + 2);
                },
                defaultController: defaultController,
                index: defaultController.serviceList.length + 2,
              ),
              DrawerListTile(
                icon: Icons.list_alt,
                press: () {
                  defaultController.changeTabIndex(defaultController.serviceList.length + 3);
                },
                defaultController: defaultController,
                index: defaultController.serviceList.length + 3,
              ),
              DrawerListTile(
                icon: Icons.settings,
                press: () {
                  defaultController.changeTabIndex(defaultController.serviceList.length + 4);
                },
                defaultController: defaultController,
                index: defaultController.serviceList.length + 4,
              ),

            ],
          ),
        ),
      ),
    );
  }
}

class DrawerListTile extends StatelessWidget {
  final IconData? icon;
  final VoidCallback? press;
  final defaultController;
  final index;

  const DrawerListTile({
    Key? key,
    this.icon,
    this.press,
    this.defaultController,
    this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // print('ffem $ffem check the ffem');
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10,horizontal: 8),
      padding: EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
          // color:  Palette.primaryColor,
        color: index == defaultController.tabIndex.value ? Palette.primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(10)
      ),
      child: InkWell(
        onTap: press,
        child: Icon(icon, size: 30*ffem, color: index == defaultController.tabIndex.value
            ? Palette.white : Palette.darkGrey,),
      ),
    );
  }
}

class CustomDrawerListTile extends StatelessWidget {
  final String? image;
  final VoidCallback? press;
  final defaultController;
  final index;

  const CustomDrawerListTile({
    Key? key,
    this.image,
    this.press,
    this.defaultController,
    this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10,horizontal: 8),
      padding: EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
          color: index == defaultController.tabIndex.value ? Palette.primaryColor : Palette.white,
          borderRadius: BorderRadius.circular(10)
      ),
      child: ListTile(
        onTap: press,
        title: Image(
          image: AssetImage(image.toString()),
          // height: 20,
          // width: 20,
          color: index == defaultController.tabIndex.value ? Palette.white : Palette.darkGrey,
        ),
      ),
    );
  }
}