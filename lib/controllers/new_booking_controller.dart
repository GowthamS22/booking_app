import 'dart:convert';
import 'dart:ffi';
import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/constants.dart';
import '../config/palette.dart';
import '../models/booking_model.dart';
import '../models/user.dart';
import '../../../config/palette.dart';
import '../../../controllers/new_booking_controller.dart';
import 'package:booking_app/screens/checkout/checkout_screen.dart';

class NewBookingController extends GetxController {
  final supabase = Supabase.instance.client;
  RxBool isLoading = false.obs;
  RxBool checkout = false.obs;
  RxBool paymentProcess = false.obs;
  RxBool onlinePayment = false.obs;

  RxBool courtChangeBtn = false.obs;
  RxBool cancelBookingbtn = false.obs;
  RxBool checkoutPayBtn = false.obs;

  RxBool confirmBtn = false.obs;

  // List mobileList = [];
  List serviceList = [];
  RxList<String> mobileList = <String>[].obs;
  RxString selectedService = ''.obs;
  RxString selectedServiceId = ''.obs;
  RxString selectedBookingId = ''.obs;

  // List courtList = [];
  List specialHoursList = [];
  DateTime selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  //List<BookingSlot> cartItems = [];
  List<BookingSlot> editCartItems = [];
  List<BookingSlot> bookedSlots = [];
  List<BookingSlot> dummyCartItems = [];
  List currentPlan = [];

  List bookingData = [];
  RxDouble discount = RxDouble(0.0);
  RxList<String> timeSlots = <String>[].obs;
  List<Map<String, dynamic>> slots = [];
  RxList<Map<String, dynamic>> courtList = <Map<String, dynamic>>[].obs;

  RxList<Map<String, dynamic>> courtNameLists = <Map<String, dynamic>>[].obs;
  List<Map<String, String>> userList = [];
  Rx<User> userData = User().obs;

  final selectedDays = Set<String>().obs;
  DateTime? repeatUntil;

  var selectedBooking = <Booking>[].obs;

  int startTime = 10;
  int endTime = 24;
  String bookingId = '';
  Timer? _pollingTimer;
  final _bookingSlotsStreamController =
      StreamController<List<BookingSlot>>.broadcast();

  // Add this stream controller
  final _serviceStreamController = StreamController<List<dynamic>>.broadcast();
  Stream<List<dynamic>> get serviceStream => _serviceStreamController.stream;

  var cartItems = <BookingSlot>[].obs;
  // New state for selected slots
  var selectedCourtSlots = <String, List<String>>{}.obs;
  var selectedCourt = Rxn<String>();

  // Method to group selected slots
  Map<String, List<List<String>>> groupSelectedSlots(
    Map<String, List<String>> selected,
  ) {
    Map<String, List<List<String>>> result = {};

    selected.forEach((court, slots) {
      if (slots.isEmpty) return;
      final sortedSlots = [...slots]..sort();
      final grouped = <List<String>>[];

      List<String> currentGroup = [sortedSlots[0]];

      for (int i = 1; i < sortedSlots.length; i++) {
        final prev = sortedSlots[i - 1];
        final curr = sortedSlots[i];

        if (isAdjacent(prev, curr)) {
          // Assuming isAdjacent is also moved or accessible
          currentGroup.add(curr);
        } else {
          grouped.add(currentGroup);
          currentGroup = [curr];
        }
      }

      grouped.add(currentGroup);
      result[court] = grouped;
    });

    return result;
  }

  // Method to clear selected slots
  void clearSelectedSlots() {
    selectedCourtSlots.clear();
    selectedCourt.value = null;
  }

  // Method to check if two slots are adjacent
  bool isAdjacent(String slot1, String slot2) {
    final format = DateFormat.Hm();
    final time1 = format.parse(slot1);
    final time2 = format.parse(slot2);
    return time1.difference(time2).inMinutes.abs() == 30;
  }

  void toggleDay(String day) {
    if (selectedDays.contains(day)) {
      selectedDays.remove(day);
    } else {
      selectedDays.add(day);
    }
    update();
  }

  TextEditingController mobileNumberController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController serviceController = TextEditingController();
  TextEditingController bookingdateController = TextEditingController();

  @override
  void onInit() {
    fetchUserMobile();
    fetchServiceList();
    fetchStartEndTime();
    super.onInit();
    mobileNumberController = TextEditingController();
    bookingdateController = TextEditingController();
  }

  Future<void> fetchUserMobile() async {
    isLoading.value = true;

    final response = await supabase
        .schema('s22_prod_schema')
        .from('customers')
        .select('mobile, first_name');
    // Step 2: Generate a unique booking ID
    final existingBookings = await supabase
        .schema('s22_prod_schema')
        .from('bookings')
        .select('id');
    final int numberOfBookings = existingBookings.length + 1;
    bookingId = 'BOOKING${numberOfBookings.toString().padLeft(3, '0')}';

    if (response != null) {
      userList.clear();
      for (var user in response) {
        userList.add({'name': user['first_name'], 'mobile': user['mobile']});
      }
    }

    isLoading.value = false;
    update();
  }

  Future<void> getUserDatabyMobile(String mobile) async {
    currentPlan.clear();
    try {
      // Step 1: Get user by mobile
      final userResponse =
          await supabase
              .schema('s22_prod_schema')
              .from('customers')
              .select()
              .eq('mobile', mobile)
              .limit(1)
              .maybeSingle();

      if (userResponse != null) {
        // Parse user
        final user = User.fromMap(userResponse);
        userData.value = user;
        userData.value.id = user.id; // Assuming `id` field exists

        final userMembershipId = userResponse['membershipplan_id'];
      } else {
        print('No user found with mobile: $mobile');
      }
    } catch (e) {
      print('Error fetching user: $e');
    } finally {
      update();
    }
  }
  // Future<void> fetchUserMobile() async {
  //   isLoading.value = true;

  //   final response = await supabase
  //       .schema('s22_prod_schema')
  //       .from('customers')
  //       .select('mobile,first_name');

  //   if (response != null) {
  //     mobileList.clear();
  //     for (var user in response) {
  //       mobileList.add(user['mobile']);
  //     }
  //   }

  //   isLoading.value = false;
  //   update();
  // }

  // Future<void> fetchUserMobile() async {
  //   isLoading.value = true;
  //   QuerySnapshot userSnapshot =
  //       await FirebaseFirestore.instance
  //           .collection(authController.centerSlug.toString())
  //           .doc('userDetails')
  //           .collection('user')
  //           .get();
  //   for (var user in userSnapshot.docs) {
  //     mobileList.add(user['mobile']);
  //   }
  //   isLoading.value = false;
  //   update();
  // }

  Future<void> fetchServiceList() async {
    isLoading.value = true;

    try {
      final response = await supabase
          .schema('s22_prod_schema')
          .from('services')
          .select('id, name, icon')
          .eq('active', true)
          .order('display_order', ascending: true);

      if (response != null) {
        serviceList.clear();
        for (var service in response) {
          serviceList.add({
            'id': service['id'],
            'name': service['name'],
            'icon': service['icon'],
          });
        }
        // Add the service list to the stream
        _serviceStreamController.add(serviceList);
        setDefaultSerivce();
      }
    } catch (e) {
      print('Error fetching services: $e');
      _serviceStreamController.addError(e);
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<List<Map<String, dynamic>>> getSlotsWithPeakStatusAndPrice({
    required String serviceId,
    required DateTime selectedDate,
    required List<Map<String, dynamic>> courtList,
  }) async {
    List<Map<String, dynamic>> slots = [];

    try {
      // 1. Fetch specialhours (peak) from services
      final serviceResponse = await supabase
          .schema('s22_prod_schema')
          .from('services')
          .select('specialhours')
          .eq('id', serviceId);

      // 2. Fetch opening_times from store_details
      final storeResponse =
          await supabase
              .schema('s22_prod_schema')
              .from('store_details')
              .select('opening_times')
              .single();

      final today = DateFormat('EEEE').format(selectedDate);

      // 3. Decode opening_times
      final openingTimesRaw = storeResponse['opening_times'];
      final openingTimes = jsonDecode(openingTimesRaw) as List<dynamic>;

      final opening = openingTimes.firstWhere(
        (item) => item['day'] == today,
        orElse: () => null,
      );

      if (opening == null) return [];

      final openStart = parseTimeString(opening['startTime']);
      final openEnd = parseTimeString(opening['endTime']);

      // 4. Get today's peak hours
      final specialHours =
          (serviceResponse.first['specialhours'] ?? []) as List<dynamic>;

      // 5. Generate slots and assign peak/non-peak pricing
      TimeOfDay current = openStart;

      while (current.hour < openEnd.hour ||
          (current.hour == openEnd.hour && current.minute < openEnd.minute)) {
        final slotStart = current;
        final slotEnd = addMinutesToTimeOfDay(current, 30);

        bool isPeak = false;
        double? price;

        for (var sh in specialHours) {
          if (sh['day'] != today) continue;

          final peakStart = parseTimeString(sh['startTime']);
          final peakEnd = parseTimeString(sh['endTime']);

          if (isTimeInRange(slotStart, peakStart, peakEnd)) {
            isPeak = true;
            price = double.tryParse(sh['price'].toString());
            break;
          }
        }

        // If not peak, use courtList to get non-peak price per court
        for (var court in courtList) {
          slots.add({
            'courtId': court['id'],
            'courtName': court['name'],
            'start': slotStart,
            'end': slotEnd,
            'isPeak': isPeak,
            'price': isPeak ? price : court['price'],
          });
        }

        current = slotEnd;
      }

      print('slots: $slots');
    } catch (e) {
      print('Error fetching time slots: $e');
    } finally {
      isLoading.value = false;
      update();
    }

    return slots;
  }

  // Helper: Add minutes to TimeOfDay
  TimeOfDay addMinutesToTimeOfDay(TimeOfDay time, int minutes) {
    final dt = DateTime(
      0,
      0,
      0,
      time.hour,
      time.minute,
    ).add(Duration(minutes: minutes));
    return TimeOfDay(hour: dt.hour, minute: dt.minute);
  }

  // Helper: Check if time is in range
  bool isTimeInRange(TimeOfDay t, TimeOfDay start, TimeOfDay end) {
    final tMinutes = t.hour * 60 + t.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return tMinutes >= startMinutes && tMinutes < endMinutes;
  }

  // void fetchServiceList() async {
  //   isLoading.value = true;
  //   QuerySnapshot serviceSnapshot = await FirebaseFirestore.instance
  //       .collection(authController.centerSlug.toString())
  //       .doc('services')
  //       .collection('service')
  //       .where('active',isEqualTo: 1)
  //       .orderBy('displayOrder',descending: false)
  //       .get();
  //   for(var service in serviceSnapshot.docs) {
  //     serviceList.add({'id':service.id,'name':service['name'],'icon':service['icon']});
  //   }
  //   setDefaultSerivce();
  //   isLoading.value = false;
  //   update();
  // }
  List<String> generateTimeSlots(int startHour, int endHour) {
    List<String> slots = [];
    for (int hour = startHour; hour < endHour; hour++) {
      slots.add('${hour.toString().padLeft(2, '0')}:00');
      slots.add('${hour.toString().padLeft(2, '0')}:30');
    }
    slots.add(
      '${endHour.toString().padLeft(2, '0')}:00',
    ); // Optional: include the end hour
    return slots;
  }

  Future<void> fetchStartEndTime() async {
    isLoading.value = true;

    try {
      if (selectedServiceId.value == null || selectedServiceId.value.isEmpty) {
        isLoading.value = false;
        update();
        return;
      }

      final today = DateFormat('EEEE').format(selectedDate);
      final response = await supabase
          .schema('s22_prod_schema')
          .from('services')
          .select('specialhours')
          .eq('id', selectedServiceId.value);

      if (response != null && response.isNotEmpty) {
        specialHoursList = response.first['specialhours'];

        final todayHours = specialHoursList.firstWhere(
          (item) => item['day'] == today,
          orElse: () => null,
        );

        if (todayHours != null &&
            todayHours['startTime'] != null &&
            todayHours['endTime'] != null) {
          try {
            startTime = parseTimeString(todayHours['startTime']).hour;
            endTime =
                parseTimeString(todayHours['endTime']).hour == 0
                    ? 24
                    : parseTimeString(todayHours['endTime']).hour;

            // Generate time slots
            timeSlots.value = generateTimeSlots(startTime, endTime);
            print("Time slots: $timeSlots");

            // Add the updated data to the stream
            _serviceStreamController.add(serviceList);
          } catch (e) {
            print('Error parsing time: $e');
            showCustomSnackbar('Time parse error', '$e', Colors.red);
          }
        } else {
          print('Missing time data for $todayHours');
        }
      } else {
        showCustomSnackbar('Error : ', response.toString(), Colors.red);
      }
    } catch (e) {
      print('Error fetching time slots: $e');
      _serviceStreamController.addError(e);
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // Utility to parse "6:00 PM" into TimeOfDay
  TimeOfDay parseTimeString(String timeStr) {
    try {
      final cleanedTimeStr =
          timeStr
              .replaceAll(RegExp(r'[\u2000-\u206F\uFE00-\uFEFF\u00A0]'), ' ')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();

      // If the time is in 24-hour format (e.g., "09:00")
      if (!cleanedTimeStr.contains('AM') && !cleanedTimeStr.contains('PM')) {
        final parts = cleanedTimeStr.split(':');
        if (parts.length != 2) {
          throw FormatException('Invalid 24-hour time format');
        }
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }

      // If time includes AM/PM (e.g., "09:00 AM")
      final parts = cleanedTimeStr.split(' ');
      if (parts.length != 2) {
        throw FormatException('Invalid 12-hour time format');
      }

      final timePart = parts[0];
      final period = parts[1].toUpperCase();

      final timeComponents = timePart.split(':');
      if (timeComponents.length != 2) {
        throw FormatException('Invalid 12-hour time format');
      }

      int hour = int.parse(timeComponents[0]);
      int minute = int.parse(timeComponents[1]);

      // Convert to 24-hour format
      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      print('Time parse error: $e for input "$timeStr"');
      return const TimeOfDay(hour: 0, minute: 0); // or a fallback
    }
  }

  // void fetchStartEndTime() async {
  //   isLoading.value = true;
  //   QuerySnapshot openingSnapshot =
  //       await FirebaseFirestore.instance
  //           .collection(authController.centerSlug.toString())
  //           .doc('admins')
  //           .collection('openingTimes')
  //           .where(
  //             'day',
  //             isEqualTo: DateFormat('EEEE').format(selectedDate).toString(),
  //           )
  //           .get();
  //   if (openingSnapshot.docs.isNotEmpty) {
  //     DocumentSnapshot openingDoc = openingSnapshot.docs.first;
  //     startTime = convertTimestampToTimeOfDay(openingDoc['startTime']).hour;
  //     endTime =
  //         convertTimestampToTimeOfDay(openingDoc['endTime']).hour == 0
  //             ? 24
  //             : convertTimestampToTimeOfDay(openingDoc['endTime']).hour;
  //   }
  //   isLoading.value = false;
  //   update();
  // }

  Future<void> setDefaultSerivce() async {
    final response = await supabase
        .schema('s22_prod_schema')
        .from('services')
        .select('id, name')
        .eq('active', true)
        .order('display_order', ascending: true);

    if (response.isNotEmpty) {
      final service = response.first;
      selectedService.value = service['name'];
      selectedServiceId.value = service['id'];
    }
    fetchCourtList();
    update();
  }

  // void setDefaultSerivce() async {
  //   QuerySnapshot serviceSnapshot =
  //       await FirebaseFirestore.instance
  //           .collection(authController.centerSlug.toString())
  //           .doc('services')
  //           .collection('service')
  //           .where('active', isEqualTo: 1)
  //           .orderBy('displayOrder', descending: false)
  //           .get();
  //   if (serviceSnapshot.docs.isNotEmpty) {
  //     DocumentSnapshot serviceDoc = serviceSnapshot.docs.first;
  //     selectedService.value = serviceDoc['name'];
  //     selectedServiceId.value = serviceDoc.id;
  //   }
  //   fetchCourtList();
  //   update();
  // }

  Future<void> fetchCourtList() async {
    isLoading.value = true;

    try {
      if (selectedServiceId.isNotEmpty) {
        final response = await supabase
            .schema('s22_prod_schema')
            .from('courts')
            .select('id, name, price')
            .eq('service_id', selectedServiceId.value)
            .eq('status', true)
            .order('created_at', ascending: true);

        if (response is List) {
          courtList.value =
              response
                  .map<Map<String, dynamic>>(
                    (court) => {
                      'id': court['id'],
                      'name': court['name'],
                      'price': court['price'],
                    },
                  )
                  .toList();

          await fetchSpecialHours();
          await fetchBookedSlots();

          // Add the updated data to the stream
          _serviceStreamController.add(serviceList);
        }
      }
    } catch (e) {
      print('Error fetching court list: $e');
      _serviceStreamController.addError(e);
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // Future<void> fetchCourtList() async {
  //   if (selectedServiceId.isNotEmpty) {
  //     QuerySnapshot courtSnapshot =
  //         await FirebaseFirestore.instance
  //             .collection(authController.centerSlug.toString())
  //             .doc('courts')
  //             .collection('court')
  //             .where('serviceId', isEqualTo: selectedServiceId.toString())
  //             .where('status', isEqualTo: true)
  //             .orderBy('createdAt', descending: false)
  //             .get();
  //     for (var court in courtSnapshot.docs) {
  //       courtList.add({
  //         'id': court.id,
  //         'name': court['name'],
  //         'price': court['price'],
  //       });
  //     }
  //     fetchSpecialHours();
  //     fetechBookedSlots();
  //     isLoading.value = false;
  //     update();
  //   }
  // }
  Future<List<Map<String, dynamic>>> fetchMembershipPlans() async {
    final response = await supabase
        .schema('s22_prod_schema')
        .from('membershipplan')
        .select('*')
        .order('price');
    if (response.isEmpty) {
      throw Exception('No membership plans found');
    }

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> fetchSpecialHours() async {
    if (selectedServiceId.isNotEmpty) {
      final response = await supabase
          .schema('s22_prod_schema')
          .from('services')
          .select()
          .eq('id', selectedServiceId);

      if (response.isNotEmpty) {
        specialHoursList.clear();
        for (var hour in response) {
          final List<dynamic> specials = hour['specialhours'];

          if (specials.isNotEmpty) {
            for (var special in specials) {
              specialHoursList.add({
                'id': hour['id'],
                'specialhours': specials,
                'day': special['day'],
                'dateRange': special['dateRange'],
                'startTime': special['startTime'],
                'endTime': special['endTime'],
                'price': special['price'],
              });
            }
          }
        }
        update();
      } else {
        showCustomSnackbar(
          'Error fetching courts with special hours:',
          response.toString(),
          Colors.redAccent,
        );
        print('Error fetching courts with special hours: ${response}');
      }
    } else {
      showCustomSnackbar(
        'Error :',
        'selectedServiceId is empty',
        Colors.redAccent,
      );
    }
  }

  // Future<void> fetchSpecialHours() async {
  //   if (selectedServiceId.isNotEmpty) {
  //     QuerySnapshot specialHoursSnapshot =
  //         await FirebaseFirestore.instance
  //             .collection(authController.centerSlug.toString())
  //             .doc('specialHours')
  //             .collection('specialHour')
  //             .where('serviceId', isEqualTo: selectedServiceId.toString())
  //             .get();
  //     for (var hour in specialHoursSnapshot.docs) {
  //       specialHoursList.add({
  //         'id': hour.id,
  //         'day': hour['day'],
  //         'dateRange': hour['dateRange'],
  //         'startTime': hour['startTime'],
  //         'endTime': hour['endTime'],
  //         'price': hour['price'],
  //       });
  //     }
  //     update();
  //   }
  // }

  Future<void> fetchBookedSlots() async {
    final startOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final endOfDay = startOfDay.add(Duration(days: 1));

    if (selectedServiceId.isNotEmpty) {
      final response = await supabase
          .schema('s22_prod_schema')
          .from('booking_slots')
          .select('''
          id,
          booking_id,
          service_id,
          court_id,
          start_time,
          end_time,
          price,
          status,
          bookings (
            customer_id,
            customers (
              user_id,
              first_name
            )
          )
        ''')
          .eq('service_id', selectedServiceId)
          .eq('status', 'Booked')
          .gte('start_time', startOfDay.toIso8601String())
          .lt('start_time', endOfDay.toIso8601String())
          .order('start_time', ascending: true);

      final data = response as List<dynamic>;

      bookedSlots.clear();

      for (final booked in data) {
        final booking = booked['bookings'] ?? {};
        final customer = booking['customers'] ?? {};

        bookedSlots.add(
          BookingSlot(
            id: booked['id'],
            userId: customer['user_id'],
            name: customer['first_name'],
            mobile: null, // mobile not joined in this query, include if needed
            date: DateTime.parse(booked['start_time']),
            serviceId: booked['service_id'],
            courtId: booked['court_id'],
            startTime: DateTime.parse(booked['start_time']),
            endTime: DateTime.parse(booked['end_time']),
            price: (booked['price'] as num).toDouble(),
            status: booked['status'],
          ),
        );
      }

      print("bookedSlots : $bookedSlots");
      update();
    }
  }

  // Future<void> fetechBookedSlots() async {
  //   if (selectedServiceId.isNotEmpty) {
  //     QuerySnapshot bookedSlotsSnapshot =
  //         await FirebaseFirestore.instance
  //             .collection(authController.centerSlug.toString())
  //             .doc('bookingSlots')
  //             .collection('bookingSlot')
  //             .where('serviceId', isEqualTo: selectedServiceId.toString())
  //             .where('date', isEqualTo: selectedDate)
  //             .where('status', isEqualTo: 'Booked')
  //             .get();
  //     for (var booked in bookedSlotsSnapshot.docs) {
  //       bookedSlots.add(
  //         BookingSlot(
  //           id: booked.id,
  //           userId: booked['userId'],
  //           name: booked['name'],
  //           mobile: booked['mobile'],
  //           date: booked['date'].toDate(),
  //           serviceId: booked['serviceId'],
  //           courtId: booked['courtId'],
  //           startTime: booked['startTime'].toDate(),
  //           endTime: booked['endTime'].toDate(),
  //           price: booked['price'].toDouble(),
  //           status: booked['status'],
  //         ),
  //       );
  //     }
  //     update();
  //   }
  // }

  Future<void> bookSlot({
    DateTime? date,
    String? service,
    String? serviceId,
    String? court,
    String? courtId,
    DateTime? startTime,
    DateTime? endTime,
    double? price,
  }) async {
    //cartItems.clear();
    //SharedPreferences preferences = await SharedPreferences.getInstance();

    double? finalizedPrice = price;
    //var today = "Monday";
    var today = DateFormat('EEEE').format(date!);
    for (var hour in specialHoursList) {
      TimeOfDay selectedStartTime = TimeOfDay(
        hour: startTime!.hour,
        minute: startTime.minute,
      );
      TimeOfDay selectedEndTime = TimeOfDay(
        hour: endTime!.hour,
        minute: endTime.minute,
      );
      TimeOfDay specialStartTime = parseTimeString(hour['startTime']);
      TimeOfDay specialEndTime = parseTimeString(hour['endTime']);
      // TimeOfDay specialStartTime = convertTimestampToTimeOfDay(
      //   hour['startTime'],
      // );
      // TimeOfDay specialEndTime = convertTimestampToTimeOfDay(hour['endTime']);

      if (hour['day'] == today) {
        int startTimeComparision = compareTimeOfDay(
          selectedStartTime,
          specialStartTime,
        );
        int endTimeComparision = compareTimeOfDay(
          selectedEndTime,
          specialEndTime,
        );

        if (startTimeComparision >= 0 && endTimeComparision <= 0) {
          finalizedPrice = double.parse(hour['price'].toString());
        }
      } else if (hour['day'] == 'All') {
        int startTimeComparision = compareTimeOfDay(
          selectedStartTime,
          specialStartTime,
        );
        int endTimeComparision = compareTimeOfDay(
          selectedEndTime,
          specialEndTime,
        );

        if (startTimeComparision >= 0 && endTimeComparision <= 0) {
          finalizedPrice = hour['price'].toDouble();
        }
      }
    }

    if (currentPlan.length > 0) {
      double tempDiscount =
          finalizedPrice! * (currentPlan[0]['discount'] / 100);
      finalizedPrice = double.parse(
        (finalizedPrice - tempDiscount).toStringAsFixed(2),
      );
    }

    cartItems.add(
      BookingSlot(
        date: date,
        service: service,
        serviceId: serviceId,
        court: court,
        courtId: courtId,
        startTime: startTime,
        endTime: endTime,
        price: finalizedPrice,
      ),
    );
    update();

    /*List<Map<String, dynamic>> cartListJson = cartItems.map((item) => {
      'date': item.date,
      'serviceId': item.serviceId,
      'courtId': item.courtId,
      'startTime': item.startTime,
      'endTime': item.endTime,
    }).toList();
    saveCartList(cartListJson);*/
  }

  void saveCartList(List<Map<String, dynamic>> cartList) async {
    /*SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> cartJsonList = cartList.map((item) => jsonEncode(item)).toList();
    prefs.setStringList('cartList', cartJsonList);
    update();*/
  }

  bool checkBooked({
    DateTime? dateToFind,
    String? serviceIdToFind,
    String? courtIdToFind,
    DateTime? startTimeToFind,
  }) {
    print(
      "bookedSlots : ${dateToFind}','${serviceIdToFind}','${courtIdToFind}','${startTimeToFind}",
    );
    // print('bookingSlots : ${bookedSlots[0]}');
    //print('bookingSlots1 : ${bookedSlots[1]}');
    bool bookingExists = bookedSlots.any(
      (item) =>
          item.date == dateToFind &&
          item.serviceId == serviceIdToFind &&
          item.courtId == courtIdToFind &&
          item.startTime == startTimeToFind,
    );
    print("bookingExists: ${bookingExists}");
    if (bookingExists) {
      return true;
    } else {
      if (isBeforeNow(startTimeToFind!)) {
        return true;
      } else {
        return false;
      }
    }
  }

  String? getBookedId({
    DateTime? dateToFind,
    String? serviceIdToFind,
    String? courtIdToFind,
    DateTime? startTimeToFind,
  }) {
    Iterable<BookingSlot> bookingExists = bookedSlots.where(
      (item) =>
          item.date == dateToFind &&
          item.serviceId == serviceIdToFind &&
          item.courtId == courtIdToFind &&
          item.startTime == startTimeToFind,
    );
    if (bookingExists.isNotEmpty) {
      return bookingExists.first.subBookingId;
    } else {
      return null;
    }
  }

  bool isBeforeNow(DateTime dateTimeToCheck) {
    return dateTimeToCheck.isBefore(DateTime.now());
  }

  bool validateSlot({
    DateTime? dateToFind,
    String? serviceIdToFind,
    String? courtIdToFind,
    DateTime? startTimeToFind,
  }) {
    bool bookingExists = cartItems.any(
      (item) =>
          item.date == dateToFind &&
          item.serviceId == serviceIdToFind &&
          item.courtId == courtIdToFind &&
          item.startTime == startTimeToFind,
    );
    if (bookingExists) {
      return true;
    } else {
      return false;
    }
  }

  void removeSlot({
    DateTime? dateToRemove,
    String? serviceIdToRemove,
    String? courtIdToRemove,
    DateTime? startTimeToRemove,
    DateTime? endTimeToRemove,
  }) {
    BookingSlot removeItem = cartItems.firstWhere(
      (bookingSlot) =>
          bookingSlot.date == dateToRemove &&
          bookingSlot.serviceId == serviceIdToRemove &&
          bookingSlot.courtId == courtIdToRemove &&
          bookingSlot.startTime == startTimeToRemove,
    );
    if (removeItem.slotType == 'Repeated' ||
        removeItem.slotType == 'Repeat-Item') {
      // Remove the BookingSlot that matches the specified values
      cartItems.removeWhere(
        (bookingSlot) => bookingSlot.repeatId == removeItem.repeatId,
      );
    } else {
      // Remove the BookingSlot that matches the specified values
      cartItems.removeWhere(
        (bookingSlot) =>
            bookingSlot.date == dateToRemove &&
            bookingSlot.serviceId == serviceIdToRemove &&
            bookingSlot.courtId == courtIdToRemove &&
            bookingSlot.startTime == startTimeToRemove,
      );
    }
    update();
  }

  void deleteSlot({
    DateTime? dateToRemove,
    String? serviceIdToRemove,
    String? courtIdToRemove,
    DateTime? startTimeToRemove,
    DateTime? endTimeToRemove,
    String? slotTypeToRemove,
    String? repeatGroupIdToRemove,
  }) {
    // Delete the BookingSlot that matches the specified values
    if (slotTypeToRemove == 'Repeated') {
      /*Iterable<BookingSlot> deleteItems = cartItems.where((bookingSlot) =>
          (bookingSlot.startTime!.isAfter(startTimeToRemove!) || bookingSlot.startTime!.isAtSameMomentAs(startTimeToRemove!)) &&
          (bookingSlot.endTime!.isBefore(endTimeToRemove!) || bookingSlot.endTime!.isAtSameMomentAs(endTimeToRemove!)) &&
          bookingSlot.date == dateToRemove &&
          bookingSlot.serviceId == serviceIdToRemove &&
          bookingSlot.courtId == courtIdToRemove
      );

      for(var deleteItem in deleteItems) {
        dummyCartItems.add(deleteItem);
      }

      for(var deleteItem in dummyCartItems) {
        String cleanString    = deleteItem.repeatDays!.replaceAll(RegExp(r'[{}\s]'), '');
        List<String> daysList = cleanString.split(',');
        for(var day in daysList) {
          int dayOfWeek = convertDayStringToDayOfWeek(day.toString());
          List<DateTime> upcomingDays = getUpcomingDays(deleteItem.date!,deleteItem.repeatEnd!,dayOfWeek);
          for(var upcoming in upcomingDays) {
            cartItems.removeWhere((bookingSlot) {

              int finalDay = endTimeToRemove!.hour==0 ? upcoming.day + 1 : upcoming.day ;

              DateTime rmStartTime = DateTime(upcoming.year,upcoming.month,upcoming.day,startTimeToRemove!.hour,startTimeToRemove!.minute);
              DateTime rmEndTime   = DateTime(upcoming.year,upcoming.month,finalDay,endTimeToRemove!.hour,endTimeToRemove!.minute);

              return (
                  (bookingSlot.startTime!.isAfter(rmStartTime!) || bookingSlot.startTime!.isAtSameMomentAs(rmStartTime!)) &&
                  (bookingSlot.endTime!.isBefore(rmEndTime!) || bookingSlot.endTime!.isAtSameMomentAs(rmEndTime!)) &&
                  bookingSlot.date == upcoming &&
                  bookingSlot.serviceId == serviceIdToRemove &&
                  bookingSlot.courtId == courtIdToRemove &&
                  bookingSlot.slotType == 'Repeat-Item'
              );
            });

          }
        }
      }

      cartItems.removeWhere((bookingSlot) {
        return (
            (bookingSlot.startTime!.isAfter(startTimeToRemove!) || bookingSlot.startTime!.isAtSameMomentAs(startTimeToRemove!)) &&
                (bookingSlot.endTime!.isBefore(endTimeToRemove!) || bookingSlot.endTime!.isAtSameMomentAs(endTimeToRemove!)) &&
                bookingSlot.date == dateToRemove &&
                bookingSlot.serviceId == serviceIdToRemove &&
                bookingSlot.courtId == courtIdToRemove
        );
      });
      print(cartItems.length);
      dummyCartItems.clear();
      update();*/
      cartItems.removeWhere(
        (bookingSlot) => bookingSlot.repeatGroupId == repeatGroupIdToRemove,
      );
      update();
    } else {
      cartItems.removeWhere((bookingSlot) {
        return ((bookingSlot.startTime!.isAfter(startTimeToRemove!) ||
                bookingSlot.startTime!.isAtSameMomentAs(startTimeToRemove!)) &&
            (bookingSlot.endTime!.isBefore(endTimeToRemove!) ||
                bookingSlot.endTime!.isAtSameMomentAs(endTimeToRemove!)) &&
            bookingSlot.date == dateToRemove &&
            bookingSlot.serviceId == serviceIdToRemove &&
            bookingSlot.courtId == courtIdToRemove);
      });
      update();
    }
  }

  void clearCart() {
    cartItems.clear();
    update();
  }

  TimeOfDay convertTimestampToTimeOfDay(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp);
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  int compareTimeOfDay(TimeOfDay time1, TimeOfDay time2) {
    if (time1.hour < time2.hour) {
      return -1;
    } else if (time1.hour > time2.hour) {
      return 1;
    } else {
      if (time1.minute < time2.minute) {
        return -1;
      } else if (time1.minute > time2.minute) {
        return 1;
      } else {
        return 0;
      }
    }
  }

  // Future<void> getUserDatabyMobile(String mobile) async {
  //   //isLoading.value = true;
  //   currentPlan.clear();
  //   try {
  //     QuerySnapshot userSnapshot =
  //         await FirebaseFirestore.instance
  //             .collection(authController.centerSlug.toString())
  //             .doc('userDetails')
  //             .collection('user')
  //             .where('mobile', isEqualTo: mobile.toString())
  //             .get();
  //     if (userSnapshot.docs.isNotEmpty) {
  //       DocumentSnapshot userDoc = userSnapshot.docs.first;
  //       userData.value = User.fromDocument(userDoc);
  //       userData.value.id = userDoc.id;

  //       if (userData.value.userMembershipId != null &&
  //           userData.value.userMembershipId != '') {
  //         //Membership
  //         DocumentSnapshot userMembershipSnapshot =
  //             await FirebaseFirestore.instance
  //                 .collection(authController.centerSlug.toString())
  //                 .doc('userMemberships')
  //                 .collection('userMembership')
  //                 .doc(userData.value.userMembershipId.toString())
  //                 .get();
  //         if (userMembershipSnapshot.exists) {
  //           DocumentSnapshot membershipSnapshot =
  //               await FirebaseFirestore.instance
  //                   .collection(authController.centerSlug.toString())
  //                   .doc('membershipPlans')
  //                   .collection('membershipPlan')
  //                   .doc(userMembershipSnapshot['membershipPlanId'])
  //                   .get();
  //           currentPlan.add({
  //             'plan': membershipSnapshot['name'],
  //             'discount': membershipSnapshot['discount'],
  //           });
  //         }
  //       }
  //     } else {}
  //   } catch (e) {
  //     print('Error fetching user: $e');
  //   } finally {
  //     //isLoading.value = false;
  //     update();
  //   }
  // }

  double get totalAmount {
    return cartItems.fold(0, (double sum, BookingSlot bookingSlot) {
      return sum + (bookingSlot.price ?? 0);
    });
  }

  double get gstPrice {
    var gst =
        authController.gst.isEmpty
            ? '0.0'
            : authController.gst.value.toString();
    // return (totalAmount - discount.value) * double.parse(gst) / 100;
    var value = double.parse(
      ((totalAmount - discount.value) * double.parse(gst) / 100).toString(),
    );
    return value;
  }

  double get totalPrice {
    return (totalAmount - discount.value) - gstPrice;
  }

  double get grandtotalPrice {
    return totalPrice + gstPrice;
  }

  double get subTotal {
    return totalAmount;
  }

  void showBookingSuccessAlert() {
    Get.dialog(
      Theme(
        data: ThemeData(
          // Set the overlay color of the AlertDialog
          //backgroundColor: Palette.lightGrey,
          hoverColor: MaterialStateColor.resolveWith((states) {
            return Palette
                .lightGrey; // Replace with the desired color and opacity
          }),
        ),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.all(40),
          //title: Center(child: Text('Booking Success',style: TextStyle(color: Palette.primaryColor,fontSize: 40),)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/icons/check.png', // Replace this with the path to your image
                height: 200,
                width: 200,
              ),
              SizedBox(height: 35),
              Text(
                'Your booking has been successful!',
                style: TextStyle(fontSize: 25),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> registerUser({
    String? email,
    String? firstName,
    String? lastName,
    String? address,
    String? mobile,
    String? postcode,
    String? password, // Only if you store it (not recommended in plain text)
    String? aboutus,
    BuildContext? context,
  }) async {
    try {
      final response =
          await supabase
              .schema('s22_prod_schema')
              .from('customers')
              .insert({
                'user_id': null,
                'email': email,
                'first_name': firstName,
                'last_name': lastName,
                'address': address,
                'mobile': mobile,
                'postcode': postcode,
                'password': password,
                'aboutus': aboutus,
                'date_of_birth': null,
                'city': '',
                'state': '',
                'country': '',
                'profile_picture': '',
                'status': false,
                'created_at': DateTime.now().toIso8601String(),
                //'updated_at': DateTime.now().toIso8601String(),
              })
              .select()
              .single();

      if (response != null) {
        userData.value = User(
          id: response['id'],
          email: response['email'],
          firstName: response['first_name'],
          lastName: response['last_name'],
          address: response['address'],
          mobile: response['mobile'],
          postcode: response['postcode'],
          password: response['password'],
          aboutus: response['aboutus'],
          dateOfBirth: null,
          city: response['city'],
          state: response['state'],
          country: response['country'],
          imageUrl: response['profile_picture'],
          status: response['status'],
          //userMembershipId: response['user_membership_id'],
          createdAt: DateTime.parse(response['created_at']),
          // updatedAt: DateTime.parse(response['updated_at']),
        );
      }
    } catch (e) {
      print("error : $e");
      showCustomSnackbar('Failed', '$e', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  // Future<void> registerUser({
  //   String? email,
  //   String? firstName,
  //   String? lastName,
  //   String? address,
  //   String? mobile,
  //   String? postcode,
  //   String? password,
  //   String? aboutus,
  //   BuildContext? context,
  // }) async {
  //   try {
  //     //Insert data
  //     var docRef =
  //         FirebaseFirestore.instance
  //             .collection(authController.centerSlug.toString())
  //             .doc('userDetails')
  //             .collection('user')
  //             .doc();

  //     docRef.set({
  //       'email': email,
  //       'firstName': firstName,
  //       'lastName': lastName,
  //       'address': address,
  //       'mobile': mobile,
  //       'postcode': postcode,
  //       'password': password,
  //       'aboutus': aboutus,
  //       'dateOfBirth': null,
  //       'city': '',
  //       'state': '',
  //       'country': '',
  //       'imageUrl': '',
  //       'userMembershipId': '',
  //       'verificationStatus': false,
  //       'createdAt': DateTime.now(),
  //       'updatedAt': DateTime.now(),
  //     });

  //     if (docRef.id != '') {
  //       DocumentSnapshot<Map<String, dynamic>> snapshot = await docRef.get();
  //       userData.value = User.fromDocument(snapshot);
  //       userData.value.id = snapshot.id;
  //     }
  //   } catch (e) {
  //     //Status Alert
  //     showCustomSnackbar('Failed', '${e.toString()}', Colors.red);
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

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

  void addRepeatBooking(
    DateTime? startTime,
    DateTime? endTime,
    String? serviceId,
    String? courtId,
    DateTime? date,
    String? repeatGroupId,
  ) {
    try {
      //Remove repeat booking if modify the repeat booking
      if (repeatGroupId != null && repeatGroupId != '') {
        cartItems.removeWhere(
          (bookingSlot) =>
              bookingSlot.repeatGroupId == repeatGroupId &&
              bookingSlot.slotType == 'Repeat-Item',
        );
        update();
      }

      Iterable<BookingSlot> repeatItems = cartItems.where(
        (bookingSlot) =>
            (bookingSlot.startTime!.isAfter(startTime!) ||
                bookingSlot.startTime!.isAtSameMomentAs(startTime!)) &&
            (bookingSlot.endTime!.isBefore(endTime!) ||
                bookingSlot.endTime!.isAtSameMomentAs(endTime!)) &&
            bookingSlot.date == date &&
            bookingSlot.serviceId == serviceId &&
            bookingSlot.courtId == courtId,
      );

      var RepeatGroupId = Uuid().v4();

      for (var repeatItem in repeatItems) {
        repeatItem.slotType = 'Repeated';
        repeatItem.repeatDays = selectedDays.toString();
        repeatItem.repeatEnd = repeatUntil;
        repeatItem.repeatId = Uuid().v4();
        repeatItem.repeatGroupId = RepeatGroupId;
      }

      for (var day in selectedDays) {
        int dayOfWeek = convertDayStringToDayOfWeek(day.toString());
        List<DateTime> upcomingDays = getUpcomingDays(
          date!,
          repeatUntil!,
          dayOfWeek,
        );
        for (var upcoming in upcomingDays) {
          for (var repeatItem in repeatItems) {
            bookRepeatSlot(
              date: upcoming,
              serviceId: repeatItem.serviceId,
              service: repeatItem.service,
              court: repeatItem.court,
              courtId: repeatItem.courtId,
              startTime: DateTime(
                upcoming.year,
                upcoming.month,
                upcoming.day,
                repeatItem.startTime!.hour,
                repeatItem.startTime!.minute,
              ),
              endTime: DateTime(
                upcoming.year,
                upcoming.month,
                upcoming.day,
                repeatItem.endTime!.hour,
                repeatItem.endTime!.minute,
              ),
              price: repeatItem.price,
              slotType: 'Repeat-Item',
              repeatDays: selectedDays.toString(),
              repeatEnd: repeatUntil,
              repeatId: repeatItem.repeatId,
              repeatGroupId: repeatItem.repeatGroupId,
            );
          }
        }
      }

      for (var dummy in dummyCartItems) {
        cartItems.add(dummy);
      }
      //Clear the input values
      dummyCartItems.clear();
      selectedDays.clear();
      repeatUntil = null;

      //Redirect
      Get.back();
    } catch (e) {
    } finally {
      isLoading.value = false;
    }
  }

  List<DateTime> getUpcomingDays(
    DateTime startDate,
    DateTime endDate,
    int dayValue,
  ) {
    List<DateTime> upcomingDays = [];
    DateTime nextDay = startDate;

    while (nextDay.weekday != dayValue) {
      nextDay = nextDay.add(Duration(days: 1));
    }

    if (nextDay.isAtSameMomentAs(startDate)) {
      nextDay = nextDay.add(Duration(days: 7));
    }

    while (nextDay.isBefore(endDate) || nextDay.isAtSameMomentAs(endDate)) {
      upcomingDays.add(nextDay);
      nextDay = nextDay.add(Duration(days: 7));
      while (nextDay.weekday != dayValue) {
        nextDay = nextDay.add(Duration(days: 1));
      }
    }

    return upcomingDays;
  }

  int convertDayStringToDayOfWeek(String dayString) {
    switch (dayString.toLowerCase()) {
      case 'monday':
        return DateTime.monday;
      case 'tuesday':
        return DateTime.tuesday;
      case 'wednesday':
        return DateTime.wednesday;
      case 'thursday':
        return DateTime.thursday;
      case 'friday':
        return DateTime.friday;
      case 'saturday':
        return DateTime.saturday;
      case 'sunday':
        return DateTime.sunday;
      default:
        throw ArgumentError(
          'Invalid dayString. Must be a valid day of the week.',
        );
    }
  }

  void bookRepeatSlot({
    DateTime? date,
    String? service,
    String? serviceId,
    String? court,
    String? courtId,
    DateTime? startTime,
    DateTime? endTime,
    double? price,
    String? slotType,
    String? repeatDays,
    DateTime? repeatEnd,
    String? repeatId,
    String? repeatGroupId,
  }) async {
    double? finalizedPrice = price;
    var today = DateFormat('EEEE').format(date!);
    for (var hour in specialHoursList) {
      TimeOfDay selectedStartTime = TimeOfDay(
        hour: startTime!.hour,
        minute: startTime.minute,
      );
      TimeOfDay selectedEndTime = TimeOfDay(
        hour: endTime!.hour,
        minute: endTime.minute,
      );
      TimeOfDay specialStartTime = convertTimestampToTimeOfDay(
        hour['startTime'],
      );
      TimeOfDay specialEndTime = convertTimestampToTimeOfDay(hour['endTime']);

      if (hour['day'] == today) {
        int startTimeComparision = compareTimeOfDay(
          selectedStartTime,
          specialStartTime,
        );
        int endTimeComparision = compareTimeOfDay(
          selectedEndTime,
          specialEndTime,
        );

        if (startTimeComparision >= 0 && endTimeComparision <= 0) {
          finalizedPrice = hour['price'].toDouble();
        }
      } else if (hour['day'] == 'All') {
        int startTimeComparision = compareTimeOfDay(
          selectedStartTime,
          specialStartTime,
        );
        int endTimeComparision = compareTimeOfDay(
          selectedEndTime,
          specialEndTime,
        );

        if (startTimeComparision >= 0 && endTimeComparision <= 0) {
          finalizedPrice = hour['price'].toDouble();
        }
      }
    }

    if (currentPlan.length > 0) {
      double tempDiscount =
          finalizedPrice! * (currentPlan[0]['discount'] / 100);
      finalizedPrice = double.parse(
        (finalizedPrice - tempDiscount).toStringAsFixed(2),
      );
    }

    dummyCartItems.add(
      BookingSlot(
        date: date,
        service: service,
        serviceId: serviceId,
        court: court,
        courtId: courtId,
        startTime: startTime,
        endTime: endTime,
        price: finalizedPrice,
        slotType: slotType,
        repeatDays: repeatDays,
        repeatEnd: repeatEnd,
        repeatId: repeatId,
        repeatGroupId: repeatGroupId,
      ),
    );
    update();
  }

  Future<void> validatePromocode(String promoCode) async {
    try {
      final QuerySnapshot discountSnapshot =
          await FirebaseFirestore.instance
              .collection(authController.centerSlug.toString())
              .doc('discounts')
              .collection('discount')
              .where('code', isEqualTo: promoCode.toString())
              .where('expireAt', isGreaterThanOrEqualTo: Timestamp.now())
              .where('active', isEqualTo: 1)
              .get();

      if (discountSnapshot.docs.isNotEmpty) {
        for (var doc in discountSnapshot.docs) {
          var code = doc['code'];
          final QuerySnapshot couponUsageSnapshot =
              await FirebaseFirestore.instance
                  .collection(authController.centerSlug.toString())
                  .doc('couponUsages')
                  .collection('couponUsage')
                  .where('userId', isEqualTo: authController.userId.toString())
                  .where('couponId', isEqualTo: code.toString())
                  .get();
          if (couponUsageSnapshot.docs.isEmpty) {
            if (doc['discountType'] == 'Fixed') {
              discount.value = doc['discount'];
            } else {
              discount.value = totalAmount / 100 * doc['discount'];
            }
            showCustomSnackbar('Success', 'Promo Applied ', Colors.green);
          } else {
            discount.value = 0;
            showCustomSnackbar('Failed', 'Promo Already Used', Colors.red);
          }
        }
      } else {
        discount.value = 0;
        showCustomSnackbar('Failed', 'Invalid Promo Code', Colors.red);
      }
    } catch (e) {
      print(e.toString());
    } finally {
      isLoading.value = false;
      update();
    }
  }

  //On click Confirm Booking
  Future<void> processCheckout({
    String? name,
    String? mobile,
    String? email,
    String? notes,
    String? promoCode,
    String? paymentType,
    String? bookingId,
  }) async {
    try {
      // Step 1: Validate slot availability
      bool isValid = await bulkValidateSlots(selectedBSlots: cartItems);
      if (!isValid) {
        showCustomSnackbar(
          'Failed',
          'Some bookings are not available',
          Colors.red,
        );
        confirmBtn.value = false;
        isLoading.value = false;
        update();
        return;
      }

      // Step 2: Generate a unique booking ID
      // final existingBookings = await supabase
      //     .schema('s22_prod_schema')
      //     .from('bookings')
      //     .select('id');
      // final int numberOfBookings = existingBookings.length + 1;
      // final String bookingId =
      //     'BOOKING${numberOfBookings.toString().padLeft(3, '0')}';

      // Step 3: Insert booking record
      final bookingInsertResponse =
          await supabase
              .schema('s22_prod_schema')
              .from('bookings')
              .insert({
                'booking_no': bookingId,
                'customer_id': userData.value.id.toString(),
                //'name': name,
                // 'mobile': mobile,
                //'email': email,
                'surcharge': 0.0,
                'grand_total': grandtotalPrice,
                'notes': notes,
                'sub_total': subTotal,
                'discount': discount.value,
                'gst': gstPrice,
                'total': grandtotalPrice,
                'payment_type': paymentType,
                'payment_status': 'Pending',
                'status': 'Booked',
                'created_by': authController.userId.toString(),
                'updated_by': authController.userId.toString(),
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
                // 'deleted_at':null,
                // 'deleted_by':authController.userId
              })
              .select()
              .single();
      print("bookingInsertResponse : $bookingInsertResponse");
      print("bookingInsertResponseID : ${bookingInsertResponse['id']}");
      final insertedBookingId = bookingInsertResponse['id'];

      // Step 4: Insert booking slots
      List<Map<String, dynamic>> slotData =
          cartItems.map((slot) {
            return {
              'booking_id': insertedBookingId,
              'service_id': slot.serviceId,
              'court_id': slot.courtId,
              'start_time': slot.startTime!.toIso8601String(),
              'end_time': slot.endTime!.toIso8601String(),
              'price': slot.price,
              'slot_type': slot.slotType,
              'repeat_days': slot.repeatDays,
              'repeat_end_date': slot.repeatEnd?.toIso8601String(),
              'repeat_id': slot.repeatId,
              'repeat_group_id': slot.repeatGroupId,
              //'payment_status': 'Pending',
              'status': 'Booked',
              'created_by': authController.userId.toString(),
              'updated_by': authController.userId.toString(),
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            };
          }).toList();
      print('slotData: $slotData');
      try {
        await supabase
            .schema('s22_prod_schema')
            .from('booking_slots')
            .insert(slotData);
        print('Booking slots inserted successfully.');
      } catch (error) {
        print('Error inserting booking slots: $error');
      }

      // Post-insertion operations
      cartItems.clear();
      confirmBtn.value = false;
      showBookingSuccessAlert();
      fetchBookedSlots();
      isLoading.value = false;
      update();

      // Redirect to home page
      Future.delayed(Duration(seconds: 1), () {
        Get.offAllNamed('/');
      });
    } catch (e) {
      print('Error : $e');
      showCustomSnackbar('Failed', e.toString(), Palette.dangerTxt);
    }
  }

  // Future<void> processCheckout({
  //   String? name,
  //   String? mobile,
  //   String? email,
  //   String? notes,
  //   String? promoCode,
  //   String? paymentType,
  // }) async {
  //   try {
  //     Future<bool> validation = bulkValidateSlots(selectedBSlots: cartItems);
  //     if (await validation == false) {
  //       showCustomSnackbar(
  //         'Failed',
  //         'Some bookings are not Available',
  //         Colors.red,
  //       );

  //       //Update the confirm status
  //       confirmBtn.value = false;

  //       //Update the Page
  //       isLoading.value = false;
  //       update();
  //     } else {
  //       // Reference to the bookings collection
  //       final QuerySnapshot snapshot =
  //           await FirebaseFirestore.instance
  //               .collection(authController.centerSlug.toString())
  //               .doc('bookings')
  //               .collection('booking')
  //               .get();
  //       final int numberOfBookings = snapshot.size + 1;
  //       // Generate the custom booking ID in the format "BOOKING001"
  //       final String bookingId =
  //           'BOOKING${numberOfBookings.toString().padLeft(3, '0')}';

  //       //Insert Booking
  //       var docRef = FirebaseFirestore.instance
  //           .collection(authController.centerSlug.toString())
  //           .doc('bookings')
  //           .collection('booking')
  //           .doc(bookingId);

  //       await docRef
  //           .set({
  //             //userId': userData.value.id,
  //             'name': name,
  //             'mobile': mobile,
  //             'email': email,
  //             'notes': notes,
  //             'subTotal': subTotal!.toDouble(),
  //             'discount': discount.value!.toDouble(),
  //             'gst': gstPrice!.toDouble(),
  //             'total': grandtotalPrice!.toDouble(),
  //             'paymentType': paymentType,
  //             'paymentStatus': 'Pending',
  //             //Status : Pending, Paid, Partially, Failed, Refunded
  //             'status': 'Booked',
  //             // Status : Booked, Cancelled
  //             'createdBy': authController.userId.toString(),
  //             'updatedBy': authController.userId.toString(),
  //             'createdAt': DateTime.now(),
  //             'updatedAt': DateTime.now(),
  //           })
  //           .then((value) async {
  //             //Insert Booking Slots
  //             WriteBatch batch = FirebaseFirestore.instance.batch();
  //             for (var slot in cartItems) {
  //               DocumentReference docRefs =
  //                   await FirebaseFirestore.instance
  //                       .collection(authController.centerSlug.toString())
  //                       .doc('bookingSlots')
  //                       .collection('bookingSlot')
  //                       .doc();
  //               batch.set(docRefs, {
  //                 'bookingId': docRef.id,
  //                 'subBookingId': slot.subBookingId,
  //                 //'userId': userData.value.id,
  //                 'name': name,
  //                 'mobile': mobile,
  //                 'date': slot.date,
  //                 'serviceId': slot.serviceId,
  //                 'courtId': slot.courtId,
  //                 'startTime': slot.startTime,
  //                 'endTime': slot.endTime,
  //                 'price': slot.price!.toDouble(),
  //                 'slotType': slot.slotType,
  //                 'repeatDays': slot.repeatDays.toString(),
  //                 'repeatEnd': slot.repeatEnd,
  //                 'repeatId': slot.repeatId,
  //                 'repeatGroupId': slot.repeatGroupId,
  //                 'paymentStatus': 'Pending',
  //                 'status': 'Booked',
  //                 'createdBy': authController.userId.toString(),
  //                 'updatedBy': authController.userId.toString(),
  //                 'createdAt': DateTime.now(),
  //                 'updatedAt': DateTime.now(),
  //               });
  //             }
  //             await batch.commit();
  //           });

  //       final DocumentSnapshot<Map<String, dynamic>> completedBooking =
  //           await docRef.get();

  //       //Print Receipt

  //       //Clear Cart Items
  //       cartItems.clear();

  //       //Update the confirm status
  //       confirmBtn.value = false;

  //       //Status Alert
  //       showBookingSuccessAlert();

  //       //Re initiate bookings
  //       fetchBookedSlots();

  //       //Update the Page
  //       isLoading.value = false;
  //       update();

  //       //Redirect
  //       Future.delayed(Duration(seconds: 1), () {
  //         Get.offAllNamed('/');
  //       });
  //     }
  //   } catch (e) {
  //     showCustomSnackbar('Failed', '${e.toString()}', Palette.dangerTxt);
  //   } finally {}
  // }

  double calculateRepeatPrice({String? repeatGroupId}) {
    double totalPrice = 0;
    Iterable<BookingSlot> calcItems = cartItems.where(
      (bookingSlot) => bookingSlot.repeatGroupId == repeatGroupId,
    );
    for (var re in calcItems) {
      totalPrice += re.price!;
    }
    return totalPrice;
  }

  // Future<void> getBookingData({
  //   required bookingId,
  //   List<BookingSlot>? selectedBSlots,
  // }) async {
  //   //Clear Bookings
  //   cartItems.clear();
  //   selectedBooking.clear();
  //   List<BookingSlot> bookingSlots = [];

  //   //Retrieve Booking Data
  //   DocumentSnapshot bookingSnapshot =
  //       await FirebaseFirestore.instance
  //           .collection(authController.centerSlug.toString())
  //           .doc('bookings')
  //           .collection('booking')
  //           .doc(bookingId)
  //           .get();

  //   if (bookingSnapshot.exists) {
  //     Map<String, dynamic>? booking =
  //         bookingSnapshot.data() as Map<String, dynamic>?;

  //     if (selectedBSlots!.length > 0) {
  //       selectedBooking.add(
  //         Booking(
  //           bookingId,
  //           booking!['booking_no'],
  //           booking!['customer_id'],
  //           booking!['name'],
  //           booking!['mobile'],
  //           booking!['email'],
  //           booking!['notes'],
  //           booking!['subTotal'].toDouble(),
  //           booking!['discount'].toDouble(),
  //           booking!['gst'].toDouble(),
  //           booking!['total'].toDouble(),
  //           booking!['paymentType'],
  //           booking!['paymentStatus'],
  //           booking!['status'],
  //           selectedBSlots,
  //           booking!['createdBy'],
  //           booking!['updatedBy'],
  //           booking!['createdAt'].toDate(),
  //           booking!['updatedAt'].toDate(),
  //         ),
  //       );
  //       for (BookingSlot singleSlot in selectedBSlots) {
  //         cartItems.add(singleSlot);
  //       }
  //     } else {
  //       //Booking Slot query
  //       QuerySnapshot bookingSlotsSnapshot =
  //           await FirebaseFirestore.instance
  //               .collection(authController.centerSlug.toString())
  //               .doc('bookingSlots')
  //               .collection('bookingSlot')
  //               .where('bookingId', isEqualTo: bookingId.toString())
  //               .get();

  //       //Store the booking slot in model
  //       for (DocumentSnapshot subDoc in bookingSlotsSnapshot.docs) {
  //         String serviceId = subDoc['serviceId'];
  //         String courtId = subDoc['courtId'];

  //         String serviceName = await getServiceName(serviceId);
  //         String courtName = await getCourtName(courtId);

  //         BookingSlot bookingSlot = BookingSlot(
  //           id: subDoc.id,
  //           userId: subDoc['userId'],
  //           name: subDoc['name'],
  //           mobile: subDoc['mobile'],
  //           date: subDoc['date'].toDate(),
  //           service: serviceName,
  //           serviceId: subDoc['serviceId'],
  //           court: courtName,
  //           courtId: subDoc['courtId'],
  //           startTime: subDoc['startTime'].toDate(),
  //           endTime: subDoc['endTime'].toDate(),
  //           price: subDoc['price'].toDouble(),

  //           slotType: subDoc['slotType'],
  //           repeatDays: subDoc['repeatDays'],
  //           repeatEnd:
  //               subDoc['repeatEnd'] != null
  //                   ? subDoc['repeatEnd'].toDate()
  //                   : null,
  //           repeatId: subDoc['repeatId'],
  //           repeatGroupId: subDoc['repeatGroupId'],

  //           paymentStatus: subDoc['paymentStatus'],
  //           status: subDoc['status'],
  //           createdAt: subDoc['createdAt'].toDate(),
  //           updatedAt: subDoc['updatedAt'].toDate(),
  //           createdBy: subDoc['createdBy'],
  //           updatedBy: subDoc['updatedBy'],
  //         );
  //         bookingSlots.add(bookingSlot);
  //         cartItems.add(bookingSlot);
  //       }
  //       selectedBooking.add(
  //         Booking(
  //           bookingId,
  //           booking!['booking_no'],
  //           booking!['customer_id'],
  //           booking!['name'],
  //           booking!['mobile'],
  //           booking!['email'],
  //           booking!['notes'],
  //           booking!['subTotal'].toDouble(),
  //           booking!['discount'].toDouble(),
  //           booking!['gst'].toDouble(),
  //           booking!['total'].toDouble(),
  //           booking!['paymentType'],
  //           booking!['paymentStatus'],
  //           booking!['status'],
  //           bookingSlots,
  //           booking!['createdBy'],
  //           booking!['updatedBy'],
  //           booking!['createdAt'].toDate(),
  //           booking!['updatedAt'].toDate(),
  //         ),
  //       );
  //     }
  //   }
  //   isLoading.value = false;
  //   update();
  // }

  Future<void> getBookingData({
    required String bookingId,
    List<BookingSlot>? selectedBSlots,
  }) async {
    // Clear previous booking data
    cartItems.clear();
    selectedBooking.clear();
    List<BookingSlot> bookingSlots = [];

    // Retrieve booking data from Supabase
    final bookingResponse =
        await supabase.from('bookings').select().eq('id', bookingId).single();

    if (bookingResponse.isEmpty) {
      print('Error fetching booking: $bookingResponse');
      isLoading.value = false;
      update();
      return;
    }

    final booking = bookingResponse;

    if (selectedBSlots != null && selectedBSlots.isNotEmpty) {
      selectedBooking.add(
        Booking(
          bookingId,
          booking['booking_no'],
          booking['customer_id'],
          booking['name'],
          booking['mobile'],
          booking['email'],
          booking['notes'],
          booking['subTotal'].toDouble(),
          booking['discount'].toDouble(),
          booking['gst'].toDouble(),
          booking['total'].toDouble(),
          booking['paymentType'],
          booking['paymentStatus'],
          booking['status'],
          selectedBSlots,
          booking['createdBy'],
          booking['updatedBy'],
          DateTime.parse(booking['createdAt']),
          DateTime.parse(booking['updatedAt']),
        ),
      );
      cartItems.addAll(selectedBSlots);
    } else {
      // Fetch booking slots associated with this booking
      final slotsResponse = await supabase
          .from('booking_slots')
          .select()
          .eq('bookingId', bookingId);

      if (slotsResponse.isEmpty) {
        print('Error fetching booking slots: $slotsResponse');
        isLoading.value = false;
        update();
        return;
      }

      for (final subDoc in slotsResponse) {
        String serviceName = await getServiceName(subDoc['serviceId']);
        String courtName = await getCourtName(subDoc['courtId']);

        final bookingSlot = BookingSlot(
          id: subDoc['id'],
          userId: subDoc['userId'],
          name: subDoc['name'],
          mobile: subDoc['mobile'],
          date: DateTime.parse(subDoc['date']),
          service: serviceName,
          serviceId: subDoc['serviceId'],
          court: courtName,
          courtId: subDoc['courtId'],
          startTime: DateTime.parse(subDoc['startTime']),
          endTime: DateTime.parse(subDoc['endTime']),
          price: subDoc['price'].toDouble(),
          slotType: subDoc['slotType'],
          repeatDays: subDoc['repeatDays'],
          repeatEnd:
              subDoc['repeatEnd'] != null
                  ? DateTime.parse(subDoc['repeatEnd'])
                  : null,
          repeatId: subDoc['repeatId'],
          repeatGroupId: subDoc['repeatGroupId'],
          paymentStatus: subDoc['paymentStatus'],
          status: subDoc['status'],
          createdAt: DateTime.parse(subDoc['createdAt']),
          updatedAt: DateTime.parse(subDoc['updatedAt']),
          createdBy: subDoc['createdBy'],
          updatedBy: subDoc['updatedBy'],
        );
        bookingSlots.add(bookingSlot);
        cartItems.add(bookingSlot);
      }

      selectedBooking.add(
        Booking(
          bookingId,
          booking['booking_no'],
          booking['customer_id'],
          booking['name'],
          booking['mobile'],
          booking['email'],
          booking['notes'],
          booking['subTotal'].toDouble(),
          booking['discount'].toDouble(),
          booking['gst'].toDouble(),
          booking['total'].toDouble(),
          booking['paymentType'],
          booking['paymentStatus'],
          booking['status'],
          bookingSlots,
          booking['createdBy'],
          booking['updatedBy'],
          DateTime.parse(booking['createdAt']),
          DateTime.parse(booking['updatedAt']),
        ),
      );
    }

    isLoading.value = false;
    update();
  }

  Future<void> getBookingSlotData({List<BookingSlot>? selectedBSlots}) async {
    //Clear Bookings
    cartItems.clear();
    editCartItems.clear();
    for (BookingSlot singleSlot in selectedBSlots!) {
      cartItems.add(singleSlot);
      editCartItems.add(singleSlot);
    }
    isLoading.value = false;
    update();
  }

  // Function to get service name from local cache or Firestore

  Future<String> getServiceName(String serviceId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? serviceName = prefs.getString('service_$serviceId');

    if (serviceName == null) {
      final response =
          await supabase
              .schema('s22_prod_schema')
              .from('services')
              .select('name')
              .eq('id', serviceId)
              .single();

      if (response != null && response['name'] != null) {
        serviceName = response['name'];
        prefs.setString('service_$serviceId', serviceName!);
      } else {
        throw Exception('Service not found in Supabase');
      }
    }

    return serviceName;
  }
  // Future<String> getServiceName(String serviceId) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String? serviceName = prefs.getString('service_$serviceId');
  //   if (serviceName == null) {
  //     // Service name not found in cache, fetch it from Firestore
  //     DocumentSnapshot serviceDoc =
  //         await FirebaseFirestore.instance
  //             .collection(authController.centerSlug.toString())
  //             .doc('services')
  //             .collection('service')
  //             .doc(serviceId)
  //             .get();
  //     serviceName = serviceDoc['name'];
  //     prefs.setString(
  //       'service_$serviceId',
  //       serviceName!,
  //     ); // Cache the service name
  //   }
  //   return serviceName;
  // }

  // Function to get court name from local cache or Firestore

  Future<String> getCourtName(String courtId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? courtName = prefs.getString('court_$courtId');

    if (courtName == null) {
      final response =
          await supabase
              .schema('s22_prod_schema')
              .from('courts')
              .select('name')
              .eq('id', courtId)
              .single();

      if (response != null && response['name'] != null) {
        courtName = response['name'];
        prefs.setString('court_$courtId', courtName!);
      } else {
        throw Exception('Court not found in Supabase');
      }
    }

    return courtName;
  }
  // Future<String> getCourtName(String courtId) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String? courtName = prefs.getString('court_$courtId');
  //   if (courtName == null) {
  //     // Court name not found in cache, fetch it from Firestore
  //     DocumentSnapshot courtDoc =
  //         await FirebaseFirestore.instance
  //             .collection(authController.centerSlug.toString())
  //             .doc('courts')
  //             .collection('court')
  //             .doc(courtId)
  //             .get();
  //     courtName = courtDoc['name'];
  //     prefs.setString('court_$courtId', courtName!); // Cache the court name
  //   }
  //   return courtName;
  // }

  Future<void> updateBookingSlots({String? name}) async {
    try {
      for (var item in editCartItems!) {
        QuerySnapshot querySnapshot =
            await FirebaseFirestore.instance
                .collection(authController.centerSlug.toString())
                .doc('bookingSlots')
                .collection('bookingSlot')
                .where('subBookingId', isEqualTo: item.subBookingId.toString())
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

      //Insert Booking Slots
      WriteBatch insertBatch = FirebaseFirestore.instance.batch();
      for (var slot in cartItems) {
        DocumentReference docRefs =
            await FirebaseFirestore.instance
                .collection(authController.centerSlug.toString())
                .doc('bookingSlots')
                .collection('bookingSlot')
                .doc();
        insertBatch.set(docRefs, {
          'bookingId': editCartItems[0].bookingId,
          'subBookingId': slot.subBookingId,
          'userId': editCartItems[0].userId,
          'name': editCartItems[0].name,
          'mobile': editCartItems[0].mobile,
          'date': slot.date,
          'serviceId': slot.serviceId,
          'courtId': slot.courtId,
          'startTime': slot.startTime,
          'endTime': slot.endTime,
          'price': slot.price!.toDouble(),
          'slotType': slot.slotType,
          'repeatDays': slot.repeatDays.toString(),
          'repeatEnd': slot.repeatEnd,
          'repeatId': slot.repeatId,
          'repeatGroupId': slot.repeatGroupId,
          'paymentStatus': 'Pending',
          'status': 'Booked',
          'createdBy': authController.userId.toString(),
          'updatedBy': authController.userId.toString(),
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        });
      }
      //Execute Insert
      await insertBatch.commit();

      //Clear Cart Items
      cartItems.clear();

      //Update the confirm status
      confirmBtn.value = false;

      //Status Alert
      showBookingSuccessAlert();

      //Re initiate bookings
      fetchBookedSlots();

      //Update the Page
      isLoading.value = false;
      update();

      //Redirect
      Future.delayed(Duration(seconds: 1), () {
        Get.offAllNamed('/');
      });
    } catch (e) {
      showCustomSnackbar('Failed', '${e.toString()}', Palette.dangerTxt);
    } finally {}
  }

  void printReceipt() async {
    final profile = await CapabilityProfile.load();
    final printer = NetworkPrinter(PaperSize.mm80, profile);

    final printerIp = '192.168.1.100';
    final PosPrintResult res = await printer.connect(printerIp, port: 9100);

    if (res != PosPrintResult.success) {
      showCustomSnackbar(
        'Printer Error',
        'Failed to connect to the printer.',
        Colors.red,
      );
      return;
    }

    final storeName = 'My Store';
    final storeAddress = '123 Main Street, City';
    final storeMobile = 'Phone: 123-456-7890';
    final orderItems = ['1 x Item A    \$10.00', '2 x Item B    \$15.00'];
    final total = 'Total:        \$25.00';

    // Print header with store information
    printer.text(
      '$storeName\n$storeAddress\n$storeMobile\n',
      styles: PosStyles(align: PosAlign.center),
    );

    // Print logo (if available)
    // Replace 'logo.png' with your actual logo file path
    // final ByteData data = await rootBundle.load('assets/logo.png');
    // final Uint8List logoBytes = data.buffer.asUint8List();
    // printer.image(logoBytes);

    // Print order items
    for (var item in orderItems) {
      printer.text(item);
    }

    // Print total
    printer.text(total, styles: PosStyles(align: PosAlign.right));

    printer.cut();
    printer.disconnect();

    showCustomSnackbar(
      'Print Successful',
      'The receipt has been printed successfully.',
      Colors.green,
    );
  }

  String repeatDays({String? repeatDays}) {
    List<String> fullDays = repeatDays!
        .replaceAll(RegExp(r'[{} ]'), '')
        .split(','); // Remove curly braces and split into a list
    print(fullDays);
    Map<String, String> dayAbbreviations = {
      'Monday': 'Mon',
      'Tuesday': 'Tue',
      'Wednesday': 'Wed',
      'Thursday': 'Thu',
      'Friday': 'Fri',
      'Saturday': 'Sat',
      'Sunday': 'Sun',
      // Add abbreviations for other days if needed
    };

    String abbreviatedDays = fullDays
        .map((day) {
          return dayAbbreviations.containsKey(day)
              ? dayAbbreviations[day]
              : day;
        })
        .join(', ');
    return abbreviatedDays;
  }

  Future<void> updateBooking({
    required bookingId,
    List<BookingSlot>? selectedBSlots,
  }) async {
    try {
      /*WriteBatch batch = FirebaseFirestore.instance.batch();

      for (BookingSlot bSlot in selectedBSlots) {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection(authController.centerSlug.toString())
            .doc('bookingSlots')
            .collection('bookingSlot')
            .where('subBookingId', isEqualTo: bSlot.subBookingId.toString())
            .get();

        querySnapshot.docs.forEach((docSnapshot) {
          batch.delete(docSnapshot.reference);
        });
      }*/

      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (BookingSlot bSlot in selectedBSlots!) {
        QuerySnapshot querySnapshot =
            await FirebaseFirestore.instance
                .collection(authController.centerSlug.toString())
                .doc('bookingSlots')
                .collection('bookingSlot')
                .where('subBookingId', isEqualTo: bSlot.subBookingId.toString())
                .get();

        querySnapshot.docs.forEach((docSnapshot) {
          batch.update(docSnapshot.reference, {
            'status': 'Cancelled',
            'updatedBy': authController.userId.toString(),
            'updatedAt': DateTime.now(),
          });
        });
      }

      // Commit the batch
      await batch.commit().then((value) async {
        //Insert Booking Slots
        WriteBatch insertBatch = FirebaseFirestore.instance.batch();
        for (var slot in cartItems) {
          DocumentReference docRefs =
              await FirebaseFirestore.instance
                  .collection(authController.centerSlug.toString())
                  .doc('bookingSlots')
                  .collection('bookingSlot')
                  .doc();
          insertBatch.set(docRefs, {
            'bookingId': bookingId,
            'subBookingId': slot.subBookingId,
            // 'userId': userData.value.id,
            'name': slot.name,
            'mobile': slot.mobile,
            'date': slot.date,
            'serviceId': slot.serviceId,
            'courtId': slot.courtId,
            'startTime': slot.startTime,
            'endTime': slot.endTime,
            'price': slot.price,
            'slotType': slot.slotType,
            'repeatDays': slot.repeatDays.toString(),
            'repeatEnd': slot.repeatEnd,
            'repeatId': slot.repeatId,
            'repeatGroupId': slot.repeatGroupId,
            'paymentStatus': 'Pending',
            'status': 'Booked',
            'createdBy': authController.userId.toString(),
            'updatedBy': authController.userId.toString(),
            'createdAt': DateTime.now(),
            'updatedAt': DateTime.now(),
          });
        }
        //Execute Insert
        await insertBatch.commit();
      });

      //Clear Cart Items
      cartItems.clear();

      //Update the confirm status
      confirmBtn.value = false;

      //Status Alert
      showBookingSuccessAlert();

      //Re initiate bookings
      fetchBookedSlots();

      //Update the Page
      isLoading.value = false;
      update();

      //Redirect
      Future.delayed(Duration(seconds: 1), () {
        Get.offAllNamed('/');
      });
    } catch (e) {
      showCustomSnackbar('Failed', '${e.toString()}', Palette.dangerTxt);
    } finally {}
  }

  Future<bool> bulkValidateSlots({List<BookingSlot>? selectedBSlots}) async {
    int matchingSlotCount = 0;

    for (var item in selectedBSlots!) {
      final response = await supabase
          .schema('s22_prod_schema')
          .from('booking_slots')
          .select('id')
          .eq('service_id', item.serviceId!)
          .eq('court_id', item.courtId!)
          .eq('start_time', item.startTime!.toIso8601String())
          .eq('status', 'Booked');

      matchingSlotCount += (response as List).length;
    }

    return matchingSlotCount == 0;
  }

  // Future<bool> bulkValidateSlots({List<BookingSlot>? selectedBSlots}) async {
  //   int matchingDocumentCount = 0;
  //   for (var item in selectedBSlots!) {
  //     QuerySnapshot querySnapshot =
  //         await FirebaseFirestore.instance
  //             .collection(authController.centerSlug.toString())
  //             .doc('bookingSlots')
  //             .collection('bookingSlot')
  //             .where('serviceId', isEqualTo: item.serviceId)
  //             .where('courtId', isEqualTo: item.courtId)
  //             .where('startTime', isEqualTo: item.startTime)
  //             .where('status', isEqualTo: 'Booked')
  //             .get();
  //     matchingDocumentCount += querySnapshot.docs.length;
  //   }
  //   return matchingDocumentCount == 0 ? true : false;
  // }

  Future<void> changeCourt({String? subBookingId, String? courtId}) async {
    try {
      final selectedSlots = bookedSlots.where(
        (item) => item.subBookingId == subBookingId,
      );

      int matchingSlotCount = 0;

      for (final slot in selectedSlots) {
        final conflictCheck = await supabase
            .schema('s22_prod_schema')
            .from('booking_slots')
            .select('id')
            .eq('service_id', slot.serviceId!)
            .eq('court_id', courtId!)
            .eq('start_time', slot.startTime!.toIso8601String())
            .eq('status', 'Booked');

        matchingSlotCount += (conflictCheck as List).length;
      }

      final isAvailable = matchingSlotCount == 0;

      if (isAvailable) {
        final matchingSlots = await supabase
            .from('booking_slots')
            .select('id')
            .eq('sub_booking_id', subBookingId!);

        final updates =
            (matchingSlots as List).map((slot) {
              return supabase
                  .from('booking_slots')
                  .update({
                    'court_id': courtId,
                    'updated_by': authController.userId.toString(),
                    'updated_at': DateTime.now().toIso8601String(),
                  })
                  .eq('id', slot['id']);
            }).toList();

        await Future.wait(updates);

        selectedBookingId.value = '';
        update();
        Get.back();

        showCustomSnackbar(
          'Success',
          'Court Changed Successfully',
          Colors.green,
        );
      } else {
        showCustomSnackbar(
          'Warning',
          'Selected Court Not Available',
          Colors.orange,
        );
      }
    } catch (e) {
      print('Error changing court: $e');
    } finally {
      courtChangeBtn.value = false;
    }
  }

  // Future<void> changeCourt({String? subBookingId, String? courtId}) async {
  //   try {
  //     Iterable<BookingSlot> selectedSlots = bookedSlots.where(
  //       (item) => item.subBookingId == subBookingId,
  //     );
  //     bool availableStatus;
  //     int matchingDocumentCount = 0;
  //     for (var item in selectedSlots!) {
  //       QuerySnapshot querySnapshot =
  //           await FirebaseFirestore.instance
  //               .collection(authController.centerSlug.toString())
  //               .doc('bookingSlots')
  //               .collection('bookingSlot')
  //               .where('serviceId', isEqualTo: item.serviceId)
  //               .where('courtId', isEqualTo: courtId)
  //               .where('startTime', isEqualTo: item.startTime)
  //               .where('status', isEqualTo: 'Booked')
  //               .get();
  //       matchingDocumentCount += querySnapshot.docs.length;
  //     }
  //     availableStatus = matchingDocumentCount == 0 ? true : false;
  //     if (availableStatus == true) {
  //       QuerySnapshot querySnapshot =
  //           await FirebaseFirestore.instance
  //               .collection(authController.centerSlug.toString())
  //               .doc('bookingSlots')
  //               .collection('bookingSlot')
  //               .where('subBookingId', isEqualTo: subBookingId.toString())
  //               .get();

  //       List<Future<void>> updateFutures = [];
  //       for (DocumentSnapshot docSnapshot in querySnapshot.docs) {
  //         updateFutures.add(
  //           docSnapshot.reference.update({
  //             'courtId': courtId,
  //             'updatedBy': authController.userId.toString(),
  //             'updatedAt': DateTime.now(),
  //           }),
  //         );
  //       }
  //       await Future.wait(updateFutures).then((value) {
  //         selectedBookingId.value = '';
  //         update();
  //         Get.back();
  //         showCustomSnackbar(
  //           'Success',
  //           'Court Changed Successfully',
  //           Colors.green,
  //         );
  //       });
  //     } else {
  //       showCustomSnackbar(
  //         'Warning',
  //         'Select Court Not Available',
  //         Colors.orange,
  //       );
  //     }
  //   } catch (e) {
  //   } finally {
  //     courtChangeBtn.value = false;
  //   }
  // }

  Stream<List<BookingSlot>> getBookingSlotStream() {
    if (selectedServiceId.isEmpty) {
      return Stream.value([]);
    }

    // Start polling if not already started
    if (_pollingTimer == null) {
      _startPolling();
    }

    return _bookingSlotsStreamController.stream;
  }

  void _startPolling() {
    // Poll every 5 seconds
    _pollingTimer = Timer.periodic(Duration(seconds: 5), (_) {
      _fetchBookedSlots();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _fetchBookedSlots() async {
    if (selectedServiceId.isEmpty) {
      _bookingSlotsStreamController.add([]);
      return;
    }

    try {
      final dateStr = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      ).toIso8601String().substring(0, 10);

      final response = await supabase
          .schema('s22_prod_schema')
          .from('booking_slots')
          .select()
          .eq('service_id', selectedServiceId.value)
          .eq('status', 'Booked')
          .gte('start_time', dateStr)
          //.lt('start_time', endOfDay)
          .order('start_time', ascending: true);
      print("response: $response");
      if (response == null) {
        _bookingSlotsStreamController.add([]);
        return;
      }
      final slots =
          (response as List).map((slot) {
            return BookingSlot(
              id: slot['id'],
              userId: slot['user_id'],
              name: slot['name'],
              mobile: slot['mobile'],
              date: DateTime.parse(slot['start_time']),
              serviceId: slot['service_id'],
              courtId: slot['court_id'],
              startTime: DateTime.parse(slot['start_time']),
              endTime: DateTime.parse(slot['end_time']),
              price: (slot['price'] as num).toDouble(),
              status: slot['status'],
            );
          }).toList();

      _bookingSlotsStreamController.add(slots);
    } catch (e) {
      print('Error fetching booked slots: $e');
      _bookingSlotsStreamController.addError(e);
    }
  }

  @override
  void onClose() {
    _stopPolling();
    if (mobileNumberController.hasListeners) {
      mobileNumberController.dispose(); // Only if not still bound
    }
    // bookingdateController.dispose();
    _bookingSlotsStreamController.close();
    _serviceStreamController.close();
    super.onClose();
  }
}
