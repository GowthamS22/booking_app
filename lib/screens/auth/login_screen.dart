import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../config/constants.dart';
import '../../controllers/auth_controller.dart';

import '../../config/palette.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthController authController = Get.put(AuthController());
  bool _showPassword = false;
  void _togglevisibility() {
    setState(() {
      _showPassword = !_showPassword;
    });
  }

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: CustomScrollView(slivers: [_buildLoginForm()]));
  }

  SliverToBoxAdapter _buildLoginForm() {
    Widget _loginBtn = Obx(
      () =>
          authController.isLoading == false
              ? ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      authController.isLoading.value = true;
                    });
                    authController.signIn(
                      email: emailController.text,
                      password: passwordController.text,
                    );
                  }
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                    Palette.primaryColor,
                  ),
                  shape: MaterialStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
                child: Text(
                  'Log In',
                  style: GoogleFonts.getFont(
                    'Poppins',
                    fontSize: 15 * ffem,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
              : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: Colors.grey,
                ),
                height: 40,
                width: double.infinity,
                child: Center(
                  child: SizedBox(
                    height: 30,
                    width: 30,
                    child: CircularProgressIndicator(
                      color: Palette.primaryColor,
                    ),
                  ),
                ),
              ),
    );

    return SliverToBoxAdapter(
      child: Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: MediaQuery.of(context).size.width / 2,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bg/intro_bg.png'),
                  fit: BoxFit.fill,
                ),
              ),
              child: Container(
                padding: EdgeInsets.all(100),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'Dropin \nBooking \nSystem',
                    style: GoogleFonts.getFont(
                      'Poppins',
                      fontSize: 30 * ffem,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width / 2,
              height: MediaQuery.of(context).size.height,
              color: Colors.white,
              child: Container(
                padding: EdgeInsets.all(80),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        child: Column(
                          children: [
                            Row(
                              //crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Icon(Icons.account_circle, size: 30 * ffem),
                                SizedBox(width: 30),
                                Text(
                                  'EMAIL',
                                  style: GoogleFonts.getFont(
                                    'Mulish',
                                    fontSize: 15 * ffem,
                                    letterSpacing: 4.0,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.only(left: 70),
                              child: TextFormField(
                                controller: emailController,
                                validator: (value) {
                                  if (!RegExp(
                                    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                                  ).hasMatch(value!)) {
                                    return 'Invalid Email';
                                  } else {
                                    return null;
                                  }
                                },
                                style: GoogleFonts.getFont(
                                  'Mulish',
                                  fontSize: 15 * ffem,
                                ),
                                decoration: InputDecoration(
                                  filled: false,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 17.0,
                                  ),
                                  errorStyle: TextStyle(fontSize: 15 * ffem),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 50),
                      Container(
                        child: Column(
                          children: [
                            Row(
                              //crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Icon(Icons.lock, size: 30 * ffem),
                                SizedBox(width: 30),
                                Text(
                                  'PASSWORD',
                                  style: GoogleFonts.getFont(
                                    'Mulish',
                                    fontSize: 15 * ffem,
                                    letterSpacing: 4.0,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.only(left: 70),
                              child: TextFormField(
                                controller: passwordController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter the password';
                                  }
                                  return null;
                                },
                                obscureText: !_showPassword,
                                style: GoogleFonts.getFont(
                                  'Mulish',
                                  fontSize: 15 * ffem,
                                ),
                                decoration: InputDecoration(
                                  filled: false,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 17.0,
                                  ),
                                  suffixIcon: GestureDetector(
                                    onTap: () {
                                      _togglevisibility();
                                    },
                                    child: Icon(
                                      _showPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.grey,
                                      size: 30,
                                    ),
                                  ),
                                  errorStyle: TextStyle(fontSize: 15 * ffem),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 50),
                      Container(
                        height: 55,
                        width: 150,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Palette.primaryColor.withOpacity(0.3),
                              blurRadius: 20,
                              offset: Offset(0, 10), // Only bottom shadow
                            ),
                          ],
                        ),
                        child: _loginBtn,
                      ),
                      SizedBox(height: 30),
                      /*TextButton(
                        onPressed: () {

                        },
                        child: Text('Forgot Password', style: GoogleFonts.getFont(
                          'Mulish',
                          fontSize: 23,
                          color: Palette.primaryColor,
                          letterSpacing: 3.0,
                        )),
                      )*/
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
