import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/constants.dart';
import '../../config/palette.dart';
import '../../controllers/report_controller.dart';
import '../auth/close_cash_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: ReportController(),
      builder: (controller) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(children: [buildBody(controller)]),
        );
      },
    );
  }

  buildBody(ReportController controller) {
    return ListView(
      shrinkWrap: true,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reports',
              style: TextStyle(
                fontSize: 18 * ffem,
                fontWeight: FontWeight.bold,
                color: Palette.primaryColor,
              ),
            ),
            Divider(height: 40, color: Palette.darkGrey),
            Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    buildCloseCashDialog(controller);
                  },
                  child: Text(
                    'Close Cash',
                    style: TextStyle(fontSize: 15 * ffem),
                  ),
                  style: ButtonStyle(
                    backgroundColor: MaterialStatePropertyAll(
                      Palette.primaryColor,
                    ),
                    padding: MaterialStatePropertyAll(
                      EdgeInsets.symmetric(
                        vertical: 10 * ffem,
                        horizontal: 20 * ffem,
                      ),
                    ),
                    shape: MaterialStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10 * ffem),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Future buildCloseCashDialog(ReportController controller) {
    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10 * ffem),
              ),
              content: Container(
                padding: EdgeInsets.all(20),
                width: MediaQuery.of(context).size.width / 2.5,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(
                        'Are you sure you want to close cash?',
                        style: TextStyle(
                          fontSize: 20 * ffem,
                          color: Palette.primaryColor,
                        ),
                      ),
                      SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Get.back();
                            },
                            child: Text(
                              'No',
                              style: TextStyle(fontSize: 20 * ffem),
                            ),
                            style: ButtonStyle(
                              backgroundColor: MaterialStatePropertyAll(
                                Palette.mediumGrey,
                              ),
                              padding: MaterialStatePropertyAll(
                                EdgeInsets.symmetric(
                                  vertical: 10 * ffem,
                                  horizontal: 30 * ffem,
                                ),
                              ),
                              shape: MaterialStatePropertyAll(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    10 * ffem,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Get.to(CloseCashScreen());
                            },
                            child: Text(
                              'Yes',
                              style: TextStyle(fontSize: 20 * ffem),
                            ),
                            style: ButtonStyle(
                              backgroundColor: MaterialStatePropertyAll(
                                Palette.dangerTxt,
                              ),
                              padding: MaterialStatePropertyAll(
                                EdgeInsets.symmetric(
                                  vertical: 10 * ffem,
                                  horizontal: 30 * ffem,
                                ),
                              ),
                              shape: MaterialStatePropertyAll(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    10 * ffem,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
