import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import '../config/palette.dart';
import '../models/booking_model.dart';

class BookingController extends GetxController {

  final String? serviceID;
  final String? serviceName;
  BookingController(this.serviceID,this.serviceName);

  RxBool isLoading                        = false.obs;
  RxBool tableLoading                     = true.obs;
  RxString selectedService                = ''.obs;

  var selectedBooking                     = <Booking>[].obs;
  var selectedBookingSlots                = <BookingSlot>[].obs;
  double? bookingSlotPayments             = null;
  var bookingSlotPaymentList              = <BookingSlotPayments>[].obs;
  RxBool cancelSlotIsLoading              = false.obs;

  final int _itemsPerPage                 = 60;
  DocumentSnapshot? _lastDocument;

  List<BookingSlot> newBookingSlots          = []; // Populate this list with your user data
  List<BookingSlot> filteredNewBookingSlots  = [];
  bool newSortAscending                      = true;
  int  newSortColumnIndex                    = 1;

  List serviceList                           = [];
  List courtList                             = [];

  @override
  void onInit() {
    fetchServiceList();
    fetchCourtList();
    super.onInit();
  }

  void fetchServiceList() async {
    serviceList.clear();
    QuerySnapshot serviceSnapshot = await FirebaseFirestore.instance
        .collection(authController.centerSlug.toString())
        .doc('services')
        .collection('service')
        .where('active',isEqualTo: 1)
        .orderBy('displayOrder',descending: false)
        .get();
    for(var service in serviceSnapshot.docs) {
      serviceList.add({'id':service.id,'name':service['name'],'icon':service['icon']});
    }
    update();
  }

  String getServiceNameById(String serviceId) {
    final service = serviceList.firstWhere((element) => element['id'] == serviceId, orElse: () => null);
    if (service != null) {
      return service['name'] as String;
    } else {
      return 'Loading...';
    }
  }

  void fetchCourtList() async {
    courtList.clear();
    QuerySnapshot courtSnapshot = await FirebaseFirestore.instance
        .collection(authController.centerSlug.toString())
        .doc('courts')
        .collection('court')
        .where('status',isEqualTo: true)
        .get();
    for(var court in courtSnapshot.docs) {
      courtList.add({'id':court.id,'name':court['name']});
    }
    update();
  }

  String getCourtNameById(String courtId) {
    final court = courtList.firstWhere((element) => element['id'] == courtId, orElse: () => null);
    if (court != null) {
      return court['name'] as String;
    } else {
      return 'Loading...';
    }
  }


  //New code

  List<BookingSlot> mergeBookingSlots(List<BookingSlot> cartItemsMrg) {
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
      if (nextSlot.courtId == currentSlot.courtId &&
          nextSlot.date == currentSlot.date &&
          nextSlot.startTime!.difference(currentSlot.endTime!) == Duration(minutes: 0) &&
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

  //search booking slots
  void searchBookingSlots(String query) {
    filteredNewBookingSlots = newBookingSlots.where((slot) {
      final bookingId = slot.bookingId!.toLowerCase();
      final game      = slot.service!.toLowerCase();
      final court     = slot.court!.toLowerCase();
      return bookingId.contains(query.toLowerCase()) || game.contains(query.toLowerCase()) || court.contains(query.toLowerCase());
    }).toList();
    update();
  }

  // sort booking slots column
  void onSortBookingSlotColumn(int columnIndex, bool ascending) {
    if (columnIndex == 0) {
      newBookingSlots.sort((item1, item2) => compareString(ascending, item1.bookingId, item2.bookingId));
      filteredNewBookingSlots.sort((item1, item2) => compareString(ascending, item1.bookingId, item2.bookingId));
    } else if (columnIndex == 1) {
      newBookingSlots.sort((item1, item2) => compareString(ascending, item1.court, item2.court));
      filteredNewBookingSlots.sort((item1, item2) => compareString(ascending, item1.court, item2.court));
    } else if (columnIndex == 2) {
      newBookingSlots.sort((item1, item2) => compareString(ascending, item1.startTime, item2.startTime));
      filteredNewBookingSlots.sort((item1, item2) => compareString(ascending, item1.startTime, item2.startTime));
    } else if (columnIndex == 3) {
      newBookingSlots.sort((item1, item2) => compareString(ascending, item1.endTime, item2.endTime));
      filteredNewBookingSlots.sort((item1, item2) => compareString(ascending, item1.endTime, item2.endTime));
    } else if (columnIndex == 5) {
      newBookingSlots.sort((item1, item2) => compareString(ascending, item1.paymentStatus, item2.paymentStatus));
      filteredNewBookingSlots.sort((item1, item2) => compareString(ascending, item1.paymentStatus, item2.paymentStatus));
    }
    newSortColumnIndex  = columnIndex;
    newSortAscending    = ascending;
    update();
  }

  // get booking slot details
  Future<void> getBookingSlotDetails({String? bookingId,String? subBookingId}) async {

    //Clear Bookings
    selectedBooking.clear();
    List<BookingSlot> bookingSlots = [];

    //Retrieve Booking Data
    DocumentSnapshot bookingSnapshot = await FirebaseFirestore.instance
        .collection(authController.centerSlug.toString())
        .doc('bookings')
        .collection('booking')
        .doc(bookingId)
        .get();

    if (bookingSnapshot.exists) {

      Map<String, dynamic>? booking = bookingSnapshot.data() as Map<String, dynamic>?;

      //Booking Slot query
      QuerySnapshot bookingSlotsSnapshot = await FirebaseFirestore.instance
          .collection(authController.centerSlug.toString())
          .doc('bookingSlots')
          .collection('bookingSlot')
          .where('bookingId',isEqualTo: bookingId.toString())
          .where('subBookingId',isEqualTo: subBookingId.toString())
          .where('status',isEqualTo: 'Booked')
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
          repeatEnd: subDoc['repeatEnd'] !=null ? subDoc['repeatEnd'].toDate() : null,
          repeatId: subDoc['repeatId'],
          repeatGroupId: subDoc['repeatGroupId'],
          paymentStatus: subDoc['paymentStatus'],
          status: subDoc['status'],
          createdBy: subDoc['createdBy'],
          updatedBy: subDoc['updatedBy'],
          createdAt: subDoc['createdAt'].toDate(),
          updatedAt: subDoc['updatedAt'].toDate(),
        );
        bookingSlots.add(bookingSlot);
      }

      selectedBooking.add(Booking(
          bookingId,
          booking!['userId'],
          booking!['name'],
          booking!['mobile'],
          booking!['email'],
          booking!['notes'],
          booking!['subTotal'].toDouble(),
          booking!['discount'].toDouble(),
          booking!['gst'].toDouble(),
          booking!['total'].toDouble(),
          booking!['paymentType'],
          booking!['paymentStatus'],
          booking!['status'],
          bookingSlots,
          booking!['createdBy'],
          booking!['updatedBy'],
          booking!['createdAt'].toDate(),
          booking!['updatedAt'].toDate()
      ));
    }
    isLoading.value = false;
    update();

  }

  //calculate booking slot payments
  Future calculateBookingSlotPayments({String? bookingId,String? subBookingId}) async {
    try {
      bookingSlotPayments=null;
      bookingSlotPaymentList.clear();
      QuerySnapshot bookingSlotPaymentSnapshot = await FirebaseFirestore.instance
          .collection(authController.centerSlug.toString())
          .doc('bookingSlotPayments')
          .collection('bookingSlotPayment')
          .where('bookingId',isEqualTo: bookingId.toString())
          .where('subBookingId',isEqualTo: subBookingId.toString())
          .get();
      if(bookingSlotPaymentSnapshot.docs.isNotEmpty) {

        for(var payment in bookingSlotPaymentSnapshot.docs) {
          bookingSlotPaymentList.add(BookingSlotPayments(
            payment.id,
            payment['bookingPaymentId'],
            payment['bookingId'],
            payment['subBookingId'],
            payment['paymentType'],
            payment['total'].toDouble(),
            payment['paidAmount'].toDouble(),
            payment['balance'].toDouble(),
            payment['status'],
            payment['createdBy'],
            payment['updatedBy'],
            payment['createdAt'].toDate(),
            payment['updatedAt'].toDate(),
          ));
        }

        double paidAmount    = 0;
        double balanceAmount = 0;
        bookingSlotPaymentSnapshot.docs.forEach((doc) {
          paidAmount    += doc['paidAmount']!;
          balanceAmount += doc['balance']!;// Assuming the field is named 'total'
        });
        bookingSlotPayments = paidAmount - balanceAmount;
      } else {
        bookingSlotPayments = 0;
      }
    } catch(e) {
      print(e.toString());
    }
  }

  //cancel booking slots
  Future<void> cancelBookingSlot(subBookingId) async {

    try {

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection(authController.centerSlug.toString())
          .doc('bookingSlots')
          .collection('bookingSlot')
          .where('subBookingId',isEqualTo: subBookingId.toString())
          .where('startTime',isGreaterThanOrEqualTo: DateTime(DateTime.now().year,DateTime.now().month,DateTime.now().day,DateTime.now().hour,DateTime.now().minute))
          .get();

      List<Future<void>> updateFutures = [];
      for (DocumentSnapshot docSnapshot in querySnapshot.docs) {
        updateFutures.add(docSnapshot.reference.update({
          'status': 'Cancelled',
          'updatedBy': authController.userId.toString(),
          'updatedAt': DateTime.now(),
        }));
      }

      await Future.wait(updateFutures);
      showCustomSnackbar('Success', 'Booking Cancelled Successfully', Colors.green);

    } catch (e) {
      print(e.toString());
    } finally {
      cancelSlotIsLoading.value = false;
      update();
      Get.offAllNamed('/');
    }

  }

  //New code

  int compareString(bool ascending, var val1, var val2) => ascending ?  Comparable.compare(val1, val2) : Comparable.compare(val2, val1);

  // Function to get service name from local cache or Firestore
  Future<String> getServiceName(String serviceId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? serviceName = prefs.getString('service_$serviceId');
    if (serviceName == null) {
      // Service name not found in cache, fetch it from Firestore
      DocumentSnapshot serviceDoc =
      await FirebaseFirestore.instance.collection(authController.centerSlug.toString()).doc('services').collection('service').doc(serviceId).get();
      serviceName = serviceDoc['name'];
      prefs.setString('service_$serviceId', serviceName!); // Cache the service name
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
      await FirebaseFirestore.instance.collection(authController.centerSlug.toString()).doc('courts').collection('court').doc(courtId).get();
      courtName = courtDoc['name'];
      prefs.setString('court_$courtId', courtName!); // Cache the court name
    }
    return courtName;
  }

  List<BookingSlot> mergeTimeSlots(List<BookingSlot> cartItems) {
    if (cartItems.isEmpty) return [];

    // Sort the cartItems based on court, date, startTime, and endTime
    cartItems.sort((a, b) {
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
    BookingSlot currentSlot = cartItems[0];

    for (int i = 1; i < cartItems.length; i++) {
      BookingSlot nextSlot = cartItems[i];

      // Check if the next slot can be merged with the current slot
      if (nextSlot.court == currentSlot.court &&
          nextSlot.date == currentSlot.date &&
          nextSlot.startTime!.difference(currentSlot.endTime!) == Duration(minutes: 0) &&
          nextSlot.serviceId == currentSlot.serviceId) {
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

}