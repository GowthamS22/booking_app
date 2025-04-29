import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
class PrinterModal {
  String? printerIP;
  int? printerPort;

  PrinterModal({
   this.printerIP,this.printerPort,
  });

  factory PrinterModal.fromDocumentSnapshot(DocumentSnapshot data){

    print('showing the printer data ${data['printerDetails']['printerIP']}');
    return
      PrinterModal(
        printerIP: data['printerDetails']['printerIP'],
        printerPort: data['printerDetails']['printerPort'],
      );
  }

}