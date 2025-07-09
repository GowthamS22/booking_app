// ignore_for_file: unnecessary_null_comparison

import 'package:booking_app/controllers/cart_controller.dart';
import 'package:booking_app/models/user.dart' as AppUser;
import 'package:booking_app/screens/checkout/checkout_screen.dart';
import 'package:booking_app/screens/shopping/addon_items_widget.dart';
import 'package:booking_app/screens/shopping/cart_items.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/constants.dart';
import '../../../config/palette.dart';
import '../../../controllers/new_booking_controller.dart';
import '../../../controllers/checkout_controller.dart';
import '../../../controllers/cart_controller.dart';
import '../../../models/booking_model.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:booking_app/components/mobile_number_formatter.dart';

import '../extended_bookings.dart';

final supabase = Supabase.instance.client;

class CourtViewScreen extends StatefulWidget {
  const CourtViewScreen({super.key});

  @override
  State<CourtViewScreen> createState() => _CourtViewScreenState();
}

class _CourtViewScreenState extends State<CourtViewScreen> {
  final NewBookingController controller = Get.put(NewBookingController());
  final CheckoutController checkoutController = Get.put(CheckoutController());
  final CartController cartController = Get.put(CartController());
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _advanceformKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController mobileController;
  late TextEditingController repeatUntilController;
  final ScrollController _horizontal = ScrollController();
  final ScrollController _vertical = ScrollController();
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _leftVerticalController = ScrollController();
  DateTime selectedDate = DateTime.now();
  DateTime? membershipValidityDate;
  DateTime? selectedDateTime;
  bool isDate = false;
  String? selectedMembershipId;
  List<Map<String, dynamic>> slotInfo = [];
  Set<int> expandedIndexes = {};
  Map<String, Map<String, dynamic>> slotInfoMap = {};
  String? _selectedPlan;
  double _selectedPrice = 0.0;
  double memberPrice = 0.0;
  bool isMembershipApplied = false;
  var courtPrice = 0.0;
  double membershipPrice = 0.0;
  double totalPrice = 0.0;
  List<String> selectedSlots = []; // Add this line
  bool hasMembership = false;
  bool hasPendingMembership = false;
  double? memberPeakPrice;
  double? memberNonPeakPrice;
  bool showTodayButton = false;

  @override
  void initState() {
    super.initState();

    // Initialize text controllers
    nameController = TextEditingController();
    mobileController = TextEditingController();
    repeatUntilController = TextEditingController();

    selectedSlots.clear();
    showTodayButton = false;

    // Initialize selectedDateTime to today
    selectedDateTime = DateTime.now();

    // Add listeners
    _vertical.addListener(() {
      if (_leftVerticalController.hasClients) {
        _leftVerticalController.jumpTo(_vertical.offset);
      }
    });
    _horizontal.addListener(() {
      if (_headerHorizontalController.hasClients) {
        _headerHorizontalController.jumpTo(_horizontal.offset);
      }
    });

    // Move all controller clearing operations to post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _clearControllersAndLoadData();
    });
  }

  void _clearControllersAndLoadData() {
    // Safely clear controller data after the widget is built
    try {
      controller.clearSelectedSlots();
      controller.selectedCourtSlots.clear();
      controller.userData.value = AppUser.User();
    } catch (e) {
      print('Error clearing controller data: $e');
    }

    // Safely clear cart
    try {
      cartController.clearCart();
    } catch (e) {
      print('Error clearing cart: $e');
    }

    // Load initial data after clearing
    _loadInitialData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only refresh if a booking was just completed
    if (mounted && controller.bookingJustCompleted.value) {
      controller.bookingJustCompleted.value = false; // Reset the flag
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          _refreshCourtView();
        }
      });
    }
  }

  @override
  void dispose() {
    // Clear controller data before disposing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        cartController.clearCart();
        controller.clearSelectedSlots();
        controller.userData.value = AppUser.User();
      } catch (e) {
        print('Error clearing controllers on dispose: $e');
      }
    });

    // Reset selected date to today
    setState(() {
      selectedDateTime = DateTime.now();
      controller.selectedDate = DateTime.now();
      showTodayButton = false;
    });

    // Remove listeners before disposing
    _vertical.removeListener(() {});
    _horizontal.removeListener(() {});

    // Dispose scroll controllers
    _vertical.dispose();
    _horizontal.dispose();
    _headerHorizontalController.dispose();
    _leftVerticalController.dispose();

    // Dispose text controllers
    nameController.dispose();
    mobileController.dispose();
    repeatUntilController.dispose();

    super.dispose();
  }

  void _refreshCourtView() {
    // Clear all selections
    selectedSlots.clear();
    controller.clearSelectedSlots();
    controller.selectedCourtSlots.clear();

    // Refresh data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        try {
          print('🔄 Refreshing court view...');

          // Ensure we have a selected service
          if (controller.selectedServiceId.value == null ||
              controller.selectedServiceId.value.isEmpty) {
            print('📋 No service selected, fetching service list...');
            await controller.fetchServiceList();
            if (controller.serviceList.isNotEmpty) {
              controller.selectedServiceId.value = controller.serviceList[0]['id'];
              print('✅ Service ID set: ${controller.selectedServiceId.value}');
            }
          }

          // Ensure we have court list
          if (controller.courtList.isEmpty) {
            print('🏟️ No courts loaded, fetching court list...');
            await controller.fetchCourtList();
            print('✅ Courts loaded: ${controller.courtList.length}');
          }

          // Fetch fresh booking data
          print('📅 Fetching booked slots...');
          await controller.fetchBookedSlots();

          // Fetch slot info
          print('🎯 Fetching slot info...');
          await fetchSlotInfo();

          // Update UI
          if (mounted) {
            setState(() {});
            print('✅ Court view refreshed successfully');
          }
        } catch (error) {
          print('❌ Error refreshing court view: $error');
          if (mounted) {
            showCustomSnackbar(
              'Error',
              'Failed to refresh court data. Please try again.',
              Colors.red,
            );
          }
        }
      }
    });
  }

  Future<void> _loadInitialData() async {
    try {
      // Check if widget is still mounted
      if (!mounted) {
        print('Widget not mounted, skipping initial data load');
        return;
      }

      controller.isLoading.value = true;

      // First fetch service list
      await controller.fetchServiceList();

      if (controller.serviceList.isNotEmpty) {
        // Set initial service ID
        controller.selectedServiceId.value = controller.serviceList[0]['id'];

        // Fetch court list and booked slots
        await Future.wait([
          controller.fetchCourtList(),
          controller.fetchBookedSlots(),
        ]);

        // Clear and reload court list
        controller.courtList.clear();
        await controller.fetchCourtList();

        // Fetch slot info
        await fetchSlotInfo();

        // Initialize selected membership plan after fetching all plans
        if (controller.membershipPlans.isNotEmpty) {
          _selectedPlan = controller.membershipPlans.first["name"];
          _selectedPrice =
              double.tryParse(
                controller.membershipPlans.first["price"].toString(),
              ) ??
              0;
        }
      }
    } catch (error, stackTrace) {
      print('Error loading initial data: $error');
      print('Stack trace: $stackTrace');

      // Show user-friendly error message
      if (mounted) {
        showCustomSnackbar(
          'Error',
          'Failed to load booking data. Please try again.',
          Colors.red,
        );
      }
    } finally {
      if (mounted) {
        controller.isLoading.value = false;
      }
    }
  }

  Future<List<Map<String, dynamic>>> fetchSlotInfo() async {
    try {
      controller.isLoading.value = true;

      // Fetch slots with peak status and price for the selected date
      slotInfo = await controller.getSlotsWithPeakStatusAndPrice(
        serviceId: controller.selectedServiceId.value,
        selectedDate: controller.selectedDate,
        courtList: controller.courtList,
      );

      // Map for quick lookup
      slotInfoMap = {
        for (var slot in slotInfo)
          "${slot['start'].hour.toString().padLeft(2, '0')}:${slot['start'].minute.toString().padLeft(2, '0')}":
              slot,
      };

      // Update controller.timeSlots
      controller.timeSlots.value = slotInfoMap.keys.toList();

      // Refresh UI
      if (mounted) {
        setState(() {});
      }

      return slotInfo;
    } catch (error) {
      print('Error fetching slot info: $error');
      return [];
    } finally {
      controller.isLoading.value = false;
    }
  }

  bool isSlotInPast(String slot) {
    final now = DateTime.now();
    final slotTime = parseTime(slot);

    // If the selected date is before today, all slots are in the past
    if (selectedDateTime != null &&
        selectedDateTime!.isBefore(DateTime(now.year, now.month, now.day))) {
      return true;
    }

    // If the selected date is today, check for the 10-minute grace period
    if (selectedDateTime != null &&
        selectedDateTime!.year == now.year &&
        selectedDateTime!.month == now.month &&
        selectedDateTime!.day == now.day) {
      // Slot is in the past only if now is more than 10 minutes after slot start
      return now.isAfter(slotTime.add(const Duration(minutes: 10)));
    }

    // For future dates, slot is not in the past
    return false;
  }

  bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    // Don't auto-refresh here - it interferes with slot selection

    return Container(
      child: Column(
        children: [
        const SizedBox(height: 15),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      "Court Availability",
                      style: GoogleFonts.inter(
                        fontSize: 23,
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isDate == true &&
                        selectedDateTime != null &&
                        !isSameDate(selectedDateTime!, DateTime.now()))
                      Text(
                        " - ${DateFormat('MMM d, yyyy EEEE').format(selectedDateTime!)}",
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          color: Colors.indigo.shade500,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                Text(
                  "View and manage court bookings",
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            Spacer(),
            if (showTodayButton)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade500,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                child: GestureDetector(
                  onTap: () async {
                    final today = DateTime.now();
                    final todayDate = DateTime(
                      today.year,
                      today.month,
                      today.day,
                    );
                    setState(() {
                      selectedDateTime = todayDate;
                      controller.selectedDate = todayDate;
                      showTodayButton = false;
                    });
                    controller.clearSelectedSlots();
                    selectedSlots.clear();
                    controller.courtList.clear();
                    controller.timeSlots.clear();
                    controller.bookedSlots.clear();
                    slotInfo.clear();
                    slotInfoMap.clear();
                    try {
                      await controller.fetchServiceList();
                      if (controller.serviceList.isNotEmpty) {
                        if (controller.selectedServiceId.value.isEmpty) {
                          controller.selectedServiceId.value =
                              controller.serviceList[0]['id'];
                        }
                        await controller.fetchCourtList();
                        await Future.wait([
                          controller.fetchBookedSlots(),
                          fetchSlotInfo(),
                        ]);
                      }
                    } catch (e) {
                      print('Error fetching data: $e');
                    }
                  },
                  child: Text(
                    'Today',
                    style: GoogleFonts.inter(
                      fontSize: 23,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: () {
                setState(() {
                  isDate = true;
                  _pickDateTime();
                });
              },
              child: Container(
                // padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Palette.newColor),
                ),
                child: Icon(Icons.date_range_sharp, size: 35),
              ),
            ),
            const SizedBox(width: 20),
            Row(
              children:
                  controller.serviceList.take(2).map((item) {
                    final bool isSelected =
                        controller.selectedServiceId.value == item['id'];
                    final bool isDisabled = item['is_available'] == false;

                    return GestureDetector(
                      onTap:
                          isDisabled
                              ? null
                              : () async {
                                if (!isSelected) {
                                  // Clear previous selections when switching category
                                  controller.clearSelectedSlots();
                                  selectedSlots.clear();
                                  setState(() {}); // Update UI
                                  controller.update(); // Notify GetX listeners

                                  final selectedItem = item;
                                  if (selectedItem['is_available']) {
                                    try {
                                      controller.isLoading.value = true;
                                      setState(() {
                                        controller.selectedServiceId.value =
                                            item['id'];
                                      });
                                      await Future.wait([
                                        controller.fetchCourtList(),
                                        controller.fetchBookedSlots(),
                                      ]);
                                      controller.courtList.clear();
                                      await controller.fetchCourtList();
                                      await fetchSlotInfo();
                                    } catch (error) {
                                      print('Error loading data: $error');
                                    } finally {
                                      controller.isLoading.value = false;
                                    }
                                  }
                                }
                              },
                      child: Container(
                        margin: EdgeInsets.only(right: 20),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? Colors.indigo.shade500
                                  : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                isSelected
                                    ? Palette.newColor
                                    : Palette.newColor,
                          ),
                        ),
                        child: Image.asset(
                          item['name'] == 'Badminton'
                              ? 'assets/images/icons/sports-1.png'
                              : 'assets/images/icons/sports-3.png',
                          width: 50,
                          height: 50,
                          fit: BoxFit.fill,
                          color: isSelected ? Colors.white : Colors.grey,
                        ),
                      ),
                    );
                  }).toList(),
            ),

            Obx(() {
              final hasSelectedSlots = controller.selectedCourtSlots.values.any((slots) => slots.isNotEmpty);
              return Row(
                children: [
                  if (hasSelectedSlots) ...[
                    GestureDetector(
                      onTap: () {
                        final grouped = controller.groupSelectedSlots(
                          controller.selectedCourtSlots,
                        );
                        List<BookingInfo> bookings = [];
                        String membershipPlan = '';
                        double memberPrice = 0.0;
                        bool membershipApplied = false;
                        grouped.forEach((court, slotGroups) {
                          // Get the court ID from courtList
                          final courtData = controller.courtList.firstWhere(
                            (c) => c['name'] == court,
                            orElse: () => <String, dynamic>{},
                          );
                          final courtId = courtData['id'] as String?;

                          for (final group in slotGroups) {
                            group.sort();
                            final start = group.first;
                            final lastSlotData = slotInfoMap[group.last];
                            final end =
                            lastSlotData != null
                                ? calculateEndTime(group.last)
                                : calculateEndTime(
                              group.last,
                            ); // fallback, but ideally use slotInfoMap
                            List<BookingSubSlotInfo> subSlots = [];
                            for (String slot in group) {
                              final slotData = slotInfoMap[slot];
                              if (slotData != null) {
                                final subStartTime =
                                    slot; // Slot is already in HH:mm format
                                final subEndTime = calculateEndTime(
                                  slot,
                                ); // Calculate end time for this 30-min slot
                                final subPrice =
                                (slotData['price'] ?? 0.0).toDouble();
                                final subIsPeak = slotData['isPeak'] ?? false;
                                subSlots.add(
                                  BookingSubSlotInfo(
                                    startTime: subStartTime,
                                    endTime: subEndTime,
                                    price: subPrice,
                                    isPeak: subIsPeak,
                                  ),
                                );
                              }
                            }

                            bookings.add(
                              BookingInfo(
                                courtName: court,
                                courtId: courtId,
                                selectedDateTime:
                                selectedDateTime != null
                                    ? selectedDate
                                    : DateTime.now(),
                                selectedDays: [],
                                subSlots: subSlots,
                                bookingId: controller.bookingId,
                              ),
                            );
                          }
                        });
                        openBookingRightDrawer(
                          context,
                          membershipPlan,
                          memberPrice,
                          membershipApplied,
                          (selectedMembershipId != null && selectedMembershipId!.isNotEmpty) ? selectedMembershipId : null,
                          bookings,
                          onCancel: () {
                            setState(
                                  () {},
                            ); // This will force the parent to rebuild and reflect cleared state
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 17,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade500,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Text(
                          'Book Now',
                          style: GoogleFonts.inter(
                            fontSize: 23,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        controller.clearSelectedSlots();
                        setState(() {});
                        // Add this line to ensure UI updates properly
                        controller.update();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 17,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Palette.newColor),
                        ),
                        child: Text(
                          'Clear Selection',
                          style: GoogleFonts.inter(
                            fontSize: 23,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },),
          ],
        ),

        const SizedBox(height: 20),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading courts and time slots...',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (controller.courtList.isEmpty || controller.timeSlots.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sports_tennis,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No courts or time slots available',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final sortedCourts = List<Map<String, dynamic>>.from(
                  controller.courtList,
                )..sort((a, b) {
                  // Extract numbers from court names
                  final aName = a['name'] as String;
                  final bName = b['name'] as String;

                  // Split names into text and number parts
                  final aMatch = RegExp(r'(\D+)(\d+)').firstMatch(aName);
                  final bMatch = RegExp(r'(\D+)(\d+)').firstMatch(bName);

                  if (aMatch != null && bMatch != null) {
                    // Compare text parts first
                    final aText = aMatch.group(1)!;
                    final bText = bMatch.group(1)!;
                    final textCompare = aText.compareTo(bText);

                    if (textCompare != 0) return textCompare;

                    // If text parts are same, compare numbers
                    final aNum = int.parse(aMatch.group(2)!);
                    final bNum = int.parse(bMatch.group(2)!);
                    return aNum.compareTo(bNum);
                  }

                  // Fallback to regular string comparison if pattern doesn't match
                  return aName.compareTo(bName);
                });
                final amSlots =
                    controller.timeSlots.where((slot) {
                      final hour = int.parse(slot.split(":")[0]);
                      return hour < 12;
                    }).toList();

                final pmSlots =
                    controller.timeSlots.where((slot) {
                      final hour = int.parse(slot.split(":")[0]);
                      return hour >= 12;
                    }).toList();

                return Stack(
                  children: [
                    // AM/PM Header
                    Positioned(
                      top: 0,
                      left: 150,
                      right: 0,
                      height: 20,
                      child: SingleChildScrollView(
                        controller: _headerHorizontalController,
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // AM block
                            if (amSlots.isNotEmpty)
                              Container(
                                width: amSlots.length * 80,
                                alignment: Alignment.center,
                                color: Colors.grey.shade200,
                                child: Text(
                                  'AM',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                            // PM block
                            if (pmSlots.isNotEmpty)
                              Container(
                                width: pmSlots.length * 80,
                                alignment: Alignment.center,
                                color: Colors.grey.shade300,
                                child: Text(
                                  'PM',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Top Time Slot Header
                    Positioned(
                      top: 20, // Adjusted position (SizedBox 16 + AM/PM 20)
                      left: 150,
                      right: 0,
                      height: 50,
                      child: SingleChildScrollView(
                        controller: _headerHorizontalController,
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          height: 50,
                          color: Colors.white,
                          child: Row(
                            children: [
                              ...controller.timeSlots.map((slot) {
                                final slotData = slotInfoMap[slot];
                                final isPeak = slotData?['isPeak'] ?? false;
                                courtPrice =
                                    (slotData?['price'] ?? 0.0).toDouble();
                                // Parse and convert to 12-hour format manually (without AM/PM)
                                final parts = slot.split(":");
                                int hour = int.parse(parts[0]);
                                final minute = int.parse(parts[1]);

                                String hour12 = ((hour % 12 == 0)
                                        ? 12
                                        : hour % 12)
                                    .toString()
                                    .padLeft(2, '0');
                                String minuteStr = minute.toString().padLeft(
                                  2,
                                  '0',
                                );
                                final formattedTime = "$hour12:$minuteStr";

                                return Container(
                                  width: 80,
                                  height: 50,
                                  alignment: Alignment.center,
                                  color: Colors.white,
                                  child: Text(
                                    formattedTime,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isPeak
                                              ? Colors.amber.shade500
                                              : Colors.grey.shade500,
                                      fontSize: 18,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Left Court Name Column
                    Positioned(
                      top: 70,
                      left: 0,
                      bottom: 0,
                      width: 150,
                      child: SingleChildScrollView(
                        controller: _leftVerticalController,
                        child: Column(
                          children:
                              sortedCourts.map((court) {
                                return Container(
                                  width: 150,
                                  height: 58,
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  color: Colors.white,
                                  child: Text(
                                    court['name'],
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade900,
                                      fontSize: 22,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ),

                    Positioned(
                      top: 70, // Adjusted position
                      left: 150,
                      right: 0,
                      bottom: 0,
                      child: SingleChildScrollView(
                        controller: _horizontal,
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          controller: _vertical,
                          scrollDirection: Axis.vertical,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Grid Content
                              ...sortedCourts.map((court) {
                                final courtName = court['name'];
                                final selectedSlots = controller.selectedCourtSlots[courtName] ?? [];
                                return Row(
                                  children: [
                                    ...List.generate(controller.timeSlots.length, (
                                      index,
                                    ) {
                                      String slot = controller.timeSlots[index];
                                      final slotData = slotInfoMap[slot];
                                      final isPeak   = slotData?['isPeak'] ?? false;
                                      courtPrice     = (slotData?['price'] ?? 0.0).toDouble();
                                      bool isSelected = selectedSlots.contains(
                                        slot,
                                      );
                                      String? user = getBookingUser(
                                        courtName,
                                        slot,
                                      );
                                      bool isBooked = user != null;
                                      bool isPastSlot = isSlotInPast(slot);

                                      // Merged selection
                                      final isFirstInMerged =
                                          isSelected &&
                                          (index == 0 ||
                                              !selectedSlots.contains(
                                                controller.timeSlots[index - 1],
                                              ));

                                      int mergeSpan = 1;
                                      if (isFirstInMerged) {
                                        for (
                                          int i = index + 1;
                                          i < controller.timeSlots.length;
                                          i++
                                        ) {
                                          if (selectedSlots.contains(
                                            controller.timeSlots[i],
                                          )) {
                                            mergeSpan++;
                                          } else {
                                            break;
                                          }
                                        }
                                      }

                                      if (isSelected && !isFirstInMerged) {
                                        return const SizedBox.shrink();
                                      }
                                      if (isBooked) {
                                        final currentUser = user;
                                        final isFirstBooking =
                                            index == 0 ||
                                            getBookingUser(
                                                  courtName,
                                                  controller.timeSlots[index -
                                                      1],
                                                ) !=
                                                currentUser;

                                        if (!isFirstBooking) {
                                          return const SizedBox.shrink();
                                        }

                                        // Calculate how many adjacent slots are booked by the same user
                                        int span = 1;
                                        for (
                                          int i = index + 1;
                                          i < controller.timeSlots.length;
                                          i++
                                        ) {
                                          if (getBookingUser(
                                                courtName,
                                                controller.timeSlots[i],
                                              ) ==
                                              currentUser) {
                                            span++;
                                          } else {
                                            break;
                                          }
                                        }

                                        return GestureDetector(
                                          onTap: () {
                                            final slotTime = parseTime(
                                              controller.timeSlots[index],
                                            );
                                            final courtId =
                                                controller.courtList.firstWhere(
                                                  (c) => c['name'] == courtName,
                                                  orElse:
                                                      () => <String, dynamic>{},
                                                )?['id'];

                                            // Find the booking for this court and slot
                                            final bookingSlot = controller
                                                .bookedSlots
                                                .firstWhereOrNull((b) {
                                                  return b.courtId == courtId &&
                                                      b.startTime != null &&
                                                      b.endTime != null &&
                                                      !slotTime.isBefore(
                                                        b.startTime!,
                                                      ) &&
                                                      slotTime.isBefore(
                                                        b.endTime!,
                                                      );
                                                });

                                            if (bookingSlot != null) {
                                              // Find the merged block for this user/court
                                              int startIdx = index;
                                              int endIdx = index;

                                              // Expand left
                                              while (startIdx > 0) {
                                                final prevUser = getBookingUser(
                                                  courtName,
                                                  controller
                                                      .timeSlots[startIdx - 1],
                                                );
                                                if (prevUser == currentUser) {
                                                  startIdx--;
                                                } else {
                                                  break;
                                                }
                                              }
                                              // Expand right
                                              while (endIdx <
                                                  controller.timeSlots.length -
                                                      1) {
                                                final nextUser = getBookingUser(
                                                  courtName,
                                                  controller.timeSlots[endIdx +
                                                      1],
                                                );
                                                if (nextUser == currentUser) {
                                                  endIdx++;
                                                } else {
                                                  break;
                                                }
                                              }

                                              final mergedStart = parseTime(
                                                controller.timeSlots[startIdx],
                                              );
                                              final mergedEnd = parseTime(
                                                controller.timeSlots[endIdx],
                                              ).add(Duration(minutes: 30));
                                              print(
                                                'Merged booking: start=$mergedStart, end=$mergedEnd',
                                              );

                                              // // Your existing logic for extension drawer
                                              // final isCurrentUser =
                                              //     bookingSlot.name ==
                                              //     currentUser;
                                              // final hasMembership =
                                              //     (bookingSlot.membershipPlanId ??
                                              //             '')
                                              //         .isNotEmpty;
                                              // if (isCurrentUser &&
                                              //     hasMembership) {
                                              openExtendedbookingRightDrawer(
                                                context,
                                                bookingSlot,
                                                mergedStartTime: mergedStart,
                                                mergedEndTime: mergedEnd,
                                                controller: controller,
                                                updateTotalPrice:
                                                    () => totalPrice,
                                                onMembershipApplied:
                                                    (price, isApplied) {},
                                                onRefresh: () {
                                                  controller.fetchBookedSlots();
                                                  fetchSlotInfo();
                                                },
                                                slotInfoMap: slotInfoMap,
                                              );
                                              controller.fetchBookedSlots();
                                              fetchSlotInfo();
                                              if (mounted) setState(() {});
                                              // }
                                              // else {
                                              //   ScaffoldMessenger.of(
                                              //     context,
                                              //   ).showSnackBar(
                                              //     SnackBar(
                                              //       content: Text(
                                              //         'Only your own bookings with membership can be extended.',
                                              //       ),
                                              //       backgroundColor: Colors.red,
                                              //     ),
                                              //   );
                                              // }
                                            }
                                          },
                                          child: Container(
                                            width: span * 80.0,
                                            height: 58,
                                            alignment: Alignment.center,
                                            margin: EdgeInsets.zero,
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              border: Border.all(
                                                color: Colors.grey.shade200,
                                              ),
                                            ),
                                            child: Text(
                                              currentUser,
                                              style: GoogleFonts.inter(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.red.shade500,
                                              ),
                                            ),
                                          ),
                                        );
                                      }

                                      return GestureDetector(
                                        onTapDown: (TapDownDetails details) {
                                          if (isBooked || isPastSlot) return;
                                          setState(() {
                                            final selected =
                                                controller
                                                    .selectedCourtSlots[courtName] ??
                                                [];
                                            if (selected.contains(slot)) {
                                              int clickedSlotIndex = index;
                                              if (mergeSpan > 1) {
                                                double slotWidth = 80.0;
                                                double tapX =
                                                    details.localPosition.dx;

                                                int slotOffset =
                                                    (tapX / slotWidth).floor();
                                                clickedSlotIndex =
                                                    index + slotOffset;
                                                if (clickedSlotIndex < 0 ||
                                                    clickedSlotIndex >=
                                                        controller
                                                            .timeSlots
                                                            .length ||
                                                    !selected.contains(
                                                      controller
                                                          .timeSlots[clickedSlotIndex],
                                                    )) {
                                                  clickedSlotIndex = index;
                                                }
                                              }
                                              String slotToRemove =
                                                  controller
                                                      .timeSlots[clickedSlotIndex];
                                              selected.remove(slotToRemove);

                                              controller
                                                      .selectedCourtSlots[courtName] =
                                                  selected;
                                            } else {
                                              bool isAdjacentToAny = false;
                                              for (var existingSlot
                                                  in selected) {
                                                if (isAdjacent(
                                                  slot,
                                                  existingSlot,
                                                )) {
                                                  isAdjacentToAny = true;
                                                  break;
                                                }
                                              }

                                              if (selected.isEmpty ||
                                                  isAdjacentToAny) {
                                                selected.add(slot);
                                              } else {
                                                selected.add(slot);
                                              }
                                              controller
                                                      .selectedCourtSlots[courtName] =
                                                  selected;
                                            }
                                            controller.selectedCourt.value =
                                                courtName;
                                          });
                                          // Add this line to notify GetX listeners
                                          controller.update();
                                        },
                                        child: Container(
                                          width: 80.0 * mergeSpan,
                                          height: 58,
                                          alignment: Alignment.center,
                                          margin: EdgeInsets.zero,
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? Colors.green
                                                    : isPastSlot
                                                    ? Colors.grey.shade300
                                                    : isPeak
                                                    ? Colors.amber.shade50
                                                    : Colors.green.shade50,
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                            ),
                                            // borderRadius: BorderRadius.circular(
                                            //   4,
                                            // ),
                                          ),
                                          child: Icon(
                                            isSelected
                                                ? Icons.check
                                                : isPastSlot
                                                ? Icons.access_time
                                                : Icons.access_time,
                                            color:
                                                isSelected
                                                    ? Colors.white
                                                    : isPastSlot
                                                    ? Colors.grey.shade500
                                                    : isPeak
                                                    ? Colors.amber.shade500
                                                    : Colors.green.shade500,
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Top-left static corner
                    Positioned(
                      top: 0,
                      left: 0,
                      width: 150,
                      height: 70,
                      child: Container(
                        color: Colors.white,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'Court/Time',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade400,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          }),
        ),
      ],
    ),
    );
  }

  BookingModel? getBookingModelForUser(
    String userName,
    List<BookingModel> bookings,
  ) {
    return bookings.firstWhereOrNull((b) => b.customerName == userName);
  }

  DateTime parseTime(String slot) {
    try {
      final parts = slot.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final date = selectedDateTime ?? DateTime.now();
      return DateTime(date.year, date.month, date.day, hour, minute, 0, 0, 0);
    } catch (e) {
      print('Error parsing time: $e');
      return DateTime.now();
    }
  }

  String? getBookingUser(String courtName, String slot) {
    final slotTime = parseTime(slot);

    for (var booking in controller.bookedSlots) {
      final court = controller.courtList.firstWhere(
        (c) => c['id'] == booking.courtId,
        orElse: () => {},
      );
      if (court == null || court['name'] != courtName) continue;

      if (booking.startTime != null &&
          slotTime.isAtSameMomentAs(booking.startTime!)) {
        return booking.name;
      }
    }
    return null;
  }

  int getBookingSpan(String courtName, String slot) {
    final slotTime = parseTime(slot);

    for (var booking in controller.bookedSlots) {
      final court = controller.courtList.firstWhere(
        (c) => c['id'] == booking.courtId,
        orElse: () => {},
      );
      if (court == null || court['name'] != courtName) {
        continue;
      }

      if (slotTime.isAtSameMomentAs(booking.startTime!)) {
        final duration = booking.endTime!.difference(booking.startTime!);
        return (duration.inMinutes / 30).round(); // 30-min slots
      }
    }
    return 1;
  }

  void _pickDateTime() async {
    // Step 1: Pick Date
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            // Main dialog styling
            // dialogTheme: DialogTheme(
            //   shape: RoundedRectangleBorder(
            //     borderRadius: BorderRadius.circular(16),
            //   ),
            //   elevation: 4,
            //   backgroundColor: Colors.white,
            // ),
            colorScheme: ColorScheme.light(
              primary: Colors.blue, // Header color
              onPrimary: Colors.white, // Header text color
              surface: Colors.white, // Calendar background
              onSurface: Colors.black, // Default text color
            ),
            materialTapTargetSize: MaterialTapTargetSize.padded,
          ),
          child: MediaQuery(
            // Overall scaling
            data: MediaQuery.of(context).copyWith(
              textScaleFactor:
                  1.7, // Slightly reduced from 1.9 for better proportions
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 20,
              ), // Add padding around the picker
              child: child!,
            ),
          ),
        );
      },
    );

    if (pickedDate == null) return;
    final today = DateTime.now();
    // Combine Date and Time
    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
    );

    // Clear all selections before updating date
    controller.clearSelectedSlots();
    selectedSlots.clear();
    controller.update(); // Notify GetX listeners

    setState(() {
      selectedDateTime = combined;
      controller.selectedDate = combined; // Update controller's selected date
      showTodayButton =
          !(combined.year == today.year &&
              combined.month == today.month &&
              combined.day == today.day);
    });

    // Clear all data before fetching new data
    controller.courtList.clear();
    controller.timeSlots.clear();
    controller.bookedSlots.clear();
    slotInfo.clear();
    slotInfoMap.clear();

    try {
      // Fetch data in sequence to respect dependencies
      await controller.fetchServiceList();

      if (controller.serviceList.isNotEmpty) {
        // Set initial service ID if not already set
        if (controller.selectedServiceId.value.isEmpty) {
          controller.selectedServiceId.value = controller.serviceList[0]['id'];
        }

        // Fetch court list first as it's needed for slots
        await controller.fetchCourtList();

        // Then fetch booked slots and slot info
        await Future.wait([controller.fetchBookedSlots(), fetchSlotInfo()]);
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  String calculateEndTime(String lastSlot) {
    final parts = lastSlot.split(":");
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);

    // Add 30 minutes to the last slot
    minute += 30;
    if (minute >= 60) {
      hour += 1;
      minute -= 60;
    }

    // Format time back as HH:mm
    final endHour = hour.toString().padLeft(2, '0');
    final endMinute = minute.toString().padLeft(2, '0');
    return "$endHour:$endMinute";
  }

  double calculatePrice(int durationInMinutes) {
    // Get all selected slots for the current court
    final selectedSlots =
        controller.selectedCourtSlots[controller.selectedCourt] ?? [];
    print("Previous selectedslots : $selectedSlots");
    // Calculate total price by summing up each slot's price
    double totalPrice = 0.0;
    for (String slot in selectedSlots) {
      // Get price for this specific slot from slotInfoMap
      final slotData = slotInfoMap[slot];
      final slotPrice = slotData?['price'] ?? 0.0;
      totalPrice += slotPrice;
    }

    return totalPrice;
  }

  int calculatePeakDuration(List<String> slots) {
    int peakDuration = 0;
    for (String slot in slots) {
      final slotData = slotInfoMap[slot];
      if (slotData?['isPeak'] ?? false) {
        peakDuration += 30; // Each slot is 30 minutes
      }
    }
    return peakDuration;
  }

  bool isAdjacent(String slot1, String slot2) {
    final format = DateFormat.Hm();
    final time1 = format.parse(slot1);
    final time2 = format.parse(slot2);
    return time1.difference(time2).inMinutes.abs() == 30;
  }

  void updateTotalPrice() {
    if (isMembershipApplied) {
      totalPrice = courtPrice + membershipPrice;
    } else {
      totalPrice = courtPrice;
    }
    setState(() {}); // update UI
  }

  Future<void> openBookingRightDrawer(
    BuildContext context,
    String membershipPlan,
    double memberPrice,
    bool isMembershipApplied,
    String? membershipId,
    List<BookingInfo> bookings, {
    VoidCallback? onCancel,
  }) async {
    Color? borderColor;
    Color? backgroundColor;
    Color? textColor;
    if (membershipPlan != null) {
      if (membershipPlan.toLowerCase().contains('gold') ||
          membershipPlan.contains('Gold')) {
        borderColor = Colors.amber.shade500;
        backgroundColor = Colors.amber.shade50;
        textColor = Colors.amber.shade800;
      } else if (membershipPlan.toLowerCase().contains('platinum') ||
          membershipPlan.contains('Platinum')) {
        borderColor = Colors.indigo.shade500;
        backgroundColor = Colors.indigo.shade50;
        textColor = Colors.indigo.shade700;
      } else {
        borderColor = Colors.grey.shade300;
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.black;
      }
    }

    bool membershipInCart = false;

    void _clearMembershipData() {
      setState(() {
        hasMembership = false;
        hasPendingMembership = false;
        memberPeakPrice = null;
        memberNonPeakPrice = null;
        membershipPlan = '';
        membershipValidityDate = null;
        isMembershipApplied = false;
        membershipPrice = 0.0;
        updateCourtPrice();
        membershipInCart = false;
      });
    }

    void _updateUserData(Map<String, dynamic> userData) async {
      // Use a small delay to ensure UI is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          nameController.text = userData['name'] ?? '';
          mobileController.text = userData['mobile'] ?? '';
        });
      });

      // Check membership_data table for pending membership
      bool hasPendingMembership = false;
      DateTime? membershipValidityFromCheck;

      if (userData['id'] != null) {
        final SharedPreferences preferences = await SharedPreferences.getInstance();
        String? centerSlug = preferences.getString('centerSlug');

        try {
          final membershipDataCheck = await supabase
              .schema('${centerSlug}_prod_schema')
              .from('membership_data')
              .select('*')
              .eq('customer_id', userData['id'])
              .maybeSingle();

          if (membershipDataCheck != null) {
            if (membershipDataCheck['status'] == false) {
              hasPendingMembership = true;
              print('⚠️ Customer has pending membership payment');
            } else if (membershipDataCheck['status'] == true) {
              // Customer has active membership in membership_data table
              // This should be treated as having membership
              hasPendingMembership = false;
              print('✅ Customer has active membership in membership_data');

              DateTime? startDate = membershipDataCheck != null ? DateTime.tryParse(membershipDataCheck['created_at']?.toString() ?? '') : null;
              DateTime? endDate;
              if (startDate != null && membershipDataCheck != null && membershipDataCheck['validity'] != null) {
                final billingCycle = membershipDataCheck['billing_cycle']?.toString().toLowerCase();
                final validity     = int.tryParse(membershipDataCheck['validity'].toString()) ?? 0;

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
              membershipValidityFromCheck = endDate;

            }
          }
        } catch (e) {
          print('Error checking membership_data: $e');
        }
      }

      setState(() {
        // Update pending membership status
        this.hasPendingMembership = hasPendingMembership;

        // Only set hasMembership to true if there's NO pending membership
        hasMembership = !hasPendingMembership && (userData['membershipplan_id'] != null && userData['membershipplan_id'].toString().isNotEmpty);

        if (hasMembership && !hasPendingMembership) {
          memberPeakPrice         = double.tryParse(userData['peak_price']?.toString() ?? '0');
          memberNonPeakPrice      = double.tryParse(userData['non_peak_price']?.toString() ?? '0');
          membershipPlan          = userData['membership_plan'];
          membershipValidityDate  = DateTime.tryParse(membershipValidityFromCheck.toString() ?? '');
        } else {
          // Reset membership data if no membership
          memberPeakPrice = null;
          memberNonPeakPrice = null;
          membershipPlan = '';
          membershipValidityDate = null;
          isMembershipApplied = false;
          membershipPrice = 0.0;
        }
        if(userData['already_in_cart']==true) {
          membershipInCart = true;
        }
        updateCourtPrice();
      });
    }

    Future<void> _validateAndFetchUserData(String mobile) async {
      if (mobile.length == 12) {
        final suggestions = await controller.fetchUserSuggestions(mobile);
        if (suggestions.isNotEmpty) {
          final exactMatch = suggestions.firstWhere((user) => user['mobile'] == mobile, orElse: () => {},);
          if (exactMatch.isNotEmpty) {
            _updateUserData(exactMatch);
          } else {
            _clearMembershipData();
          }
        } else {
          _clearMembershipData();
        }
      } else {
        _clearMembershipData();
      }
    }

    if (!mounted) return;
    await showGeneralDialog(
      context: context,
      barrierLabel: "New Booking",
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0), // from right
            end: Offset.zero,
          ).animate(animation),
          child: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: MediaQuery.of(context).size.width / 2.5,
              child: Material(
                color: Colors.white,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    setState(() {
                      courtPrice = bookings.fold(
                        0.0,
                        (sum, b) =>
                            sum +
                            b.subSlots.fold(0.0, (subSum, subSlot) {
                              // Always use regular price - let checkout handle membership discounts
                              double price = (subSlot.price is num) ? subSlot.price.toDouble() : 0.0;
                              return subSum + price;

                              /* Don't apply membership prices here - moved to checkout
                              double price;
                              if (hasMembership && memberPeakPrice != null && memberNonPeakPrice != null) {
                                final isMembershipExpired = membershipValidityDate != null && membershipValidityDate!.isBefore(DateTime.now());
                                if(isMembershipExpired) {
                                  price = (subSlot.price is num) ? subSlot.price.toDouble() : 0.0;
                                } else {
                                  price = subSlot.isPeak ? memberPeakPrice! : memberNonPeakPrice!;
                                }
                              } else {
                                price = (subSlot.price is num) ? subSlot.price.toDouble() : 0.0;
                              }
                              */
                            }),
                      );
                    });
                    totalPrice = courtPrice + (isMembershipApplied ? memberPrice : 0.0);
                    final selectedName =
                        controller.serviceList.firstWhere(
                          (e) =>
                              e['id'].toString() ==
                              controller.selectedServiceId.toString(),
                          orElse: () => null,
                        )?['name'] ??
                        'Unknown';
                    return Container(
                      color: Colors.white,
                      height: MediaQuery.of(context).size.height,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'New Booking',
                                    style: GoogleFonts.inter(
                                      fontSize: 22,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Create new booking based on selected courts',
                                    style: GoogleFonts.inter(
                                      fontSize: 20,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    selectedDateTime != null
                                        ? DateFormat(
                                          'd MMM yyyy',
                                        ).format(selectedDateTime!)
                                        : DateFormat(
                                          'd MMM yyyy',
                                        ).format(DateTime.now()),
                                    style: GoogleFonts.inter(
                                      fontSize: 20,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    // selectedDateTime != null
                                    //     ? DateFormat(
                                    //       'h:mm a',
                                    //     ).format(selectedDateTime!)
                                    //     :
                                    DateFormat('h:mm a').format(DateTime.now()),
                                    style: GoogleFonts.inter(
                                      fontSize: 20,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Divider(color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Form(
                            key: _formKey,
                            child: Row(
                              spacing: 30,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [

                                //Mobile Field
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Mobile',
                                        style: GoogleFonts.inter(
                                          fontSize: 22,
                                          color: Colors.grey.shade900,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: 200,
                                          maxWidth: MediaQuery.of(context).size.width * 0.50,
                                        ),
                                        child: Autocomplete<Map<String, dynamic>>(
                                          displayStringForOption: (option) => option['mobile'] ?? '',
                                          optionsBuilder: (TextEditingValue textEditingValue) async {
                                            if (textEditingValue.text.isEmpty) {
                                              return const Iterable<Map<String, dynamic>>.empty();
                                            }
                                            return await controller.fetchUserSuggestions(textEditingValue.text);
                                          },
                                          onSelected: (Map<String, dynamic> selection) {
                                            _updateUserData(selection);
                                            // Hide keyboard after selection
                                            FocusScope.of(context).unfocus();
                                          },
                                          fieldViewBuilder: (BuildContext context,
                                              TextEditingController fieldTextEditingController,
                                              FocusNode fieldFocusNode,
                                              VoidCallback onFieldSubmitted) {

                                            if (mobileController.text != fieldTextEditingController.text) {
                                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                                fieldTextEditingController.text = mobileController.text;
                                              });
                                            }

                                            return TextFormField(
                                              controller: fieldTextEditingController,
                                              focusNode: fieldFocusNode,
                                              keyboardType: TextInputType.phone,
                                              textInputAction: TextInputAction.done, // Changed to 'done' for better UX
                                              inputFormatters: [
                                                FilteringTextInputFormatter.digitsOnly,
                                                MobileNumberFormatter(),
                                              ],
                                              onChanged: (value) {
                                                mobileController.text = value;
                                                if (value.length < 12) { // Only clear if not a complete number
                                                  _clearMembershipData();
                                                }
                                              },
                                              onFieldSubmitted: (value) {
                                                final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
                                                if (digitsOnly.length == 10) {
                                                  _validateAndFetchUserData(value);
                                                } else {
                                                  _clearMembershipData();
                                                }
                                                FocusScope.of(context).unfocus();
                                              },
                                              onEditingComplete: () {
                                                final digitsOnly = mobileController.text.replaceAll(RegExp(r'\D'), '');
                                                if (digitsOnly.length == 10) {
                                                  _validateAndFetchUserData(mobileController.text);
                                                } else {
                                                  _clearMembershipData();
                                                }
                                                FocusScope.of(context).unfocus();
                                              },
                                              validator: (value) {
                                                final digitsOnly = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                                                if (digitsOnly.isEmpty) return 'Mobile number is required';
                                                if (digitsOnly.length != 10) return 'Enter a valid 10-digit number';
                                                return null;
                                              },
                                              style: GoogleFonts.inter(
                                                fontSize: 22,
                                                color: Colors.grey.shade800,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding: const EdgeInsets.symmetric(
                                                  vertical: 15,
                                                  horizontal: 12,
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: BorderSide(
                                                    color: Colors.grey.shade300,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                          optionsViewBuilder: (BuildContext context,
                                              AutocompleteOnSelected<Map<String, dynamic>> onSelected,
                                              Iterable<Map<String, dynamic>> options) {
                                            return Align(
                                              alignment: Alignment.topLeft,
                                              child: Material(
                                                elevation: 4.0,
                                                child: SizedBox(
                                                  width: 350,
                                                  height: 200,
                                                  child: ListView.builder(
                                                    padding: EdgeInsets.zero,
                                                    itemCount: options.length,
                                                    itemBuilder: (BuildContext context, int index) {
                                                      final Map<String, dynamic> option = options.elementAt(index);
                                                      return ListTile(
                                                        title: Text(
                                                          option['name'],
                                                          style: const TextStyle(fontSize: 22),
                                                        ),
                                                        subtitle: Text(
                                                          option['mobile'],
                                                          style: const TextStyle(fontSize: 22),
                                                        ),
                                                        onTap: () {
                                                          onSelected(option);
                                                          // Hide keyboard after tap
                                                          FocusScope.of(context).unfocus();
                                                        },
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Name Field
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Name',
                                            style: GoogleFonts.inter(
                                              fontSize: 22,
                                              color: Colors.grey.shade900,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          if (hasMembership) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: backgroundColor,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: borderColor!,
                                                ),
                                              ),
                                              child: Text(() {
                                                  if (membershipValidityDate == null) {
                                                    return '$membershipPlan : (No Validity Info)';
                                                  }
                                                  final now     = DateTime.now();
                                                  final today   = DateTime(now.year, now.month, now.day);
                                                  final expiry  = DateTime(
                                                    membershipValidityDate!.year,
                                                    membershipValidityDate!.month,
                                                    membershipValidityDate!.day,
                                                  );
                                                  final difference = expiry.difference(today).inDays;
                                                  if (difference > 0) {
                                                    return '$membershipPlan : (Valid for $difference days)';
                                                  } else if (difference == 0) {
                                                    return '$membershipPlan : (Expires Today)';
                                                  } else {
                                                    return '$membershipPlan : (Expired)';
                                                  }
                                                }(),
                                                style: GoogleFonts.inter(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: 200,
                                          maxWidth: MediaQuery.of(context).size.width * 0.50,
                                        ),
                                        child: TypeAheadField<Map<String, dynamic>>(
                                          controller: nameController,
                                          suggestionsCallback: (pattern) async {
                                            if (pattern.isEmpty) return [];
                                            await Future.delayed(Duration(milliseconds: 300)); // Debounce
                                            return await controller.fetchUserSuggestions(pattern);
                                          },
                                          builder: (context, _, focusNode) {
                                            return TextFormField(
                                              controller: nameController,
                                              focusNode: focusNode,
                                              keyboardType: TextInputType.name,
                                              validator: (value) {
                                                if (value == null || value.trim().isEmpty) {
                                                  return 'Name is required';
                                                }
                                                return null;
                                              },
                                              onFieldSubmitted: (value) async {
                                                final suggestions = await controller.fetchUserSuggestions(value);
                                                if (suggestions.isNotEmpty) {
                                                  _updateUserData(suggestions.first);
                                                  FocusScope.of(context).unfocus();
                                                }
                                              },
                                              style: GoogleFonts.inter(
                                                fontSize: 22,
                                                color: Colors.grey.shade800,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding: const EdgeInsets.symmetric(
                                                  vertical: 15,
                                                  horizontal: 12,
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: BorderSide(
                                                    color: Colors.grey.shade300,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                          itemBuilder: (context, suggestion) {
                                            return ListTile(
                                              title: Text(
                                                suggestion['name'],
                                                style: TextStyle(fontSize: 22),
                                              ),
                                              subtitle: Text(
                                                suggestion['mobile'],
                                                style: TextStyle(fontSize: 22),
                                              ),
                                            );
                                          },
                                          onSelected: (suggestion) async {
                                            print('Selected customer data: $suggestion');
                                            FocusScope.of(context).unfocus();
                                            _updateUserData(suggestion);
                                            if(suggestion['already_in_cart']==true) {
                                              membershipInCart = true;
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Booking Information',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                bookings.isNotEmpty ? selectedName : '',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Booking Details List
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                ), // outer border
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Column(
                                      children: List.generate(bookings.length, (
                                        index,
                                      ) {
                                        final booking = bookings[index];
                                        final isLast =
                                            index == bookings.length - 1;

                                        return Column(
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 15.0,
                                                    vertical: 12,
                                                  ),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        flex: 2,
                                                        child: Text(
                                                          booking.courtName,
                                                          style:
                                                              GoogleFonts.inter(
                                                                fontSize: 22,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color:
                                                                    Colors
                                                                        .black,
                                                              ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                                        child: Text(
                                                          "\$${booking.subSlots.fold(0.0, (sum, subSlot) {
                                                            // Always show regular price - membership discount shown in checkout
                                                            return sum + subSlot.price;
                                                          }).toStringAsFixed(2)}",
                                                          textAlign: TextAlign.right,
                                                          style: GoogleFonts.inter(
                                                             fontSize: 22,
                                                             fontWeight: FontWeight.w600,
                                                             color: Colors.grey.shade900,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 5),
                                                  Row(
                                                    children: [
                                                      if (booking.subSlots.any((subSlot) => subSlot.isPeak,)) ...[
                                                        Expanded(
                                                          flex: 4,
                                                          child: Text.rich(
                                                            TextSpan(
                                                              children: [
                                                                TextSpan(
                                                                  text:
                                                                      "${booking.subSlots.first.startTime} - ${booking.subSlots.last.endTime}",
                                                                  style: GoogleFonts.inter(
                                                                    fontSize:
                                                                        22,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color:
                                                                        Colors
                                                                            .green
                                                                            .shade600,
                                                                  ),
                                                                ),
                                                                TextSpan(
                                                                  text:
                                                                      " (${booking.subSlots.fold(0, (sum, subSlot) => sum + (subSlot.isPeak ? 30 : 0))} mins peak)",
                                                                  style: GoogleFonts.inter(
                                                                    fontSize:
                                                                        22,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    color:
                                                                        Colors
                                                                            .orange
                                                                            .shade700,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ] else ...[
                                                        Expanded(
                                                          flex: 4,
                                                          child: Text(
                                                            "${booking.subSlots.first.startTime} - ${booking.subSlots.last.endTime}",
                                                            style: GoogleFonts.inter(
                                                              fontSize: 22,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  Colors
                                                                      .green
                                                                      .shade600,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                      Expanded(
                                                        flex: 2,
                                                        child: Text(
                                                          "${booking.subSlots.length * 30}mins",
                                                          style:
                                                              GoogleFonts.inter(
                                                                fontSize: 22,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color:
                                                                    Colors
                                                                        .indigo
                                                                        .shade500,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (!isLast)
                                              Divider(
                                                height: 2,
                                                color: Colors.grey.shade300,
                                              ), // bottom line for each row
                                          ],
                                        );
                                      }),
                                    ),
                                    Obx(() {
                                      return ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: cartController.cartItems.length,
                                        itemBuilder: (_, index) {
                                          final item = cartController.cartItems[index];
                                          return Dismissible(
                                            key: ValueKey(item.product.id),
                                            direction: DismissDirection.endToStart,
                                            background: Container(
                                              color: Colors.red,
                                              alignment: Alignment.centerRight,
                                              padding: const EdgeInsets.symmetric(horizontal: 20,),
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            onDismissed: (_) => cartController.removeItem(item),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10,),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item.product.name,
                                                      style: const TextStyle(
                                                        fontSize: 22,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Container(
                                                    width: MediaQuery.of(context,).size.width / 14,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                        color: Colors.grey.shade400,
                                                      ),
                                                      borderRadius: BorderRadius.circular(8,),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        IconButton(
                                                          onPressed: () => cartController.decrementQty(item,),
                                                          icon: const Icon(
                                                            Icons.remove,
                                                            size: 25,
                                                          ),
                                                        ),
                                                        Text(
                                                          '${item.quantity}',
                                                          style: const TextStyle(fontSize: 22,),
                                                        ),
                                                        IconButton(
                                                          onPressed: () => cartController.incrementQty(item,),
                                                          icon: const Icon(
                                                            Icons.add,
                                                            size: 25,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    width: 110,
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                      children: [
                                                        Text(
                                                          '\$${item.appliedPrice.toStringAsFixed(2)}',
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 22,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          Container(height: 360, child: AddonItemsWidget()),

                          SizedBox(height: 10),
                          if (isMembershipApplied) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: MediaQuery.of(context).size.width / 3,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: backgroundColor,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: borderColor!),
                                  ),

                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '$membershipPlan Membership',
                                        style: GoogleFonts.inter(
                                          fontSize: 23,
                                          color: textColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),

                                      Text(
                                        '\$ ${memberPrice.toStringAsFixed(2)}',
                                        style: GoogleFonts.inter(
                                          fontSize: 23,
                                          color: textColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      isMembershipApplied =
                                          !isMembershipApplied;
                                      updateTotalPrice();
                                    });
                                  },
                                  icon: Icon(
                                    LucideIcons.trash2,
                                    size: 30,
                                    color: Colors.grey.shade900,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    minimumSize: const Size(70, 45),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      side: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                          ] else ...[
                            Divider(color: Colors.grey.shade300),
                            Row(
                              children: [
                                Spacer(),
                                if (hasMembership &&
                                    memberPeakPrice != null &&
                                    memberNonPeakPrice != null) ...[
                                  Text(
                                    'Total',
                                    style: GoogleFonts.inter(
                                      fontSize: 25,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Obx(
                                    () => Text(
                                      '\$ ${(totalPrice + cartController.total).toStringAsFixed(2)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 25,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    'Total',
                                    style: GoogleFonts.inter(
                                      fontSize: 23,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Obx(
                                    () => Text(
                                      '\$ ${(totalPrice + cartController.total).toStringAsFixed(2)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 25,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                          if (isMembershipApplied && membershipValidityDate != null && membershipValidityDate!.difference(DateTime.now()).inDays > 0) ...[
                            //Spacer(),
                            Divider(color: Colors.grey.shade300),
                            Row(
                              children: [
                                Spacer(),
                                Text(
                                  'Total',
                                  style: GoogleFonts.inter(
                                    fontSize: 23,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Obx(
                                  () => Text(
                                    '\$ ${(totalPrice + cartController.total).toStringAsFixed(2)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 25,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              spacing: 20,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      controller.clearSelectedSlots();
                                      nameController.clear();
                                      mobileController.clear();
                                      hasMembership = false;
                                      isMembershipApplied = false;
                                      membershipPrice = 0.0;
                                      selectedMembershipId = null;
                                      selectedSlots.clear();
                                      cartController.clearCart();
                                      if (onCancel != null)
                                        onCancel(); // notify parent to refresh
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.shade300,
                                      foregroundColor: Colors.white,
                                      minimumSize: Size.fromHeight(65),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      "Cancel",
                                      style: GoogleFonts.inter(
                                        fontSize: 22,

                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {

                                        //Navigator.pop(context);
                                        final double TotalAmount;
                                        final digitsOnly = mobileController.text.replaceAll(RegExp(r'\D'), '');
                                        controller.getUserDatabyMobile(digitsOnly,);

                                        if (isMembershipApplied) {
                                          TotalAmount = courtPrice + memberPrice + cartController.total;
                                        } else {
                                          TotalAmount = courtPrice + cartController.total;
                                        }

                                        showBookingConfirmationDialog(
                                          context,
                                          nameController.text,
                                          mobileController.text,
                                          selectedName,
                                          TotalAmount,
                                          selectedDateTime ?? DateTime.now(),
                                          bookings,
                                          membershipId,
                                          membershipPlan,
                                          isMembershipApplied,
                                          memberPrice,
                                        );

                                      } else {

                                        showCustomSnackbar(
                                          'Error :',
                                          'Please enter name & mobile for bookingslots',
                                          Colors.redAccent,
                                        );

                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      minimumSize: Size.fromHeight(65),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text("Quick Booking",
                                      style: GoogleFonts.inter(
                                        fontSize: 22,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            // Bottom Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              spacing: 30,
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      print('test');
                                      controller.clearSelectedSlots();
                                      nameController.clear();
                                      mobileController.clear();
                                      hasMembership = false;
                                      isMembershipApplied = false;
                                      membershipPrice = 0.0;
                                      selectedMembershipId = null;
                                      selectedSlots.clear();
                                      cartController.clearCart();
                                      fetchSlotInfo();
                                      if (onCancel != null)
                                        onCancel(); // notify parent to refresh
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.shade300,
                                      foregroundColor: Colors.white,
                                      minimumSize: Size.fromHeight(65),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      "Cancel",
                                      style: GoogleFonts.inter(
                                        fontSize: 23,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                // if (isMembershipApplied) ...[
                                //   Expanded(
                                //     child: ElevatedButton(
                                //       onPressed: () {
                                //         Navigator.pop(context);
                                //         showAdvanceBookingDialog(context, bookings);
                                //       },
                                //       style: ElevatedButton.styleFrom(
                                //         backgroundColor: Colors.black,
                                //         foregroundColor: Colors.white,
                                //       ),
                                //       child: Text(
                                //         "Advance Booking",
                                //         style: GoogleFonts.inter(
                                //           fontSize: 17,
                                //           color: Colors.white,
                                //           fontWeight: FontWeight.w600,
                                //         ),
                                //       ),
                                //     ),
                                //   ),
                                // ]
                                //else ...[
                                if (!membershipInCart && !hasMembership && !hasPendingMembership || (membershipValidityDate != null && membershipValidityDate!.difference(DateTime.now()).inDays <= 0)) ...[
                                  // Expanded(
                                  //   child: ElevatedButton(
                                  //     onPressed:
                                  //         (nameController.text
                                  //                     .trim()
                                  //                     .isNotEmpty ||
                                  //                 mobileController.text
                                  //                     .trim()
                                  //                     .isNotEmpty)
                                  //             ? () async {
                                  //               // First get user data if mobile is entered
                                  //               final digitsOnly = mobileController.text.replaceAll(RegExp(r'\D'), '');
                                  //               if (digitsOnly.length == 10) {
                                  //                 await controller.getUserDatabyMobile(digitsOnly);
                                  //               }
                                  //
                                  //               // Check for pending membership payment
                                  //               final hasPending = await checkPendingMembershipPayment();
                                  //               if (hasPending) {
                                  //                 showCustomSnackbar(
                                  //                   'Error',
                                  //                   'This customer has a pending membership payment. Please complete the existing payment first.',
                                  //                   Colors.redAccent,
                                  //                 );
                                  //                 return;
                                  //               }
                                  //
                                  //               Navigator.pop(context);
                                  //               openMembershipDrawer(
                                  //                 context,
                                  //                 bookings,
                                  //                 onCancel: null,
                                  //               );
                                  //             }
                                  //             : null, // disables the button if both are empty
                                  //     style: ElevatedButton.styleFrom(
                                  //       backgroundColor:
                                  //           (nameController.text
                                  //                       .trim()
                                  //                       .isNotEmpty ||
                                  //                   mobileController.text
                                  //                       .trim()
                                  //                       .isNotEmpty)
                                  //               ? Colors.black
                                  //               : Colors
                                  //                   .grey, // visually indicate disabled
                                  //
                                  //       foregroundColor: Colors.white,
                                  //       minimumSize: Size.fromHeight(65),
                                  //       shape: RoundedRectangleBorder(
                                  //         borderRadius: BorderRadius.circular(
                                  //           10,
                                  //         ),
                                  //       ),
                                  //     ),
                                  //     child: Text(
                                  //       "Enroll Membership",
                                  //       style: GoogleFonts.inter(
                                  //         fontSize: 23,
                                  //         color: Colors.white,
                                  //         fontWeight: FontWeight.w600,
                                  //       ),
                                  //     ),
                                  //   ),
                                  // ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 15),
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  //Navigator.pop(context);
                                  controller.getUserDatabyMobile(
                                    mobileController.text,
                                  );
                                  showBookingConfirmationDialog(
                                    context,
                                    nameController.text,
                                    mobileController.text,
                                    selectedName,
                                    totalPrice,
                                    selectedDateTime ?? DateTime.now(),
                                    bookings,
                                    membershipId,
                                    membershipPlan,
                                    isMembershipApplied,
                                    memberPrice,
                                  );
                                } else {
                                  showCustomSnackbar(
                                    'Error :',
                                    'Please enter name & mobile for bookingslots',
                                    Colors.redAccent,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                minimumSize: Size.fromHeight(65),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                "Quick Booking",
                                style: GoogleFonts.inter(
                                  fontSize: 23,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
    return;
  }

  // QuickBooking Plan Dialog
  Future<void> showBookingConfirmationDialog(
    BuildContext parentContext,
    String customerName,
    String mobile,
    String game,
    double billAmount,
    DateTime selectedDateTime,
    List<BookingInfo> bookings,
    String? selectedMembershipId,
    String? selectedMembershipPlan,
    bool isMembershipApplied,
    double membershipPrice,
  ) async {
    // Create a copy of bookings to modify prices without affecting original
    List<BookingInfo> updatedBookings =
        bookings.map((booking) {
          return BookingInfo(
            courtName: booking.courtName,
            courtId: booking.courtId,
            selectedDateTime: booking.selectedDateTime,
            selectedDays: booking.selectedDays,
            subSlots:
                booking.subSlots.map((subSlot) {
                  // Don't apply membership pricing here - let checkout handle it
                  double updatedPrice = subSlot.price;
                  return BookingSubSlotInfo(
                    startTime: subSlot.startTime,
                    endTime: subSlot.endTime,
                    price: updatedPrice,
                    isPeak: subSlot.isPeak,
                  );
                }).toList(),
            bookingId: booking.bookingId,
            membershipPlanId: selectedMembershipId,
          );
        }).toList();

    // Recalculate total amount with updated prices
    double updatedTotalAmount = updatedBookings.fold(0.0, (sum, booking) {
      return sum +
          booking.subSlots.fold(
            0.0,
            (subSum, subSlot) => subSum + subSlot.price,
          );
    });

    // Store controller values before showing dialog to avoid disposed controller access
    final bookingIdValue          = controller.bookingId;
    final selectedServiceIdValue  = controller.selectedServiceId.value;
    final serviceListValue        = List.from(controller.serviceList);
    final userDataValue           = controller.userData.value;
    final nameControllerText      = controller.nameController.text;
    final mobileControllerText    = controller.mobileNumberController.text;

    await showDialog(
      context: parentContext,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder:
          (dialogContext) => WillPopScope(
            onWillPop: () async {
              // Clear cart when dialog is closed
              //cartController.clearCart();
              return true;
            },
            child: Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Booking Confirmation",
                            style: GoogleFonts.inter(
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bookingIdValue,
                            style: GoogleFonts.inter(
                              fontSize: 23,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customerName.toString(),
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 25,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    mobile,
                                    style: GoogleFonts.inter(
                                      color: Colors.grey.shade800,
                                      fontSize: 25,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(LucideIcons.gamepad2, size: 35),
                                      const SizedBox(width: 10),
                                      Text(
                                        game,
                                        style: GoogleFonts.inter(
                                          fontSize: 25,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),

                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              "Court Information",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 22,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Booking Details List
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                  ), // outer border
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Column(
                                  children: List.generate(bookings.length, (index) {
                                    final booking = bookings[index];
                                    final isLast = index == bookings.length - 1;

                                    return Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                            vertical: 12,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  booking.courtName,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              if (booking.subSlots.any(
                                                (subSlot) => subSlot.isPeak,
                                              )) ...[
                                                Expanded(
                                                  flex: 4,
                                                  child: Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text:
                                                              "${booking.subSlots.first.startTime} - ${booking.subSlots.last.endTime}",
                                                          style: GoogleFonts.inter(
                                                            fontSize: 22,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color:
                                                                Colors.green.shade600,
                                                          ),
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              "(${booking.subSlots.fold(0, (sum, subSlot) => sum + (subSlot.isPeak ? 30 : 0))} mins peak)",
                                                          style: GoogleFonts.inter(
                                                            fontSize: 22,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color:
                                                                Colors
                                                                    .orange
                                                                    .shade700,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ] else ...[
                                                Expanded(
                                                  flex: 4,
                                                  child: Text(
                                                    "${booking.subSlots.first.startTime} - ${booking.subSlots.last.endTime}",
                                                    style: GoogleFonts.inter(
                                                      fontSize: 22,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.green.shade600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  "${booking.subSlots.length * 30}mins",
                                                  style: GoogleFonts.inter(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.indigo.shade600,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  "\$${booking.subSlots.fold(0.0, (sum, subSlot) {
                                                    // Always show regular price - membership discount shown in checkout
                                                    return sum + subSlot.price;
                                                  }).toStringAsFixed(2)}",
                                                  textAlign: TextAlign.right,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey.shade900,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (!isLast)
                                          Divider(
                                            height: 2,
                                            color: Colors.grey.shade400,
                                          ), // bottom line for each row
                                      ],
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                          Obx(
                            () => ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: cartController.cartItems.length,
                              itemBuilder: (_, index) {
                                final item = cartController.cartItems[index];
                                return Dismissible(
                                  key: ValueKey(item.product.id),
                                  direction: DismissDirection.none,
                                  confirmDismiss:
                                      (_) async => false, // ❗ Disables dismiss swipe
                                  background: Container(
                                    color: Colors.red,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(
                                        fontSize: 22,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  onDismissed: (_) => cartController.removeItem(item),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.product.name,
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          width:
                                              MediaQuery.of(context).size.width / 14,
                                          padding: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey.shade400,
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '${item.quantity}',
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 110,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 8.0,
                                                ),
                                                child: Text(
                                                  '\$${item.appliedPrice.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 22,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          if (isMembershipApplied) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container(
                                  width: MediaQuery.of(context).size.width / 2.4,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '$selectedMembershipPlan Membership',
                                        style: GoogleFonts.inter(
                                          fontSize: 23,
                                          color: Palette.newColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '\$ ${membershipPrice.toStringAsFixed(2)}',
                                        style: GoogleFonts.inter(
                                          fontSize: 23,
                                          color: Palette.newColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                          ],

                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    // Close dialog first to prevent TypeAhead widget disposal issues
                                    Navigator.pop(context);

                                    try {
                                      if (controller.userData.value.id != null) {
                                        // User exists, create booking with pending payment
                                        populateCartWithSubSlots(bookings);
                                        await controller.processCheckout(
                                          name: nameControllerText,
                                          email: userDataValue.email,
                                          mobile: userDataValue.mobile,
                                          bookingId: bookingIdValue,
                                          paymentType: 'Pending', // Set payment type as Pending
                                          promoCode: '',
                                          notes: 'Payment pending - Pay Later option selected',
                                          bookings: updatedBookings,
                                          membershipID: (selectedMembershipId != null && selectedMembershipId!.isNotEmpty) ? selectedMembershipId : null,
                                          membershipName: selectedMembershipPlan,
                                          membershipPrice: memberPrice,
                                        );

                                      } else {
                                        // Create new user and then create booking with pending payment
                                          await controller.registerUser(
                                            mobile: mobile,
                                            firstName: customerName.toString(),
                                          );
                                          // Create booking with pending payment
                                          populateCartWithSubSlots(bookings);
                                          await controller.processCheckout(
                                            name: nameControllerText,
                                            email: userDataValue.email,
                                            mobile: userDataValue.mobile,
                                            paymentType: 'Pending', // Set payment type as Pending
                                            promoCode: '',
                                            notes: 'Payment pending - Pay Later option selected',
                                            bookingId: bookingIdValue,
                                            bookings: updatedBookings,
                                            membershipID: (selectedMembershipId != null && selectedMembershipId!.isNotEmpty) ? selectedMembershipId : null,
                                            membershipName: selectedMembershipPlan,
                                            membershipPrice: memberPrice,
                                          );
                                      }

                                      // After booking, clear slots and reset form
                                      controller.clearSelectedSlots();
                                      nameController.clear();
                                      mobileController.clear();
                                      hasMembership = false;
                                      isMembershipApplied = false;
                                      membershipPrice = 0.0;
                                      selectedMembershipId = null;
                                      selectedSlots.clear();
                                      cartController.clearCart();

                                      // Refresh court view to show the new booking
                                      if (mounted) {
                                        _refreshCourtView();
                                      }

                                      // Show success message
                                      showCustomSnackbar('Success', 'Booking created successfully with pending payment',Colors.green);
                                    } catch (e) {
                                      print('Error in pay later: $e');
                                      showCustomSnackbar('Success', 'Failed to create booking: ${e.toString()}',Colors.red);
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.black,
                                    minimumSize: Size.fromHeight(50),
                                    side: BorderSide(color: Colors.grey.shade400),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    "Pay Later",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 23,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    Navigator.of(
                                      dialogContext,
                                    ).pop(); // Close the dialog first

                                    //await Future.delayed(Duration(seconds: 1));
                                    //print(updatedBookings[0].subSlots[0].price);
                                    Get.to(
                                      //Checkout(),
                                      CheckoutScreen(
                                        type: 'New',
                                        customerName: customerName,
                                        mobileno: mobile,
                                        selectedDateTime: selectedDateTime,
                                        billAmount: billAmount + cartController.total,
                                        bookings: updatedBookings,
                                        membershipID: (selectedMembershipId != null && selectedMembershipId!.isNotEmpty) ? selectedMembershipId : null,
                                        membershipName: selectedMembershipPlan,
                                        isMembershipApplied: isMembershipApplied,
                                        membershipPrice: memberPrice,
                                        forpayment: 'new-booking-payment',
                                      ),
                                    );
                                        //?.then((_) {
                                      // Always refresh when returning from checkout
                                      // if (mounted) {
                                      //   print('🔙 Returned from checkout, refreshing court view...');
                                      //
                                      //   // Force clear cart items and selected slots
                                      //   controller.cartItems.clear();
                                      //   cartController.clearCart();
                                      //
                                      //   // Reset local state immediately
                                      //   setState(() {
                                      //     selectedSlots.clear();
                                      //   });
                                      //
                                      //   // Add a small delay to ensure checkout state is fully cleared
                                      //   Future.delayed(Duration(milliseconds: 500), () {
                                      //     if (mounted) {
                                      //       print('🔄 Starting delayed refresh...');
                                      //       _refreshCourtView();
                                      //     }
                                      //   });
                                      // }
                                    //});
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    minimumSize: Size.fromHeight(50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    "Pay Now",
                                    style: GoogleFonts.inter(
                                      fontSize: 23,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Add close button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        //cartController.clearCart();
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
    // return result ?? false;
  }

  void populateCartWithSubSlots(List<BookingInfo> bookings) {
    controller.cartItems.clear(); // Clear any existing items

    for (final bookingInfo in bookings) {
      final courtId =
          controller.courtList.firstWhere(
            (court) => court['name'] == bookingInfo.courtName,
            orElse: () => {},
          )?['id']; // Find the court ID based on the name

      if (courtId == null) {
        print('Warning: Could not find court ID for ${bookingInfo.courtName}');
        continue; // Skip if court ID is not found
      }

      for (final subSlotInfo in bookingInfo.subSlots) {
        final startTime = parseDateTime(
          selectedDateTime!,
          subSlotInfo.startTime,
        );
        final endTime = parseDateTime(selectedDateTime!, subSlotInfo.endTime);

        // Apply membership pricing if available
        double finalPrice;
        // Always use regular price - let checkout handle membership discounts
        finalPrice = subSlotInfo.price;

        print('selectedDateTime: ${selectedDateTime}');
        final individualSlot = BookingSlot(
          serviceId: controller.selectedServiceId.value,
          courtId: courtId,
          court: bookingInfo.courtName,
          date: selectedDateTime, // Set the date to match the startTime
          startTime: startTime,
          endTime: endTime,
          price: finalPrice,
          slotType: null,
          repeatDays: null,
          repeatEnd: bookingInfo.repeatUntil,
          repeatId: null,
          repeatGroupId: null,
          status: 'Selected',
          bookingId: null, // Will be assigned after booking creation
          paymentStatus: 'CASH',
          name: nameController.text,
          mobile: mobileController.text,
          service: controller.selectedService.value,
          updatedAt: DateTime.now(),
          updatedBy: authController.userId.toString(),
          userId: authController.userId.toString(),
          bookingNo: controller.bookingId,
        );
        controller.cartItems.add(individualSlot);
      }
      print("SelectedSlots  : ${controller.cartItems}");
    }
  }

  DateTime parseDateTime(DateTime date, String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  //Membership Plan Dialog

  Future<void> openMembershipDrawer(
    BuildContext context,
    List<BookingInfo> bookings, {
    VoidCallback? onCancel,
  }) async {
    final plans = controller.membershipPlans;
    String? selectedPlan = plans.first['name'];
    selectedMembershipId = plans.first['id'];
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Membership Plan',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(anim1),
          child: Align(
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5, // Right half of screen
              child: Material(
                color: Colors.white,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Membership Plan',
                            style: GoogleFonts.inter(
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Choose desired membership plan for the customer',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const Divider(height: 24),
                          Text(
                            'Plans',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 22,
                              color: Colors.black,
                            ),
                          ),

                          const SizedBox(height: 12),
                          ...plans.map((plan) {
                            bool isSelected = plan['name'] == selectedPlan;
                            Color borderColor;
                            Color backgroundColor;
                            Color textColor;

                            if (plan['name'].toString().toLowerCase().contains(
                              'gold',
                            )) {
                              borderColor = Colors.amber.shade500;
                              backgroundColor = Colors.amber.shade50;
                              textColor = Colors.amber.shade500;
                            } else if (plan['name']
                                .toString()
                                .toLowerCase()
                                .contains('platinum')) {
                              borderColor = Colors.indigo.shade500;
                              backgroundColor = Colors.indigo.shade50;
                              textColor = Colors.indigo.shade500;
                            } else {
                              borderColor = Colors.grey.shade300;
                              backgroundColor = Colors.grey.shade100;
                              textColor = Colors.black;
                            }
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedPlan = plan['name'].toString();
                                  selectedMembershipId = plan['id'].toString();
                                  _selectedPrice =
                                      double.tryParse(
                                        plan['price'].toString(),
                                      ) ??
                                      0;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? borderColor!
                                            : Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color:
                                      isSelected
                                          ? backgroundColor
                                          : Colors.white,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          LucideIcons.crown,
                                          color: textColor,
                                          size: 30,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          " ${plan['name']} Membership",
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                            color: textColor,
                                            fontSize: 23,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '\$${plan['price']}',
                                          style: GoogleFonts.inter(
                                            color: textColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 23,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          plan['billing_cycle'],
                                          style: GoogleFonts.inter(
                                            color: textColor,
                                            fontSize: 23,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      plan['description'],
                                      style: GoogleFonts.inter(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...List<Widget>.from(
                                      (plan['highlights'] as List).map((
                                        highlight,
                                      ) {
                                        return Row(
                                          children: [
                                            Icon(
                                              LucideIcons.dot,
                                              size: 22,
                                              color: Colors.black,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                highlight,
                                                style: GoogleFonts.inter(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          Spacer(),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    //openMembershipDrawer call again
                                    openBookingRightDrawer(
                                      context,
                                      '',
                                      0.0,
                                      false,
                                      null, // No membership selected
                                      bookings,
                                      onCancel:
                                          null, // No setState or UI logic here
                                    );
                                    // setState(() {
                                    //   selectedPlan = null;
                                    //   selectedMembershipId = null;
                                    //   _selectedPrice = 0.0;
                                    // });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade300,
                                    foregroundColor: Colors.white,
                                    minimumSize: Size.fromHeight(50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    "Cancel",
                                    style: GoogleFonts.inter(
                                      fontSize: 23,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    WidgetsBinding.instance.addPostFrameCallback((
                                      _,
                                    ) {
                                      if (selectedPlan != null) {
                                        String planName = selectedPlan!;
                                        double price = _selectedPrice;
                                        bool isApplied = true;
                                        setState(() {
                                          membershipPrice = price;
                                          memberPrice = price; // Fix: Set memberPrice too
                                          isMembershipApplied = isApplied;
                                          updateTotalPrice();
                                        });
                                        print(
                                          "Selected: $planName | Price: $price | Applied: $isApplied | membershipID: $selectedMembershipId",
                                        );
                                        // Store current values before reopening drawer
                                        final currentName = nameController.text;
                                        final currentMobile = mobileController.text;

                                        openBookingRightDrawer(
                                          context,
                                          planName,
                                          price,
                                          isApplied,
                                          selectedMembershipId,
                                          bookings,
                                          onCancel:
                                              null, // No setState or UI logic here
                                        );

                                        // Restore values after drawer opens
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          nameController.text = currentName;
                                          mobileController.text = currentMobile;
                                        });
                                      }
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo,
                                    foregroundColor: Colors.white,
                                    minimumSize: Size.fromHeight(50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    "Confirm",
                                    style: GoogleFonts.inter(
                                      fontSize: 23,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void updateCourtPrice() {
    double total = 0.0;
    controller.selectedCourtSlots.forEach((court, slots) {
      for (String slot in slots) {
        final slotData = slotInfoMap[slot];
        // Always use regular price - let checkout handle membership discounts
        double price = slotData?['price'] ?? 0.0;
        total += price;

        /* Don't apply membership prices here - moved to checkout
        final isPeak = slotData?['isPeak'] ?? false;
        double price;
        if (hasMembership && memberPeakPrice != null && memberNonPeakPrice != null) {
          final isMembershipExpired = membershipValidityDate != null && membershipValidityDate!.isBefore(DateTime.now());
          if(!isMembershipExpired) {
            price = isPeak ? memberPeakPrice! : memberNonPeakPrice!;
          } else {
            price = slotData?['price'] ?? 0.0;
          }
        } else {
          price = slotData?['price'] ?? 0.0;
        }
        */
      }
    });
    setState(() {
      courtPrice = total;
      print('courtPrice : $courtPrice');
    });
  }

  Future<bool> checkPendingMembershipPayment() async {
    if (controller.userData.value.id == null) return false;

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug = preferences.getString('centerSlug');

    try {
      // Check if customer has any bookings with pending membership payments
      final response = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('bookings')
          .select('id, membership_id, paymentstatus')
          .eq('customers_id', controller.userData.value.id!)
          .not('membership_id', 'is', null)
          .eq('paymentstatus', 'Pending')
          .limit(1);

      if (response.isNotEmpty) {
        return true;
      }

      // Also check membershippayment table if it exists
      final membershipResponse = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('membershippayment')
          .select('id')
          .eq('customers_id', controller.userData.value.id!)
          .eq('status', false)
          .limit(1);

      return membershipResponse.isNotEmpty;
    } catch (e) {
      print('Error checking pending membership payment: $e');
      return false;
    }
  }

  // DEBUG: Show cleanup dialog for orphaned membership records
  void _showDebugCleanupDialog() {
    final TextEditingController customerIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🧹 Debug: Cleanup Orphaned Membership',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter customer ID to clean up orphaned membership records:',
              style: GoogleFonts.inter(fontSize: 14)),
            SizedBox(height: 16),
            TextField(
              controller: customerIdController,
              decoration: InputDecoration(
                labelText: 'Customer ID',
                hintText: 'e.g., 12345',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Text('⚠️ This will remove ALL membership records for this customer.',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final customerId = customerIdController.text.trim();
              if (customerId.isNotEmpty) {
                Navigator.pop(context);
                await _debugCleanupMembership(customerId);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Clean Up'),
          ),
        ],
      ),
    );
  }

  // DEBUG: Clean up orphaned membership records for specific customer
  Future<void> _debugCleanupMembership(String customerId) async {
    try {
      print('🧹 Starting debug cleanup for customer: $customerId');

      // Add delay to ensure UI is stable
      await Future.delayed(Duration(milliseconds: 300));

      // Perform cleanup without showing additional loading dialog
      // (the flutter_typeahead widget conflicts with dialogs)
      showCustomSnackbar('Info', 'Cleaning up membership records...', Colors.blue);

      final success = await checkoutController.debugCleanupCustomerMembership(
        customerId: customerId,
      );

      // Add delay before showing results
      await Future.delayed(Duration(milliseconds: 300));

      if (mounted) {  // Check if widget is still mounted
        if (success) {
          showCustomSnackbar('Success', 'Membership records cleaned up! Try booking again.', Colors.green);
        } else {
          showCustomSnackbar('Error', 'Failed to clean up membership records', Colors.red);
        }
      }

    } catch (e) {
      print('❌ Debug cleanup error: $e');

      if (mounted) {  // Check if widget is still mounted
        showCustomSnackbar('Error', 'Cleanup failed: $e', Colors.red);
      }
    }
  }
}


class MobileNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Remove non-digit characters
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Limit to 10 digits
    final limited = digitsOnly.length > 10 ? digitsOnly.substring(0, 10) : digitsOnly;

    // Apply formatting: XXXX XXX XXX
    String formatted = '';
    for (int i = 0; i < limited.length; i++) {
      if (i == 4 || i == 7) {
        formatted += ' ';
      }
      formatted += limited[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}