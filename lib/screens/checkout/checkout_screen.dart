import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../app/getx_binding.dart';
import '../../config/constants.dart';
import '../../config/google-fonts.dart';
import '../../config/palette.dart';
import '../../controllers/checkout_controller.dart';
import '../../controllers/customer_controller.dart';
import '../../controllers/new_booking_controller.dart';
import '../../controllers/default_controller.dart';
import '../../models/booking_model.dart';
import '../../widgets/checkout_number_pad.dart';

class CheckoutScreen extends StatefulWidget {
  final type;
  const CheckoutScreen({this.type, Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {

  final NewBookingController newBookingController = Get.put(NewBookingController());//Get.find();
  final DefaultController defaultController       = Get.put(DefaultController());
  final CustomerController customerController     = Get.put(CustomerController());

  TextEditingController notesController         = TextEditingController();
  TextEditingController promoCodeController     = TextEditingController();

  TextEditingController paidAmountController    = TextEditingController();
  TextEditingController balanceAmountController = TextEditingController();

  String? _selectedPaymentType = 'Credit Card'; // Make it nullable

  bool _customerCopy = false;
  bool _noReceipt    = false;

  @override
  Widget build(BuildContext context) {

    return GetBuilder(
      init: CheckoutController(),
      builder: (controller) {

        if(widget.type=='New') {

          defaultController.selectedBooking.clear();
          defaultController.actionBookingSlots.clear();
          customerController.selectedPlan.clear();

        } else if(widget.type=='ExistingBooking') {

          customerController.selectedPlan.clear();

        } else if(widget.type=='Membership') {

          defaultController.selectedBooking.clear();
          defaultController.actionBookingSlots.clear();

        }  else if(widget.type=='Product') {

          customerController.selectedPlan.clear();

        }

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
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildCartItems(newBookingController,controller),
                          SizedBox(width: 20,),
                          buildCheckout(newBookingController,controller),
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

  buildCartItems(NewBookingController controller,CheckoutController checkoutController) {

    //Load Existing booking payment items
    var bookingID      = (defaultController.selectedBooking.length > 0) ? defaultController.selectedBooking[0].id : '' ;
    print(defaultController.actionBookingSlots.length);
    if(defaultController.actionBookingSlots.length > 0) {
      controller.cartItems.clear();
      for(var item in defaultController.actionBookingSlots.where((slot) => slot.paymentStatus != "Paid").toList()) {
        controller.cartItems.add(BookingSlot(
            id: item.id,
            userId: item.userId,
            name: item.name,
            mobile: item.mobile,
            bookingId: item.bookingId,
            subBookingId: item.subBookingId,
            date: item.date,
            price: item.price,
            service: item.service,
            serviceId: item.serviceId,
            court: item.court,
            courtId: item.courtId,
            startTime: item.startTime,
            endTime: item.endTime,
            slotType: item.slotType,
            repeatDays: item.repeatDays,
            repeatEnd: item.repeatEnd,
            repeatId: item.repeatId,
            repeatGroupId: item.repeatGroupId,
            status: item.status,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
            createdBy: item.createdBy,
            updatedBy: item.updatedBy
        ));
      }
    }


    //Booking Cart Items Merge
    List<BookingSlot> cartItems = [];
    for(var item in controller.cartItems) {
      cartItems.add(BookingSlot(
          id: item.id,
          userId: item.userId,
          name: item.name,
          mobile: item.mobile,
          bookingId: item.bookingId,
          subBookingId: item.subBookingId,
          date: item.date,
          price: item.price,
          service: item.service,
          serviceId: item.serviceId,
          court: item.court,
          courtId: item.courtId,
          startTime: item.startTime,
          endTime: item.endTime,
          slotType: item.slotType,
          repeatDays: item.repeatDays,
          repeatEnd: item.repeatEnd,
          repeatId: item.repeatId,
          repeatGroupId: item.repeatGroupId,
          paymentStatus: item.paymentStatus,
          status: item.status,
          createdAt: item.createdAt,
          updatedAt: item.updatedAt,
          createdBy: item.createdBy,
          updatedBy: item.updatedBy
      ));
    }

    List<BookingSlot> mergedSlots = controller.mergeTimeSlots(cartItems);
    mergedSlots.removeWhere((bookingSlot) => (bookingSlot.slotType=='Repeat-Item'));
    print('checking the checkout -2 ');

    return Expanded(
      flex: 2,
      child: SingleChildScrollView(
        child: Column(
          children: [

            Container(
              padding: EdgeInsets.symmetric(vertical: 20,horizontal: 20),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20),topRight: Radius.circular(20)),
                  color: Palette.white,
                  border: Border.all(color: Palette.mediumGrey,width: 1)
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  (widget.type=='Membership') ?
                  Text('Membership : #${customerController.selectedPlan[0]['name']}',style: TextStyle(color: Palette.darkGrey,fontSize: 15*ffem,fontWeight: FontWeight.bold))
                  :
                  Text('Order No. #${bookingID}',style: TextStyle(color: Palette.darkGrey,fontSize: 15*ffem,fontWeight: FontWeight.bold)),
                  Text('${(controller.userData.value.firstName!=null) ? controller.userData.value.firstName : ''} ${(controller.userData.value.lastName!=null) ? controller.userData.value.lastName : ''}',style: TextStyle(color: Palette.darkGrey,fontSize: 15*ffem,fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height / 1.4,
              //padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Palette.mediumGrey,width: 1),
                //borderRadius: BorderRadius.circular(15)
              ),
              child: Stack(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 2,
                    child: ListView(
                      children: [
//                         ListView.builder(
//                           physics: NeverScrollableScrollPhysics(),
//                           scrollDirection: Axis.vertical,
//                           shrinkWrap: true,
//                           itemCount: mergedSlots.length,
//                           itemBuilder: (context, index) {

//                             BookingSlot cartItem = mergedSlots[index];

//                             String fmtdStartTime = cartItem.startTime != null ? DateFormat('hh:mm a').format(cartItem.startTime!) : '';
//                             String fmtdEndTime = cartItem.endTime != null ? DateFormat('hh:mm a').format(cartItem.endTime!) : '';

//                             var finalPrice = (cartItem.slotType=='Repeated') ? controller.calculateRepeatPrice(repeatGroupId: cartItem.repeatGroupId) : cartItem.price ;

//                             return Container(
//                               //margin: EdgeInsets.only(bottom: 20),
//                               padding: EdgeInsets.all(10),
//                               decoration: BoxDecoration(
//                                 //borderRadius: BorderRadius.circular(15),
//                                   color: Palette.white,
//                                   border: Border.all(color: Palette.lightGrey,width: 1)
//                               ),
//                               child: ListTile(
//                                 title: Row(
//                                   children: [
//                                     Text('${cartItem.court}  ',style: TextStyle(color: Palette.darkGrey,fontSize: 15*ffem,fontWeight: FontWeight.bold)),
//                                   ],
//                                 ),
//                                 subtitle: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     SizedBox(height: 5,),
//                                     Text('${DateFormat('dd-MM-yy EE').format(cartItem.date!)}',style: TextStyle(color: Palette.darkGrey,fontSize: 15*ffem),),
//                                     SizedBox(height: 5,),
//                                     Row(
//                                       children: [
//                                         Text('${fmtdStartTime} - ',style: TextStyle(color: Palette.darkGrey,fontSize:15*ffem,fontWeight: FontWeight.bold),),
//                                         Text('${fmtdEndTime}',style: TextStyle(color: Palette.darkGrey,fontSize:15*ffem,fontWeight: FontWeight.bold),),
//                                       ],
                  ListView.builder(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: mergedSlots.length,
                    itemBuilder: (context, index) {

                      BookingSlot cartItem = mergedSlots[index];

                      String fmtdStartTime = cartItem.startTime != null ? DateFormat('hh:mm a').format(cartItem.startTime!) : '';
                      String fmtdEndTime = cartItem.endTime != null ? DateFormat('hh:mm a').format(cartItem.endTime!) : '';

                      var finalPrice = (cartItem.slotType=='Repeated') ? controller.calculateRepeatPrice(repeatGroupId: cartItem.repeatGroupId) : cartItem.price ;

                      return Container(
                        //margin: EdgeInsets.only(bottom: 20),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          //borderRadius: BorderRadius.circular(15),
                            color: Palette.white,
                            border: Border.all(color: Palette.lightGrey,width: 1)
                        ),
                        child: ListTile(
                          title: Row(
                            children: [
                              Text('${cartItem.court}  ',style: TextStyle(color: Palette.darkGrey,fontSize: 15*ffem,fontWeight: FontWeight.bold)),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 5,),
                              Row(
                                children: [
                                  Text('${DateFormat('dd-MM-yy EE').format(cartItem.date!)}  ',style: TextStyle(color: Palette.darkGrey,fontSize: 15*ffem),),
                                  Text('${fmtdStartTime} - ',style: TextStyle(color: Palette.darkGrey,fontSize:15*ffem,fontWeight: FontWeight.bold),),
                                  Text('${fmtdEndTime}',style: TextStyle(color: Palette.darkGrey,fontSize:15*ffem,fontWeight: FontWeight.bold),),
                                ],
                              ),
                              /*Text('${DateFormat('dd-MM-yy EE').format(cartItem.date!)}',style: TextStyle(color: Palette.darkGrey,fontSize: 15*ffem),),
                              SizedBox(height: 5,),
                              Row(
                                children: [
                                  Text('${fmtdStartTime} - ',style: TextStyle(color: Palette.darkGrey,fontSize:15*ffem,fontWeight: FontWeight.bold),),
                                  Text('${fmtdEndTime}',style: TextStyle(color: Palette.darkGrey,fontSize:15*ffem,fontWeight: FontWeight.bold),),
                                ],
                              ),*/
                              (cartItem.slotType=='Repeated') ?
                              Column(
                                children: [
                                  SizedBox(height: 5,),
                                  TextButton(
                                    onPressed: null,
                                    child: Text('Repeat Till - ${DateFormat('dd-MM-yyy').format(cartItem.repeatEnd!)}',style: TextStyle(color: Palette.white,fontSize:12*ffem,),),
                                    style: ButtonStyle(
                                        backgroundColor: MaterialStatePropertyAll(Palette.primaryColor),
                                        padding: MaterialStatePropertyAll(EdgeInsets.symmetric(horizontal: 10*ffem,vertical: 10)),
                                        shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))
                                    ),),

                                  ],
                                ):
                              Container(),
                          ]
                              ),
                        trailing: Text(NumberFormat.currency(locale: 'en_US', symbol: '\$').format(finalPrice),style: TextStyle(color: Palette.primaryColor,fontSize: 20*ffem,fontWeight: FontWeight.bold)),
                      ));
                          },
                        ),
                        ListView.separated(
                            physics: NeverScrollableScrollPhysics(),
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                SizedBox(
                                  height: 5,
                                ),
                            shrinkWrap: true,
                            itemCount: shoppingController
                                .productsCartModal.length,
                            itemBuilder:
                                (BuildContext context, int index) {
                              return Container(
                                // ordercontanierL3s (318:7992)
                                padding: EdgeInsets.fromLTRB(
                                    10 * fem,
                                    0 * fem,
                                    9 * fem,
                                    10 * fem),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  // color: Colors.red,
                                  border: Border.all(
                                      color: Color(0xffc4cdd8)),
                                ),
                                child:
                                ListTile(
                                  title: Text(
                                    '${shoppingController.productsCartModal[index].name}',
                                    overflow: TextOverflow
                                        .ellipsis,
                                    style: SafeGoogleFont(
                                      'Roboto',
                                      fontSize: 14 * ffem,
                                      fontWeight:
                                      FontWeight.w500,
                                      height:
                                      1.7142857143 *
                                          ffem /
                                          fem,
                                      letterSpacing:
                                      0.3740000129 *
                                          fem,
                                      color: Color(
                                          0xff000000),
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${shoppingController.productsCartModal[index].count} X ${shoppingController.productsCartModal[index].salePrice}',
                                    overflow: TextOverflow
                                        .ellipsis,
                                    style: SafeGoogleFont(
                                      'Roboto',
                                      fontSize: 14 * ffem,
                                      fontWeight:
                                      FontWeight.w500,
                                      height:
                                      1.7142857143 *
                                          ffem /
                                          fem,
                                      letterSpacing:
                                      0.3740000129 *
                                          fem,
                                      color: Color(
                                          0xff000000),
                                    ),
                                  ),
                                  trailing: Text(NumberFormat.currency(locale: 'en_US', symbol: '\$').format(shoppingController.productsCartModal[index].salePrice! * shoppingController.productsCartModal[index].count!.value),style: TextStyle(color: Palette.primaryColor,fontSize: 20*ffem,fontWeight: FontWeight.bold)),
                                ),
                              );
                            }),
                      ],
                    ),
                  ),
                  (widget.type=='Membership') ? Container(
                    //margin: EdgeInsets.only(bottom: 20),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      //borderRadius: BorderRadius.circular(15),
                        color: Palette.white,
                        border: Border.all(color: Palette.lightGrey,width: 1)
                    ),
                    child: ListTile(
                      title: Row(
                        children: [
                          Text('${customerController.selectedPlan[0]['name']}  ',style: TextStyle(color: Palette.darkGrey,fontSize: 15*ffem,fontWeight: FontWeight.bold)),
                        ],
                      ),
                      trailing: Text(NumberFormat.currency(locale: 'en_US', symbol: '\$').format(customerController.selectedPlan[0]['price']),style: TextStyle(color: Palette.primaryColor,fontSize: 20*ffem,fontWeight: FontWeight.bold)),
                    ),
                  ) : Container(),

                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                          color: Palette.white,
                          border: Border(top: BorderSide(color: Palette.lightGrey,width: 2))
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  Text('Subtotal', style: TextStyle(color: Palette.darkGrey, fontSize: 15*ffem, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 20,),
                                  Text('Discount', style: TextStyle(color: Palette.darkGrey, fontSize: 15*ffem, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 20,),
                                  Text('GST', style: TextStyle(color: Palette.darkGrey, fontSize: 15*ffem, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 20,),
                                  Text('Total', style: TextStyle(color: Palette.primaryColor, fontSize: 20*ffem, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(NumberFormat.currency(locale: 'en_US', symbol: '\$').format(checkoutController.subTotal), style: TextStyle(color: Palette.darkGrey, fontSize: 15*ffem, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 20,),
                                  Text(NumberFormat.currency(locale: 'en_US', symbol: '\$').format(checkoutController.discount.value), style: TextStyle(color: Palette.darkGrey, fontSize: 15*ffem, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 20,),
                                  Text(NumberFormat.currency(locale: 'en_US', symbol: '\$').format(checkoutController.gstPrice), style: TextStyle(color: Palette.darkGrey, fontSize: 15*ffem, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 20,),
                                  Text(NumberFormat.currency(locale: 'en_US', symbol: '\$').format(checkoutController.grandtotalPrice), style: TextStyle(color: Palette.primaryColor, fontSize: 20*ffem, fontWeight: FontWeight.bold)),
                                ],
                              )
                            ],
                          ),

                        ],
                      ),
                    ),
                  )

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  buildCheckout(NewBookingController controller,CheckoutController checkoutController) {

    void _handlePaymentTypeChange(String? value) { // Make the parameter nullable
      setState(() {
        _selectedPaymentType = value;
        if(value=='Cash') {
          paidAmountController.text      = '';
          balanceAmountController.text   = checkoutController.grandtotalPrice.toStringAsFixed(2);
        }
      });
    }

    if(_selectedPaymentType=='Credit Card' || _selectedPaymentType=='Account') {
      paidAmountController.text      = checkoutController.grandtotalPrice.toStringAsFixed(2);
      balanceAmountController.text   = '0.00';
    }

    if(paidAmountController.text.length > 0) {
      double paid = double.parse(paidAmountController.text);
      if(paid > 0) {
        double balance = checkoutController.grandtotalPrice - paid;
        balanceAmountController.text = balance.toStringAsFixed(2);
      }
    } else {
      balanceAmountController.text = checkoutController.grandtotalPrice.toStringAsFixed(2);
    }

    Widget _payBtn = Obx(() => checkoutController.checkoutPayBtn==false ?
    ElevatedButton(
      onPressed: () {
        if(paidAmountController.text !='' && double.parse(paidAmountController.text) > 0) {
          if(double.parse(balanceAmountController.text) <= 0) {
            setState(() {
              checkoutController.checkoutPayBtn.value = true;
            });

            if(widget.type=='Membership') {

              checkoutController.makeMembershipPayment(
                userId: customerController.selectedPlan[0]['userId'],
                userMembershipId: customerController.selectedPlan[0]['userMembershipId'],
                paymentType: _selectedPaymentType,
                promoCode: promoCodeController.text,
                notes: notesController.text,
                total: double.parse(customerController.selectedPlan[0]['price'].toString()),
                paid: double.parse(paidAmountController.text),
                balance: double.parse(balanceAmountController.text),
              );

            } else if(widget.type=='ExistingBooking') {

              checkoutController.makeBookingPayment(
                userId: defaultController.selectedUser[0].id,
                bookingSlots: defaultController.actionBookingSlots.where((slot) => slot.paymentStatus != "Paid").toList(),
                paymentType: _selectedPaymentType,
                promoCode: promoCodeController.text,
                notes: notesController.text,
                paid: double.parse(paidAmountController.text),
                balance: double.parse(balanceAmountController.text),
              );

            } else if(widget.type=='New') {

              if(controller.userData.value.id!=null) {
                //Create Booking
                checkoutController.processFinalCheckout(
                  userId: controller.userData.value.id,
                  name: controller.nameController.text,
                  email: controller.userData.value.email,
                  mobile: controller.userData.value.mobile,
                  paymentType: _selectedPaymentType,
                  promoCode: promoCodeController.text,
                  notes: notesController.text,
                  paid: double.parse(paidAmountController.text),
                  balance: double.parse(balanceAmountController.text),
                );
              } else {
                //Create user and store the booking
                checkoutController.registerUser(
                  mobile: controller.mobileNumberController.text,
                  firstName: controller.nameController.text,
                ).then((value) {
                  //Create Booking
                  checkoutController.processFinalCheckout(
                    userId: checkoutController.userData.value.id,
                    name: controller.nameController.text,
                    email: controller.userData.value.email,
                    mobile: controller.userData.value.mobile,
                    paymentType: _selectedPaymentType,
                    promoCode: promoCodeController.text,
                    notes: notesController.text,
                    paid: double.parse(paidAmountController.text),
                    balance: double.parse(balanceAmountController.text),
                  );
                },);
              }

            } else if(widget.type=='Product') {
              checkoutController.productsPayment(
                  paymentType: _selectedPaymentType,
                  promoCode: promoCodeController.text,
                  notes: notesController.text,
                  paid: double.parse(paidAmountController.text),
                  balance: double.parse(balanceAmountController.text),
                  products: shoppingController.productsCartModal
              );
            }

          } else {
            showCustomSnackbar('Warning', 'Invalid Amount', Colors.orange);
          }
        } else {
          showCustomSnackbar('Warning', 'Please enter the Paid Amount', Colors.orange);
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.double_arrow_outlined,size: 25*ffem,color: Palette.white,),
          Text(' Pay',style: TextStyle(fontSize: 15*ffem,color: Palette.white),)
        ],
      ),
      style: ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(Palette.payColors),
          shape: MaterialStatePropertyAll(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          )),
          padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 8*ffem,horizontal: 15*ffem))
      ),
    )
        :
    Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), color: Palette.lightGrey,),
      height: 50,
      width: 130,
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
    );

    return Expanded(
      flex: 2,
      child: ListView(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: [
          Column(
            children: [
              /*Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text('Promo Code',style: TextStyle(fontSize: 15*ffem),),
                      SizedBox(width: 10,),
                      Container(
                        width: MediaQuery.of(context).size.width / 6,
                        child: TextFormField(
                          controller: promoCodeController,
                          decoration:  InputDecoration(
                              border: OutlineInputBorder(borderSide: BorderSide(color: Palette.lightGrey,width: 2),borderRadius: BorderRadius.circular(10)),
                              contentPadding: EdgeInsets.symmetric(vertical: 10*ffem,horizontal: 15*ffem),
                              hintText: 'Enter the code'
                          ),
                          style: TextStyle(
                              fontSize: 15*ffem
                          ),
                          onFieldSubmitted: (value) {
                            checkoutController.validatePromocode(value);
                          },
                        ),
                      )
                    ],
                  ),
                ],
              ),*/
              SizedBox(height: 30,),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  (_selectedPaymentType=='Cash') ?
                  Row(
                    children: [
                      Text('Balance',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),),
                      SizedBox(width: 10,),
                      Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Palette.primaryColor,width: 3),
                            borderRadius: BorderRadius.circular(15)
                        ),
                        width: MediaQuery.of(context).size.width / 9,
                        child: TextFormField(
                          readOnly: true,
                          controller: balanceAmountController,
                          style: TextStyle(
                            color: Palette.primaryColor,
                            fontSize: 25*ffem, // Set the font size to make it large
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 5*ffem,)
                          ),
                        ),
                      ),
                      SizedBox(width: 50,),
                      Text('Paid',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),),
                      SizedBox(width: 10,),
                      Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Palette.primaryColor,width: 3),
                            borderRadius: BorderRadius.circular(15)
                        ),
                        width: MediaQuery.of(context).size.width / 9,
                        child: TextFormField(
                          readOnly: true,
                          controller: paidAmountController,
                          style: TextStyle(
                            color: Palette.primaryColor,
                            fontSize: 25*ffem, // Set the font size to make it large
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 5*ffem,)
                          ),
                        ),
                      ),
                    ],
                  )
                  :
                  Container()
                ],
              ),

              SizedBox(height: 30,),
              Container(
                width: MediaQuery.of(context).size.width / 2.2,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _handlePaymentTypeChange('Credit Card');
                      },
                      child: Row(
                        children: [
                          Transform.scale(
                            scale: 1.5,
                            child: Radio(
                              value: 'Credit Card',
                              groupValue: _selectedPaymentType,
                              onChanged: _handlePaymentTypeChange,
                            ),
                          ),
                          Icon(Icons.credit_card,size: 20*ffem,color: Palette.white,),
                          Text(' Card',style: TextStyle(fontSize: 15*ffem,color: Palette.white),),
                        ],
                      ),
                      style: ButtonStyle(
                          backgroundColor: MaterialStatePropertyAll(Palette.mediumGrey),
                          padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 2*ffem,horizontal: 18*ffem)),
                          shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50)
                          ))
                      ),
                    ),
                    SizedBox(width: 20,),
                    ElevatedButton(
                      onPressed: () {
                        _handlePaymentTypeChange('Cash');
                      },
                      child: Row(
                        children: [
                          Transform.scale(
                            scale: 1.5,
                            child: Radio(
                              value: 'Cash',
                              groupValue: _selectedPaymentType,
                              onChanged: _handlePaymentTypeChange,
                            ),
                          ),
                          Icon(Icons.attach_money,size: 20*ffem,color: Palette.white,),
                          Text(' Cash',style: TextStyle(fontSize: 15*ffem,color: Palette.white),),
                        ],
                      ),
                      style: ButtonStyle(
                          backgroundColor: MaterialStatePropertyAll(Palette.mediumGrey),
                          padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 2*ffem,horizontal: 18*ffem)),
                          shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50)
                          ))
                      ),
                    ),
                    SizedBox(width: 20,),
                    ElevatedButton(
                      onPressed: () {
                        _handlePaymentTypeChange('Account');
                      },
                      child: Row(
                        children: [
                          Transform.scale(
                            scale: 1.5,
                            child: Radio(
                              value: 'Account',
                              groupValue: _selectedPaymentType,
                              onChanged: _handlePaymentTypeChange,
                            ),
                          ),
                          Text('On Account',style: TextStyle(fontSize: 15*ffem,color: Palette.white),),
                        ],
                      ),
                      style: ButtonStyle(
                          backgroundColor: MaterialStatePropertyAll(Palette.mediumGrey),
                          padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 2*ffem,horizontal: 10*ffem)),
                          shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50)
                          ))
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30,),
              (_selectedPaymentType=='Cash') ?
              Container(
                width: MediaQuery.of(context).size.width / 2.2,
                child: CheckoutNumberPad(
                  submitForm: () {

                  },
                  onBackspaceTap: () {
                    setState(() {
                      if (paidAmountController.text.isNotEmpty) {
                        paidAmountController.text = paidAmountController.text.substring(0, paidAmountController.text.length - 1);
                      }
                    });
                  },
                  onNumberTap: (number) {
                    setState(() {
                      if(number=='.') {
                        if(paidAmountController.text.length > 0) {
                          paidAmountController.text += number;
                        }
                      } else {
                        paidAmountController.text += number;
                      }

                    });
                  },
                ),
              )
              :
              Container(
                width: MediaQuery.of(context).size.width / 2.2,
                child: TextFormField(
                  maxLines: 3,
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(borderSide: BorderSide(color: Palette.lightGrey,width: 2),borderRadius: BorderRadius.circular(10)),
                    contentPadding: EdgeInsets.symmetric(vertical: 10*ffem,horizontal: 15),
                    labelStyle: TextStyle(fontSize: 15*ffem),
                  ),
                  style: TextStyle(fontSize: 15*ffem),
                ),
              ),
              SizedBox(height: 10,),
              Container(
                width: MediaQuery.of(context).size.width / 2.2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Customer Copy',
                          style: TextStyle(fontSize: 15*ffem),
                        ),
                        SizedBox(width: 20,),
                        CupertinoSwitch(
                          value: _customerCopy,
                          onChanged: (value) {
                            setState(() {
                              _customerCopy = value;
                            });
                          },
                        )
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'No Receipt',
                          style: TextStyle(fontSize: 15*ffem),
                        ),
                        SizedBox(width: 20,),
                        CupertinoSwitch(
                          value: _noReceipt,
                          onChanged: (value) {
                            setState(() {
                              _noReceipt = value;
                            });
                          },
                        )
                      ],
                    )
                  ],
                ),
              ),
              SizedBox(height: 20,),
              Container(
                width: MediaQuery.of(context).size.width / 2.2,
                child: _payBtn,
              ),
              SizedBox(height: 20,),
            ],
          )
        ],
      ),
    );
  }

}
