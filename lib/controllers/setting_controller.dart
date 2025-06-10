import 'dart:io';
import 'package:get/get.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PrinterController extends GetxController {
  static PrinterController instance = Get.find();
  final supabase = Supabase.instance.client;
  final isScanning = false.obs;
  final availablePrinters = <Map<String, String>>[].obs;
  final pairedPrinters = <Map<String, dynamic>>[].obs;
  // final RxList<PrinterModel> pairedPrinters =
  //     <PrinterModel>[
  //       PrinterModel(
  //         ip: '192.168.1.10',
  //         port: '9100',
  //         name: 'Kitchen Printer',
  //         isEditing: false,
  //       ),
  //       PrinterModel(
  //         ip: '192.168.1.11',
  //         port: '9100',
  //         name: 'Billing Printer',
  //         isEditing: false,
  //       ),
  //     ].obs;
  final selectedPrinter = Rxn<Map<String, String>>();

  Future<void> scanForPrinters() async {
    final info = NetworkInfo();
    String? localIp = await info.getWifiIP();

    if (localIp == null) {
      Get.snackbar('Error', 'Failed to get local IP. Connect to Wi-Fi.');
      return;
    }

    final subnet = localIp.substring(0, localIp.lastIndexOf('.'));
    availablePrinters.clear();
    isScanning.value = true;

    List<Future<void>> tasks = [];

    for (int i = 1; i <= 254; i++) {
      final ip = '$subnet.$i';
      tasks.add(_checkPrinter(ip, 9100));
    }

    await Future.wait(tasks);
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

  void confirmPairSelectedPrinter() {
    if (selectedPrinter.value != null) {
      pairPrinter(selectedPrinter.value!);
      selectedPrinter.value = null;
    }
  }

  void pairPrinter(Map<String, String> printer) {
    pairedPrinters.add(
      {
        'name': printer['name']!,
        'ip': printer['ip']!,
        'port': printer['port']!,
        'isEditing': false.obs,
      },
      // PrinterModel(
      //   name: printer['name']!,
      //   ip: printer['ip']!,
      //   port: printer['port']!,
      //   isEditing: false,
      // ),
    );
    updateSupabasePrinters();
  }

  void toggleEdit(int index) {
    pairedPrinters[index]['isEditing'].value =
        !pairedPrinters[index]['isEditing'].value;
  }

  void deletePrinter(int index) {
    pairedPrinters.removeAt(index);
    updateSupabasePrinters();
  }

  void savePrinter(int index, String ip, String port) {
    pairedPrinters[index]['ip'] = ip;
    pairedPrinters[index]['port'] = port;
    pairedPrinters[index]['isEditing'].value = false;
    updateSupabasePrinters();
  }

  Future<void> updateSupabasePrinters() async {
    final List<Map<String, dynamic>> printersJson = pairedPrinters.toList();
    await supabase
        .schema('s22_prod_schema')
        .from('store_details')
        .update({'printer': printersJson})
        .eq('user_id', 'b2f48a45-741c-46b8-b71d-e092c344ca49');
  }
}
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../config/constants.dart';

// class SettingController extends GetxController {
//   static SettingController instance = Get.find();
//   RxList<PrinterModal> printerList = RxList([]);

//   @override
//   void onInit() {
//     // TODO: implement onInit
//     printerList.bindStream(getPrinters());
//     super.onInit();
//   }

//   Stream<List<PrinterModal>> getPrinters() {
//     printerList.clear();

//     return FirebaseFirestore.instance
//         .collection('shop_1')
//         .doc('settings')
//         .collection('printers')
//         .snapshots()
//         .map((QuerySnapshot query) {
//           List<PrinterModal> val = [];
//           // print('checking the category name inside the query $categoryName');
//           query.docs.forEach((element) {
//             val.add(PrinterModal.fromDocumentSnapshot(element));
//           });

//           return val;
//         });
//   }

//   void savingSettingsPrinter(String printerIP, int portNumber) {
//     FirebaseFirestore.instance
//         .collection(authController.centerSlug.toString())
//         .doc('settings')
//         .collection('printers')
//         .add({
//           'printerDetails': {'printerIP': printerIP, 'printerPort': portNumber},
//         });
//   }
// }
