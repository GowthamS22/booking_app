import 'dart:ffi';
import 'dart:math';

import 'package:booking_app/screens/checkout/checkout.dart';
import 'package:booking_app/screens/checkout/checkout_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../config/constants.dart';
import '../../config/palette.dart';
import '../../controllers/new_booking_controller.dart';
import '../../models/booking_model.dart';
import '../../widgets/shimmer/shimmer_booking_loading.dart';
import '../../widgets/checkout_number_pad.dart';
import '../../widgets/shimmer/shimmer_table_loading.dart';

class NewBookingScreen extends StatefulWidget {
  final bookingId;
  final type;
  final List<BookingSlot>? selectedBSlots;
  const NewBookingScreen({
    Key? key,
    this.bookingId,
    this.type,
    this.selectedBSlots,
  }) : super(key: key);

  @override
  State<NewBookingScreen> createState() => _NewBookingScreenState();
}

class _NewBookingScreenState extends State<NewBookingScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    bool hasFetchedBookingData = false;

    return GetBuilder(
      init: NewBookingController(),
      builder: (controller) {
        if (widget.type == 'New') {
          controller.selectedBooking.clear();
        }

        if (!hasFetchedBookingData && widget.selectedBSlots!.length > 0) {
          if (controller.cartItems.length <= 0) {
            controller
                .getBookingSlotData(selectedBSlots: widget.selectedBSlots)
                .then((value) {
                  if (widget.selectedBSlots!.length > 0) {
                    controller.selectedDate = widget.selectedBSlots![0].date!;
                  }
                  controller.mobileNumberController.text =
                      widget.selectedBSlots![0].mobile!;
                  controller.bookingdateController.text =
                      widget.selectedBSlots![0].createdAt.toString();
                });
          }
          hasFetchedBookingData =
              true; // Set the flag to true after calling the function
        }

        return Scaffold(
          backgroundColor: Palette.white,
          body: Container(
            padding: EdgeInsets.all(30),
            child: Column(children: [buildBody(controller)]),
          ),
        );
      },
    );
  }

  buildBody(NewBookingController controller) {
    DateFormat formatter = DateFormat('dd-MM-yyyy');
    String formattedDate = formatter.format(DateTime.now());
    controller.bookingdateController.text = formattedDate;
    DateTime? selectedTime0;
    TextEditingController dateController = TextEditingController();
    dateController.text = DateFormat(
      'yyyy-MM-dd EE',
    ).format(controller.selectedDate);

    DateTime now = controller.selectedDate;
    // Define the start and end time for the slots
    final DateTime startTime = DateTime(
      now.year,
      now.month,
      now.day,
      controller.startTime,
      0,
      0,
    );
    final DateTime endTime = DateTime(
      now.year,
      now.month,
      now.day,
      controller.endTime,
      0,
      0,
    );

    // Function to generate the list of time slots
    List<TimeSlot> generateTimeSlots(min) {
      List<TimeSlot> timeSlots = [];
      DateTime currentTime = startTime;
      while (currentTime.isBefore(endTime)) {
        DateTime nextTime = currentTime.add(Duration(minutes: min));
        /*if (nextTime.hour == 0 && nextTime.minute == 0) {
          nextTime = DateTime(endTime.year, endTime.month, endTime.day, 23, 59, 59);
        }*/
        timeSlots.add(TimeSlot(startTime: currentTime, endTime: nextTime));
        currentTime = nextTime;
      }
      return timeSlots;
    }

    List<TimeSlot> hourTimeSlots = generateTimeSlots(60);

    List<String> items = List.generate(20, (index) => 'Item ${index + 1}');

    if (controller.mobileNumberController.text.length >= 10) {
      if (controller.userData.value.id != null) {
        if (controller.userData.value.mobile !=
            controller.mobileNumberController.text) {
          controller.userData.value.id = null;
          controller.getUserDatabyMobile(
            controller.mobileNumberController.text,
          );
        }
      } else {
        controller.getUserDatabyMobile(controller.mobileNumberController.text);
      }
    }
    if (controller.userData.value.id != null) {
      controller.nameController.text = controller.userData.value.firstName!;
    }

    Widget confirmBtn = Obx(
      () =>
          controller.confirmBtn.value == false
              ? ElevatedButton(
                onPressed:
                    controller.cartItems.length > 0
                        ? () {
                          if (controller.nameController.text != '' &&
                              controller.mobileNumberController.text != '') {
                            buildConfirmPopup(controller);
                          } else {
                            validationDialog(controller);
                          }
                        }
                        : null,
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    controller.cartItems.length > 0
                        ? Palette.primaryColor
                        : Palette.secondaryColor,
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(vertical: 15, horizontal: 35),
                  ),
                ),
                child: Text(
                  'Confirm',
                  style: GoogleFonts.poppins(
                    fontSize: 15 * ffem,
                    color: Palette.white,
                  ),
                ),
              )
              : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: Colors.grey,
                ),
                height: 50,
                width: 130,
                child: Center(
                  child: SizedBox(
                    height: 30 * ffem,
                    width: 30 * ffem,
                    child: CircularProgressIndicator(
                      color: Palette.primaryColor,
                    ),
                  ),
                ),
              ),
    );

    Widget updateBtn = Obx(
      () =>
          controller.confirmBtn.value == false
              ? ElevatedButton(
                onPressed:
                    controller.cartItems.length > 0
                        ? () {
                          buildConfirmPopup(controller);
                        }
                        : null,
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    controller.cartItems.length > 0
                        ? Palette.primaryColor
                        : Palette.secondaryColor,
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(vertical: 15, horizontal: 35),
                  ),
                ),
                child: Text(
                  'Update Booking',
                  style: GoogleFonts.poppins(
                    fontSize: 15 * ffem,
                    color: Palette.white,
                  ),
                ),
              )
              : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: Colors.grey,
                ),
                height: 50,
                width: 130,
                child: Center(
                  child: SizedBox(
                    height: 40,
                    width: 40,
                    child: CircularProgressIndicator(
                      color: Palette.primaryColor,
                    ),
                  ),
                ),
              ),
    );

    List<BookingSlot> cartItems = [];
    for (var item in controller.cartItems) {
      cartItems.add(
        BookingSlot(
          userId: item.userId,
          name: item.name,
          mobile: item.mobile,
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
          repeatGroupId: item.repeatGroupId,
        ),
      );
    }

    List<BookingSlot> mergedSlots = controller.mergeTimeSlots(cartItems);
    //mergedSlots.removeWhere((bookingSlot) => (bookingSlot.slotType=='Repeat-Item'));

    List<TimeSlot> timeSlots = generateTimeSlots(30);

    return Expanded(
      child: ListView(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    (widget.selectedBSlots!.length <= 0)
                        ? 'New Booking'
                        : 'Edit Booking #',
                    style: GoogleFonts.poppins(
                      fontSize: 20 * ffem,
                      color: Palette.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      (widget.selectedBSlots!.length <= 0)
                          ? Row(
                            children: [
                              ElevatedButton(
                                onPressed:
                                    controller.cartItems.length > 0
                                        ? () {
                                          if (controller.nameController.text !=
                                                  '' &&
                                              controller
                                                      .mobileNumberController
                                                      .text !=
                                                  '') {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              Get.to(
                                                //Checkout(),
                                                CheckoutScreen(type: 'New'),
                                              );
                                            }
                                          } else {
                                            validationDialog(controller);
                                          }
                                        }
                                        : null,
                                style: ButtonStyle(
                                  backgroundColor: WidgetStatePropertyAll(
                                    controller.cartItems.length > 0
                                        ? Palette.payColors
                                        : Palette.payColorsLight,
                                  ),
                                  shape: WidgetStatePropertyAll(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                  ),
                                  padding: WidgetStatePropertyAll(
                                    EdgeInsets.symmetric(
                                      vertical: 15,
                                      horizontal: 35,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Pay Now',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15 * ffem,
                                    color: Palette.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 50),
                              confirmBtn,
                            ],
                          )
                          : updateBtn,
                      SizedBox(width: 50),
                      ElevatedButton(
                        onPressed: () {
                          Get.offAllNamed('/');
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            Palette.dangerBg,
                          ),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                              side: BorderSide(
                                color: Palette.dangerTxt,
                                width: 1,
                              ),
                            ),
                          ),
                          padding: WidgetStatePropertyAll(
                            EdgeInsets.symmetric(vertical: 15, horizontal: 35),
                          ),
                        ),
                        child: Text(
                          'Discard',
                          style: GoogleFonts.poppins(
                            fontSize: 15 * ffem,
                            color: Palette.dangerTxt,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 30),
              Form(
                key: _formKey,
                child: Row(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Mobile No',
                          style: GoogleFonts.poppins(fontSize: 15 * ffem),
                        ),
                        SizedBox(width: 10),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 6.5,
                          child: Autocomplete<String>(
                            optionsBuilder: (
                              TextEditingValue textEditingValue,
                            ) {
                              if (textEditingValue.text.length < 3) {
                                return const Iterable<String>.empty();
                              }
                              final input = textEditingValue.text.replaceAll(
                                ' ',
                                '',
                              );
                              return controller.mobileList.where(
                                (number) =>
                                    number.contains(textEditingValue.text) ||
                                    number.contains(input),
                              );
                            },
                            fieldViewBuilder: (
                              context,
                              textEditingController,
                              focusNode,
                              onFieldSubmitted,
                            ) {
                              controller.mobileNumberController =
                                  textEditingController;
                              return TextField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Palette.lightGrey,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 10 * ffem,
                                    horizontal: 15,
                                  ),
                                ),
                                style: GoogleFonts.poppins(fontSize: 15 * ffem),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  if (value.length >= 10) {
                                    controller.getUserDatabyMobile(value);
                                  }
                                },
                              );
                            },
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 4,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(maxHeight: 200),
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      itemCount: options.length,
                                      itemBuilder: (context, index) {
                                        final option = options.elementAt(index);
                                        return ListTile(
                                          title: Text(
                                            option,
                                            style: GoogleFonts.poppins(
                                              fontSize: 15 * ffem,
                                            ),
                                          ),
                                          onTap: () {
                                            onSelected(option);
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                            onSelected: (String selection) {
                              setState(() {
                                controller.mobileNumberController.text =
                                    selection;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    // Row(
                    //   children: [
                    //     Text(
                    //       'Mobile No',
                    //       style: GoogleFonts.poppins(fontSize: 15 * ffem),
                    //     ),
                    //     SizedBox(width: 10),
                    //     Container(
                    //       width: MediaQuery.of(context).size.width / 6.5,
                    //       child: TypeAheadField(
                    //         textFieldConfiguration: TextFieldConfiguration(
                    //           controller: controller.mobileNumberController,
                    //           decoration:  InputDecoration(
                    //             border: OutlineInputBorder(borderSide: BorderSide(color: Palette.lightGrey,width: 2,),borderRadius: BorderRadius.circular(10)),
                    //             contentPadding: EdgeInsets.symmetric(vertical: 10*ffem,horizontal: 15),
                    //           ),
                    //           style: GoogleFonts.poppins(
                    //               fontSize: 15*ffem
                    //           ),
                    //           inputFormatters: <TextInputFormatter>[
                    //             FilteringTextInputFormatter.digitsOnly,
                    //           ], // Only
                    //           keyboardType: TextInputType.number,
                    //           onChanged: (value) {
                    //             if(value.length >= 10) {
                    //               controller.getUserDatabyMobile(value);
                    //             }
                    //           },
                    //         ),
                    //         suggestionsCallback: (pattern) {
                    //           return controller.mobileList.where((number) => number.contains(pattern) || number.contains(pattern.replaceAll(' ', ''))) .toList();
                    //         },
                    //         itemBuilder: (context, suggestion) {
                    //           return ListTile(
                    //             title: Text(suggestion,style: GoogleFonts.poppins(fontSize: 15*ffem)),
                    //           );
                    //         },
                    //         onSuggestionSelected: (suggestion) {
                    //           setState(() {
                    //             controller.mobileNumberController.text = suggestion;
                    //           });
                    //         },
                    //         errorBuilder: (context, error) {
                    //           return Text('');
                    //         },
                    //         hideOnEmpty: false,
                    //         keepSuggestionsOnLoading: false,
                    //         minCharsForSuggestions: 3,
                    //         noItemsFoundBuilder: (context) {
                    //           return Container(
                    //             padding: EdgeInsets.symmetric(vertical: 10*ffem,horizontal: 10*ffem),
                    //             child: Text('No Match Found'),
                    //           );
                    //         }, onSelected: (value) {  },
                    //       ),
                    //     )
                    //   ],
                    // ),
                    SizedBox(width: 20),
                    Row(
                      children: [
                        Text(
                          'Name',
                          style: GoogleFonts.poppins(fontSize: 15 * ffem),
                        ),
                        SizedBox(width: 10),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 6.5,
                          child: TextFormField(
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '';
                              }
                              return null;
                            },
                            controller: controller.nameController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Palette.lightGrey,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 10 * ffem,
                                horizontal: 15,
                              ),
                            ),
                            style: GoogleFonts.poppins(fontSize: 15 * ffem),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 20),
                    Row(
                      children: [
                        Text(
                          'Game',
                          style: GoogleFonts.poppins(fontSize: 15 * ffem),
                        ),
                        SizedBox(width: 10),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 6.5,
                          child: DropdownButtonFormField<String>(
                            value:
                                (controller.selectedServiceId.value.isNotEmpty)
                                    ? controller.selectedServiceId.value
                                    : null,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Palette.lightGrey,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 10 * ffem,
                                horizontal: 15,
                              ),
                            ),
                            items:
                                controller.serviceList.map((item) {
                                  return DropdownMenuItem<String>(
                                    value: item['id'],
                                    child: Text(
                                      '${item['name']}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15 * ffem,
                                      ),
                                    ),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                controller.selectedServiceId.value = value!;
                                controller.bookedSlots.clear();
                                controller.fetchBookedSlots();
                                controller.courtList.clear();
                                controller.fetchCourtList();
                                controller.fetchStartEndTime();
                              });
                            },
                            onSaved: (value) {},
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 20),
                    Row(
                      children: [
                        Text(
                          'Booking Date',
                          style: GoogleFonts.poppins(fontSize: 15 * ffem),
                        ),
                        SizedBox(width: 10),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 6.5,
                          child: TextFormField(
                            readOnly: true,
                            controller: controller.bookingdateController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Palette.lightGrey,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 10 * ffem,
                                horizontal: 15,
                              ),
                            ),
                            style: GoogleFonts.poppins(fontSize: 15 * ffem),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(height: 40 * ffem, color: Palette.darkGrey, thickness: 2),

              //Booking elements
              Column(
                children: [
                  (controller.cartItems.length > 0)
                      ? ListView.builder(
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        itemCount: mergedSlots.length,
                        itemBuilder: (context, index) {
                          BookingSlot cartItem = mergedSlots[index];

                          //Add Sub booking id to the slots
                          String subID = Uuid().v4();
                          Iterable<BookingSlot> subItems = controller.cartItems
                              .where(
                                (bookingSlot) =>
                                    (bookingSlot.startTime!.isAfter(
                                          cartItem.startTime!,
                                        ) ||
                                        bookingSlot.startTime!.isAtSameMomentAs(
                                          cartItem.startTime!,
                                        )) &&
                                    (bookingSlot.endTime!.isBefore(
                                          cartItem.endTime!,
                                        ) ||
                                        bookingSlot.endTime!.isAtSameMomentAs(
                                          cartItem.endTime!,
                                        )) &&
                                    bookingSlot.date == cartItem.date &&
                                    bookingSlot.serviceId ==
                                        cartItem.serviceId &&
                                    bookingSlot.courtId == cartItem.courtId &&
                                    bookingSlot.repeatGroupId ==
                                        bookingSlot.repeatGroupId,
                              );

                          String? nonNullBookingId;
                          for (var sub in subItems) {
                            if (sub.bookingId != null) {
                              nonNullBookingId = sub.subBookingId;
                              break;
                            }
                          }

                          for (var sub in subItems) {
                            if (nonNullBookingId != null) {
                              sub.subBookingId = nonNullBookingId;
                            } else {
                              sub.subBookingId = subID;
                            }
                          }
                          //Add Sub booking id to the slots

                          String fmtdStartTime =
                              cartItem.startTime != null
                                  ? DateFormat(
                                    'hh:mm a',
                                  ).format(cartItem.startTime!)
                                  : '';
                          String fmtdEndTime =
                              cartItem.endTime != null
                                  ? DateFormat(
                                    'hh:mm a',
                                  ).format(cartItem.endTime!)
                                  : '';

                          var finalPrice =
                              (cartItem.slotType == 'Repeated')
                                  ? controller.calculateRepeatPrice(
                                    repeatGroupId: cartItem.repeatGroupId,
                                  )
                                  : cartItem.price;
                          if (cartItem.slotType != 'Repeat-Item') {
                            return Container(
                              width: double.infinity,
                              margin: EdgeInsets.symmetric(vertical: 5),
                              padding: EdgeInsets.symmetric(
                                vertical: 7,
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Palette.fieldBg,
                                borderRadius: BorderRadius.circular(15 * ffem),
                                border: Border.all(
                                  color: Palette.lightGrey,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          ElevatedButton(
                                            onPressed: null,
                                            style: ButtonStyle(
                                              backgroundColor:
                                                  WidgetStatePropertyAll(
                                                    Colors.deepPurpleAccent,
                                                  ),
                                              shape: WidgetStatePropertyAll(
                                                RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        15 * ffem,
                                                      ),
                                                ),
                                              ),
                                              padding: WidgetStatePropertyAll(
                                                EdgeInsets.symmetric(
                                                  horizontal: 15 * ffem,
                                                  vertical: 10 * ffem,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              '${cartItem.court}',
                                              style: GoogleFonts.poppins(
                                                color: Palette.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15 * ffem,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 50),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                DateFormat(
                                                  'dd/MM/yyy EE',
                                                ).format(cartItem.date!),
                                                style: GoogleFonts.poppins(
                                                  color: Palette.primaryColor,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15 * ffem,
                                                ),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                '${fmtdStartTime} - ${fmtdEndTime}',
                                                style: GoogleFonts.poppins(
                                                  color: Palette.primaryColor,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15 * ffem,
                                                ),
                                              ),
                                            ],
                                          ),
                                          //Text('${DateFormat('dd/MM/yyy EEEE').format(cartItem.date!)}\n${fmtdStartTime} - ${fmtdEndTime}',style: GoogleFonts.poppins(color: Palette.primaryColor,fontWeight:FontWeight.w600,fontSize: 25),),
                                          //SizedBox(width: 50,),
                                          //Text('${fmtdStartTime} - ${fmtdEndTime}',style: GoogleFonts.poppins(color: Palette.primaryColor,fontWeight:FontWeight.w600,fontSize: 25),),
                                          SizedBox(width: 50),

                                          (cartItem.slotType == 'Repeated')
                                              ? (widget.selectedBSlots !=
                                                          null &&
                                                      widget
                                                              .selectedBSlots!
                                                              .length >
                                                          0)
                                                  ? Container()
                                                  : Row(
                                                    children: [
                                                      Text(
                                                        controller.repeatDays(
                                                          repeatDays:
                                                              cartItem
                                                                  .repeatDays,
                                                        ),
                                                        style: GoogleFonts.poppins(
                                                          color:
                                                              Palette
                                                                  .primaryColor,
                                                          fontSize: 15 * ffem,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      SizedBox(width: 50),
                                                      Text(
                                                        DateFormat(
                                                          'dd-MM-yyy',
                                                        ).format(
                                                          cartItem.repeatEnd!,
                                                        ),
                                                        style: GoogleFonts.poppins(
                                                          color:
                                                              Palette
                                                                  .primaryColor,
                                                          fontSize: 15 * ffem,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                              : Row(
                                                children: [
                                                  Text(
                                                    ' - ',
                                                    style: GoogleFonts.poppins(
                                                      color:
                                                          Palette.primaryColor,
                                                      fontSize: 15 * ffem,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  SizedBox(width: 50),
                                                  Text(
                                                    ' - ',
                                                    style: GoogleFonts.poppins(
                                                      color:
                                                          Palette.primaryColor,
                                                      fontSize: 15 * ffem,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        NumberFormat.currency(
                                          locale: 'en_US',
                                          symbol: '\$',
                                        ).format(finalPrice),
                                        style: GoogleFonts.poppins(
                                          color: Palette.primaryColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15 * ffem,
                                        ),
                                      ),
                                      (widget.selectedBSlots != null &&
                                              widget.selectedBSlots!.length > 0)
                                          ? Container()
                                          : Row(
                                            children: [
                                              SizedBox(width: 30),
                                              ElevatedButton(
                                                onPressed: () {
                                                  controller.selectedDays
                                                      .clear();
                                                  controller.repeatUntil = null;

                                                  if (cartItem.slotType ==
                                                      'Repeated') {
                                                    String cleanString =
                                                        cartItem.repeatDays!
                                                            .replaceAll(
                                                              RegExp(r'[{}\s]'),
                                                              '',
                                                            );
                                                    List<String> daysList =
                                                        cleanString.split(',');
                                                    for (var rday in daysList) {
                                                      controller.selectedDays
                                                          .add(rday);
                                                    }
                                                    controller.repeatUntil =
                                                        cartItem.repeatEnd;
                                                  }

                                                  buildRepeatDialog(
                                                    controller,
                                                    cartItem.startTime,
                                                    cartItem.endTime,
                                                    cartItem.serviceId,
                                                    cartItem.courtId,
                                                    cartItem.date,
                                                    cartItem.repeatGroupId,
                                                  );
                                                },
                                                style: ButtonStyle(
                                                  backgroundColor:
                                                      WidgetStatePropertyAll(
                                                        Palette.white,
                                                      ),
                                                  shape: WidgetStatePropertyAll(
                                                    RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            35,
                                                          ),
                                                    ),
                                                  ),
                                                  padding:
                                                      WidgetStatePropertyAll(
                                                        EdgeInsets.symmetric(
                                                          horizontal: 15 * ffem,
                                                          vertical: 10 * ffem,
                                                        ),
                                                      ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      cartItem.slotType ==
                                                              'Repeated'
                                                          ? Icons
                                                              .edit_calendar_outlined
                                                          : Icons.refresh,
                                                      size: 20 * ffem,
                                                      color:
                                                          Palette.primaryColor,
                                                    ),
                                                    Text(
                                                      cartItem.slotType ==
                                                              'Repeated'
                                                          ? ' Modify'
                                                          : ' Repeat Booking',
                                                      style: GoogleFonts.poppins(
                                                        color:
                                                            Palette
                                                                .primaryColor,
                                                        fontSize: 15 * ffem,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                      SizedBox(width: 50),
                                      ElevatedButton(
                                        onPressed: () {
                                          controller.deleteSlot(
                                            dateToRemove: cartItem.date,
                                            serviceIdToRemove:
                                                cartItem.serviceId,
                                            courtIdToRemove: cartItem.courtId,
                                            startTimeToRemove:
                                                cartItem.startTime,
                                            endTimeToRemove: cartItem.endTime,
                                            slotTypeToRemove: cartItem.slotType,
                                            repeatGroupIdToRemove:
                                                cartItem.repeatGroupId,
                                          );
                                        },
                                        style: ButtonStyle(
                                          shape: WidgetStatePropertyAll(
                                            RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(60),
                                            ),
                                          ),
                                          backgroundColor:
                                              WidgetStatePropertyAll(
                                                Palette.dangerBg,
                                              ),
                                          padding: WidgetStatePropertyAll(
                                            EdgeInsets.all(10 * ffem),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.delete,
                                          size: 20 * ffem,
                                          color: Palette.dangerTxt,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          } else {
                            return Container();
                          }
                        },
                      )
                      : Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(vertical: 10),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Palette.fieldBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Palette.lightGrey,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Select a court',
                          style: GoogleFonts.poppins(
                            fontSize: 15 * ffem,
                            color: Palette.primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                ],
              ),
              SizedBox(height: 10 * ffem),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 35 * ffem,
                        width: 190,
                        child: ElevatedButton(
                          onPressed:
                              (DateTime(
                                        DateTime.now().year,
                                        DateTime.now().month,
                                        DateTime.now().day,
                                      ) !=
                                      controller.selectedDate)
                                  ? () {
                                    setState(() {
                                      if (DateTime(
                                            DateTime.now().year,
                                            DateTime.now().month,
                                            DateTime.now().day,
                                          ) !=
                                          controller.selectedDate) {
                                        DateTime selectedTime = controller
                                            .selectedDate
                                            .subtract(Duration(days: 1));
                                        controller.selectedDate = selectedTime;
                                        dateController.text = DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(controller.selectedDate);

                                        controller.bookedSlots.clear();
                                        controller.fetchBookedSlots();
                                        controller.courtList.clear();
                                        controller.fetchCourtList();
                                        controller.fetchStartEndTime();
                                      }
                                    });
                                  }
                                  : null,
                          style: ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll(
                              Palette.fieldBg,
                            ),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            alignment: Alignment.center,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_left_outlined,
                                color: Palette.primaryColor,
                                size: 30,
                              ),
                              Text(
                                'Previous Day',
                                style: GoogleFonts.poppins(
                                  color:
                                      (controller.selectedDate !=
                                              DateTime(
                                                DateTime.now().year,
                                                DateTime.now().month,
                                                DateTime.now().day,
                                              ))
                                          ? Palette.primaryColor
                                          : Palette.secondaryColor,
                                  fontSize: 14 * ffem,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      SizedBox(
                        height: 35 * ffem,
                        width: 180,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              DateTime selectedTime = DateTime(
                                DateTime.now().year,
                                DateTime.now().month,
                                DateTime.now().day,
                              );
                              controller.selectedDate = selectedTime;
                              dateController.text = DateFormat(
                                'yyyy-MM-dd',
                              ).format(controller.selectedDate);
                            });

                            controller.bookedSlots.clear();
                            controller.fetchBookedSlots();
                            controller.courtList.clear();
                            controller.fetchCourtList();
                            controller.fetchStartEndTime();
                          },
                          style: ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll(
                              Palette.fieldBg,
                            ),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            alignment: Alignment.center,
                          ),
                          child: Text(
                            'Today',
                            style: GoogleFonts.poppins(
                              color: Palette.primaryColor,
                              fontSize: 13 * ffem,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      SizedBox(
                        height: 35 * ffem,
                        width: 180,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              DateTime selectedTime = controller.selectedDate
                                  .add(Duration(days: 1));
                              controller.selectedDate = selectedTime;
                              dateController.text = DateFormat(
                                'yyyy-MM-dd',
                              ).format(controller.selectedDate);
                            });
                            controller.bookedSlots.clear();
                            controller.fetchBookedSlots();
                            controller.courtList.clear();
                            controller.fetchCourtList();
                            controller.fetchStartEndTime();
                          },
                          style: ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll(
                              Palette.fieldBg,
                            ),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            alignment: Alignment.center,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_right_outlined,
                                color: Palette.primaryColor,
                                size: 30,
                              ),
                              Text(
                                'Next Day',
                                style: GoogleFonts.poppins(
                                  color: Palette.primaryColor,
                                  fontSize: 14 * ffem,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width: 20),
                      SizedBox(
                        height: 35 * ffem,
                        width: 200,
                        child: TextFormField(
                          controller: dateController,
                          //initialValue: DateFormat('yyyy-MM-dd').format(controller.selectedDate),
                          readOnly: true,
                          onTap: () async {
                            final initialTime = DateTime.now();
                            final selectedTime = await showDatePicker(
                              firstDate: DateTime(2023),
                              lastDate: DateTime(initialTime.year + 1),
                              context: context,
                              initialDate: selectedTime0 ?? initialTime,
                              selectableDayPredicate: (DateTime date) {
                                return date.isAfter(
                                  initialTime.subtract(Duration(days: 1)),
                                ); // Disable previous days
                              },
                            );
                            if (selectedTime != null) {
                              setState(() {
                                controller.selectedDate = selectedTime;
                                selectedTime0 = selectedTime;
                                dateController.text = DateFormat(
                                  'yyyy-MM-dd',
                                ).format(controller.selectedDate);
                              });
                              //controller.bookedSlots.clear();
                              //controller.fetechBookedSlots();
                              controller.courtList.clear();
                              controller.fetchCourtList();
                              controller.fetchStartEndTime();
                            }
                          },
                          decoration: InputDecoration(
                            suffixIcon: Icon(
                              Icons.calendar_month,
                              size: 25 * ffem,
                              color: Palette.primaryColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Palette.white),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Palette.white),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Palette.white),
                            ),
                            filled: true,
                            fillColor: Palette.white,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 5 * ffem,
                            ),
                          ),
                          style: GoogleFonts.poppins(fontSize: 15 * ffem),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 30),

              (controller.courtList.length > 0)
                  ? SizedBox(
                    width: timeSlots.length * 56,
                    child: Row(
                      children: [
                        Expanded(flex: 1, child: Container()),
                        SizedBox(width: 10),
                        Expanded(
                          flex: 6,
                          child: GridView.builder(
                            scrollDirection: Axis.vertical,
                            shrinkWrap: true,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: hourTimeSlots.length,
                                  crossAxisSpacing: 5,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 2,
                                ),
                            itemCount: hourTimeSlots.length,
                            itemBuilder: (context, index) {
                              final slot = hourTimeSlots[index];
                              return ElevatedButton(
                                onPressed: null,
                                style: ButtonStyle(
                                  padding: WidgetStatePropertyAll(
                                    EdgeInsets.symmetric(horizontal: 2),
                                  ),
                                  shape: WidgetStatePropertyAll(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: Palette.lightGrey,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  backgroundColor: WidgetStatePropertyAll(
                                    Palette.fieldBg,
                                  ),
                                ),
                                child: Text(
                                  DateFormat('h a').format(slot.startTime),
                                  style: GoogleFonts.poppins(
                                    fontSize: 13 * ffem,
                                    color: Palette.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                  : ShimmerBookingLoading(columnCount: 9, rowCount: 1),

              (controller.courtList.length > 0)
                  ? StreamBuilder<List<BookingSlot>>(
                    stream: controller.getBookingSlotStream(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }

                      if (snapshot.connectionState == ConnectionState.waiting ||
                          snapshot.data == null) {
                        return ShimmerTableLoading(columnCount: 6, rowCount: 4);
                      }

                      // Update the bookedSlots list with the new data
                      controller.bookedSlots = snapshot.data!;
                      //controller.update();

                      return InkWell(
                        onTap:
                            (controller.mobileNumberController.text == '' ||
                                    controller.nameController.text == '')
                                ? () {
                                  validationDialog(controller);
                                }
                                : null,
                        child: IgnorePointer(
                          ignoring:
                              (controller.mobileNumberController.text == '' ||
                                      controller.nameController.text == '')
                                  ? true
                                  : false,
                          child: SizedBox(
                            width: timeSlots.length * 56,
                            height: MediaQuery.of(context).size.height / 1.66,
                            child: ListView.builder(
                              controller: ScrollController(),
                              itemCount: controller.courtList.length,
                              itemBuilder: (context, index) {
                                final court = controller.courtList[index];

                                return Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        height: 40,
                                        margin: EdgeInsets.symmetric(
                                          vertical: 5,
                                        ),
                                        child: ElevatedButton(
                                          onPressed: null,
                                          style: ButtonStyle(
                                            backgroundColor:
                                                WidgetStatePropertyAll(
                                                  Palette.fieldBg,
                                                ),
                                            shape: WidgetStatePropertyAll(
                                              RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                            ),
                                          ),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              '${court['name']}',
                                              style: GoogleFonts.poppins(
                                                color: Palette.primaryColor,
                                                fontSize: 15 * ffem,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      flex: 6,
                                      child: GridView.builder(
                                        scrollDirection: Axis.vertical,
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: timeSlots.length,
                                              crossAxisSpacing: 5,
                                              mainAxisSpacing: 10,
                                            ),
                                        itemCount: timeSlots.length,
                                        itemBuilder: (context, index) {
                                          final slot = timeSlots[index];

                                          bool bookStatus = controller
                                              .checkBooked(
                                                dateToFind:
                                                    controller.selectedDate,
                                                serviceIdToFind:
                                                    controller
                                                        .selectedServiceId
                                                        .value,
                                                courtIdToFind: court['id'],
                                                startTimeToFind: slot.startTime,
                                              );

                                          String? subBookingId = controller
                                              .getBookedId(
                                                dateToFind:
                                                    controller.selectedDate,
                                                serviceIdToFind:
                                                    controller
                                                        .selectedServiceId
                                                        .value,
                                                courtIdToFind: court['id'],
                                                startTimeToFind: slot.startTime,
                                              );

                                          bool status = controller.validateSlot(
                                            dateToFind: controller.selectedDate,
                                            serviceIdToFind:
                                                controller
                                                    .selectedServiceId
                                                    .value,
                                            courtIdToFind: court['id'],
                                            startTimeToFind: slot.startTime,
                                          );

                                          return ElevatedButton(
                                            onLongPress:
                                                (bookStatus == true)
                                                    ? () {
                                                      if (controller
                                                              .selectedBookingId
                                                              .value !=
                                                          '') {
                                                        courtChangeDialog(
                                                          controller,
                                                          controller
                                                              .selectedBookingId
                                                              .toString(),
                                                        );
                                                      }
                                                    }
                                                    : null,
                                            onPressed:
                                                bookStatus == false
                                                    ? status == false
                                                        ? () {
                                                          controller.bookSlot(
                                                            service:
                                                                controller
                                                                    .selectedService
                                                                    .value,
                                                            serviceId:
                                                                controller
                                                                    .selectedServiceId
                                                                    .value,
                                                            court:
                                                                court['name'],
                                                            courtId:
                                                                court['id'],
                                                            date:
                                                                controller
                                                                    .selectedDate,
                                                            startTime:
                                                                slot.startTime,
                                                            endTime:
                                                                slot.endTime,
                                                            price:
                                                                court['price']
                                                                    .toDouble(),
                                                          );
                                                        }
                                                        : () {
                                                          controller.removeSlot(
                                                            dateToRemove:
                                                                controller
                                                                    .selectedDate,
                                                            serviceIdToRemove:
                                                                controller
                                                                    .selectedServiceId
                                                                    .value,
                                                            courtIdToRemove:
                                                                court['id'],
                                                            startTimeToRemove:
                                                                slot.startTime,
                                                          );
                                                        }
                                                    : () {
                                                      if (controller
                                                              .selectedBookingId
                                                              .value ==
                                                          '') {
                                                        String?
                                                        subBookingId = controller
                                                            .getBookedId(
                                                              dateToFind:
                                                                  controller
                                                                      .selectedDate,
                                                              serviceIdToFind:
                                                                  controller
                                                                      .selectedServiceId
                                                                      .value,
                                                              courtIdToFind:
                                                                  court['id'],
                                                              startTimeToFind:
                                                                  slot.startTime,
                                                            );
                                                        setState(() {
                                                          if (subBookingId !=
                                                              null) {
                                                            controller
                                                                    .selectedBookingId
                                                                    .value =
                                                                subBookingId!;
                                                          }
                                                        });
                                                      } else {
                                                        setState(() {
                                                          controller
                                                              .selectedBookingId
                                                              .value = '';
                                                        });
                                                      }
                                                    },
                                            style: ButtonStyle(
                                              shape: WidgetStatePropertyAll(
                                                RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  side: BorderSide(
                                                    color:
                                                        (controller
                                                                    .selectedBookingId
                                                                    .value ==
                                                                subBookingId)
                                                            ? Colors.orange
                                                            : Colors.grey,
                                                    width: 1,
                                                  ),
                                                ),
                                              ),
                                              backgroundColor:
                                                  bookStatus == false
                                                      ? status == false
                                                          ? WidgetStatePropertyAll(
                                                            Palette.white,
                                                          )
                                                          : WidgetStatePropertyAll(
                                                            Palette
                                                                .primaryColor,
                                                          )
                                                      : controller
                                                              .selectedBookingId
                                                              .value ==
                                                          subBookingId
                                                      ? WidgetStatePropertyAll(
                                                        Colors.orange,
                                                      )
                                                      : WidgetStatePropertyAll(
                                                        Palette.mediumGrey,
                                                      ),
                                            ),
                                            child: Text(''),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  )
                  : ShimmerBookingLoading(columnCount: 9, rowCount: 6),
            ],
          ),
        ],
      ),
    );
  }

  buildRepeatDialog(
    NewBookingController controller,
    DateTime? startTime,
    DateTime? endTime,
    String? serviceId,
    String? courtId,
    DateTime? date,
    String? repeatGroupId,
  ) {
    final repeatFormKey = GlobalKey<FormState>();

    final TextEditingController repeatDateController = TextEditingController();

    Future<void> selectRepeatDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate:
            controller.repeatUntil == null
                ? DateTime.now()
                : controller.repeatUntil!,
        firstDate: DateTime(DateTime.now().year),
        lastDate: DateTime(
          DateTime.now().year + 1,
          DateTime.now().month,
          DateTime.now().day,
        ),
      );

      if (picked != null && picked != controller.repeatUntil) {
        setState(() {
          controller.repeatUntil = picked;
          repeatDateController.text =
              '${controller.repeatUntil!.day}-${controller.repeatUntil!.month}-${controller.repeatUntil!.year}';
        });
      }
    }

    if (controller.repeatUntil != null) {
      repeatDateController.text =
          '${controller.repeatUntil!.day}-${controller.repeatUntil!.month}-${controller.repeatUntil!.year}';
    } else {
      repeatDateController.text = '';
    }

    /*int selectedDay = DateTime.monday;
    List<DateTime> upcomingDays = controller.getUpcomingDays(DateTime(2023,08,01),DateTime(2023,08,30),selectedDay);
    print(upcomingDays);*/

    List<String> days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
      'Daily',
    ];

    Widget saveBtn = Obx(
      () =>
          controller.isLoading == false
              ? ElevatedButton(
                onPressed: () {
                  if (controller.selectedDays.length > 0 &&
                      controller.repeatUntil != '' &&
                      controller.repeatUntil != null) {
                    setState(() {
                      controller.isLoading.value = true;
                    });
                    controller.addRepeatBooking(
                      startTime,
                      endTime,
                      serviceId,
                      courtId,
                      date,
                      repeatGroupId,
                    );
                  } else {
                    showCustomSnackbar(
                      'Warning',
                      'Please select the days and date',
                      Colors.orange,
                    );
                  }
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Palette.primaryColor),
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(
                      vertical: 10 * ffem,
                      horizontal: 40 * ffem,
                    ),
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
                child: Text(
                  'Confirm',
                  style: GoogleFonts.poppins(fontSize: 15 * ffem),
                ),
              )
              : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: Colors.grey,
                ),
                height: 70,
                width: 160,
                child: Center(
                  child: SizedBox(
                    height: 40,
                    width: 40,
                    child: CircularProgressIndicator(
                      color: Palette.primaryColor,
                    ),
                  ),
                ),
              ),
    );

    return Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Container(
          padding: EdgeInsets.all(10),
          child: SingleChildScrollView(
            child: Form(
              key: repeatFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Repeating Days',
                    style: GoogleFonts.poppins(
                      fontSize: 15 * ffem,
                      color: Palette.darkGrey,
                    ),
                  ),
                  Divider(color: Palette.mediumGrey, height: 40, thickness: 2),
                  GetBuilder(
                    init: NewBookingController(),
                    builder: (controller) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10.0,
                            runSpacing: 10.0,
                            children:
                                days.map((day) {
                                  return ElevatedButton(
                                    onPressed: () {
                                      if (day == 'Daily') {
                                        for (var sday in days) {
                                          if (sday != 'Daily') {
                                            controller.toggleDay(sday);
                                          }
                                        }
                                      } else {
                                        controller.toggleDay(day);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          controller.selectedDays.contains(day)
                                              ? Palette.primaryColor
                                              : Palette.fieldBg,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 10 * ffem,
                                        horizontal: 15 * ffem,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(40),
                                        side: BorderSide(
                                          color: Palette.primaryColor,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      day,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15 * ffem,
                                        color:
                                            controller.selectedDays.contains(
                                                  day,
                                                )
                                                ? Palette.white
                                                : Palette.primaryColor,
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 10),

                  Text(
                    'Repeat Until',
                    style: GoogleFonts.poppins(
                      fontSize: 15 * ffem,
                      color: Palette.darkGrey,
                    ),
                  ),
                  Divider(
                    color: Palette.mediumGrey,
                    height: 20 * ffem,
                    thickness: 2,
                  ),
                  /*Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('Due Date',style: GoogleFonts.poppins(fontSize: 25),),
                    Text('${controller.repeatUntil}',style: GoogleFonts.poppins(fontSize: 25),)
                  ],
                ),*/
                  /*Container(
                    height: 150*ffem,
                    child: CupertinoDatePicker(
                      minimumDate: DateTime.now(),
                      maximumYear: DateTime.now().year + 1,
                      initialDateTime: controller.repeatUntil,
                      mode: CupertinoDatePickerMode.date,
                      onDateTimeChanged: (DateTime newDate) {
                        controller.repeatUntil = newDate;
                        controller.update();
                      },
                    ),
                  ),*/
                  SizedBox(height: 20),
                  SizedBox(
                    height: 50 * ffem,
                    child: TextFormField(
                      readOnly: true, // Prevents manual text input
                      onTap: () => selectRepeatDate(context),
                      controller: repeatDateController,
                      decoration: InputDecoration(
                        labelText: 'Date',
                        suffixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Palette.lightGrey,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 10 * ffem,
                          horizontal: 15,
                        ),
                        labelStyle: GoogleFonts.poppins(fontSize: 15 * ffem),
                      ),
                      style: GoogleFonts.poppins(fontSize: 15 * ffem),
                    ),
                  ),
                  SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      saveBtn,
                      ElevatedButton(
                        onPressed: () {
                          Get.back();
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            Palette.dangerBg,
                          ),
                          padding: WidgetStatePropertyAll(
                            EdgeInsets.symmetric(
                              vertical: 10 * ffem,
                              horizontal: 40 * ffem,
                            ),
                          ),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                              side: BorderSide(
                                color: Palette.dangerTxt,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        child: Text(
                          'Discard',
                          style: GoogleFonts.poppins(
                            fontSize: 15 * ffem,
                            color: Palette.dangerTxt,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future buildConfirmPopup(NewBookingController controller) {
    Widget confirmationBtn = Obx(
      () =>
          controller.confirmBtn.value == false
              ? ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all<Color>(
                    Palette.primaryColor,
                  ),
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50.0),
                      side: const BorderSide(color: Palette.primaryColor),
                    ),
                  ),
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(
                      vertical: 15 * ffem,
                      horizontal: 20 * ffem,
                    ),
                  ),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      controller.confirmBtn.value = true;
                    });
                    if (controller.userData.value.id != null) {
                      //Check booking edit selected
                      if (widget.selectedBSlots!.length <= 0) {
                        // Create Booking
                        controller.processCheckout(
                          name: controller.nameController.text,
                          email: controller.userData.value.email,
                          mobile: controller.userData.value.mobile,
                          paymentType: 'Cash',
                          promoCode: '',
                          notes: '',
                        );
                      } else {
                        //Update Booking
                        if (widget.selectedBSlots!.length > 0) {
                          controller.updateBookingSlots(
                            name: controller.nameController.text,
                          );
                        }
                      }
                    } else {
                      //Create user and store the booking
                      controller
                          .registerUser(
                            mobile: controller.mobileNumberController.text,
                            firstName: controller.nameController.text,
                          )
                          .then((value) {
                            //Create Booking
                            controller.processCheckout(
                              name: controller.nameController.text,
                              email: controller.userData.value.email,
                              mobile: controller.userData.value.mobile,
                              paymentType: 'Cash',
                              promoCode: '',
                              notes: '',
                            );
                          });
                    }
                  }
                },
                child: Text(
                  'Confirm',
                  style: GoogleFonts.poppins(fontSize: 20),
                ),
              )
              : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: Colors.grey,
                ),
                height: 60,
                width: 300,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30 * ffem),
                    child: Row(
                      children: [
                        Text(
                          'Booking in Progress..  ',
                          style: GoogleFonts.poppins(
                            fontSize: 15 * ffem,
                            color: Palette.white,
                          ),
                        ),
                        SizedBox(
                          height: 20 * ffem,
                          width: 20 * ffem,
                          child: CircularProgressIndicator(
                            color: Palette.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );

    List<BookingSlot> cartItems = [];
    for (BookingSlot item in controller.cartItems) {
      cartItems.add(
        BookingSlot(
          userId: item.userId,
          name: item.name,
          mobile: item.mobile,
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
          repeatGroupId: item.repeatGroupId,
        ),
      );
    }

    List<BookingSlot> mergedSlots = controller.mergeTimeSlots(cartItems);
    mergedSlots.removeWhere(
      (bookingSlot) => (bookingSlot.slotType == 'Repeat-Item'),
    );

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            children: [
              SizedBox(height: 40),
              Text(
                'Confirm Booking?',
                style: GoogleFonts.poppins(fontSize: 18 * ffem),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              SizedBox(
                width: MediaQuery.of(context).size.width / 2,
                child: Column(
                  children: [
                    Table(
                      children: [
                        TableRow(
                          children: [
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.all(
                                  10 * ffem,
                                ), // Adjust padding as needed
                                child: Text(
                                  'Name',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15 * ffem,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.all(
                                  10 * ffem,
                                ), // Adjust padding as needed
                                child: Text(
                                  controller.nameController.text,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15 * ffem,
                                  ),
                                ),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.all(
                                  10 * ffem,
                                ), // Adjust padding as needed
                                child: Text(
                                  'Mobile',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15 * ffem,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.all(
                                  10 * ffem,
                                ), // Adjust padding as needed
                                child: Text(
                                  controller.mobileNumberController.text,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15 * ffem,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      border: TableBorder.all(
                        color: Palette.mediumGrey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              Expanded(
                child: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: mergedSlots.length,
                    itemBuilder: (context, index) {
                      BookingSlot cartItem = mergedSlots[index];

                      String fmtdStartTime =
                          cartItem.startTime != null
                              ? DateFormat(
                                'hh:mm a',
                              ).format(cartItem.startTime!)
                              : '';
                      String fmtdEndTime =
                          cartItem.endTime != null
                              ? DateFormat('hh:mm a').format(cartItem.endTime!)
                              : '';

                      var finalPrice =
                          (cartItem.slotType == 'Repeated')
                              ? controller.calculateRepeatPrice(
                                repeatGroupId: cartItem.repeatGroupId,
                              )
                              : cartItem.price;

                      return Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(vertical: 5),
                        padding: EdgeInsets.symmetric(
                          vertical: 7,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Palette.fieldBg,
                          borderRadius: BorderRadius.circular(15 * ffem),
                          border: Border.all(
                            color: Palette.lightGrey,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton(
                                      onPressed: null,
                                      style: ButtonStyle(
                                        backgroundColor: WidgetStatePropertyAll(
                                          Colors.deepPurpleAccent,
                                        ),
                                        shape: WidgetStatePropertyAll(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              15 * ffem,
                                            ),
                                          ),
                                        ),
                                        padding: WidgetStatePropertyAll(
                                          EdgeInsets.symmetric(
                                            horizontal: 15 * ffem,
                                            vertical: 10 * ffem,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        '${cartItem.court}',
                                        style: GoogleFonts.poppins(
                                          color: Palette.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15 * ffem,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 50),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat(
                                            'dd/MM/yyy EE',
                                          ).format(cartItem.date!),
                                          style: GoogleFonts.poppins(
                                            color: Palette.primaryColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15 * ffem,
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          '${fmtdStartTime} - ${fmtdEndTime}',
                                          style: GoogleFonts.poppins(
                                            color: Palette.primaryColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15 * ffem,
                                          ),
                                        ),
                                      ],
                                    ),
                                    //Text('${DateFormat('dd/MM/yyy EEEE').format(cartItem.date!)}\n${fmtdStartTime} - ${fmtdEndTime}',style: GoogleFonts.poppins(color: Palette.primaryColor,fontWeight:FontWeight.w600,fontSize: 25),),
                                    //SizedBox(width: 50,),
                                    //Text('${fmtdStartTime} - ${fmtdEndTime}',style: GoogleFonts.poppins(color: Palette.primaryColor,fontWeight:FontWeight.w600,fontSize: 25),),
                                    SizedBox(width: 50),
                                    (cartItem.slotType == 'Repeated')
                                        ? Row(
                                          children: [
                                            Text(
                                              controller.repeatDays(
                                                repeatDays: cartItem.repeatDays,
                                              ),
                                              style: GoogleFonts.poppins(
                                                color: Palette.primaryColor,
                                                fontSize: 15 * ffem,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(width: 50),
                                            Text(
                                              DateFormat(
                                                'dd-MM-yyy',
                                              ).format(cartItem.repeatEnd!),
                                              style: GoogleFonts.poppins(
                                                color: Palette.primaryColor,
                                                fontSize: 15 * ffem,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        )
                                        : Row(
                                          children: [
                                            Text(
                                              ' - ',
                                              style: GoogleFonts.poppins(
                                                color: Palette.primaryColor,
                                                fontSize: 15 * ffem,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(width: 50),
                                            Text(
                                              ' - ',
                                              style: GoogleFonts.poppins(
                                                color: Palette.primaryColor,
                                                fontSize: 15 * ffem,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  NumberFormat.currency(
                                    locale: 'en_US',
                                    symbol: '\$',
                                  ).format(finalPrice),
                                  style: GoogleFonts.poppins(
                                    color: Palette.primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15 * ffem,
                                  ),
                                ),
                                /*SizedBox(width: 30,),
                                ElevatedButton(
                                  onPressed: () {

                                    controller.selectedDays.clear();
                                    controller.repeatUntil = null;

                                    if(cartItem.slotType=='Repeated') {
                                      String cleanString    = cartItem.repeatDays!.replaceAll(RegExp(r'[{}\s]'), '');
                                      List<String> daysList = cleanString.split(',');
                                      for(var rday in daysList) {
                                        controller.selectedDays.add(rday);
                                      }
                                      controller.repeatUntil = cartItem.repeatEnd;
                                    }

                                    buildRepeatDialog(controller,cartItem.startTime,cartItem.endTime,cartItem.serviceId,cartItem.courtId,cartItem.date,cartItem.repeatGroupId);

                                  },
                                  child: Row(
                                    children: [
                                      Icon(cartItem.slotType=='Repeated' ? Icons.edit_calendar_outlined : Icons.refresh,size: 20*ffem,color: Palette.primaryColor,),
                                      Text(cartItem.slotType=='Repeated' ? ' Modify' : ' Repeat Booking',style: GoogleFonts.poppins(color: Palette.primaryColor,fontSize: 15*ffem),)
                                    ],
                                  ),
                                  style: ButtonStyle(
                                      backgroundColor: WidgetStatePropertyAll(Palette.white),
                                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(35)
                                      )),
                                      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 15*ffem,vertical: 10*ffem))
                                  ),
                                ),
                                SizedBox(width: 50,),
                                ElevatedButton(
                                  onPressed: () {
                                    controller.deleteSlot(
                                      dateToRemove: cartItem.date,
                                      serviceIdToRemove: cartItem.serviceId,
                                      courtIdToRemove: cartItem.courtId,
                                      startTimeToRemove: cartItem.startTime,
                                      endTimeToRemove: cartItem.endTime,
                                      slotTypeToRemove: cartItem.slotType,
                                      repeatGroupIdToRemove: cartItem.repeatGroupId,
                                    );
                                  },
                                  child: Icon(Icons.delete,size: 20*ffem,color: Palette.dangerTxt,),
                                  style: ButtonStyle(
                                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(60)
                                    )),
                                    backgroundColor: WidgetStatePropertyAll(Palette.dangerBg),
                                    padding: WidgetStatePropertyAll(EdgeInsets.all(10*ffem)),
                                  ),
                                )*/
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                        Palette.white,
                      ),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50.0),
                          side: const BorderSide(color: Palette.black),
                        ),
                      ),
                      padding: WidgetStatePropertyAll(
                        EdgeInsets.symmetric(
                          vertical: 15 * ffem,
                          horizontal: 20 * ffem,
                        ),
                      ),
                    ),
                    onPressed: () => Get.back(),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        color: Palette.mediumGrey,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  confirmationBtn,
                ],
              ),
            ],
          ),
        );
      },
    );

    /*return Get.dialog(
        AlertDialog(
          contentPadding: EdgeInsets.symmetric(vertical: 70,horizontal: 20),
          content: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20*ffem),
              child: Column(
                children: [

                  ListView.builder(
                    itemCount: mergedSlots.length,
                    itemBuilder: (context, index) {

                      BookingSlot cartItem = mergedSlots[index];

                      String fmtdStartTime = cartItem.startTime != null ? DateFormat('hh:mm a').format(cartItem.startTime!) : '';
                      String fmtdEndTime   = cartItem.endTime != null ? DateFormat('hh:mm a').format(cartItem.endTime!) : '';

                      var finalPrice = (cartItem.slotType=='Repeated') ? controller.calculateRepeatPrice(repeatGroupId: cartItem.repeatGroupId) : cartItem.price ;

                      return Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(vertical: 5),
                        padding: EdgeInsets.symmetric(vertical: 7,horizontal: 10),
                        decoration: BoxDecoration(
                            color: Palette.fieldBg,
                            borderRadius: BorderRadius.circular(15*ffem),
                            border: Border.all(color: Palette.lightGrey,width: 1)
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton(
                                      onPressed: null,
                                      child: Text('${cartItem.court}',style: GoogleFonts.poppins(color: Palette.white,fontWeight:FontWeight.w600,fontSize: 15*ffem),),
                                      style: ButtonStyle(
                                          backgroundColor: WidgetStatePropertyAll(Colors.deepPurpleAccent),
                                          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(15*ffem)
                                          )),
                                          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 15*ffem,vertical: 10*ffem))
                                      ),
                                    ),
                                    SizedBox(width: 50,),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${DateFormat('dd/MM/yyy EE').format(cartItem.date!)}',style: GoogleFonts.poppins(color: Palette.primaryColor,fontWeight:FontWeight.w600,fontSize: 15*ffem),),
                                        SizedBox(height: 10,),
                                        Text('${fmtdStartTime} - ${fmtdEndTime}',style: GoogleFonts.poppins(color: Palette.primaryColor,fontWeight:FontWeight.w600,fontSize: 15*ffem),),
                                      ],
                                    ),
                                    //Text('${DateFormat('dd/MM/yyy EEEE').format(cartItem.date!)}\n${fmtdStartTime} - ${fmtdEndTime}',style: GoogleFonts.poppins(color: Palette.primaryColor,fontWeight:FontWeight.w600,fontSize: 25),),
                                    //SizedBox(width: 50,),
                                    //Text('${fmtdStartTime} - ${fmtdEndTime}',style: GoogleFonts.poppins(color: Palette.primaryColor,fontWeight:FontWeight.w600,fontSize: 25),),
                                    SizedBox(width: 50,),
                                    (cartItem.slotType=='Repeated') ?
                                    Row(
                                      children: [
                                        Text('${controller.repeatDays(repeatDays: cartItem.repeatDays)}',style: GoogleFonts.poppins(color: Palette.primaryColor,fontSize: 15*ffem,fontWeight:FontWeight.w600,),),
                                        SizedBox(width: 50,),
                                        Text('${DateFormat('dd-MM-yyy').format(cartItem.repeatEnd!)}',style: GoogleFonts.poppins(color: Palette.primaryColor,fontSize: 15*ffem,fontWeight:FontWeight.w600,),),
                                      ],
                                    )
                                        :
                                    Row(
                                      children: [
                                        Text(' - ',style: GoogleFonts.poppins(color: Palette.primaryColor,fontSize: 15*ffem,fontWeight:FontWeight.w600,),),
                                        SizedBox(width: 50,),
                                        Text(' - ',style: GoogleFonts.poppins(color: Palette.primaryColor,fontSize: 15*ffem,fontWeight:FontWeight.w600,),),
                                      ],
                                    ),

                                  ],
                                ),

                              ],
                            ),
                            Row(
                              children: [
                                Text(NumberFormat.currency(locale: 'en_US', symbol: '\$').format(finalPrice),style: GoogleFonts.poppins(color: Palette.primaryColor,fontWeight:FontWeight.w600,fontSize: 15*ffem),),
                                SizedBox(width: 30,),
                                ElevatedButton(
                                  onPressed: () {

                                    controller.selectedDays.clear();
                                    controller.repeatUntil = null;

                                    if(cartItem.slotType=='Repeated') {
                                      String cleanString    = cartItem.repeatDays!.replaceAll(RegExp(r'[{}\s]'), '');
                                      List<String> daysList = cleanString.split(',');
                                      for(var rday in daysList) {
                                        controller.selectedDays.add(rday);
                                      }
                                      controller.repeatUntil = cartItem.repeatEnd;
                                    }

                                    buildRepeatDialog(controller,cartItem.startTime,cartItem.endTime,cartItem.serviceId,cartItem.courtId,cartItem.date,cartItem.repeatGroupId);

                                  },
                                  child: Row(
                                    children: [
                                      Icon(cartItem.slotType=='Repeated' ? Icons.edit_calendar_outlined : Icons.refresh,size: 20*ffem,color: Palette.primaryColor,),
                                      Text(cartItem.slotType=='Repeated' ? ' Modify' : ' Repeat Booking',style: GoogleFonts.poppins(color: Palette.primaryColor,fontSize: 15*ffem),)
                                    ],
                                  ),
                                  style: ButtonStyle(
                                      backgroundColor: WidgetStatePropertyAll(Palette.white),
                                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(35)
                                      )),
                                      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 15*ffem,vertical: 10*ffem))
                                  ),
                                ),
                                SizedBox(width: 50,),
                                ElevatedButton(
                                  onPressed: () {
                                    controller.deleteSlot(
                                      dateToRemove: cartItem.date,
                                      serviceIdToRemove: cartItem.serviceId,
                                      courtIdToRemove: cartItem.courtId,
                                      startTimeToRemove: cartItem.startTime,
                                      endTimeToRemove: cartItem.endTime,
                                      slotTypeToRemove: cartItem.slotType,
                                      repeatGroupIdToRemove: cartItem.repeatGroupId,
                                    );
                                  },
                                  child: Icon(Icons.delete,size: 20*ffem,color: Palette.dangerTxt,),
                                  style: ButtonStyle(
                                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(60)
                                    )),
                                    backgroundColor: WidgetStatePropertyAll(Palette.dangerBg),
                                    padding: WidgetStatePropertyAll(EdgeInsets.all(10*ffem)),
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),

                  Text('Are you sure confirm the Booking?',style: GoogleFonts.poppins(fontSize: 15*ffem),textAlign: TextAlign.center),
                  SizedBox(height: 50,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(Palette.white),
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50.0),
                                    side: const BorderSide(color: Palette.black
                                    )
                                )
                            ),
                            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 15*ffem,horizontal: 20*ffem))
                        ),
                        onPressed: () => Get.back(),
                        child: const Text(
                          'Cancel',
                          style: GoogleFonts.poppins(color: Palette.mediumGrey,fontSize: 20),
                        ),
                      ),
                      _confirmationBtn,
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
    );*/
  }

  Future validationDialog(NewBookingController controller) {
    return Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Container(
          padding: EdgeInsets.all(10),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 80 * ffem),
                SizedBox(height: 20),
                Text(
                  'Mobile number Name and Required!',
                  style: GoogleFonts.poppins(
                    fontSize: 15 * ffem,
                    color: Palette.darkGrey,
                  ),
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () => Get.back(),
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Palette.lightGrey),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10 * ffem),
                      ),
                    ),
                    padding: WidgetStatePropertyAll(
                      EdgeInsets.symmetric(
                        vertical: 10 * ffem,
                        horizontal: 30 * ffem,
                      ),
                    ),
                  ),
                  child: Text(
                    'Ok',
                    style: GoogleFonts.poppins(fontSize: 18 * ffem),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future courtChangeDialog(
    NewBookingController controller,
    String? selectedBookingId,
  ) {
    final Iterable<BookingSlot> selectedSlots = controller.bookedSlots.where(
      (item) => item.subBookingId == selectedBookingId,
    );
    final TextEditingController courtController = TextEditingController();
    courtController.text = selectedSlots.first.courtId!;

    List<BookingSlot> cartItems = [];
    for (var item in selectedSlots) {
      cartItems.add(
        BookingSlot(
          userId: item.userId,
          name: item.name,
          mobile: item.mobile,
          date: item.date,
          price: item.price,
          service: item.serviceId,
          serviceId: item.serviceId,
          court: item.courtId,
          courtId: item.courtId,
          startTime: item.startTime,
          endTime: item.endTime,
          slotType: item.slotType,
          repeatDays: item.repeatDays,
          repeatEnd: item.repeatEnd,
          repeatGroupId: item.repeatGroupId,
        ),
      );
    }
    List<BookingSlot> mergedSlots = controller.mergeTimeSlots(cartItems);

    Widget updateCourtBtn = Obx(
      () =>
          controller.courtChangeBtn.value == false
              ? ElevatedButton(
                onPressed: () {
                  setState(() {
                    controller.courtChangeBtn.value = true;
                  });
                  controller.changeCourt(
                    subBookingId: selectedBookingId,
                    courtId: courtController.text,
                  );
                },
                style: ButtonStyle(
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10 * ffem),
                    ),
                  ),
                  backgroundColor: WidgetStatePropertyAll(Palette.primaryColor),
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(
                      vertical: 10 * ffem,
                      horizontal: 30 * ffem,
                    ),
                  ),
                ),
                child: Text(
                  'Update',
                  style: GoogleFonts.poppins(fontSize: 15 * ffem),
                ),
              )
              : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10 * ffem),
                  color: Colors.grey,
                ),
                height: 45,
                width: 130,
                child: Center(
                  child: SizedBox(
                    height: 20 * ffem,
                    width: 20 * ffem,
                    child: CircularProgressIndicator(
                      color: Palette.primaryColor,
                    ),
                  ),
                ),
              ),
    );

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: Container(
                padding: EdgeInsets.all(10),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width / 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          //color: Palette.fieldBg
                        ),
                        child: Column(
                          children: [
                            Table(
                              children: [
                                TableRow(
                                  children: [
                                    TableCell(
                                      child: Padding(
                                        padding: EdgeInsets.all(
                                          10 * ffem,
                                        ), // Adjust padding as needed
                                        child: Row(
                                          children: [
                                            Icon(Icons.person, size: 20 * ffem),
                                            Text(
                                              '  Customer',
                                              style: GoogleFonts.poppins(
                                                fontSize: 15 * ffem,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      child: Padding(
                                        padding: EdgeInsets.all(
                                          10 * ffem,
                                        ), // Adjust padding as needed
                                        child: Text(
                                          '${mergedSlots.first.name}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 15 * ffem,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                TableRow(
                                  children: [
                                    TableCell(
                                      child: Padding(
                                        padding: EdgeInsets.all(
                                          10 * ffem,
                                        ), // Adjust padding as needed
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.phone_android,
                                              size: 20 * ffem,
                                            ),
                                            Text(
                                              '  Mobile',
                                              style: GoogleFonts.poppins(
                                                fontSize: 15 * ffem,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      child: Padding(
                                        padding: EdgeInsets.all(
                                          10 * ffem,
                                        ), // Adjust padding as needed
                                        child: Text(
                                          '${mergedSlots.first.mobile}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 15 * ffem,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                TableRow(
                                  children: [
                                    TableCell(
                                      child: Padding(
                                        padding: EdgeInsets.all(
                                          10 * ffem,
                                        ), // Adjust padding as needed
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.watch_later,
                                              size: 20 * ffem,
                                            ),
                                            Text(
                                              '  Time',
                                              style: GoogleFonts.poppins(
                                                fontSize: 15 * ffem,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      child: Padding(
                                        padding: EdgeInsets.all(
                                          10 * ffem,
                                        ), // Adjust padding as needed
                                        child: Text(
                                          '${DateFormat('hh:mm').format(mergedSlots.first.startTime!)} - ${DateFormat('hh:mm a').format(mergedSlots.first.endTime!)}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 15 * ffem,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                TableRow(
                                  children: [
                                    TableCell(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 20 * ffem,
                                          horizontal: 10 * ffem,
                                        ), // Adjust padding as needed
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.account_balance,
                                              size: 20 * ffem,
                                            ),
                                            Text(
                                              '  Court',
                                              style: GoogleFonts.poppins(
                                                fontSize: 15 * ffem,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      child: Padding(
                                        padding: EdgeInsets.all(
                                          10 * ffem,
                                        ), // Adjust padding as needed
                                        child: DropdownButtonFormField<String>(
                                          value: selectedSlots.first.courtId,
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Palette.lightGrey,
                                                width: 2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 10 * ffem,
                                                  horizontal: 15,
                                                ),
                                          ),
                                          items:
                                              controller.courtList.map((item) {
                                                return DropdownMenuItem<String>(
                                                  value: item['id'],
                                                  child: Text(
                                                    '${item['name']}',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 15 * ffem,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                          onChanged: (value) {
                                            courtController.text = value!;
                                          },
                                          onSaved: (value) {},
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              defaultColumnWidth: IntrinsicColumnWidth(flex: 2),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Get.back();
                            },
                            style: ButtonStyle(
                              shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    10 * ffem,
                                  ),
                                ),
                              ),
                              backgroundColor: WidgetStatePropertyAll(
                                Palette.mediumGrey,
                              ),
                              padding: WidgetStatePropertyAll(
                                EdgeInsets.symmetric(
                                  vertical: 10 * ffem,
                                  horizontal: 30 * ffem,
                                ),
                              ),
                            ),
                            child: Text(
                              'Close',
                              style: GoogleFonts.poppins(fontSize: 15 * ffem),
                            ),
                          ),
                          updateCourtBtn,
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
