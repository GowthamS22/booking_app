import 'package:booking_app/app/getx_binding.dart';
import 'package:booking_app/config/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../config/palette.dart';
import '../../controllers/setting_controller.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {

  final _formKey = GlobalKey<FormState>();

  TextEditingController printerIpController = TextEditingController();
  TextEditingController printerPortController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: SettingController(),
      builder: (controller) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              buildBody(controller),
              buildStreamPrinterIP(controller),
            ],
          ),
        );
      },
    );
  }

  buildStreamPrinterIP(SettingController settingController) {
    return
      Obx(() {
        return ListView.separated(
            shrinkWrap: true,
            separatorBuilder: (context, index) => SizedBox(height: 10,),
            itemCount: settingController.printerList.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text('Printer IP : ${settingController.printerList[index]
                    .printerIP}',
                  style: TextStyle(fontSize: 18 * ffem,
                      fontWeight: FontWeight.bold,
                      color: Palette.primaryColor),),
                trailing: Text(
                  'Printer Port : ${settingController.printerList[index]
                      .printerPort}',
                  style: TextStyle(fontSize: 18 * ffem,
                      fontWeight: FontWeight.bold,
                      color: Palette.primaryColor),),
              );
            }
        );
      });
  }

  buildBody(SettingController controller) {
    return ListView(
      shrinkWrap: true,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: TextStyle(fontSize: 18 * ffem,
                fontWeight: FontWeight.bold,
                color: Palette.primaryColor),),
            Divider(height: 40, color: Palette.darkGrey),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Printer Settings', style: TextStyle(
                      fontSize: 16 * ffem,
                      fontWeight: FontWeight.bold,
                      color: Palette.primaryColor),),
                  SizedBox(height: 20,),
                  Row(
                    children: [
                      Row(
                        children: [
                          Text('Printer IP', style: TextStyle(
                              fontSize: 15 * ffem),),
                          SizedBox(width: 10,),
                          Container(
                            width: MediaQuery
                                .of(context)
                                .size
                                .width / 6.5,
                            child: TextFormField(
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '';
                                }
                                return null;
                              },
                              controller: printerIpController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Palette.lightGrey, width: 2),
                                    borderRadius: BorderRadius.circular(
                                        5 * ffem)),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 10 * ffem, horizontal: 15),
                              ),
                              style: TextStyle(fontSize: 15 * ffem),
                            ),
                          )
                        ],
                      ),
                      SizedBox(width: 30,),
                      Row(
                        children: [
                          Text('Printer Port', style: TextStyle(
                              fontSize: 15 * ffem),),
                          SizedBox(width: 10,),
                          Container(
                            width: MediaQuery
                                .of(context)
                                .size
                                .width / 6.5,
                            child: TextFormField(
                              controller: printerPortController,
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[
                                // for below version 2 use this
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9]')),
// for version 2 and greater youcan also use this
                                FilteringTextInputFormatter.digitsOnly

                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Palette.lightGrey, width: 2),
                                    borderRadius: BorderRadius.circular(
                                        5 * ffem)),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 10 * ffem, horizontal: 15),
                              ),
                              style: TextStyle(fontSize: 15 * ffem),
                            ),
                          )
                        ],
                      ),
                      SizedBox(width: 30,),
                      ElevatedButton(
                        child: Text('Save', style: TextStyle(fontSize: 15 *
                            ffem, color: Palette.white),),
                        onPressed: () {
                          settingController.savingSettingsPrinter(
                              printerIpController.text,
                              int.parse(printerPortController.text));
                        },
                        style: ButtonStyle(
                            backgroundColor: MaterialStatePropertyAll(Palette
                                .primaryColor),
                            padding: MaterialStatePropertyAll(EdgeInsets
                                .symmetric(
                                vertical: 10 * ffem, horizontal: 15 * ffem)),
                            shape: MaterialStatePropertyAll(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      5 * ffem),
                                ))
                        ),
                      )
                    ],
                  ),


                ],
              ),
            ),
          ],
        )
      ],
    );
  }
}
