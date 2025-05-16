import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/constants.dart';
import '../../config/palette.dart';
import '../../controllers/customer_controller.dart';
import '../../controllers/default_controller.dart';
import '../../models/booking_model.dart';
import '../../models/user.dart';
import '../../widgets/shimmer/shimmer_table_loading.dart';
import '../booking/new_booking_screen.dart';
import '../checkout/checkout_screen.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({Key? key}) : super(key: key);

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final CustomerController customerController = Get.put(CustomerController());
  final DefaultController defaultController = Get.put(DefaultController());
  TextEditingController _searchController = TextEditingController();
  Stream<QuerySnapshot>? _userStream;

  @override
  void initState() {
    super.initState();
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
    return GetBuilder(
      init: CustomerController(),
      builder: (controller) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(children: [buildBody(controller)]),
        );
      },
    );
  }

  buildBody(CustomerController controller) {
    return Expanded(
      child: ListView(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Players',
                    style: TextStyle(
                      fontSize: 18 * ffem,
                      fontWeight: FontWeight.bold,
                      color: Palette.primaryColor,
                    ),
                  ),
                  SizedBox(width: 100),
                  Container(
                    color: Palette.fieldBg,
                    height: 40 * ffem,
                    width: MediaQuery.of(context).size.width / 3,
                    child: Padding(
                      padding: EdgeInsets.all(0 * ffem),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (query) {
                          // Filter the users based on the query
                          customerController.filterUsers(query);
                        },
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(10 * ffem),
                          //isDense: true,
                          hintText: "Search",
                          hintStyle: TextStyle(fontSize: 15 * ffem),
                          suffixIcon: Icon(
                            Icons.search_outlined,
                            color: Palette.mediumGrey,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              Divider(height: 40, color: Palette.darkGrey),
              buildCustomerList(controller),
            ],
          ),
        ],
      ),
    );
  }

  buildCustomerList(CustomerController controller) {
    return Column(
      children: [
        /*Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (query) {
              // Filter the users based on the query
              // You can modify your filtering logic here
              filterUsers(query);
            },
          ),
        ),*/
        Container(
          width: double.infinity,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          child: StreamBuilder<QuerySnapshot>(
            stream: _userStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting ||
                  snapshot.data == null) {
                return ShimmerTableLoading(columnCount: 4, rowCount: 4);
              }

              // Process the documents in the snapshot and create a list of User objects
              customerController.users =
                  snapshot.data!.docs.map((doc) {
                    Map<String, dynamic> userData =
                        doc.data() as Map<String, dynamic>;
                    return User(
                      id: doc.id.toString(),
                      email: userData['email'],
                      firstName: userData['firstName'],
                      lastName: userData['lastName'],
                      address: userData['address'],
                      mobile: userData['mobile'],
                      postcode: userData['postcode'],
                      password: userData['password'],
                      aboutus: userData['aboutus'],
                      dateOfBirth:
                          userData['dateOfBirth'] != null
                              ? (userData['dateOfBirth'] as Timestamp).toDate()
                              : null,
                      city: userData['city'],
                      state: userData['state'],
                      country: userData['country'],
                      imageUrl: userData['profile_picture'],
                      //userMembershipId: userData['userMembershipId'],
                      createdAt: (userData['createdAt'] as Timestamp).toDate(),
                      updatedAt: (userData['updatedAt'] as Timestamp).toDate(),
                      // Initialize other fields here
                    );
                  }).toList();

              var _showList =
                  _searchController.text.isNotEmpty
                      ? customerController.filteredUsers
                      : customerController.users;

              return (customerController.users.length > 0)
                  ? Container(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        border: TableBorder.symmetric(
                          outside: BorderSide(
                            color: Palette.mediumGrey,
                            width: 2,
                          ),
                        ),
                        sortAscending: customerController.sortAscending,
                        sortColumnIndex: customerController.sortColumnIndex,
                        headingRowHeight: 60,
                        dataRowMaxHeight: double.infinity,
                        horizontalMargin: 10,
                        dataRowMinHeight: 60,
                        headingRowColor: WidgetStatePropertyAll(
                          Palette.rowHeadingbg,
                        ),
                        dataRowColor: WidgetStatePropertyAll(Palette.rowDatabg),
                        columns: [
                          DataColumn(
                            onSort: controller.onSortCustomerColumn,
                            label: Center(
                              child: Text(
                                'Name',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Palette.primaryColor,
                                  fontSize: 15 * ffem,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          DataColumn(
                            onSort: controller.onSortCustomerColumn,
                            label: Center(
                              child: Text(
                                'Mobile',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Palette.primaryColor,
                                  fontSize: 15 * ffem,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          DataColumn(
                            onSort: controller.onSortCustomerColumn,
                            label: Center(
                              child: Text(
                                'Created On',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Palette.primaryColor,
                                  fontSize: 15 * ffem,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          DataColumn(
                            onSort: controller.onSortCustomerColumn,
                            label: Center(
                              child: Text(
                                'View',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Palette.primaryColor,
                                  fontSize: 15 * ffem,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                        rows:
                            _showList
                                .map(
                                  (user) => DataRow(
                                    cells: [
                                      DataCell(
                                        Row(
                                          children: [
                                            Container(
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  8.0,
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                  child: CachedNetworkImage(
                                                    maxHeightDiskCache: 50,
                                                    fit: BoxFit.cover,
                                                    key: UniqueKey(),
                                                    height: 50,
                                                    width: 50,
                                                    imageUrl:
                                                        user.imageUrl
                                                            .toString(),
                                                    placeholder:
                                                        (
                                                          context,
                                                          url,
                                                        ) => FittedBox(
                                                          fit: BoxFit.cover,
                                                          child: Icon(
                                                            Icons.person,
                                                            color:
                                                                Palette
                                                                    .primaryColor,
                                                          ),
                                                        ),
                                                    errorWidget:
                                                        (
                                                          context,
                                                          url,
                                                          error,
                                                        ) => FittedBox(
                                                          fit: BoxFit.cover,
                                                          child: Icon(
                                                            Icons.person,
                                                            color:
                                                                Palette
                                                                    .primaryColor,
                                                          ),
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '${user.firstName} ${(user.lastName != null ? user.lastName : '')}',
                                              style: TextStyle(
                                                fontSize: 15 * ffem,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${user.mobile}',
                                          style: TextStyle(fontSize: 15 * ffem),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${DateFormat('dd-MMM-yyyy').format(DateTime(user.createdAt!.year, user.createdAt!.month, user.createdAt!.day))}',
                                          style: TextStyle(fontSize: 15 * ffem),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          children: [
                                            IconButton(
                                              onPressed: () {
                                                controller.isLoading.value =
                                                    true;
                                                selectedIds.clear();
                                                controller
                                                    .selectedDateOption
                                                    .value = 'Today';
                                                controller.selectedDate =
                                                    DateTime.now();
                                                controller
                                                    .getBookingSlotDetails(
                                                      userId: user.id,
                                                      bookingId: null,
                                                      subBookingId: null,
                                                      selDate:
                                                          controller
                                                              .selectedDate,
                                                    );
                                                controller.getCurrentMembership(
                                                  userId: user.id,
                                                );
                                                //controller.calculateBookingSlotPayments(bookingId: element.bookingId,subBookingId: element.subBookingId);
                                                buildBookingSlotViewDialog(
                                                  controller,
                                                );
                                              },
                                              icon: Icon(
                                                Icons.remove_red_eye,
                                                color: Colors.blue,
                                                size: 30,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  )
                  : Container(
                    width: double.infinity,
                    color: Palette.lightGrey,
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'There is no data found',
                      style: TextStyle(fontSize: 25),
                      textAlign: TextAlign.center,
                    ),
                  );
            },
          ),
        ),
      ],
    );
  }

  buildBookingSlotViewDialog(CustomerController controller) {
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
                          final user = controller.selectedUser[0];
                          final bookings = controller.selectedBooking;

                          List<BookingSlot> cartItems = [];
                          for (var item in controller.selectedBookingSlots) {
                            cartItems.add(
                              BookingSlot(
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
                                updatedBy: item.updatedBy,
                              ),
                            );
                          }

                          List<BookingSlot> mergedSlots = controller
                              .mergeTimeSlots(cartItems);
                          //desc mergedSlots.sort((a, b) => b.startTime!.compareTo(a.startTime!));
                          mergedSlots.sort(
                            (a, b) => a.startTime!.compareTo(b.startTime!),
                          );

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Booking Details',
                                    style: TextStyle(
                                      color: Palette.primaryColor,
                                      fontSize: 15 * ffem,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          Get.back();
                                        },
                                        style: ButtonStyle(
                                          shape: WidgetStatePropertyAll(
                                            RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                          ),
                                          padding: WidgetStatePropertyAll(
                                            EdgeInsets.symmetric(
                                              vertical: 10 * ffem,
                                              horizontal: 20,
                                            ),
                                          ),
                                          backgroundColor:
                                              WidgetStatePropertyAll(
                                                Palette.primaryColor,
                                              ),
                                        ),
                                        child: Text(
                                          'Close',
                                          style: TextStyle(
                                            fontSize: 15 * ffem,
                                            color: Palette.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              Divider(
                                height: 20,
                                thickness: 2,
                                color: Palette.mediumGrey,
                              ),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                    width:
                                        MediaQuery.of(context).size.width / 3,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Palette.fieldBg,
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
                                                        Icon(
                                                          Icons.person,
                                                          size: 20 * ffem,
                                                        ),
                                                        Text(
                                                          ' Customer',
                                                          style: TextStyle(
                                                            fontSize: 15 * ffem,
                                                            fontWeight:
                                                                FontWeight.bold,
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
                                                      '${(user.firstName != null) ? user.firstName : ''} ${(user.lastName != null) ? user.lastName : ''}',
                                                      style: TextStyle(
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
                                                          ' Mobile',
                                                          style: TextStyle(
                                                            fontSize: 15 * ffem,
                                                            fontWeight:
                                                                FontWeight.bold,
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
                                                      '${user.mobile}',
                                                      style: TextStyle(
                                                        fontSize: 15 * ffem,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          defaultColumnWidth:
                                              IntrinsicColumnWidth(flex: 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 15 * ffem,
                                    ),
                                    width:
                                        MediaQuery.of(context).size.width / 3,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Palette.fieldBg,
                                    ),
                                    child: Column(
                                      children: [
                                        (controller.currentPlan.length > 0)
                                            ? Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 20,
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Membership ',
                                                    style: TextStyle(
                                                      fontSize: 15 * ffem,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  SizedBox(height: 5),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        '${controller.currentPlan[0]['plan']} - ${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(controller.currentPlan[0]['price'])}',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15 * ffem,
                                                        ),
                                                      ),
                                                      Text(
                                                        '  ${controller.currentPlan[0]['status']}',
                                                        style: TextStyle(
                                                          color:
                                                              controller.currentPlan[0]['status'] ==
                                                                      'Active'
                                                                  ? Colors.green
                                                                  : Colors.red,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15 * ffem,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 5),
                                                  Text(
                                                    'Expiry Date : ${controller.currentPlan[0]['remainingDays']}',
                                                    style: TextStyle(
                                                      fontSize: 15 * ffem,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                            : ElevatedButton(
                                              onPressed: () {
                                                buildMembershipDialog(
                                                  controller,
                                                  user.id,
                                                );
                                              },
                                              style: ButtonStyle(
                                                backgroundColor:
                                                    WidgetStatePropertyAll(
                                                      Palette.payColors,
                                                    ),
                                                padding: WidgetStatePropertyAll(
                                                  EdgeInsets.symmetric(
                                                    vertical: 10 * ffem,
                                                    horizontal: 15 * ffem,
                                                  ),
                                                ),
                                              ),
                                              child: Text(
                                                'Become a Member',
                                                style: TextStyle(
                                                  fontSize: 15 * ffem,
                                                ),
                                              ),
                                            ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 30),

                              Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  'Booked Court List',
                                  style: TextStyle(
                                    fontSize: 15 * ffem,
                                    fontWeight: FontWeight.bold,
                                    color: Palette.primaryColor,
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                              ),
                              SizedBox(height: 20),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width / 4,
                                    child: DropdownButtonFormField<String>(
                                      value:
                                          controller.selectedDateOption.value,
                                      onChanged: (newValue) {
                                        if (newValue == 'Select Date') {
                                          controller.selectedDateOption.value =
                                              newValue!;
                                          controller.selectDate(
                                            context,
                                            user.id,
                                          );
                                          //controller.isLoading.value = true;
                                        } else {
                                          controller.selectedDateOption.value =
                                              newValue!;
                                          controller.selectDate(
                                            context,
                                            user.id,
                                          );
                                          controller.isLoading.value = true;
                                          controller.getBookingSlotDetails(
                                            userId: user.id,
                                            bookingId: null,
                                            subBookingId: null,
                                            selDate: controller.selectedDate,
                                          );
                                        }
                                      },
                                      items:
                                          controller.dateOptions.map((option) {
                                            return DropdownMenuItem<String>(
                                              value: option,
                                              child: Text(
                                                option,
                                                style: TextStyle(
                                                  fontSize: 15 * ffem,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Palette.lightGrey,
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 10 * ffem,
                                          horizontal: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 20),
                                  Text(
                                    (controller.selectedDateOption ==
                                            'Select Date')
                                        ? DateFormat(
                                          'dd-MMM-yyyy EEEE',
                                        ).format(controller.selectedDate!)
                                        : '',
                                    style: TextStyle(
                                      fontSize: 15 * ffem,
                                      color: Palette.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),

                              (mergedSlots.length > 0)
                                  ? Container(
                                    width: double.infinity,
                                    child: DataTable(
                                      headingRowHeight: 40,
                                      dataRowHeight: 50,
                                      headingRowColor: WidgetStatePropertyAll(
                                        Palette.rowHeadingbg,
                                      ),
                                      dataRowColor: WidgetStatePropertyAll(
                                        Palette.rowDatabg,
                                      ),
                                      columns: [
                                        DataColumn(
                                          label: Text(
                                            'Court',
                                            style: TextStyle(
                                              fontSize: 15 * ffem,
                                              color: Palette.primaryColor,
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Date',
                                            style: TextStyle(
                                              fontSize: 15 * ffem,
                                              color: Palette.primaryColor,
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Start & End Time',
                                            style: TextStyle(
                                              fontSize: 15 * ffem,
                                              color: Palette.primaryColor,
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Price',
                                            style: TextStyle(
                                              fontSize: 15 * ffem,
                                              color: Palette.primaryColor,
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Payment Status',
                                            style: TextStyle(
                                              fontSize: 15 * ffem,
                                              color: Palette.primaryColor,
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Select',
                                            style: TextStyle(
                                              fontSize: 15 * ffem,
                                              color: Palette.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                      rows:
                                          mergedSlots
                                              .map(
                                                (e) => DataRow(
                                                  cells: [
                                                    DataCell(
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            '${e.court}',
                                                            style: TextStyle(
                                                              fontSize:
                                                                  15 * ffem,
                                                            ),
                                                          ),
                                                          Text(
                                                            '${e.service}',
                                                            style: TextStyle(
                                                              fontSize:
                                                                  13 * ffem,
                                                              color:
                                                                  Palette
                                                                      .mediumGrey,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        '${DateFormat('dd-MMM-yy E').format(e.startTime!)}',
                                                        style: TextStyle(
                                                          fontSize: 15 * ffem,
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        '${DateFormat('hh:mm ').format(e.startTime!)} ${DateFormat('hh:mm a').format(e.endTime!)}',
                                                        style: TextStyle(
                                                          fontSize: 15 * ffem,
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        '${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(e.price)}',
                                                        style: TextStyle(
                                                          fontSize: 15 * ffem,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Container(
                                                        width: double.infinity,
                                                        child: TextButton(
                                                          onPressed: null,
                                                          style: ButtonStyle(
                                                            backgroundColor: WidgetStatePropertyAll(
                                                              e.paymentStatus ==
                                                                      'Paid'
                                                                  ? Colors.green
                                                                  : e.paymentStatus ==
                                                                      'Partially'
                                                                  ? Colors
                                                                      .orange
                                                                  : Colors.red,
                                                            ),
                                                            shape: WidgetStatePropertyAll(
                                                              RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      15,
                                                                    ),
                                                              ),
                                                            ),
                                                            padding:
                                                                WidgetStatePropertyAll(
                                                                  EdgeInsets.symmetric(
                                                                    vertical:
                                                                        3 *
                                                                        ffem,
                                                                    horizontal:
                                                                        8 *
                                                                        ffem,
                                                                  ),
                                                                ),
                                                          ),
                                                          child: Text(
                                                            '${e.paymentStatus}',
                                                            style: TextStyle(
                                                              color:
                                                                  Palette.white,
                                                              fontSize:
                                                                  13 * ffem,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Checkbox(
                                                        value: selectedIds
                                                            .contains(
                                                              e.subBookingId
                                                                  .toString(),
                                                            ),
                                                        onChanged: (value) {
                                                          setState(() {
                                                            toggleSelected(
                                                              e.subBookingId
                                                                  .toString(),
                                                            );
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                              .toList(),
                                    ),
                                  )
                                  : Container(
                                    width: double.infinity,
                                    color: Palette.lightGrey,
                                    padding: EdgeInsets.all(20),
                                    child: Text(
                                      'No Bookings found',
                                      style: TextStyle(fontSize: 15 * ffem),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),

                              SizedBox(height: 20),
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
                              Divider(
                                color: Palette.mediumGrey,
                                height: 50,
                                thickness: 2,
                              ),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  //Edit Button
                                  (controller.editLoading == false)
                                      ? ElevatedButton(
                                        onPressed:
                                            selectedIds.length > 0
                                                ? () {
                                                  setState(() {
                                                    controller
                                                        .editLoading
                                                        .value = true;
                                                  });
                                                  controller.actionBookingSlots
                                                      .clear();
                                                  controller
                                                      .getActionBookingSlotDetails(
                                                        selectedIds:
                                                            selectedIds,
                                                      )
                                                      .then((value) {
                                                        setState(() {
                                                          controller
                                                              .editLoading
                                                              .value = false;
                                                        });
                                                        Get.to(
                                                          NewBookingScreen(
                                                            bookingId: null,
                                                            selectedBSlots:
                                                                controller
                                                                    .actionBookingSlots,
                                                          ),
                                                        );
                                                      });
                                                }
                                                : null,
                                        style: ButtonStyle(
                                          shape: WidgetStatePropertyAll(
                                            RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                          ),
                                          padding: WidgetStatePropertyAll(
                                            EdgeInsets.symmetric(
                                              vertical: 10 * ffem,
                                              horizontal: 20,
                                            ),
                                          ),
                                          backgroundColor:
                                              WidgetStatePropertyAll(
                                                selectedIds.length > 0
                                                    ? Colors.orange
                                                    : Colors.orangeAccent,
                                              ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.edit_calendar_outlined,
                                              size: 20 * ffem,
                                            ),
                                            Text(
                                              ' Edit Booking',
                                              style: TextStyle(
                                                fontSize: 15 * ffem,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                      : Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            15 * ffem,
                                          ),
                                          color: Colors.grey,
                                        ),
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

                                  SizedBox(width: 30 * ffem),

                                  //Cancel Button
                                  (controller.cancelLoading == false)
                                      ? ElevatedButton(
                                        onPressed:
                                            selectedIds.length > 0
                                                ? () {
                                                  buildCancelSlotPopup(
                                                    controller,
                                                    selectedIds,
                                                  );
                                                }
                                                : null,
                                        style: ButtonStyle(
                                          shape: WidgetStatePropertyAll(
                                            RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                          ),
                                          padding: WidgetStatePropertyAll(
                                            EdgeInsets.symmetric(
                                              vertical: 10 * ffem,
                                              horizontal: 20,
                                            ),
                                          ),
                                          backgroundColor:
                                              WidgetStatePropertyAll(
                                                selectedIds.length > 0
                                                    ? Colors.red
                                                    : Colors.redAccent,
                                              ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.cancel, size: 20 * ffem),
                                            Text(
                                              ' Cancel Booking',
                                              style: TextStyle(
                                                fontSize: 15 * ffem,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                      : Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            15 * ffem,
                                          ),
                                          color: Colors.grey,
                                        ),
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

                                  SizedBox(width: 30 * ffem),

                                  //Checkout Button
                                  (controller.paymentLoading == false)
                                      ? ElevatedButton(
                                        onPressed:
                                            selectedIds.length > 0
                                                ? () {
                                                  setState(() {
                                                    controller
                                                        .paymentLoading
                                                        .value = true;
                                                  });
                                                  controller.actionBookingSlots
                                                      .clear();
                                                  controller
                                                      .getActionBookingSlotDetails(
                                                        selectedIds:
                                                            selectedIds,
                                                      )
                                                      .then((value) {
                                                        setState(() {
                                                          controller
                                                              .paymentLoading
                                                              .value = false;
                                                        });
                                                        Get.to(
                                                          CheckoutScreen(
                                                            type:
                                                                'ExistingBooking',
                                                          ),
                                                        );
                                                      });
                                                }
                                                : null,
                                        style: ButtonStyle(
                                          padding: WidgetStatePropertyAll(
                                            EdgeInsets.symmetric(
                                              vertical: 10 * ffem,
                                              horizontal: 20 * ffem,
                                            ),
                                          ),
                                          shape: WidgetStatePropertyAll(
                                            RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          backgroundColor:
                                              WidgetStatePropertyAll(
                                                selectedIds.length > 0
                                                    ? Colors.green
                                                    : Colors.greenAccent,
                                              ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.paid, size: 20 * ffem),
                                            Text(
                                              ' Checkout',
                                              style: TextStyle(
                                                fontSize: 15 * ffem,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                      : Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            15 * ffem,
                                          ),
                                          color: Colors.grey,
                                        ),
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
                              ),
                            ],
                          );
                        } else {
                          return Center(
                            child: Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white, // Container color
                                borderRadius: BorderRadius.circular(
                                  10,
                                ), // Optional: Adds rounded corners
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
                                    style: TextStyle(fontSize: 15 * ffem),
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

  buildCancelSlotPopup(
    CustomerController controller,
    List<String>? selectedIds,
  ) {
    Widget _deleteBtn = Obx(
      () =>
          controller.cancelSlotIsLoading.value == false
              ? ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                    Palette.primaryColor,
                  ),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50.0),
                      side: const BorderSide(color: Palette.primaryColor),
                    ),
                  ),
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(
                      vertical: 15 * ffem,
                      horizontal: 30 * ffem,
                    ),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    controller.cancelSlotIsLoading.value = true;
                  });
                  controller.cancelBookingSlots(selectedIds: selectedIds);
                  //controller.cancelBookingSlot(subBookingId);
                },
                child: Text('Cancel', style: TextStyle(fontSize: 15 * ffem)),
              )
              : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: Colors.grey,
                ),
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
              ),
    );

    return Get.dialog(
      AlertDialog(
        contentPadding: EdgeInsets.symmetric(vertical: 70, horizontal: 20),
        content: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20 * ffem),
            child: Column(
              children: [
                Text(
                  'Are you sure to Cancel the Booking?',
                  style: TextStyle(fontSize: 15 * ffem),
                  textAlign: TextAlign.center,
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
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50.0),
                                side: const BorderSide(color: Palette.black),
                              ),
                            ),
                        padding: WidgetStatePropertyAll(
                          EdgeInsets.symmetric(
                            vertical: 15 * ffem,
                            horizontal: 30 * ffem,
                          ),
                        ),
                      ),
                      onPressed: () => Get.back(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Palette.mediumGrey,
                          fontSize: 15 * ffem,
                        ),
                      ),
                    ),
                    _deleteBtn,
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  buildMembershipDialog(CustomerController controller, String? userId) {
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
                padding: EdgeInsets.all(20),
                width: MediaQuery.of(context).size.width / 2,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Membership Plans',
                        style: TextStyle(
                          fontSize: 15 * ffem,
                          color: Palette.primaryColor,
                        ),
                      ),
                      Divider(
                        height: 40,
                        color: Palette.lightGrey,
                        thickness: 2,
                      ),
                      (controller.membershipList.length > 0)
                          ? ListView.builder(
                            scrollDirection: Axis.vertical,
                            shrinkWrap: true,
                            itemCount: controller.membershipList.length,
                            itemBuilder: (context, index) {
                              var membership = controller.membershipList[index];
                              return Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: 15 * ffem,
                                  horizontal: 15 * ffem,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey,
                                      offset: Offset(2, 2),
                                      blurRadius: 5,
                                      spreadRadius: 1,
                                    ),
                                    BoxShadow(
                                      color: Colors.white,
                                      offset: Offset(-2, -2),
                                      blurRadius: 5,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.star,
                                    size: 30 * ffem,
                                    color: Palette.primaryColor,
                                  ), // Replace with your desired icon
                                  title: Text(
                                    '${membership.name} - ${membership.validDays} Days - ${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(membership.price)}',
                                    style: TextStyle(fontSize: 15 * ffem),
                                  ),
                                  trailing: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      (controller.buyNowLoading.value == false)
                                          ? ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                controller.buyNowLoading.value =
                                                    true;
                                              });
                                              controller
                                                  .buyMembership(
                                                    userId: userId,
                                                    membershipPlanId:
                                                        membership.id,
                                                    name: membership.name,
                                                    price: membership.price,
                                                    paymentType: '',
                                                  )
                                                  .then((value) {
                                                    setState(() {
                                                      controller
                                                          .buyNowLoading
                                                          .value = false;
                                                    });
                                                    Get.to(
                                                      CheckoutScreen(
                                                        type: 'Membership',
                                                      ),
                                                    );
                                                  });
                                            },
                                            style: ButtonStyle(
                                              shape: WidgetStatePropertyAll(
                                                RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        20 * ffem,
                                                      ),
                                                ),
                                              ),
                                              backgroundColor:
                                                  WidgetStatePropertyAll(
                                                    Palette.payColors,
                                                  ),
                                              padding: WidgetStatePropertyAll(
                                                EdgeInsets.symmetric(
                                                  vertical: 10 * ffem,
                                                  horizontal: 15 * ffem,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              "Buy Now",
                                              style: TextStyle(
                                                fontSize: 15 * ffem,
                                              ),
                                            ),
                                          )
                                          : Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              color: Colors.grey,
                                            ),
                                            height: 40,
                                            width: 100,
                                            child: Center(
                                              child: SizedBox(
                                                height: 15,
                                                width: 15,
                                                child:
                                                    CircularProgressIndicator(
                                                      color:
                                                          Palette.primaryColor,
                                                    ),
                                              ),
                                            ),
                                          ),
                                    ],
                                  ),
                                  subtitle: Container(
                                    // Use a container for flexible description
                                    padding: EdgeInsets.only(top: 8),
                                    // Use a container for flexible description
                                    child: Text(
                                      "Discount : ${membership.discount}%",
                                      style: TextStyle(fontSize: 15 * ffem),
                                    ), // Add some padding for spacing
                                  ),
                                ),
                              );
                            },
                          )
                          : Container(
                            child: Text(
                              'There is no Membership Plans Available..',
                              style: TextStyle(fontSize: 15 * ffem),
                            ),
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
