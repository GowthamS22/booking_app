import 'dart:io';
import 'package:booking_app/config/palette.dart';
import 'package:booking_app/models/booking_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:intl/intl.dart';

class PrinterController extends GetxController {

  static PrinterController get instance => Get.find();

  final supabase          = Supabase.instance.client;
  final isScanning        = false.obs;
  final availablePrinters = <Map<String, String>>[].obs;
  final pairedPrinters    = <Map<String, dynamic>>[].obs;
  final selectedPrinter   = Rxn<Map<String, String>>();

  @override
  void onInit() {
    super.onInit();
    loadPrintersFromSupabase();
  }

  Future<void> loadPrintersFromSupabase() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? centerSlug = prefs.getString('centerSlug');

    final response = await supabase
        .schema('${centerSlug}_prod_schema')
        .from('store_details')
        .select('printer')
        .eq('shortcode', centerSlug.toString())
        .single();
print(response);
    if (response['printer'] != null) {
      pairedPrinters.assignAll((response['printer'] as List).map((printer) {
        return {
          'name': printer['name'],
          'ip': printer['ip'],
          'port': printer['port'],
          'isEditing': false.obs,
        };
      }).toList());
    }
    update();
  }

  Future<void> scanForPrinters() async {
    final info = NetworkInfo();
    String? localIp = await info.getWifiIP();

    if (localIp == null) {
      Get.snackbar('Error', 'Failed to get local IP. Connect to Wi-Fi.');
      return;
    }

    // Extract subnet (e.g., 192.168.1.x)
    final subnet = localIp.substring(0, localIp.lastIndexOf('.'));
    availablePrinters.clear();
    isScanning.value = true;

    Get.snackbar('Progress', 'Scanning for printers on network...');

    // Use Future.wait to run multiple checks in parallel
    List<Future<void>> futures = [];
    for (int i = 1; i <= 254; i++) {
      final ip = '$subnet.$i';
      futures.add(_checkPrinter(ip, 9100)); // Check on standard printer port 9100
    }

    // Wait for all futures to complete
    await Future.wait(futures);

    if (availablePrinters.isEmpty) {
      Get.snackbar('Warning', 'No printers found on the network.');
    }

    print(availablePrinters);

    isScanning.value = false;
  }

  Future<String?> _getHostName(String ip) async {
    try {
      final result = await InternetAddress(ip).reverse();
      return result.host;
    } catch (e) {
      print("e : $e");
      return null;
    }
  }

  Future<void> _checkPrinter(String ip, int port) async {
    try {
      final socket = await Socket.connect(
        ip,
        port,
        timeout: Duration(milliseconds: 300),
      );
      socket.destroy();
      final hostName = await _getHostName(ip);
      availablePrinters.add({
        'name': hostName ?? 'Printer @ $ip',
        'ip': ip,
        'port': port.toString(),
      });
    } catch (_) {}
  }

  void selectPrinter(Map<String, String> printer) {
    selectedPrinter.value = printer;
  }

  void confirmPairSelectedPrinter(BuildContext context) {
    print(selectedPrinter.value);
    if (selectedPrinter.value != null) {
      pairPrinter(selectedPrinter.value!);
      selectedPrinter.value = null;
      Navigator.pop(context); // 👈 Close the drawer here
    } else {
      Get.snackbar('Warning', 'Please select the Printer');
    }
  }

  void pairPrinter(Map<String, String> printer) {
    pairedPrinters.add({
        'name': printer['name']!,
        'ip': printer['ip']!,
        'port': printer['port']!,
        'isEditing': false.obs,
    },);
    update();
  }

  void toggleEdit(int index) {
    pairedPrinters[index]['isEditing'].value =
        !pairedPrinters[index]['isEditing'].value;
  }

  void deletePrinter(int index) {
    pairedPrinters.removeAt(index);
    update();
  }

  void savePrinter(int index, String ip, String port) {
    pairedPrinters[index]['ip'] = ip;
    pairedPrinters[index]['port'] = port;
    pairedPrinters[index]['isEditing'].value = false;
    //updateSupabasePrinters();
  }

  Future<void> updateSupabasePrinters() async {
    SharedPreferences prefs                       = await SharedPreferences.getInstance();
    String? centerSlug                            = prefs.getString('centerSlug');

    // Convert RxBool to bool
    final List<Map<String, dynamic>> printersJson = pairedPrinters.map((printer) {
      return {
        'name': printer['name'],
        'ip': printer['ip'],
        'port': printer['port'],
        'isEditing': (printer['isEditing'] as RxBool).value,
      };
    }).toList();
    final response = await supabase
        .schema('${centerSlug}_prod_schema')
        .from('store_details')
        .update({
          'printer': printersJson
        })
        .eq('shortcode', centerSlug.toString())
        .select('printer')
        .single();
    showCustomSnackbar('Success', 'Printers Updated Successfully', Colors.green);
    update(); // Add this to ensure UI updates after DB update
  }

  Future<void> testPrintOnAllPrinters() async {
    if (pairedPrinters.isEmpty) {
      Get.snackbar('Warning', 'No printers are paired');
      return;
    }
    for (var printer in pairedPrinters) {
      try {
        await _printTestReceipt(
          printerIp: printer['ip'],
          printerPort: int.parse(printer['port']),
          printerName: printer['name'],
        );
        Get.snackbar('Success', 'Test sent to ${printer['name']}');
      } catch (e) {
        Get.snackbar('Error', 'Failed to print on ${printer['name']}: $e');
      }
    }
  }

  Future<void> _printTestReceipt({
    required String printerIp,
    required int printerPort,
    required String printerName,
  }) async {

    final Map<String, dynamic> data  = {
      'restaurant': {
        'firstName': 'Sample Sports Club',
        'address': '123 Test St, Test City',
        'phoneNumber': '123-456-7890',
        'website': 'www.test.com',
        'abn_no': '123456789',
      },
      'token_number': '001',
      'cart': {
        'cart': [
          {
            'name': '11:30 AM to 12:30 AM',
            'quantity': 1,
            'price': 10.00,
            'appliedPrice': 20.00,
            'discount': 10,
          },
          {
            'name': 'Badminton Racket',
            'quantity': 2,
            'price': 15.00,
            'appliedPrice': 15.00,
          },
          {
            'name': 'Shuttle Cocks',
            'quantity': 1,
            'price': 15.00,
            'appliedPrice': 15.00,
          },
        ],
      },
      'bill': {
        'discount': 5.00,
        'price': 35.00,
        'taxes': 3.50,
        'surcharge': 0.00,
        'tab_value': 'EFTPOS',
        'bill_amount': 33.50,
        'paid_amount': 40.00,
        'balance_amount': 6.50,
      },
    };

    try {
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(PaperSize.mm80, profile);
      final PosPrintResult res = await printer.connect(printerIp, port: printerPort);

      if (res == PosPrintResult.success) {
        final orderDate = DateFormat('dd/MM/yyyy hh:mm:ss a').format(DateTime.now());

        printer.setStyles(PosStyles(align: PosAlign.center, bold: true));
        //printer.text('Tax Invoice / Receipt \n', styles: PosStyles(align: PosAlign.center,width: PosTextSize.size2,height: PosTextSize.size2));
        printer.setStyles(PosStyles(align: PosAlign.center));
        printer.text('${data['restaurant']['firstName']} \n', styles: PosStyles(align: PosAlign.center,width: PosTextSize.size2,height: PosTextSize.size2));
        printer.text('${data['restaurant']['address']}', styles: PosStyles(align: PosAlign.center));
        printer.text('PH: ${data['restaurant']['phoneNumber']}', styles: PosStyles(align: PosAlign.center));
        printer.text('WEBSITE: ${data['restaurant']['website']}', styles: PosStyles(align: PosAlign.center));
        printer.text('ABN: ${data['restaurant']['abn_no']}', styles: PosStyles(align: PosAlign.center));
        printer.text('Date: $orderDate \n', styles: PosStyles(align: PosAlign.center));
        printer.text('Order No: #${data['token_number']}', styles: PosStyles(align: PosAlign.center,width: PosTextSize.size2,height: PosTextSize.size2));
        printer.text('--------------------------------------------');

        // Header for table
        printer.setStyles(PosStyles(align: PosAlign.left, bold: true));
        printer.text('Item                    Qty    Price   Total');
        printer.setStyles(PosStyles(align: PosAlign.left));
        printer.text('--------------------------------------------');

        // Print each item in table format
        for (var item in data['cart']['cart']) {
          final itemName      = item['name'].padRight(20);
          final itemQuantity  = item['quantity'].toString().padLeft(4);
          final itemPrice     = ('\$${item['price'].toStringAsFixed(2)}').padLeft(7);
          final itemTotal     = ('\$${item['appliedPrice'].toStringAsFixed(2)}').padLeft(8);

          printer.text('$itemName $itemQuantity $itemPrice $itemTotal');

          if (item['options'] != null) {
            for (var option in item['options']) {
              final optionText  = ' - ${option['name']}';
              final optionPrice = option['price'].toStringAsFixed(2);
              //printer.text('$optionText $optionPrice');
              _printAlignedText(printer, optionText, '\$${optionPrice}');
            }
          }

          if (item['discount'] != null && item['discount'] > 0) {
            final itemDiscount = (item['price'] + (item['options']?.fold(0.0, (prev, opt) => prev + opt['price']) ?? 0.0) - item['appliedPrice']).toStringAsFixed(2);
            //printer.text(' - Discount ${item['discount']}% $itemDiscount');
            _printAlignedText(printer, ' - Discount ${item['discount']}%', '\$${itemDiscount}');
          }
        }

        printer.text('--------------------------------------------');

        if (data['bill']['discount'] > 0) {
          _printAlignedText(printer, 'Discount:', '\$${data['bill']['discount'].toStringAsFixed(2)}');
        }
        _printAlignedText(printer, 'Sub-Total:', '\$${data['bill']['price'].toStringAsFixed(2)}');
        _printAlignedText(printer, 'GST Incl.:', '\$${data['bill']['taxes'].toStringAsFixed(2)}');
        if (data['bill']['surcharge'] > 0) {
          _printAlignedText(printer, 'Surcharge:', '\$${data['bill']['surcharge'].toStringAsFixed(2)}');
        }
        _printAlignedText(printer, 'Payment Method:', '${data['bill']['tab_value']}');
        _printAlignedText(printer, 'Total Amount:', '\$${data['bill']['bill_amount'].toStringAsFixed(2)}');
        _printAlignedText(printer, 'Paid Amount:', '\$${data['bill']['paid_amount'].toStringAsFixed(2)}');
        _printAlignedText(printer, 'Balance Amount:', '\$${data['bill']['balance_amount'].abs().toStringAsFixed(2)}');

        printer.text('--------------------------------------------');
        printer.text('THANK YOU! HAVE A NICE DAY!', styles: PosStyles(align: PosAlign.center));
        printer.cut();
        if(data['bill']['tab_value']=='CASH') {
          printer.drawer(pin: PosDrawer.pin2);
        }
        printer.disconnect();

      } else {
        print('Failed to connect to the printer');
      }
    } catch (e) {
      print('Error during printing: $e');
    }

  }

  void _printAlignedText(NetworkPrinter printer, String leftText, String rightText) {
    final totalWidth = 42;
    final leftWidth  = leftText.length;
    final rightWidth = rightText.length;
    final spaceWidth = totalWidth - leftWidth - rightWidth;

    final alignedText = '$leftText${' ' * spaceWidth}$rightText';
    printer.text(alignedText);
  }

  Future<void> printBookingReceipt({
    required List<BookingSlot>? bookingSlotItems,
    required String printerIp,
    required int printerPort,
    required String printerName,
  }) async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data            = prefs.getString('storeDetails');

    try {
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(PaperSize.mm80, profile);
      final PosPrintResult res = await printer.connect(printerIp, port: printerPort);
      if (res == PosPrintResult.success) {

        final orderDate = DateFormat('dd/MM/yyyy hh:mm:ss a').format(DateTime.now());

        printer.setStyles(PosStyles(align: PosAlign.center, bold: true));
        //printer.text('Tax Invoice / Receipt \n', styles: PosStyles(align: PosAlign.center,width: PosTextSize.size2,height: PosTextSize.size2));
        // printer.setStyles(PosStyles(align: PosAlign.center));
        // printer.text('${data['name']} \n', styles: PosStyles(align: PosAlign.center,width: PosTextSize.size2,height: PosTextSize.size2));
        // printer.text('${data['address']}', styles: PosStyles(align: PosAlign.center));
        // printer.text('PH: ${data['mobile']}', styles: PosStyles(align: PosAlign.center));
        // printer.text('WEBSITE: ${data['restaurant']['website']}', styles: PosStyles(align: PosAlign.center));
        // printer.text('ABN: ${data['abn']}', styles: PosStyles(align: PosAlign.center));
        // printer.text('Booking Date: $orderDate \n', styles: PosStyles(align: PosAlign.center));
        // printer.text('Booking ID: #${data['token_number']}', styles: PosStyles(align: PosAlign.center,width: PosTextSize.size2,height: PosTextSize.size2));
        // printer.text('--------------------------------------------');
        //
        // // Header for table
        // printer.setStyles(PosStyles(align: PosAlign.left, bold: true));
        // printer.text('Item                    Qty    Price   Total');
        // printer.setStyles(PosStyles(align: PosAlign.left));
        // printer.text('--------------------------------------------');
        //
        // // Print each item in table format
        // for (var item in data['cart']['cart']) {
        //   final itemName      = item['name'].padRight(20);
        //   final itemQuantity  = item['quantity'].toString().padLeft(4);
        //   final itemPrice     = ('\$${item['price'].toStringAsFixed(2)}').padLeft(7);
        //   final itemTotal     = ('\$${item['appliedPrice'].toStringAsFixed(2)}').padLeft(8);
        //
        //   printer.text('$itemName $itemQuantity $itemPrice $itemTotal');
        //
        //   if (item['options'] != null) {
        //     for (var option in item['options']) {
        //       final optionText  = ' - ${option['name']}';
        //       final optionPrice = option['price'].toStringAsFixed(2);
        //       //printer.text('$optionText $optionPrice');
        //       _printAlignedText(printer, optionText, '\$${optionPrice}');
        //     }
        //   }
        //
        //   if (item['discount'] != null && item['discount'] > 0) {
        //     final itemDiscount = (item['price'] + (item['options']?.fold(0.0, (prev, opt) => prev + opt['price']) ?? 0.0) - item['appliedPrice']).toStringAsFixed(2);
        //     //printer.text(' - Discount ${item['discount']}% $itemDiscount');
        //     _printAlignedText(printer, ' - Discount ${item['discount']}%', '\$${itemDiscount}');
        //   }
        // }
        //
        // printer.text('--------------------------------------------');
        //
        // if (data['bill']['discount'] > 0) {
        //   _printAlignedText(printer, 'Discount:', '\$${data['bill']['discount'].toStringAsFixed(2)}');
        // }
        // _printAlignedText(printer, 'Sub-Total:', '\$${data['bill']['price'].toStringAsFixed(2)}');
        // _printAlignedText(printer, 'GST Incl.:', '\$${data['bill']['taxes'].toStringAsFixed(2)}');
        // if (data['bill']['surcharge'] > 0) {
        //   _printAlignedText(printer, 'Surcharge:', '\$${data['bill']['surcharge'].toStringAsFixed(2)}');
        // }
        // _printAlignedText(printer, 'Payment Method:', '${data['bill']['tab_value']}');
        // _printAlignedText(printer, 'Total Amount:', '\$${data['bill']['bill_amount'].toStringAsFixed(2)}');
        // _printAlignedText(printer, 'Paid Amount:', '\$${data['bill']['paid_amount'].toStringAsFixed(2)}');
        // _printAlignedText(printer, 'Balance Amount:', '\$${data['bill']['balance_amount'].abs().toStringAsFixed(2)}');

        printer.text('--------------------------------------------');
        printer.text('THANK YOU! HAVE A NICE DAY!', styles: PosStyles(align: PosAlign.center));
        printer.cut();
        // if(data['bill']['tab_value']=='CASH') {
        //   printer.drawer(pin: PosDrawer.pin2);
        // }
        printer.disconnect();

      } else {
        print('Failed to connect to the printer');
      }
    } catch (e) {
      print('Error during printing: $e');
    }

  }

}
