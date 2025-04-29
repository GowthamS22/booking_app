import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/constants.dart';
import '../config/google-fonts.dart';
import '../config/palette.dart';
import '../screens/booking/new_booking_screen.dart';

class AppScaffold extends StatelessWidget {

  const AppScaffold({required this.sidebar, required this.body});
  final Widget sidebar;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        sidebar,
        Expanded(
          flex: 10,
          child: Container(
            margin: EdgeInsets.only(left: 5,right: 15,top: 15,bottom: 15),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20)
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Scaffold(
                appBar: AppBar(
                  elevation: 0,
                  toolbarHeight: 80,
                  backgroundColor: Colors.white,
                  leadingWidth: MediaQuery.of(context).size.width / 4,
                  leading: Row(
                    children: [
                      SizedBox(width: 20,),
                      Row(
                        children: [
                          Image(
                            image: AssetImage('assets/images/icons/user-icon.png'),
                            width: 40*ffem,
                          ),
                          SizedBox(width: 20,),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${authController.userName}',style: TextStyle(fontSize: 15*ffem,color: Palette.darkGrey),),
                              SizedBox(height: 10,),
                              Text('Staff #${authController.staffID}',style: TextStyle(fontSize: 15*ffem,color: Palette.mediumGrey),)
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                  actions: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 5,vertical: 15),
                      child: ElevatedButton(
                        onPressed: () {
                          Get.to(NewBookingScreen(type: 'New',selectedBSlots: [],));
                        },
                        child: Row(
                          children: [
                            SizedBox(width: 10,),
                            Icon(Icons.add_circle_outline,size:20*ffem, color: Colors.white),
                            SizedBox(width: 5,),
                            Text('${'Add Booking'}',style: TextStyle(fontSize:15*ffem, color: Palette.white),),
                            SizedBox(width: 10,),
                          ],
                        ),
                        style: ButtonStyle(
                            backgroundColor: MaterialStatePropertyAll(Palette.primaryColor),
                            padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical:15, horizontal: 15)),
                            shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50)
                            ))
                        ),
                      ),
                    ),
                    SizedBox(width: 30,),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 5,vertical: 15),
                      child: TextButton(
                        onPressed: () {
                          authController.logOut();
                        },
                        child: Row(
                          children: [
                            Icon(Icons.logout,size:20*ffem, color: Colors.grey),
                            SizedBox(width: 5,),
                            Text('${'Logout'}',style: TextStyle(fontSize:15*ffem, color: Palette.darkGrey),)
                          ],
                        ),
                        style: ButtonStyle(
                            backgroundColor: MaterialStatePropertyAll(Colors.white),
                            padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical:15, horizontal: 15)),
                            shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50)
                            ))
                        ),
                      ),
                    ),
                    SizedBox(width: 20,),
                  ],
                ),
                body: body,
              ),
            ),
          ),
        )
      ],
    );
  }
}