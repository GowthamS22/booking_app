// ignore_for_file: unnecessary_null_comparison

import 'package:booking_app/screens/checkout/checkout_screen.dart';
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
  Map<String, List<String>> selectedCourtSlots = {};
  String? selectedCourt;
  DateTime selectedDate = DateTime.now();
  DateTime? selectedDateTime;
  var courtPrice = 0;
  bool isDate = false;
  String selectedPlan = 'Gold';
  List<Map<String, dynamic>> slotInfo = [];
  Set<int> expandedIndexes = {};
  Map<String, Map<String, dynamic>> slotInfoMap = {};
  @override
  void initState() {
    super.initState();
    // Initialize selectedDateTime to today
    selectedDateTime = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
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
      }
    } catch (error) {
      print('Error loading initial data: $error');
    } finally {
      controller.isLoading.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchSlotInfo() async {
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
    setState(() {}); // Refresh UI
    return slotInfo;
  }

  bool isSlotInPast(String slot) {
    final now = DateTime.now();
    final slotTime = parseTime(slot);
    if (selectedDateTime == null ||
        (selectedDateTime!.year == now.year &&
            selectedDateTime!.month == now.month &&
            selectedDateTime!.day == now.day)) {
      if (slotTime.hour < now.hour) {
        return true;
      } else if (slotTime.hour == now.hour && slotTime.minute < now.minute) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Row(
                  children: [
                    Text(
                      "Court Availability",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isDate == true && selectedDateTime != null)
                      Text(
                        " - ${DateFormat('MMM d, yyyy').format(selectedDateTime!)}",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.indigo.shade500,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                Text(
                  "View and manage court bookings",
                  style: GoogleFonts.inter(
                    fontSize: 14,
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
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                child: Icon(Icons.date_range_sharp, size: 22),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 150),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.3,
                  child: DropdownButtonFormField<String>(
                    value:
                        (controller.selectedServiceId.value.isNotEmpty)
                            ? controller.selectedServiceId.value
                            : null,
                    items:
                        controller.serviceList.map((item) {
                          return DropdownMenuItem<String>(
                            value: item['id'],
                            child: Text(
                              '${item['name']}',
                              style: GoogleFonts.inter(fontSize: 15 * ffem),
                            ),
                          );
                        }).toList(),
                    onChanged: (value) async {
                      if (value != null) {
                        try {
                          controller.isLoading.value = true;

                          setState(() {
                            controller.selectedServiceId.value = value;
                          });

                          // Fetch court list and booked slots in parallel
                          await Future.wait([
                            controller.fetchCourtList(),
                            controller.fetchBookedSlots(),
                          ]);

                          // Clear and reload court list
                          controller.courtList.clear();
                          await controller.fetchCourtList();

                          // Fetch slot info
                          await fetchSlotInfo();
                        } catch (error) {
                          print('Error loading data: $error');
                        } finally {
                          controller.isLoading.value = false;
                        }
                      }
                    },
                    onSaved: (value) {},
                    decoration: InputDecoration(
                      hintText: 'Select game',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      isDense: true,
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            if (selectedCourtSlots.isNotEmpty) ...[
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
                    final grouped = groupSelectedSlots(selectedCourtSlots);
                    List<BookingInfo> bookings = [];
                    String membershipPlan = '';
                    double memberPrice = 0.0;
                    bool membershipApplied = false;
                    grouped.forEach((court, slotGroups) {
                      for (final group in slotGroups) {
                        group.sort();
                        final start = group.first;
                        final end = calculateEndTime(group.last);
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

                    showBookingDialog(
                      context,
                      membershipPlan,
                      memberPrice,
                      membershipApplied,
                      bookings,
                    );
                  },
                  child: Text(
                    'Book Now',
                    style: GoogleFonts.inter(
                      fontSize: 16,
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
                  border: Border.all(color: Colors.grey),
                ),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCourtSlots.clear();
                      selectedCourt = null;
                    });
                  },
                  child: Text(
                    'Clear Selection',
                    style: GoogleFonts.inter(
                      fontSize: 16,
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
                )..sort((a, b) => a['name'].compareTo(b['name']));
                return Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 100,
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
                              // Time slot header
                              Row(
                                children: [
                                  ...controller.timeSlots.map((slot) {
                                    final slotData = slotInfoMap[slot];
                                    final isPeak = slotData?['isPeak'] ?? false;
                                    courtPrice =
                                        (slotData?['price'] ?? 0.0).toInt();

                                    return Container(
                                      width: 82,
                                      height: 50,
                                      alignment: Alignment.center,
                                      color: Colors.white,
                                      child: Text(
                                        slot,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          color:
                                              isPeak
                                                  ? Colors.amber.shade500
                                                  : Colors.grey.shade500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),

                              // Grid Content
                              SingleChildScrollView(
                                controller: _vertical,
                                scrollDirection: Axis.vertical,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:
                                      controller.courtList.map((court) {
                                        final courtName = court['name'];
                                        final selectedSlots =
                                            selectedCourtSlots[courtName] ?? [];

                                        return Row(
                                          children: [
                                            // Left padding cell (empty to align court name)
                                            ...List.generate(controller.timeSlots.length, (
                                              index,
                                            ) {
                                              String slot =
                                                  controller.timeSlots[index];
                                              final slotData =
                                                  slotInfoMap[slot];
                                              final isPeak =
                                                  slotData?['isPeak'] ?? false;
                                              courtPrice =
                                                  (slotData?['price'] ?? 0.0)
                                                      .toInt();
                                              bool isSelected = selectedSlots
                                                  .contains(slot);
                                              String? user = getBookingUser(
                                                courtName,
                                                slot,
                                              );
                                              bool isBooked = user != null;
                                              bool isPastSlot = isSlotInPast(
                                                slot,
                                              );

                                              // Merged selection
                                              final isFirstInMerged =
                                                  isSelected &&
                                                  (index == 0 ||
                                                      !selectedSlots.contains(
                                                        controller
                                                            .timeSlots[index -
                                                            1],
                                                      ));

                                              int mergeSpan = 1;
                                              if (isFirstInMerged) {
                                                for (
                                                  int i = index + 1;
                                                  i <
                                                      controller
                                                          .timeSlots
                                                          .length;
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

                                              if (isSelected &&
                                                  !isFirstInMerged) {
                                                return const SizedBox.shrink();
                                              }
                                              if (isBooked) {
                                                final currentUser = user;
                                                final isFirstBooking =
                                                    index == 0 ||
                                                    getBookingUser(
                                                          courtName,
                                                          controller
                                                              .timeSlots[index -
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
                                                  i <
                                                      controller
                                                          .timeSlots
                                                          .length;
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

                                                return Container(
                                                  width: span * 80.0,
                                                  height: 60,
                                                  color: Colors.red.shade50,
                                                  alignment: Alignment.center,
                                                  margin: const EdgeInsets.all(
                                                    1,
                                                  ),
                                                  child: Text(
                                                    currentUser,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          Colors.red.shade500,
                                                    ),
                                                  ),
                                                );
                                              }
                                              return GestureDetector(
                                                onTap: () {
                                                  if (isBooked || isPastSlot)
                                                    return;
                                                  setState(() {
                                                    final selected =
                                                        selectedCourtSlots[courtName] ??
                                                        [];
                                                    if (selected.contains(
                                                      slot,
                                                    )) {
                                                      selected.remove(slot);
                                                    } else {
                                                      bool isAdjacentToAny =
                                                          false;
                                                      for (var existingSlot
                                                          in selected) {
                                                        if (isAdjacent(
                                                          slot,
                                                          existingSlot,
                                                        )) {
                                                          isAdjacentToAny =
                                                              true;
                                                          break;
                                                        }
                                                      }

                                                      if (selected.isEmpty ||
                                                          isAdjacentToAny) {
                                                        selected.add(slot);
                                                      } else {
                                                        selected.add(slot);
                                                      }
                                                    }
                                                    selectedCourtSlots[courtName] =
                                                        selected;
                                                    selectedCourt = courtName;
                                                  });
                                                },
                                                child: Container(
                                                  width: 80.0 * mergeSpan,
                                                  height: 58,
                                                  alignment: Alignment.center,
                                                  margin: const EdgeInsets.all(
                                                    1,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        isSelected
                                                            ? Colors.green
                                                            : isPastSlot
                                                            ? Colors
                                                                .grey
                                                                .shade300
                                                            : isPeak
                                                            ? Colors
                                                                .amber
                                                                .shade50
                                                            : Colors
                                                                .green
                                                                .shade50,
                                                    border: Border.all(
                                                      color:
                                                          Colors.grey.shade300,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
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
                                                            ? Colors
                                                                .grey
                                                                .shade500
                                                            : isPeak
                                                            ? Colors
                                                                .amber
                                                                .shade500
                                                            : Colors
                                                                .green
                                                                .shade500,
                                                  ),
                                                ),
                                              );
                                            }),
                                          ],
                                        );
                                      }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Sticky court names
                    Positioned(
                      top: 50,
                      left: 0,
                      width: 110,
                      bottom: 0,
                      child: SingleChildScrollView(
                        controller: _vertical,
                        scrollDirection: Axis.vertical,
                        child: Column(
                          children:
                              sortedCourts.map((court) {
                                print("Courts: ${court['name']}");
                                return Container(
                                  width: 110,
                                  height: 60,
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  color: Colors.white,
                                  child: Text(
                                    court['name'],
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ),

                    // Top-left static corner
                    Positioned(
                      top: 0,
                      left: 0,
                      width: 110,
                      height: 50,
                      child: Container(
                        color: Colors.white,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'Court/Time',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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

  DateTime parseTime(String slot) {
    try {
      final parts = slot.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      // Debug logging
      print('Parsing slot: $slot');
      print('Parsed hour: $hour, minute: $minute');

      // Use selectedDateTime if available, otherwise use current date
      final date = selectedDateTime ?? DateTime.now();
      return DateTime(date.year, date.month, date.day, hour, minute);
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

  void _pickDateTime() async {
    // Step 1: Pick Date
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    // // Step 2: Pick Time
    // TimeOfDay? pickedTime = await showTimePicker(
    //   context: context,
    //   initialTime:
    //       selectedDateTime != null
    //           ? TimeOfDay.fromDateTime(selectedDateTime!)
    //           : TimeOfDay.now(),
    // );

    if (pickedDate == null) return;

    // Combine Date and Time
    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      // pickedTime.hour,
      // pickedTime.minute,
    );

    setState(() {
      selectedDateTime = combined;
    });
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
    final selectedSlots = selectedCourtSlots[selectedCourt] ?? [];

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

  //Booking Dialog Dialog
  Future<void> showBookingDialog(
    BuildContext context,
    String membershipPlan,
    double memberPrice,
    bool isMembershipApplied,
    List<BookingInfo> bookings,
  ) async {
    double total = bookings.fold(
      0,
      (sum, b) =>
          sum + b.subSlots.fold(0.0, (sum, subSlot) => sum + subSlot.price),
    );

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth:
                  MediaQuery.of(context).size.width /
                  1.5, // 💡 Set this to your preferred max width
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                                fontSize: 18,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Create new booking based on selected courts',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
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
                                fontSize: 16,
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
                                fontSize: 16,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Name Field
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Name',
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    color: Colors.grey.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),

                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: 200,
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                        0.50,
                                  ),
                                  child: TypeAheadField<Map<String, dynamic>>(
                                    controller: nameController,
                                    suggestionsCallback: (pattern) {
                                      if (pattern.isEmpty) return [];
                                      return controller.userList.where((user) {
                                        return user['name']!
                                            .toLowerCase()
                                            .contains(pattern.toLowerCase());
                                      }).toList();
                                    },
                                    builder: (context, controller, focusNode) {
                                      return TextFormField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          color: Colors.grey.shade900,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 10,
                                                horizontal: 12,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    itemBuilder: (context, suggestion) {
                                      return ListTile(
                                        title: Text(suggestion['name']),
                                        subtitle: Text(suggestion['mobile']),
                                      );
                                    },
                                    onSelected: (suggestion) {
                                      nameController.text = suggestion['name'];
                                      mobileController.text =
                                          suggestion['mobile'];
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mobile',
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    color: Colors.grey.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: 200,
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                        0.50,
                                  ),
                                  child: TextFormField(
                                    controller: mobileController,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: Colors.grey.shade900,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    keyboardType: TextInputType.phone,
                                    //  initialValue: '0465 657 456',
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 12,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
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
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'Court Information',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),

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
                                              fontSize: 16,
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
                                                      fontSize: 16,
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
                                                      fontSize: 14,
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
                                                fontSize: 16,
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
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.indigo.shade600,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            "\$${booking.subSlots.fold(0.0, (sum, subSlot) => sum + subSlot.price).toStringAsFixed(2)}",
                                            textAlign: TextAlign.right,
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
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
                    SizedBox(height: 10),
                    if (isMembershipApplied) ...[
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.amber.shade500),
                            ),

                            child: Row(
                              children: [
                                Text(
                                  '$membershipPlan Membership',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: Colors.amber.shade500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Spacer(),

                                Text(
                                  '\$ ${memberPrice}',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: Colors.amber.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                'Membership price updated!!',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.green.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Spacer(),
                              Text(
                                'Total',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '\$ ${(total + memberPrice).toStringAsFixed(2)}',
                                style: GoogleFonts.inter(
                                  fontSize: 19,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Text(
                            'Add Membership and pay ${55} and save ${25}',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Spacer(),
                          Text(
                            'Total',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '\$ ${total}',
                            style: GoogleFonts.inter(
                              fontSize: 19,
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Bottom Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedCourtSlots
                                    .clear(); // Clear all selected slots
                                selectedCourt = null;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              "Cancel",
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isMembershipApplied) ...[
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                showAdvanceBookingDialog(context, bookings);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                "Advance Booking",
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                showMembershipplanDialog(context, bookings);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                "Enroll Membership",
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],

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
                                  TotalAmount = total + memberPrice;
                                } else {
                                  TotalAmount = total;
                                }
                                showBookingConfirmationDialog(
                                  context,
                                  nameController.text,
                                  mobileController.text,
                                  selectedCourt.toString(),
                                  TotalAmount,
                                  selectedDateTime ?? DateTime.now(),
                                  bookings,
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
                            ),
                            child: Text(
                              "Quick Booking",
                              style: GoogleFonts.inter(
                                fontSize: 17,
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
              ),
            ),
          ),
        );
      },
    );
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
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.bookingId,
                      style: GoogleFonts.inter(
                        fontSize: 16,
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
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              mobile,
                              style: GoogleFonts.inter(
                                color: Colors.grey.shade800,
                                fontSize: 14,
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
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),

                            Text(
                              game,
                              style: GoogleFonts.inter(
                                fontSize: 16,
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
                          fontSize: 16,
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
                                              fontSize: 16,
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
                                                      fontSize: 16,
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
                                                      fontSize: 14,
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
                                                fontSize: 16,
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
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.indigo.shade600,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            "\$${booking.subSlots.fold(0.0, (sum, subSlot) => sum + subSlot.price).toStringAsFixed(2)}",
                                            textAlign: TextAlign.right,
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
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
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              side: BorderSide(color: Colors.grey.shade400),
                            ),
                            child: Text(
                              "Pay Later",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
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
                                ),
                              );
                              // if (parentContext.mounted) {
                              //   WidgetsBinding.instance.addPostFrameCallback((
                              //     _,
                              //   ) {

                              //     // Navigator.of(parentContext).push(
                              //     //   MaterialPageRoute(
                              //     //     builder: (_) => CheckoutScreen(),
                              //     //   ),
                              //     // );
                              //   });
                              // }

                              // await Future.delayed(Duration(seconds: 2));
                              // // Navigator.pop(context); // closes dialog
                              // // ... some async work
                              // if (!mounted) return;
                              // // Navigator.of(
                              // //   context,
                              // // ).popUntil((route) => route.isFirst);
                              // // Navigator.pop(parentContext);
                              // // WidgetsBinding.instance.addPostFrameCallback((_) {
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (_) => CheckoutScreen(),
                              //   ),
                              // );
                              // });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              "Pay Now",
                              style: GoogleFonts.inter(
                                fontSize: 14,
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

  //Membership Plan Dialog
  Future<void> showMembershipplanDialog(
    BuildContext context,
    List<BookingInfo> bookings,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: controller.fetchMembershipPlans(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return AlertDialog(
                title: Text("Error"),
                content: Text(snapshot.error.toString()),
              );
            }

            final plans = snapshot.data!;
            String? selectedPlan;
            double selectedPrice = 0;
            List<String> selectedHighlights = [];
            bool isInitialized = false;

            return StatefulBuilder(
              builder: (context, setState) {
                if (!isInitialized && plans.isNotEmpty) {
                  selectedPlan = plans.first["name"];
                  selectedPrice =
                      double.tryParse(plans.first["price"].toString()) ?? 0;
                  selectedHighlights =
                      (plans.first["highlights"] as String)
                          .replaceAll('[', '')
                          .replaceAll(']', '')
                          .split(',')
                          .map((e) => e.trim())
                          .toList();
                  isInitialized = true;
                }
                return Dialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width / 2,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Membership Plan",
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Choose desired membership plan for the customer",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children:
                                  plans.map((plan) {
                                    final isSelected =
                                        selectedPlan == plan["name"];

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedPlan =
                                              plan['name'].toString();
                                          selectedPrice =
                                              double.tryParse(
                                                plan["price"].toString(),
                                              ) ??
                                              0;
                                          final dynamic highlightsRaw =
                                              plan["highlights"]
                                                  .replaceAll('[', '')
                                                  .replaceAll(']', '')
                                                  .split(',')
                                                  .map((e) => e.trim())
                                                  .toList();
                                          if (highlightsRaw is List) {
                                            selectedHighlights =
                                                List<String>.from(
                                                  highlightsRaw,
                                                );
                                          } else if (highlightsRaw is String) {
                                            selectedHighlights = [
                                              highlightsRaw,
                                            ]; // fallback
                                          } else {
                                            selectedHighlights = [];
                                          }
                                        });
                                      },
                                      child: Container(
                                        width: 180,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color:
                                                isSelected
                                                    ? Colors.indigo.shade500
                                                    : Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          color: Colors.white,
                                        ),
                                        child: Column(
                                          children: [
                                            Image.asset(
                                              plan["badge_icon_url"],
                                              height: 100,
                                              width: 100,
                                              fit: BoxFit.contain,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "${plan["name"]} Plan",
                                              style: GoogleFonts.inter(
                                                color:
                                                    isSelected
                                                        ? Colors.indigo.shade500
                                                        : Colors.black,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              "\$ ${plan["price"]!.toString()}",
                                              style: GoogleFonts.inter(
                                                color:
                                                    isSelected
                                                        ? Colors.indigo.shade500
                                                        : Colors.black,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              plan["billing_cycle"],
                                              style: GoogleFonts.inter(
                                                color:
                                                    isSelected
                                                        ? Colors.indigo.shade500
                                                        : Colors.black,
                                                fontWeight: FontWeight.w400,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                            const SizedBox(height: 20),

                            // Highlights
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Highlights",
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...selectedHighlights.map((highlight) {
                              print("text : $highlight");
                              return Row(
                                children: [
                                  Icon(
                                    Icons.check,
                                    size: 18,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      highlight,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),

                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.shade300,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text(
                                      "Cancel",
                                      style: GoogleFonts.inter(
                                        fontSize: 17,
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
                                      Navigator.pop(
                                        context,
                                      ); // close current booking dialog
                                      // Then use a post-frame callback to trigger next dialog safely
                                      WidgetsBinding.instance.addPostFrameCallback((
                                        _,
                                      ) {
                                        if (selectedPlan != null) {
                                          String planName = selectedPlan!;
                                          double price = selectedPrice;
                                          bool isApplied = true;

                                          // Now you can pass these values to your booking dialog or controller
                                          print(
                                            "Selected: $planName | Price: $price | Applied: $isApplied",
                                          );
                                          showBookingDialog(
                                            context,
                                            planName,
                                            price,
                                            isApplied,
                                            bookings,
                                          );
                                        }
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigo,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text(
                                      "Confirm",
                                      style: GoogleFonts.inter(
                                        fontSize: 17,
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
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Advance Booking Dialog
  Future<void> showAdvanceBookingDialog(
    BuildContext context,
    List<BookingInfo> bookings,
  ) {
    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // List of controllers for the Repeat Until TextFields
            final List<TextEditingController> repeatUntilControllers =
                List.generate(
                  bookings.length,
                  (index) => TextEditingController(
                    text:
                        bookings[index].repeatUntil != null
                            ? DateFormat(
                              'MMM d, yyyy',
                            ).format(bookings[index].repeatUntil!)
                            : '',
                  ),
                );

            // Dispose controllers when the dialog is closed
            // This is important to prevent memory leaks
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!Navigator.of(context).canPop()) {
                for (var controller in repeatUntilControllers) {
                  controller.dispose();
                }
              }
            });

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      MediaQuery.of(context).size.width /
                      1.5, // 💡 Set this to your preferred max width
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                                    fontSize: 18,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Create new booking based on selected courts',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
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
                                    fontSize: 16,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  selectedDateTime != null
                                      ? DateFormat(
                                        'h:mm a',
                                      ).format(selectedDateTime!)
                                      : DateFormat(
                                        'h:mm a',
                                      ).format(DateTime.now()),
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Form(
                          key: _advanceformKey,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              // Name Field
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Name',
                                      style: GoogleFonts.inter(
                                        fontSize: 17,
                                        color: Colors.grey.shade900,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),

                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: 200,
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
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
                                        builder: (
                                          context,
                                          controller,
                                          focusNode,
                                        ) {
                                          return TextFormField(
                                            controller: controller,
                                            focusNode: focusNode,
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              color: Colors.grey.shade900,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            decoration: InputDecoration(
                                              //labelText: 'Name',
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 10,
                                                    horizontal: 12,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mobile',
                                      style: GoogleFonts.inter(
                                        fontSize: 17,
                                        color: Colors.grey.shade900,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: 200,
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                            0.50,
                                      ),
                                      child: TextFormField(
                                        controller: mobileController,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          color: Colors.grey.shade900,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        keyboardType: TextInputType.phone,
                                        //  initialValue: '0465 657 456',
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 10,
                                                horizontal: 12,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
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
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Court Information',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
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
                                children: List.generate(bookings.length, (
                                  index,
                                ) {
                                  final booking = bookings[index];
                                  final isLast = index == bookings.length - 1;
                                  final isExpanded = expandedIndexes.contains(
                                    index,
                                  );
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
                                                  fontSize: 16,
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
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontSize: 16,
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
                                                            "(${booking.subSlots.fold(0, (sum, subSlot) => sum + (subSlot.isPeak ? 30 : 0))} mins peak)",
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontSize: 14,
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
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        Colors.green.shade600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                "${booking.subSlots.length * 30}mins",
                                                style: GoogleFonts.inter(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.indigo.shade600,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                "\$${booking.subSlots.fold(0.0, (sum, subSlot) => sum + subSlot.price).toStringAsFixed(2)}",
                                                textAlign: TextAlign.right,
                                                style: GoogleFonts.inter(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                isExpanded
                                                    ? Icons.expand_less
                                                    : Icons.expand_more,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  if (isExpanded) {
                                                    expandedIndexes.remove(
                                                      index,
                                                    );
                                                  } else {
                                                    expandedIndexes.add(index);
                                                  }
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isExpanded) ...[
                                        /// === Repeat Day Section ===
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                            vertical: 12,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Label
                                              Expanded(
                                                flex: 1,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 8.0,
                                                      ),
                                                  child: Text(
                                                    'Repeat Day',
                                                    style: GoogleFonts.inter(
                                                      color:
                                                          Colors.grey.shade900,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),

                                              // Day Chips
                                              Expanded(
                                                flex: 3,
                                                child: Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children:
                                                      [
                                                        'Mon',
                                                        'Tue',
                                                        'Wed',
                                                        'Thu',
                                                        'Fri',
                                                        'Sat',
                                                        'Sun',
                                                      ].map((day) {
                                                        final isSelected =
                                                            booking.selectedDays
                                                                .contains(day);
                                                        return ChoiceChip(
                                                          shape:
                                                              const StadiumBorder(),
                                                          label: Text(day),
                                                          selected: isSelected,
                                                          onSelected: (
                                                            selected,
                                                          ) {
                                                            if (booking
                                                                .sameLikeAbove)
                                                              return; // Disable editing
                                                            setState(() {
                                                              if (selected) {
                                                                booking
                                                                    .selectedDays
                                                                    .add(day);
                                                              } else {
                                                                booking
                                                                    .selectedDays
                                                                    .remove(
                                                                      day,
                                                                    );
                                                              }
                                                            });
                                                          },
                                                          selectedColor:
                                                              Colors.black,
                                                          backgroundColor:
                                                              Colors
                                                                  .grey
                                                                  .shade100,
                                                          labelStyle:
                                                              GoogleFonts.inter(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color:
                                                                    isSelected
                                                                        ? Colors
                                                                            .white
                                                                        : Colors
                                                                            .grey
                                                                            .shade800,
                                                              ),
                                                        );
                                                      }).toList(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        /// === Repeat Until Section ===
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                            vertical: 12,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                flex: 1,
                                                child: Text(
                                                  'Repeat Until',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14,
                                                    color: Colors.grey.shade900,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                flex: 3,
                                                child: TextFormField(
                                                  controller:
                                                      repeatUntilControllers[index],
                                                  readOnly: true,
                                                  onTap: () async {
                                                    if (booking.sameLikeAbove)
                                                      return; // Disable editing
                                                    final pickedDate =
                                                        await showDatePicker(
                                                          context: context,
                                                          initialDate:
                                                              booking
                                                                  .repeatUntil ??
                                                              DateTime.now().add(
                                                                const Duration(
                                                                  days: 7,
                                                                ),
                                                              ),
                                                          firstDate:
                                                              DateTime.now(),
                                                          lastDate: DateTime(
                                                            2100,
                                                          ),
                                                        );
                                                    if (pickedDate != null) {
                                                      setState(() {
                                                        booking.repeatUntil =
                                                            pickedDate;
                                                        repeatUntilControllers[index]
                                                            .text = DateFormat(
                                                          'MMM d, yyyy',
                                                        ).format(pickedDate);
                                                      });
                                                    }
                                                  },
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        'e.g May 28, 2026',
                                                    suffixIcon:
                                                        booking.repeatUntil !=
                                                                null
                                                            ? IconButton(
                                                              icon: Icon(
                                                                LucideIcons
                                                                    .xCircle,
                                                              ),
                                                              onPressed:
                                                                  booking.sameLikeAbove
                                                                      ? null
                                                                      : () {
                                                                        setState(() {
                                                                          booking.repeatUntil =
                                                                              null;
                                                                          repeatUntilControllers[index]
                                                                              .clear();
                                                                        });
                                                                      },
                                                            )
                                                            : Icon(
                                                              LucideIcons
                                                                  .calendar,
                                                            ),
                                                    isDense: true,
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 10,
                                                          horizontal: 12,
                                                        ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        /// === "Same like above" Checkbox ===
                                        if (index != 0)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0,
                                            ),
                                            child: Row(
                                              children: [
                                                Checkbox(
                                                  value: booking.sameLikeAbove,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      booking.sameLikeAbove =
                                                          value ?? false;
                                                      if (booking
                                                          .sameLikeAbove) {
                                                        // Clone repeatDays and repeatUntil from index 0
                                                        booking.selectedDays =
                                                            List<String>.from(
                                                              bookings[0]
                                                                  .selectedDays,
                                                            );
                                                        booking.repeatUntil =
                                                            bookings[0]
                                                                .repeatUntil;
                                                        repeatUntilControllers[index]
                                                                .text =
                                                            bookings[0].repeatUntil !=
                                                                    null
                                                                ? DateFormat(
                                                                  'MMM d, yyyy',
                                                                ).format(
                                                                  bookings[0]
                                                                      .repeatUntil!,
                                                                )
                                                                : '';
                                                      }
                                                    });
                                                  },
                                                ),
                                                const Text("Same like above"),
                                              ],
                                            ),
                                          ),
                                      ],

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

                        SizedBox(height: 10),

                        Row(
                          children: [
                            Text(
                              'Add Membership and pay ${55} and save ${25}',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Spacer(),
                            Text(
                              'Total',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '\$ 20',
                              style: GoogleFonts.inter(
                                fontSize: 19,
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Bottom Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  // setState(() {
                                  //   selectedCourtSlots
                                  //       .clear(); // Clear all selected slots
                                  //   selectedCourt = null;
                                  // });
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade300,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(
                                  "Cancel",
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(
                                  "Book Now",
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
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
