import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class TyroPaymentService {
  static Future<Map<String, dynamic>> processPayment({
    required BuildContext context,
    required double amount,
    required String reference,
    required String apiKey,
    required String merchantId,
    required String terminalId,
    required String integrationKey,
    required String posProductVendor,
    required String posProductName,
    required String posProductVersion,
  }) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => TyroPaymentScreen(
          amount: amount,
          reference: reference,
          apiKey: apiKey,
          merchantId: merchantId,
          terminalId: terminalId,
          integrationKey: integrationKey,
          posProductVendor: posProductVendor,
          posProductName: posProductName,
          posProductVersion: posProductVersion,
        ),
      ),
    );

    return result ?? {'status': 'cancelled', 'message': 'Payment cancelled'};
  }
}

class TyroPaymentScreen extends StatefulWidget {
  final double amount;
  final String reference;
  final String apiKey;
  final String merchantId;
  final String terminalId;
  final String integrationKey;
  final String posProductVendor;
  final String posProductName;
  final String posProductVersion;

  const TyroPaymentScreen({
    required this.amount,
    required this.reference,
    required this.apiKey,
    required this.merchantId,
    required this.terminalId,
    required this.integrationKey,
    required this.posProductVendor,
    required this.posProductName,
    required this.posProductVersion,
    Key? key,
  }) : super(key: key);

  @override
  State<TyroPaymentScreen> createState() => _TyroPaymentScreenState();
}

class _TyroPaymentScreenState extends State<TyroPaymentScreen> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EFTPOS Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop({
            'status': 'cancelled',
            'message': 'Payment cancelled by user'
          }),
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialData: InAppWebViewInitialData(
              data: _generateHtmlContent(),
              baseUrl: WebUri("https://yourdomain.com/"),
              encoding: 'utf-8',
              mimeType: 'text/html',
            ),
            initialOptions: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(
                javaScriptEnabled: true,
                useShouldOverrideUrlLoading: true,
                mediaPlaybackRequiresUserGesture: false,
              ),
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;

              // Optional: Handle receipt callback from JS here
              controller.addJavaScriptHandler(
                handlerName: 'merchantReceipt',
                callback: (args) {
                  final merchantReceipt = args.isNotEmpty ? args[0] : null;
                  print('Merchant Receipt: $merchantReceipt');
                  // You can store/show the receipt here
                  return null;
                },
              );
            },
            onLoadStop: (controller, url) async {
              setState(() {
                _isLoading = false;
              });
            },
            onLoadError: (controller, url, code, message) {
              setState(() {
                _isLoading = false;
              });
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              print('response navigation action ${navigationAction.request}');
              final uri = navigationAction.request.url;
              if (uri != null) {
                if (uri.toString().contains('payment-success')) {
                  // Get transaction details from the webview
                  final transactionDetails = await controller.evaluateJavascript(
                    source: "window.transactionResponse || null",
                  );

                  Navigator.of(context).pop({
                    'status': 'success',
                    'reference': widget.reference,
                    'amount': widget.amount,
                    'transactionId': transactionDetails['response']['transactionId'],
                    'timestamp': DateTime.now().toIso8601String(),
                    'payment_response': transactionDetails['response'],
                    // Add any other relevant details
                  });
                  return NavigationActionPolicy.CANCEL;
                } else if (uri.toString().contains('payment-failed')) {
                  Navigator.of(context).pop({
                    'status': 'failed',
                    'message': uri.queryParameters['error'] ?? 'Payment failed',
                    'reference': widget.reference,
                    'amount': widget.amount,
                  });
                  return NavigationActionPolicy.CANCEL;
                }
              }
              return NavigationActionPolicy.ALLOW;
            },
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  String _generateHtmlContent() {
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <script src="https://iclientsimulator.test.tyro.com/iclient-with-ui-v1.js"></script>
        <style>
          body { font-family: Arial, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background: #f5f5f5; }
          .loader { border: 5px solid #f3f3f3; border-top: 5px solid #3498db; border-radius: 50%; width: 50px; height: 50px; animation: spin 2s linear infinite; }
          @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
        </style>
      </head>
      <body>
        <div id="loader" class="loader"></div>
        <script>
          document.addEventListener('DOMContentLoaded', function() {
            const posProductInfo = {
              posProductVendor: '${widget.posProductVendor}',
              posProductName: '${widget.posProductName}',
              posProductVersion: '${widget.posProductVersion}'
            };
            
            const iclient = new TYRO.IClientWithUI('${widget.apiKey}', posProductInfo);
            
            iclient.initiatePurchase(
              {
                amount: '10000',
                cashout: '0',
                integratedReceipt: true,
                mid: '${widget.merchantId}',
                tid: '${widget.terminalId}',
                integrationKey: '${widget.integrationKey}',
              },
              {
                receiptCallback: (receipt) => {
                  window.flutter_inappwebview.callHandler('merchantReceipt', receipt.merchantReceipt);
                },
                transactionCompleteCallback: (response) => {
                  if(response.result=='APPROVED') {
                    window.transactionResponse = {
                      ...window.transactionResponse,
                      status: 'success',
                      message: response.message,
                      response: response
                    };
                    window.location.href = 'https://yourdomain.com/payment-success?ref=${widget.reference}';
                  } else {
                    window.location.href = 'https://yourdomain.com/payment-failed?error=' +  encodeURIComponent(response.message || 'Payment failed');
                  }
                },
                errorCallback: (error) => {
                  window.location.href = 'https://yourdomain.com/payment-failed?error=' +  encodeURIComponent(error.message || 'Payment error');
                }
              }
            );
          });
        </script>
      </body>
      </html>
    ''';
  }
}
