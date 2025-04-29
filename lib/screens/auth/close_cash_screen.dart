import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../components/reason_for_difference.dart';
import '../../components/types.dart';
import '../../config/constants.dart';
import '../../config/palette.dart';
import '../../controllers/report_controller.dart';
import '../../widgets/checkout_number_pad.dart';
import '../../widgets/shimmer/shimmer_table_loading.dart';

class CloseCashScreen extends StatefulWidget {
  const CloseCashScreen({Key? key}) : super(key: key);

  @override
  State<CloseCashScreen> createState() => _CloseCashScreenState();
}

class _CloseCashScreenState extends State<CloseCashScreen> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: ReportController(),
      builder: (controller) {
        return Container(
          decoration: BoxDecoration(
            color: Palette.lightGrey,
          ),
          padding: EdgeInsets.all(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Scaffold(
              appBar: AppBar(
                elevation: 0,
                toolbarHeight: 80,
                backgroundColor: Colors.white,
                leadingWidth: MediaQuery.of(context).size.width / 4,
                leading: Row(
                  children: [
                    SizedBox(width: 30,),
                    InkWell(
                      onTap: () {
                        setState(() {
                          Get.back();
                        });
                      },
                      child: Icon(Icons.arrow_back,size: 30*ffem,color: Palette.black,),
                    ),
                    SizedBox(width: 30,),
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
              ),
              backgroundColor: Palette.white,
              body: Container(
                padding: EdgeInsets.symmetric(vertical: 20,horizontal: 30),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Closing Cash', style: TextStyle(fontSize: 18 * ffem,fontWeight: FontWeight.bold,color: Palette.primaryColor),),
                      Divider(height: 40, color: Palette.darkGrey),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          buildNumberPad(controller),
                          SizedBox(width: 20,),
                          buildCloseList(controller),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  buildNumberPad(ReportController controller) {
    return Expanded(
      flex: 2,
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CheckoutNumberPad(
              submitForm: () {

              },
              onBackspaceTap: () {
                setState(() {
                  if (controller.quantityController.text.isNotEmpty) {
                    if(controller.quantityController.text.length==0) {
                      controller.quantityController.text = 0 as String;
                    } else {
                      controller.quantityController.text = controller.quantityController.text.substring(0, controller.quantityController.text.length - 1);
                    }
                  }
                });
                controller.editQuantity(controller.types, controller.typeIndex.value, controller.quantityController.text.trim()=='' ? '0' : controller.quantityController.text.trim());
              },
              onNumberTap: (number) {
                if(number.length !=0) {

                  setState(() {
                    if(number=='.') {
                      if(controller.quantityController.text.length > 0) {
                        controller.quantityController.text += number;
                      }
                    } else {
                      controller.quantityController.text += number;
                    }
                  });
                  controller.editQuantity(controller.types, controller.typeIndex.value, controller.quantityController.text.trim());
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  buildCloseList(ReportController controller) {
    return Expanded(
      flex: 2,
      child: Container(
        height: MediaQuery.of(context).size.height / 1.5,
        margin: const EdgeInsets.all(15.0),
        padding: const EdgeInsets.all(3.0),
        decoration: BoxDecoration(border: Border.all(color: Palette.primaryColor)),
        child: SingleChildScrollView(
          child: Column(
            children: [
              (controller.openCloseCash.length > 0) ?
              SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 10,),
                    Text(
                      'Collection Report',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14*ffem,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(15.0),
                      padding: const EdgeInsets.all(3.0),
                      decoration: BoxDecoration(
                          border:
                          Border.all(color: Palette.primaryColor)),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Text(
                              'FLOAT CASH',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14*ffem,
                              ),
                            ),
                            trailing: Text(
                              '${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(controller.openCloseCash[0]['openCloseAmount'])}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 14*ffem,
                              ),
                            ),
                          ),
                          ListTile(
                            leading: Text(
                              'CASH',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14*ffem,
                              ),
                            ),
                            trailing: Text(
                              '${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(controller.cashSales)}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 14*ffem,
                              ),
                            ),
                          ),
                          ListTile(
                            leading: Text(
                              'EFPOS',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14*ffem,
                              ),
                            ),
                            trailing: Text(
                              '${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(controller.cardSales)}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 14*ffem,
                              ),
                            ),
                          ),
                          ListTile(
                            leading: Text(
                              'ON ACCOUNT',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14*ffem,
                              ),
                            ),
                            trailing: Text(
                              '${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(controller.accountSales)}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 14*ffem,
                              ),
                            ),
                          ),
                          ListTile(
                            leading: Text(
                              'ONLINE BOOKING',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14*ffem,
                              ),
                            ),
                            trailing: Text(
                              '${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(controller.onlineSales)}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 14*ffem,
                              ),
                            ),
                          ),
                          ListTile(
                            leading: Text(
                              'MEMBERSHIP',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14*ffem,
                              ),
                            ),
                            trailing: Text(
                              '${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(controller.membershipSales)}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 14*ffem,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Obx(() {
                      if(double.parse(controller.cashSales.toString()) - double.parse(controller.calculatingCash().toString()) == 0.0) {
                        return SizedBox.shrink();
                      } else {
                        return ReasonForDifference(
                          textBorderColor: controller.textBorderColor.value,
                          //closing: controller,
                          //authController: authController,
                          salesHeading: 'CASH',
                          cashHeading: 'CASH COUNTER',
                          textEditingController: controller.reasonForCashController,
                          salesAmount: double.parse(controller.cardSales.toString()),
                          cashAmount: double.parse(controller.calculatingCash().toString()),
                        );
                      }
                    },),
                    SizedBox(
                      height: 20,
                    ),
                    Container(
                      margin: const EdgeInsets.all(15.0),
                      padding: const EdgeInsets.all(3.0),
                      decoration: BoxDecoration(
                          border:
                          Border.all(color: Palette.primaryColor)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Price',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14*ffem,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Type',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14*ffem,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 5,
                                  child: Text(
                                    'Quantity',
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14*ffem,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Total',
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14*ffem,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 30,
                            ),
                            Types(
                              closing: controller.notesType.value,
                              type: 'Notes',
                              dollarOrCoins: '\$',
                              quantity: controller.notesQuantity.value,
                              isNotes: true,
                              isCents: false,
                              isCoins: false,
                            ),
                            Divider(
                              thickness: 2,
                              color: Colors.black,
                            ),
                            Types(
                              closing: controller.coinsType.value,
                              type: 'Coins',
                              dollarOrCoins: '\$',
                              quantity: controller.coinsQuantity.value,
                              isNotes: false,
                              isCents: false,
                              isCoins: true,
                            ),
                            Divider(
                              thickness: 2,
                              color: Colors.black,
                            ),
                            Types(
                              closing: controller.centsType.value,
                              type: 'Cents',
                              dollarOrCoins: '',
                              quantity: controller.centsQuantity.value,
                              isNotes: false,
                              isCents: true,
                              isCoins: false,
                            ),

                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 10,),
                    Container(
                      margin: const EdgeInsets.all(15.0),
                      padding: const EdgeInsets.all(3.0),
                      decoration: BoxDecoration(border: Border.all(color: Palette.primaryColor)),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Text(
                              'CASH',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14*ffem,
                              ),
                            ),
                            trailing: Text(
                              '${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(controller.calculatingCash())}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 14*ffem,
                              ),
                            ),
                          ),
                          ListTile(
                            leading: Text(
                              'EFPOS',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14*ffem,
                              ),
                            ),
                            trailing: Text(
                              '${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(controller.cardSales)}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 14*ffem,
                              ),
                            ),
                          ),
                          ListTile(
                            leading: Text(
                              'MEMBERSHIP',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14*ffem,
                              ),
                            ),
                            trailing: Text(
                              '${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(controller.membershipSales)}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 14*ffem,
                              ),
                            ),
                          ),
                          ListTile(
                            leading: Text(
                              'SUB-TOTAL',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14*ffem,
                              ),
                            ),
                            trailing: Text(
                              '${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(controller.calculatingSubtotal())}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 14*ffem,
                              ),
                            ),
                          ),
                          ListTile(
                            leading: Text(
                              'FLOAT',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14*ffem,
                              ),
                            ),
                            trailing: Text(
                              '${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(controller.openCloseCash[0]['openCloseAmount'])}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 14*ffem,
                              ),
                            ),
                          ),
                          ListTile(
                            leading: Text(
                              'TOTAL',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14*ffem,
                              ),
                            ),
                            trailing: Text(
                              '${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(controller.calculatingTotal())}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 14*ffem,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(height: 10,),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 18),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                controller.printReceipt();
                              },
                              child: Text('Print Receipt',style: TextStyle(fontSize: 15*ffem),),
                              style: ButtonStyle(
                                  backgroundColor: MaterialStatePropertyAll(Palette.payColors),
                                  shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)
                                  )),
                                  padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 10*ffem,horizontal: 20*ffem))
                              ),
                            ),
                          ),
                          SizedBox(height: 30*ffem,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  Get.back();
                                  Get.back();
                                },
                                child: Text('Back',style: TextStyle(fontSize: 15*ffem),),
                                style: ButtonStyle(
                                    backgroundColor: MaterialStatePropertyAll(Palette.mediumGrey),
                                    shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)
                                    )),
                                    padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 10*ffem,horizontal: 85*ffem))
                                ),
                              ),
                              (controller.closeBtnLoading.value==false) ?
                              ElevatedButton(
                                onPressed: () {
                                  if(double.parse(controller.cashSales.toString()) - double.parse(controller.calculatingCash().toString()) != 0.0) {
                                    if(controller.reasonForCashController.text.isNotEmpty && controller.reasonForCashController.text.length > 5) {
                                      controller.closeCash(
                                        hundredNotes: controller.notesQuantity[0],
                                        fiftyNotes: controller.notesQuantity[1],
                                        twentyNotes: controller.notesQuantity[2],
                                        tenNotes: controller.notesQuantity[3],
                                        fiveNotes: controller.notesQuantity[4],
                                        twoCoins: controller.coinsQuantity[0],
                                        oneCoins: controller.coinsQuantity[1],
                                        fiftyCents: controller.centsQuantity[0],
                                        twentyCents: controller.centsQuantity[1],
                                        tenCents: controller.centsQuantity[2],
                                        fiveCents: controller.centsQuantity[3],
                                        total: controller.calculatingTotal(),
                                        isForceClosed: false,
                                      );
                                    } else {
                                      showCustomSnackbar('Warning', 'Please enter the reason for difference in amount', Colors.red);
                                    }
                                  } else {
                                    controller.closeCash(
                                      hundredNotes: controller.notesQuantity[0],
                                      fiftyNotes: controller.notesQuantity[1],
                                      twentyNotes: controller.notesQuantity[2],
                                      tenNotes: controller.notesQuantity[3],
                                      fiveNotes: controller.notesQuantity[4],
                                      twoCoins: controller.coinsQuantity[0],
                                      oneCoins: controller.coinsQuantity[1],
                                      fiftyCents: controller.centsQuantity[0],
                                      twentyCents: controller.centsQuantity[1],
                                      tenCents: controller.centsQuantity[2],
                                      fiveCents: controller.centsQuantity[3],
                                      total: controller.calculatingTotal(),
                                      isForceClosed: false,
                                    );
                                  }
                                },
                                child: Text('Close Cash',style: TextStyle(fontSize: 15*ffem),),
                                style: ButtonStyle(
                                    backgroundColor: MaterialStatePropertyAll(Palette.dangerTxt),
                                    shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)
                                    )),
                                    padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 10*ffem,horizontal: 60*ffem))
                                ),
                              )
                              :
                              Container(
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Palette.lightGrey,),
                                height: 47,
                                width: 250,
                                child: Center(
                                  child: SizedBox(
                                    height: 30,
                                    width: 30,
                                    child: CircularProgressIndicator(
                                      color: Palette.primaryColor,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                          SizedBox(height: 30*ffem,),
                        ],
                      ),
                    ),
                  ],
                ),
              )
                  :
              ShimmerTableLoading(rowCount: 5,columnCount: 1,)
            ],
          ),
        ),
      ),
    );
  }
}


class NoOfSales extends StatelessWidget {
  const NoOfSales({
    Key? key,
    required this.cardSales,
    required this.cashSales,
    required this.onlineSales,
    required this.cashSalesAmount,
    required this.cardSalesAmount,
    required this.onlineSalesAmount,
    required this.textBorderColor,
  }) : super(key: key);


  final String cashSales, cardSales,onlineSales;
  final int cashSalesAmount, cardSalesAmount , onlineSalesAmount;
  final Color textBorderColor;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(15.0),
      padding: const EdgeInsets.all(3.0),
      decoration:
      BoxDecoration(border: Border.all(color: Palette.primaryColor)),
      child: Column(
        children: [
          ListTile(
            leading: Text(
              cashSales,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            trailing: Text(
              '${cashSalesAmount.toString()}',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Palette.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          ListTile(
            leading: Text(
              cardSales,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            trailing: Text(
              '${cardSalesAmount.toString()}',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:Palette.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          ListTile(
            leading: Text(
              onlineSales,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            trailing: Text(
              '${onlineSalesAmount.toString()}',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:Palette.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
