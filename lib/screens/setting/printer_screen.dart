import 'package:booking_app/config/palette.dart';
import 'package:booking_app/controllers/setting_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';


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
                        'Settings',
                        style: GoogleFonts.inter(
                          color: Colors.black,
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Customize display, order flow, and printer functions',
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade500,
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
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
                    onPressed: () {
                      printerController.updateSupabasePrinters();
                    },
                    child: Text(
                      'Update',
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
                            'Printer Setup',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              fontSize: 25,
                            ),
                          ),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _showManualAddDialog(context),
                                icon: Icon(
                                  LucideIcons.plus,
                                  size: 30,
                                ),
                                label: Text(
                                  'Add',
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
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  openRightDrawer(context);
                                  printerController.scanForPrinters();
                                },
                                icon: Icon(
                                  LucideIcons.scanLine,
                                  size: 30,
                                ),
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
                        ],
                      ),
                      SizedBox(height: 16),
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
                                          fontSize: 22,
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
                                          fontSize: 22,
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
                                          fontSize: 22,
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
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
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
                                                color: printerController.selectedPrinter.value == printer
                                                    ? Colors.indigo.shade50
                                                    : Colors.transparent,
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 5),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        flex: 1,
                                                        child: Center(
                                                          child: Text(
                                                            printer['name'],
                                                            style: GoogleFonts.inter(
                                                              color: Colors.grey.shade900,
                                                              fontSize: 22,
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
                                                              width: MediaQuery.of(context).size.width * 0.09,
                                                              child: TextFormField(
                                                                initialValue: printer['ip'],
                                                                onChanged:(val) => printer['ip'] = val,
                                                                decoration: InputDecoration(
                                                                  border: OutlineInputBorder(
                                                                    borderRadius: BorderRadius.circular(8),
                                                                    borderSide: BorderSide(
                                                                      color: Colors.grey.shade300,
                                                                    ),
                                                                  ),
                                                                  contentPadding: EdgeInsets.symmetric(
                                                                    horizontal: 10,
                                                                    vertical: 10,
                                                                  ),
                                                                ),
                                                                style: TextStyle(fontSize: 22),
                                                              ),
                                                            ),
                                                          )
                                                              : Center(
                                                            child: Text(
                                                              printer['ip'],
                                                              style: GoogleFonts.inter(
                                                                color: Colors.grey.shade900,
                                                                fontSize: 22,
                                                                fontWeight: FontWeight.w400,
                                                              ),
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
                                                              width: MediaQuery.of(context).size.width * 0.09,
                                                              child: TextFormField(
                                                                initialValue: printer['port'],
                                                                onChanged: (val) => printer['port'] = val,
                                                                decoration: InputDecoration(
                                                                  border: OutlineInputBorder(
                                                                    borderRadius: BorderRadius.circular(8),
                                                                    borderSide: BorderSide(
                                                                      color: Colors.grey.shade300,
                                                                    ),
                                                                  ),
                                                                  contentPadding: EdgeInsets.symmetric(
                                                                    horizontal: 10,
                                                                    vertical: 10,
                                                                  ),
                                                                ),
                                                                style: TextStyle(fontSize: 22),
                                                              ),
                                                            ),
                                                          )
                                                              : Center(
                                                            child: Text(
                                                              printer['port'],
                                                              style: GoogleFonts.inter(
                                                                color: Colors.grey.shade900,
                                                                fontSize: 22,
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
                                                                printer['isEditing'].value
                                                                    ? LucideIcons.save
                                                                    : LucideIcons.pencil,
                                                                size: 30,
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
                                                                  printerController.toggleEdit(index);
                                                                }
                                                              },
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor: Palette.newColorbg,
                                                                minimumSize: const Size(70, 60),
                                                                shape: RoundedRectangleBorder(
                                                                    borderRadius: BorderRadius.circular(10),
                                                                    side: BorderSide(color: Palette.newColor)
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(width: 8),
                                                            IconButton(
                                                              icon: Icon(
                                                                LucideIcons.trash2,
                                                                size: 30,
                                                                color: Colors.white,
                                                              ),
                                                              onPressed: () {
                                                                printerController.deletePrinter(index);
                                                              },
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor: Colors.red,
                                                                minimumSize: const Size(70, 60),
                                                                shape: RoundedRectangleBorder(
                                                                    borderRadius: BorderRadius.circular(10),
                                                                    side: BorderSide(color: Colors.red)
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${printerController.pairedPrinters.length} of 5 row(s) selected.',
                                    style: GoogleFonts.inter(
                                      fontSize: 22,
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
                                            fontSize: 22,
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
                                            fontSize: 22,
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
              const SizedBox(height: 24),
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
                        fontSize: 22,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        printerController.testPrintOnAllPrinters();
                      },
                      icon: Icon(LucideIcons.printer, size: 30),
                      label: Text(
                        'Test Printer',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          color: Colors.indigo.shade500,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showManualAddDialog(BuildContext context) {
    final nameController = TextEditingController();
    final ipController = TextEditingController();
    final portController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        backgroundColor: Colors.white,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.4,
          padding: EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Printer Manually',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Printer Name',
                    labelStyle: GoogleFonts.inter(fontSize: 22),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    errorStyle: TextStyle(fontSize: 20)
                  ),
                  style: GoogleFonts.inter(fontSize: 22),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter printer name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: ipController,
                  decoration: InputDecoration(
                    labelText: 'IP Address',
                    labelStyle: GoogleFonts.inter(fontSize: 22),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    errorStyle: TextStyle(fontSize: 20)
                  ),
                  style: GoogleFonts.inter(fontSize: 22),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter IP address';
                    }
                    if (!RegExp(r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$')
                        .hasMatch(value)) {
                      return 'Enter valid IP address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: portController,
                  decoration: InputDecoration(
                    labelText: 'Port',
                    labelStyle: GoogleFonts.inter(fontSize: 22),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    errorStyle: TextStyle(fontSize: 20)
                  ),
                  style: GoogleFonts.inter(fontSize: 22),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter port number';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Enter valid port number';
                    }
                    final port = int.parse(value);
                    if (port < 1 || port > 65535) {
                      return 'Port must be between 1-65535';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          printerController.addPrinterManually(
                            nameController.text,
                            ipController.text,
                            portController.text,
                          );
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Palette.newColor,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Add Printer',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
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
    ).then((_) {
      nameController.dispose();
      ipController.dispose();
      portController.dispose();
    });
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
            begin: const Offset(1, 0),
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
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scan and add new Bluetooth Thermal Printer',
                        style: GoogleFonts.inter(
                          fontSize: 20,
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
                                minimumSize: const Size(250, 60),
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.grey.shade200,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                "Cancel",
                                style: GoogleFonts.inter(
                                  fontSize: 22,
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
                                minimumSize: const Size(250, 60),
                                backgroundColor: Colors.grey.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                "Pair",
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