import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:intl/intl.dart';

import '../app/getx_binding.dart';
import '../config/constants.dart';
import '../config/palette.dart';

class ReportController extends GetxController {

  RxBool closeBtnLoading  = false.obs;

  List openCloseCash = [];
  var cashSales      = 0.0;
  var cardSales      = 0.0;
  var accountSales   = 0.0;
  var onlineSales    = 0.0;
  var membershipSales= 0.0;

  TextEditingController quantityController      = TextEditingController();
  TextEditingController reasonForCashController = TextEditingController();
  TextEditingController reasonForCardController = TextEditingController();
  var notesType         = ['100','50','20','10','5',].obs;
  var notesQuantity     = ['0','0','0','0','0',].obs;
  var coinsType         = ['2','1'].obs;
  var coinsQuantity     = ['0','0'].obs;
  var centsType         = ['50','20','10','5'].obs;
  var centsQuantity     = ['0','0','0','0'].obs;
  var textBorderColor   = Palette.primaryColor.obs;
  var types             = [].obs;
  var typeIndex         = 0.obs;

  void onInit() {
    fetchOpenCash();
    super.onInit();
  }

  void editQuantity(List type,int index,String value){
    type[index] = value;
  }

  Future<void> fetchOpenCash() async {
    try {

      DateTime now = DateTime.now();
      DocumentSnapshot openCloseCashSnapshot = await FirebaseFirestore.instance
          .collection(authController.centerSlug.toString())
          .doc('openCloseCash')
          .collection('records')
          .doc(authController.openCloseId.toString())
          .get();

      if(openCloseCashSnapshot.exists) {
        Map<String, dynamic> data = openCloseCashSnapshot.data() as Map<String, dynamic>;
        openCloseCash.add({
          'openCloseId': authController.openCloseId.toString(),
          'openCloseDate': data['date'].toDate(),
          'openCloseDateTime': data['openDateTime'].toDate(),
          'openCloseStaffId': data['openStaffId'],
          'openCloseStaffName': data['openStaffName'],
          'openCloseAmount': data['openingAmount'].toDouble()
        });

        DateTime openDate   = data['date'].toDate();
        DateTime filterDate = DateTime(openDate.year,openDate.month,openDate.day,openDate.hour,openDate.minute,openDate.second);

        //Cash Sales List
        QuerySnapshot cashSalesSnapshot = await FirebaseFirestore.instance
            .collection(authController.centerSlug.toString())
            .doc('bookingPayments')
            .collection('bookingPayment')
            .where('date',isGreaterThanOrEqualTo: filterDate)
            .where('paymentType',isEqualTo: 'Cash')
            .where('paymentVia',isEqualTo: 'APP')
            .get();

        double cashTotalSum = cashSalesSnapshot.docs
            .map((doc) => (doc.get('total') ?? 0.0) as double)
            .fold(0.0, (previousValue, element) => previousValue + element);
        cashSales = cashTotalSum;


        //Card Sales List
        QuerySnapshot cardSalesSnapshot = await FirebaseFirestore.instance
            .collection(authController.centerSlug.toString())
            .doc('bookingPayments')
            .collection('bookingPayment')
            .where('date',isGreaterThanOrEqualTo: filterDate)
            .where('paymentType',isEqualTo: 'Credit Card')
            .where('paymentVia',isEqualTo: 'APP')
            .get();

        double cardTotalSum = cardSalesSnapshot.docs
            .map((doc) => (doc.get('total') ?? 0.0) as double)
            .fold(0.0, (previousValue, element) => previousValue + element);
        cardSales = cardTotalSum;


        //Account Sales List
        QuerySnapshot accountSalesSnapshot = await FirebaseFirestore.instance
            .collection(authController.centerSlug.toString())
            .doc('bookingPayments')
            .collection('bookingPayment')
            .where('date',isGreaterThanOrEqualTo: filterDate)
            .where('paymentType',isEqualTo: 'Account')
            .where('paymentVia',isEqualTo: 'APP')
            .get();

        double accountTotalSum = accountSalesSnapshot.docs
            .map((doc) => (doc.get('total') ?? 0.0) as double)
            .fold(0.0, (previousValue, element) => previousValue + element);
        accountSales = accountTotalSum;


        //Online Sales List
        QuerySnapshot onlineSalesSnapshot = await FirebaseFirestore.instance
            .collection(authController.centerSlug.toString())
            .doc('bookingPayments')
            .collection('bookingPayment')
            .where('date',isGreaterThanOrEqualTo: filterDate)
            .where('paymentType',isEqualTo: 'Credit Card')
            .where('paymentVia',isEqualTo: 'ONLINE')
            .get();

        double onlineTotalSum = onlineSalesSnapshot.docs
            .map((doc) => (doc.get('total') ?? 0.0) as double)
            .fold(0.0, (previousValue, element) => previousValue + element);
        onlineSales = onlineTotalSum;

        //Membership Sales List
        QuerySnapshot membershipSalesSnapshot = await FirebaseFirestore.instance
            .collection(authController.centerSlug.toString())
            .doc('membershipPayments')
            .collection('membershipPayment')
            .where('createdAt',isGreaterThanOrEqualTo: filterDate)
            .where('status',isEqualTo: true)
            .get();

        double membershipTotalSum = membershipSalesSnapshot.docs
            .map((doc) => (doc.get('total') ?? 0.0) as double)
            .fold(0.0, (previousValue, element) => previousValue + element);
        membershipSales = membershipTotalSum;

        //

      }

    } catch (e) {

    } finally {
      update();
    }
  }

  double calculatingCash(){
    var subTotalNotes = 0.0;
    var subTotalCoins = 0.0;
    var subTotalCents = 0.0;
    for(var i = 0; i< notesType.length; i++){
      subTotalNotes += double.parse(notesType[i]) * double.parse(notesQuantity[i]);
    }
    for(var i = 0; i< coinsType.length; i++){
      subTotalCoins += double.parse(coinsType[i]) * double.parse(coinsQuantity[i]);
    }
    for(var i = 0; i< centsType.length; i++){
      subTotalCents += (double.parse(centsType[i]) * double.parse(centsQuantity[i]))/100;
    }
    return subTotalNotes + subTotalCoins + subTotalCents;
  }

  double calculatingSubtotal(){
    return calculatingCash() + cardSales + onlineSales + accountSales + membershipSales + cashSales;
  }

  double calculatingTotal(){
    var total = calculatingSubtotal() + openCloseCash[0]['openCloseAmount'];
    return total;
  }

  void printReceipt({
    double? floatCash,
    double? cashBooking,
    double? cardBooking,
    double? onlineBooking,
    double? subTotal,
    double? gst,
    double? total,
  }) async {

    final profile       = await CapabilityProfile.load();
    final printer       = NetworkPrinter(PaperSize.mm80, profile);
    var storeName       = 'My Store';
    var storeAddress    = '123 Main Street, City';
    var storeMobile     = 'Phone: 123-456-7890';
    var imageUrl        = '';
    var abn             = '';
    var email           = '@email.com';

    var dateAndTime     =  DateFormat('yMd').format(DateTime.now());
    dynamic currentTime = DateFormat('hh:mm:ss').format(DateTime.now());

    DocumentReference docRef = FirebaseFirestore.instance
        .collection(authController.centerSlug.toString())
        .doc('admins');

    await docRef.get().then((value) {
      storeName     = value.get('name');
      storeAddress  = value.get('address');
      storeMobile   = 'Phone : ${value.get('phone')}';
      imageUrl      = value.get('imageUrl');
      email         = value.get('email');
      abn           = 'ABN : ${value.get('abn')}';
    });




    for(var printerIPs in settingController.printerList) {

      print('checking the IP Address ${printerIPs.printerIP}');

      final printerIp = '${printerIPs.printerIP}';
      final PosPrintResult res = await printer.connect(printerIp, port: printerIPs.printerPort!);
      if (res != PosPrintResult.success) {
        shoppingController.productsCartModal.clear();
        showCustomSnackbar('Printer Error', 'Failed to connect to the printer.', Colors.red);
        return;
      }

      //current date
      printer.row([
        PosColumn(
          text: '${dateAndTime}',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '',
          width: 6,
          styles: PosStyles(align: PosAlign.center, underline: false,
          ),
        ),
        PosColumn(
          text: '${currentTime}',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
      ]);
      printer.feed(1);

      // Print header with store information
      printer.row([
        PosColumn(
          text: '',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '$storeName',
          width: 6,
          styles: PosStyles(align: PosAlign.center, underline: false,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
        ),
        PosColumn(
          text: '',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
      ]);
      printer.feed(1);

      printer.row([
        PosColumn(
          text: '',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '$storeAddress',
          width: 6,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
      ]);

      printer.row([
        PosColumn(
          text: '',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '$abn',
          width: 6,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
      ]);
      printer.row([
        PosColumn(
          text: '',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '$storeMobile',
          width: 6,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
      ]);

      printer.feed(1);
      printer.hr();

      printer.row([
        PosColumn(
          text: 'Report',
          width: 6,
          styles: PosStyles(align: PosAlign.center, underline: false,),
        ),
      ]);

      printer.feed(1);

      printer.row([
        PosColumn(
          text: 'Date : ${DateFormat('dd-MMM-yy hh:mm a').format(DateTime.now())}',
          width: 9,
          styles: PosStyles(align: PosAlign.center, underline: false),
        )
      ]);
      printer.row([
        PosColumn(
          text: 'Cashier : ${authController.userName.toString()}',
          width: 9,
          styles: PosStyles(align: PosAlign.center, underline: false),
        )
      ]);

      printer.feed(1);
      printer.hr();

      printer.row([
        PosColumn(
          text: 'CLOSE CASH REPORT',
          width: 6,
          styles: PosStyles(align: PosAlign.center, underline: false,),
        ),
      ]);

      // Float
      printer.row([
        PosColumn(
          text: 'FLOAT',
          width: 6,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(openCloseCash[0]['openCloseAmount'])}',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
      ]);

      printer.feed(1);

      // Cash Sales
      printer.row([
        PosColumn(
          text: 'CASH SALES',
          width: 6,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(cashSales.toString())}',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
      ]);

      printer.feed(1);

      // Card Sales
      printer.row([
        PosColumn(
          text: 'CARD SALES',
          width: 6,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(cardSales.toString())}',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
      ]);

      printer.feed(1);

      // Online Sales
      printer.row([
        PosColumn(
          text: 'ONLINE SALES',
          width: 6,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(onlineSales.toString())}',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
      ]);

      printer.feed(1);

      // Membership Sales
      printer.row([
        PosColumn(
          text: 'MEMBERSHIP',
          width: 6,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(membershipSales.toString())}',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
      ]);

      printer.feed(1);

      // Sub Total
      printer.row([
        PosColumn(
          text: 'SUB TOTAL',
          width: 6,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(calculatingSubtotal())}',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
      ]);

      printer.feed(1);

      // GST
      printer.row([
        PosColumn(
          text: 'GST',
          width: 6,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '\$0.0',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
      ]);

      printer.feed(1);

      // Total
      printer.row([
        PosColumn(
          text: 'SUB TOTAL',
          width: 6,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: '${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(calculatingTotal())}',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
      ]);

      printer.feed(1);

      printer.hr();

      // static text
      printer.row([
        PosColumn(
          text: '',
          width: 1,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
        PosColumn(
          text: 'Thank You!',
          width: 10,
          styles: PosStyles(align: PosAlign.center, underline: false,
            height: PosTextSize.size2,
            width: PosTextSize.size1,
          ),
        ),
        PosColumn(
          text: '',
          width: 1,
          styles: PosStyles(align: PosAlign.center, underline: false),
        ),
      ]);

      printer.cut();
      printer.disconnect();
      printer.drawer();

      showCustomSnackbar('Print Successful', 'The receipt has been printed successfully.', Colors.green);

    }














    // printer.text('$storeName\n$storeAddress\n$storeMobile\n', styles: PosStyles(align: PosAlign.center));

    // Print logo (if available)
    // Replace 'logo.png' with your actual logo file path
    // final ByteData data = await rootBundle.load('assets/logo.png');
    // final Uint8List logoBytes = data.buffer.asUint8List();
    // printer.image(logoBytes);












    // printer.text(total, styles: PosStyles(align: PosAlign.right));



  }

  Future<void> closeCash({
    String? hundredNotes,
    String? fiftyNotes,
    String? twentyNotes,
    String? tenNotes,
    String? fiveNotes,
    String? twoCoins,
    String? oneCoins,
    String? fiftyCents,
    String? twentyCents,
    String? tenCents,
    String? fiveCents,
    double? total,
    bool? isForceClosed
  }) async {
    try {

      //Update Record Status
      await FirebaseFirestore.instance
          .collection(authController.centerSlug.toString())
          .doc('openCloseCash')
          .collection('records')
          .doc(openCloseCash[0]['openCloseId'].toString())
          .update({
        'status': false,
      },).then((value) async {

        DateTime now = DateTime.now();
        var docRef = FirebaseFirestore.instance
            .collection(authController.centerSlug.toString())
            .doc('openCloseCash')
            .collection('completedRecords')
            .doc();

        await docRef.set({
          'actualAmount': double.parse(openCloseCash[0]['openCloseAmount'].toString()),
          'closeAmount': total,
          'closeDateTime': now,
          'date': openCloseCash[0]['openCloseDate'],
          'isForceClosed': isForceClosed,
          'openingAmount': double.parse(openCloseCash[0]['openCloseAmount'].toString()),
          'openDateTime': openCloseCash[0]['openCloseDateTime'],
          'openStaffId': openCloseCash[0]['openCloseStaffId'],
          'openStaffName': openCloseCash[0]['openCloseStaffName'],
          'CloseCash': {
            'hundredNotes': hundredNotes,
            'fiftyNotes': fiftyNotes,
            'twentyNotes': twentyNotes,
            'tenNotes': tenNotes,
            'fiveNotes': fiveNotes,
            'twoCoins': twoCoins,
            'oneCoins': oneCoins,
            'fiftyCents': fiftyCents,
            'twentyCents': twentyCents,
            'tenCents': tenCents,
            'fiveCents': fiveCents,
            'subTotal': calculatingSubtotal(),
            'float': double.parse(openCloseCash[0]['openCloseAmount'].toString()),
            'total': calculatingTotal(),
            'cashBooking': double.parse(cashSales.toString()),
            'cardBooking': double.parse(cardSales.toString()),
            'accountBooking': double.parse(accountSales.toString()),
            'onlineBooking': double.parse(onlineSales.toString()),
            'membershipAmount': double.parse(membershipSales.toString()),
            'reasonForCash': reasonForCashController.text.toString(),
            'reasonForCard': reasonForCardController.text.toString()
          }
        }).then((value) {
          //Logout User
          authController.logOut();

        },);

      },);

    } catch (e) {

    } finally {
      closeBtnLoading.value=false;
    }
  }


}