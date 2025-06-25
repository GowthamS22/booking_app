import 'package:booking_app/config/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toastification/toastification.dart';

class Palette {
  static const Color primaryColor = Color(0xFF2C83F1);
  static const Color secondaryColor = Color(0xFF73b0fd);
  //static const Color primaryColor = Color(0xFFF57C00);
  //static const Color secondaryColor = Colors.orangeAccent;

  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color mediumGrey = Color(0xFFBDBDBD);
  static const Color darkGrey = Color(0xFF616161);
  static const Color tabBarUnselectedColor = Color(0xFF637185);
  static const Color tabBarSelectedColor = Color(0xff2c83f1);

  static const Color blueGrey = Color(0xFFECEFF1);

  static const Color black = Colors.black;
  static const Color drawerBlack = Colors.black54;
  static const Color white = Colors.white;

  static const Color chartBg = Color(0xff232d37);
  static const Color rowHeadingbg = Color(0xFFE7EDF5);
  static const Color rowDatabg = Color(0xFFF8F8F8);

  static const Color fieldBg = Color(0xFFE7EDF5);

  static const Color successBg = Color(0xFFF4FFF2);
  static const Color successTxt = Color(0xFF2AC67B);
  static const Color dangerBg = Color(0xFFFFF2F2);
  static const Color dangerTxt = Color.fromARGB(255, 37, 32, 32);
  static const Color bookedColor = Color(0xFF1c304a);

  static const Color payColors = Color(0xFF2AC67B);
  static const Color payColorsLight = Color(0xFF78c6a0);
  static const Color newColor = Color(0xFF6366F1);
  static const Color newColorbg = Color(0xFFEEF2FF);
}

Color textPrimary = Color(0xFF111111);
Color textSecondary = Color(0xFF3A3cd3);

void showCustomSnackbar(String title, String message, Color color) {
  toastification.show(
    type: ToastificationType.success,
    style: ToastificationStyle.flatColored,
    autoCloseDuration: const Duration(seconds: 2),
    title: Text('${title}', style: TextStyle(fontSize: 22, color: Colors.black87)),
    description: RichText(text: TextSpan(text: '${message}', style: TextStyle(fontSize: 20, color: Colors.black87))),
    alignment: Alignment.topRight,
    direction: TextDirection.ltr,
    animationDuration: const Duration(milliseconds: 300),
    animationBuilder: (context, animation, alignment, child) {
      return FadeTransition(
        opacity: AlwaysStoppedAnimation(10),
        child: child,
      );
    },
    icon: const Icon(Icons.check, size: 40, color: Colors.black87,),
    showIcon: true, // show or hide the icon
    primaryColor: color,
    backgroundColor: color,
    foregroundColor: color,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    borderRadius: BorderRadius.circular(12),
    boxShadow: const [
      BoxShadow(
        color: Color(0x07000000),
        blurRadius: 16,
        offset: Offset(0, 16),
        spreadRadius: 0,
      )
    ],
    showProgressBar: true,
    progressBarTheme: ProgressIndicatorThemeData(color: Colors.black26),
    closeButton: ToastCloseButton(
      showType: CloseButtonShowType.onHover,
      buttonBuilder: (context, onClose) {
        return OutlinedButton.icon(
          onPressed: onClose,
          icon: const Icon(Icons.close, size: 20),
          label: const Text('Close'),
        );
      },
    ),
    closeOnClick: false,
    pauseOnHover: true,
    dragToClose: true,
    applyBlurEffect: false,
  );
  // Get.snackbar(
  //   '',
  //   '',
  //   titleText: Text(
  //     '${title}',
  //     style: TextStyle(color: Colors.white, fontSize: 15 * ffem),
  //   ),
  //   messageText: Text(
  //     '${message}',
  //     style: TextStyle(color: Colors.white, fontSize: 15 * ffem),
  //   ),
  //   snackPosition: SnackPosition.TOP,
  //   backgroundColor: color, // Customize the background color
  //   colorText: Colors.white, // Customize the text color
  //   duration: Duration(seconds: 1), // Customize the duration
  //   borderRadius: 20, // Customize the border radius
  //   margin: EdgeInsets.only(top: 100), // Customize the margin
  //   maxWidth: 500, // Set the maximum width of the Snackbar
  // );
}
