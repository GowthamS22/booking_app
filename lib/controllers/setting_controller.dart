import 'package:badminton_app/models/printer_modals.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';

class SettingController extends GetxController {

  static SettingController instance = Get.find();
  RxList<PrinterModal> printerList = RxList([]);


  @override
  void onInit() {
    // TODO: implement onInit
    printerList.bindStream(getPrinters());
    super.onInit();
  }


  Stream<List<PrinterModal>> getPrinters(){
    printerList.clear();

    return
      FirebaseFirestore.instance
          .collection('shop_1')
          .doc('settings')
          .collection('printers').snapshots().map((QuerySnapshot query) {
        List<PrinterModal> val = [];
        // print('checking the category name inside the query $categoryName');
        query.docs.forEach((element) {
          val.add(PrinterModal.fromDocumentSnapshot(element));
        });



        return val;
      });
  }

  void savingSettingsPrinter(String printerIP,int portNumber){

    FirebaseFirestore.instance
        .collection(authController.centerSlug.toString())
        .doc('settings')
        .collection('printers')
        .add({
      'printerDetails':{
        'printerIP':printerIP,
        'printerPort':portNumber,
      }
    });


  }



}