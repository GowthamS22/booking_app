import 'package:booking_app/config/palette.dart';
import 'package:booking_app/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:get/get.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: OnboardingSlider(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class OnboardingSlider extends StatefulWidget {
  @override
  _OnboardingSliderState createState() => _OnboardingSliderState();
}

class _OnboardingSliderState extends State<OnboardingSlider> {
  final PageController _controller = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView(
            controller: _controller,
            children: [
              OnboardingPage(
                controller: _controller,
                imagePath: 'assets/images/slider/db_os_01.png',
                title: 'Book Your Court in Seconds',
                subtitle: 'Say goodbye to calls and chaos. Just tap\nand play — it\'s that simple.',
                buttonText: 'Next',
                isLastPage: false,
              ),
              OnboardingPage(
                controller: _controller,
                imagePath: 'assets/images/slider/db_os_03.png',
                title: 'Buy Gear, Book Games',
                subtitle: 'Get your sports essentials and instantly\nbook a court — all in one smooth flow.',
                buttonText: 'Next',
                isLastPage: false,
              ),
              OnboardingPage(
                controller: _controller,
                imagePath: 'assets/images/slider/db_os_02.png',
                title: 'Smart Scheduling for\nMembers',
                subtitle: 'Set your match time, stay consistent — no\nmore last-minute rushes.',
                buttonText: 'Start Booking !!',
                isLastPage: false,
              ),
              OnboardingPage(
                controller: _controller,
                imagePath: 'assets/images/slider/db_os_04.png',
                title: '',
                subtitle: '',
                buttonText: '',
                isLastPage: true,
              ),
            ],
          ),
          Positioned(
            bottom: 30,
            child: SmoothPageIndicator(
              controller: _controller,
              count: 4,
              effect: WormEffect(
                dotColor: Colors.grey.shade500,
                activeDotColor: Colors.white,
                dotHeight: 8,
                dotWidth: 8,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class OnboardingPage extends StatefulWidget {
  final PageController controller;
  final String imagePath;
  final String title;
  final String subtitle;
  final String buttonText;
  final bool isLastPage;

  const OnboardingPage({
    required this.controller,
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.isLastPage,
  });

  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  bool showScanner = false;

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? qrController;
  final AuthController authController = Get.put(AuthController());

  bool showManualInput = false;
  final TextEditingController manualInputController = TextEditingController();

  // Called when QR code is detected
  void _onQRViewCreated(QRViewController controller) {
    qrController = controller;
    controller.scannedDataStream.listen((scanData) async {
      final scannedCode = scanData.code;

      if (scannedCode != null && scannedCode.isNotEmpty) {
        print('QR Code Scanned: $scannedCode');

        // Pause the camera
        controller.pauseCamera();

        // Store centerSlug in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('centerSlug', scannedCode.toString());

        // Hide the scanner UI
        setState(() {
          showScanner = false;
          authController.centerSlug.value = scannedCode.toString();
        });

        Get.offAllNamed('/');

        // Optional: Navigate to next screen or show a confirmation
        // Navigator.push(...);
      }
    });
  }

  @override
  void dispose() {
    qrController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Image
        Align(
          alignment: widget.isLastPage ? Alignment.centerLeft : Alignment.center,
          child: Image.asset(
            widget.imagePath,
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
        ),

        // Black overlay for all pages
        Container(
          height: double.infinity,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: widget.isLastPage
                ? LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.black,
              ],
              stops: [0.5, 1.0],
            )
                : LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                Colors.black,
              ],
              stops: [0.5, 1.0],
            ),
          ),
        ),

        // Logo for the last page
        if (widget.isLastPage)
          Positioned(
            top: 60,
            left: 60,
            child: Image.asset(
              'assets/images/dropin_logo.png',
              fit: BoxFit.cover,
              height: 90,
              width: 250,
            ),
          ),

        // Content Positioned to the right
        Align(
          alignment: showScanner ? Alignment.center : Alignment.centerRight,
          child: Container(
            width: MediaQuery.of(context).size.width * (showScanner ? 0.50 : 0.32),
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isLastPage) ...[
                  if (!showScanner) ...[

                    if (showManualInput) ...[

                      SizedBox(height: 20),
                      Container(
                        width: 300,
                        child: TextField(
                          controller: manualInputController,
                          style: TextStyle(color: Colors.white, fontSize: 25),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white10,
                            hintText: 'Enter client id',
                            hintStyle: TextStyle(color: Colors.white70, fontSize: 25),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.white38),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        width: 300,
                        child: ElevatedButton(
                          onPressed: () async {
                            final manualValue = manualInputController.text.trim();
                            if (manualValue.isNotEmpty) {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('centerSlug', manualValue);
                              authController.centerSlug.value = manualValue;

                              setState(() {
                                showManualInput = false;
                                showScanner = false;
                              });

                              Get.offAllNamed('/');

                              // Optional: Navigate to next screen or show a success message
                            } else {
                              showCustomSnackbar('Error', 'Please enter a valid client id', Colors.redAccent);
                            }
                          },
                          child: Text(
                            'Submit',
                            style: TextStyle(color: Colors.white, fontSize: 22),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Palette.newColor,
                            minimumSize: const Size(250, 44),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Palette.newColor),
                            ),
                          ),
                        ),
                      ),

                    ] else ...[

                      Text('Scan QR code to login',
                        style: TextStyle(
                            fontSize: 25,
                            color: Colors.white,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        width: 250,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              showScanner = true;
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.qrCode, color: Colors.white, size: 30),
                              SizedBox(width: 15),
                              Text(
                                'Scan Now',
                                style: TextStyle(color: Colors.white, fontSize: 22),
                              )
                            ],
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Palette.newColor,
                            minimumSize: const Size(250, 44),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Palette.newColor),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        width: 250,
                        child: Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.white38,
                                thickness: 2,
                                indent: 20,
                                endIndent: 10,
                              ),
                            ),
                            Text(
                              'or',
                              style: TextStyle(color: Colors.white70, fontSize: 25),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.white38,
                                thickness: 2,
                                indent: 10,
                                endIndent: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        width: 250,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              showManualInput = true;
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.user, color: Colors.white, size: 30),
                              SizedBox(width: 15),
                              Text(
                                'Enter Manually',
                                style: TextStyle(color: Colors.white, fontSize: 22),
                              )
                            ],
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Palette.newColor,
                            minimumSize: const Size(250, 44),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Palette.newColor),
                            ),
                          ),
                        ),
                      ),

                    ]

                  ] else ...[

                    // QR Scanner Container
                    Container(
                      width: MediaQuery.of(context).size.width * 0.85, // Use 85% of screen width
                      height: MediaQuery.of(context).size.height * 0.75,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            'Scan QR code to login',
                            style: TextStyle(color: Colors.white, fontSize: 25),
                          ),
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(left: 40, top: 20, bottom: 40, right: 40),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              // Placeholder child – replace with your QR widget
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: QRView(
                                  key: qrKey,
                                  onQRViewCreated: _onQRViewCreated,
                                  overlay: QrScannerOverlayShape(
                                    borderColor: Colors.white,
                                    borderRadius: 10,
                                    borderLength: 30,
                                    borderWidth: 10,
                                    overlayColor: Colors.white10,
                                    cutOutSize: MediaQuery.of(context).size.width * 0.6,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )

                  ],
                ] else ...[
                  Text(widget.title, style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Text(widget.subtitle, style: TextStyle(fontSize: 22, color: Colors.white70)),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (widget.isLastPage) {
                        // Navigate to the next screen (e.g., home screen)
                        // Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen()));
                      } else {
                        // Go to the next page
                        widget.controller.nextPage(
                          duration: Duration(milliseconds: 500),
                          curve: Curves.ease,
                        );
                      }
                    },
                    child: Text(
                      widget.buttonText,
                      style: TextStyle(color: Colors.white, fontSize: 22),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.newColor,
                      minimumSize: const Size(250, 44),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Palette.newColor),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        )
      ],
    );
  }
}