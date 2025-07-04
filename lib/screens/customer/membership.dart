import 'package:booking_app/config/palette.dart';
import 'package:booking_app/controllers/membership_controller.dart';
import 'package:booking_app/screens/checkout/checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({Key? key}) : super(key: key);

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  final MembershipController membershipController = Get.put(
    MembershipController(),
  );
  final TextEditingController _searchController = TextEditingController();
  String? centerSlug;
  bool isLoading = true;
  String? editingCustomerId;
  TextEditingController editNameController = TextEditingController();
  TextEditingController editMobileController = TextEditingController();
  String? editMembershipPlanId;
  List<Map<String, dynamic>> filteredCustomers = [];
  String? selectedMembershipId;
  double _selectedPrice = 0.0;
  String? staffName;

  @override
  void initState() {
    super.initState();
    _loadCenterSlug();
    membershipController.fetchCustomerDetails(hasMembership: true).then((_) {
      filteredCustomers = membershipController.customers;
      setState(() {});
    });
    if (membershipController.membershipPlans.isEmpty) {
      membershipController.fetchMembershipPlanDetails();
    }
  }

  Future<void> _loadCenterSlug() async {
    final preferences = await SharedPreferences.getInstance();
    setState(() {
      membershipController.centerSlug = preferences.getString('centerSlug');
      staffName = preferences.getString('userName');
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || membershipController.centerSlug == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Members',
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 23,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Get a glance of all members at once',
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade500,
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                Spacer(),
                Text(
                  DateFormat('MMM d, yyyy EEEE').format(DateTime.now()),
                  style: GoogleFonts.inter(
                    color: Colors.black,
                    fontSize: 23,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 10),
                CircleAvatar(
                  radius: 25,
                  backgroundImage: AssetImage("assets/images/pic/Avatar.png"),
                ),
                SizedBox(width: 10),
                Text(
                  '${staffName}',
                  style: GoogleFonts.inter(
                    color: Colors.black,
                    fontSize: 23,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            _buildTopBar(),
            SizedBox(height: 20),
            // Custom Header Row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Name',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Mobile No.',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Total Booking',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Membership',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Total Spent (\$)',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Action',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Obx(() {
              if (membershipController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 200,
                    child: ListView.builder(
                      itemCount: filteredCustomers.length,
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final customer = filteredCustomers[index];
                        final isEditing = editingCustomerId == customer['id'];
                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 10,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Name
                                  Expanded(
                                    child: Center(
                                      child:
                                          isEditing
                                              ? TextFormField(
                                                controller: editNameController,
                                                style: GoogleFonts.inter(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey.shade900,
                                                ),

                                                decoration: InputDecoration(
                                                  isDense:
                                                      true, // trims vertical padding a bit
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                        horizontal: 10,
                                                      ),
                                                  border: OutlineInputBorder(
                                                    // default state
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                        // unfocused state
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color:
                                                              Colors
                                                                  .grey
                                                                  .shade400,
                                                          width: 1.2,
                                                        ),
                                                      ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                        // focused state
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                          width: 1.2,
                                                        ),
                                                      ),
                                                ),
                                                keyboardType:
                                                    TextInputType.name,
                                                maxLines: 1,
                                              )
                                              : Text(
                                                customer['name'] ?? '',
                                                style: GoogleFonts.inter(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey.shade900,
                                                ),
                                              ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  // Mobile
                                  Expanded(
                                    child: Center(
                                      child:
                                          isEditing
                                              ? TextFormField(
                                                controller:
                                                    editMobileController,
                                                style: GoogleFonts.inter(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey.shade900,
                                                ),
                                                keyboardType:
                                                    TextInputType.phone,
                                                inputFormatters: [
                                                  MobileNumberFormatter(),
                                                ],
                                                validator: (value) {
                                                  final digitsOnly =
                                                      value?.replaceAll(
                                                        RegExp(r'\D'),
                                                        '',
                                                      ) ??
                                                      '';
                                                  if (digitsOnly.isEmpty)
                                                    return 'Mobile number is required';
                                                  if (digitsOnly.length != 10)
                                                    return 'Enter a valid 10-digit number';
                                                  final ausMobileRegExp =
                                                      RegExp(
                                                        r'^\d{4} \d{3} \d{3}$',
                                                      );
                                                  if (!ausMobileRegExp.hasMatch(
                                                    value ?? '',
                                                  )) {
                                                    return 'Mobile number must be in the format XXXX XXX XXX (e.g., 0470 350 213).';
                                                  }
                                                  return null;
                                                },
                                                decoration: InputDecoration(
                                                  isDense:
                                                      true, // trims vertical padding a bit
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                        horizontal: 10,
                                                      ),
                                                  border: OutlineInputBorder(
                                                    // default state
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                        // unfocused state
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color:
                                                              Colors
                                                                  .grey
                                                                  .shade400,
                                                          width: 1.2,
                                                        ),
                                                      ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                        // focused state
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                          width: 1.2,
                                                        ),
                                                      ),
                                                ),
                                                maxLines: 1,
                                              )
                                              : Text(
                                                customer['mobile'] ?? '',
                                                style: GoogleFonts.inter(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey.shade900,
                                                ),
                                              ),
                                    ),
                                  ),

                                  // Total Bookings
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        customer['totalBookings'].toString(),
                                        style: GoogleFonts.inter(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Membership
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        customer['membership'] ?? '',
                                        style: GoogleFonts.inter(
                                          fontSize: 23,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade900,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Total Spent
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        "\$${customer['totalSpent']}",
                                        style: GoogleFonts.inter(
                                          fontSize: 23,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade900,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Actions
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            isEditing
                                                ? LucideIcons.save
                                                : LucideIcons.edit,
                                            size: 28,
                                            color:
                                                isEditing ? Colors.green : null,
                                          ),
                                          onPressed: () async {
                                            if (isEditing) {
                                              final updatedName =
                                                  editNameController.text
                                                      .trim();
                                              final updatedMobile =
                                                  editMobileController.text
                                                      .trim();
                                              final updatedMembershipPlanId =
                                                  editMembershipPlanId;

                                              // Validation: Name or Mobile empty
                                              if (updatedName.isEmpty ||
                                                  updatedMobile.isEmpty) {
                                                showCustomSnackbar(
                                                  'Error',
                                                  'Name and Mobile number cannot be empty.',
                                                  Colors.red,
                                                );
                                                return;
                                              }

                                              // Remove spaces for digit check
                                              final digitsOnly = updatedMobile
                                                  .replaceAll(
                                                    RegExp(r'\\D'),
                                                    '',
                                                  );
                                              if (digitsOnly.length != 10) {
                                                showCustomSnackbar(
                                                  'Error',
                                                  'Mobile number must be exactly 10 digits.',
                                                  Colors.red,
                                                );
                                                return;
                                              }

                                              // Format check: XXXX XXX XXX (Australian)
                                              final ausMobileRegExp = RegExp(
                                                r'^\\d{4} \\d{3} \\d{3}\$',
                                              );
                                              if (!ausMobileRegExp.hasMatch(
                                                updatedMobile,
                                              )) {
                                                showCustomSnackbar(
                                                  'Error',
                                                  'Mobile number must be in the format XXXX XXX XXX (e.g., 0470 350 213).',
                                                  Colors.red,
                                                );
                                                return;
                                              }

                                              // Duplicate check for editing
                                              final duplicate =
                                                  membershipController.customers
                                                      .any(
                                                        (c) =>
                                                            c['mobile'] ==
                                                                updatedMobile &&
                                                            c['id'] !=
                                                                customer['id'],
                                                      );
                                              if (duplicate) {
                                                showCustomSnackbar(
                                                  'Error',
                                                  'The phone number you entered is already assigned to another customer. Please use a unique number.',
                                                  Colors.red,
                                                );
                                                return;
                                              }

                                              // Call your update method
                                              await membershipController
                                                  .updateCustomer(
                                                    customerId: customer['id'],
                                                    name: updatedName,
                                                    mobile: updatedMobile,
                                                    membershipPlanId:
                                                        updatedMembershipPlanId,
                                                  );
                                              setState(() {
                                                editingCustomerId = null;
                                              });
                                            } else {
                                              // Enter edit mode
                                              setState(() {
                                                editingCustomerId =
                                                    customer['id'];
                                                editNameController.text =
                                                    customer['name'] ?? '';
                                                editMobileController.text =
                                                    customer['mobile'] ?? '';
                                                final plan = membershipController
                                                    .membershipPlans
                                                    .firstWhereOrNull(
                                                      (plan) =>
                                                          plan['name'] ==
                                                          customer['membership'],
                                                    );
                                                editMembershipPlanId =
                                                    plan?['id'];
                                              });
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 10),
                                        IconButton(
                                          icon: Icon(
                                            LucideIcons.trash2,
                                            color: Colors.red,
                                            size: 28,
                                          ),
                                          onPressed: () async {
                                            // Delete action
                                            showDeleteDialog(
                                              context,
                                              customer['id'],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Spacer(),
        Expanded(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.6,
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.roboto(fontSize: 22),
              decoration: InputDecoration(
                hintText: 'search "john"',
                hintStyle: GoogleFonts.inter(
                  fontSize: 22,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w400,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.grey.shade500,
                    width: 1.5,
                  ),
                ),
                isDense: true,
              ),
              onChanged: (_) => filterCustomers(),
            ),
          ),
        ),
        const SizedBox(width: 20),

        // Container(
        //   height: 50,
        //   width: 50,
        //   decoration: BoxDecoration(
        //     color: Colors.white,
        //     borderRadius: BorderRadius.circular(12),
        //     border: Border.all(color: Colors.grey.shade300),
        //   ),
        //   child: const Icon(LucideIcons.filter, size: 30),
        // ),
        // Container(
        //   height: 60,
        //   width: 60,
        //   decoration: BoxDecoration(
        //     color: Colors.white,
        //     borderRadius: BorderRadius.circular(12),
        //     border: Border.all(color: Colors.grey.shade300),
        //   ),
        //   child: const Icon(LucideIcons.upload, size: 30),
        // ),
        // const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            openMembershipDrawer(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 13),
            decoration: BoxDecoration(
              color: Palette.newColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey),
            ),
            child: Text(
              'New Membership',
              style: GoogleFonts.inter(
                fontSize: 23,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> openMembershipDrawer(BuildContext context) async {
    String? selectedMembershipPlanId;
    bool hasMembership = false;
    String membershipPlan = '';
    String existingMembershipPlanId = '';
    DateTime? membershipValidityDate;
    DateTime? membershipValidityStartDate;
    bool isSameMembershipSelected = false;
    String existingCustomer = '';

    membershipController.nameController.text = '';
    membershipController.mobileController.text = '';

    final plans = membershipController.membershipPlans;
    String? selectedPlan = '';
    selectedMembershipId = '';

    // Helper method to calculate prorated credit
    double calculateProratedCredit(
      double originalPrice,
      DateTime startDate,
      DateTime endDate,
    ) {
      final totalDays = endDate.difference(startDate).inDays;
      final remainingDays = endDate.difference(DateTime.now()).inDays;

      if (remainingDays <= 0) return 0;

      return (originalPrice / totalDays) * remainingDays;
    }

    // Helper method to calculate upgrade cost
    double calculateUpgradeCost(
      double currentPlanPrice,
      double newPlanPrice,
      DateTime validityStart,
      DateTime validityEnd,
    ) {
      final proratedCredit = calculateProratedCredit(
        currentPlanPrice,
        validityStart,
        validityEnd,
      );
      return (newPlanPrice - proratedCredit).clamp(
        0,
        newPlanPrice,
      ); // Ensure we don't go negative
    }

    // Form key for validation
    final _formKey = GlobalKey<FormState>();

    void _clearMembershipData() {
      setState(() {
        existingCustomer = '';
        hasMembership = false;
        membershipPlan = '';
        existingMembershipPlanId = '';
        membershipValidityDate = null;
        membershipValidityStartDate = null;
        isSameMembershipSelected = false;
        selectedMembershipPlanId = null;
      });
    }

    void _updateUserData(Map<String, dynamic> userData) {
      membershipController.nameController.text = userData['name'] ?? '';
      membershipController.mobileController.text = userData['mobile'] ?? '';
      setState(() {
        existingCustomer = userData['id'];
        hasMembership =
            userData['membershipplan_id'] != null &&
            userData['membershipplan_id'].toString().isNotEmpty;
        membershipPlan = hasMembership ? userData['membership_plan'] : null;
        existingMembershipPlanId = userData['membershipplan_id'].toString();
        membershipValidityDate =
            hasMembership
                ? DateTime.tryParse(userData['validity_end']?.toString() ?? '')
                : null;
        membershipValidityStartDate =
            hasMembership
                ? DateTime.tryParse(
                  userData['validity_start']?.toString() ?? '',
                )
                : null;
        isSameMembershipSelected =
            hasMembership &&
            selectedMembershipPlanId != null &&
            selectedMembershipPlanId == userData['membershipplan_id'];
      });
    }

    Future<void> _validateAndFetchUserData(String mobile) async {
      if (mobile.length == 12) {
        final suggestions = await membershipController.fetchUserSuggestions(
          mobile,
        );
        if (suggestions.isNotEmpty) {
          final exactMatch = suggestions.firstWhere(
            (user) => user['mobile'] == mobile,
            orElse: () => {},
          );
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

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Customer Add',
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
              widthFactor: 0.4,
              child: Material(
                color: Colors.white,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return Form(
                      key: _formKey,
                      child: SafeArea(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 24,
                            right: 24,
                            top: 24,
                            bottom:
                                MediaQuery.of(context).viewInsets.bottom + 24,
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: IntrinsicHeight(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'New Membership',
                                          style: GoogleFonts.inter(
                                            fontSize: 23,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Enter details for new membership',
                                          style: GoogleFonts.inter(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                        const Divider(height: 24),

                                        // Membership Type Dropdown
                                        const SizedBox(height: 10),
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'Membership Type',
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 22,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              TextSpan(
                                                text: '*',
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 22,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Obx(() {
                                          return SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              children: [
                                                // Membership plan chips
                                                ...membershipController.membershipPlans.map((
                                                  plan,
                                                ) {
                                                  Color chipColor;
                                                  Color textColor;

                                                  if (plan['name']
                                                      .toString()
                                                      .toLowerCase()
                                                      .contains('gold')) {
                                                    chipColor =
                                                        selectedMembershipPlanId ==
                                                                plan['id']
                                                            ? Colors
                                                                .amber
                                                                .shade600
                                                            : Colors
                                                                .amber
                                                                .shade100;
                                                    textColor =
                                                        selectedMembershipPlanId ==
                                                                plan['id']
                                                            ? Colors.white
                                                            : Colors
                                                                .amber
                                                                .shade800;
                                                  } else if (plan['name']
                                                      .toString()
                                                      .toLowerCase()
                                                      .contains('platinum')) {
                                                    chipColor =
                                                        selectedMembershipPlanId ==
                                                                plan['id']
                                                            ? Colors
                                                                .indigo
                                                                .shade600
                                                            : Colors
                                                                .indigo
                                                                .shade100;
                                                    textColor =
                                                        selectedMembershipPlanId ==
                                                                plan['id']
                                                            ? Colors.white
                                                            : Colors
                                                                .indigo
                                                                .shade800;
                                                  } else {
                                                    chipColor =
                                                        selectedMembershipPlanId ==
                                                                plan['id']
                                                            ? Colors
                                                                .grey
                                                                .shade800
                                                            : Colors
                                                                .grey
                                                                .shade200;
                                                    textColor =
                                                        selectedMembershipPlanId ==
                                                                plan['id']
                                                            ? Colors.white
                                                            : Colors
                                                                .grey
                                                                .shade800;
                                                  }

                                                  return GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        selectedMembershipPlanId =
                                                            plan['id'];
                                                        isSameMembershipSelected =
                                                            false;
                                                        isSameMembershipSelected =
                                                            hasMembership &&
                                                            selectedMembershipPlanId !=
                                                                null &&
                                                            selectedMembershipPlanId ==
                                                                existingMembershipPlanId;
                                                      });
                                                    },
                                                    child: Container(
                                                      margin: EdgeInsets.only(
                                                        right: 10,
                                                      ),
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 20,
                                                            vertical: 12,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: chipColor,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              20,
                                                            ),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          if (plan['name']
                                                              .toString()
                                                              .toLowerCase()
                                                              .contains('gold'))
                                                            Icon(
                                                              LucideIcons.crown,
                                                              size: 25,
                                                              color: textColor,
                                                            ),
                                                          if (plan['name']
                                                              .toString()
                                                              .toLowerCase()
                                                              .contains(
                                                                'platinum',
                                                              ))
                                                            Icon(
                                                              LucideIcons.star,
                                                              size: 25,
                                                              color: textColor,
                                                            ),
                                                          SizedBox(width: 8),
                                                          Text(
                                                            plan['name'] ?? '',
                                                            style:
                                                                GoogleFonts.inter(
                                                                  fontSize: 20,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  color:
                                                                      textColor,
                                                                ),
                                                          ),
                                                          SizedBox(width: 8),
                                                          Text(
                                                            '\$${plan['price']}',
                                                            style:
                                                                GoogleFonts.inter(
                                                                  fontSize: 20,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  color:
                                                                      textColor,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ],
                                            ),
                                          );
                                        }),

                                        const SizedBox(height: 20),

                                        // Display selected membership details
                                        if (selectedMembershipPlanId != null &&
                                            selectedMembershipPlanId!
                                                .isNotEmpty) ...[
                                          ...membershipController
                                              .membershipPlans
                                              .where(
                                                (plan) =>
                                                    plan['id'] ==
                                                    selectedMembershipPlanId,
                                              )
                                              .map((plan) {
                                                Color borderColor;
                                                Color backgroundColor;
                                                Color textColor;

                                                if (plan['name']
                                                    .toString()
                                                    .toLowerCase()
                                                    .contains('gold')) {
                                                  borderColor =
                                                      Colors.amber.shade500;
                                                  backgroundColor =
                                                      Colors.amber.shade50;
                                                  textColor =
                                                      Colors.amber.shade500;
                                                } else if (plan['name']
                                                    .toString()
                                                    .toLowerCase()
                                                    .contains('platinum')) {
                                                  borderColor =
                                                      Colors.indigo.shade500;
                                                  backgroundColor =
                                                      Colors.indigo.shade50;
                                                  textColor =
                                                      Colors.indigo.shade500;
                                                } else {
                                                  borderColor =
                                                      Colors.grey.shade300;
                                                  backgroundColor =
                                                      Colors.grey.shade100;
                                                  textColor = Colors.black;
                                                }

                                                return Container(
                                                  margin: const EdgeInsets.only(
                                                    top: 16,
                                                    bottom: 12,
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: borderColor,
                                                      width: 1.5,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    color: backgroundColor,
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            LucideIcons.crown,
                                                            color: textColor,
                                                            size: 30,
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Text(
                                                            " ${plan['name']} Membership",
                                                            style:
                                                                GoogleFonts.inter(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  color:
                                                                      textColor,
                                                                  fontSize: 23,
                                                                ),
                                                          ),
                                                          const Spacer(),
                                                          Text(
                                                            '\$${plan['price']}',
                                                            style:
                                                                GoogleFonts.inter(
                                                                  color:
                                                                      textColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  fontSize: 23,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Text(
                                                            plan['billing_cycle'],
                                                            style:
                                                                GoogleFonts.inter(
                                                                  color:
                                                                      textColor,
                                                                  fontSize: 23,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                      Text(
                                                        plan['description'],
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontSize: 22,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      ...List<Widget>.from(
                                                        (plan['highlights']
                                                                as List)
                                                            .map((highlight) {
                                                              return Row(
                                                                children: [
                                                                  Icon(
                                                                    LucideIcons
                                                                        .dot,
                                                                    size: 22,
                                                                    color:
                                                                        Colors
                                                                            .black,
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 6,
                                                                  ),
                                                                  Expanded(
                                                                    child: Text(
                                                                      highlight,
                                                                      style: GoogleFonts.inter(
                                                                        fontSize:
                                                                            22,
                                                                        fontWeight:
                                                                            FontWeight.w700,
                                                                        color:
                                                                            Colors.black,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              );
                                                            }),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              })
                                              .toList(),
                                          const SizedBox(height: 20),
                                        ],

                                        // Show upgrade calculation if applicable
                                        if (hasMembership &&
                                            selectedMembershipPlanId != null &&
                                            selectedMembershipPlanId !=
                                                existingMembershipPlanId &&
                                            membershipValidityDate != null) ...[
                                          Builder(
                                            builder: (context) {
                                              final currentPlan =
                                                  membershipController
                                                      .membershipPlans
                                                      .firstWhere(
                                                        (plan) =>
                                                            plan['id'] ==
                                                            existingMembershipPlanId,
                                                        orElse: () => {},
                                                      );

                                              final selectedPlan =
                                                  membershipController
                                                      .membershipPlans
                                                      .firstWhere(
                                                        (plan) =>
                                                            plan['id'] ==
                                                            selectedMembershipPlanId,
                                                        orElse: () => {},
                                                      );

                                              if (currentPlan.isNotEmpty &&
                                                  selectedPlan.isNotEmpty) {
                                                final currentPrice =
                                                    double.tryParse(
                                                      currentPlan['price']
                                                              ?.toString() ??
                                                          '0',
                                                    ) ??
                                                    0;
                                                final selectedPrice =
                                                    double.tryParse(
                                                      selectedPlan['price']
                                                              ?.toString() ??
                                                          '0',
                                                    ) ??
                                                    0;

                                                if (selectedPrice >
                                                    currentPrice) {
                                                  final upgradeAmount =
                                                      calculateUpgradeCost(
                                                        currentPrice,
                                                        selectedPrice,
                                                        membershipValidityStartDate!, // Assuming membership started today
                                                        membershipValidityDate!,
                                                      );

                                                  final creditAmount =
                                                      currentPrice -
                                                      upgradeAmount;

                                                  return Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          12,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.blue.shade50,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      border: Border.all(
                                                        color:
                                                            Colors
                                                                .blue
                                                                .shade100,
                                                      ),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          'Upgrade Calculation',
                                                          style:
                                                              GoogleFonts.inter(
                                                                fontSize: 22,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color:
                                                                    Colors
                                                                        .blue
                                                                        .shade800,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              'Current Plan:',
                                                              style: GoogleFonts.inter(
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                            Text(
                                                              '\$$currentPrice (${currentPlan['name']})',
                                                              style: GoogleFonts.inter(
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              'New Plan:',
                                                              style: GoogleFonts.inter(
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                            Text(
                                                              '\$$selectedPrice (${selectedPlan['name']})',
                                                              style: GoogleFonts.inter(
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              'Unused Credit:',
                                                              style: GoogleFonts.inter(
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                            Text(
                                                              '\$${creditAmount.toStringAsFixed(2)}',
                                                              style: GoogleFonts.inter(
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color:
                                                                    Colors
                                                                        .green
                                                                        .shade800,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const Divider(
                                                          height: 16,
                                                          thickness: 1,
                                                        ),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              'Amount to Pay:',
                                                              style: GoogleFonts.inter(
                                                                fontSize: 22,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                            ),
                                                            Text(
                                                              '\$${upgradeAmount.toStringAsFixed(2)}',
                                                              style: GoogleFonts.inter(
                                                                fontSize: 22,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color:
                                                                    Palette
                                                                        .newColor,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }
                                              }
                                              return const SizedBox();
                                            },
                                          ),
                                          const SizedBox(height: 20),
                                        ],

                                        // Mobile Field
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            RichText(
                                              text: TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: 'Mobile ',
                                                    style: GoogleFonts.inter(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 22,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: '*',
                                                    style: GoogleFonts.inter(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 22,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (hasMembership) ...[
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  () {
                                                    if (membershipValidityDate ==
                                                        null) {
                                                      return '$membershipPlan : (No Validity Info)';
                                                    }

                                                    final now = DateTime.now();
                                                    final today = DateTime(
                                                      now.year,
                                                      now.month,
                                                      now.day,
                                                    );
                                                    final expiry = DateTime(
                                                      membershipValidityDate!
                                                          .year,
                                                      membershipValidityDate!
                                                          .month,
                                                      membershipValidityDate!
                                                          .day,
                                                    );

                                                    final difference =
                                                        expiry
                                                            .difference(today)
                                                            .inDays;

                                                    if (difference > 0) {
                                                      return '$membershipPlan : (Valid for $difference days)';
                                                    } else if (difference ==
                                                        0) {
                                                      return '$membershipPlan : (Expires Today)';
                                                    } else {
                                                      return '$membershipPlan : (Expired)';
                                                    }
                                                  }(),
                                                  style: GoogleFonts.inter(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 10),

                                        // ConstrainedBox(
                                        //   constraints: BoxConstraints(
                                        //     minWidth: 200,
                                        //     maxWidth: MediaQuery.of(context).size.width * 0.8,
                                        //   ),
                                        //   child: TypeAheadField<Map<String, dynamic>>(
                                        //     controller: membershipController.mobileController,
                                        //     suggestionsCallback: (pattern) async {
                                        //       return await membershipController.fetchUserSuggestions(pattern);
                                        //     },
                                        //     builder: (context, _, focusNode) {
                                        //       return TextFormField(
                                        //         controller: membershipController.mobileController,
                                        //         focusNode: focusNode,
                                        //         keyboardType: TextInputType.phone,
                                        //         validator: (value) {
                                        //           if (value == null || value.trim().isEmpty) {
                                        //             return 'Mobile number is required';
                                        //           }
                                        //           if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                                        //             return 'Enter a valid 10-digit number';
                                        //           }
                                        //           return null;
                                        //         },
                                        //         style: GoogleFonts.inter(
                                        //           fontSize: 22,
                                        //           color: Colors.grey.shade800,
                                        //           fontWeight: FontWeight.w500,
                                        //         ),
                                        //         decoration: InputDecoration(
                                        //           isDense: true,
                                        //           contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                        //           border: OutlineInputBorder(
                                        //             borderRadius: BorderRadius.circular(8),
                                        //             borderSide: BorderSide(color: Colors.grey.shade300),
                                        //           ),
                                        //           errorStyle: GoogleFonts.inter(
                                        //             fontSize: 22,
                                        //             fontWeight: FontWeight.w500,
                                        //           ),
                                        //         ),
                                        //       );
                                        //     },
                                        //     itemBuilder: (context, suggestion) {
                                        //       return ListTile(
                                        //         title: Text(suggestion['name'] ?? '', style: const TextStyle(fontSize: 22)),
                                        //         subtitle: Text(suggestion['mobile'] ?? '', style: const TextStyle(fontSize: 22)),
                                        //       );
                                        //     },
                                        //     onSelected: (suggestion) {
                                        //       membershipController.nameController.text = suggestion['name'] ?? '';
                                        //       membershipController.mobileController.text = suggestion['mobile'] ?? '';
                                        //       setState(() {
                                        //         existingCustomer = suggestion['id'];
                                        //         hasMembership = suggestion['membershipplan_id'] != null && suggestion['membershipplan_id'].toString().isNotEmpty;
                                        //         membershipPlan = hasMembership ? suggestion['membership_plan'] : null;
                                        //         existingMembershipPlanId = suggestion['membershipplan_id'].toString();
                                        //         membershipValidityDate = hasMembership ? DateTime.tryParse(suggestion['validity_end']?.toString() ?? '') : null;
                                        //         membershipValidityStartDate = hasMembership ? DateTime.tryParse(suggestion['validity_start']?.toString() ?? '') : null;
                                        //         isSameMembershipSelected = hasMembership && selectedMembershipPlanId != null && selectedMembershipPlanId == suggestion['membershipplan_id'];
                                        //       });
                                        //     },
                                        //   ),
                                        // ),
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minWidth: 200,
                                            maxWidth:
                                                MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                0.50,
                                          ),
                                          child: Autocomplete<
                                            Map<String, dynamic>
                                          >(
                                            displayStringForOption:
                                                (option) =>
                                                    option['mobile'] ?? '',
                                            optionsBuilder: (
                                              TextEditingValue textEditingValue,
                                            ) async {
                                              if (textEditingValue
                                                  .text
                                                  .isEmpty) {
                                                return const Iterable<
                                                  Map<String, dynamic>
                                                >.empty();
                                              }
                                              return await membershipController
                                                  .fetchUserSuggestions(
                                                    textEditingValue.text,
                                                  );
                                            },
                                            onSelected: (
                                              Map<String, dynamic> selection,
                                            ) {
                                              _updateUserData(selection);
                                              // Hide keyboard after selection
                                              FocusScope.of(context).unfocus();
                                            },
                                            fieldViewBuilder: (
                                              BuildContext context,
                                              TextEditingController
                                              fieldTextEditingController,
                                              FocusNode fieldFocusNode,
                                              VoidCallback onFieldSubmitted,
                                            ) {
                                              if (membershipController
                                                      .mobileController
                                                      .text !=
                                                  fieldTextEditingController
                                                      .text) {
                                                WidgetsBinding.instance
                                                    .addPostFrameCallback((_) {
                                                      fieldTextEditingController
                                                              .text =
                                                          membershipController
                                                              .mobileController
                                                              .text;
                                                    });
                                              }

                                              return TextFormField(
                                                controller:
                                                    fieldTextEditingController,
                                                focusNode: fieldFocusNode,
                                                keyboardType:
                                                    TextInputType.phone,
                                                textInputAction:
                                                    TextInputAction
                                                        .done, // Changed to 'done' for better UX
                                                inputFormatters: [
                                                  FilteringTextInputFormatter
                                                      .digitsOnly,
                                                  MobileNumberFormatter(),
                                                ],
                                                onChanged: (value) {
                                                  membershipController
                                                      .mobileController
                                                      .text = value;
                                                  if (value.length < 12) {
                                                    // Only clear if not a complete number
                                                    _clearMembershipData();
                                                  }
                                                },
                                                onFieldSubmitted: (value) {
                                                  _validateAndFetchUserData(
                                                    value,
                                                  );
                                                  // Hide keyboard after submission
                                                  FocusScope.of(
                                                    context,
                                                  ).unfocus();
                                                },
                                                onEditingComplete: () {
                                                  final digitsOnly =
                                                      membershipController
                                                          .mobileController
                                                          .text
                                                          .replaceAll(
                                                            RegExp(r'\D'),
                                                            '',
                                                          );
                                                  if (digitsOnly.length == 10) {
                                                    _validateAndFetchUserData(
                                                      membershipController
                                                          .mobileController
                                                          .text,
                                                    );
                                                  } else {
                                                    _clearMembershipData();
                                                  }
                                                  FocusScope.of(
                                                    context,
                                                  ).unfocus();
                                                },
                                                validator: (value) {
                                                  final digitsOnly =
                                                      value?.replaceAll(
                                                        RegExp(r'\D'),
                                                        '',
                                                      ) ??
                                                      '';
                                                  if (digitsOnly.isEmpty)
                                                    return 'Mobile number is required';
                                                  if (digitsOnly.length != 10)
                                                    return 'Enter a valid 10-digit number';
                                                  return null;
                                                },
                                                style: GoogleFonts.inter(
                                                  fontSize: 22,
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
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    borderSide: BorderSide(
                                                      color:
                                                          Colors.grey.shade300,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                            optionsViewBuilder: (
                                              BuildContext context,
                                              AutocompleteOnSelected<
                                                Map<String, dynamic>
                                              >
                                              onSelected,
                                              Iterable<Map<String, dynamic>>
                                              options,
                                            ) {
                                              return Align(
                                                alignment: Alignment.topLeft,
                                                child: Material(
                                                  elevation: 4.0,
                                                  child: SizedBox(
                                                    height: 200,
                                                    child: ListView.builder(
                                                      padding: EdgeInsets.zero,
                                                      itemCount: options.length,
                                                      itemBuilder: (
                                                        BuildContext context,
                                                        int index,
                                                      ) {
                                                        final Map<
                                                          String,
                                                          dynamic
                                                        >
                                                        option = options
                                                            .elementAt(index);
                                                        return ListTile(
                                                          title: Text(
                                                            option['name'],
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 22,
                                                                ),
                                                          ),
                                                          subtitle: Text(
                                                            option['mobile'],
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 22,
                                                                ),
                                                          ),
                                                          onTap: () {
                                                            onSelected(option);
                                                            // Hide keyboard after tap
                                                            FocusScope.of(
                                                              context,
                                                            ).unfocus();
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

                                        // Name Field
                                        const SizedBox(height: 20),
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'Name ',
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 22,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              TextSpan(
                                                text: '*',
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 22,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        TextFormField(
                                          controller:
                                              membershipController
                                                  .nameController,
                                          style: GoogleFonts.inter(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.grey.shade900,
                                          ),
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(10),
                                              ),
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade100,
                                              ),
                                            ),
                                            errorStyle: GoogleFonts.inter(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please enter customer name';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 20),

                                        if (hasMembership) ...[
                                          if (isSameMembershipSelected)
                                            Text(
                                              membershipValidityDate != null &&
                                                      membershipValidityDate!
                                                          .isBefore(
                                                            DateTime.now(),
                                                          )
                                                  ? 'Your $membershipPlan membership has expired. You can renew it or choose a different plan.'
                                                  : 'You already have an active $membershipPlan membership. Please upgrade if you need a different plan.',
                                              style: GoogleFonts.inter(
                                                fontSize: 22,
                                                color:
                                                    membershipValidityDate !=
                                                                null &&
                                                            membershipValidityDate!
                                                                .isBefore(
                                                                  DateTime.now(),
                                                                )
                                                        ? Colors.orange
                                                        : Colors.red,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              textAlign: TextAlign.center,
                                            )
                                          else
                                            Column(
                                              children: [
                                                Text(
                                                  'Current membership plan: $membershipPlan ${membershipValidityDate != null
                                                      ? membershipValidityDate!.isBefore(DateTime.now())
                                                          ? "(Expired)"
                                                          : "(Active)"
                                                      : ""}',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 22,
                                                    color:
                                                        membershipValidityDate !=
                                                                    null &&
                                                                membershipValidityDate!
                                                                    .isBefore(
                                                                      DateTime.now(),
                                                                    )
                                                            ? Colors.orange
                                                            : Colors
                                                                .grey
                                                                .shade800,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                SizedBox(height: 20),
                                              ],
                                            ),
                                        ],

                                        Spacer(),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.grey.shade300,
                                                  foregroundColor: Colors.white,
                                                  minimumSize: Size.fromHeight(
                                                    60,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
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
                                                onPressed: () async {
                                                  if (_formKey.currentState!
                                                      .validate()) {
                                                    if (selectedMembershipPlanId ==
                                                            null ||
                                                        selectedMembershipPlanId!
                                                            .isEmpty) {
                                                      showCustomSnackbar(
                                                        'Error',
                                                        'Please select a membership type',
                                                        Colors.red,
                                                      );
                                                      return;
                                                    }

                                                    final name =
                                                        membershipController
                                                            .nameController
                                                            .text
                                                            .trim();
                                                    final mobile =
                                                        membershipController
                                                            .mobileController
                                                            .text
                                                            .trim();
                                                    final isMembershipExpired =
                                                        membershipValidityDate !=
                                                            null &&
                                                        membershipValidityDate!
                                                            .isBefore(
                                                              DateTime.now(),
                                                            );

                                                    // Check membership upgrade/downgrade logic
                                                    if (hasMembership) {
                                                      final currentPlan =
                                                          membershipController
                                                              .membershipPlans
                                                              .firstWhere(
                                                                (plan) =>
                                                                    plan['id'] ==
                                                                    existingMembershipPlanId,
                                                                orElse:
                                                                    () => {},
                                                              );

                                                      final selectedPlan =
                                                          membershipController
                                                              .membershipPlans
                                                              .firstWhere(
                                                                (plan) =>
                                                                    plan['id'] ==
                                                                    selectedMembershipPlanId,
                                                                orElse:
                                                                    () => {},
                                                              );

                                                      if (currentPlan
                                                              .isNotEmpty &&
                                                          selectedPlan
                                                              .isNotEmpty) {
                                                        final currentPrice =
                                                            double.tryParse(
                                                              currentPlan['price']
                                                                      ?.toString() ??
                                                                  '0',
                                                            ) ??
                                                            0;
                                                        final selectedPrice =
                                                            double.tryParse(
                                                              selectedPlan['price']
                                                                      ?.toString() ??
                                                                  '0',
                                                            ) ??
                                                            0;

                                                        // Calculate amount to pay
                                                        double amountToPay =
                                                            selectedPrice;
                                                        String
                                                        paymentDescription =
                                                            'New ${selectedPlan['name']} membership';

                                                        // For expired memberships, allow renewing the same plan
                                                        if (!isMembershipExpired) {
                                                          if (selectedMembershipPlanId ==
                                                              existingMembershipPlanId) {
                                                            showCustomSnackbar(
                                                              'Warning',
                                                              'You already have this ${currentPlan['name']} membership plan',
                                                              Colors.orange,
                                                            );
                                                            return;
                                                          }

                                                          if (selectedPrice >
                                                              currentPrice) {
                                                            // Upgrade scenario
                                                            amountToPay =
                                                                calculateUpgradeCost(
                                                                  currentPrice,
                                                                  selectedPrice,
                                                                  membershipValidityStartDate!,
                                                                  membershipValidityDate!,
                                                                );
                                                            paymentDescription =
                                                                'Upgrade to ${selectedPlan['name']}';
                                                          } else if (selectedPrice <
                                                              currentPrice) {
                                                            showCustomSnackbar(
                                                              'Cannot Downgrade',
                                                              'You cannot select a cheaper membership plan (\$$selectedPrice) than your current \$$currentPrice plan',
                                                              Colors.orange,
                                                            );
                                                            return;
                                                          }
                                                        }

                                                        try {
                                                          String? customerId =
                                                              existingCustomer
                                                                      .isNotEmpty
                                                                  ? existingCustomer
                                                                  : (await membershipController
                                                                      .addCustomer(
                                                                        firstName:
                                                                            name,
                                                                        mobile:
                                                                            mobile,
                                                                      ))?['id'];

                                                          Navigator.pop(
                                                            context,
                                                          );

                                                          if (customerId !=
                                                                  null &&
                                                              customerId
                                                                  .isNotEmpty) {
                                                            Get.to(
                                                              CheckoutScreen(
                                                                type:
                                                                    'Membership',
                                                                customerName:
                                                                    name,
                                                                mobileno:
                                                                    mobile,
                                                                selectedDateTime:
                                                                    DateTime.now(),
                                                                billAmount:
                                                                    amountToPay,
                                                                bookings: [],
                                                                membershipID:
                                                                    selectedMembershipPlanId!,
                                                                membershipName:
                                                                    selectedPlan['name'] ??
                                                                    '',
                                                                isMembershipApplied:
                                                                    true,
                                                                membershipPrice:
                                                                    selectedPrice,
                                                                exuserId:
                                                                    customerId,
                                                              ),
                                                            );

                                                            // Clear form
                                                            membershipController
                                                                .nameController
                                                                .clear();
                                                            membershipController
                                                                .mobileController
                                                                .clear();
                                                            selectedMembershipPlanId =
                                                                null;
                                                            setState(() {});
                                                          }
                                                        } catch (e) {
                                                          Navigator.pop(
                                                            context,
                                                          );
                                                          showCustomSnackbar(
                                                            'Error',
                                                            'An error occurred: ${e.toString()}',
                                                            Colors.red,
                                                          );
                                                        }
                                                      }
                                                    } else {
                                                      // New membership purchase code remains the same

                                                      // Duplicate check for adding
                                                      final existing =
                                                          membershipController
                                                              .customers
                                                              .firstWhereOrNull(
                                                                (c) =>
                                                                    c['mobile'] ==
                                                                    mobile,
                                                              );
                                                      if (existing != null) {
                                                        if ((existing['name'] ??
                                                                    '')
                                                                .toLowerCase() !=
                                                            name.toLowerCase()) {
                                                          showCustomSnackbar(
                                                            'Error',
                                                            'This number already belongs to ${existing['name']} – please select that customer or enter a different number.',
                                                            Colors.red,
                                                          );
                                                          return;
                                                        } else {
                                                          showCustomSnackbar(
                                                            'Error',
                                                            'This mobile number already exists.',
                                                            Colors.red,
                                                          );
                                                          return;
                                                        }
                                                      }

                                                      try {
                                                        String? customerId = '';
                                                        if (existingCustomer !=
                                                                '' &&
                                                            existingCustomer !=
                                                                null) {
                                                          customerId =
                                                              existingCustomer;
                                                        } else {
                                                          final customer =
                                                              await membershipController
                                                                  .addCustomer(
                                                                    firstName:
                                                                        name,
                                                                    mobile:
                                                                        mobile,
                                                                  );
                                                          customerId =
                                                              customer!['id'];
                                                        }

                                                        Navigator.pop(context);

                                                        if (customerId !=
                                                                null &&
                                                            customerId != '') {
                                                          final selectedPlan =
                                                              membershipController
                                                                  .membershipPlans
                                                                  .firstWhere(
                                                                    (plan) =>
                                                                        plan['id'] ==
                                                                        selectedMembershipPlanId,
                                                                    orElse:
                                                                        () =>
                                                                            {},
                                                                  );

                                                          Get.to(
                                                            CheckoutScreen(
                                                              type:
                                                                  'Membership',
                                                              customerName:
                                                                  name,
                                                              mobileno: mobile,
                                                              selectedDateTime:
                                                                  DateTime.now(),
                                                              billAmount:
                                                                  double.tryParse(
                                                                    selectedPlan['price']
                                                                            ?.toString() ??
                                                                        '0',
                                                                  ) ??
                                                                  0,
                                                              bookings: [],
                                                              membershipID:
                                                                  selectedMembershipPlanId!,
                                                              membershipName:
                                                                  selectedPlan['name'] ??
                                                                  '',
                                                              isMembershipApplied:
                                                                  true,
                                                              membershipPrice:
                                                                  double.tryParse(
                                                                    selectedPlan['price']
                                                                            ?.toString() ??
                                                                        '0',
                                                                  ) ??
                                                                  0,
                                                              exuserId:
                                                                  customerId,
                                                            ),
                                                          );

                                                          // Clear form
                                                          membershipController
                                                              .nameController
                                                              .clear();
                                                          membershipController
                                                              .mobileController
                                                              .clear();
                                                          selectedMembershipPlanId =
                                                              null;
                                                          setState(() {});
                                                        }
                                                      } catch (e) {
                                                        Navigator.pop(context);
                                                        showCustomSnackbar(
                                                          'Error',
                                                          'An error occurred: ${e.toString()}',
                                                          Colors.red,
                                                        );
                                                      }
                                                    }
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Palette.newColor,
                                                  foregroundColor: Colors.white,
                                                  minimumSize: Size.fromHeight(
                                                    60,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                                child: Text(
                                                  () {
                                                    if (existingMembershipPlanId ==
                                                            '' ||
                                                        existingMembershipPlanId ==
                                                            null) {
                                                      return 'Buy Now';
                                                    } else if (membershipValidityDate !=
                                                            null &&
                                                        membershipValidityDate!
                                                            .isBefore(
                                                              DateTime.now(),
                                                            )) {
                                                      return selectedMembershipPlanId ==
                                                              existingMembershipPlanId
                                                          ? 'Renew Now'
                                                          : 'Upgrade Now';
                                                    } else {
                                                      return 'Upgrade Now';
                                                    }
                                                  }(),
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
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
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

  void showDeleteDialog(BuildContext context, String? customerId) {
    if (customerId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Customer ID is missing!')));
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.all(20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Delete Customer?',
                  style: GoogleFonts.inter(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'Are you sure \nyou want to delete this customer? \nThis action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: Size.fromHeight(50),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final navigator = Navigator.of(
                            context,
                          ); // capture before await
                          await membershipController.softDeleteCustomer(
                            customerId,
                          );
                          if (mounted) {
                            navigator.pop(); // safe to pop
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade500,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: const Size.fromHeight(50),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Delete',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  void filterCustomers() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      filteredCustomers = membershipController.customers;
    } else {
      filteredCustomers =
          membershipController.customers.where((customer) {
            final name = (customer['name'] ?? '').toLowerCase();
            final mobile = (customer['mobile'] ?? '').toLowerCase();
            return name.contains(query) || mobile.contains(query);
          }).toList();
    }
    setState(() {});
  }
}

class MobileNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove non-digit characters
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Limit to 10 digits
    final limited =
        digitsOnly.length > 10 ? digitsOnly.substring(0, 10) : digitsOnly;

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
