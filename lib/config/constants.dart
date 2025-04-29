import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

AuthController authController = AuthController.instance;

var dFontSize = 25;

double baseWidth = 1024;
double fem = MediaQuery.sizeOf(Get.context!).width / baseWidth;
double ffem = fem * 0.97;
