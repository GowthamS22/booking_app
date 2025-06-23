// ignore_for_file: unnecessary_null_comparison

import 'package:booking_app/controllers/cart_controller.dart';
import 'package:booking_app/screens/checkout/checkout_screen.dart';
import 'package:booking_app/screens/shopping/addon_items_widget.dart';
import 'package:booking_app/screens/shopping/cart_items.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/constants.dart';
import '../../../config/palette.dart';
import '../../../controllers/new_booking_controller.dart';
import '../../../models/booking_model.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import '../extended_bookings.dart';

class CourtViewScreen extends StatefulWidget {
  const CourtViewScreen({super.key});

  @override
  State<CourtViewScreen> createState() => _CourtViewScreenState();
}

class _CourtViewScreenState extends State<CourtViewScreen> {
  final NewBookingController controller = Get.put(NewBookingController());
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _advanceformKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController repeatUntilController = TextEditingController();
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
  double? memberPeakPrice;
  double? memberNonPeakPrice;

  @override
  void initState() {
    super.initState();
    // Initialize selectedDateTime to today
    selectedDateTime = DateTime.now();
    _vertical.addListener(() {
      _leftVerticalController.jumpTo(_vertical.offset);
    });
    _horizontal.addListener(() {
      _headerHorizontalController.jumpTo(_horizontal.offset);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _vertical.dispose();
    _horizontal.dispose();
    _headerHorizontalController.dispose();
    _leftVerticalController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      controller.isLoading.value = true;

      // First fetch service list
      await controller.fetchServiceList();

      if (controller.serviceList.isNotEmpty) {
        // Set initial service ID
        controller.selectedServiceId.value = controller.serviceList[0]['id'];
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
    } catch (error) {
      print('Error loading initial data: $error');
    } finally {
      controller.isLoading.value = false;
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
    if (selectedDateTime != null &&
        selectedDateTime!.isBefore(DateTime(now.year, now.month, now.day))) {
      return true;
    }
    if (selectedDateTime != null &&
        selectedDateTime!.year == now.year &&
        selectedDateTime!.month == now.month &&
        selectedDateTime!.day == now.day) {
      return slotTime.isBefore(now);
    }
    return false;
  }

  bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  final CartController cartController = Get.find<CartController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Icon(Icons.date_range_sharp, size: 35),
              ),
            ),
            const SizedBox(width: 15),
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
                        margin: EdgeInsets.only(right: 12),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? Colors.indigo.shade500
                                  : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Image.asset(
                          item['name'] == 'Badminton'
                              ? 'assets/images/icons/badminton.png'
                              : 'assets/images/icons/tennis.png',
                          width: 32,
                          height: 32,
                          fit: BoxFit.fill,
                          color: isSelected ? Colors.white : Colors.grey,
                        ),
                      ),
                    );
                  }).toList(),
            ),

            const SizedBox(width: 10),
            if (controller.selectedCourtSlots.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade500,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                child: GestureDetector(
                  onTap: () {
                    final grouped = controller.groupSelectedSlots(
                      controller.selectedCourtSlots,
                    );
                    List<BookingInfo> bookings = [];
                    String membershipPlan = '';
                    double memberPrice = 0.0;
                    bool membershipApplied = false;
                    grouped.forEach((court, slotGroups) {
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
                      selectedMembershipId ?? '',
                      bookings,
                      onCancel: () {
                        setState(
                          () {},
                        ); // This will force the parent to rebuild and reflect cleared state
                      },
                    );
                  },
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
              SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: GestureDetector(
                  onTap: () {
                    controller.clearSelectedSlots();
                    setState(() {});
                  },
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
                        fontSize: 16,
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
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No courts or time slots available',
                      style: GoogleFonts.inter(
                        fontSize: 16,
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
                                      fontSize: 18,
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
                                final selectedSlots =
                                    controller.selectedCourtSlots[courtName] ??
                                    [];

                                return Row(
                                  children: [
                                    ...List.generate(controller.timeSlots.length, (
                                      index,
                                    ) {
                                      String slot = controller.timeSlots[index];
                                      final slotData = slotInfoMap[slot];
                                      final isPeak =
                                          slotData?['isPeak'] ?? false;
                                      courtPrice =
                                          (slotData?['price'] ?? 0.0)
                                              .toDouble();
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

                                              // Your existing logic for extension drawer
                                              final isCurrentUser =
                                                  bookingSlot.name ==
                                                  currentUser;
                                              final hasMembership =
                                                  (bookingSlot.membershipPlanId ??
                                                          '')
                                                      .isNotEmpty;
                                              if (isCurrentUser &&
                                                  hasMembership) {
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
                                                );
                                                controller.fetchBookedSlots();
                                                fetchSlotInfo();
                                                if (mounted) setState(() {});
                                              } else {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Only your own bookings with membership can be extended.',
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
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
    );

    if (pickedDate == null) return;

    // Combine Date and Time
    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
    );

    // Clear all selections before updating date
    controller.clearSelectedSlots();
    selectedSlots.clear();

    setState(() {
      selectedDateTime = combined;
      controller.selectedDate = combined; // Update controller's selected date
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
    String membershipId,
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
                              double price;
                              if (hasMembership &&
                                  memberPeakPrice != null &&
                                  memberNonPeakPrice != null) {
                                price =
                                    subSlot.isPeak
                                        ? memberPeakPrice!
                                        : memberNonPeakPrice!;
                              } else {
                                price =
                                    (subSlot.price is num)
                                        ? subSlot.price.toDouble()
                                        : 0.0;
                              }
                              return subSum + price;
                            }),
                      );
                    });
                    totalPrice =
                        courtPrice + (isMembershipApplied ? memberPrice : 0.0);
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
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                // Name Field
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,

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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: backgroundColor,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: borderColor!,
                                                ),
                                              ),
                                              child: Text(
                                                membershipValidityDate != null
                                                    ? '$membershipPlan :(${membershipValidityDate!.difference(DateTime.now()).inDays > 0 ? 'Valid for ${membershipValidityDate!.difference(DateTime.now()).inDays} days' : 'Expired'})'
                                                    : '$membershipPlan : (No Validity Info)',
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: textColor,
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
                                          maxWidth:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.50,
                                        ),
                                        child: TypeAheadField<
                                          Map<String, dynamic>
                                        >(
                                          controller: nameController,
                                          suggestionsCallback: (pattern) {
                                            if (pattern.isEmpty) return [];
                                            return controller.userList.where((
                                              user,
                                            ) {
                                              return user['name']!
                                                  .toLowerCase()
                                                  .contains(
                                                    pattern.toLowerCase(),
                                                  );
                                            }).toList();
                                          },
                                          builder: (context, _, focusNode) {
                                            return TextFormField(
                                              controller: nameController,
                                              focusNode: focusNode,
                                              keyboardType: TextInputType.name,
                                              validator: (value) {
                                                if (value == null ||
                                                    value.trim().isEmpty) {
                                                  return 'Name is required';
                                                }

                                                return null;
                                              },
                                              style: GoogleFonts.inter(
                                                fontSize: 18,
                                                color: Colors.grey.shade800,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                      horizontal: 12,
                                                    ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  borderSide: BorderSide(
                                                    color: Colors.grey.shade300,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                          itemBuilder: (context, suggestion) {
                                            return ListTile(
                                              title: Text(suggestion['name']),
                                              subtitle: Text(
                                                suggestion['mobile'],
                                              ),
                                            );
                                          },
                                          onSelected: (suggestion) {
                                            nameController.text =
                                                suggestion['name'];
                                            mobileController.text =
                                                suggestion['mobile'];
                                            print(
                                              'Selected customer data: $suggestion',
                                            );
                                            setState(() {
                                              hasMembership =
                                                  (suggestion['membershipplan_id'] !=
                                                          null &&
                                                      suggestion['membershipplan_id']
                                                          .toString()
                                                          .isNotEmpty);
                                              memberPeakPrice =
                                                  hasMembership
                                                      ? double.tryParse(
                                                        suggestion['peak_price']
                                                                ?.toString() ??
                                                            '0',
                                                      )
                                                      : null;
                                              memberNonPeakPrice =
                                                  hasMembership
                                                      ? double.tryParse(
                                                        suggestion['non_peak_price']
                                                                ?.toString() ??
                                                            '0',
                                                      )
                                                      : null;
                                              membershipPlan =
                                                  hasMembership
                                                      ? suggestion['membership_plan']
                                                      : null;
                                              membershipValidityDate =
                                                  hasMembership
                                                      ? DateTime.tryParse(
                                                        suggestion['validity_end']
                                                                ?.toString() ??
                                                            '',
                                                      )
                                                      : null;
                                              updateCourtPrice();
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Mobile Field
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          maxWidth:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.50,
                                        ),
                                        child: TypeAheadField<
                                          Map<String, dynamic>
                                        >(
                                          controller: mobileController,
                                          suggestionsCallback: (pattern) {
                                            if (pattern.isEmpty) return [];
                                            return controller.userList.where((
                                              user,
                                            ) {
                                              return user['mobile']!
                                                  .toLowerCase()
                                                  .contains(
                                                    pattern.toLowerCase(),
                                                  );
                                            }).toList();
                                          },
                                          builder: (context, _, focusNode) {
                                            return TextFormField(
                                              controller: mobileController,
                                              focusNode: focusNode,
                                              keyboardType: TextInputType.phone,
                                              validator: (value) {
                                                if (value == null ||
                                                    value.trim().isEmpty) {
                                                  return 'Mobile number is required';
                                                }
                                                if (!RegExp(
                                                  r'^[0-9]{10}$',
                                                ).hasMatch(value)) {
                                                  return 'Enter a valid 10-digit number';
                                                }
                                                return null;
                                              },
                                              style: GoogleFonts.inter(
                                                fontSize: 18,
                                                color: Colors.grey.shade800,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                      horizontal: 12,
                                                    ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  borderSide: BorderSide(
                                                    color: Colors.grey.shade300,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                          itemBuilder: (context, suggestion) {
                                            return ListTile(
                                              title: Text(suggestion['name']),
                                              subtitle: Text(
                                                suggestion['mobile'],
                                              ),
                                            );
                                          },
                                          onSelected: (suggestion) {
                                            nameController.text =
                                                suggestion['name'];
                                            mobileController.text =
                                                suggestion['mobile'];
                                            setState(() {
                                              hasMembership =
                                                  (suggestion['membershipplan_id'] !=
                                                          null &&
                                                      suggestion['membershipplan_id']
                                                          .toString()
                                                          .isNotEmpty);
                                              memberPeakPrice =
                                                  hasMembership
                                                      ? double.tryParse(
                                                        suggestion['peak_price']
                                                                ?.toString() ??
                                                            '0',
                                                      )
                                                      : null;
                                              memberNonPeakPrice =
                                                  hasMembership
                                                      ? double.tryParse(
                                                        suggestion['non_peak_price']
                                                                ?.toString() ??
                                                            '0',
                                                      )
                                                      : null;
                                              membershipPlan =
                                                  hasMembership
                                                      ? suggestion['membership_plan']
                                                      : null;

                                              membershipValidityDate =
                                                  hasMembership
                                                      ? DateTime.tryParse(
                                                        suggestion['validity_end']
                                                                ?.toString() ??
                                                            '',
                                                      )
                                                      : null;
                                              updateCourtPrice();
                                            });
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
                                'Sport : ${bookings.isNotEmpty ? 'Badminton' : ''}',
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
                                                            if (hasMembership && memberPeakPrice != null && memberNonPeakPrice != null) {
                                                              return sum + (subSlot.isPeak ? memberPeakPrice! : memberNonPeakPrice!);
                                                            } else {
                                                              return sum + subSlot.price;
                                                            }
                                                          }).toStringAsFixed(2)}",
                                                          textAlign:
                                                              TextAlign.right,
                                                          style:
                                                              GoogleFonts.inter(
                                                                fontSize: 22,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color:
                                                                    Colors
                                                                        .grey
                                                                        .shade900,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                  ),
                                                  SizedBox(height: 5),
                                                  Row(
                                                    children: [
                                                      if (booking.subSlots.any(
                                                        (subSlot) =>
                                                            subSlot.isPeak,
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
                                    Obx(
                                      () => ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount:
                                            cartController.cartItems.length,
                                        itemBuilder: (_, index) {
                                          final item =
                                              cartController.cartItems[index];
                                          return Dismissible(
                                            key: ValueKey(item.product.id),
                                            direction:
                                                DismissDirection.endToStart,
                                            background: Container(
                                              color: Colors.red,
                                              alignment: Alignment.centerRight,
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                            onDismissed:
                                                (_) => cartController
                                                    .removeItem(item),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 15,
                                                    vertical: 10,
                                                  ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item.product.name,
                                                      style: const TextStyle(
                                                        fontSize: 22,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Container(
                                                    width:
                                                        MediaQuery.of(
                                                          context,
                                                        ).size.width /
                                                        14,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade400,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        IconButton(
                                                          onPressed:
                                                              () => cartController
                                                                  .decrementQty(
                                                                    item,
                                                                  ),
                                                          icon: const Icon(
                                                            Icons.remove,
                                                            size: 25,
                                                          ),
                                                        ),
                                                        Obx(
                                                          () => Text(
                                                            '${item.quantity.value}',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 22,
                                                                ),
                                                          ),
                                                        ),
                                                        IconButton(
                                                          onPressed:
                                                              () => cartController
                                                                  .incrementQty(
                                                                    item,
                                                                  ),
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
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.end,
                                                      children: [
                                                        Obx(
                                                          () => Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  left: 8.0,
                                                                ),
                                                            child: Text(
                                                              '\$${item.appliedPrice.value.toStringAsFixed(2)}',
                                                              style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 22,
                                                              ),
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
                                  ],
                                ),
                              ),
                            ),
                          ),

                          Container(height: 360, child: AddonItemsWidget()),

                          SizedBox(height: 10),
                          if (isMembershipApplied) ...[
                            Row(
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
                                SizedBox(width: 5),
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
                                    size: 20,
                                    color: Colors.grey.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            // Spacer(),
                            Divider(color: Colors.grey.shade300),
                            Row(
                              children: [
                                // Text(
                                //   'Add Membership and pay ${55} and save ${25}',
                                //   style: GoogleFonts.inter(
                                //     fontSize: 15,
                                //     color: Colors.black,
                                //     fontWeight: FontWeight.w600,
                                //   ),
                                // ),
                                Spacer(),
                                if (hasMembership &&
                                    memberPeakPrice != null &&
                                    memberNonPeakPrice != null) ...[
                                  Text(
                                    'Total',
                                    style: GoogleFonts.inter(
                                      fontSize: 23,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  SizedBox(width: 8),
                                  Text(
                                    '\$ ${courtPrice.toStringAsFixed(2)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 25,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
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
                                  Text(
                                    '\$ ${courtPrice.toStringAsFixed(2)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 25,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                          if (isMembershipApplied) ...[
                            //Spacer(),
                            Divider(color: Colors.grey.shade300),
                            Row(
                              children: [
                                // Text(
                                //   'Membership price updated!!',
                                //   style: GoogleFonts.inter(
                                //     fontSize: 12,
                                //     color: Colors.green.shade500,
                                //     fontWeight: FontWeight.w500,
                                //   ),
                                // ),
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
                                Text(
                                  '\$ ${totalPrice.toStringAsFixed(2)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 25,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Row(
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
                                      if (onCancel != null)
                                        onCancel(); // notify parent to refresh
                                      Navigator.pop(context);
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
                                        fontSize: 22,

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
                                      if (_formKey.currentState!.validate()) {
                                        Navigator.pop(context);
                                        final double TotalAmount;
                                        controller.getUserDatabyMobile(
                                          mobileController.text,
                                        );
                                        if (isMembershipApplied) {
                                          TotalAmount =
                                              courtPrice + memberPrice;
                                        } else {
                                          TotalAmount = courtPrice;
                                        }
                                        showBookingConfirmationDialog(
                                          context,
                                          nameController.text,
                                          mobileController.text,
                                          controller.selectedCourt.toString(),
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
                                      minimumSize: Size.fromHeight(50),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      "Quick Booking",
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
                              spacing: 20,
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
                                      if (onCancel != null)
                                        onCancel(); // notify parent to refresh
                                      Navigator.pop(context);
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
                                if (!hasMembership ||
                                    (membershipValidityDate != null &&
                                        membershipValidityDate!
                                                .difference(DateTime.now())
                                                .inDays <=
                                            0)) ...[
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed:
                                          (nameController.text
                                                      .trim()
                                                      .isNotEmpty ||
                                                  mobileController.text
                                                      .trim()
                                                      .isNotEmpty)
                                              ? () {
                                                Navigator.pop(context);
                                                openMembershipDrawer(
                                                  context,
                                                  bookings,
                                                  onCancel: null,
                                                );
                                              }
                                              : null, // disables the button if both are empty
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            (nameController.text
                                                        .trim()
                                                        .isNotEmpty ||
                                                    mobileController.text
                                                        .trim()
                                                        .isNotEmpty)
                                                ? Colors.black
                                                : Colors
                                                    .grey, // visually indicate disabled

                                        foregroundColor: Colors.white,
                                        minimumSize: Size.fromHeight(50),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        "Enroll Membership",
                                        style: GoogleFonts.inter(
                                          fontSize: 23,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  Navigator.pop(context);
                                  controller.getUserDatabyMobile(
                                    mobileController.text,
                                  );
                                  showBookingConfirmationDialog(
                                    context,
                                    nameController.text,
                                    mobileController.text,
                                    controller.selectedCourt.toString(),
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
                                minimumSize: Size.fromHeight(50),
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
    await showDialog(
      context: parentContext,
      builder:
          (dialogContext) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Booking Confirmed",
                      style: GoogleFonts.inter(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.bookingId,
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
                                fontSize: 23,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              mobile,
                              style: GoogleFonts.inter(
                                color: Colors.grey.shade800,
                                fontSize: 22,
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
                                Icon(LucideIcons.gamepad2, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  'Sport',
                                  style: GoogleFonts.inter(
                                    color: Colors.grey.shade800,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),

                            Text(
                              game,
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
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
                                              if (hasMembership && memberPeakPrice != null && memberNonPeakPrice != null) {
                                                return sum + (subSlot.isPeak ? memberPeakPrice! : memberNonPeakPrice!);
                                              } else {
                                                return sum + subSlot.price;
                                              }
                                            }).toStringAsFixed(2)}",
                                            textAlign: TextAlign.right,
                                            style: GoogleFonts.inter(
                                              fontSize: 23,
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

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              if (controller.userData.value.id != null) {
                                // User exists, create booking with pending payment
                                populateCartWithSubSlots(bookings);
                                controller.processCheckout(
                                  name: controller.nameController.text,
                                  email: controller.userData.value.email,
                                  mobile: controller.userData.value.mobile,
                                  paymentType:
                                      'Pending', // Set payment type as Pending
                                  promoCode: '',
                                  notes:
                                      'Payment pending - Pay Later option selected',
                                );
                              } else {
                                // Create new user and then create booking with pending payment
                                controller
                                    .registerUser(
                                      mobile:
                                          controller
                                              .mobileNumberController
                                              .text,
                                      firstName: controller.nameController.text,
                                    )
                                    .then((value) {
                                      // Create booking with pending payment
                                      populateCartWithSubSlots(bookings);
                                      controller.processCheckout(
                                        name: controller.nameController.text,
                                        email: controller.userData.value.email,
                                        mobile:
                                            controller.userData.value.mobile,
                                        paymentType:
                                            'Pending', // Set payment type as Pending
                                        promoCode: '',
                                        notes:
                                            'Payment pending - Pay Later option selected',
                                      );
                                    });
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

                              await Future.delayed(Duration(seconds: 1));
                              Get.to(
                                //Checkout(),
                                CheckoutScreen(
                                  type: 'New',
                                  customerName: customerName,
                                  mobileno: mobile,
                                  selectedDateTime: selectedDateTime,
                                  billAmount: billAmount,
                                  bookings: bookings,
                                  membershipID: selectedMembershipId!,
                                  membershipName: selectedMembershipPlan,
                                  isMembershipApplied: isMembershipApplied,
                                  membershipPrice: memberPrice,
                                ),
                              );
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
        print('selectedDateTime: ${selectedDateTime}');
        final individualSlot = BookingSlot(
          serviceId: controller.selectedServiceId.value,
          courtId: courtId,
          court: bookingInfo.courtName,
          date: selectedDateTime, // Set the date to match the startTime
          startTime: startTime,
          endTime: endTime,
          price: subSlotInfo.price,
          slotType: null,
          repeatDays: null,
          repeatEnd: bookingInfo.repeatUntil,
          repeatId: null,
          repeatGroupId: null,
          status: 'Selected',
          bookingId: bookings.first.bookingId,
          paymentStatus: 'CASH',
          name: nameController.text,
          mobile: mobileController.text,
          service: controller.selectedCourt.value,
          updatedAt: DateTime.now(),
          updatedBy: authController.userId.toString(),
          userId: authController.userId.toString(),
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
                                      '',
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
                                          isMembershipApplied = isApplied;
                                          updateTotalPrice();
                                        });
                                        print(
                                          "Selected: $planName | Price: $price | Applied: $isApplied | membershipID: $selectedMembershipId",
                                        );
                                        openBookingRightDrawer(
                                          context,
                                          planName,
                                          price,
                                          isApplied,
                                          selectedMembershipId!,
                                          bookings,
                                          onCancel:
                                              null, // No setState or UI logic here
                                        );
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
        final isPeak = slotData?['isPeak'] ?? false;
        double price;
        if (hasMembership &&
            memberPeakPrice != null &&
            memberNonPeakPrice != null) {
          price = isPeak ? memberPeakPrice! : memberNonPeakPrice!;
        } else {
          price = slotData?['price'] ?? 0.0;
        }
        total += price;
      }
    });
    setState(() {
      courtPrice = total;
      print('courtPrice : $courtPrice');
    });
  }
}
