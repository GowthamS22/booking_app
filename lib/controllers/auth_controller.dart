import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/palette.dart';

class AuthController extends GetxController {

  static AuthController instance = Get.find();
  var centerName      = ''.obs;
  var centerSlug      = ''.obs;
  var emailID         = ''.obs;
  var logoURL         = ''.obs;
  var pin             = ''.obs;
  var userId          = ''.obs;
  var userName        = ''.obs;
  var staffID         = ''.obs;
  var gst             = ''.obs;

  var openCloseId;
  var openCloseDate;
  var openCloseStaffId;
  var openCloseStaffName;
  var openCloseAmount;

  RxBool isLoading    = false.obs;
  RxBool startLoading = false.obs;
  RxBool pinLoading   = false.obs;

  FirebaseAuth _auth = FirebaseAuth.instance;

  void signIn({String? email, String? password}) async {

    SharedPreferences preferences = await SharedPreferences.getInstance();

    try {

      await _auth.signInWithEmailAndPassword(email: email.toString(), password: password.toString());

      centerName            = RxString(_auth.currentUser!.displayName.toString());
      centerSlug            = RxString('shop_1');
      emailID.value         = _auth.currentUser!.email.toString();

      DocumentSnapshot profileSnap = await FirebaseFirestore.instance
          .collection(centerSlug.toString())
          .doc('admins')
          .get();

      logoURL.value      = profileSnap['imageUrl'] ?? '';
      gst.value          = profileSnap['gst'];

      preferences.setString('centerName', centerName.toString());
      preferences.setString('centerSlug', centerSlug.toString());
      preferences.setString('emailID', emailID.toString());
      preferences.setString('logoURL', logoURL.toString());
      preferences.setString('gst', gst.toString());

      //Status Alert
      showCustomSnackbar('Success', 'Login Successful', Colors.green);

      //Redirect to Home
      Get.offAllNamed('/');

    } on FirebaseAuthException catch (e) {

      if(e.message!.contains('The password is invalid or the user does not have a password')) {
        showCustomSnackbar('Failed', 'The password entered is incorrect', Colors.red);
      } else if(e.message!.contains('There is no user record corresponding to this identifier. The user may have been deleted')) {
        showCustomSnackbar('Failed', 'The email id and password is incorrect', Colors.red);
      } else if(e.message!.contains('The email address is badly formatted')) {
        showCustomSnackbar('Failed', 'The email id format is incorrect', Colors.red);
      } else {
        showCustomSnackbar('Failed', 'Something went wrong!!', Colors.red);
      }

    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pinLogin({String? memberPin}) async {

    SharedPreferences preferences = await SharedPreferences.getInstance();

    try {

      final QuerySnapshot staffSnapshot = await FirebaseFirestore.instance
          .collection(centerSlug.toString())
          .doc('staff_details')
          .collection('staff')
          .where('pin',isEqualTo: memberPin.toString())
          .get();
      if(staffSnapshot.docs.isNotEmpty) {

        pin.value             = '${staffSnapshot.docs[0]['pin']}';
        userId.value          = '${staffSnapshot.docs[0].id}';
        userName.value        = '${staffSnapshot.docs[0]['firstName']} ${staffSnapshot.docs[0]['lastName']}';
        staffID.value         = '${staffSnapshot.docs[0]['staffID']}';
        emailID.value         = '${staffSnapshot.docs[0]['email']}';

        preferences.setString('pin', pin.toString());
        preferences.setString('userId', userId.toString());
        preferences.setString('userName', userName.toString());
        preferences.setString('staffID', staffID.toString());
        preferences.setString('emailID', emailID.toString());

        DateTime now = DateTime.now();
        QuerySnapshot openCloseCashSnapshot = await FirebaseFirestore.instance
            .collection(centerSlug.toString())
            .doc('openCloseCash')
            .collection('records')
            //.where('date',isEqualTo: DateTime(now.year,now.month,now.day))
            .where('status',isEqualTo: true)
            .get();
        if(openCloseCashSnapshot.docs.isNotEmpty) {
          Map<String, dynamic> data = openCloseCashSnapshot.docs[0].data() as Map<String, dynamic>;

          openCloseId         = openCloseCashSnapshot.docs[0].id;
          openCloseDate       = data['date'].toDate();
          openCloseStaffId    = data['openStaffId'];
          openCloseStaffName  = data['openStaffName'];
          openCloseAmount     = data['openingAmount'].toDouble();

          preferences.setString('openCloseId', openCloseCashSnapshot.docs[0].id.toString());

        }

        //Status Alert
        showCustomSnackbar('Success', 'Login Successful', Colors.green);

        //Redirect to Home
        Get.offAllNamed('/');

      } else {
        //Status Alert
        showCustomSnackbar('Failed', 'Invalid login credentials!', Colors.red);
      }

    } catch (e) {

      //Status Alert
      showCustomSnackbar('Failed', '${e.toString()}', Colors.red);

    } finally {
      pinLoading.value = false;
      isLoading.value  = false;
    }
  }

  void logOut() async {
    try {

      //centerName = RxString('');
      //emailID    = RxString('');
      //logoURL    = RxString('');
      pin                 = RxString('');
      openCloseId         = '';
      openCloseDate       = '';
      openCloseStaffId    = '';
      openCloseStaffName  = '';
      openCloseAmount     = '';

      SharedPreferences preferences = await SharedPreferences.getInstance();
      //await preferences.remove('centerName');
      //await preferences.remove('emailID');
      //await preferences.remove('logoUrl');
      await preferences.remove('pin');
      await preferences.remove('openCloseId');

      //Status Alert
      showCustomSnackbar('Success', 'You have successfully logged out!', Colors.orange);

      Get.offAllNamed('/');

    } catch (e) {
      Get.snackbar('Sign out unsuccessful!', e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          colorText: Palette.white,
          backgroundColor: Palette.primaryColor);
    }
  }

  Future<bool> validateOpenCashStatus() async {
    DateTime now = DateTime.now();
    QuerySnapshot openCloseCashSnapshot = await FirebaseFirestore.instance
        .collection(centerSlug.toString())
        .doc('openCloseCash')
        .collection('records')
        //.where('date',isEqualTo: DateTime(now.year,now.month,now.day))
        .where('status',isEqualTo: true)
        .get();

    if(openCloseCashSnapshot.docs.isNotEmpty) {
      return false;
    } else {
      return true;
    }
  }

  Future<void> addOpenCash({double? openingAmount,}) async {
    try {

      SharedPreferences preferences = await SharedPreferences.getInstance();

      DateTime now = DateTime.now();
      var docRef = FirebaseFirestore.instance
          .collection(centerSlug.toString())
          .doc('openCloseCash')
          .collection('records')
          .doc();

      await docRef.set({
        'date': DateTime.now(), // Use the obtained bookingId
        'openingAmount': openingAmount,
        'openDateTime': DateTime.now(),
        'openStaffId': userId.toString(),
        'openStaffName': userName.toString(),
        'status': true,
      }).then((value) {

        docRef.get().then((docSnapshot) {
          if (docSnapshot.exists) {
            Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
            // Process the retrieved data as needed
            openCloseId         = docRef.id;
            openCloseDate       = data['date'].toDate();
            openCloseStaffId    = data['openStaffId'];
            openCloseStaffName  = data['openStaffName'];
            openCloseAmount     = data['openingAmount'].toDouble();

            preferences.setString('openCloseId', docRef.id.toString());

            //Status Alert
            showCustomSnackbar('Success', 'Opening Cash Saved Successfully', Colors.green);

            //Redirect to Home
            Get.offAllNamed('/');

          }
        }).catchError((error) {
          print('Error retrieving document: $error');
        });

      },);

    } catch (e) {
      showCustomSnackbar('Failed', '${e.toString()}', Colors.red);
    } finally {
      //Redirect to Home
      Get.offAllNamed('/');
      startLoading.value=false;
    }
  }

}