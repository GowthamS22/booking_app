import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../../controllers/setting_controller.dart';
import 'scanPrinterDrawer.dart';

class PrinterScreen extends StatefulWidget {
  const PrinterScreen({super.key});

  @override
  State<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends State<PrinterScreen> {
  final PrinterController printerController = Get.put(PrinterController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      body: Padding(
        padding: EdgeInsets.all(16.0),
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
                        'Settings',
                        style: GoogleFonts.inter(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Customize display, order flow, and printer functions',
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade500,
                    ),
                    onPressed: () {
                      printerController.updateSupabasePrinters();
                    },
                    child: Text(
                      'Update',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Divider(color: Colors.grey.shade300),
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
                      // Title and Scan Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Printer Setup',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              fontSize: 16,
                            ),
                          ),

                          ElevatedButton.icon(
                            onPressed: () {
                              openRightDrawer(context);
                              printerController.scanForPrinters();
                            },
                            icon: Icon(
                              LucideIcons.fingerprint,
                              size: 18,
                            ), // lucide fingerprint icon
                            label: Text(
                              'Scan',
                              style: GoogleFonts.inter(
                                color: Colors.indigo.shade500,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.indigo.shade500,
                              backgroundColor:
                                  Colors.indigo.shade50, // Button fill
                              side: BorderSide(
                                color: Colors.indigo.shade500,
                              ), // Border color
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      // Table Header
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Center(
                                      child: Text(
                                        'Printer Name',
                                        style: GoogleFonts.inter(
                                          color: Colors.grey.shade900,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Center(
                                      child: Text(
                                        'IP Address',
                                        style: GoogleFonts.inter(
                                          color: Colors.grey.shade900,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Center(
                                      child: Text(
                                        'PORT',
                                        style: GoogleFonts.inter(
                                          color: Colors.grey.shade900,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Center(
                                      child: Text(
                                        'Action',
                                        style: GoogleFonts.inter(
                                          color: Colors.grey.shade900,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              // Printer Rows
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.4,
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Obx(() => ListView.builder(
                                        itemCount: printerController.pairedPrinters.length,
                                        itemBuilder: (context, index) {
                                          final printer = printerController.pairedPrinters[index];
                                          return Obx(() {
                                            return GestureDetector(
                                              key: ValueKey(printer['name']),
                                              onTap: () {
                                                printerController.selectPrinter({
                                                  'name': printer['name'],
                                                  'ip': printer['ip'],
                                                  'port': printer['port'],
                                                });
                                              },
                                              child: Container(
                                                color: printerController.selectedPrinter.value == printer ? Colors.indigo.shade50 : Colors.transparent,
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric( vertical: 5,),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        flex: 1,
                                                        child: Center(
                                                          child: Text(
                                                            printer['name'],
                                                            style: GoogleFonts.inter(
                                                              color: Colors.grey.shade900,
                                                              fontSize: 16,
                                                              fontWeight: FontWeight.w400,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 1,
                                                        child: Obx(
                                                          () => printer['isEditing'].value
                                                                  ? Center(
                                                                    child: SizedBox(
                                                                      width: MediaQuery.of(context,).size.width * 0.09,
                                                                      child: TextFormField(
                                                                        initialValue: printer['ip'],
                                                                        onChanged:(val,) => printer['ip'] = val,
                                                                        decoration: InputDecoration(
                                                                          border: OutlineInputBorder(
                                                                            borderRadius: BorderRadius.circular(8,),
                                                                            borderSide: BorderSide(
                                                                              color:Colors.grey.shade300,
                                                                            ),
                                                                          ),
                                                                          contentPadding: EdgeInsets.symmetric( horizontal: 8, vertical: 3,),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  )
                                                                  : Center(
                                                                    child: Text(
                                                                      printer['ip'],
                                                                      style: GoogleFonts.inter(
                                                                        color: Colors.grey.shade900,
                                                                        fontSize: 16,
                                                                        fontWeight: FontWeight.w400,
                                                                      ),
                                                                    ),
                                                                  ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 1,
                                                        child: Obx(
                                                          () =>
                                                              printer['isEditing'].value
                                                                  ? Center(
                                                                    child: SizedBox(
                                                                      width: MediaQuery.of(context,).size.width * 0.09,
                                                                      child: TextFormField(
                                                                        initialValue: printer['port'],
                                                                        onChanged: (val,) => printer['port'] = val,
                                                                        decoration: InputDecoration(
                                                                          border: OutlineInputBorder(
                                                                            borderRadius: BorderRadius.circular(8,),
                                                                            borderSide: BorderSide(
                                                                              color: Colors.grey.shade300,
                                                                            ),
                                                                          ),
                                                                          contentPadding: EdgeInsets.symmetric(
                                                                            horizontal: 8,
                                                                            vertical: 3,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  )
                                                                  : Center(
                                                                    child: Text(
                                                                      printer['port'],
                                                                      style: GoogleFonts.inter(color: Colors.grey.shade900,
                                                                        fontSize: 16,
                                                                        fontWeight: FontWeight.w400,
                                                                      ),
                                                                    ),
                                                                  ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 1,
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            IconButton(
                                                              icon: Icon(
                                                                printer['isEditing'].value ? LucideIcons.save : LucideIcons.pencil,
                                                                size: 20,
                                                                color: Colors.black87,
                                                              ),
                                                              onPressed: () {
                                                                if (printer['isEditing'].value) {
                                                                  printerController.savePrinter(
                                                                    index,
                                                                    printer['ip'],
                                                                    printer['port'],
                                                                  );
                                                                } else {
                                                                  printerController.toggleEdit(index,);
                                                                }
                                                              },
                                                              style: IconButton.styleFrom(
                                                                backgroundColor: Colors.grey.shade200,
                                                                shape: RoundedRectangleBorder(
                                                                  side: BorderSide(
                                                                    color: Colors.grey.shade200,
                                                                  ),
                                                                  borderRadius: BorderRadius.circular(6,),
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(width: 8,),
                                                            IconButton(
                                                              icon: Icon(LucideIcons.trash2,size: 20,color:Colors.white,),
                                                              onPressed: () {
                                                                print(index);
                                                                printerController.deletePrinter(index,);
                                                              },
                                                              style: IconButton.styleFrom(
                                                                backgroundColor: Colors.red.shade600,
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.circular(6,),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          });
                                        },
                                      )),
                                    ),
                                    const Divider(),
                                  ],
                                ),
                              ),

                              Row(
                                mainAxisAlignment:MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '0 of 5 row(s) selected.',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      OutlinedButton(
                                        onPressed: () {},
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.grey.shade700,
                                          side: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Text(
                                          'Previous',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: Colors.grey.shade500,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton(
                                        onPressed: () {},
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.grey.shade700,
                                          side: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Text(
                                          'Next',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: Colors.grey.shade500,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24), // 👈 Adds the desired space
              // Printer Test Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Printer Test',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        printerController.testPrintOnAllPrinters();
                      },
                      icon: Icon(LucideIcons.printer, size: 18),
                      label: Text(
                        'Test Printer',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.indigo.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.indigo.shade500, // Text/Icon color
                        backgroundColor: Colors.indigo.shade50, // Light purple fill
                        side: BorderSide(
                          color: Colors.indigo.shade500,
                        ), // Border
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void openRightDrawer(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierLabel: "Scan Printer",
      barrierDismissible: true,
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
              width: 400,
              child: Material(
                color: Colors.white,
                child: Container(
                  height: MediaQuery.of(context).size.height,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan Printer',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scan and add new Bluetooth Thermal Printer',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Divider(color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      if (printerController.isScanning.value)
                        Center(child: CircularProgressIndicator())
                      else
                        Expanded(
                          child: Obx(() {
                            final selectedIp = printerController.selectedPrinter.value?['ip'];
                            return ListView.builder(
                              itemCount: printerController.availablePrinters.length,
                              itemBuilder: (context, index) {
                                final printer = printerController.availablePrinters[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    LucideIcons.printer,
                                    color: Colors.grey.shade900,
                                  ),
                                  title: Text(
                                    '${printer['name']} (${printer['ip']})',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  selected: selectedIp == printer['ip'],
                                  selectedTileColor: Colors.indigo.shade50,
                                  onTap: () => printerController.selectPrinter(printer),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                );
                              },
                            );
                          }),
                        ),
                      Spacer(),
                      Divider(color: Colors.grey.shade300),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                printerController.selectedPrinter.value = null;
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.grey.shade200,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                "Cancel",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => printerController.confirmPairSelectedPrinter(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                "Pair",
                                style: GoogleFonts.inter(
                                  fontSize: 16,
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
          ),
        );
      },
    );
  }
}
