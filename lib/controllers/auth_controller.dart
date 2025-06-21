import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/palette.dart';

class AuthController extends GetxController {
  final supabase = Supabase.instance.client;
  static AuthController instance = Get.find();
  var centerName = ''.obs;
  var centerSlug = ''.obs;
  var emailID = ''.obs;
  var logoURL = ''.obs;
  var pin = ''.obs;
  var userId = ''.obs;
  var userName = ''.obs;
  var staffID = ''.obs;
  var gst = ''.obs;

  var openCloseId;
  var openCloseDate;
  var openCloseStaffId;
  var openCloseStaffName;
  var openCloseAmount;

  RxBool isLoading = false.obs;
  RxBool startLoading = false.obs;
  RxBool pinLoading = false.obs;

  FirebaseAuth _auth = FirebaseAuth.instance;

  void signIn({String? email, String? password}) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    try {
      await _auth.signInWithEmailAndPassword(
        email: email.toString(),
        password: password.toString(),
      );

      centerName = RxString(_auth.currentUser!.displayName.toString());
      centerSlug = RxString('shop_1');
      emailID.value = _auth.currentUser!.email.toString();

      DocumentSnapshot profileSnap =
          await FirebaseFirestore.instance
              .collection(centerSlug.toString())
              .doc('admins')
              .get();

      logoURL.value = profileSnap['imageUrl'] ?? '';
      gst.value = profileSnap['gst'];

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
      if (e.message!.contains(
        'The password is invalid or the user does not have a password',
      )) {
        showCustomSnackbar(
          'Failed',
          'The password entered is incorrect',
          Colors.red,
        );
      } else if (e.message!.contains(
        'There is no user record corresponding to this identifier. The user may have been deleted',
      )) {
        showCustomSnackbar(
          'Failed',
          'The email id and password is incorrect',
          Colors.red,
        );
      } else if (e.message!.contains('The email address is badly formatted')) {
        showCustomSnackbar(
          'Failed',
          'The email id format is incorrect',
          Colors.red,
        );
      } else {
        showCustomSnackbar('Failed', 'Something went wrong!!', Colors.red);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pinLogin({required String memberPin}) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? centerSlug                  = 's22'; //preferences.getString('centerSlug');
    try {

      final userResponse = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('users')
          .select('*')
          .eq('pin', memberPin)
          .single();

      final storeResponse = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('store_details')
          .select('*')
          .eq('shortcode', centerSlug.toString())
          .single();

      final categoryResponse = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('categories')
          .select('*')
          .eq('status', true);

      final productsResponse = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('products')
          .select('*');

      final paymentDeviceResponse = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('payment_devices')
          .select('*')
          .single();

      final sportsWithPlatformResponse = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('sports')
          .select('*, platform_status(*)')
          .eq('status', true);

      await preferences.setString('categories', jsonEncode(categoryResponse));
      await preferences.setString('products', jsonEncode(productsResponse));
      await preferences.setString('storeDetails', jsonEncode(storeResponse));
      await preferences.setString('paymentDevices', jsonEncode(paymentDeviceResponse));
      await preferences.setString('sportsWithPlatforms', jsonEncode(sportsWithPlatformResponse));

      if (userResponse != null) {
        emailID.value = userResponse['email'];
        final String password = userResponse['password'];
        pin.value = userResponse['pin'];
        // userId.value = userResponse['id'];
        userName.value = userResponse['name'];
        staffID.value = userResponse['user_no'];
        final authResponse = await supabase.auth.signInWithPassword(
          email: emailID.value,
          password: password,
        );

        if (authResponse.user != null) {
          userId.value = authResponse.user!.id;
          await preferences.setString('pin', pin.toString());
          await preferences.setString('userId', userId.toString());
          await preferences.setString('userName', userName.toString());
          await preferences.setString('staffID', staffID.toString());
          await preferences.setString('emailID', emailID.toString());
          await preferences.setString('centerSlug', 's22');

          // // 4️⃣ Check for openCloseCash with status == true
          final openCloseResponse = await supabase
                  .schema('s22_prod_schema')
                  .from('open_close_cash')
                  .select('*')
                  .eq('status', 'Current')
                  .limit(1)
                  .maybeSingle();

          if (openCloseResponse != null) {
            openCloseId = openCloseResponse['id'];
            print('openCloseId: $openCloseId');
            // final openCloseDate = DateTime.parse(openCloseResponse['date']);
            // final openCloseStaffId = openCloseResponse['openStaffId'];
            // final openCloseStaffName = openCloseResponse['openStaffName'];
            // final openCloseAmount =
            //     (openCloseResponse['openingAmount'] as num).toDouble();

            await preferences.setString('openCloseId', openCloseId);
          }

          // ✅ Login successful
          showCustomSnackbar('Success', 'Login Successful', Colors.green);
          Get.offAllNamed('/');
        } else {
          showCustomSnackbar(
            'Failed',
            'Authentication failed. Invalid email/password.',
            Colors.red,
          );
        }
      } else {
        showCustomSnackbar('Failed', 'Invalid PIN entered.', Colors.red);
      }
    } catch (e) {
      showCustomSnackbar('Failed', e.toString(), Colors.red);
    } finally {
      pinLoading.value = false;
      isLoading.value = false;
    }
  }

  void logOut() async {
    try {
      //centerName = RxString('');
      //emailID    = RxString('');
      //logoURL    = RxString('');
      pin = RxString('');
      openCloseId = '';
      openCloseDate = '';
      openCloseStaffId = '';
      openCloseStaffName = '';
      openCloseAmount = '';

      SharedPreferences preferences = await SharedPreferences.getInstance();
      //await preferences.remove('centerName');
      //await preferences.remove('emailID');
      //await preferences.remove('logoUrl');
      await preferences.remove('pin');
      await preferences.remove('openCloseId');

      //Status Alert
      showCustomSnackbar(
        'Success',
        'You have successfully logged out!',
        Colors.orange,
      );

      Get.offAllNamed('/');
    } catch (e) {
      Get.snackbar(
        'Sign out unsuccessful!',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        colorText: Palette.white,
        backgroundColor: Palette.primaryColor,
      );
    }
  }

  Future<bool> validateOpenCashStatus() async {
    final response = await supabase
        .schema('s22_prod_schema')
        .from('open_close_cash')
        .select()
        .eq('status', 'Current');

    final data = response as List;

    if (data.isNotEmpty) {
      return false;
    } else {
      return true;
    }
  }

  Future<void> addOpenCash({double? openingAmount}) async {
    final preferences = await SharedPreferences.getInstance();
    // final now = DateTime.now();

    try {
      // Insert into Supabase
      final insertResponse =
          await supabase
              .schema('s22_prod_schema')
              .from('open_close_cash')
              .insert({
                //'date': now.toIso8601String(),
                'opening_balance': openingAmount,
                'user_id': userId.toString(),
                'status': "Current",
              })
              .select()
              .single();

      if (insertResponse != null) {
        final data = insertResponse;

        openCloseId = data['id'];
        // openCloseDate = DateTime.parse(data['date']);
        // openCloseStaffId = data['open_staff_id'];
        // openCloseStaffName = data['open_staff_name'];
        // openCloseAmount = (data['opening_amount'] as num).toDouble();

        await preferences.setString('openCloseId', openCloseId.toString());

        showCustomSnackbar(
          'Success',
          'Opening Cash Saved Successfully',
          Colors.green,
        );

        Get.offAllNamed('/');
      }
    } catch (e) {
      showCustomSnackbar('Failed', e.toString(), Colors.red);
    } finally {
      startLoading.value = false;
    }
  }

}
