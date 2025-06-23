import 'package:booking_app/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:booking_app/controllers/cash_controller.dart';

class CloseCash extends StatefulWidget {
  const CloseCash({Key? key}) : super(key: key);

  @override
  State<CloseCash> createState() => _CloseCashState();
}

class _CloseCashState extends State<CloseCash> {
  final CashController cashController = Get.put(CashController());
  final TextEditingController cashInDrawerController = TextEditingController();
  final TextEditingController cashDifferenceReasonController = TextEditingController();
  final TextEditingController eftposDifferenceReasonController = TextEditingController();
  final TextEditingController otherSpendReasonController = TextEditingController();

  bool showCashDifferenceReason = false;
  bool showEftposDifferenceReason = false;
  bool showOtherSpendReason = false;
  bool showDenomination = false;

  double openingBalance = 0.0;
  double cashSales = 0.0;
  double eftposSales = 0.0;
  double eftposFromDevice = 0.0;
  double overallOnAccount = 0.0;
  double otherSpend = 0.0;

  List<int> quantities = List.filled(11, 0);
  double cashSum = 0.0;

  final List<MoneyType> moneyTypes = [
    MoneyType(label: '100', price: 100, type: "Notes"),
    MoneyType(label: '50', price: 50, type: "Notes"),
    MoneyType(label: '20', price: 20, type: "Notes"),
    MoneyType(label: '10', price: 10, type: "Notes"),
    MoneyType(label: '5', price: 5, type: "Notes"),
    MoneyType(label: '2', price: 2, type: "Coins"),
    MoneyType(label: '1', price: 1, type: "Coins"),
    MoneyType(label: '50¢', price: 0.5, type: "Cents"),
    MoneyType(label: '20¢', price: 0.2, type: "Cents"),
    MoneyType(label: '10¢', price: 0.1, type: "Cents"),
    MoneyType(label: '5¢', price: 0.05, type: "Cents"),
  ];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    // Fetch opening balance from database
    final openingData = await cashController.getOpeningBalance();
    setState(() {
      openingBalance = openingData ?? 0.0;
    });

    // Fetch cash sales total
    //final salesData = await cashController.getCashSalesTotal();
    setState(() {
      // cashSales = salesData['cashTotal'] ?? 0.0;
      // eftposSales = salesData['eftposTotal'] ?? 0.0;
      // overallOnAccount = salesData['onAccountTotal'] ?? 0.0;
    });
  }

  void _calculateTotal() {
    double total = 0;
    for (int i = 0; i < moneyTypes.length; i++) {
      total += quantities[i] * moneyTypes[i].price;
    }
    setState(() {
      cashSum = total;
      cashInDrawerController.text = total.toStringAsFixed(2);

      // Check if cash sales matches cash in drawer
      showCashDifferenceReason = (cashSales != total);
    });
  }

  Future<void> _submitCloseCash() async {
    // Validate required fields
    if (showCashDifferenceReason && cashDifferenceReasonController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter reason for cash difference');
      return;
    }

    if (showEftposDifferenceReason && eftposDifferenceReasonController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter reason for EFTPOS difference');
      return;
    }

    if (showOtherSpendReason && otherSpendReasonController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter reason for other spend');
      return;
    }

    final closeCashData = {
      'opening_balance': openingBalance,
      'cash_sales': cashSales,
      'cash_in_drawer': cashSum,
      'cash_difference_reason': showCashDifferenceReason ? cashDifferenceReasonController.text : null,
      'eftpos_sales': eftposSales,
      'eftpos_from_device': eftposFromDevice,
      'eftpos_difference_reason': showEftposDifferenceReason ? eftposDifferenceReasonController.text : null,
      'overall_on_account': overallOnAccount,
      'other_spend': otherSpend,
      'other_spend_reason': showOtherSpendReason ? otherSpendReasonController.text : null,
    };

    // final result = await cashController.closeCash(closeCashData);
    // if (result) {
    //   Get.snackbar('Success', 'Cash closed successfully');
    //   // Navigate to another screen or reset form
    // } else {
    //   Get.snackbar('Error', 'Failed to close cash');
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Close Cash',
                        style: GoogleFonts.inter(
                          color: Colors.black,
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.newColor,
                      minimumSize: const Size(150, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _submitCloseCash,
                    child: Text(
                      'Close Cash',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Divider(color: Colors.grey.shade400),
              SizedBox(height: 10),
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Close Cash',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              fontSize: 25,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Implement scan functionality
                            },
                            icon: Icon(LucideIcons.fingerprint, size: 30),
                            label: Text(
                              'Scan',
                              style: GoogleFonts.inter(
                                color: Colors.indigo.shade500,
                                fontSize: 25,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Palette.newColorbg,
                              minimumSize: const Size(150, 60),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(color: Palette.newColor)
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 25),
                      Column(
                        spacing: 20,
                        children: [
                          // Opening Balance
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Opening Balance',
                                style: GoogleFonts.poppins(
                                  fontSize: 25,
                                ),
                              ),
                              Container(
                                width: 500,
                                child: Expanded(
                                  child: TextFormField(
                                    controller: TextEditingController(text: openingBalance.toStringAsFixed(2)),
                                    style: GoogleFonts.poppins(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo.shade500,
                                    ),
                                    textAlign: TextAlign.right,
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(Icons.attach_money_sharp, color: Colors.grey, size: 35),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 1.0,
                                        ),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 1.0,
                                        ),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Palette.newColor,
                                          width: 2.0,
                                        ),
                                      ),
                                    ),
                                    readOnly: true,
                                  ),
                                ),
                              )
                            ],
                          ),

                          // Cash Sales
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Cash Sales',
                                style: GoogleFonts.poppins(
                                  fontSize: 25,
                                ),
                              ),
                              Container(
                                width: 500,
                                child: Expanded(
                                  child: TextFormField(
                                    controller: TextEditingController(text: cashSales.toStringAsFixed(2)),
                                    style: GoogleFonts.poppins(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo.shade500,
                                    ),
                                    textAlign: TextAlign.right,
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(Icons.attach_money_sharp, color: Colors.grey, size: 35),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 1.0,
                                        ),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 1.0,
                                        ),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Palette.newColor,
                                          width: 2.0,
                                        ),
                                      ),
                                    ),
                                    readOnly: true,
                                  ),
                                ),
                              )
                            ],
                          ),

                          // Cash in drawer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Cash in drawer',
                                style: GoogleFonts.poppins(
                                  fontSize: 25,
                                ),
                              ),
                              Container(
                                width: 500,
                                child: Expanded(
                                  child: TextFormField(
                                    controller: cashInDrawerController,
                                    style: GoogleFonts.poppins(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo.shade500,
                                    ),
                                    textAlign: TextAlign.right,
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(Icons.attach_money_sharp, color: Colors.grey, size: 35),
                                      hintText: '0.00',
                                      hintStyle: TextStyle(fontSize: 25),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 1.0,
                                        ),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 1.0,
                                        ),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Palette.newColor,
                                          width: 2.0,
                                        ),
                                      ),
                                    ),
                                    readOnly: true,
                                    onTap: () {
                                      setState(() {
                                        showDenomination = true;
                                      });
                                    },
                                  ),
                                ),
                              )
                            ],
                          ),

                          // Cash difference reason (conditionally shown)
                          if (showCashDifferenceReason)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Reason for difference in amount',
                                  style: GoogleFonts.poppins(
                                    fontSize: 25,
                                  ),
                                ),
                                Container(
                                  width: 500,
                                  child: Expanded(
                                    child: TextFormField(
                                      controller: cashDifferenceReasonController,
                                      style: GoogleFonts.poppins(
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo.shade500,
                                      ),
                                      textAlign: TextAlign.right,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                            width: 1.0,
                                          ),
                                        ),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                            width: 1.0,
                                          ),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Palette.newColor,
                                            width: 2.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),

                          // EFTPOS Sales
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'EFTPOS Sales',
                                style: GoogleFonts.poppins(
                                  fontSize: 25,
                                ),
                              ),
                              Container(
                                width: 500,
                                child: Expanded(
                                  child: TextFormField(
                                    controller: TextEditingController(text: eftposSales.toStringAsFixed(2)),
                                    style: GoogleFonts.poppins(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo.shade500,
                                    ),
                                    textAlign: TextAlign.right,
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(Icons.attach_money_sharp, color: Colors.grey, size: 35),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 1.0,
                                        ),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 1.0,
                                        ),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Palette.newColor,
                                          width: 2.0,
                                        ),
                                      ),
                                    ),
                                    readOnly: true,
                                  ),
                                ),
                              )
                            ],
                          ),

                          // EFTPOS from Device
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'EFTPOS from Device',
                                style: GoogleFonts.poppins(
                                  fontSize: 25,
                                ),
                              ),
                              Container(
                                width: 500,
                                child: Expanded(
                                  child: TextFormField(
                                    onChanged: (value) {
                                      setState(() {
                                        eftposFromDevice = double.tryParse(value) ?? 0.0;
                                        showEftposDifferenceReason = (eftposSales != eftposFromDevice);
                                      });
                                    },
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                    style: GoogleFonts.poppins(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo.shade500,
                                    ),
                                    textAlign: TextAlign.right,
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(Icons.attach_money_sharp, color: Colors.grey, size: 35),
                                      hintText: '0.00',
                                      hintStyle: TextStyle(fontSize: 25),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 1.0,
                                        ),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 1.0,
                                        ),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Palette.newColor,
                                          width: 2.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),

                          // EFTPOS difference reason (conditionally shown)
                          if (showEftposDifferenceReason)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Reason for difference in amount',
                                  style: GoogleFonts.poppins(
                                    fontSize: 25,
                                  ),
                                ),
                                Container(
                                  width: 500,
                                  child: Expanded(
                                    child: TextFormField(
                                      controller: eftposDifferenceReasonController,
                                      style: GoogleFonts.poppins(
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo.shade500,
                                      ),
                                      textAlign: TextAlign.right,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                            width: 1.0,
                                          ),
                                        ),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                            width: 1.0,
                                          ),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Palette.newColor,
                                            width: 2.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),

                          // Overall on account / Void
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Overall on account / Void',
                                style: GoogleFonts.poppins(
                                  fontSize: 25,
                                ),
                              ),
                              Container(
                                width: 500,
                                child: Expanded(
                                  child: TextFormField(
                                    controller: TextEditingController(text: overallOnAccount.toStringAsFixed(2)),
                                    style: GoogleFonts.poppins(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo.shade500,
                                    ),
                                    textAlign: TextAlign.right,
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(Icons.attach_money_sharp, color: Colors.grey, size: 35),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 1.0,
                                        ),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 1.0,
                                        ),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Palette.newColor,
                                          width: 2.0,
                                        ),
                                      ),
                                    ),
                                    readOnly: true,
                                  ),
                                ),
                              )
                            ],
                          ),

                          // Other Spend
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Other Spend',
                                style: GoogleFonts.poppins(
                                  fontSize: 25,
                                ),
                              ),
                              Container(
                                width: 500,
                                child: Expanded(
                                  child: TextFormField(
                                    onChanged: (value) {
                                      setState(() {
                                        otherSpend = double.tryParse(value) ?? 0.0;
                                        showOtherSpendReason = (otherSpend > 0);
                                      });
                                    },
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                    style: GoogleFonts.poppins(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo.shade500,
                                    ),
                                    textAlign: TextAlign.right,
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(Icons.attach_money_sharp, color: Colors.grey, size: 35),
                                      hintText: '0.00',
                                      hintStyle: TextStyle(fontSize: 25),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 1.0,
                                        ),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 1.0,
                                        ),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Palette.newColor,
                                          width: 2.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),

                          // Other Spend reason (conditionally shown)
                          if (showOtherSpendReason)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Reason for Other Spend',
                                  style: GoogleFonts.poppins(
                                    fontSize: 25,
                                  ),
                                ),
                                Container(
                                  width: 500,
                                  child: Expanded(
                                    child: TextFormField(
                                      controller: otherSpendReasonController,
                                      style: GoogleFonts.poppins(
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo.shade500,
                                      ),
                                      textAlign: TextAlign.right,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                            width: 1.0,
                                          ),
                                        ),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                            width: 1.0,
                                          ),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Palette.newColor,
                                            width: 2.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: showDenomination ? _buildDenominationBottomSheet() : null,
    );
  }

  Widget _buildDenominationBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cash Denomination',
                style: GoogleFonts.poppins(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Text(
                    '\$${cashSum.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 30),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        quantities = List.filled(11, 0);
                        cashSum = 0;
                        cashInDrawerController.text = '';
                      });
                    },
                    child: Text(
                      'Reset',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        color: Colors.indigo.shade500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.newColorbg,
                      minimumSize: const Size(120, 60),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Palette.newColor)
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: moneyTypes.length,
              itemBuilder: (context, index) {
                return _buildDenominationRow(index);
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                showDenomination = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.newColor,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Submit',
              style: GoogleFonts.poppins(
                fontSize: 22,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDenominationRow(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              moneyTypes[index].label,
              style: GoogleFonts.poppins(
                fontSize: 25,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              moneyTypes[index].type,
              style: GoogleFonts.poppins(
                fontSize: 25,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
              ),
              textAlign: TextAlign.center,
              controller: TextEditingController(
                text: quantities[index] == 0 ? '' : quantities[index].toString(),
              ),
              onChanged: (value) {
                setState(() {
                  quantities[index] = int.tryParse(value) ?? 0;
                  _calculateTotal();
                });
              },
              style: TextStyle(fontSize: 25),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '\$${(quantities[index] * moneyTypes[index].price).toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MoneyType {
  final String label;
  final double price;
  final String type;

  MoneyType({
    required this.label,
    required this.price,
    required this.type,
  });
}