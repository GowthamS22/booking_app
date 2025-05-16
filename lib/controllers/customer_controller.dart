import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../config/constants.dart';
import '../config/palette.dart';
import '../models/booking_model.dart';
import '../models/membership_plan.dart';
import '../models/user.dart';

class CustomerController extends GetxController {
  final supabase = Supabase.instance.client;
  RxBool isLoading = false.obs;
  RxBool tableLoading = true.obs;

  List<User> users = [];
  List<User> filteredUsers = [];
  bool sortAscending = true;
  int sortColumnIndex = 1;

  RxBool editLoading = false.obs;
  RxBool cancelLoading = false.obs;
  RxBool paymentLoading = false.obs;
  RxBool cancelSlotIsLoading = false.obs;

  RxBool buyNowLoading = false.obs;
  var membershipList = <MembershipPlan>[].obs;
  List currentPlan = [];
  List selectedPlan = [];

  var selectedBooking = <Booking>[].obs;
  var selectedUser = <User>[].obs;
  var selectedBookingSlots = <BookingSlot>[].obs;
  var actionBookingSlots = <BookingSlot>[].obs;

  final int _itemsPerPage = 10;
  DocumentSnapshot? _lastDocument;

  final List<String> dateOptions = [
    'Today',
    'Yesterday',
    'Tomorrow',
    'Last 7 Days',
    'Select Date',
  ];
  RxString selectedDateOption = 'Today'.obs;
  DateTime selectedDate = DateTime.now();

  Future<void> selectDate(BuildContext context, String? id) async {
    if (selectedDateOption.value == 'Today') {
      selectedDate = DateTime.now();
    } else if (selectedDateOption.value == 'Yesterday') {
      selectedDate = DateTime.now().subtract(Duration(days: 1));
    } else if (selectedDateOption.value == 'Tomorrow') {
      selectedDate = DateTime.now().add(Duration(days: 1));
    } else if (selectedDateOption.value == 'Last 7 Days') {
      selectedDate = DateTime.now().subtract(Duration(days: 6));
    } else if (selectedDateOption.value == 'Select Date') {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );

      if (picked != null && picked != selectedDate) {
        isLoading.value = true;
        selectedDate = picked;
        getBookingSlotDetails(
          userId: id,
          bookingId: null,
          subBookingId: null,
          selDate: selectedDate,
        );
        update();
      }
    }
  }

  @override
  void onInit() {
    //fetchMembershipList();
    super.onInit();
  }

  // void fetchMembershipList() async {
  //   membershipList.clear();
  //   QuerySnapshot membershipSnapshot = await FirebaseFirestore.instance
  //       .collection(authController.centerSlug.toString())
  //       .doc('membershipPlans')
  //       .collection('membershipPlan')
  //       .get();
  //   for(var membership in membershipSnapshot.docs) {
  //     DateTime dateTimeValue = membership['createdAt'].toDate();
  //     membershipList.add(MembershipPlan(
  //         id: membership.id,
  //         name: membership['name'],
  //         price: membership['price'].toDouble(),
  //         validDays: membership['validDays'].toInt(),
  //         discount: membership['discount'].toDouble(),
  //         active: membership['active'],
  //         createdAt: dateTimeValue
  //     ));
  //   }
  //   isLoading.value = false;
  //   update();
  // }

  void filterUsers(String query) {
    filteredUsers =
        users.where((user) {
          final name = '${user.firstName} ${user.lastName ?? ''}'.toLowerCase();
          final mobile = user.mobile!.toLowerCase();
          return name.contains(query.toLowerCase()) ||
              mobile.contains(query.toLowerCase());
        }).toList();
    update();
  }

  void onSortCustomerColumn(int columnIndex, bool ascending) {
    if (columnIndex == 0) {
      users.sort(
        (item1, item2) =>
            compareString(ascending, item1.firstName, item2.firstName),
      );
      filteredUsers.sort(
        (item1, item2) =>
            compareString(ascending, item1.firstName, item2.firstName),
      );
    } else if (columnIndex == 1) {
      users.sort(
        (item1, item2) => compareString(ascending, item1.mobile, item2.mobile),
      );
      filteredUsers.sort(
        (item1, item2) => compareString(ascending, item1.mobile, item2.mobile),
      );
    }
    sortColumnIndex = columnIndex;
    sortAscending = ascending;
    update();
  }

  int compareString(bool ascending, var val1, var val2) =>
      ascending
          ? Comparable.compare(val1, val2)
          : Comparable.compare(val2, val1);

  // get booking slot details
  Future<void> getBookingSlotDetails({
    String? userId,
    String? bookingId,
    String? subBookingId,
    DateTime? selDate,
  }) async {
    //Clear Bookings
    selectedUser.clear();
    selectedBooking.clear();
    selectedBookingSlots.clear();

    //Retrieve User Data
    final userResponse =
        await supabase
            .schema('s22_prod_schema')
            .from('customers')
            .select()
            .eq('id', userId!)
            .single();

    if (userResponse != null) {
      final userData = User.fromMap(userResponse);
      print(userData);
      selectedUser.add(User.fromMap(userResponse));

      //Retrieve Booking Data
      final bookingResponse = await supabase
          .schema('s22_prod_schema')
          .from('bookings')
          .select()
          .eq('customer_id', userId);

      for (var booking in bookingResponse) {
        selectedBooking.add(
          Booking(
            booking['id'],
            booking['booking_no'],
            booking['customer_id'],
            booking['name'],
            booking['mobile'],
            booking['email'],
            booking['notes'],
            (booking['sub_total'] as num).toDouble(),
            (booking['discount'] as num).toDouble(),
            (booking['gst'] as num).toDouble(),
            (booking['total'] as num).toDouble(),
            booking['payment_type'],
            booking['payment_status'],
            booking['status'],
            [],
            booking['created_by'],
            booking['updated_by'],
            DateTime.parse(booking['created_at']),
            DateTime.parse(booking['updated_at']),
          ),
        );
      }

      //Booking Slot query
      QuerySnapshot<Map<String, dynamic>> bookingSlotsSnapshot;

      final slotQuery = supabase
          .schema('s22_prod_schema')
          .from('booking_slots')
          .select()
          .eq('booking_id', bookingId!)
          .eq('status', 'Booked')
          .eq('booking_id', bookingId);

      if (selectedDateOption.value == 'Last 7 Days') {
        slotQuery
          ..gte(
            'start_time',
            DateTime.now().subtract(Duration(days: 7)).toIso8601String(),
          )
          ..lte('start_time', DateTime.now().toIso8601String());
      } else if (selDate != null) {
        final startOfDay = DateTime(selDate.year, selDate.month, selDate.day);
        final endOfDay = startOfDay.add(Duration(days: 1));
        slotQuery
          ..gte('start_time', startOfDay.toIso8601String())
          ..lt('start_time', endOfDay.toIso8601String());
      }
      final slotResponse = await slotQuery;
      //Store the booking slot in model
      for (final slot in slotResponse) {
        final serviceName = await getServiceName(slot['service_id']);
        final courtName = await getCourtName(slot['court_id']);

        selectedBookingSlots.add(
          BookingSlot(
            id: slot['id'],
            userId: userId,
            name: slot['name'],
            mobile: slot['mobile'],
            bookingId: slot['booking_id'],
            subBookingId: slot['sub_booking_id'],
            date: DateTime.parse(slot['start_time']),
            service: serviceName,
            serviceId: slot['service_id'],
            court: courtName,
            courtId: slot['court_id'],
            startTime: DateTime.parse(slot['start_time']),
            endTime: DateTime.parse(slot['end_time']),
            price: (slot['price'] as num).toDouble(),
            slotType: slot['slot_type'],
            repeatDays: slot['repeat_days'],
            repeatEnd:
                slot['repeat_end'] != null
                    ? DateTime.parse(slot['repeat_end'])
                    : null,
            repeatId: slot['repeat_id'],
            repeatGroupId: slot['repeat_group_id'],
            paymentStatus: slot['payment_status'],
            status: slot['status'],
            createdBy: slot['created_by'],
            updatedBy: slot['updated_by'],
            createdAt: DateTime.parse(slot['created_at']),
            updatedAt: DateTime.parse(slot['updated_at']),
          ),
        );
      }
    }

    isLoading.value = false;
    update();
  }

  // // get booking slot details
  // Future<void> getBookingSlotDetails({
  //   String? userId,
  //   String? bookingId,
  //   String? subBookingId,
  //   DateTime? selDate,
  // }) async {
  //   //Clear Bookings
  //   selectedUser.clear();
  //   selectedBooking.clear();
  //   selectedBookingSlots.clear();

  //   //Retrieve User Data
  //   DocumentSnapshot userSnapshot =
  //       await FirebaseFirestore.instance
  //           .collection(authController.centerSlug.toString())
  //           .doc('userDetails')
  //           .collection('user')
  //           .doc(userId)
  //           .get();
  //   if (userSnapshot.exists) {
  //     Map<String, dynamic>? userData =
  //         userSnapshot.data() as Map<String, dynamic>?;
  //     selectedUser.add(
  //       User(
  //         id: userId,
  //         email: userData!['email'],
  //         firstName: userData!['firstName'],
  //         lastName: userData!['lastName'],
  //         address: userData!['address'],
  //         mobile: userData!['mobile'],
  //         postcode: userData!['postcode'],
  //         password: userData!['password'],
  //         aboutus: userData!['aboutus'],
  //         dateOfBirth:
  //             userData!['dateOfBirth'] != null
  //                 ? (userData!['dateOfBirth'] as Timestamp).toDate()
  //                 : null,
  //         city: userData!['city'],
  //         state: userData!['state'],
  //         country: userData!['country'],
  //         imageUrl: userData!['imageUrl'],
  //         userMembershipId: userData!['userMembershipId'],
  //         createdAt: (userData!['createdAt'] as Timestamp).toDate(),
  //         updatedAt: (userData!['updatedAt'] as Timestamp).toDate(),
  //       ),
  //     );

  //     //Retrieve Booking Data
  //     QuerySnapshot bookingSnapshot =
  //         await FirebaseFirestore.instance
  //             .collection(authController.centerSlug.toString())
  //             .doc('bookings')
  //             .collection('booking')
  //             .where('userId', isEqualTo: selectedUser[0].id)
  //             .get();

  //     if (bookingSnapshot.docs.isNotEmpty) {
  //       for (var booking in bookingSnapshot.docs) {
  //         selectedBooking.add(
  //           Booking(
  //             booking.id,
  //             booking!['userId'],
  //             booking!['name'],
  //             booking!['mobile'],
  //             booking!['email'],
  //             booking!['notes'],
  //             booking!['subTotal'].toDouble(),
  //             booking!['discount'].toDouble(),
  //             booking!['gst'].toDouble(),
  //             booking!['total'].toDouble(),
  //             booking!['paymentType'],
  //             booking!['paymentStatus'],
  //             booking!['status'],
  //             [],
  //             booking!['createdBy'],
  //             booking!['updatedBy'],
  //             booking!['createdAt'].toDate(),
  //             booking!['updatedAt'].toDate(),
  //           ),
  //         );
  //       }
  //     }

  //     //Booking Slot query
  //     QuerySnapshot<Map<String, dynamic>> bookingSlotsSnapshot;

  //     Query<Map<String, dynamic>> baseQuery = FirebaseFirestore.instance
  //         .collection(authController.centerSlug.toString())
  //         .doc('bookingSlots')
  //         .collection('bookingSlot')
  //         .where('userId', isEqualTo: userId.toString())
  //         .where('status', isEqualTo: 'Booked');

  //     if (selectedDateOption.value == 'Last 7 Days') {
  //       print('test');
  //       bookingSlotsSnapshot =
  //           await baseQuery
  //               .where(
  //                 'date',
  //                 isGreaterThanOrEqualTo: DateTime(
  //                   selectedDate.year,
  //                   selectedDate.month,
  //                   selectedDate.day,
  //                 ),
  //               )
  //               .where(
  //                 'date',
  //                 isLessThanOrEqualTo: DateTime(
  //                   DateTime.now().year,
  //                   DateTime.now().month,
  //                   DateTime.now().day,
  //                 ),
  //               )
  //               .get();
  //     } else {
  //       bookingSlotsSnapshot =
  //           await baseQuery
  //               .where(
  //                 'date',
  //                 isEqualTo: DateTime(
  //                   selDate!.year,
  //                   selDate.month,
  //                   selDate.day,
  //                 ),
  //               )
  //               .get();
  //     }

  //     //Store the booking slot in model
  //     for (DocumentSnapshot subDoc in bookingSlotsSnapshot.docs) {
  //       String serviceId = subDoc['serviceId'];
  //       String courtId = subDoc['courtId'];

  //       String serviceName = await getServiceName(serviceId);
  //       String courtName = await getCourtName(courtId);

  //       BookingSlot bookingSlot = BookingSlot(
  //         id: subDoc.id,
  //         userId: subDoc['userId'],
  //         name: subDoc['name'],
  //         mobile: subDoc['mobile'],
  //         bookingId: subDoc['bookingId'],
  //         subBookingId: subDoc['subBookingId'],
  //         date: subDoc['date'].toDate(),
  //         service: serviceName,
  //         serviceId: subDoc['serviceId'],
  //         court: courtName,
  //         courtId: subDoc['courtId'],
  //         startTime: subDoc['startTime'].toDate(),
  //         endTime: subDoc['endTime'].toDate(),
  //         price: subDoc['price'].toDouble(),
  //         slotType: subDoc['slotType'],
  //         repeatDays: subDoc['repeatDays'],
  //         repeatEnd:
  //             subDoc['repeatEnd'] != null ? subDoc['repeatEnd'].toDate() : null,
  //         repeatId: subDoc['repeatId'],
  //         repeatGroupId: subDoc['repeatGroupId'],
  //         paymentStatus: subDoc['paymentStatus'],
  //         status: subDoc['status'],
  //         createdBy: subDoc['createdBy'],
  //         updatedBy: subDoc['updatedBy'],
  //         createdAt: subDoc['createdAt'].toDate(),
  //         updatedAt: subDoc['updatedAt'].toDate(),
  //       );
  //       selectedBookingSlots.add(bookingSlot);
  //     }
  //   }

  //   isLoading.value = false;
  //   update();
  // }

  // get action booking slot details
  Future<void> getActionBookingSlotDetails({List<String>? selectedIds}) async {
    //Clear Bookings
    actionBookingSlots.clear();

    for (var id in selectedIds!) {
      //Booking Slot query
      QuerySnapshot bookingSlotsSnapshot =
          await FirebaseFirestore.instance
              .collection(authController.centerSlug.toString())
              .doc('bookingSlots')
              .collection('bookingSlot')
              .where('subBookingId', isEqualTo: id.toString())
              .where('status', isEqualTo: 'Booked')
              .get();

      //Store the booking slot in model
      for (DocumentSnapshot subDoc in bookingSlotsSnapshot.docs) {
        String serviceId = subDoc['serviceId'];
        String courtId = subDoc['courtId'];

        String serviceName = await getServiceName(serviceId);
        String courtName = await getCourtName(courtId);

        BookingSlot bookingSlot = BookingSlot(
          id: subDoc.id,
          userId: subDoc['userId'],
          name: subDoc['name'],
          mobile: subDoc['mobile'],
          bookingId: subDoc['bookingId'],
          subBookingId: subDoc['subBookingId'],
          date: subDoc['date'].toDate(),
          service: serviceName,
          serviceId: subDoc['serviceId'],
          court: courtName,
          courtId: subDoc['courtId'],
          startTime: subDoc['startTime'].toDate(),
          endTime: subDoc['endTime'].toDate(),
          price: subDoc['price'].toDouble(),
          slotType: subDoc['slotType'],
          repeatDays: subDoc['repeatDays'],
          repeatEnd:
              subDoc['repeatEnd'] != null ? subDoc['repeatEnd'].toDate() : null,
          repeatId: subDoc['repeatId'],
          repeatGroupId: subDoc['repeatGroupId'],
          paymentStatus: subDoc['paymentStatus'],
          status: subDoc['status'],
          createdBy: subDoc['createdBy'],
          updatedBy: subDoc['updatedBy'],
          createdAt: subDoc['createdAt'].toDate(),
          updatedAt: subDoc['updatedAt'].toDate(),
        );
        actionBookingSlots.add(bookingSlot);
      }
    }

    isLoading.value = false;
    update();
  }

  //cancel booking slots
  Future<void> cancelBookingSlots({List<String>? selectedIds}) async {
    try {
      for (var id in selectedIds!) {
        QuerySnapshot querySnapshot =
            await FirebaseFirestore.instance
                .collection(authController.centerSlug.toString())
                .doc('bookingSlots')
                .collection('bookingSlot')
                .where('subBookingId', isEqualTo: id.toString())
                .get();

        List<Future<void>> updateFutures = [];
        for (DocumentSnapshot docSnapshot in querySnapshot.docs) {
          updateFutures.add(
            docSnapshot.reference.update({
              'status': 'Cancelled',
              'updatedBy': authController.userId.toString(),
              'updatedAt': DateTime.now(),
            }),
          );
        }
        await Future.wait(updateFutures);
      }

      Get.back();
      Get.back();

      //Status alert
      showCustomSnackbar(
        'Success',
        'Booking Cancelled Successfully',
        Colors.green,
      );
    } catch (e) {
      print(e.toString());
    } finally {
      cancelSlotIsLoading.value = false;
      update();
    }
  }

  // Function to get service name from local cache or Firestore
  Future<String> getServiceName(String serviceId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? serviceName = prefs.getString('service_$serviceId');
    if (serviceName == null) {
      // Service name not found in cache, fetch it from Firestore
      DocumentSnapshot serviceDoc =
          await FirebaseFirestore.instance
              .collection(authController.centerSlug.toString())
              .doc('services')
              .collection('service')
              .doc(serviceId)
              .get();
      serviceName = serviceDoc['name'];
      prefs.setString(
        'service_$serviceId',
        serviceName!,
      ); // Cache the service name
    }
    return serviceName;
  }

  // Function to get court name from local cache or Firestore
  Future<String> getCourtName(String courtId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? courtName = prefs.getString('court_$courtId');
    if (courtName == null) {
      // Court name not found in cache, fetch it from Firestore
      DocumentSnapshot courtDoc =
          await FirebaseFirestore.instance
              .collection(authController.centerSlug.toString())
              .doc('courts')
              .collection('court')
              .doc(courtId)
              .get();
      courtName = courtDoc['name'];
      prefs.setString('court_$courtId', courtName!); // Cache the court name
    }
    return courtName;
  }

  List<BookingSlot> mergeTimeSlots(List<BookingSlot> cartItemsMrg) {
    if (cartItemsMrg.isEmpty) return [];

    // Sort the cartItemsMrg based on court, date, startTime, and endTime
    cartItemsMrg.sort((a, b) {
      int courtComparison = a.court!.compareTo(b.court!);
      if (courtComparison != 0) {
        return courtComparison;
      }

      int dateComparison = a.date!.compareTo(b.date!);
      if (dateComparison != 0) {
        return dateComparison;
      }

      int startTimeComparison = a.startTime!.compareTo(b.startTime!);
      if (startTimeComparison != 0) {
        return startTimeComparison;
      }

      return a.endTime!.compareTo(b.endTime!);
    });

    List<BookingSlot> mergedSlots = [];
    BookingSlot currentSlot = cartItemsMrg[0];

    for (int i = 1; i < cartItemsMrg.length; i++) {
      BookingSlot nextSlot = cartItemsMrg[i];

      // Check if the next slot can be merged with the current slot
      if (nextSlot.court == currentSlot.court &&
          nextSlot.date == currentSlot.date &&
          nextSlot.startTime!.difference(currentSlot.endTime!) ==
              Duration(minutes: 0) &&
          nextSlot.serviceId == currentSlot.serviceId &&
          nextSlot.subBookingId == currentSlot.subBookingId &&
          nextSlot.repeatGroupId == currentSlot.repeatGroupId) {
        // Extend the current slot's endTime and add price
        currentSlot.endTime = nextSlot.endTime;
        currentSlot.price = (currentSlot.price ?? 0) + (nextSlot.price ?? 0);
      } else {
        // Cannot merge, add the current slot to the mergedSlots list
        mergedSlots.add(currentSlot);
        currentSlot = nextSlot; // Update the current slot to the next slot
      }
    }

    // Add the last slot to the mergedSlots list
    mergedSlots.add(currentSlot);

    return mergedSlots;
  }

  Future<void> buyMembership({
    String? userId,
    String? membershipPlanId,
    String? name,
    double? price,
    String? paymentType,
  }) async {
    try {
      selectedPlan.clear();

      //Insert user membership
      var docRef =
          FirebaseFirestore.instance
              .collection(authController.centerSlug.toString())
              .doc('userMemberships')
              .collection('userMembership')
              .doc();

      await docRef.set({
        'userId': userId.toString(),
        'membershipPlanId': membershipPlanId.toString(),
        'price': price,
        'paymentType': paymentType,
        'paymentStatus': 'Pending', //Status : Pending, Paid, Failed,
        'status': 'InActive', // Status : Active, InActive
        'createdBy': authController.userId.toString(),
        'updatedBy': authController.userId.toString(),
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });

      selectedPlan.add({
        'userId': userId.toString(),
        'userMembershipId': docRef.id,
        'name': name.toString(),
        'price': price!.toDouble(),
      });
      update();
      //selectedId.value = docRef.id;
    } catch (e) {
      print(e.toString());
    } finally {}
  }

  Future<void> getCurrentMembership({String? userId}) async {
    isLoading.value = true;
    currentPlan.clear();
    QuerySnapshot userMembershipSnapshot =
        await FirebaseFirestore.instance
            .collection(authController.centerSlug.toString())
            .doc('userMemberships')
            .collection('userMembership')
            .where('status', isEqualTo: 'Active')
            .where('userId', isEqualTo: userId.toString())
            .get();
    if (userMembershipSnapshot.docs.isNotEmpty) {
      DocumentSnapshot membershipSnapshot =
          await FirebaseFirestore.instance
              .collection(authController.centerSlug.toString())
              .doc('membershipPlans')
              .collection('membershipPlan')
              .doc(userMembershipSnapshot.docs[0]['membershipPlanId'])
              .get();

      DateTime created = userMembershipSnapshot.docs[0]['createdAt'].toDate();
      DateTime endDate = created.add(
        Duration(days: membershipSnapshot['validDays']),
      );

      currentPlan.add({
        'plan': membershipSnapshot['name'],
        'validDays': membershipSnapshot['validDays'],
        'price': userMembershipSnapshot.docs[0]['price'],
        'createdAt': userMembershipSnapshot.docs[0]['createdAt'].toDate(),
        'status': userMembershipSnapshot.docs[0]['status'],
        'remainingDays': DateFormat('dd-MMM-yyyy').format(endDate),
      });
    }
    update();
  }
}
