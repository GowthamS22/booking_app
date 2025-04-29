import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app/getx_binding.dart';
import '../../config/constants.dart';
import '../../config/palette.dart';
import '../../screens/screens.dart';
import '../../widgets/shimmer/shimmer_table_loading.dart';
import '../../models/booking_model.dart';
import '../../controllers/default_controller.dart';
import '../../controllers/new_booking_controller.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {


  final ScrollController _scrollController         = ScrollController();
  final DefaultController defaultController        = Get.put(DefaultController());
  TextEditingController upcomingSearchController   = TextEditingController();
  TextEditingController allBookingSearchController = TextEditingController();

  late TabController _tabController;

  late Stream<QuerySnapshot> _bookingSlotStream;
  late Stream<QuerySnapshot> _finishedUpaidbookingSlotStream;
  late Stream<QuerySnapshot> _bookingStream;

  @override
  void initState() {
    super.initState();

    DateTime now = DateTime.now();
    DateTime thirtyMinutesFromNow = now.add(Duration(minutes: 30));

    _bookingSlotStream = FirebaseFirestore.instance
        .collection(authController.centerSlug.toString())
        .doc('bookingSlots')
        .collection('bookingSlot')
        .where('date',isEqualTo: DateTime(DateTime.now().year,DateTime.now().month,DateTime.now().day))
        .where('status',isEqualTo: 'Booked')
        .snapshots();

    _finishedUpaidbookingSlotStream = FirebaseFirestore.instance
        .collection(authController.centerSlug.toString())
        .doc('bookingSlots')
        .collection('bookingSlot')
        .where('date',isEqualTo: DateTime(DateTime.now().year,DateTime.now().month,DateTime.now().day))
        .where('status',isEqualTo: 'Booked')
        .where('paymentStatus',isEqualTo: 'Pending')
        .snapshots();

    _bookingStream = FirebaseFirestore.instance
        .collection(authController.centerSlug.toString())
        .doc('bookings')
        .collection('booking')
        .orderBy('createdAt',descending: true)
        .snapshots();

    _tabController = TabController(vsync: this, length: 3);
    _scrollController.addListener(_scrollListener);// Number of tabs
    shoppingController.initialized;
    settingController.initialized;
    // defaultController.printReceipt();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      defaultController.loadMoreBookingData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<String> selectedIds = [];

  void toggleSelected(String id) {
    setState(() {
      if (selectedIds.contains(id)) {
        selectedIds.remove(id);
      } else {
        selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    TextEditingController searchController = TextEditingController();

    return GetBuilder(
      init: DefaultController(),
      builder: (controller) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20,vertical: 10),
          child: Column(
            children: [
              SizedBox(height: 0,),
              buildBody(controller, searchController),
            ],
          ),
        );
      },
    );
  }

  buildBody(DefaultController controller, TextEditingController searchController) {
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
                      onTap: (value) {
                        upcomingSearchController.text = '';
                      },
                      tabs: [
                        Tab(height:40*ffem, child: Text('Upcoming Booking',style: TextStyle(fontSize:15*ffem, color: Palette.primaryColor),)),
                        Tab(height:40*ffem, child: Text('Finished & Unpaid',style: TextStyle(fontSize:15*ffem, color: Palette.primaryColor),)),
                        Tab(height:40*ffem, child: Text('All Bookings',style: TextStyle(fontSize:15*ffem, color: Palette.primaryColor),),),
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
                          controller: upcomingSearchController,
                          onChanged: (value) {
                            controller.searchBookingSlots(value,_tabController.index);
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(10*ffem),
                            //isDense: true,
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
                      child: SingleChildScrollView(
                        child: buildUpcomingBookingSlotListTable(controller,searchController),
                      ),
                    ),
                    Container(
                      child: SingleChildScrollView(
                        child: buildFinishedUnpaidBookingSlotListTable(controller),
                      ),
                    ),
                    Container(
                      child: SingleChildScrollView(
                        child: buildAllBookingSlotListTable(controller),
                      ),
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




//Not Used
  buildBookingListTable(DefaultController controller, searchController) {


    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10)
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: _bookingStream,
            builder: (context, snapshot) {

              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting || snapshot.data == null) {
                return ShimmerTableLoading(columnCount: 4,rowCount: 4,);
              }

              // Process the documents in the snapshot and create a list of User objects
              defaultController.bookingList = snapshot.data!.docs.map((doc) {
                Map<String, dynamic> bookingData = doc.data() as Map<String, dynamic>;
                List<BookingSlot> bookingSlots = [];
                return Booking(
                    doc.id.toString(),
                    bookingData['userId'],
                    bookingData['name'],
                    bookingData['mobile'],
                    bookingData['email'],
                    bookingData['notes'],
                    bookingData['subTotal'].toDouble(),
                    bookingData['discount'].toDouble(),
                    bookingData['gst'].toDouble(),
                    bookingData['total'].toDouble(),
                    bookingData['paymentType'],
                    bookingData['paymentStatus'],
                    bookingData['status'],
                    bookingSlots,
                    bookingData['createdBy'],
                    bookingData['updatedBy'],
                    bookingData['createdAt'].toDate(),
                    bookingData['updatedAt'].toDate()
                );

              }).toList();

              var _showList = allBookingSearchController.text.isNotEmpty ? defaultController.filteredBookingList : defaultController.bookingList;

              return (defaultController.bookingList.length > 0) ?
              Container(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    border: TableBorder.symmetric(
                      outside: BorderSide(
                        color: Palette.mediumGrey,
                        width: 2,
                      ),
                    ),
                    sortAscending: defaultController.BookingSortAscending,
                    sortColumnIndex: defaultController.BookingSortColumnIndex,
                    headingRowHeight: 60,
                    dataRowMaxHeight: double.infinity,
                    horizontalMargin: 10,
                    dataRowMinHeight: 60,
                    headingRowColor: MaterialStatePropertyAll(Palette.rowHeadingbg),
                    dataRowColor: MaterialStatePropertyAll(Palette.rowDatabg),
                    columns: [
                      DataColumn(
                        onSort: controller.onSortBookingColumn,
                        label: Center(
                          child: Text(
                            'Booking ID',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Palette.primaryColor,
                              fontSize: 15*ffem,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        onSort: controller.onSortBookingColumn,
                        label: Center(
                          child: Text(
                            'Customer',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Palette.primaryColor,
                              fontSize: 15*ffem,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        onSort: controller.onSortBookingColumn,
                        label: Center(
                          child: Text(
                            'Booked On',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Palette.primaryColor,
                              fontSize: 15*ffem,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        onSort: controller.onSortBookingColumn,
                        label: Center(
                          child: Text(
                            'Action',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Palette.primaryColor,
                              fontSize: 15*ffem,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        onSort: controller.onSortBookingColumn,
                        label: Center(
                          child: Text(
                            'Status',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Palette.primaryColor,
                              fontSize: 15*ffem,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        onSort: controller.onSortBookingColumn,
                        label: Center(
                          child: Text(
                            'Payment Status',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Palette.primaryColor,
                              fontSize: 15*ffem,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                    rows: _showList.map((booking) => DataRow(
                      cells: [
                        DataCell(
                          Text('${booking.id}',style: TextStyle(fontSize: 15*ffem),),
                        ),
                        DataCell(
                          Text('${booking.name}',style: TextStyle(fontSize: 15*ffem),),
                        ),
                        DataCell(
                            Text('${DateFormat('dd-MMM-yy').format(DateTime(booking.createdAt!.year,booking.createdAt!.month,booking.createdAt!.day))}',style: TextStyle(fontSize: 15*ffem),)
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  controller.isLoading.value = true;
                                  controller.getBookingDetails(booking.id);
                                  controller.calculatePayments(bookingId: booking.id);
                                  buildViewDialog(controller);
                                },
                                icon: const Icon(Icons.remove_red_eye, color: Colors.blue,size: 30,),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                            Container(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: null,
                                child: Text('${booking.status}',style: TextStyle(color: Palette.white,fontSize: 15*ffem),),
                                style: ButtonStyle(
                                    backgroundColor: MaterialStatePropertyAll(booking.status == 'Booked' ? Colors.green : booking.status == 'Pending' ? Colors.orange : Colors.red),
                                    shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15)
                                    )),
                                    padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 5*ffem,horizontal: 10*ffem))
                                ),
                              ),
                            )
                        ),
                        DataCell(
                            Container(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: null,
                                child: Text('${booking.paymentStatus}',style: TextStyle(color: Palette.white,fontSize: 15*ffem),),
                                style: ButtonStyle(
                                    backgroundColor: MaterialStatePropertyAll(booking.paymentStatus == 'Paid' ? Colors.green : booking.paymentStatus == 'Partially' ? Colors.orange : Colors.red),
                                    shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15)
                                    )),
                                    padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 5*ffem,horizontal: 10*ffem))
                                ),
                              ),
                            )
                        ),
                      ],
                    )).toList(),
                  ),
                ),
              ) :
              Container(width: double.infinity, color: Palette.lightGrey, padding: EdgeInsets.all(20), child: Text('There is no data found',style: TextStyle(fontSize: 25),textAlign: TextAlign.center,),);
            },
          ),
        )
      ],
    );

    var _showList = searchController.text.isEmpty ? controller.bookingList : controller.filteredBookingList ;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10)
      ),
      child: Obx(() => controller.tableLoading == false ?
      _showList.length > 0 ?
      SingleChildScrollView(
        controller: _scrollController,
        child: DataTable(
          border: TableBorder.symmetric(
            outside: BorderSide(
              color: Palette.mediumGrey,
              width: 2,
            ),

          ),
          sortAscending: controller.isAscendingBooking,
          sortColumnIndex: controller.sortColumnBooking,
          headingRowHeight: 60,
          dataRowMaxHeight: double.infinity,
          horizontalMargin: 10,
          dataRowMinHeight: 70,
          headingRowColor: MaterialStatePropertyAll(Palette.rowHeadingbg),
          dataRowColor: MaterialStatePropertyAll(Palette.rowDatabg),
          columns: [
            DataColumn(
              onSort: controller.onSortBookingColumn,
              label: Center(
                child: Text(
                  'Booking ID',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Palette.primaryColor,
                    fontSize: 15*ffem,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            DataColumn(
              onSort: controller.onSortBookingColumn,
              label: Center(
                child: Text(
                  'Customer',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Palette.primaryColor,
                    fontSize: 15*ffem,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            DataColumn(
              onSort: controller.onSortBookingColumn,
              label: Center(
                child: Text(
                  'Game',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Palette.primaryColor,
                    fontSize: 15*ffem,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            DataColumn(
              onSort: controller.onSortBookingColumn,
              label: Center(
                child: Text(
                  'Booked On',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Palette.primaryColor,
                    fontSize: 15*ffem,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            DataColumn(
              onSort: controller.onSortBookingColumn,
              label: Center(
                child: Text(
                  'Action',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Palette.primaryColor,
                    fontSize: 15*ffem,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            DataColumn(
              onSort: controller.onSortBookingColumn,
              label: Center(
                child: Text(
                  'Status',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Palette.primaryColor,
                    fontSize: 15*ffem,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            DataColumn(
              onSort: controller.onSortBookingColumn,
              label: Center(
                child: Text(
                  'Payment Status',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Palette.primaryColor,
                    fontSize: 15*ffem,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          ],
          rows: _showList.map((element) {

            Set<String> uniqueCourt = {};
            element.bookingSlot.forEach((doc) {
              String? courtName = doc.court;
              uniqueCourt.add(courtName!);
            });
            List<String> distinctCourt = uniqueCourt.toList();

            Set<String> uniqueService = {};
            element.bookingSlot.forEach((doc) {
              String? serviceName = doc.service;
              uniqueService.add(serviceName!);
            });
            List<String> distinctService = uniqueService.toList();

            return DataRow(cells: [
              DataCell(
                Text('${element.id}',style: TextStyle(fontSize: 15*ffem),),
              ),
              DataCell(
                Text('${element.name}',style: TextStyle(fontSize: 15*ffem),),
              ),
              DataCell(
                  Column(
                    children: distinctService.map((element) {
                      return Text('${element}',style: TextStyle(fontSize: 15*ffem),);
                    }).toList(),
                  )
              ),
              DataCell(
                  Text('${DateFormat('dd-MMM-yy').format(DateTime(element.createdAt!.year,element.createdAt!.month,element.createdAt!.day))}',style: TextStyle(fontSize: 15*ffem),)
              ),
              /*DataCell(
              Text('${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(element.total)}',style: TextStyle(fontSize: 25),),
            ),*/
              DataCell(
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        controller.isLoading.value = true;
                        controller.getBookingDetails(element.id);
                        controller.calculatePayments(bookingId: element.id);
                        buildViewDialog(controller);
                      },
                      icon: const Icon(Icons.remove_red_eye, color: Colors.blue,size: 30,),
                    ),
                  ],
                ),
              ),
              DataCell(
                  Container(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: null,
                      child: Text('${element.status}',style: TextStyle(color: Palette.white,fontSize: 15*ffem),),
                      style: ButtonStyle(
                          backgroundColor: MaterialStatePropertyAll(element.status == 'Booked' ? Colors.green : element.paymentStatus == 'Pending' ? Colors.orange : Colors.red),
                          shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)
                          )),
                          padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 5*ffem,horizontal: 10*ffem))
                      ),
                    ),
                  )
              ),
              DataCell(
                  Container(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: null,
                      child: Text('${element.paymentStatus}',style: TextStyle(color: Palette.white,fontSize: 15*ffem),),
                      style: ButtonStyle(
                          backgroundColor: MaterialStatePropertyAll(element.paymentStatus == 'Paid' ? Colors.green : element.paymentStatus == 'Partially' ? Colors.orange : Colors.red),
                          shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)
                          )),
                          padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 5*ffem,horizontal: 10*ffem))
                      ),
                    ),
                  )
              ),
            ]);
          },).toList(),
        ),
      )
          :
      Container(width: double.infinity, color: Palette.lightGrey, padding: EdgeInsets.all(20), child: Text('There is no bookings found',style: TextStyle(fontSize: 25),textAlign: TextAlign.center,),)
          :
      ShimmerTableLoading(columnCount: 6,rowCount: 4,)),
    );


  }
//Not Used
  buildDeletePopup(DefaultController controller, Booking element) {

    Widget _deleteBtn = Obx(() => controller.cancelIsLoading.value == false ?
    ElevatedButton(
      style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(Palette.primaryColor),
          shape: MaterialStateProperty.all<
              RoundedRectangleBorder>(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50.0),
              side: const BorderSide(color: Palette.primaryColor)
          )
          ),
          padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 15*ffem,horizontal: 30*ffem))
      ),
      onPressed: () {
        setState(() {
          controller.cancelIsLoading.value = true;
        });
        controller.cancelEntireBooking(element.id);
      },
      child: Text('Cancel',style: TextStyle(fontSize: 15*ffem),),
    )
    :
    Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), color: Colors.grey,),
      height: 55,
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

    return Get.dialog(
        AlertDialog(
          contentPadding: EdgeInsets.symmetric(vertical: 70,horizontal: 20),
          content: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20*ffem),
              child: Column(
                children: [
                  Text('Are you sure to Cancel entire Booking?',style: TextStyle(fontSize: 15*ffem),textAlign: TextAlign.center),
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
                            padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 15*ffem,horizontal: 30*ffem))
                        ),
                        onPressed: () => Get.back(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Palette.mediumGrey,fontSize: 15*ffem),
                        ),
                      ),
                      _deleteBtn,
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
    );

  }
//Not Used
  buildViewDialog(DefaultController controller) {

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Container(
                padding: EdgeInsets.all(20),
                width: MediaQuery.of(context).size.width / 1.2,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Obx(() => controller.isLoading == false ?
                      GetBuilder<DefaultController>(
                        builder: (controller) {

                          final booking  = controller.selectedBooking[0];
                          final payments = controller.bookingPayments;

                          final NewBookingController newBookingController = Get.put(NewBookingController());

                          List<BookingSlot> bookingItems = [];
                          for(BookingSlot item in booking.bookingSlot) {
                            bookingItems.add(item);
                          }
                          List<BookingSlot> mergedSlots = newBookingController.mergeTimeSlots(bookingItems);

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Booking Details',style: TextStyle(color: Palette.primaryColor, fontSize: 15*ffem, fontWeight: FontWeight.bold),),
                                  Row(
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          Get.back();
                                        },
                                        child: Text('Close',style: TextStyle(fontSize: 15*ffem,color: Palette.white),),
                                        style: ButtonStyle(
                                          shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(15)
                                          )),
                                          padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 10*ffem,horizontal: 20)),
                                          backgroundColor: MaterialStatePropertyAll(Palette.primaryColor),
                                        ),
                                      )
                                    ],
                                  )
                                ],
                              ),

                              Divider(height: 20,thickness: 2, color: Palette.mediumGrey),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Palette.fieldBg
                                    ),
                                    width: MediaQuery.of(context).size.width / 3,
                                    child: Column(
                                      children: [
                                        Table(
                                          children: [
                                            TableRow(
                                              children: [
                                                TableCell(
                                                  child: Padding(
                                                    padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                    child: Text('Booking ID',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),),
                                                  ),
                                                ),
                                                TableCell(
                                                  child: Padding(
                                                    padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                    child: Text('${booking.id}',style: TextStyle(fontSize: 15*ffem),),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            TableRow(
                                              children: [
                                                TableCell(
                                                  child: Padding(
                                                    padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                    child: Text('Booking Date',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),),
                                                  ),
                                                ),
                                                TableCell(
                                                  child: Padding(
                                                    padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                    child: Text('${DateFormat('dd-MMM-yyyy').format(DateTime(booking.createdAt!.year,booking.createdAt!.month,booking.createdAt!.day))}',style: TextStyle(fontSize: 15*ffem),),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            /*TableRow(
                                          children: [
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('Status',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),),
                                              ),
                                            ),
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('${booking.status}',style: TextStyle(
                                                  fontSize: 15*ffem,
                                                  color: booking.status == 'Booked' ? Colors.green : booking.status == 'Pending' ? Colors.orange : Colors.red,
                                                  fontWeight: FontWeight.bold
                                                ),),
                                              ),
                                            ),
                                          ],
                                        ),
                                        TableRow(
                                          children: [
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('Payment Type',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),),
                                              ),
                                            ),
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('${booking.paymentType}',style: TextStyle(
                                                  fontSize: 15*ffem,
                                                ),),
                                              ),
                                            ),
                                          ],
                                        ),
                                        TableRow(
                                          children: [
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('Payment Status',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),),
                                              ),
                                            ),
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('${booking.paymentStatus}',style: TextStyle(
                                                  fontSize: 15*ffem,
                                                  color: booking.paymentStatus == 'Paid' ? Colors.green : booking.paymentStatus == 'Partially' ? Colors.orange : Colors.red,
                                                  fontWeight: FontWeight.bold
                                                ),),
                                              ),
                                            ),
                                          ],
                                        ),*/
                                          ],
                                          border: TableBorder.all(color: Palette.mediumGrey,borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: MediaQuery.of(context).size.width / 3,
                                    child: Column(
                                      children: [
                                        Table(
                                          children: [
                                            TableRow(
                                              children: [
                                                TableCell(
                                                  child: Padding(
                                                    padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.person,size: 20*ffem,),
                                                        Text(' Customer',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),)
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                TableCell(
                                                  child: Padding(
                                                    padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                    child: Text('${booking.name}',style: TextStyle(fontSize: 15*ffem),),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            TableRow(
                                              children: [
                                                TableCell(
                                                  child: Padding(
                                                    padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.phone_android,size: 20*ffem,),
                                                        Text(' Mobile',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),)
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                TableCell(
                                                  child: Padding(
                                                    padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                    child: Text('${booking.mobile}',style: TextStyle(fontSize: 15*ffem),),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            /*TableRow(
                                          children: [
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.email,size: 20*ffem,),
                                                    Text(' Email',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),)
                                                  ],
                                                ),
                                              ),
                                            ),
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('${booking.email}',style: TextStyle(fontSize: 15*ffem),),
                                              ),
                                            ),
                                          ],
                                        ),
                                        TableRow(
                                          children: [
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.note,size: 20*ffem,),
                                                    Text(' Notes',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),)
                                                  ],
                                                ),
                                              ),
                                            ),
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('${booking.notes}',style: TextStyle(fontSize: 15*ffem),),
                                              ),
                                            ),
                                          ],
                                        ),
                                        TableRow(
                                          children: [
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.note,size: 20*ffem,),
                                                    Text(' Notes',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),)
                                                  ],
                                                ),
                                              ),
                                            ),
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('${booking.notes}',style: TextStyle(fontSize: 15*ffem),),
                                              ),
                                            ),
                                          ],
                                        ),*/
                                          ],
                                          defaultColumnWidth:IntrinsicColumnWidth(flex: 2),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 30,),
                              Align(
                                child: Text('Booked Court List',style: TextStyle(fontSize: 15*ffem,fontWeight:FontWeight.bold,color: Palette.primaryColor),textAlign: TextAlign.start,),
                                alignment: Alignment.topLeft,
                              ),
                              SizedBox(height: 20,),
                              Container(
                                height: MediaQuery.of(context).size.height / 3,
                                width: double.infinity,
                                child: SingleChildScrollView(
                                  child: DataTable(
                                    headingRowHeight: 40,
                                    dataRowHeight: 40,
                                    headingRowColor: MaterialStatePropertyAll(Palette.rowHeadingbg),
                                    dataRowColor: MaterialStatePropertyAll(Palette.rowDatabg),
                                    columns: [
                                      DataColumn(label: Text('Game',style: TextStyle(fontSize: 15*ffem,color: Palette.primaryColor),)),
                                      DataColumn(label: Text('Court',style: TextStyle(fontSize: 15*ffem,color: Palette.primaryColor),)),
                                      DataColumn(label: Text('Date',style: TextStyle(fontSize: 15*ffem,color: Palette.primaryColor),)),
                                      DataColumn(label: Text('Start Time',style: TextStyle(fontSize: 15*ffem,color: Palette.primaryColor),)),
                                      DataColumn(label: Text('End Time',style: TextStyle(fontSize: 15*ffem,color: Palette.primaryColor),)),
                                      DataColumn(label: Text('Price',style: TextStyle(fontSize: 15*ffem,color: Palette.primaryColor),)),
                                      DataColumn(label: Text('Action',style: TextStyle(fontSize: 15*ffem,color: Palette.primaryColor),)),
                                    ],
                                    rows: mergedSlots.map((e) =>
                                        DataRow(cells: [
                                          DataCell(
                                            Text('${e.service}',style: TextStyle(fontSize: 15*ffem),),
                                          ),
                                          DataCell(
                                            Text('${e.court}',style: TextStyle(fontSize: 15*ffem),),
                                          ),
                                          DataCell(
                                            Text('${DateFormat('dd-MMM-yy E').format(e.startTime!)}',style: TextStyle(fontSize: 15*ffem),),
                                          ),
                                          DataCell(
                                            Text('${DateFormat('hh:mm a').format(e.startTime!)}',style: TextStyle(fontSize: 15*ffem),),
                                          ),
                                          DataCell(
                                            Text('${DateFormat('hh:mm a').format(e.endTime!)}',style: TextStyle(fontSize: 15*ffem),),
                                          ),
                                          DataCell(
                                            Text('${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(e.price)}',style: TextStyle(fontSize: 15*ffem, fontWeight: FontWeight.bold),),
                                          ),
                                          DataCell(
                                            Checkbox(
                                              value: selectedIds.contains(e.subBookingId.toString()),
                                              onChanged: (value) {
                                                toggleSelected(e.subBookingId.toString());
                                              },
                                            ),
                                            /*CheckboxListTile(
                                              value: _isChecked[0],
                                              onChanged: (val) {
                                                setState(() {
                                                  _isChecked[0] = val!;
                                                  canUpload = true;
                                                  for (var item in _isChecked) {
                                                    if (item == false) {
                                                      canUpload = false;
                                                    }
                                                  }
                                                });
                                              },
                                            ),*/
                                          ),
                                        ]),
                                    ).toList(),
                                  ),
                                ),
                              ),

                              Divider(height: 40,color: Palette.darkGrey,thickness: 2),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  (booking.status!='Cancelled') ?
                                  ElevatedButton(
                                    onPressed: () {
                                      Get.to(NewBookingScreen(bookingId: booking.id,));
                                    },
                                    child: Text('Modify Booking',style: TextStyle(fontSize: 15*ffem,color: Palette.white),),
                                    style: ButtonStyle(
                                      shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)
                                      )),
                                      padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 10*ffem,horizontal: 20)),
                                      backgroundColor: MaterialStatePropertyAll(Colors.orange),
                                    ),
                                  )
                                      :
                                  Text(''),
                                  SizedBox(width: 20,),
                                  (booking.status!='Cancelled') ?
                                  ElevatedButton(
                                    onPressed: () {
                                      buildDeletePopup(controller, booking);
                                    },
                                    child: Text('Cancel Booking',style: TextStyle(fontSize: 15*ffem,color: Palette.white),),
                                    style: ButtonStyle(
                                      shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)
                                      )),
                                      padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 10*ffem,horizontal: 20)),
                                      backgroundColor: MaterialStatePropertyAll(Palette.dangerTxt),
                                    ),
                                  )
                                      :
                                  Text(''),
                                  SizedBox(width: 20,),
                                  ElevatedButton(
                                    onPressed: () {

                                    },
                                    child: Row(
                                      children: [
                                        Icon(Icons.paid,size: 20*ffem,),
                                        Text(' Make Payment',style: TextStyle(fontSize: 15*ffem),)
                                      ],
                                    ),
                                    style: ButtonStyle(
                                        padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 10*ffem,horizontal: 20)),
                                        shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10)
                                        )),
                                        backgroundColor: MaterialStatePropertyAll(Palette.payColors)
                                    ),
                                  )
                                ],
                              ),

                              /*SizedBox(height: 30,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Booking Payments',style: TextStyle(fontSize: 15*ffem),),
                                  SizedBox(height: 10,),
                                  Container(
                                    width: MediaQuery.of(context).size.width / 3,
                                    child: Table(
                                      children: [
                                        TableRow(
                                          children: [
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('Sub Total',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold,color: Palette.primaryColor),),
                                              ),
                                            ),
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(booking.subTotal)}',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),textAlign: TextAlign.end,),
                                              ),
                                            ),
                                          ],
                                        ),
                                        TableRow(
                                          children: [
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('Discount',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold,color: Palette.primaryColor),),
                                              ),
                                            ),
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(booking.discount)}',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),textAlign: TextAlign.end,),
                                              ),
                                            ),
                                          ],
                                        ),
                                        TableRow(
                                          children: [
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('GST',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold,color: Palette.primaryColor),),
                                              ),
                                            ),
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(booking.gst)}',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),textAlign: TextAlign.end,),
                                              ),
                                            ),
                                          ],
                                        ),
                                        TableRow(
                                          children: [
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('Total',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold,color: Palette.primaryColor),),
                                              ),
                                            ),
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(booking.total)}',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),textAlign: TextAlign.end,),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      border: TableBorder.all(color: Palette.mediumGrey,borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ],
                              ),

                              Container(
                                decoration: BoxDecoration(
                                    color: Palette.fieldBg,
                                    borderRadius: BorderRadius.circular(10)
                                ),
                                width: MediaQuery.of(context).size.width / 3,
                                child: Table(
                                  children: [
                                    TableRow(
                                      children: [
                                        TableCell(
                                          child: Padding(
                                            padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                            child: Text('Sub Total',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold,color: Palette.primaryColor),),
                                          ),
                                        ),
                                        TableCell(
                                          child: Padding(
                                            padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                            child: Text('${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(booking.subTotal)}',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),textAlign: TextAlign.end,),
                                          ),
                                        ),
                                      ],
                                    ),
                                    TableRow(
                                      children: [
                                        TableCell(
                                          child: Padding(
                                            padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                            child: Text('Discount',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold,color: Palette.primaryColor),),
                                          ),
                                        ),
                                        TableCell(
                                          child: Padding(
                                            padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                            child: Text('${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(booking.discount)}',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),textAlign: TextAlign.end,),
                                          ),
                                        ),
                                      ],
                                    ),
                                    TableRow(
                                      children: [
                                        TableCell(
                                          child: Padding(
                                            padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                            child: Text('GST',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold,color: Palette.primaryColor),),
                                          ),
                                        ),
                                        TableCell(
                                          child: Padding(
                                            padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                            child: Text('${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(booking.gst)}',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),textAlign: TextAlign.end,),
                                          ),
                                        ),
                                      ],
                                    ),
                                    TableRow(
                                      children: [
                                        TableCell(
                                          child: Padding(
                                            padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                            child: Text('Total',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold,color: Palette.primaryColor),),
                                          ),
                                        ),
                                        TableCell(
                                          child: Padding(
                                            padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                            child: Text('${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(booking.total)}',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),textAlign: TextAlign.end,),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  border: TableBorder.all(color: Palette.mediumGrey,borderRadius: BorderRadius.circular(10)),
                                ),
                              ),

                            ],
                          ),*/

                              /*Divider(height: 50,thickness: 2, color: Palette.mediumGrey),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: null,
                                child: Text('Modify Booking',style: TextStyle(fontSize: 15*ffem,color: Palette.white),),
                                style: ButtonStyle(
                                  shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)
                                  )),
                                  padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 10*ffem,horizontal: 20)),
                                  backgroundColor: MaterialStatePropertyAll(Palette.primaryColor),
                                ),
                              ),
                              SizedBox(width: 50,),
                              ElevatedButton(
                                onPressed: null,
                                child: Text('Cancel Booking',style: TextStyle(fontSize: 15*ffem,color: Palette.white),),
                                style: ButtonStyle(
                                    shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15)
                                    )),
                                    padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 10*ffem,horizontal: 20)),
                                    backgroundColor: MaterialStatePropertyAll(Palette.dangerTxt)
                                ),
                              ),
                            ],
                          )*/

                            ],
                          );

                        },
                      )
                          :
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white, // Container color
                            borderRadius: BorderRadius.circular(10), // Optional: Adds rounded corners
                          ),
                          child: Column(
                            children: [

                              SizedBox(
                                width: 70,
                                height: 70,
                                child: CircularProgressIndicator(),
                              ), // Loading spinner
                              SizedBox(height: 50),
                              Text(
                                'Please wait, your booking is loading... It takes some time',
                                style: TextStyle(fontSize: 15*ffem),
                                textAlign: TextAlign.center,
                              ),

                            ],
                          ),
                        ),
                      ))
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    /*return Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Container(
            padding: EdgeInsets.all(20),
            width: MediaQuery.of(context).size.width / 1.2,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Obx(() => controller.isLoading == false ?
                  GetBuilder<DefaultController>(
                    builder: (controller) {

                      final booking  = controller.selectedBooking[0];
                      final payments = controller.bookingPayments;

                      final NewBookingController newBookingController = Get.put(NewBookingController());

                      List<BookingSlot> bookingItems = [];
                      for(BookingSlot item in booking.bookingSlot) {
                        bookingItems.add(item);
                      }
                      List<BookingSlot> mergedSlots = newBookingController.mergeTimeSlots(bookingItems);

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Booking Details',style: TextStyle(color: Palette.primaryColor, fontSize: 15*ffem, fontWeight: FontWeight.bold),),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Get.back();
                                    },
                                    child: Text('Close',style: TextStyle(fontSize: 15*ffem,color: Palette.white),),
                                    style: ButtonStyle(
                                      shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15)
                                      )),
                                      padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 10*ffem,horizontal: 20)),
                                      backgroundColor: MaterialStatePropertyAll(Palette.primaryColor),
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),

                          Divider(height: 20,thickness: 2, color: Palette.mediumGrey),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Palette.fieldBg
                                ),
                                width: MediaQuery.of(context).size.width / 3,
                                child: Column(
                                  children: [
                                    Table(
                                      children: [
                                        TableRow(
                                          children: [
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('Booking ID',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),),
                                              ),
                                            ),
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('${booking.id}',style: TextStyle(fontSize: 15*ffem),),
                                              ),
                                            ),
                                          ],
                                        ),
                                        TableRow(
                                          children: [
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('Booking Date',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),),
                                              ),
                                            ),
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('${DateFormat('dd-MMM-yyyy').format(DateTime(booking.createdAt!.year,booking.createdAt!.month,booking.createdAt!.day))}',style: TextStyle(fontSize: 15*ffem),),
                                              ),
                                            ),
                                          ],
                                        ),
                                        *//*TableRow(
                                          children: [
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('Status',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),),
                                              ),
                                            ),
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('${booking.status}',style: TextStyle(
                                                  fontSize: 15*ffem,
                                                  color: booking.status == 'Booked' ? Colors.green : booking.status == 'Pending' ? Colors.orange : Colors.red,
                                                  fontWeight: FontWeight.bold
                                                ),),
                                              ),
                                            ),
                                          ],
                                        ),
                                        TableRow(
                                          children: [
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('Payment Type',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),),
                                              ),
                                            ),
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('${booking.paymentType}',style: TextStyle(
                                                  fontSize: 15*ffem,
                                                ),),
                                              ),
                                            ),
                                          ],
                                        ),
                                        TableRow(
                                          children: [
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('Payment Status',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),),
                                              ),
                                            ),
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('${booking.paymentStatus}',style: TextStyle(
                                                  fontSize: 15*ffem,
                                                  color: booking.paymentStatus == 'Paid' ? Colors.green : booking.paymentStatus == 'Partially' ? Colors.orange : Colors.red,
                                                  fontWeight: FontWeight.bold
                                                ),),
                                              ),
                                            ),
                                          ],
                                        ),*//*
                                      ],
                                      border: TableBorder.all(color: Palette.mediumGrey,borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width / 3,
                                child: Column(
                                  children: [
                                    Table(
                                      children: [
                                        TableRow(
                                          children: [
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.person,size: 20*ffem,),
                                                    Text(' Customer',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),)
                                                  ],
                                                ),
                                              ),
                                            ),
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('${booking.name}',style: TextStyle(fontSize: 15*ffem),),
                                              ),
                                            ),
                                          ],
                                        ),
                                        TableRow(
                                          children: [
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.phone_android,size: 20*ffem,),
                                                    Text(' Mobile',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),)
                                                  ],
                                                ),
                                              ),
                                            ),
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('${booking.mobile}',style: TextStyle(fontSize: 15*ffem),),
                                              ),
                                            ),
                                          ],
                                        ),
                                        *//*TableRow(
                                          children: [
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.email,size: 20*ffem,),
                                                    Text(' Email',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),)
                                                  ],
                                                ),
                                              ),
                                            ),
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('${booking.email}',style: TextStyle(fontSize: 15*ffem),),
                                              ),
                                            ),
                                          ],
                                        ),
                                        TableRow(
                                          children: [
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.note,size: 20*ffem,),
                                                    Text(' Notes',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),)
                                                  ],
                                                ),
                                              ),
                                            ),
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('${booking.notes}',style: TextStyle(fontSize: 15*ffem),),
                                              ),
                                            ),
                                          ],
                                        ),
                                        TableRow(
                                          children: [
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.note,size: 20*ffem,),
                                                    Text(' Notes',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),)
                                                  ],
                                                ),
                                              ),
                                            ),
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('${booking.notes}',style: TextStyle(fontSize: 15*ffem),),
                                              ),
                                            ),
                                          ],
                                        ),*//*
                                      ],
                                      defaultColumnWidth:IntrinsicColumnWidth(flex: 2),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 30,),
                          Align(
                            child: Text('Booked Court List',style: TextStyle(fontSize: 15*ffem,fontWeight:FontWeight.bold,color: Palette.primaryColor),textAlign: TextAlign.start,),
                            alignment: Alignment.topLeft,
                          ),
                          SizedBox(height: 20,),
                          Container(
                            height: MediaQuery.of(context).size.height / 3,
                            width: double.infinity,
                            child: SingleChildScrollView(
                              child: DataTable(
                                headingRowHeight: 40,
                                dataRowHeight: 40,
                                headingRowColor: MaterialStatePropertyAll(Palette.rowHeadingbg),
                                dataRowColor: MaterialStatePropertyAll(Palette.rowDatabg),
                                columns: [
                                  DataColumn(label: Text('Game',style: TextStyle(fontSize: 15*ffem,color: Palette.primaryColor),)),
                                  DataColumn(label: Text('Court',style: TextStyle(fontSize: 15*ffem,color: Palette.primaryColor),)),
                                  DataColumn(label: Text('Date',style: TextStyle(fontSize: 15*ffem,color: Palette.primaryColor),)),
                                  DataColumn(label: Text('Start Time',style: TextStyle(fontSize: 15*ffem,color: Palette.primaryColor),)),
                                  DataColumn(label: Text('End Time',style: TextStyle(fontSize: 15*ffem,color: Palette.primaryColor),)),
                                  DataColumn(label: Text('Price',style: TextStyle(fontSize: 15*ffem,color: Palette.primaryColor),)),
                                  DataColumn(label: Text('Action',style: TextStyle(fontSize: 15*ffem,color: Palette.primaryColor),)),
                                ],
                                rows: mergedSlots.map((e) =>
                                    DataRow(cells: [
                                      DataCell(
                                        Text('${e.service}',style: TextStyle(fontSize: 15*ffem),),
                                      ),
                                      DataCell(
                                        Text('${e.court}',style: TextStyle(fontSize: 15*ffem),),
                                      ),
                                      DataCell(
                                        Text('${DateFormat('dd-MMM-yy E').format(e.startTime!)}',style: TextStyle(fontSize: 15*ffem),),
                                      ),
                                      DataCell(
                                        Text('${DateFormat('hh:mm a').format(e.startTime!)}',style: TextStyle(fontSize: 15*ffem),),
                                      ),
                                      DataCell(
                                        Text('${DateFormat('hh:mm a').format(e.endTime!)}',style: TextStyle(fontSize: 15*ffem),),
                                      ),
                                      DataCell(
                                        Text('${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(e.price)}',style: TextStyle(fontSize: 15*ffem, fontWeight: FontWeight.bold),),
                                      ),
                                      DataCell(
                                          Checkbox(
                                            value: controller.selectedIds.contains(e.subBookingId.toString()),
                                            onChanged: (_) => controller.toggleSelection(e.subBookingId.toString()),
                                          )
                                      ),
                                    ]),
                                ).toList(),
                              ),
                            ),
                          ),

                          Divider(height: 40,color: Palette.darkGrey,thickness: 2),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              (booking.status!='Cancelled') ?
                              ElevatedButton(
                                onPressed: () {
                                  Get.to(NewBookingScreen(bookingId: booking.id,));
                                },
                                child: Text('Modify Booking',style: TextStyle(fontSize: 15*ffem,color: Palette.white),),
                                style: ButtonStyle(
                                  shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)
                                  )),
                                  padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 10*ffem,horizontal: 20)),
                                  backgroundColor: MaterialStatePropertyAll(Colors.orange),
                                ),
                              )
                                  :
                              Text(''),
                              SizedBox(width: 20,),
                              (booking.status!='Cancelled') ?
                              ElevatedButton(
                                onPressed: () {
                                  buildDeletePopup(controller, booking);
                                },
                                child: Text('Cancel Booking',style: TextStyle(fontSize: 15*ffem,color: Palette.white),),
                                style: ButtonStyle(
                                  shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)
                                  )),
                                  padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 10*ffem,horizontal: 20)),
                                  backgroundColor: MaterialStatePropertyAll(Palette.dangerTxt),
                                ),
                              )
                                  :
                              Text(''),
                              SizedBox(width: 20,),
                              ElevatedButton(
                                onPressed: () {

                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.paid,size: 20*ffem,),
                                    Text(' Make Payment',style: TextStyle(fontSize: 15*ffem),)
                                  ],
                                ),
                                style: ButtonStyle(
                                    padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 10*ffem,horizontal: 20)),
                                    shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)
                                    )),
                                    backgroundColor: MaterialStatePropertyAll(Palette.payColors)
                                ),
                              )
                            ],
                          ),

                          *//*SizedBox(height: 30,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Booking Payments',style: TextStyle(fontSize: 15*ffem),),
                                  SizedBox(height: 10,),
                                  Container(
                                    width: MediaQuery.of(context).size.width / 3,
                                    child: Table(
                                      children: [
                                        TableRow(
                                          children: [
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('Sub Total',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold,color: Palette.primaryColor),),
                                              ),
                                            ),
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(booking.subTotal)}',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),textAlign: TextAlign.end,),
                                              ),
                                            ),
                                          ],
                                        ),
                                        TableRow(
                                          children: [
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('Discount',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold,color: Palette.primaryColor),),
                                              ),
                                            ),
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(booking.discount)}',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),textAlign: TextAlign.end,),
                                              ),
                                            ),
                                          ],
                                        ),
                                        TableRow(
                                          children: [
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('GST',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold,color: Palette.primaryColor),),
                                              ),
                                            ),
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(booking.gst)}',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),textAlign: TextAlign.end,),
                                              ),
                                            ),
                                          ],
                                        ),
                                        TableRow(
                                          children: [
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('Total',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold,color: Palette.primaryColor),),
                                              ),
                                            ),
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(booking.total)}',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),textAlign: TextAlign.end,),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      border: TableBorder.all(color: Palette.mediumGrey,borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ],
                              ),

                              Container(
                                decoration: BoxDecoration(
                                    color: Palette.fieldBg,
                                    borderRadius: BorderRadius.circular(10)
                                ),
                                width: MediaQuery.of(context).size.width / 3,
                                child: Table(
                                  children: [
                                    TableRow(
                                      children: [
                                        TableCell(
                                          child: Padding(
                                            padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                            child: Text('Sub Total',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold,color: Palette.primaryColor),),
                                          ),
                                        ),
                                        TableCell(
                                          child: Padding(
                                            padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                            child: Text('${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(booking.subTotal)}',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),textAlign: TextAlign.end,),
                                          ),
                                        ),
                                      ],
                                    ),
                                    TableRow(
                                      children: [
                                        TableCell(
                                          child: Padding(
                                            padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                            child: Text('Discount',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold,color: Palette.primaryColor),),
                                          ),
                                        ),
                                        TableCell(
                                          child: Padding(
                                            padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                            child: Text('${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(booking.discount)}',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),textAlign: TextAlign.end,),
                                          ),
                                        ),
                                      ],
                                    ),
                                    TableRow(
                                      children: [
                                        TableCell(
                                          child: Padding(
                                            padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                            child: Text('GST',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold,color: Palette.primaryColor),),
                                          ),
                                        ),
                                        TableCell(
                                          child: Padding(
                                            padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                            child: Text('${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(booking.gst)}',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),textAlign: TextAlign.end,),
                                          ),
                                        ),
                                      ],
                                    ),
                                    TableRow(
                                      children: [
                                        TableCell(
                                          child: Padding(
                                            padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                            child: Text('Total',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold,color: Palette.primaryColor),),
                                          ),
                                        ),
                                        TableCell(
                                          child: Padding(
                                            padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                            child: Text('${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(booking.total)}',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),textAlign: TextAlign.end,),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  border: TableBorder.all(color: Palette.mediumGrey,borderRadius: BorderRadius.circular(10)),
                                ),
                              ),

                            ],
                          ),*//*

                          *//*Divider(height: 50,thickness: 2, color: Palette.mediumGrey),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: null,
                                child: Text('Modify Booking',style: TextStyle(fontSize: 15*ffem,color: Palette.white),),
                                style: ButtonStyle(
                                  shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)
                                  )),
                                  padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 10*ffem,horizontal: 20)),
                                  backgroundColor: MaterialStatePropertyAll(Palette.primaryColor),
                                ),
                              ),
                              SizedBox(width: 50,),
                              ElevatedButton(
                                onPressed: null,
                                child: Text('Cancel Booking',style: TextStyle(fontSize: 15*ffem,color: Palette.white),),
                                style: ButtonStyle(
                                    shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15)
                                    )),
                                    padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 10*ffem,horizontal: 20)),
                                    backgroundColor: MaterialStatePropertyAll(Palette.dangerTxt)
                                ),
                              ),
                            ],
                          )*//*

                        ],
                      );

                    },
                  )
                      :
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white, // Container color
                        borderRadius: BorderRadius.circular(10), // Optional: Adds rounded corners
                      ),
                      child: Column(
                        children: [

                          SizedBox(
                            width: 70,
                            height: 70,
                            child: CircularProgressIndicator(),
                          ), // Loading spinner
                          SizedBox(height: 50),
                          Text(
                            'Please wait, your booking is loading... It takes some time',
                            style: TextStyle(fontSize: 15*ffem),
                            textAlign: TextAlign.center,
                          ),

                        ],
                      ),
                    ),
                  ))
                ],
              ),
            ),
          ),
        )
    );*/
  }
//Not Used
  buildUpcomingBookingListTable(DefaultController controller, searchController) {
    var _showList = searchController.text.isEmpty ? controller.upcomingBookingList : controller.upcomingfilteredBookingList ;
    double fontSz = ffem;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10)
      ),
      child: Obx(() => controller.uptableLoading == false ?
      _showList.length > 0 ?
      SingleChildScrollView(
        //controller: _scrollController,
        child: DataTable(
          border: TableBorder.symmetric(
            outside: BorderSide(
              color: Palette.mediumGrey,
              width: 2,
            ),

          ),
          sortAscending: controller.isAscendingBooking,
          sortColumnIndex: controller.sortColumnBooking,
          headingRowHeight: 60,
          dataRowMaxHeight: double.infinity,
          horizontalMargin: 10,
          dataRowMinHeight: 70,
          headingRowColor: MaterialStatePropertyAll(Palette.rowHeadingbg),
          dataRowColor: MaterialStatePropertyAll(Palette.rowDatabg),
          columns: [
            DataColumn(
              onSort: controller.onSortBookingColumn,
              label: Center(
                child: Text(
                  'Booking ID',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Palette.primaryColor,
                    fontSize: 15*ffem,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            DataColumn(
              onSort: controller.onSortBookingColumn,
              label: Center(
                child: Text(
                  'Customer',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Palette.primaryColor,
                    fontSize: 15*ffem,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            DataColumn(
              onSort: controller.onSortBookingColumn,
              label: Center(
                child: Text(
                  'Game',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Palette.primaryColor,
                    fontSize: 15*ffem,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            DataColumn(
              onSort: controller.onSortBookingColumn,
              label: Center(
                child: Text(
                  'Booked On',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Palette.primaryColor,
                    fontSize: 15*ffem,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            DataColumn(
              onSort: controller.onSortBookingColumn,
              label: Center(
                child: Text(
                  'Action',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Palette.primaryColor,
                    fontSize: 15*ffem,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            DataColumn(
              onSort: controller.onSortBookingColumn,
              label: Center(
                child: Text(
                  'Status',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Palette.primaryColor,
                    fontSize: 15*ffem,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            DataColumn(
              onSort: controller.onSortBookingColumn,
              label: Center(
                child: Text(
                  'Payment Status',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Palette.primaryColor,
                    fontSize: 15*ffem,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          ],
          rows: _showList.map((element) {

            Set<String> uniqueCourt = {};
            element.bookingSlot.forEach((doc) {
              String? courtName = doc.court;
              uniqueCourt.add(courtName!);
            });
            List<String> distinctCourt = uniqueCourt.toList();

            Set<String> uniqueService = {};
            element.bookingSlot.forEach((doc) {
              String? serviceName = doc.service;
              uniqueService.add(serviceName!);
            });
            List<String> distinctService = uniqueService.toList();

            return DataRow(cells: [
              DataCell(
                Text('${element.id}',style: TextStyle(fontSize: 15*ffem),),
              ),
              DataCell(
                Text('${element.name}',style: TextStyle(fontSize: 15*ffem),),
              ),
              DataCell(
                  Column(
                    children: distinctService.map((element) {
                      return Text('${element}',style: TextStyle(fontSize: 15*ffem),);
                    }).toList(),
                  )
              ),
              DataCell(
                  Text('${DateFormat('dd-MM-yy').format(DateTime(element.createdAt!.year,element.createdAt!.month,element.createdAt!.day))}',style: TextStyle(fontSize: 15*ffem),)
              ),
              /*DataCell(
              Text('${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(element.total)}',style: TextStyle(fontSize: 25),),
            ),*/
              DataCell(
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        controller.isLoading.value = true;
                        controller.getBookingDetails(element.id);
                        buildViewDialog(controller);
                      },
                      icon: const Icon(Icons.remove_red_eye, color: Colors.blue,size: 30,),
                    ),
                  ],
                ),
              ),
              DataCell(
                  Container(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: null,
                      child: Text('${element.status}',style: TextStyle(color: Palette.white,fontSize: 15*ffem),),
                      style: ButtonStyle(
                          backgroundColor: MaterialStatePropertyAll(element.status == 'Booked' ? Colors.green : element.paymentStatus == 'Pending' ? Colors.orange : Colors.red),
                          shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)
                          )),
                          padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 5*ffem,horizontal: 10*ffem))
                      ),
                    ),
                  )
              ),
              DataCell(
                  Container(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: null,
                      child: Text('${element.paymentStatus}',style: TextStyle(color: Palette.white,fontSize: 15*ffem),),
                      style: ButtonStyle(
                          backgroundColor: MaterialStatePropertyAll(element.paymentStatus == 'Paid' ? Colors.green : element.paymentStatus == 'Partially' ? Colors.orange : Colors.red),
                          shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)
                          )),
                          padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 5*ffem,horizontal: 10*ffem))
                      ),
                    ),
                  )
              ),
            ]);
          },).toList(),
        ),
      )
          :
      Container(width: double.infinity, color: Palette.lightGrey, padding: EdgeInsets.all(20), child: Text('There is no bookings found',style: TextStyle(fontSize: 25),textAlign: TextAlign.center,),)
          :
      ShimmerTableLoading(columnCount: 6,rowCount: 4,)),
    );
  }
//Not Used
//Not Used
  buildUpcomingBookingSlotListTableWithoutStream(DefaultController controller, TextEditingController searchController) {
    var _showList = upcomingSearchController.text.isEmpty ? controller.upcomingBookingSlotsList : controller.upcomingFilteredBookingSlotsList ;
    return Container(
        width: double.infinity,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10)
        ),

        child: Obx(() {
          if(controller.upSlotTableLoading == false) {
            if(_showList.length > 0) {

              return SingleChildScrollView(
                //controller: _scrollController,
                child: DataTable(
                  border: TableBorder.symmetric(
                    outside: BorderSide(
                      color: Palette.mediumGrey,
                      width: 2,
                    ),
                  ),
                  sortAscending: controller.isAscendingBookingSlot,
                  sortColumnIndex: controller.sortColumnBookingSlot,
                  headingRowHeight: 60,
                  dataRowMaxHeight: double.infinity,
                  horizontalMargin: 10,
                  dataRowMinHeight: 60,
                  headingRowColor: MaterialStatePropertyAll(Palette.rowHeadingbg),
                  dataRowColor: MaterialStatePropertyAll(Palette.rowDatabg),
                  columns: [
                    DataColumn(
                      onSort: controller.onSortBookingSlotColumn1,
                      label: Center(
                        child: Text(
                          'Booking ID',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Palette.primaryColor,
                            fontSize: 15*ffem,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    DataColumn(
                      onSort: controller.onSortBookingSlotColumn1,
                      label: Center(
                        child: Text(
                          'Game',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Palette.primaryColor,
                            fontSize: 15*ffem,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    DataColumn(
                      onSort: controller.onSortBookingSlotColumn1,
                      label: Center(
                        child: Text(
                          'Court',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Palette.primaryColor,
                            fontSize: 15*ffem,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    DataColumn(
                      onSort: controller.onSortBookingSlotColumn1,
                      label: Center(
                        child: Text(
                          'Start Time',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Palette.primaryColor,
                            fontSize: 15*ffem,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    DataColumn(
                      onSort: controller.onSortBookingSlotColumn1,
                      label: Center(
                        child: Text(
                          'End Time',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Palette.primaryColor,
                            fontSize: 15*ffem,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    DataColumn(
                      onSort: controller.onSortBookingSlotColumn1,
                      label: Center(
                        child: Text(
                          'View',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Palette.primaryColor,
                            fontSize: 15*ffem,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    DataColumn(
                      onSort: controller.onSortBookingSlotColumn1,
                      label: Center(
                        child: Text(
                          'Payment Status',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Palette.primaryColor,
                            fontSize: 15*ffem,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                  rows: _showList.map((element) {
                    return DataRow(cells: [
                      DataCell(
                        Text('${element.bookingId}',style: TextStyle(fontSize: 15*ffem),),
                      ),
                      DataCell(
                        Text('${element.service}',style: TextStyle(fontSize: 15*ffem),),
                      ),
                      DataCell(
                        Text('${element.court}',style: TextStyle(fontSize: 15*ffem),),
                      ),
                      DataCell(
                        Text('${DateFormat('hh:mm a').format(element.startTime!)}',style: TextStyle(fontSize: 15*ffem),),
                      ),
                      DataCell(
                        Text('${DateFormat('hh:mm a').format(element.endTime!)}',style: TextStyle(fontSize: 15*ffem),),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {

                                controller.isLoading.value = true;
                                controller.getBookingSlotDetails(bookingId: element.bookingId,subBookingId: element.subBookingId);
                                controller.calculateBookingSlotPayments(bookingId: element.bookingId,subBookingId: element.subBookingId);
                                buildBookingSlotViewDialog(controller);

                              },
                              icon: Icon(Icons.remove_red_eye, color: Colors.blue,size: 30,),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                          Container(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: null,
                              child: Text('${element.paymentStatus}',style: TextStyle(color: Palette.white,fontSize: 15*ffem),),
                              style: ButtonStyle(
                                  backgroundColor: MaterialStatePropertyAll(element.paymentStatus == 'Paid' ? Colors.green : element.paymentStatus == 'Partially' ? Colors.orange : Colors.red),
                                  shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15)
                                  )),
                                  padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 5*ffem,horizontal: 10*ffem))
                              ),
                            ),
                          )
                        //Text('${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(element.price)}',style: TextStyle(fontSize: 15*ffem),),
                      ),
                    ]);
                  },).toList(),
                ),
              );
            } else {
              return Container(width: double.infinity, color: Palette.lightGrey, padding: EdgeInsets.all(20), child: Text('There is no bookings found',style: TextStyle(fontSize: 25),textAlign: TextAlign.center,),);
            }
          } else {
            return ShimmerTableLoading(columnCount: 6,rowCount: 4,);
          }
        },)
    );
  }
//Not Used



//Final Code

  //Upcoming Booking Slot Lits
  buildUpcomingBookingSlotListTable(DefaultController controller, TextEditingController searchController) {

    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10)
          ),
          child: (controller.serviceList.length > 0 && controller.courtList.length > 0) ?
          StreamBuilder<QuerySnapshot>(
            stream: _bookingSlotStream,
            builder: (context, snapshot) {

              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting || snapshot.data == null) {
                return ShimmerTableLoading(columnCount: 6,rowCount: 4,);
              }

                List<BookingSlot> newBookingSlots          = [];

                // Process the documents in the snapshot and create a list of User objects
                newBookingSlots = snapshot.data!.docs.map((doc) {
                Map<String, dynamic> slotData = doc.data() as Map<String, dynamic>;

                String serviceName = defaultController.getServiceIconById(slotData['serviceId']);
                String courtName   = defaultController.getCourtNameById(slotData['courtId']);

                return BookingSlot(
                  id: doc.id.toString(),
                  userId: slotData['userId'],
                  name: slotData['name'],
                  mobile: slotData['mobile'],
                  bookingId: slotData['bookingId'],
                  subBookingId: slotData['subBookingId'],
                  date: slotData['date'].toDate(),
                  service: serviceName,
                  serviceId: slotData['serviceId'],
                  court: courtName,
                  courtId: slotData['courtId'],
                  startTime: slotData['startTime'].toDate(),
                  endTime: slotData['endTime'].toDate(),
                  price: slotData['price'].toDouble(),
                  slotType: slotData['slotType'],
                  repeatDays: slotData['repeatDays'],
                  repeatEnd: slotData['repeatEnd'] !=null ? slotData['repeatEnd'].toDate() : null,
                  repeatId: slotData['repeatId'],
                  repeatGroupId: slotData['repeatGroupId'],
                  paymentStatus: slotData['paymentStatus'],
                  status: slotData['status'],
                  createdBy: slotData['createdBy'],
                  updatedBy: slotData['updatedBy'],
                  createdAt: (slotData['createdAt'] as Timestamp).toDate(),
                  updatedAt: (slotData['updatedAt'] as Timestamp).toDate(),
                );
              }).toList();

              List<BookingSlot> mergedList      = defaultController.mergeBookingSlots(newBookingSlots);

              DateTime currentTime              = DateTime.now();
              DateTime thirtyMinutesFromNow     = currentTime.add(Duration(minutes: 30));
              List<BookingSlot> finalSlots      = [];

              for (BookingSlot slot in mergedList) {
                if (slot.startTime!.isBefore(thirtyMinutesFromNow) && slot.endTime!.isAfter(currentTime)) {
                  finalSlots.add(slot);
                }
              }

              finalSlots.sort((a, b) => a.startTime!.compareTo(b.startTime!));

              defaultController.newBookingSlots = finalSlots;
              var _showList = upcomingSearchController.text.isNotEmpty ? defaultController.filteredNewBookingSlots : defaultController.newBookingSlots;

              return (defaultController.newBookingSlots.length > 0) ?
              Container(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    border: TableBorder.symmetric(
                      outside: BorderSide(
                        color: Palette.mediumGrey,
                        width: 2,
                      ),
                    ),
                    sortAscending: controller.newSortAscending,
                    sortColumnIndex: controller.newSortColumnIndex,
                    headingRowHeight: 60,
                    dataRowMaxHeight: double.infinity,
                    horizontalMargin: 10,
                    dataRowMinHeight: 60,
                    headingRowColor: MaterialStatePropertyAll(Palette.rowHeadingbg),
                    dataRowColor: MaterialStatePropertyAll(Palette.rowDatabg),
                    columns: [
                      DataColumn(
                        onSort: controller.onSortBookingSlotColumn1,
                        label: Center(
                          child: Text(
                            'Booking ID',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Palette.primaryColor,
                              fontSize: 15*ffem,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        onSort: controller.onSortBookingSlotColumn1,
                        label: Center(
                          child: Text(
                            'Name',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Palette.primaryColor,
                              fontSize: 15*ffem,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        onSort: controller.onSortBookingSlotColumn1,
                        label: Center(
                          child: Text(
                            'Court',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Palette.primaryColor,
                              fontSize: 15*ffem,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        onSort: controller.onSortBookingSlotColumn1,
                        label: Center(
                          child: Text(
                            'Start & End Time',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Palette.primaryColor,
                              fontSize: 15*ffem,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        onSort: controller.onSortBookingSlotColumn1,
                        label: Center(
                          child: Text(
                            'View',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Palette.primaryColor,
                              fontSize: 15*ffem,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        onSort: controller.onSortBookingSlotColumn1,
                        label: Center(
                          child: Text(
                            'Payment Status',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Palette.primaryColor,
                              fontSize: 15*ffem,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                    rows: _showList.map((element) {

                      List<String> serviceSplit = element.service!.split('%');

                      return DataRow(cells: [
                        DataCell(
                          Text('${element.bookingId}',style: TextStyle(fontSize: 15*ffem),),
                        ),
                        DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(' ${element.name}',style: TextStyle(fontSize: 15*ffem),),
                                Text(' ${element.mobile}',style: TextStyle(fontSize: 15*ffem,color: Palette.mediumGrey),),
                              ],
                            )
                        ),
                        DataCell(
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image(
                                image: AssetImage('${serviceSplit[1]}'),
                                fit: BoxFit.fill,
                                color: Colors.grey,
                                width: 50,
                                height: 50,
                              ),
                              Text(' ${element.court}',style: TextStyle(fontSize: 15*ffem),),
                            ],
                          )
                        ),
                        DataCell(
                          Text('${DateFormat('hh:mm ').format(element.startTime!)} - ${DateFormat('hh:mm a').format(element.endTime!)}',style: TextStyle(fontSize: 15*ffem),),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {

                                  controller.isLoading.value = true;
                                  selectedIds.clear();
                                  controller.selectedDateOption.value = 'Today';
                                  controller.selectedDate = DateTime.now();
                                  controller.getBookingSlotDetails(userId: element.userId, bookingId: element.bookingId,subBookingId: element.subBookingId,selDate: element.date);
                                  //controller.calculateBookingSlotPayments(bookingId: element.bookingId,subBookingId: element.subBookingId);
                                  buildBookingSlotViewDialog(controller);

                                },
                                icon: Icon(Icons.remove_red_eye, color: Colors.blue,size: 30,),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                            Container(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: null,
                                child: Text('${element.paymentStatus}',style: TextStyle(color: Palette.white,fontSize: 15*ffem),),
                                style: ButtonStyle(
                                    backgroundColor: MaterialStatePropertyAll(element.paymentStatus == 'Paid' ? Colors.green : element.paymentStatus == 'Partially' ? Colors.orange : Colors.red),
                                    shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15)
                                    )),
                                    padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 5*ffem,horizontal: 10*ffem))
                                ),
                              ),
                            )
                          //Text('${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(element.price)}',style: TextStyle(fontSize: 15*ffem),),
                        ),
                      ]);
                    },).toList(),
                  ),
                ),
              ) :
              Container(width: double.infinity, color: Palette.lightGrey, padding: EdgeInsets.all(20), child: Text('There is no data found',style: TextStyle(fontSize: 15*ffem),textAlign: TextAlign.center,),);
            },
          ) :
          ShimmerTableLoading(columnCount: 6,rowCount: 4,),
        )
      ],
    );

  }

  //Finished and Unpaid Booking Slot Lists
  buildFinishedUnpaidBookingSlotListTable(DefaultController controller) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10)
          ),
          child: (controller.serviceList.length > 0 && controller.courtList.length > 0) ?
          StreamBuilder<QuerySnapshot>(
            stream: _finishedUpaidbookingSlotStream,
            builder: (context, snapshot) {

              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting || snapshot.data == null) {
                return ShimmerTableLoading(columnCount: 6,rowCount: 4,);
              }

              List<BookingSlot> newBookingSlots          = [];

              // Process the documents in the snapshot and create a list of User objects
              newBookingSlots = snapshot.data!.docs.map((doc) {
                Map<String, dynamic> slotData = doc.data() as Map<String, dynamic>;

                String serviceName = defaultController.getServiceIconById(slotData['serviceId']);
                String courtName   = defaultController.getCourtNameById(slotData['courtId']);

                return BookingSlot(
                  id: doc.id.toString(),
                  userId: slotData['userId'],
                  name: slotData['name'],
                  mobile: slotData['mobile'],
                  bookingId: slotData['bookingId'],
                  subBookingId: slotData['subBookingId'],
                  date: slotData['date'].toDate(),
                  service: serviceName,
                  serviceId: slotData['serviceId'],
                  court: courtName,
                  courtId: slotData['courtId'],
                  startTime: slotData['startTime'].toDate(),
                  endTime: slotData['endTime'].toDate(),
                  price: slotData['price'].toDouble(),
                  slotType: slotData['slotType'],
                  repeatDays: slotData['repeatDays'],
                  repeatEnd: slotData['repeatEnd'] !=null ? slotData['repeatEnd'].toDate() : null,
                  repeatId: slotData['repeatId'],
                  repeatGroupId: slotData['repeatGroupId'],
                  paymentStatus: slotData['paymentStatus'],
                  status: slotData['status'],
                  createdBy: slotData['createdBy'],
                  updatedBy: slotData['updatedBy'],
                  createdAt: (slotData['createdAt'] as Timestamp).toDate(),
                  updatedAt: (slotData['updatedAt'] as Timestamp).toDate(),
                );
              }).toList();

              List<BookingSlot> mergedList      = defaultController.mergeBookingSlots(newBookingSlots);

              DateTime currentTime              = DateTime.now();
              List<BookingSlot> finalSlots      = [];

              for (BookingSlot slot in mergedList) {
                if (slot.endTime!.isBefore(currentTime)) {
                  finalSlots.add(slot);
                }
              }

              finalSlots.sort((a, b) => a.startTime!.compareTo(b.startTime!));

              defaultController.finishedUnpaidBookingSlots = finalSlots;
              var _showList = upcomingSearchController.text.isNotEmpty ? defaultController.filteredFinishedUnpaidBookingSlots : defaultController.finishedUnpaidBookingSlots;

              return (defaultController.finishedUnpaidBookingSlots.length > 0) ?
              Container(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    border: TableBorder.symmetric(
                      outside: BorderSide(
                        color: Palette.mediumGrey,
                        width: 2,
                      ),
                    ),
                    sortAscending: controller.newSortAscending,
                    sortColumnIndex: controller.newSortColumnIndex,
                    headingRowHeight: 60,
                    dataRowMaxHeight: double.infinity,
                    horizontalMargin: 10,
                    dataRowMinHeight: 60,
                    headingRowColor: MaterialStatePropertyAll(Palette.rowHeadingbg),
                    dataRowColor: MaterialStatePropertyAll(Palette.rowDatabg),
                    columns: [
                      DataColumn(
                        onSort: controller.onSortBookingSlotColumn2,
                        label: Center(
                          child: Text(
                            'Booking ID',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Palette.primaryColor,
                              fontSize: 15*ffem,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        onSort: controller.onSortBookingSlotColumn2,
                        label: Center(
                          child: Text(
                            'Name',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Palette.primaryColor,
                              fontSize: 15*ffem,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        onSort: controller.onSortBookingSlotColumn2,
                        label: Center(
                          child: Text(
                            'Court',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Palette.primaryColor,
                              fontSize: 15*ffem,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        onSort: controller.onSortBookingSlotColumn2,
                        label: Center(
                          child: Text(
                            'Start & End Time',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Palette.primaryColor,
                              fontSize: 15*ffem,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        onSort: controller.onSortBookingSlotColumn2,
                        label: Center(
                          child: Text(
                            'View',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Palette.primaryColor,
                              fontSize: 15*ffem,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        onSort: controller.onSortBookingSlotColumn2,
                        label: Center(
                          child: Text(
                            'Payment Status',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Palette.primaryColor,
                              fontSize: 15*ffem,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                    rows: _showList.map((element) {

                      List<String> serviceSplit = element.service!.split('%');

                      return DataRow(cells: [
                        DataCell(
                          Text('${element.bookingId}',style: TextStyle(fontSize: 15*ffem),),
                        ),
                        DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(' ${element.name}',style: TextStyle(fontSize: 15*ffem),),
                                Text(' ${element.mobile}',style: TextStyle(fontSize: 15*ffem,color: Palette.mediumGrey),),
                              ],
                            )
                        ),
                        DataCell(
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Image(
                                  image: AssetImage('${serviceSplit[1]}'),
                                  fit: BoxFit.fill,
                                  color: Colors.grey,
                                  width: 50,
                                  height: 50,
                                ),
                                Text(' ${element.court}',style: TextStyle(fontSize: 15*ffem),),
                              ],
                            )
                        ),
                        DataCell(
                          Text('${DateFormat('hh:mm ').format(element.startTime!)} - ${DateFormat('hh:mm a').format(element.endTime!)}',style: TextStyle(fontSize: 15*ffem),),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {

                                  controller.isLoading.value = true;
                                  selectedIds.clear();
                                  controller.selectedDateOption.value = 'Today';
                                  controller.selectedDate = DateTime.now();
                                  controller.getBookingSlotDetails(userId: element.userId, bookingId: element.bookingId,subBookingId: element.subBookingId,selDate: element.date);
                                  //controller.calculateBookingSlotPayments(bookingId: element.bookingId,subBookingId: element.subBookingId);
                                  buildBookingSlotViewDialog(controller);

                                },
                                icon: Icon(Icons.remove_red_eye, color: Colors.blue,size: 30,),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                            Container(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: null,
                                child: Text('${element.paymentStatus}',style: TextStyle(color: Palette.white,fontSize: 15*ffem),),
                                style: ButtonStyle(
                                    backgroundColor: MaterialStatePropertyAll(element.paymentStatus == 'Paid' ? Colors.green : element.paymentStatus == 'Partially' ? Colors.orange : Colors.red),
                                    shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15)
                                    )),
                                    padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 5*ffem,horizontal: 10*ffem))
                                ),
                              ),
                            )
                          //Text('${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(element.price)}',style: TextStyle(fontSize: 15*ffem),),
                        ),
                      ]);
                    },).toList(),
                  ),
                ),
              ) :
              Container(width: double.infinity, color: Palette.lightGrey, padding: EdgeInsets.all(20), child: Text('There is no data found',style: TextStyle(fontSize: 15*ffem),textAlign: TextAlign.center,),);
            },
          ) :
          ShimmerTableLoading(columnCount: 6,rowCount: 4,),
        )
      ],
    );
  }

  //All Booking Slot Lists
  buildAllBookingSlotListTable(DefaultController controller) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: MediaQuery.of(context).size.width / 4,
              child: DropdownButtonFormField<String>(
                value: controller.allselectedDateOption.value,
                onChanged: (newValue) {
                  controller.allselectedDateOption.value = newValue!;
                  controller.allselectDate(context);
                },
                items: controller.dateOptions.map((option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option,style: TextStyle(fontSize: 15*ffem)),
                  );
                }).toList(),
                decoration:  InputDecoration(
                  border: OutlineInputBorder(borderSide: BorderSide(color: Palette.lightGrey,width: 2),borderRadius: BorderRadius.circular(10)),
                  contentPadding: EdgeInsets.symmetric(vertical: 10*ffem,horizontal: 15),
                ),
              ),
            ),
            SizedBox(width: 20),
            /*Container(
              width: MediaQuery.of(context).size.width / 6.5,
              child: DropdownButtonFormField<String>(
                value: null,
                decoration:  InputDecoration(
                  border: OutlineInputBorder(borderSide: BorderSide(color: Palette.lightGrey,width: 2),borderRadius: BorderRadius.circular(10)),
                  contentPadding: EdgeInsets.symmetric(vertical: 10*ffem,horizontal: 15),
                ),
                items: controller.courtList.map((item) {
                  return DropdownMenuItem<String>(
                    value: item['id'],
                    child: Text('${item['name']}',style: TextStyle(fontSize: 15*ffem),),
                  );
                }).toList(),
                onChanged: (value) {

                },
                onSaved: (value) {

                },
              ),
            ),*/
            SizedBox(width: 20),
            Text(
              (controller.allselectedDateOption == 'Select Date') ? DateFormat('dd-MMM-yyyy EEEE').format(controller.allselectedDate!) : '',
              style: TextStyle(fontSize: 15*ffem,color: Palette.primaryColor,fontWeight: FontWeight.bold),
            )
          ],
        ),
        SizedBox(height: 20,),

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10)
          ),
          child: (controller.serviceList.length > 0 && controller.courtList.length > 0) ?
          StreamBuilder<QuerySnapshot>(
            stream: controller.getBookingSlotStream(controller.allselectedDate),
            builder: (context, snapshot) {

              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting || snapshot.data == null) {
                return ShimmerTableLoading(columnCount: 6,rowCount: 4,);
              }

              List<BookingSlot> newBookingSlots          = [];

              // Process the documents in the snapshot and create a list of User objects
              newBookingSlots = snapshot.data!.docs.map((doc) {
                Map<String, dynamic> slotData = doc.data() as Map<String, dynamic>;

                String serviceName = defaultController.getServiceIconById(slotData['serviceId']);
                String courtName   = defaultController.getCourtNameById(slotData['courtId']);

                return BookingSlot(
                  id: doc.id.toString(),
                  userId: slotData['userId'],
                  name: slotData['name'],
                  mobile: slotData['mobile'],
                  bookingId: slotData['bookingId'],
                  subBookingId: slotData['subBookingId'],
                  date: slotData['date'].toDate(),
                  service: serviceName,
                  serviceId: slotData['serviceId'],
                  court: courtName,
                  courtId: slotData['courtId'],
                  startTime: slotData['startTime'].toDate(),
                  endTime: slotData['endTime'].toDate(),
                  price: slotData['price'].toDouble(),
                  slotType: slotData['slotType'],
                  repeatDays: slotData['repeatDays'],
                  repeatEnd: slotData['repeatEnd'] !=null ? slotData['repeatEnd'].toDate() : null,
                  repeatId: slotData['repeatId'],
                  repeatGroupId: slotData['repeatGroupId'],
                  paymentStatus: slotData['paymentStatus'],
                  status: slotData['status'],
                  createdBy: slotData['createdBy'],
                  updatedBy: slotData['updatedBy'],
                  createdAt: (slotData['createdAt'] as Timestamp).toDate(),
                  updatedAt: (slotData['updatedAt'] as Timestamp).toDate(),
                );
              }).toList();

              List<BookingSlot> mergedList      = defaultController.mergeBookingSlots(newBookingSlots);

              DateTime currentTime              = DateTime.now();
              List<BookingSlot> finalSlots      = [];

              for (BookingSlot slot in mergedList) {
                finalSlots.add(slot);
              }

              finalSlots.sort((a, b) => a.startTime!.compareTo(b.startTime!));

              defaultController.allBookingSlots = finalSlots;
              var _showList = upcomingSearchController.text.isNotEmpty ? defaultController.filteredAllBookingSlots : defaultController.allBookingSlots;

              return (defaultController.allBookingSlots.length > 0) ?
              Container(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    border: TableBorder.symmetric(
                      outside: BorderSide(
                        color: Palette.mediumGrey,
                        width: 2,
                      ),
                    ),
                    sortAscending: controller.newSortAscending,
                    sortColumnIndex: controller.newSortColumnIndex,
                    headingRowHeight: 60,
                    dataRowMaxHeight: double.infinity,
                    horizontalMargin: 10,
                    dataRowMinHeight: 60,
                    headingRowColor: MaterialStatePropertyAll(Palette.rowHeadingbg),
                    dataRowColor: MaterialStatePropertyAll(Palette.rowDatabg),
                    columns: [
                      DataColumn(
                        onSort: controller.onSortBookingSlotColumn3,
                        label: Center(
                          child: Text(
                            'Booking ID',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Palette.primaryColor,
                              fontSize: 15*ffem,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        onSort: controller.onSortBookingSlotColumn3,
                        label: Center(
                          child: Text(
                            'Name',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Palette.primaryColor,
                              fontSize: 15*ffem,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        onSort: controller.onSortBookingSlotColumn3,
                        label: Center(
                          child: Text(
                            'Court',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Palette.primaryColor,
                              fontSize: 15*ffem,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        onSort: controller.onSortBookingSlotColumn3,
                        label: Center(
                          child: Text(
                            'Start & End Time',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Palette.primaryColor,
                              fontSize: 15*ffem,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        onSort: controller.onSortBookingSlotColumn3,
                        label: Center(
                          child: Text(
                            'View',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Palette.primaryColor,
                              fontSize: 15*ffem,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        onSort: controller.onSortBookingSlotColumn3,
                        label: Center(
                          child: Text(
                            'Payment Status',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Palette.primaryColor,
                              fontSize: 15*ffem,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                    rows: _showList.map((element) {

                      List<String> serviceSplit = element.service!.split('%');

                      return DataRow(cells: [
                        DataCell(
                          Text('${element.bookingId}',style: TextStyle(fontSize: 15*ffem),),
                        ),
                        DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(' ${element.name}',style: TextStyle(fontSize: 15*ffem),),
                                Text(' ${element.mobile}',style: TextStyle(fontSize: 15*ffem,color: Palette.mediumGrey),),
                              ],
                            )
                        ),
                        DataCell(
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Image(
                                  image: AssetImage('${serviceSplit[1]}'),
                                  fit: BoxFit.fill,
                                  color: Colors.grey,
                                  width: 50,
                                  height: 50,
                                ),
                                Text(' ${element.court}',style: TextStyle(fontSize: 15*ffem),),
                              ],
                            )
                        ),
                        DataCell(
                          Text('${DateFormat('hh:mm ').format(element.startTime!)} - ${DateFormat('hh:mm a').format(element.endTime!)}',style: TextStyle(fontSize: 15*ffem),),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {

                                  controller.isLoading.value = true;
                                  selectedIds.clear();
                                  controller.selectedDateOption.value = 'Today';
                                  controller.selectedDate = DateTime.now();
                                  controller.getBookingSlotDetails(userId: element.userId, bookingId: element.bookingId,subBookingId: element.subBookingId,selDate: element.date);
                                  //controller.calculateBookingSlotPayments(bookingId: element.bookingId,subBookingId: element.subBookingId);
                                  buildBookingSlotViewDialog(controller);

                                },
                                icon: Icon(Icons.remove_red_eye, color: Colors.blue,size: 30,),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                            Container(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: null,
                                child: Text('${element.paymentStatus}',style: TextStyle(color: Palette.white,fontSize: 15*ffem),),
                                style: ButtonStyle(
                                    backgroundColor: MaterialStatePropertyAll(element.paymentStatus == 'Paid' ? Colors.green : element.paymentStatus == 'Partially' ? Colors.orange : Colors.red),
                                    shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15)
                                    )),
                                    padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 5*ffem,horizontal: 10*ffem))
                                ),
                              ),
                            )
                          //Text('${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(element.price)}',style: TextStyle(fontSize: 15*ffem),),
                        ),
                      ]);
                    },).toList(),
                  ),
                ),
              ) :
              Container(width: double.infinity, color: Palette.lightGrey, padding: EdgeInsets.all(20), child: Text('There is no data found',style: TextStyle(fontSize: 15*ffem),textAlign: TextAlign.center,),);
            },
          ) :
          ShimmerTableLoading(columnCount: 6,rowCount: 4,),
        )
      ],
    );
  }



  buildBookingSlotViewDialog(DefaultController controller) {
    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Container(
                padding: EdgeInsets.all(20),
                width: MediaQuery.of(context).size.width / 1.2,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Obx(() {
                        if (controller.isLoading == null) {
                          return CircularProgressIndicator(); // Show a loading indicator while the value is null
                        } else if (controller.isLoading == false) {

                          final user          = controller.selectedUser[0];
                          final bookings      = controller.selectedBooking;
                          final payments      = controller.bookingSlotPayments;

                          List<BookingSlot> cartItems = [];
                          for(var item in controller.selectedBookingSlots) {
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
                          //desc mergedSlots.sort((a, b) => b.startTime!.compareTo(a.startTime!));
                          mergedSlots.sort((a, b) => a.startTime!.compareTo(b.startTime!));

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Booking Details',style: TextStyle(color: Palette.primaryColor, fontSize: 15*ffem, fontWeight: FontWeight.bold),),
                                  Row(
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          Get.back();
                                        },
                                        child: Text('Close',style: TextStyle(fontSize: 15*ffem,color: Palette.white),),
                                        style: ButtonStyle(
                                          shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(15)
                                          )),
                                          padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 10*ffem,horizontal: 20)),
                                          backgroundColor: MaterialStatePropertyAll(Palette.primaryColor),
                                        ),
                                      )
                                    ],
                                  )
                                ],
                              ),

                              Divider(height: 20,thickness: 2, color: Palette.mediumGrey),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  /*Container(
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Palette.fieldBg
                                    ),
                                    width: MediaQuery.of(context).size.width / 2,
                                    child: Column(
                                      children: [
                                        Table(
                                          children: [
                                            TableRow(
                                              children: [
                                                TableCell(
                                                  child: Padding(
                                                    padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                    child: Text('Booking ID',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),),
                                                  ),
                                                ),
                                                TableCell(
                                                  child: Padding(
                                                    padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                    child: Container(
                                                      height: 20,
                                                      child: ListView.builder(
                                                        scrollDirection: Axis.horizontal,
                                                        shrinkWrap: true,
                                                        itemCount: bookings.length,
                                                        itemBuilder: (context, index) {
                                                          return Text('${bookings[index].id}, ',style: TextStyle(fontSize: 15*ffem),
                                                          );
                                                        },
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
                                                    padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                    child: Text('Booked On',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),),
                                                  ),
                                                ),
                                                TableCell(
                                                  child: Padding(
                                                    padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                    child: Container(
                                                      height: 20,
                                                      child: ListView.builder(
                                                        scrollDirection: Axis.horizontal,
                                                        shrinkWrap: true,
                                                        itemCount: bookings.length,
                                                        itemBuilder: (context, index) {
                                                          return Text('${DateFormat('dd-MMM-yy E').format(bookings[index].createdAt!)}, ',style: TextStyle(fontSize: 15*ffem),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          border: TableBorder.all(color: Palette.mediumGrey,borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ],
                                    ),
                                  ),*/
                                  Container(
                                    width: MediaQuery.of(context).size.width / 3,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Palette.fieldBg
                                    ),
                                    child: Column(
                                      children: [
                                        Table(
                                          children: [
                                            TableRow(
                                              children: [
                                                TableCell(
                                                  child: Padding(
                                                    padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.person,size: 20*ffem,),
                                                        Text(' Customer',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),)
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                TableCell(
                                                  child: Padding(
                                                    padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                    child: Text('${(user.firstName!=null) ? user.firstName : ''} ${(user.lastName!=null) ? user.lastName : ''}',style: TextStyle(fontSize: 15*ffem),),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            TableRow(
                                              children: [
                                                TableCell(
                                                  child: Padding(
                                                    padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.phone_android,size: 20*ffem,),
                                                        Text(' Mobile',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),)
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                TableCell(
                                                  child: Padding(
                                                    padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                    child: Text('${user.mobile}',style: TextStyle(fontSize: 15*ffem),),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          defaultColumnWidth:IntrinsicColumnWidth(flex: 2),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 30,),

                              Align(
                                child: Text('Booked Court List',style: TextStyle(fontSize: 15*ffem,fontWeight:FontWeight.bold,color: Palette.primaryColor),textAlign: TextAlign.start,),
                                alignment: Alignment.topLeft,
                              ),
                              SizedBox(height: 20,),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    child: DropdownButtonFormField<String>(
                                      value: controller.selectedDateOption.value,
                                      onChanged: (newValue) {
                                        if(newValue=='Select Date') {
                                          controller.selectedDateOption.value = newValue!;
                                          controller.selectDate(context,user.id);
                                          //controller.isLoading.value = true;
                                        } else {
                                          controller.selectedDateOption.value = newValue!;
                                          controller.selectDate(context,user.id);
                                          controller.isLoading.value = true;
                                          controller.getBookingSlotDetails(
                                              userId: user.id,
                                              bookingId: null,
                                              subBookingId: null,
                                              selDate: controller.selectedDate
                                          );
                                        }
                                      },
                                      items: controller.dateOptions.map((option) {
                                        return DropdownMenuItem<String>(
                                          value: option,
                                          child: Text(option,style: TextStyle(fontSize: 15*ffem)),
                                        );
                                      }).toList(),
                                      decoration:  InputDecoration(
                                        border: OutlineInputBorder(borderSide: BorderSide(color: Palette.lightGrey,width: 2),borderRadius: BorderRadius.circular(10)),
                                        contentPadding: EdgeInsets.symmetric(vertical: 10*ffem,horizontal: 15),
                                      ),
                                    ),
                                    width: MediaQuery.of(context).size.width / 4,
                                  ),
                                  SizedBox(width: 20),
                                  Text(
                                    (controller.selectedDateOption == 'Select Date') ? DateFormat('dd-MMM-yyyy EEEE').format(controller.selectedDate!) : '',
                                    style: TextStyle(fontSize: 15*ffem,color: Palette.primaryColor,fontWeight: FontWeight.bold),
                                  )
                                ],
                              ),
                              SizedBox(height: 20,),

                              (mergedSlots.length > 0) ?
                              Container(
                                width: double.infinity,
                                child: DataTable(
                                  headingRowHeight: 40,
                                  dataRowHeight: 50,
                                  headingRowColor: MaterialStatePropertyAll(Palette.rowHeadingbg),
                                  dataRowColor: MaterialStatePropertyAll(Palette.rowDatabg),
                                  columns: [
                                    DataColumn(label: Text('Court',style: TextStyle(fontSize: 15*ffem,color: Palette.primaryColor),)),
                                    DataColumn(label: Text('Date',style: TextStyle(fontSize: 15*ffem,color: Palette.primaryColor),)),
                                    DataColumn(label: Text('Start & End Time',style: TextStyle(fontSize: 15*ffem,color: Palette.primaryColor),)),
                                    DataColumn(label: Text('Price',style: TextStyle(fontSize: 15*ffem,color: Palette.primaryColor),)),
                                    DataColumn(label: Text('Payment Status',style: TextStyle(fontSize: 15*ffem,color: Palette.primaryColor),)),
                                    DataColumn(label: Text('Select',style: TextStyle(fontSize: 15*ffem,color: Palette.primaryColor),)),
                                  ],
                                  rows: mergedSlots.map((e) =>
                                      DataRow(cells: [
                                        DataCell(
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text('${e.court}',style: TextStyle(fontSize: 15*ffem),),
                                                Text('${e.service}',style: TextStyle(fontSize: 13*ffem,color: Palette.mediumGrey),),
                                              ],
                                            )
                                        ),
                                        DataCell(
                                          Text('${DateFormat('dd-MMM-yy E').format(e.startTime!)}',style: TextStyle(fontSize: 15*ffem),),
                                        ),
                                        DataCell(
                                          Text('${DateFormat('hh:mm ').format(e.startTime!)} ${DateFormat('hh:mm a').format(e.endTime!)}',style: TextStyle(fontSize: 15*ffem),),
                                        ),
                                        DataCell(
                                          Text('${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(e.price)}',style: TextStyle(fontSize: 15*ffem, fontWeight: FontWeight.bold),),
                                        ),
                                        DataCell(
                                            Container(
                                              width: double.infinity,
                                              child: TextButton(
                                                onPressed: null,
                                                child: Text('${e.paymentStatus}',style: TextStyle(color: Palette.white,fontSize: 13*ffem),),
                                                style: ButtonStyle(
                                                    backgroundColor: MaterialStatePropertyAll(e.paymentStatus == 'Paid' ? Colors.green : e.paymentStatus == 'Partially' ? Colors.orange : Colors.red),
                                                    shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(15)
                                                    )),
                                                    padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 3*ffem,horizontal: 8*ffem))
                                                ),
                                              ),
                                            )
                                        ),
                                        DataCell(
                                          Checkbox(
                                            value: selectedIds.contains(e.subBookingId.toString()),
                                            onChanged: (value) {
                                              setState(() {
                                                toggleSelected(e.subBookingId.toString());
                                              });
                                            },
                                          ),
                                        )
                                      ]),
                                  ).toList(),
                                ),
                              ):
                              Container(
                                width: double.infinity,
                                color: Palette.lightGrey,
                                padding: EdgeInsets.all(20),
                                child: Text('No Bookings found',style: TextStyle(fontSize: 15*ffem),textAlign: TextAlign.center,),
                              ),

                              SizedBox(height: 20,),
                              /*Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                        color: Palette.fieldBg,
                                        borderRadius: BorderRadius.circular(10)
                                    ),
                                    width: MediaQuery.of(context).size.width / 3,
                                    child: Table(
                                      children: [
                                        TableRow(
                                          children: [
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('Total',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold,color: Palette.primaryColor),),
                                              ),
                                            ),
                                            TableCell(
                                              child: Padding(
                                                padding: EdgeInsets.all(10*ffem), // Adjust padding as needed
                                                child: Text('${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(mergedSlots[0].price)}',style: TextStyle(fontSize: 15*ffem,fontWeight: FontWeight.bold),textAlign: TextAlign.end,),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      border: TableBorder.all(color: Palette.mediumGrey,borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ],
                              ),*/
                              Divider(color: Palette.mediumGrey,height: 50,thickness: 2),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  //Edit Button
                                  (controller.editLoading==false) ?
                                  ElevatedButton(
                                    onPressed: selectedIds.length > 0 ? () {
                                      setState(() {
                                        controller.editLoading.value = true;
                                      });
                                      controller.actionBookingSlots.clear();
                                      controller.getActionBookingSlotDetails(selectedIds: selectedIds).then((value) {
                                        setState(() {
                                          controller.editLoading.value = false;
                                        });
                                        Get.to(NewBookingScreen(bookingId: null,selectedBSlots: controller.actionBookingSlots,));
                                      },);
                                    } : null,
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_calendar_outlined,size: 20*ffem,),
                                        Text(' Edit Booking',style: TextStyle(fontSize: 15*ffem),)
                                      ],
                                    ),
                                    style: ButtonStyle(
                                      shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15)
                                      )),
                                      padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 10*ffem,horizontal: 20)),
                                      backgroundColor: MaterialStatePropertyAll(selectedIds.length > 0 ? Colors.orange : Colors.orangeAccent),
                                    ),
                                  ):
                                  Container(
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(15*ffem), color: Colors.grey,),
                                    height: 50,
                                    width: 150,
                                    child: Center(
                                      child: SizedBox(
                                        height: 30,
                                        width: 30,
                                        child: CircularProgressIndicator(
                                          color: Palette.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(width: 30*ffem,),

                                  //Cancel Button
                                  (controller.cancelLoading==false) ?
                                  ElevatedButton(
                                    onPressed: selectedIds.length > 0 ? () {
                                      buildCancelSlotPopup(controller, selectedIds);
                                    } : null,
                                    child: Row(
                                      children: [
                                        Icon(Icons.cancel,size: 20*ffem,),
                                        Text(' Cancel Booking',style: TextStyle(fontSize: 15*ffem),)
                                      ],
                                    ),
                                    style: ButtonStyle(
                                      shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15)
                                      )),
                                      padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 10*ffem,horizontal: 20)),
                                      backgroundColor: MaterialStatePropertyAll(selectedIds.length > 0 ? Colors.red : Colors.redAccent),
                                    ),
                                  ):
                                  Container(
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(15*ffem), color: Colors.grey,),
                                    height: 50,
                                    width: 150,
                                    child: Center(
                                      child: SizedBox(
                                        height: 30,
                                        width: 30,
                                        child: CircularProgressIndicator(
                                          color: Palette.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(width: 30*ffem,),

                                  //Checkout Button
                                  (controller.paymentLoading==false) ?
                                  ElevatedButton(
                                    onPressed: selectedIds.length > 0 ? () {
                                      setState(() {
                                        controller.paymentLoading.value = true;
                                      });
                                      controller.actionBookingSlots.clear();
                                      controller.getActionBookingSlotDetails(selectedIds: selectedIds).then((value) {
                                        setState(() {
                                          controller.paymentLoading.value = false;
                                        });
                                        Get.to(CheckoutScreen(type: 'ExistingBooking',));
                                      },);
                                    } : null,
                                    child: Row(
                                      children: [
                                        Icon(Icons.paid,size: 20*ffem,),
                                        Text(' Checkout',style: TextStyle(fontSize: 15*ffem),)
                                      ],
                                    ),
                                    style: ButtonStyle(
                                        padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 10*ffem,horizontal: 20*ffem)),
                                        shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10)
                                        )),
                                        backgroundColor: MaterialStatePropertyAll(selectedIds.length > 0 ? Colors.green : Colors.greenAccent)
                                    ),
                                  ):
                                  Container(
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(15*ffem), color: Colors.grey,),
                                    height: 50,
                                    width: 150,
                                    child: Center(
                                      child: SizedBox(
                                        height: 30,
                                        width: 30,
                                        child: CircularProgressIndicator(
                                          color: Palette.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),

                                ],
                              )

                            ],
                          );
                        } else {
                          return Center(
                            child: Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white, // Container color
                                borderRadius: BorderRadius.circular(10), // Optional: Adds rounded corners
                              ),
                              child: Column(
                                children: [

                                  SizedBox(
                                    width: 70,
                                    height: 70,
                                    child: CircularProgressIndicator(),
                                  ), // Loading spinner
                                  SizedBox(height: 50),
                                  Text(
                                    'Please wait, your booking is loading... It takes some time',
                                    style: TextStyle(fontSize: 15*ffem),
                                    textAlign: TextAlign.center,
                                  ),

                                ],
                              ),
                            ),
                          ); // Show a loading indicator while isLoading is true
                        }
                      }),

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

  buildCancelSlotPopup(DefaultController controller, List<String>? selectedIds) {

    Widget _deleteBtn = Obx(() => controller.cancelSlotIsLoading.value == false ?
    ElevatedButton(
      style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(Palette.primaryColor),
          shape: MaterialStateProperty.all<
              RoundedRectangleBorder>(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50.0),
              side: const BorderSide(color: Palette.primaryColor)
          )
          ),
          padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 15*ffem,horizontal: 30*ffem))
      ),
      onPressed: () {
        setState(() {
          controller.cancelSlotIsLoading.value = true;
        });
        controller.cancelBookingSlots(selectedIds: selectedIds);
      },
      child: Text('Cancel',style: TextStyle(fontSize: 15*ffem),),
    )
        :
    Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), color: Colors.grey,),
      height: 55,
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

    return Get.dialog(
        AlertDialog(
          contentPadding: EdgeInsets.symmetric(vertical: 70,horizontal: 20),
          content: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20*ffem),
              child: Column(
                children: [
                  Text('Are you sure to Cancel the Booking?',style: TextStyle(fontSize: 15*ffem),textAlign: TextAlign.center),
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
                            padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 15*ffem,horizontal: 30*ffem))
                        ),
                        onPressed: () => Get.back(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Palette.mediumGrey,fontSize: 15*ffem),
                        ),
                      ),
                      _deleteBtn,
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
    );

  }

//Final Code
}
