import 'package:booking_app/controllers/customer_controller.dart';
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

  @override
  void initState() {
    super.initState();
    _loadCenterSlug();
    customerController.fetchCustomerDetails();
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
            SizedBox(height: 20),
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
                      itemCount: customerController.customers.length,
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final customer = customerController.customers[index];
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
                                      child: Text(
                                        customer['name'] ?? '',
                                        style: GoogleFonts.inter(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade900,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Mobile
                                  Expanded(
                                    child: Center(
                                      child: Text(
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
                                            LucideIcons.edit,
                                            size: 28,
                                          ),
                                          onPressed: () {
                                            // Edit action
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
                                            //Navigator.pop(context);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            //  const Divider(height: 1),
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
            width: MediaQuery.of(context).size.width * 0.3,
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.roboto(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'search "john"',
                hintStyle: GoogleFonts.inter(
                  fontSize: 22,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w400,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 7,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
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
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        const SizedBox(width: 20),

        Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Icon(LucideIcons.filter, size: 30),
        ),
        const SizedBox(width: 10),
        Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Icon(LucideIcons.upload, size: 30),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.indigo.shade500,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey),
          ),
          child: GestureDetector(
            onTap: () {
              openMembershipDrawer(context);
            },
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
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
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
                    return Padding(
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
                          Text(
                            'Name',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 22,
                              color: Colors.black,
                            ),
                          ),

                          const SizedBox(height: 8),
                          TextField(
                            controller: customerController.nameController,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey.shade900,
                            ),
                            decoration: InputDecoration(
                              // labelText: "Name",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade100,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Mobile',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 22,
                              color: Colors.black,
                            ),
                          ),

                          const SizedBox(height: 8),
                          TextFormField(
                            controller: customerController.mobileController,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey.shade900,
                            ),
                            decoration: InputDecoration(
                              //labelText: "Name",
                              // hintText: "e.g Sara Williams",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade100,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Membership Type',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 22,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Obx(() {
                            return DropdownButtonFormField<String>(
                              value: selectedMembershipPlanId,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey.shade900,
                              ),
                              isExpanded: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade100,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              items:
                                  customerController.membershipPlans.map((
                                    plan,
                                  ) {
                                    return DropdownMenuItem<String>(
                                      value: plan['id'],
                                      child: Text(
                                        plan['name'] ?? '',
                                        style: GoogleFonts.inter(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.grey.shade900,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                selectedMembershipPlanId = value;
                                setState(() {});
                              },
                            );
                          }),
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
                                  onPressed: () async {
                                    final name =
                                        customerController.nameController.text
                                            .trim();
                                    final mobile =
                                        customerController.mobileController.text
                                            .trim();
                                    final membershipId =
                                        selectedMembershipPlanId;
                                    if (name.isEmpty ||
                                        mobile.isEmpty ||
                                        membershipId == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Please fill all fields.',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    final success = await customerController
                                        .addCustomer(
                                          firstName: name,
                                          mobile: mobile,
                                          membershipPlanId: membershipId,
                                        );
                                    if (success) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Customer added successfully!',
                                          ),
                                        ),
                                      );
                                      customerController.nameController.clear();
                                      customerController.mobileController
                                          .clear();
                                      selectedMembershipPlanId = null;
                                      setState(() {});
                                      Navigator.pop(context);
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to add customer.',
                                          ),
                                        ),
                                      );
                                    }
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
                                    "Add",
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
                          await customerController.softDeleteCustomer(
                            customerId,
                          );
                          Navigator.of(context).pop();
                          setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade500,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: Size.fromHeight(50),
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

  // Widget _buildCustomerTable() {
  //   return StreamBuilder<List<Map<String, dynamic>>>(
  //     stream: supabase
  //         .schema('${centerSlug}_prod_schema')
  //         .from('customers')
  //         .stream(primaryKey: ['id'])
  //         //.eq('status', true)
  //         .map((data) => data as List<Map<String, dynamic>>),
  //     builder: (context, snapshot) {
  //       if (snapshot.connectionState == ConnectionState.waiting) {
  //         return const Center(child: CircularProgressIndicator());
  //       }
  //       if (snapshot.hasError) {
  //         return Center(child: Text("Error: ${snapshot.error}"));
  //       }

  //       List<Map<String, dynamic>> customers = snapshot.data ?? [];

  //       // Filter by search
  //       final searchText = _searchController.text.toLowerCase();
  //       if (searchText.isNotEmpty) {
  //         customers =
  //             customers.where((c) {
  //               final name =
  //                   "${c['first_name'] ?? ''} ${c['last_name'] ?? ''}"
  //                       .toLowerCase();
  //               return name.contains(searchText);
  //             }).toList();
  //       }

  //       return SingleChildScrollView(
  //         scrollDirection: Axis.vertical,
  //         child: Container(
  //           padding: EdgeInsets.all(20),
  //           width: MediaQuery.of(context).size.width / 1.06,
  //           child: DataTable(
  //             headingRowColor: MaterialStateProperty.all(Colors.black),
  //             headingTextStyle: GoogleFonts.inter(
  //               color: Colors.white,
  //               fontSize: 22,
  //               fontWeight: FontWeight.bold,
  //             ),
  //             columnSpacing: 32,
  //             headingRowHeight: 70,
  //             dataRowMinHeight: 50,
  //             dataRowMaxHeight: 65,
  //             columns: const [
  //               DataColumn(label: Text("Name")),
  //               DataColumn(label: Text("Mobile No.")),
  //               DataColumn(label: Text("Total Booking")),
  //               DataColumn(label: Text("Membership")),
  //               DataColumn(label: Text("Total Spent (\$)")),
  //               DataColumn(label: Text("Action")),
  //             ],
  //             rows:
  //                 customers.map((customer) {
  //                   final name =
  //                       "${customer['first_name'] ?? ''} ${customer['last_name'] ?? ''}";
  //                   final mobile = customer['mobile'] ?? '';
  //                   final membership = customer['membershipplan_id'] ?? '-';

  //                   return DataRow(
  //                     cells: [
  //                       DataCell(
  //                         Text(name, style: GoogleFonts.inter(fontSize: 22)),
  //                       ),
  //                       DataCell(
  //                         Text(mobile, style: GoogleFonts.inter(fontSize: 22)),
  //                       ),
  //                       DataCell(
  //                         Text("23", style: GoogleFonts.inter(fontSize: 22)),
  //                       ), // TODO: Replace with actual bookings
  //                       DataCell(
  //                         Text(
  //                           membership,
  //                           style: GoogleFonts.inter(fontSize: 22),
  //                         ),
  //                       ),
  //                       DataCell(
  //                         Text(
  //                           "\$7586.87",
  //                           style: GoogleFonts.inter(fontSize: 22),
  //                         ),
  //                       ), // TODO: Replace with actual total spent
  //                       DataCell(
  //                         Row(
  //                           children: [
  //                             IconButton(
  //                               icon: const Icon(Icons.edit, size: 28),
  //                               onPressed: () {
  //                                 // Edit action
  //                               },
  //                             ),
  //                             IconButton(
  //                               icon: const Icon(
  //                                 Icons.delete,
  //                                 color: Colors.red,
  //                                 size: 28,
  //                               ),
  //                               onPressed: () async {
  //                                 await supabase
  //                                     .schema('${centerSlug}_prod_schema')
  //                                     .from('customers')
  //                                     .delete()
  //                                     .eq('id', customer['id']);
  //                               },
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                     ],
  //                   );
  //                 }).toList(),
  //           ),
  //         ),
  //       );
  //     },
  //   );

  // }
}
