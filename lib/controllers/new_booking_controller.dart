import 'dart:convert';
import 'dart:ffi';
import 'dart:math';
import 'dart:async';

import 'package:booking_app/controllers/cart_controller.dart';
import 'package:booking_app/controllers/checkout_controller.dart';
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

  final CartController cartController = Get.find<CartController>();

  RxBool isLoading = false.obs;
  RxBool checkout = false.obs;
  RxBool paymentProcess = false.obs;
  RxBool onlinePayment = false.obs;
  RxBool hasShownSpecialHoursError = false.obs; // Add this flag

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
  RxList<Map<String, dynamic>> membershipPlans =
      <Map<String, dynamic>>[].obs; // New: To store membership plans

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
    cartItems.clear(); // Clear cart items as well
    update();
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
    fetchMembershipPlans(); // Fetch membership plans on init
    super.onInit();
    mobileNumberController = TextEditingController();
    bookingdateController = TextEditingController();
  }

  Future<void> fetchUserMobile() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug = preferences.getString('centerSlug');

    isLoading.value = true;

    final response = await supabase
        .schema('${centerSlug}_prod_schema')
        .from('customers')
        .select('''
          mobile, 
          first_name, 
          membershipplan_id,
          membership_data,
          created_at,
          membershipplan (
            name,
            price,
            billing_cycle,
            peak_price,
            non_peak_price,
            validity
          )
        ''');

    bookingId = 'BCK-2025-TMP';

    if (response != null) {
      userList.clear();
      for (var user in response) {
        final plan = user['membershipplan'];
        final membershipData = user['membership_data'] as Map<String, dynamic>?;

        // Use purchased_date from membership_data if available, otherwise fall back to null
        DateTime? startDate =
            membershipData != null
                ? DateTime.tryParse(
                  membershipData['purchased_date']?.toString() ?? '',
                )
                : null;
        DateTime? endDate;
        if (startDate != null && plan != null && plan['validity'] != null) {
          final billingCycle = plan['billing_cycle']?.toString().toLowerCase();
          final validity = int.tryParse(plan['validity'].toString()) ?? 0;

          if (billingCycle == 'month') {
            endDate = startDate.add(Duration(days: validity));
          } else if (billingCycle == 'year') {
            endDate = DateTime(
              startDate.year,
              startDate.month + validity,
              startDate.day,
            );
          }
        }

        userList.add({
          'name': user['first_name'] ?? '',
          'mobile': user['mobile'] ?? '',
          'membership_plan': plan?['name'] ?? '',
          'price': plan?['price']?.toString() ?? '',
          'billing_cycle': plan?['billing_cycle'] ?? '',
          'peak_price': plan?['peak_price']?.toString() ?? '',
          'non_peak_price': plan?['non_peak_price']?.toString() ?? '',
          'validity_start': startDate?.toIso8601String() ?? '',
          'validity_end': endDate?.toIso8601String() ?? '',
          'membershipplan_id': user['membershipplan_id'] ?? '',
        });
      }
    }

    isLoading.value = false;
    update();
  }

  Future<List<Map<String, dynamic>>> fetchUserSuggestions(String query) async {
    if (query.isEmpty) return [];

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug = preferences.getString('centerSlug');

    final response = await supabase
        .schema('${centerSlug}_prod_schema')
        .from('customers')
        .select('''
        id,
        mobile,
        first_name,
        membershipplan_id,
        membership_data,
        created_at,
        status,
        membershipplan (
          name,
          price,
          billing_cycle,
          peak_price,
          non_peak_price,
          validity
        )
      ''')
        .eq('status', true)
        .or('first_name.ilike.%$query%,mobile.ilike.%$query%')
        .limit(10);

    return await Future.wait(response.map((user) async {
      final plan = user['membershipplan'];
      final membershipData = user['membership_data'] as Map<String, dynamic>?;

      DateTime? startDate = membershipData != null
          ? DateTime.tryParse(membershipData['purchased_date']?.toString() ?? '')
          : null;

      DateTime? endDate;
      if (startDate != null && plan != null && plan['validity'] != null) {
        final billingCycle = plan['billing_cycle']?.toString().toLowerCase();
        final validity = int.tryParse(plan['validity'].toString()) ?? 0;

        if (billingCycle == 'month') {
          endDate = startDate.add(Duration(days: validity));
        } else if (billingCycle == 'year') {
          endDate = DateTime(
            startDate.year,
            startDate.month + validity,
            startDate.day,
          );
        }
      }

      try {
        // Check if membership exists in cart
        final membershipDataRes = await supabase
            .schema('${centerSlug}_prod_schema')
            .from('membership_data')
            .select('*')
            .eq('customer_id', user['id'])
            .eq('status', true)
            .maybeSingle(); // Use maybeSingle instead of single to handle null case

        return {
          'id': user['id'] ?? '',
          'name': user['first_name'] ?? '',
          'mobile': user['mobile'] ?? '',
          'membership_plan': plan?['name'] ?? '',
          'price': plan?['price']?.toString() ?? '',
          'billing_cycle': plan?['billing_cycle'] ?? '',
          'peak_price': plan?['peak_price']?.toString() ?? '',
          'non_peak_price': plan?['non_peak_price']?.toString() ?? '',
          'validity_start': startDate?.toIso8601String() ?? '',
          'validity_end': endDate?.toIso8601String() ?? '',
          'membershipplan_id': user['membershipplan_id'] ?? '',
          'already_in_cart': membershipDataRes != null, // True if found in membership_data table
        };
      } catch (e) {
        // If no record found, return with already_in_cart as false
        return {
          'id': user['id'] ?? '',
          'name': user['first_name'] ?? '',
          'mobile': user['mobile'] ?? '',
          'membership_plan': plan?['name'] ?? '',
          'price': plan?['price']?.toString() ?? '',
          'billing_cycle': plan?['billing_cycle'] ?? '',
          'peak_price': plan?['peak_price']?.toString() ?? '',
          'non_peak_price': plan?['non_peak_price']?.toString() ?? '',
          'validity_start': startDate?.toIso8601String() ?? '',
          'validity_end': endDate?.toIso8601String() ?? '',
          'membershipplan_id': user['membershipplan_id'] ?? '',
          'already_in_cart': false,
        };
      }
    }));
  }

  Future<List<Map<String, dynamic>>> fetchUserSuggestionsOLD(String query) async {
    if (query.isEmpty) return [];

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug = preferences.getString('centerSlug');

    final response = await supabase
        .schema('${centerSlug}_prod_schema')
        .from('customers')
        .select('''
        id,
        mobile,
        first_name,
        membershipplan_id,
        membership_data,
        created_at,
        status,
        membershipplan (
          name,
          price,
          billing_cycle,
          peak_price,
          non_peak_price,
          validity
        )
      ''')
        .eq('status',true)
        .or(
          'first_name.ilike.%$query%,mobile.ilike.%$query%',
        ) // Dynamic search on name or mobile
        .limit(10); // Pagination or limit to reduce data size

    return response.map((user) {
      final plan = user['membershipplan'];
      final membershipData = user['membership_data'] as Map<String, dynamic>?;
      // Use purchased_date from membership_data if available, otherwise fall back to null
      DateTime? startDate =
          membershipData != null
              ? DateTime.tryParse(
                membershipData['purchased_date']?.toString() ?? '',
              )
              : null;
      DateTime? endDate;
      if (startDate != null && plan != null && plan['validity'] != null) {
        final billingCycle = plan['billing_cycle']?.toString().toLowerCase();
        final validity = int.tryParse(plan['validity'].toString()) ?? 0;

        if (billingCycle == 'month') {
          endDate = startDate.add(Duration(days: validity));
        } else if (billingCycle == 'year') {
          endDate = DateTime(
            startDate.year,
            startDate.month + validity,
            startDate.day,
          );
        }
      }

      return {
        'id': user['id'] ?? '',
        'name': user['first_name'] ?? '',
        'mobile': user['mobile'] ?? '',
        'membership_plan': plan?['name'] ?? '',
        'price': plan?['price']?.toString() ?? '',
        'billing_cycle': plan?['billing_cycle'] ?? '',
        'peak_price': plan?['peak_price']?.toString() ?? '',
        'non_peak_price': plan?['non_peak_price']?.toString() ?? '',
        'validity_start': startDate?.toIso8601String() ?? '',
        'validity_end': endDate?.toIso8601String() ?? '',
        'membershipplan_id': user['membershipplan_id'] ?? '',
      };
    }).toList();
  }

  Future<void> getUserDatabyMobile(String mobile) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug = preferences.getString('centerSlug');

    currentPlan.clear();
    userData.value = User();
    try {
      // Step 1: Get user by mobile
      final userResponse =
          await supabase
              .schema('${centerSlug}_prod_schema')
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

  Future<void> fetchServiceListOld() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    String? centerSlug = pref.getString('centerSlug');
    isLoading.value = true;
    try {
      final today = DateFormat(
        'EEE',
      ).format(selectedDate); // Get full day name (e.g., 'Monday')

      // Fetch all sports
      final sportsResponse = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('sports')
          .select(
            'id, sport_name, platform_name,platform_index,no_of_platform,regular_fee,peak_fee,platform_from_time,platform_to_time,status,peak_hour_status',
          )
          .order(
            'platform_index',
            ascending: true,
          ); // Order by index to check 0 first

      // Fetch active days for today
      final activeDaysResponse = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('active_days')
          .select('sport_id, day_name, status')
          .eq('day_name', today);
      //.eq('status', true);

      if (sportsResponse == null || activeDaysResponse == null) {
        // Handle case where no data is returned
        showCustomSnackbar(
          'Error',
          'Failed to fetch sports or active days data.',
          Colors.red,
        );
        isLoading.value = false;
        update();
        return;
      }

      final List<Map<String, dynamic>> availableSports = [];

      for (var sport in sportsResponse) {
        final sportId = sport['id'];
        final sportStatus =
            sport['status'] ?? false; // Default to false if null

        // Check if this sport has an active day entry for today with status true
        final isActiveToday = activeDaysResponse.any(
          (activeDay) =>
              activeDay['sport_id'] == sportId && activeDay['status'] == true,
        );

        availableSports.add({
          'id': sport['id'],
          'name': sport['sport_name'],
          'icon': '',
          'peak_hour_status': sport['peak_hour_status'],
          'platform_from_time': sport['platform_from_time'],
          'platform_to_time': sport['platform_to_time'],
          'regular_fee': sport['regular_fee'],
          'peak_fee': sport['peak_fee'],
          'platform_index':
              sport['platform_index'], // Include platform_index for sorting
          'is_available': sportStatus && isActiveToday,
        });
      }

      // Sort availableSports alphabetically by name
      availableSports.sort((a, b) {
        final nameA = (a['name'] ?? '').toLowerCase();
        final nameB = (b['name'] ?? '').toLowerCase();
        return nameA.compareTo(nameB);
      });

      if (availableSports.isNotEmpty) {
        serviceList.clear();
        serviceList.addAll(
          availableSports
              .where((sport) => sport['is_available'] == true)
              .toList(),
        );

        if (serviceList.isNotEmpty) {
          final firstAvailableSport = serviceList.firstWhere(
            (sport) => sport['is_available'] == true,
            orElse: () => null,
          );

          if (firstAvailableSport != null) {
            selectedService.value = firstAvailableSport['name'];
            selectedServiceId.value = firstAvailableSport['id'];
            fetchCourtList();
          } else {
            showCustomSnackbar(
              'No Sports Available',
              'No sports are scheduled for today.',
              Colors.orange,
            );
            selectedService.value = '';
            selectedServiceId.value = '';
          }
        } else {
          // Case: availableSports was not empty, but after filtering, serviceList became empty
          showCustomSnackbar(
            'No Sports Available',
            'No sports are scheduled for today.',
            Colors.orange,
          );
          selectedService.value = '';
          selectedServiceId.value = '';
        }
      } else {
        // No sports available at all (initial sportsResponse was empty)
        showCustomSnackbar(
          'No Sports Available',
          'No sports are configured in the system.',
          Colors.orange,
        );
        serviceList.clear();
      }
      _serviceStreamController.add(
        serviceList,
      ); // Always update the stream here once at the end of this block
    } catch (e) {
      print('Error fetching services: $e');
      _serviceStreamController.addError(e);
      showCustomSnackbar(
        'Error',
        'An error occurred while fetching services.',
        Colors.red,
      );
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> fetchServiceList() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    String? centerSlug = pref.getString('centerSlug');
    isLoading.value = true;

    try {
      final String? cachedSports = pref.getString('allSports');
      final String? cachedActiveDays = pref.getString('allActiveDays');
      final dayName = DateFormat('EEE').format(selectedDate); // Use selectedDate

      if (cachedSports != null && cachedActiveDays != null) {
        final List<dynamic> sportsData = jsonDecode(cachedSports);
        final List<dynamic> activeDaysData = jsonDecode(cachedActiveDays);

        // Filter active days for the selected date
        final activeDaysForSelectedDate = activeDaysData.where(
                (activeDay) => activeDay['day_name'] == dayName && activeDay['status'] == true
        ).toList();

        final List<Map<String, dynamic>> availableSports = [];

        for (var sport in sportsData) {
          final sportId = sport['id'];
          final sportStatus = sport['status'] ?? false;

          // Check if this sport is active for the selected date
          final isActiveOnSelectedDate = activeDaysForSelectedDate.any(
                  (activeDay) => activeDay['sport_id'] == sportId
          );

          availableSports.add({
            'id': sport['id'],
            'name': sport['sport_name'],
            'icon': '',
            'peak_hour_status': sport['peak_hour_status'],
            'platform_from_time': sport['platform_from_time'],
            'platform_to_time': sport['platform_to_time'],
            'regular_fee': sport['regular_fee'],
            'peak_fee': sport['peak_fee'],
            'platform_index': sport['platform_index'],
            'is_available': sportStatus && isActiveOnSelectedDate,
          });
        }

        availableSports.sort((a, b) {
          final nameA = (a['name'] ?? '').toLowerCase();
          final nameB = (b['name'] ?? '').toLowerCase();
          return nameA.compareTo(nameB);
        });

        serviceList.clear();
        serviceList.addAll(
          availableSports.where((sport) => sport['is_available'] == true).toList(),
        );

        if (serviceList.isNotEmpty) {
          final firstAvailableSport = serviceList.firstWhere(
                (sport) => sport['is_available'] == true,
            orElse: () => null,
          );

          if (firstAvailableSport != null) {
            selectedService.value = firstAvailableSport['name'];
            selectedServiceId.value = firstAvailableSport['id'];
            fetchCourtList();
          } else {
            showCustomSnackbar(
              'No Sports Available',
              'No sports are scheduled for the selected date.',
              Colors.orange,
            );
            selectedService.value = '';
            selectedServiceId.value = '';
          }
        } else {
          showCustomSnackbar(
            'No Sports Available',
            'No sports are scheduled for the selected date.',
            Colors.orange,
          );
          selectedService.value = '';
          selectedServiceId.value = '';
        }

        _serviceStreamController.add(serviceList);
        isLoading.value = false;
        update();
        return;
      }

      // Fallback: If no cached data, fetch fresh data for the selected date
      final sportsResponse = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('sports')
          .select(
        'id, sport_name, platform_name,platform_index,no_of_platform,regular_fee,peak_fee,platform_from_time,platform_to_time,status,peak_hour_status',
      )
          .order('platform_index', ascending: true);

      final activeDaysResponse = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('active_days')
          .select('sport_id, day_name, status')
          .eq('day_name', dayName);

      // ... rest of your existing fetch logic ...

    } catch (e) {
      print('Error fetching services: $e');
      _serviceStreamController.addError(e);
      showCustomSnackbar(
        'Error',
        'An error occurred while fetching services.',
        Colors.red,
      );
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
    final SharedPreferences pref = await SharedPreferences.getInstance();
    String? centerSlug = pref.getString('centerSlug');
    List<Map<String, dynamic>> slots = [];

    try {
      // 1. Fetch sport details to check 'enabled' status and get base fees
      final sportResponse =
          await supabase
              .schema('${centerSlug}_prod_schema')
              .from('sports')
              .select(
                'peak_hour_status, platform_from_time, platform_to_time, regular_fee, peak_fee',
              )
              .eq('id', serviceId)
              .maybeSingle();

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

      List<Map<String, dynamic>> dailySpecialHours = [];
      String today = DateFormat('EEE').format(selectedDate);

      // Always use platform_from_time and platform_to_time from sports table
      if (sportResponse['platform_from_time'] != null &&
          sportResponse['platform_to_time'] != null) {
        openStart = parseTimeString(sportResponse['platform_from_time']);
        openEnd = parseTimeString(sportResponse['platform_to_time']);
      } else {
        print('Missing platform time data for sport: $serviceId');
        return [];
      }

      // Fetch special hours for today
      final specialHoursResponse = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('special_hours')
          .select('from_time, to_time, peak_hour_status')
          .eq('sport_id', serviceId)
          .contains('days', [today]);

      if (specialHoursResponse != null && specialHoursResponse.isNotEmpty) {
        dailySpecialHours = specialHoursResponse;
      }

      // 5. Generate slots and assign peak/non-peak pricing
      TimeOfDay current = openStart;

      while (current.hour < openEnd.hour ||
          (current.hour == openEnd.hour && current.minute < openEnd.minute)) {
        final slotStart = current;
        final slotEnd = addMinutesToTimeOfDay(current, 30);

        bool isPeak = isSportEnabled; // Initial peak status from sports table
        double slotPrice = isSportEnabled ? sportPeakFee : sportRegularFee;
        bool specialHourOverride = false;
        for (var sh in dailySpecialHours) {
          final specialStart = parseTimeString(sh['from_time']);
          final specialEnd = parseTimeString(sh['to_time']);

          if (isTimeInRange(slotStart, specialStart, specialEnd)) {
            //bool specialHourDbStatus = sh['peak_hour_status'] ?? false;
            //if (!specialHourDbStatus) {
            isPeak = true;
            slotPrice = sportPeakFee;
            // } else {
            //   isPeak    = false;
            //   slotPrice = sportRegularFee;
            // }
            //specialHourOverride = true;
            //break;
          } else {
            isPeak = false;
            slotPrice = sportRegularFee;
          }
        }
        // if (!specialHourOverride) {
        //   isPeak = isSportEnabled;
        //   slotPrice = isSportEnabled ? sportPeakFee : sportRegularFee;
        // } else {
        //   print(
        //     '  Special hour override applied. Final isPeak = $isPeak, price = $slotPrice',
        //   );
        // }
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
    final SharedPreferences pref = await SharedPreferences.getInstance();
    String? centerSlug = pref.getString('centerSlug');
    isLoading.value = true;

    try {
      if (selectedServiceId.value == null || selectedServiceId.value.isEmpty) {
        isLoading.value = false;
        update();
        return;
      }

      // If we already have time slots, don't fetch again
      if (timeSlots.isNotEmpty) {
        isLoading.value = false;
        update();
        return;
      }

      final today = DateFormat('EEE').format(selectedDate);

      // Fetch sport details to check 'enabled' status
      final sportResponse =
          await supabase
              .schema('${centerSlug}_prod_schema')
              .from('sports')
              .select('peak_hour_status, platform_from_time, platform_to_time')
              .eq('id', selectedServiceId.value)
              .maybeSingle();

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
            _serviceStreamController.add(serviceList);
            hasShownSpecialHoursError.value = false;
          } catch (e) {
            showCustomSnackbar('Time parse error', '$e', Colors.red);
          }
        } else {
          showCustomSnackbar('Error', 'Missing platform time data', Colors.red);
        }
      } else {
        // If sport is not enabled, use special_hours for today
        final specialHoursResponse = await supabase
            .schema('${centerSlug}_prod_schema')
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
              _serviceStreamController.add(serviceList);
            } catch (e) {
              print('Error parsing time from special hours: $e');
              showCustomSnackbar('Time parse error', '$e', Colors.red);
            }
          } else {
            showCustomSnackbar(
              'Error',
              'Missing special hours time data',
              Colors.red,
            );
          }
        } else {
          // Only show the error if we don't have any time slots yet
          if (timeSlots.isEmpty) {
            showCustomSnackbar(
              'Error',
              'No special hours found for today for the selected service',
              Colors.red,
            );
          }
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

      DateTime parsedDateTime;
      if (cleanedTimeStr.contains('AM') || cleanedTimeStr.contains('PM')) {
        parsedDateTime = DateFormat("h:mm a").parse(cleanedTimeStr);
      } else if (cleanedTimeStr.length == 5 && cleanedTimeStr.contains(':')) {
        parsedDateTime = DateFormat("HH:mm").parse(cleanedTimeStr);
      } else if (cleanedTimeStr.length == 8 && cleanedTimeStr.contains(':')) {
        parsedDateTime = DateFormat("HH:mm:ss").parse(cleanedTimeStr);
      } else {
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

  Future<void> fetchCourtListOld() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    String? centerSlug = pref.getString('centerSlug');
    isLoading.value = true;

    try {
      if (selectedServiceId.isEmpty) {
        courtList.clear();
        _serviceStreamController.add(serviceList);
        isLoading.value = false;
        update();
        return;
      }

      final response = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('sports')
          .select(
            'id, sport_name, platform_name, platform_index, no_of_platform, regular_fee, peak_fee, peak_hour_status, status, platform_status(id, sport_id, platform_id, status, created_at, updated_at)',
          )
          .eq('id', selectedServiceId.value) // Changed from sport_name to id
          .eq('status', true)
          .order('platform_index', ascending: true);

      if (response is List) {
        if (response.isEmpty) {
          print(
            'No sports found for selectedServiceId: ${selectedServiceId.value}',
          );
          courtList.clear();
          isLoading.value = false;
          update();
          return;
        }

        List<Map<String, dynamic>> generatedCourts = [];
        final Uuid uuid = Uuid();

        for (var sport in response) {
          final int numberOfPlatforms = sport['no_of_platform'] ?? 0;
          final String platformName = sport['platform_name'] ?? 'Court';
          final bool sportOverallStatus = sport['status'] ?? false;
          final String platformIndexType =
              sport['platform_index'] ?? 'numeric'; // Get platform_index

          // Extract platform_status entries for this sport
          final List<dynamic> currentSportPlatformStatuses =
              sport['platform_status'] ?? [];
          final Map<String, bool> platformStatusMap = {};
          final Map<String, String> platformIdMap =
              {}; // To store platform_status IDs
          for (var ps in currentSportPlatformStatuses) {
            platformStatusMap[ps['platform_id'].toString()] =
                ps['status'] ?? false;
            platformIdMap[ps['platform_id'].toString()] = ps['id'];
          }
          for (int i = 1; i <= numberOfPlatforms; i++) {
            String generatedCourtName;
            if (platformIndexType == 'alphabetical') {
              generatedCourtName =
                  '${platformName} ${String.fromCharCode(64 + i)}'; // A, B, C...
            } else {
              generatedCourtName =
                  '${platformName} ${i.toString().padLeft(2, '0')}'; // 01, 02, 03...
            }
            bool individualCourtStatus = sportOverallStatus;

            if (platformStatusMap.containsKey(i.toString())) {
              individualCourtStatus = platformStatusMap[i.toString()]!;
            }
            final String courtId = platformIdMap[i.toString()] ?? uuid.v4();

            generatedCourts.add({
              'id': courtId,
              'name': generatedCourtName,
              'price': sport['regular_fee'],
              'no_of_platform': 1,
              'peak_fee': sport['peak_fee'],
              'peak_hour_status': sport['peak_hour_status'],
              'sport_id': sport['id'],
              'status': individualCourtStatus,
            });
          }
        }
        courtList.value = generatedCourts;
        await fetchSpecialHours();
        await fetchBookedSlots();
      } else {
        courtList.clear();
      }
    } catch (e) {
      print('Error fetching court list: $e');
      _serviceStreamController.addError(e);
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> fetchCourtList() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    String? centerSlug = pref.getString('centerSlug');
    isLoading.value = true;

    try {
      if (selectedServiceId.isEmpty) {
        courtList.clear();
        _serviceStreamController.add(serviceList);
        isLoading.value = false;
        update();
        return;
      }

      // Check for cached sports data
      final String? cachedSports = pref.getString('allSports');
      final String? cachedPlatformStatus = pref.getString('platformStatus');
      final dayName = DateFormat('EEE').format(selectedDate);

      if (cachedSports != null && cachedPlatformStatus != null) {
        final List<dynamic> sportsData = jsonDecode(cachedSports);
        final List<dynamic> platformStatusData = jsonDecode(cachedPlatformStatus);

        // Filter sports for the selected service ID
        final selectedSport = sportsData.firstWhere(
              (sport) => sport['id'] == selectedServiceId.value,
          orElse: () => null,
        );

        if (selectedSport == null) {
          print('No sports found for selectedServiceId: ${selectedServiceId.value}');
          courtList.clear();
          isLoading.value = false;
          update();
          return;
        }

        List<Map<String, dynamic>> generatedCourts = [];
        final Uuid uuid = Uuid();

        final int numberOfPlatforms = selectedSport['no_of_platform'] ?? 0;
        final String platformName = selectedSport['platform_name'] ?? 'Court';
        final bool sportOverallStatus = selectedSport['status'] ?? false;
        final String platformIndexType = selectedSport['platform_index'] ?? 'numeric';

        // Filter platform statuses for this sport
        final currentSportPlatformStatuses = platformStatusData.where(
                (ps) => ps['sport_id'] == selectedServiceId.value
        ).toList();

        final Map<String, bool> platformStatusMap = {};
        final Map<String, String> platformIdMap = {};

        for (var ps in currentSportPlatformStatuses) {
          platformStatusMap[ps['platform_id'].toString()] = ps['status'] ?? false;
          platformIdMap[ps['platform_id'].toString()] = ps['id'];
        }

        for (int i = 1; i <= numberOfPlatforms; i++) {
          String generatedCourtName;
          if (platformIndexType == 'alphabetical') {
            generatedCourtName = '${platformName} ${String.fromCharCode(64 + i)}';
          } else {
            generatedCourtName = '${platformName} ${i.toString().padLeft(2, '0')}';
          }

          bool individualCourtStatus = sportOverallStatus;
          if (platformStatusMap.containsKey(i.toString())) {
            individualCourtStatus = platformStatusMap[i.toString()]!;
          }

          final String courtId = platformIdMap[i.toString()] ?? uuid.v4();

          generatedCourts.add({
            'id': courtId,
            'name': generatedCourtName,
            'price': selectedSport['regular_fee'],
            'no_of_platform': 1,
            'peak_fee': selectedSport['peak_fee'],
            'peak_hour_status': selectedSport['peak_hour_status'],
            'sport_id': selectedSport['id'],
            'status': individualCourtStatus,
          });
        }

        courtList.value = generatedCourts;
        await fetchSpecialHours();
        await fetchBookedSlots();
      } else {
        // Fallback to API call if no cached data
        final response = await supabase
            .schema('${centerSlug}_prod_schema')
            .from('sports')
            .select(
          'id, sport_name, platform_name, platform_index, no_of_platform, regular_fee, peak_fee, peak_hour_status, status, platform_status(id, sport_id, platform_id, status, created_at, updated_at)',
        )
            .eq('id', selectedServiceId.value)
            .eq('status', true)
            .order('platform_index', ascending: true);

        if (response is List && response.isNotEmpty) {
          List<Map<String, dynamic>> generatedCourts = [];
          final Uuid uuid = Uuid();

          for (var sport in response) {
            final int numberOfPlatforms = sport['no_of_platform'] ?? 0;
            final String platformName = sport['platform_name'] ?? 'Court';
            final bool sportOverallStatus = sport['status'] ?? false;
            final String platformIndexType = sport['platform_index'] ?? 'numeric';

            final List<dynamic> currentSportPlatformStatuses =
                sport['platform_status'] ?? [];
            final Map<String, bool> platformStatusMap = {};
            final Map<String, String> platformIdMap = {};

            for (var ps in currentSportPlatformStatuses) {
              platformStatusMap[ps['platform_id'].toString()] = ps['status'] ?? false;
              platformIdMap[ps['platform_id'].toString()] = ps['id'];
            }

            for (int i = 1; i <= numberOfPlatforms; i++) {
              String generatedCourtName;
              if (platformIndexType == 'alphabetical') {
                generatedCourtName = '${platformName} ${String.fromCharCode(64 + i)}';
              } else {
                generatedCourtName = '${platformName} ${i.toString().padLeft(2, '0')}';
              }

              bool individualCourtStatus = sportOverallStatus;
              if (platformStatusMap.containsKey(i.toString())) {
                individualCourtStatus = platformStatusMap[i.toString()]!;
              }

              final String courtId = platformIdMap[i.toString()] ?? uuid.v4();

              generatedCourts.add({
                'id': courtId,
                'name': generatedCourtName,
                'price': sport['regular_fee'],
                'no_of_platform': 1,
                'peak_fee': sport['peak_fee'],
                'peak_hour_status': sport['peak_hour_status'],
                'sport_id': sport['id'],
                'status': individualCourtStatus,
              });
            }
          }
          courtList.value = generatedCourts;
          await fetchSpecialHours();
          await fetchBookedSlots();
        } else {
          courtList.clear();
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

  Future<void> fetchMembershipPlans() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    String? centerSlug = pref.getString('centerSlug');
    try {
      final response = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('membershipplan')
          .select('*')
          .order('price');

      if (response.isEmpty) {
        print('No membership plans found');
        membershipPlans.clear();
      }

      membershipPlans.assignAll(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      print('Error fetching membership plans: $e');
      // Handle error, e.g., show a snackbar
      showCustomSnackbar(
        'Error',
        'Failed to load membership plans: $e',
        Colors.red,
      );
    } finally {
      update();
    }
  }

  Future<void> fetchSpecialHours() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    String? centerSlug = pref.getString('centerSlug');
    if (selectedServiceId.isNotEmpty) {
      final response = await supabase
          .schema('${centerSlug}_prod_schema')
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
        hasShownSpecialHoursError.value =
            false; // Reset flag when we get special hours
        update();
      } else {
        // Only show error if we haven't shown it before
        if (!hasShownSpecialHoursError.value) {
          showCustomSnackbar(
            'No Special Hours',
            'No special hours found for the selected service.',
            Colors.orange,
          );
          hasShownSpecialHoursError.value = true;
        }
      }
    } else {
      if (!hasShownSpecialHoursError.value) {
        showCustomSnackbar(
          'Error :',
          'selectedServiceId is empty',
          Colors.redAccent,
        );
        hasShownSpecialHoursError.value = true;
      }
    }
  }

  Future<void> cancelBooking(String bookingId, String? notes) async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    String? centerSlug = pref.getString('centerSlug');

    try {
      // Step 1: Fetch current payment status of the booking
      final bookingResponse = await Supabase.instance.client
          .schema('${centerSlug}_prod_schema')
          .from('bookings')
          .select('payment_status')
          .eq('id', bookingId)
          .single();

      final String? paymentStatus = bookingResponse['payment_status'];

      // Step 2: Conditionally build update map
      final updateData = {
        'is_cancelled': true,
        'notes': notes,
      };

      if (paymentStatus == 'Paid') {
        updateData['payment_type'] = 'On Acc. / Void';
      }

      // Step 3: Update bookings table
      await Supabase.instance.client
          .schema('${centerSlug}_prod_schema')
          .from('bookings')
          .update(updateData)
          .eq('id', bookingId);

      // Step 4: Update booking_slots table
      await Supabase.instance.client
          .schema('${centerSlug}_prod_schema')
          .from('booking_slots')
          .update({'status': 'Cancelled'})
          .eq('booking_id', bookingId);

      showCustomSnackbar(
        'Success',
        'Booking cancelled successfully',
        Colors.green,
      );
      update();
      await fetchBookedSlots();
    } catch (e) {
      showCustomSnackbar('Error', 'Failed to cancel booking: $e', Colors.red);
    }
  }


  Future<void> markNoShow(String bookingId) async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    String? centerSlug = pref.getString('centerSlug');
    try {
      await Supabase.instance.client
          .schema('${centerSlug}_prod_schema')
          .from('bookings')
          .update({'is_showoff': true})
          .eq('id', bookingId);
      await Supabase.instance.client
          .schema('${centerSlug}_prod_schema')
          .from('booking_slots')
          .update({'status': 'No Show'})
          .eq('booking_id', bookingId);
      showCustomSnackbar('Success', 'Booking marked as No Show', Colors.green);
      update();
      await fetchBookedSlots();
      // Get.snackbar('Success', 'Booking marked as No Show');
    } catch (e) {
      showCustomSnackbar('Error', 'Failed to mark as No Show: $e', Colors.red);
      //Get.snackbar('Error', 'Failed to mark as No Show: $e');
    }
  }

  Future<void> fetchBookedSlots() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    String? centerSlug = pref.getString('centerSlug');
    final startOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final endOfDay = startOfDay.add(Duration(days: 1));

    if (selectedServiceId.isNotEmpty) {
      final response = await supabase
          .schema('${centerSlug}_prod_schema')
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
      is_extended_booking,
      bookings (
        customer_id,
        booking_no,
        total,
        payment_status,
        is_cancelled,
        is_showoff,
        customers (
          user_id,
          first_name,
          mobile,
          membershipplan_id
        )
      ),
      platform_status!court_id (
        platform_id,
        sport_id,
        sports (
          platform_name,
          sport_name
        )
      )
    ''')
          .eq('service_id', selectedServiceId)
          .eq('status', 'Booked')
          .eq('bookings.is_cancelled', false)
          .eq('bookings.is_showoff', false)
          .gte('start_time', startOfDay.toIso8601String())
          .lt('start_time', endOfDay.toIso8601String())
          .order('start_time', ascending: true);

      final data = response as List<dynamic>;

      bookedSlots.clear();

      for (final booked in data) {
        final booking = booked['bookings'] ?? {};
        final customer = booking['customers'] ?? {};
        final courtInfo = booked['platform_status'] ?? {};
        final sportsInfo = courtInfo['sports'] ?? {};

        bookedSlots.add(
          BookingSlot(
            id: booked['id'] as String?,
            bookingId: booked['booking_id'] as String?,
            subBookingId: booked['sub_booking_id'] as String?,
            is_extended_booking: booked['is_extended_booking'] as bool,
            userId: customer['user_id'] as String?,
            name: customer['first_name'] as String?,
            mobile: customer['mobile'] as String?,
            date:
                booked['start_time'] != null
                    ? DateTime.tryParse(booked['start_time'])
                    : null,
            serviceId: booked['service_id'] as String?,
            courtId: booked['court_id'] as String?,
            startTime:
                booked['start_time'] != null
                    ? DateTime.tryParse(booked['start_time'])
                    : null,
            endTime:
                booked['end_time'] != null
                    ? DateTime.tryParse(booked['end_time'])
                    : null,
            price:
                booked['price'] is num
                    ? (booked['price'] as num).toDouble()
                    : null,
            slotType: booking['slot_type'] as String?,
            repeatDays: booking['repeat_days'] as String?,
            repeatEnd:
                booking['repeat_end'] != null
                    ? DateTime.tryParse(booking['repeat_end'])
                    : null,
            repeatId: booking['repeat_id'] as String?,
            repeatGroupId: booking['repeat_group_id'] as String?,
            paymentStatus: booking['payment_status'] as String?,
            status: booked['status'] as String?,
            createdBy: booked['created_by'] as String?,
            updatedBy: booked['updated_by'] as String?,
            createdAt:
                booked['created_at'] != null
                    ? DateTime.tryParse(booked['created_at'])
                    : null,
            updatedAt:
                booked['updated_at'] != null
                    ? DateTime.tryParse(booked['updated_at'])
                    : null,
            membershipPlanId: customer['membershipplan_id'] as String?,
            bookingNo: booking['booking_no'] as String?,
            total:
                booking['total'] is num
                    ? (booking['total'] as num).toDouble()
                    : null,
            service: sportsInfo['sport_name'] as String?,
            //court: sportsInfo['platform_name'] as String?,
            court:
                courtInfo['sports'] != null && courtInfo['platform_id'] != null
                    ? '${courtInfo['sports']['platform_name']} ${courtInfo['platform_id'].toString().padLeft(2, '0')}'
                    : 'Unknown Court',
            platformIndex: courtInfo['platform_id']?.toString(),
          ),
        );
      }
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
        membershipPlanId: null,
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
          content: Container(
            width: 400,
            child: Column(
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
                  style: TextStyle(fontSize: 30),
                ),
              ],
            ),
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
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug = preferences.getString('centerSlug');
    isLoading.value = true;

    print(firstName);
    print(mobile);

    try {
      final response =
          await supabase
              .schema('${centerSlug}_prod_schema')
              .from('customers')
              .insert({
                'first_name': firstName,
                'mobile': mobile,
                'status': true,
              })
              .select('*')
              .single();
      if (response['id'] != null) {
        userData.value.id = response['id'];
        showCustomSnackbar(
          'Success',
          'User registered successfully',
          Colors.green,
        );
      }
    } catch (e) {
      showCustomSnackbar('Error', e.toString(), Colors.red);
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
    List<BookingInfo>? bookings,
    String? membershipID,
    String? membershipName,
    double? membershipPrice,
  }) async {

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug = preferences.getString('centerSlug');

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

      if(membershipID!=null) {
        final planDetails = await supabase
            .schema('${centerSlug}_prod_schema')
            .from('membershipplan')
            .select('*')
            .eq('id', membershipID)
            .single();

        final membershipData = await supabase
            .schema('${centerSlug}_prod_schema')
            .from('membership_data')
            .insert({
              'membershipplan_id': membershipID,
              'customer_id': userData.value.id.toString(),
              'name': planDetails['name'],
              'price': planDetails['price'],
              'billing_cycle': planDetails['billing_cycle'],
              'description': planDetails['description'],
              'peak_price': planDetails['peak_price'],
              'non_peak_price': planDetails['non_peak_price'],
              'swap_time': planDetails['swap_time'],
              'highlights': planDetails['highlights'],
              'validity': planDetails['validity'],
              'status': true,
            });
      }

      // Step 2: Generate a unique booking ID
      final bookingNumber = await getNextBookingNumber();

      // Step 3: Insert booking record
      print('cartItems before booking insert: $cartItems');

      final bookingInsertResponse =
          await supabase
              .schema('${centerSlug}_prod_schema')
              .from('bookings')
              .insert({
                'booking_no': 'BCK-2025-${bookingNumber}',
                'customer_id': userData.value.id.toString(),
                'surcharge': (0.0).toDouble(),
                'grand_total': grandtotalPrice.toDouble(),
                'notes': notes,
                'sub_total': subTotal.toDouble(),
                'discount': discount.value.toDouble(),
                'gst': gstPrice.toDouble(),
                'total': grandtotalPrice.toDouble(),
                'payment_type': paymentType,
                'payment_status': 'Pending',
                'status': 'Booked',
                'created_by': authController.userId.toString(),
                'updated_by': authController.userId.toString(),
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
                'bcart_items': jsonEncode(
                  bookings?.map((b) => b.toJson()).toList(),
                ),
                // 'deleted_at':null,
                // 'deleted_by':authController.userId
              })
              .select()
              .single();

      final insertedBookingId = bookingInsertResponse['id'];

      // Step 4: Insert booking slots
      List<Map<String, dynamic>> slotData =
          cartItems.map((slot) {
            print('Debug - Processing slot: ${slot.service} ${slot.court}');
            return {
              'booking_id': insertedBookingId,
              'service_id': slot.serviceId,
              'court_id': slot.courtId,
              'start_time': slot.startTime!.toIso8601String(),
              'end_time': slot.endTime!.toIso8601String(),
              'price': slot.price?.toDouble(),
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

      try {
        await supabase
            .schema('${centerSlug}_prod_schema')
            .from('booking_slots')
            .insert(slotData);
      } catch (error) {
        print('Error inserting booking slots: $error');
      }

      String? orderId = '';
      double? total = 0;

      if (cartController.cartItems.length > 0) {
        await createTempOrder(total: cartController.total).then((value) {
          orderId = value['id'];
          total = value['total'].toDouble();
        });

        await mergeBookingtoOrder(
          order_id: orderId,
          customer_id: userData.value.id.toString(),
          booking_id: insertedBookingId,
          redirect: false,
        );
      }

      // if (membershipID != null && membershipName != null && membershipPrice != null) {
      //
      //   final planDetails = await supabase
      //       .schema('${centerSlug}_prod_schema')
      //       .from('membershipplan')
      //       .select('*')
      //       .eq('id', membershipID)
      //       .single();
      //
      //   final membershipPayment = await supabase
      //       .schema('${centerSlug}_prod_schema')
      //       .from('membershippayment')
      //       .insert({
      //         'membershipid': membershipID,
      //         'customers_id': userData.value.id.toString(),
      //         'paymenttype': paymentType,
      //         'total': planDetails['price'].toDouble(),
      //         'paidamount': planDetails['price'].toDouble(),
      //         'status': false,
      //         'paymentresponse': '',
      //         'notes': '',
      //         'createdby': authController.userId.toString(),
      //       });
      //
      //   final currentDate = DateTime.now().toIso8601String(); // Gets current date in ISO format
      //
      //   await supabase
      //       .schema('${centerSlug}_prod_schema')
      //       .from('customers')
      //       .update({
      //         'membershipplan_id': membershipID,
      //         'membership_data': {
      //           'purchased_date': currentDate,
      //           'plan_details': planDetails, // Include the plan details if needed
      //           // Add any other membership data fields you want to include
      //         }
      //       })
      //       .eq('id', userData.value.id.toString());
      //
      // }

      // Now clear cart and navigate
      cartItems.clear();
      confirmBtn.value = false;
      userData.value = User();
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

  Future<PostgrestMap> createTempOrder({double? total}) async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      String? centerSlug = preferences.getString('centerSlug');
      final cartJson = preferences.getString('shopping_cart');
      final orderNotes = preferences.getString('order_notes');
      final orderId = preferences.getString('order_id');

      final orderResponse =
          await supabase
              .schema('${centerSlug}_prod_schema')
              .from('orders')
              .insert({
                'token_number': orderId,
                'order_date': DateFormat(
                  'yyyy-MM-dd',
                ).format(DateTime.now()), // <-- 'MM' for month, not 'mm'
                'order_type': 'product',
                'cart_items': jsonDecode(cartJson!),
                'total': total,
                'order_status': 'Pending',
                'notes': orderNotes,
              })
              .select()
              .single();

      return orderResponse;
    } catch (e) {
      showCustomSnackbar('Failed', '${e.toString()}', Palette.dangerTxt);
      rethrow; // Optional: Let the caller handle the exception
    }
  }

  Future<void> mergeBookingtoOrder({
    String? order_id,
    String? booking_id,
    String? customer_id,
    bool redirect = true,
  }) async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      String? centerSlug = preferences.getString('centerSlug');

      final response =
          await supabase
              .schema('${centerSlug}_prod_schema')
              .from('orders')
              .update({'booking_id': booking_id, 'customer_id': customer_id})
              .eq('id', order_id!)
              .select()
              .single();

      if (redirect == true) {
        update();

        showCustomSnackbar(
          'Success',
          'Order Merged to the Booking',
          Palette.newColor,
        );

        // Redirect
        Future.delayed(Duration(seconds: 1), () {
          Get.offAllNamed('/');
        });
      }
    } catch (e) {
      showCustomSnackbar('Failed', '${e.toString()}', Palette.dangerTxt);
    }
  }

  Future<int> getNextBookingNumber() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug = preferences.getString('centerSlug');
    final response =
        await supabase
            .schema('${centerSlug}_prod_schema')
            .rpc('increment_booking_counter')
            .select()
            .single();
    return response['current_token'] as int;
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
        await supabase
            .from('bookings')
            .select()
            .eq('id', bookingId)
            .maybeSingle();

    if (bookingResponse == null) {
      print('Error fetching booking: Booking not found for ID: $bookingId');
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
          membershipPlanId: subDoc['membershipplan_id'],
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
    String? centerSlug = prefs.getString('centerSlug');

    if (serviceName == null) {
      final response =
          await supabase
              .schema('${centerSlug}_prod_schema')
              .from('sports')
              .select('sport_name')
              .eq('id', serviceId)
              .maybeSingle();

      if (response != null && response['sport_name'] != null) {
        serviceName = response['sport_name'];
        prefs.setString('service_$serviceId', serviceName!);
      } else {
        print('Service not found for ID: $serviceId');
        return 'Unknown Service';
      }
    }

    return serviceName;
  }

  // Function to get court name from local cache or Firestore

  Future<String> getCourtName(String courtId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? courtName = prefs.getString('court_$courtId');
    String? centerSlug = prefs.getString('centerSlug');

    if (courtName == null) {
      final response =
          await supabase
              .schema('${centerSlug}_prod_schema')
              .from('sports')
              .select('platform_name')
              .eq('id', courtId)
              .maybeSingle();

      if (response != null && response['platform_name'] != null) {
        courtName = response['platform_name'];
        prefs.setString('court_$courtId', courtName!);
      } else {
        print('Court not found for ID: $courtId');
        return 'Unknown Court';
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? centerSlug = prefs.getString('centerSlug');
    int matchingSlotCount = 0;

    // Defensive copy of the list
    final List<BookingSlot> slotsToValidate = [...?selectedBSlots];

    for (final item in slotsToValidate) {
      final response = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('booking_slots')
          .select('id')
          .eq('service_id', item.serviceId!)
          .eq('court_id', item.courtId!)
          .eq('start_time', item.startTime!.toIso8601String())
          .eq('status', 'Booked');

      // Ensure response is a list
      if (response is List) {
        matchingSlotCount += response.length;
      } else {
        print('Unexpected response: $response');
      }
    }

    return matchingSlotCount == 0;
  }

  // Future<bool> bulkValidateSlots({List<BookingSlot>? selectedBSlots}) async {
  //   int matchingSlotCount = 0;

  //   // Create a safe copy of the list to prevent concurrent modification
  //   final List<BookingSlot> slotsToValidate = List<BookingSlot>.from(
  //     selectedBSlots ?? [],
  //   );

  //   for (var item in slotsToValidate) {
  //     final response = await supabase
  //         .schema('s22_prod_schema')
  //         .from('booking_slots')
  //         .select('id')
  //         .eq('service_id', item.serviceId!)
  //         .eq('court_id', item.courtId!)
  //         .eq('start_time', item.startTime!.toIso8601String())
  //         .eq('status', 'Booked');

  //     matchingSlotCount += (response as List).length;
  //   }

  //   return matchingSlotCount == 0;
  // }

  Future<void> changeCourt({String? subBookingId, String? courtId}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? centerSlug = prefs.getString('centerSlug');
    try {
      final selectedSlots = bookedSlots.where(
        (item) => item.subBookingId == subBookingId,
      );

      int matchingSlotCount = 0;

      for (final slot in selectedSlots) {
        final conflictCheck = await supabase
            .schema('${centerSlug}_prod_schema')
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? centerSlug = prefs.getString('centerSlug');

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
          .schema('${centerSlug}_prod_schema')
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
              membershipPlanId: slot['membershipplan_id'],
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
    _pollingTimer?.cancel();
    super.onClose();
  }

  Future<void> extendBooking({
    required BookingSlot originalBookingSlot,
    required int extensionInMinutes,
    required Map<String, Map<String, dynamic>> slotInfoMap, // <-- add this
  }) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug = preferences.getString('centerSlug');

    try {
      isLoading.value = true;
      update();

      final int numberOfSlots = extensionInMinutes ~/ 30;
      DateTime lastEndTime = originalBookingSlot.endTime!;
      int totalExtended = 0;
      List<Map<String, dynamic>> newSlotsData = [];
      double extendedSlotsTotal = 0.0; // To store the total price of new slots
      List<BookingSubSlotInfo> extendedSubSlots =
          []; // To store new sub-slots for bcart_items

      // Helper to check if a slot is already booked by this booking
      bool isSlotBookedByMe(DateTime start, DateTime end) {
        return bookedSlots.any(
          (slot) =>
              slot.courtId == originalBookingSlot.courtId &&
              slot.date?.year == start.year &&
              slot.date?.month == start.month &&
              slot.date?.day == start.day &&
              slot.startTime == start &&
              slot.endTime == end &&
              slot.bookingId == originalBookingSlot.bookingId,
        );
      }

      // Helper to check if a slot is booked by anyone
      bool isSlotBookedByAnyone(DateTime start, DateTime end) {
        return bookedSlots.any(
          (slot) =>
              slot.courtId == originalBookingSlot.courtId &&
              slot.date?.year == start.year &&
              slot.date?.month == start.month &&
              slot.date?.day == start.day &&
              slot.startTime == start &&
              slot.endTime == end,
        );
      }

      // Find all consecutive slots after the original booking that are already booked by the user
      List<BookingSlot> mySlots =
          bookedSlots
              .where(
                (slot) =>
                    slot.bookingId == originalBookingSlot.bookingId &&
                    slot.courtId == originalBookingSlot.courtId &&
                    slot.date?.year == originalBookingSlot.date?.year &&
                    slot.date?.month == originalBookingSlot.date?.month &&
                    slot.date?.day == originalBookingSlot.date?.day,
              )
              .toList();
      mySlots.sort((a, b) => a.startTime!.compareTo(b.startTime!));

      // Merge consecutive slots
      DateTime extensionStart = originalBookingSlot.endTime!;
      for (int i = 0; i < mySlots.length; i++) {
        if (mySlots[i].startTime!.isAtSameMomentAs(extensionStart)) {
          extensionStart = mySlots[i].endTime!;
          // Check for further consecutive slots
          i = -1; // Restart loop to catch chains
        }
      }

      // Always use 30 minutes for each extension slot
      final slotMinutes = 30;
      int slotsNeeded = extensionInMinutes ~/ slotMinutes;
      int slotsSecured = 0;
      DateTime nextStart = extensionStart;

      while (slotsSecured < slotsNeeded) {
        final startTime = nextStart;
        final endTime = startTime.add(Duration(minutes: slotMinutes));
        final slotKey =
            "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}";
        final slotData = slotInfoMap[slotKey];
        final price =
            slotData != null
                ? (slotData['price'] ?? originalBookingSlot.price)
                : originalBookingSlot.price;

        if (isSlotBookedByMe(startTime, endTime)) {
          // Already booked by this booking, count as secured
          slotsSecured++;
          nextStart = endTime;
          continue;
        } else if (isSlotBookedByAnyone(startTime, endTime)) {
          // Booked by someone else, stop extension
          break;
        } else {
          // Free, book it
          final newSlot = {
            'booking_id': originalBookingSlot.bookingId,
            'service_id': originalBookingSlot.serviceId,
            'court_id': originalBookingSlot.courtId,
            'start_time': startTime.toIso8601String(),
            'end_time': endTime.toIso8601String(),
            'price': price,
            'slot_type': 'Extended Time',
            'status': 'Booked',
            'is_extended_booking': true,
            'created_by': authController.userId.toString(),
            'updated_by': authController.userId.toString(),
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          };
          newSlotsData.add(newSlot);
          extendedSlotsTotal += price; // Add to the total price of new slots

          // Add to extended sub-slots for bcart_items
          extendedSubSlots.add(
            BookingSubSlotInfo(
              startTime:
                  "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}",
              endTime:
                  "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}",
              price: price,
              isPeak: slotData?['isPeak'] ?? false,
            ),
          );

          slotsSecured++;
          nextStart = endTime;
        }
      }

      if (newSlotsData.isNotEmpty) {
        try {
          final bookingResponse =
              await supabase
                  .schema('${centerSlug}_prod_schema')
                  .from('bookings')
                  .select('*')
                  .eq('id', originalBookingSlot.bookingId!)
                  .single();

          if (bookingResponse != null) {
            double currentGrandTotal =
                (bookingResponse['grand_total'] as num).toDouble();
            double newGrandTotal = currentGrandTotal + extendedSlotsTotal;
            String paymentStatus =
                bookingResponse['payment_status'] ?? 'Pending';

            Map<String, dynamic> updateData = {
              'total': newGrandTotal,
              'sub_total': newGrandTotal,
              'gst': newGrandTotal * 0.1,
              'grand_total': newGrandTotal,
              'updated_at': DateTime.now().toIso8601String(),
            };

            if (bookingResponse['bcart_items'] != null) {
              List<dynamic> jsonList = jsonDecode(
                bookingResponse['bcart_items'],
              );
              List<BookingInfo> bookings =
                  jsonList.map((b) => BookingInfo.fromJson(b)).toList();

              // Find the existing booking info for this court
              BookingInfo? existingBooking = bookings[0];

              if (existingBooking != null) {
                existingBooking.subSlots.addAll(extendedSubSlots);
                updateData['bcart_items'] = jsonEncode(
                  bookings.map((b) => b.toJson()).toList(),
                );
              }
            } else {
              // If no bcart_items exists, create new one with extended slots
              List<BookingInfo> newBookings = [
                BookingInfo(
                  courtName: "Court ${originalBookingSlot.court}",
                  selectedDateTime: originalBookingSlot.date!,
                  bookingId: originalBookingSlot.bookingId!,
                  subSlots: extendedSubSlots,
                ),
              ];
              updateData['bcart_items'] = jsonEncode(
                newBookings.map((b) => b.toJson()).toList(),
              );
            }

            // Update payment status
            updateData['payment_status'] = 'Pending';

            final bookingUpdateResponse =
                await supabase
                    .schema('${centerSlug}_prod_schema')
                    .from('bookings')
                    .update(updateData)
                    .eq('id', originalBookingSlot.bookingId!)
                    .select('*')
                    .single();
          }

          final response = await supabase
              .schema('${centerSlug}_prod_schema')
              .from('booking_slots')
              .insert(newSlotsData);

          totalExtended = slotsSecured * slotMinutes;

          print('Insert response: $response');
        } catch (e) {
          print('Supabase insert error: $e');
          showCustomSnackbar(
            'Error',
            'Failed to insert booking slots: $e',
            Colors.red,
          );
        }
      }

      await fetchBookedSlots();

      Get.back(); // Close the drawer
      showCustomSnackbar(
        'Success',
        'Booking extended successfully ',
        Colors.green.shade500,
      );
    } catch (e) {
      print('Error extending booking: $e');
      showCustomSnackbar(
        'Error',
        'Failed to extend booking. Please try again.',
        Colors.red.shade500,
      );
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> extendBookingDifferentCourt({
    required String bookingId,
    required String courtId,
    required String serviceId,
    required DateTime startTime,
    required int duration,
    required Map<String, Map<String, dynamic>> slotInfoMap,
    double defaultPrice = 0,
  }) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> newSlotsData = [];
    double extendedSlotsTotal = 0.0;
    List<BookingSubSlotInfo> extendedSubSlots = [];
    String? centerSlug = preferences.getString('centerSlug');
    int rowsNeeded = (duration / 30).ceil();

    for (int i = 0; i < rowsNeeded; i++) {
      final slotStart = startTime.add(Duration(minutes: i * 30));
      final slotEnd = slotStart.add(Duration(minutes: 30));
      final slotKey =
          "${slotStart.hour.toString().padLeft(2, '0')}:${slotStart.minute.toString().padLeft(2, '0')}";
      final slotData = slotInfoMap[slotKey];
      final double price =
          slotData != null ? (slotData['price'] ?? defaultPrice) : defaultPrice;
      final bool isPeak =
          slotData != null ? (slotData['isPeak'] ?? false) : false;

      try {
        final newSlot = {
          'booking_id': bookingId,
          'court_id': courtId,
          'service_id': serviceId,
          'start_time': slotStart.toIso8601String(),
          'end_time': slotEnd.toIso8601String(),
          'price': price,
          'slot_type': 'Extended Time',
          'is_extended_booking': true,
          'status': 'Booked',
          'created_by': authController.userId.toString(),
          'updated_by': authController.userId.toString(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        print('Insert response: $newSlot');
        newSlotsData.add(newSlot);
        extendedSlotsTotal += price;

        if (newSlotsData.isNotEmpty) {
          try {
            final bookingResponse =
                await supabase
                    .schema('${centerSlug}_prod_schema')
                    .from('bookings')
                    .select('*')
                    .eq('id', bookingId)
                    .single();

            if (bookingResponse != null) {
              double currentGrandTotal =
                  (bookingResponse['grand_total'] as num).toDouble();
              double newGrandTotal = currentGrandTotal + extendedSlotsTotal;
              String paymentStatus =
                  bookingResponse['payment_status'] ?? 'Pending';

              Map<String, dynamic> updateData = {
                'total': newGrandTotal,
                'sub_total': newGrandTotal,
                'gst': newGrandTotal * 0.1,
                'grand_total': newGrandTotal,
                'updated_at': DateTime.now().toIso8601String(),
              };

              if (bookingResponse['bcart_items'] != null) {
                List<dynamic> jsonList = jsonDecode(
                  bookingResponse['bcart_items'],
                );
                List<BookingInfo> bookings =
                    jsonList.map((b) => BookingInfo.fromJson(b)).toList();

                // Find the existing booking info for this court
                BookingInfo? existingBooking = bookings[0];

                if (existingBooking != null) {
                  existingBooking.subSlots.addAll(extendedSubSlots);
                  updateData['bcart_items'] = jsonEncode(
                    bookings.map((b) => b.toJson()).toList(),
                  );
                }
              } else {
                // If no bcart_items exists, create new one with extended slots
                List<BookingInfo> newBookings = [
                  BookingInfo(
                    courtName: "Court ${courtId.split('-').last}",
                    selectedDateTime: startTime,
                    bookingId: bookingId,
                    subSlots: extendedSubSlots,
                  ),
                ];
                updateData['bcart_items'] = jsonEncode(
                  newBookings.map((b) => b.toJson()).toList(),
                );
              }

              // Update payment status
              updateData['payment_status'] = 'Pending';

              final bookingUpdateResponse =
                  await supabase
                      .schema('${centerSlug}_prod_schema')
                      .from('bookings')
                      .update(updateData)
                      .eq('id', bookingId)
                      .select('*')
                      .single();
            }

            final response = await supabase
                .schema('${centerSlug}_prod_schema')
                .from('booking_slots')
                .insert(newSlotsData);

            //totalExtended = slotsSecured * slotMinutes;

            print('Insert response: $response');
          } catch (e) {
            print('Supabase insert error: $e');
            showCustomSnackbar(
              'Error',
              'Failed to insert booking slots: $e',
              Colors.red,
            );
          }
        }
        //selectedCourtSlots.clear();
        clearSelectedSlots();
        await fetchBookedSlots();

        Get.back(); // Close the drawer
        showCustomSnackbar(
          'Success',
          'Booking extended successfully ',
          Colors.green.shade500,
        );
      } catch (e) {
        print('Supabase insert error: $e');
        showCustomSnackbar(
          'Error',
          'Failed to insert booking slots: $e',
          Colors.red,
        );
      } finally {
        isLoading.value = false;
        update();
      }
    }
  }
}
