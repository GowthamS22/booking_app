import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/constants.dart';
import '../../controllers/booking_controller.dart';
import '../../config/palette.dart';
import '../../controllers/new_booking_controller.dart';
import '../../models/booking_model.dart';
import '../../widgets/shimmer/shimmer_table_loading.dart';
import '../booking/new_booking_screen.dart';
import '../checkout/checkout_screen.dart';

class ServiceScreen extends StatefulWidget {
  final serviceId;
  final serviceName;
  const ServiceScreen({required this.serviceId, required this.serviceName, Key? key}) : super(key: key);

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> with TickerProviderStateMixin  {

  TextEditingController bookingSearchController = TextEditingController();
  late TabController _tabController;
  late Stream<QuerySnapshot> _bookingSlotStream;

  @override
  void initState() {
    super.initState();
    /*_bookingSlotStream = FirebaseFirestore.instance
        .collection(authController.centerSlug.toString())
        .doc('bookingSlots')
        .collection('bookingSlot')
        .where('serviceId',isEqualTo: widget.serviceId.toString())
        .where('status',isEqualTo: 'Booked')
        .orderBy('startTime',descending: false)
        .snapshots();*/
    _tabController = TabController(vsync: this, length: 1); // Number of tabs
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: BookingController(widget.serviceId,widget.serviceName),
      builder: (controller) {
        controller.selectedService.value = widget.serviceId;
        return Scaffold(
          backgroundColor: Palette.white,
          body: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                buildBody(controller),
              ],
            ),
          ),
        );
      },
    );
  }

  buildBody(BookingController controller) {
    return Expanded(
      child: ListView(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width / 2,
                    child: TabBar(
                      controller: _tabController,
                      tabs: [
                        Tab(height:40*ffem, child: Text('${widget.serviceName} All Bookings',style: TextStyle(fontSize:15*ffem, color: Palette.primaryColor),),),
                      ],
                    ),
                  ),
                  SizedBox(width: 100,),
                  Expanded(
                    child: Container(
                      color: Palette.fieldBg,
                      height: 40*ffem,
                      child: Padding(
                        padding: EdgeInsets.all(0*ffem),
                        child: TextField(
                          controller: bookingSearchController,
                          onChanged: (value) {
                            controller.searchBookingSlots(value);
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(10*ffem),
                            isDense: true,
                            hintText: "Search",
                            hintStyle: TextStyle(fontSize: 15*ffem),
                            suffixIcon: Icon(Icons.search_outlined, color: Palette.mediumGrey,size: 40,),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
              SizedBox(height: 20,),
              Container(
                height: MediaQuery.of(context).size.height / 1.4,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    Container(
                    ),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }


}
