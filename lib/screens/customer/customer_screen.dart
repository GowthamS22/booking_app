import 'package:booking_app/config/palette.dart';
import 'package:booking_app/controllers/customer_controller.dart';
import 'package:booking_app/screens/checkout/checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({Key? key}) : super(key: key);

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final CustomerController customerController = Get.put(CustomerController());
  final TextEditingController _searchController = TextEditingController();
  String? centerSlug;
  bool isLoading = true;
  String? selectedMembershipPlanId;
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
    customerController.fetchCustomerDetails().then((_) {
      filteredCustomers = customerController.customers;
      setState(() {});
    });
    if (customerController.membershipPlans.isEmpty) {
      customerController.fetchMembershipPlanDetails();
    }
  }

  Future<void> _loadCenterSlug() async {
    final preferences = await SharedPreferences.getInstance();
    setState(() {
      customerController.centerSlug = preferences.getString('centerSlug');
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || customerController.centerSlug == null) {
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
                      'Customer',
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 23,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Get a glance of all customers at once',
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
              if (customerController.isLoading.value) {
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
                                              await customerController.updateCustomer(
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
                                                final plan = customerController.membershipPlans.firstWhereOrNull(
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
              'Add Customer',
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
    final plans = customerController.membershipPlans;
    String? selectedPlan = '';
    selectedMembershipId = '';

    customerController.nameController.clear();
    customerController.mobileController.clear();
    selectedMembershipPlanId = null;

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
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New Customer',
                              style: GoogleFonts.inter(
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enter details for new customer',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const Divider(height: 24),

                            // Name Field
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
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: customerController.nameController,
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

                            // Mobile Field
                            const SizedBox(height: 10),
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
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: customerController.mobileController,
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey.shade900,
                              ),
                              keyboardType: TextInputType.phone,
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
                                  return 'Please enter mobile number';
                                }
                                // Add more sophisticated phone validation if needed
                                return null;
                              },
                            ),

                            // Membership Type Dropdown
                            // const SizedBox(height: 10),
                            // Text(
                            //   'Membership Type',
                            //   style: GoogleFonts.inter(
                            //     fontWeight: FontWeight.w600,
                            //     fontSize: 22,
                            //     color: Colors.black,
                            //   ),
                            // ),
                            // const SizedBox(height: 8),
                            // Obx(() {
                            //   return DropdownButtonFormField<String>(
                            //     value: selectedMembershipPlanId,
                            //     style: GoogleFonts.inter(
                            //       fontSize: 20,
                            //       fontWeight: FontWeight.w400,
                            //       color: Colors.grey.shade900,
                            //     ),
                            //     isExpanded: true,
                            //     decoration: InputDecoration(
                            //       border: OutlineInputBorder(
                            //         borderRadius: BorderRadius.all(
                            //           Radius.circular(10),
                            //         ),
                            //         borderSide: BorderSide(
                            //           color: Colors.grey.shade100,
                            //         ),
                            //       ),
                            //       contentPadding: EdgeInsets.symmetric(
                            //         horizontal: 16,
                            //         vertical: 14,
                            //       ),
                            //       hintText: 'Select a membership (optional)',
                            //     ),
                            //     items: [
                            //       DropdownMenuItem<String>(
                            //         value: null,
                            //         child: Text(
                            //           'None',
                            //           style: GoogleFonts.inter(
                            //             fontSize: 20,
                            //             fontWeight: FontWeight.w400,
                            //             color: Colors.grey.shade500,
                            //           ),
                            //         ),
                            //       ),
                            //       ...customerController.membershipPlans.map((plan) {
                            //         return DropdownMenuItem<String>(
                            //           value: plan['id'],
                            //           child: Text(
                            //             plan['name'] ?? '',
                            //             style: GoogleFonts.inter(
                            //               fontSize: 20,
                            //               fontWeight: FontWeight.w400,
                            //               color: Colors.grey.shade900,
                            //             ),
                            //           ),
                            //         );
                            //       }).toList(),
                            //     ],
                            //     onChanged: (value) {
                            //       selectedMembershipPlanId = value;
                            //       setState(() {});
                            //     },
                            //   );
                            // }),

                            // Display selected membership details
                            if (selectedMembershipPlanId != null && selectedMembershipPlanId!.isNotEmpty)
                              ...customerController.membershipPlans.where((plan) => plan['id'] == selectedMembershipPlanId).map((plan) {
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
                                        final name = customerController.nameController.text.trim();
                                        final mobile = customerController.mobileController.text.trim();
                                        final membershipId = selectedMembershipPlanId;

                                        // showDialog(
                                        //   context: context,
                                        //   barrierDismissible: false,
                                        //   builder: (BuildContext context) {
                                        //     return Center(
                                        //       child: CircularProgressIndicator(),
                                        //     );
                                        //   },
                                        // );

                                        try {
                                          final customer = await customerController.addCustomer(
                                            firstName: name,
                                            mobile: mobile,
                                          );

                                          if (customer != null) {
                                            showCustomSnackbar('Success', 'Customer added successfully!', Colors.green);
                                          }

                                          // Optionally clear form after navigation
                                          customerController.nameController.clear();
                                          customerController.mobileController.clear();
                                          selectedMembershipPlanId = null;
                                          setState(() {});

                                          Navigator.pop(context);

                                          // Dismiss loading indicator

                                          // if (customer != null) {
                                          //   showCustomSnackbar('Success', 'Customer added successfully!', Colors.green);
                                          //
                                          //   // Clear form only if not going to payment
                                          //   if (membershipId == null || membershipId.isEmpty) {
                                          //     customerController.nameController.clear();
                                          //     customerController.mobileController.clear();
                                          //     selectedMembershipPlanId = null;
                                          //     setState(() {});
                                          //     Navigator.pop(context);
                                          //   } else {
                                          //     // Find the selected membership plan details
                                          //     final selectedPlan = customerController.membershipPlans.firstWhere(
                                          //           (plan) => plan['id'] == membershipId,
                                          //       orElse: () => {},
                                          //     );
                                          //
                                          //     // Navigate to CheckoutScreen with membership details
                                          //     Get.to(
                                          //       CheckoutScreen(
                                          //         type: 'Membership',
                                          //         customerName: name,
                                          //         mobileno: mobile,
                                          //         selectedDateTime: DateTime.now(),
                                          //         billAmount: double.tryParse(selectedPlan['price']?.toString() ?? '0') ?? 0,
                                          //         bookings: [],
                                          //         membershipID: membershipId,
                                          //         membershipName: selectedPlan['name'] ?? '',
                                          //         isMembershipApplied: true,
                                          //         membershipPrice: double.tryParse(selectedPlan['price']?.toString() ?? '0') ?? 0,
                                          //         exuserId: customer['id'],
                                          //       ),
                                          //     );
                                          //
                                          //     // Optionally clear form after navigation
                                          //     customerController.nameController.clear();
                                          //     customerController.mobileController.clear();
                                          //     selectedMembershipPlanId = null;
                                          //     setState(() {});
                                          //   }
                                          //
                                          // } else {
                                          //   showCustomSnackbar('Error', 'Failed to add customer', Colors.red);
                                          // }

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
                                    child: Text("Add",
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
                      await customerController.softDeleteCustomer(
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
      filteredCustomers = customerController.customers;
    } else {
      filteredCustomers =
          customerController.customers.where((customer) {
            final name = (customer['name'] ?? '').toLowerCase();
            final mobile = (customer['mobile'] ?? '').toLowerCase();
            return name.contains(query) || mobile.contains(query);
          }).toList();
    }
    setState(() {});
  }
}
