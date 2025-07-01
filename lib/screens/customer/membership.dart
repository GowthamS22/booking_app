import 'package:booking_app/config/palette.dart';
import 'package:booking_app/controllers/membership_controller.dart';
import 'package:booking_app/screens/checkout/checkout_screen.dart';
import 'package:flutter/material.dart';
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
  final MembershipController membershipController = Get.put(MembershipController());
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
                  'Staff Name',
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
                                        TextInputType.phone,
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
                                              // Save logic
                                              final updatedName = editNameController.text.trim();
                                              final updatedMobile = editMobileController.text.trim();
                                              final updatedMembershipPlanId = editMembershipPlanId;
                                              // Call your update method (e.g., customerController.updateCustomer)
                                              await membershipController.updateCustomer(
                                                customerId: customer['id'],
                                                name: updatedName,
                                                mobile: updatedMobile,
                                                membershipPlanId: updatedMembershipPlanId,
                                              );
                                              setState(() {
                                                editingCustomerId = null;
                                              });
                                            } else {
                                              // Enter edit mode
                                              setState(() {
                                                editingCustomerId = customer['id'];
                                                editNameController.text = customer['name'] ?? '';
                                                editMobileController.text = customer['mobile'] ?? '';
                                                // Find the plan ID by matching the name
                                                final plan = membershipController.membershipPlans.firstWhereOrNull(
                                                      (plan) => plan['name'] == customer['membership'],
                                                );
                                                editMembershipPlanId = plan?['id'];
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
    bool isSameMembershipSelected = false; // New flag to track if same membership is selected

    membershipController.nameController.text = '';
    membershipController.mobileController.text = '';

    final plans = membershipController.membershipPlans;
    String? selectedPlan = '';
    selectedMembershipId = '';

    // Form key for validation
    final _formKey = GlobalKey<FormState>();

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
              widthFactor: 0.4, // Right half of screen
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
                            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                  child: IntrinsicHeight(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                                ...membershipController.membershipPlans.map((plan) {
                                                  Color chipColor;
                                                  Color textColor;

                                                  if (plan['name'].toString().toLowerCase().contains('gold')) {
                                                    chipColor = selectedMembershipPlanId == plan['id']
                                                        ? Colors.amber.shade600
                                                        : Colors.amber.shade100;
                                                    textColor = selectedMembershipPlanId == plan['id']
                                                        ? Colors.white
                                                        : Colors.amber.shade800;
                                                  } else if (plan['name'].toString().toLowerCase().contains('platinum')) {
                                                    chipColor = selectedMembershipPlanId == plan['id']
                                                        ? Colors.indigo.shade600
                                                        : Colors.indigo.shade100;
                                                    textColor = selectedMembershipPlanId == plan['id']
                                                        ? Colors.white
                                                        : Colors.indigo.shade800;
                                                  } else {
                                                    chipColor = selectedMembershipPlanId == plan['id']
                                                        ? Colors.grey.shade800
                                                        : Colors.grey.shade200;
                                                    textColor = selectedMembershipPlanId == plan['id']
                                                        ? Colors.white
                                                        : Colors.grey.shade800;
                                                  }

                                                  return GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        selectedMembershipPlanId = plan['id'];
                                                        isSameMembershipSelected = false;
                                                        isSameMembershipSelected = hasMembership && selectedMembershipPlanId != null && selectedMembershipPlanId == existingMembershipPlanId;
                                                      });
                                                    },
                                                    child: Container(
                                                      margin: EdgeInsets.only(right: 10),
                                                      padding: EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 12,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: chipColor,
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          if (plan['name'].toString().toLowerCase().contains('gold'))
                                                            Icon(
                                                              LucideIcons.crown,
                                                              size: 25,
                                                              color: textColor,
                                                            ),
                                                          if (plan['name'].toString().toLowerCase().contains('platinum'))
                                                            Icon(
                                                              LucideIcons.star,
                                                              size: 25,
                                                              color: textColor,
                                                            ),
                                                          SizedBox(width: 8),
                                                          Text(
                                                            plan['name'] ?? '',
                                                            style: GoogleFonts.inter(
                                                              fontSize: 20,
                                                              fontWeight: FontWeight.w500,
                                                              color: textColor,
                                                            ),
                                                          ),
                                                          SizedBox(width: 8),
                                                          Text(
                                                            '\$${plan['price']}',
                                                            style: GoogleFonts.inter(
                                                              fontSize: 20,
                                                              fontWeight: FontWeight.w500,
                                                              color: textColor,
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
                                        if (selectedMembershipPlanId != null && selectedMembershipPlanId!.isNotEmpty) ...[
                                          ...membershipController.membershipPlans.where((plan) => plan['id'] == selectedMembershipPlanId).map((plan) {
                                            Color borderColor;
                                            Color backgroundColor;
                                            Color textColor;

                                            if (plan['name'].toString().toLowerCase().contains('gold')) {
                                              borderColor = Colors.amber.shade500;
                                              backgroundColor = Colors.amber.shade50;
                                              textColor = Colors.amber.shade500;
                                            } else if (plan['name'].toString().toLowerCase().contains('platinum')) {
                                              borderColor = Colors.indigo.shade500;
                                              backgroundColor = Colors.indigo.shade50;
                                              textColor = Colors.indigo.shade500;
                                            } else {
                                              borderColor = Colors.grey.shade300;
                                              backgroundColor = Colors.grey.shade100;
                                              textColor = Colors.black;
                                            }

                                            return Container(
                                              margin: const EdgeInsets.only(top: 16, bottom: 12),
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: borderColor,
                                                  width: 1.5,
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                                color: backgroundColor,
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
                                                    (plan['highlights'] as List).map((highlight) {
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
                                            );
                                          }).toList(),
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
                                            if (hasMembership) ...[
                                              Container(
                                                padding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  //color: backgroundColor,
                                                  borderRadius: BorderRadius.circular(6),
                                                  //border: Border.all(color: borderColor!,),
                                                ),
                                                child: Text(
                                                  membershipValidityDate != null
                                                      ? '$membershipPlan :(${membershipValidityDate!.difference(DateTime.now()).inDays > 0 ? 'Valid for ${membershipValidityDate!.difference(DateTime.now()).inDays} days' : 'Expired'})'
                                                      : '$membershipPlan : (No Validity Info)',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w700,
                                                    //color: textColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minWidth: 200,
                                            maxWidth: MediaQuery.of(context).size.width * 0.8,
                                          ),
                                          child: TypeAheadField<Map<String, dynamic>>(
                                            controller: membershipController.mobileController,
                                            suggestionsCallback: (pattern) async {
                                              return await membershipController.fetchUserSuggestions(pattern);
                                            },
                                            builder: (context, _, focusNode) {
                                              return TextFormField(
                                                controller: membershipController.mobileController,
                                                focusNode: focusNode,
                                                keyboardType: TextInputType.phone,
                                                validator: (value) {
                                                  if (value == null || value.trim().isEmpty) {
                                                    return 'Mobile number is required';
                                                  }
                                                  if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                                                    return 'Enter a valid 10-digit number';
                                                  }
                                                  return null;
                                                },
                                                style: GoogleFonts.inter(
                                                  fontSize: 22,
                                                  color: Colors.grey.shade800,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                                  ),
                                                  errorStyle: GoogleFonts.inter( // Add this
                                                    fontSize: 22, // Set your desired size
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              );
                                            },
                                            itemBuilder: (context, suggestion) {
                                              return ListTile(
                                                title: Text(suggestion['name'] ?? '', style: const TextStyle(fontSize: 22)),
                                                subtitle: Text(suggestion['mobile'] ?? '', style: const TextStyle(fontSize: 22)),
                                              );
                                            },
                                            onSelected: (suggestion) {
                                              membershipController.nameController.text = suggestion['name'] ?? '';
                                              membershipController.mobileController.text = suggestion['mobile'] ?? '';
                                              setState(() {
                                                hasMembership  = suggestion['membershipplan_id'] != null && suggestion['membershipplan_id'].toString().isNotEmpty;
                                                membershipPlan = hasMembership ? suggestion['membership_plan'] : null;
                                                existingMembershipPlanId = suggestion['membershipplan_id'].toString();
                                                membershipValidityDate = hasMembership ? DateTime.tryParse(suggestion['validity_end']?.toString() ?? '') : null;
                                                isSameMembershipSelected = hasMembership && selectedMembershipPlanId != null && selectedMembershipPlanId == suggestion['membershipplan_id'];
                                              });
                                            },
                                          ),
                                        ),


                                        // Name Field renew
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
                                          controller: membershipController.nameController,
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
                                            errorStyle: GoogleFonts.inter( // Add this
                                              fontSize: 22, // Set your desired size
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter customer name';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 20),

                                        if(hasMembership) ...[
                                          if(isSameMembershipSelected)
                                            Text(
                                              'You already have an active $membershipPlan membership. '
                                                  'Please upgrade if you need a different plan.',
                                              style: GoogleFonts.inter(
                                                fontSize: 22,
                                                color: Colors.red,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            )
                                          else
                                            Text(
                                              'Current membership plan: $membershipPlan',
                                              style: GoogleFonts.inter(
                                                fontSize: 22,
                                                color: Colors.grey.shade800,
                                                fontWeight: FontWeight.w600,
                                              ),
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
                                                  backgroundColor: Colors.grey.shade300,
                                                  foregroundColor: Colors.white,
                                                  minimumSize: Size.fromHeight(60),
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
                                                onPressed: () async {
                                                  if (_formKey.currentState!.validate()) {
                                                    if (selectedMembershipPlanId == null || selectedMembershipPlanId!.isEmpty) {
                                                      showCustomSnackbar('Error', 'Please select a membership type', Colors.red);
                                                      return;
                                                    }
                                                    if (isSameMembershipSelected) {
                                                      showCustomSnackbar('Warning','Already have this membership plan',Colors.orange);
                                                      return;
                                                    }
                                                    final name = membershipController.nameController.text.trim();
                                                    final mobile = membershipController.mobileController.text.trim();
                                                    final membershipId = selectedMembershipPlanId;

                                                    try {
                                                      final customer = await membershipController.addCustomer(
                                                        firstName: name,
                                                        mobile: mobile,
                                                        membershipPlanId: membershipId!,
                                                      );

                                                      Navigator.pop(context); // Dismiss loading indicator

                                                      if (customer != null) {
                                                        //showCustomSnackbar('Success', 'Customer added successfully!', Colors.green);

                                                        // Clear form only if not going to payment
                                                        if (membershipId == null || membershipId.isEmpty) {
                                                          membershipController.nameController.clear();
                                                          membershipController.mobileController.clear();
                                                          selectedMembershipPlanId = null;
                                                          setState(() {});
                                                          Navigator.pop(context);
                                                        } else {
                                                          // Find the selected membership plan details
                                                          final selectedPlan = membershipController.membershipPlans.firstWhere(
                                                                (plan) => plan['id'] == membershipId,
                                                            orElse: () => {},
                                                          );

                                                          // Navigate to CheckoutScreen with membership details
                                                          Get.to(
                                                            CheckoutScreen(
                                                              type: 'Membership',
                                                              customerName: name,
                                                              mobileno: mobile,
                                                              selectedDateTime: DateTime.now(),
                                                              billAmount: double.tryParse(selectedPlan['price']?.toString() ?? '0') ?? 0,
                                                              bookings: [],
                                                              membershipID: membershipId,
                                                              membershipName: selectedPlan['name'] ?? '',
                                                              isMembershipApplied: true,
                                                              membershipPrice: double.tryParse(selectedPlan['price']?.toString() ?? '0') ?? 0,
                                                              exuserId: customer['id'],
                                                            ),
                                                          );

                                                          // Optionally clear form after navigation
                                                          membershipController.nameController.clear();
                                                          membershipController.mobileController.clear();
                                                          selectedMembershipPlanId = null;
                                                          setState(() {});
                                                        }

                                                      } else {
                                                        showCustomSnackbar('Error', 'Failed to add customer', Colors.red);
                                                      }
                                                    } catch (e) {
                                                      Navigator.pop(context);
                                                      showCustomSnackbar('Error', 'An error occurred: ${e.toString()}', Colors.red);
                                                    }
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Palette.newColor,
                                                  foregroundColor: Colors.white,
                                                  minimumSize: Size.fromHeight(60),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                                child: Text(existingMembershipPlanId==null ? 'Buy Now' : 'Upgrade',
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
