import 'package:booking_app/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({Key? key}) : super(key: key);

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? centerSlug;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCenterSlug();
  }

  Future<void> _loadCenterSlug() async {
    final preferences = await SharedPreferences.getInstance();
    setState(() {
      centerSlug = preferences.getString('centerSlug');
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || centerSlug == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildTopBar(),
          _buildCustomerTable()
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFFF5F5F5),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 25),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                hintText: "e.g John",
                hintStyle: const TextStyle(fontSize: 25),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.filter_list, size: 30),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.upload, size: 30),
            onPressed: () {},
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.newColor,
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              // Add Customer action here
            },
            child: const Text(
              "Add Customer",
              style: TextStyle(fontSize: 25, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerTable() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .schema('${centerSlug}_prod_schema')
          .from('customers')
          .stream(primaryKey: ['id'])
          //.eq('status', true)
          .map((data) => data as List<Map<String, dynamic>>),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        List<Map<String, dynamic>> customers = snapshot.data ?? [];

        // Filter by search
        final searchText = _searchController.text.toLowerCase();
        if (searchText.isNotEmpty) {
          customers = customers.where((c) {
            final name = "${c['first_name'] ?? ''} ${c['last_name'] ?? ''}".toLowerCase();
            return name.contains(searchText);
          }).toList();
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            padding: EdgeInsets.all(20),
            width: MediaQuery.of(context).size.width / 1.06,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.black),
              headingTextStyle: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),
              columnSpacing: 32,
              headingRowHeight: 80,
              dataRowMinHeight: 80,
              dataRowMaxHeight: 90,
              columns: const [
                DataColumn(label: Text("Name")),
                DataColumn(label: Text("Mobile No.")),
                DataColumn(label: Text("Total Booking")),
                DataColumn(label: Text("Membership")),
                DataColumn(label: Text("Total Spent (\$)")),
                DataColumn(label: Text("Action")),
              ],
              rows: customers.map((customer) {
                final name = "${customer['first_name'] ?? ''} ${customer['last_name'] ?? ''}";
                final mobile = customer['mobile'] ?? '';
                final membership = customer['membershipplan_id'] ?? '-';

                return DataRow(
                  cells: [
                    DataCell(Text(name, style: const TextStyle(fontSize: 25))),
                    DataCell(Text(mobile, style: const TextStyle(fontSize: 25))),
                    const DataCell(Text("23", style: TextStyle(fontSize: 25))), // TODO: Replace with actual bookings
                    DataCell(Text(membership, style: const TextStyle(fontSize: 25))),
                    const DataCell(Text("\$7586.87", style: TextStyle(fontSize: 25))), // TODO: Replace with actual total spent
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 28),
                          onPressed: () {
                            // Edit action
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 28),
                          onPressed: () async {
                            await supabase
                                .schema('${centerSlug}_prod_schema')
                                .from('customers')
                                .delete()
                                .eq('id', customer['id']);
                          },
                        ),
                      ],
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
