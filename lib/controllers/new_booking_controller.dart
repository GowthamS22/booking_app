import 'dart:convert';
import 'dart:ffi';
import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  Future<void> fetchServiceList() async {
    isLoading.value = true;

    try {
      final response = await supabase
          .schema('s22_prod_schema')
          .from('sports')
          .select(
            'id, sport_name, platform_name,platform_index,no_of_platform,regular_fee,peak_fee,platform_from_time,platform_to_time,status,peak_hour_status',
          )
          .eq('status', true)
          .order('platform_index', ascending: true);

      if (response != null) {
        serviceList.clear();
        for (var service in response) {
          serviceList.add({
            'id': service['id'],
            'name': service['sport_name'],
            'icon': '', // Assuming 'icon' is not present in sports table.
            'peak_hour_status': service['peak_hour_status'],
            'platform_from_time': service['platform_from_time'],
            'platform_to_time': service['platform_to_time'],
            'regular_fee': service['regular_fee'],
            'peak_fee': service['peak_fee'],
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
      // 1. Fetch sport details to check 'enabled' status and get base fees
      final sportResponse =
          await supabase
              .schema('s22_prod_schema')
              .from('sports')
              .select(
                'peak_hour_status, platform_from_time, platform_to_time, regular_fee, peak_fee',
              )
              .eq('id', serviceId)
              .single();

      if (sportResponse == null) {
        print('Sport details not found for serviceId: $serviceId');
        return [];
      }

      final bool isSportEnabled = sportResponse['peak_hour_status'] ?? false;
      TimeOfDay openStart;
      TimeOfDay openEnd;
      double sportRegularFee =
          (sportResponse['regular_fee'] as num?)?.toDouble() ?? 0.0;
      double sportPeakFee =
          (sportResponse['peak_fee'] as num?)?.toDouble() ?? 0.0;

      // Always use platform_from_time and platform_to_time from sports table for overall time range
      if (sportResponse['platform_from_time'] != null &&
          sportResponse['platform_to_time'] != null) {
        openStart = parseTimeString(sportResponse['platform_from_time']);
        openEnd = parseTimeString(sportResponse['platform_to_time']);
      } else {
        print('Missing platform time data for sport: $serviceId');
        return [];
      }

      List<Map<String, dynamic>> dailySpecialHours = [];
      String today = DateFormat('EEE').format(selectedDate);

      // Fetch special hours only to determine if a slot falls within a special peak/non-peak period
      final specialHoursResponse = await supabase
          .schema('s22_prod_schema')
          .from('special_hours')
          .select('from_time, to_time, peak_hour_status')
          .eq('sport_id', serviceId)
          .contains('days', [today]);

      if (specialHoursResponse != null && specialHoursResponse.isNotEmpty) {
        dailySpecialHours.addAll(specialHoursResponse);
      }

      // 5. Generate slots and assign peak/non-peak pricing
      TimeOfDay current = openStart;

      while (current.hour < openEnd.hour ||
          (current.hour == openEnd.hour && current.minute < openEnd.minute)) {
        final slotStart = current;
        final slotEnd = addMinutesToTimeOfDay(current, 30);

        bool isPeak = isSportEnabled; // Initial peak status from sports table
        double slotPrice =
            isSportEnabled
                ? sportPeakFee
                : sportRegularFee; // Initial price from sports table

        // Check if the current slot falls into any special_hours period for today
        for (var sh in dailySpecialHours) {
          final specialStart = parseTimeString(sh['from_time']);
          final specialEnd = parseTimeString(sh['to_time']);

          if (isTimeInRange(slotStart, specialStart, specialEnd)) {
            // If a slot falls within ANY special_hours range for today, it's a peak hour
            isPeak = true;
            slotPrice = sportPeakFee;
            break; // Found a matching special hour, no need to check further
          }
        }

        for (var court in courtList) {
          slots.add({
            'courtId': court['id'],
            'courtName': court['name'],
            'start': slotStart,
            'end': slotEnd,
            'isPeak': isPeak,
            'price': slotPrice,
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

      final today = DateFormat('EEE').format(selectedDate);

      // Fetch sport details to check 'enabled' status
      final sportResponse =
          await supabase
              .schema('s22_prod_schema')
              .from('sports')
              .select('peak_hour_status, platform_from_time, platform_to_time')
              .eq('id', selectedServiceId.value)
              .single();

      if (sportResponse == null) {
        showCustomSnackbar('Error', 'Sport details not found', Colors.red);
        isLoading.value = false;
        update();
        return;
      }

      final bool isSportEnabled = sportResponse['peak_hour_status'];

      if (isSportEnabled) {
        // If sport is enabled, use platform_from_time and platform_to_time from sports table
        if (sportResponse['platform_from_time'] != null &&
            sportResponse['platform_to_time'] != null) {
          try {
            startTime =
                parseTimeString(sportResponse['platform_from_time']).hour;
            endTime =
                parseTimeString(sportResponse['platform_to_time']).hour == 0
                    ? 24
                    : parseTimeString(sportResponse['platform_to_time']).hour;

            timeSlots.value = generateTimeSlots(startTime, endTime);
            print("Time slots: $timeSlots");
            _serviceStreamController.add(serviceList);
          } catch (e) {
            print('Error parsing time from sports table: $e');
            showCustomSnackbar('Time parse error', '$e', Colors.red);
          }
        } else {
          print('Missing platform time data for enabled sport');
          showCustomSnackbar('Error', 'Missing platform time data', Colors.red);
        }
      } else {
        // If sport is not enabled, use special_hours for today
        final specialHoursResponse = await supabase
            .schema('s22_prod_schema')
            .from('special_hours')
            .select('from_time, to_time')
            .eq('sport_id', selectedServiceId.value)
            .contains('days', [today]);

        if (specialHoursResponse != null && specialHoursResponse.isNotEmpty) {
          final todayHours = specialHoursResponse.first;
          if (todayHours['from_time'] != null &&
              todayHours['to_time'] != null) {
            try {
              startTime = parseTimeString(todayHours['from_time']).hour;
              endTime =
                  parseTimeString(todayHours['to_time']).hour == 0
                      ? 24
                      : parseTimeString(todayHours['to_time']).hour;

              timeSlots.value = generateTimeSlots(startTime, endTime);
              print("Time slots: $timeSlots");
              _serviceStreamController.add(serviceList);
            } catch (e) {
              print('Error parsing time from special hours: $e');
              showCustomSnackbar('Time parse error', '$e', Colors.red);
            }
          } else {
            print('Missing time data for special hours for $today');
            showCustomSnackbar(
              'Error',
              'Missing special hours time data',
              Colors.red,
            );
          }
        } else {
          showCustomSnackbar(
            'Error',
            'No special hours found for today for the selected service',
            Colors.red,
          );
        }
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

      // Use a more robust DateTime.parse for various formats, then convert to TimeOfDay
      DateTime parsedDateTime;
      if (cleanedTimeStr.contains('AM') || cleanedTimeStr.contains('PM')) {
        // Handle 12-hour format with AM/PM (e.g., "09:00 AM", "6:00 PM")
        // Dart's DateTime.parse generally handles this if the format is consistent.
        // If issues persist, consider using DateFormat('h:mm a').parse(cleanedTimeStr).
        parsedDateTime = DateFormat("h:mm a").parse(cleanedTimeStr);
      } else if (cleanedTimeStr.length == 5 && cleanedTimeStr.contains(':')) {
        // Handle 24-hour format without seconds (e.g., "09:00")
        parsedDateTime = DateFormat("HH:mm").parse(cleanedTimeStr);
      } else if (cleanedTimeStr.length == 8 && cleanedTimeStr.contains(':')) {
        // Handle 24-hour format with seconds (e.g., "09:00:00")
        parsedDateTime = DateFormat("HH:mm:ss").parse(cleanedTimeStr);
      } else {
        // Fallback for other potential formats, or throw a specific error
        throw FormatException('Unrecognized time format: $cleanedTimeStr');
      }
      return TimeOfDay(
        hour: parsedDateTime.hour,
        minute: parsedDateTime.minute,
      );
    } catch (e) {
      print('Time parse error: $e for input "$timeStr" ');
      return const TimeOfDay(hour: 0, minute: 0); // or a fallback
    }
  }

  Future<void> setDefaultSerivce() async {
    final response = await supabase
        .schema('s22_prod_schema')
        .from('sports')
        .select('id, sport_name')
        .eq('status', true)
        .order('platform_index', ascending: true);

    if (response.isNotEmpty) {
      final service = response.first;
      selectedService.value = service['sport_name'];
      selectedServiceId.value = service['id'];
    }
    fetchCourtList();
    update();
  }

  Future<void> fetchCourtList() async {
    isLoading.value = true;

    try {
      if (selectedServiceId.isNotEmpty) {
        final response = await supabase
            .schema('s22_prod_schema')
            .from('sports')
            .select(
              'id, sport_name, platform_name, platform_index, no_of_platform, regular_fee, peak_fee, peak_hour_status',
            )
            .eq('sport_name', selectedService.value)
            .eq('status', true)
            .order('platform_index', ascending: true);

        if (response is List) {
          List<Map<String, dynamic>> generatedCourts = [];
          final Uuid uuid = Uuid();

          for (var sport in response) {
            final int numberOfPlatforms = sport['no_of_platform'] ?? 0;
            final String platformName = sport['platform_name'] ?? 'Court';

            for (int i = 1; i <= numberOfPlatforms; i++) {
              generatedCourts.add({
                'id':
                    uuid.v4(), // Generate a unique ID for each platform instance
                'name':
                    '${platformName} ${i.toString().padLeft(2, '0')}', // e.g., "Court 01"
                'price': sport['regular_fee'], // Use regular_fee as base price
                'no_of_platform': 1, // Each is a single platform
                'peak_fee': sport['peak_fee'],
                'peak_hour_status': sport['peak_hour_status'],
                'sport_id':
                    sport['id'], // Keep a reference to the parent sport's ID
              });
            }
          }
          courtList.value = generatedCourts;

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
          .from('special_hours')
          .select('id, days, from_time, to_time, peak_hour_status')
          .eq('sport_id', selectedServiceId);

      if (response.isNotEmpty) {
        specialHoursList.clear();
        for (var hour in response) {
          specialHoursList.add({
            'id': hour['id'],
            'day': hour['days'],
            'startTime': hour['from_time'],
            'endTime': hour['to_time'],
            'peak_hour_status': hour['peak_hour_status'] ?? false,
          });
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
    // The price is expected to be finalized by getSlotsWithPeakStatusAndPrice
    double? finalizedPrice = price;

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
    String? password,
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
          createdAt: DateTime.parse(response['created_at']),
        );
      }
    } catch (e) {
      print("error : $e");
      showCustomSnackbar('Failed', '$e', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

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
    // The price is expected to be finalized by getSlotsWithPeakStatusAndPrice
    double? finalizedPrice = price;

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

  // Future<void> validatePromocode(String promoCode) async {
  //   try {
  //     final QuerySnapshot discountSnapshot =
  //         await FirebaseFirestore.instance
  //             .collection(authController.centerSlug.toString())
  //             .doc('discounts')
  //             .collection('discount')
  //             .where('code', isEqualTo: promoCode.toString())
  //             .where('expireAt', isGreaterThanOrEqualTo: Timestamp.now())
  //             .where('active', isEqualTo: 1)
  //             .get();

  //     if (discountSnapshot.docs.isNotEmpty) {
  //       for (var doc in discountSnapshot.docs) {
  //         var code = doc['code'];
  //         final QuerySnapshot couponUsageSnapshot =
  //             await FirebaseFirestore.instance
  //                 .collection(authController.centerSlug.toString())
  //                 .doc('couponUsages')
  //                 .collection('couponUsage')
  //                 .where('userId', isEqualTo: authController.userId.toString())
  //                 .where('couponId', isEqualTo: code.toString())
  //                 .get();
  //         if (couponUsageSnapshot.docs.isEmpty) {
  //           if (doc['discountType'] == 'Fixed') {
  //             discount.value = doc['discount'];
  //           } else {
  //             discount.value = totalAmount / 100 * doc['discount'];
  //           }
  //           showCustomSnackbar('Success', 'Promo Applied ', Colors.green);
  //         } else {
  //           discount.value = 0;
  //           showCustomSnackbar('Failed', 'Promo Already Used', Colors.red);
  //         }
  //       }
  //     } else {
  //       discount.value = 0;
  //       showCustomSnackbar('Failed', 'Invalid Promo Code', Colors.red);
  //     }
  //   } catch (e) {
  //     print(e.toString());
  //   } finally {
  //     isLoading.value = false;
  //     update();
  //   }
  // }

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
          endTime: DateTime.parse(subDoc['end_time']),
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
              .from('sports')
              .select('sport_name')
              .eq('id', serviceId)
              .single();

      if (response != null && response['sport_name'] != null) {
        serviceName = response['sport_name'];
        prefs.setString('service_$serviceId', serviceName!);
      } else {
        throw Exception('Service not found in Supabase');
      }
    }

    return serviceName;
  }

  // Function to get court name from local cache or Firestore

  Future<String> getCourtName(String courtId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? courtName = prefs.getString('court_$courtId');

    if (courtName == null) {
      final response =
          await supabase
              .schema('s22_prod_schema')
              .from('sports')
              .select('platform_name')
              .eq('id', courtId)
              .single();

      if (response != null && response['platform_name'] != null) {
        courtName = response['platform_name'];
        prefs.setString('court_$courtId', courtName!);
      } else {
        throw Exception('Court not found in Supabase');
      }
    }

    return courtName;
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
              subBookingId: slot['sub_booking_id'],
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
