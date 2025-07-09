import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/constants.dart';
import '../../config/palette.dart';
import '../../controllers/auth_controller.dart';

class OpeningCashScreen extends StatefulWidget {
  const OpeningCashScreen({Key? key}) : super(key: key);

  @override
  State<OpeningCashScreen> createState() => _OpeningCashScreenState();
}

class _OpeningCashScreenState extends State<OpeningCashScreen> {
  final AuthController authController = Get.put(AuthController());
  TextEditingController cashController = TextEditingController();
  bool openCash = true;
  bool kitchenDisplay = false;
  bool onlineOrder = false;
  bool surchargeStatus = false;
  bool isLoading = false;
  bool showDenomination = false;

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

  List<int> quantities = List.filled(11, 0);
  List<TextEditingController> denominationControllers = [];
  double cashSum = 0;

  @override
  void initState() {
    super.initState();
    cashController.text = '0.00';

    // Initialize denomination controllers
    for (int i = 0; i < moneyTypes.length; i++) {
      denominationControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    cashController.dispose();
    for (var controller in denominationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Container(
              width: 600,
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!openCash) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              openCash = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade500,
                            padding: EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 30,
                            ),
                          ),
                          child: Text(
                            'OPEN CASH',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 25,
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isLoading = true;
                            });
                            // Handle skip logic
                            authController.logOut(); // Or navigate to order screen
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                            padding: EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 30,
                            ),
                          ),
                          child: isLoading
                              ? CircularProgressIndicator(
                            color: Colors.indigo.shade500,
                            strokeWidth: 2,
                          )
                              : Text(
                            'SKIP',
                            style: GoogleFonts.poppins(
                              color: Colors.indigo.shade500,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (openCash) ...[
                    Column(
                      children: [
                        Row(
                          spacing: 150,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'OPEN CASH',
                              style: GoogleFonts.poppins(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: cashController,
                                style: GoogleFonts.poppins(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo.shade500,
                                ),
                                textAlign: TextAlign.right,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.attach_money_sharp,
                                      color: Colors.grey, size: 40),
                                  hintText: '0.00',
                                  hintStyle: TextStyle(fontSize: 30),
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
                                    // Update with current cashSum when opening
                                    cashController.text =
                                        cashSum.toStringAsFixed(2);
                                    showDenomination = true;
                                  });
                                },
                              ),
                            )
                          ],
                        ),
                        SizedBox(height: 50),
                        ElevatedButton(
                          onPressed: () {
                            if (cashController.text.isNotEmpty) {
                              setState(() {
                                authController.startLoading.value = true;
                              });
                              authController
                                  .validateOpenCashStatus()
                                  .then((value) {
                                if (value == true) {
                                  authController.addOpenCash(
                                    openingAmount:
                                    double.parse(cashController.text),
                                    // kitchenDisplay: kitchenDisplay,
                                    // onlineOrder: onlineOrder,
                                  );
                                } else {
                                  showCustomSnackbar('Warning',
                                      'Cash counter already opened', Colors.orange);
                                  setState(() {
                                    authController.startLoading.value = false;
                                  });
                                }
                              });
                            } else {
                              showCustomSnackbar('Warning',
                                  'Please Enter the Amount', Colors.orange);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade500,
                            minimumSize: Size(double.infinity, 60),
                          ),
                          child: authController.startLoading.value
                              ? CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                              : Text('OPEN CASH',
                              style: GoogleFonts.poppins(
                                  fontSize: 25, color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (showDenomination) ...[
            // Centered dialog
            Center(
              child: _buildDenominationDialog(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDenominationDialog() {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.4,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(width: 10), // Spacer for alignment
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
                              for (var controller in denominationControllers) {
                                controller.clear();
                              }
                              cashSum = 0;
                              cashController.text = '0.00';
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
                                side: BorderSide(color: Palette.newColor)),
                          ),
                        ),
                        SizedBox(width: 30),
                        IconButton(
                          icon: Icon(Icons.close, size: 30),
                          onPressed: () {
                            setState(() {
                              showDenomination = false;
                            });
                          },
                        ),
                      ],
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
                  cashController.text = cashSum.toStringAsFixed(2);
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
      ),
    );
  }

  Widget _buildDenominationRow(int index) {
    // Update controller value when quantities change
    if (denominationControllers[index].text != quantities[index].toString() &&
        quantities[index] != 0) {
      denominationControllers[index].text = quantities[index].toString();
    } else if (quantities[index] == 0 && denominationControllers[index].text.isNotEmpty) {
      denominationControllers[index].clear();
    }

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
              controller: denominationControllers[index],
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

  void _calculateTotal() {
    double total = 0;
    for (int i = 0; i < moneyTypes.length; i++) {
      total += quantities[i] * moneyTypes[i].price;
    }
    setState(() {
      cashSum = total;
    });
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

void showCustomSnackbar(String title, String message, Color color) {
  Get.snackbar(
    title,
    message,
    backgroundColor: color,
    colorText: Colors.white,
    snackPosition: SnackPosition.BOTTOM,
  );
}