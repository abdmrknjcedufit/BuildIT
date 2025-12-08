import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:buildit_mobile/app_colors.dart';

class StripePaymentPopup extends StatefulWidget {
  final String checkoutUrl;
  final String sessionId;
  final Function(String sessionId) onSuccess;
  final Function() onCancel;
  final Function(String error) onError;

  const StripePaymentPopup({
    super.key,
    required this.checkoutUrl,
    required this.sessionId,
    required this.onSuccess,
    required this.onCancel,
    required this.onError,
  });

  @override
  State<StripePaymentPopup> createState() => _StripePaymentPopupState();
}

class _StripePaymentPopupState extends State<StripePaymentPopup> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('🔵 WebView: Page started loading: $url');
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            print('✅ WebView: Page finished loading: $url');
            setState(() {
              _isLoading = false;
            });
            
            // Proveri da li je URL success ili cancel
            _checkPaymentStatus(url);
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ WebView: Error loading page: ${error.description}');
            widget.onError('Greška pri učitavanju Stripe stranice: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            print('🔵 WebView: Navigation request: ${request.url}');
            
            // Proveri da li je ovo success ili cancel URL
            if (request.url.contains('payment-success') || 
                request.url.contains('success') ||
                request.url.contains('checkout/success')) {
              _handlePaymentSuccess();
              return NavigationDecision.prevent;
            }
            
            if (request.url.contains('payment-cancel') || 
                request.url.contains('cancel') ||
                request.url.contains('checkout/cancel')) {
              _handlePaymentCancel();
              return NavigationDecision.prevent;
            }
            
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  void _checkPaymentStatus(String url) {
    // Proveri URL za success/cancel indikatore
    if (url.contains('payment-success') || 
        url.contains('success') ||
        url.contains('checkout/success')) {
      _handlePaymentSuccess();
    } else if (url.contains('payment-cancel') || 
               url.contains('cancel') ||
               url.contains('checkout/cancel')) {
      _handlePaymentCancel();
    }
  }

  void _handlePaymentSuccess() {
    print('✅ StripePaymentPopup: Payment success detected');
    Navigator.of(context).pop();
    widget.onSuccess(widget.sessionId);
  }

  void _handlePaymentCancel() {
    print('⚠️ StripePaymentPopup: Payment cancelled');
    Navigator.of(context).pop();
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Header sa naslovom i zatvaranjem
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.primaryOrange,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Stripe Plaćanje',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      _handlePaymentCancel();
                    },
                  ),
                ],
              ),
            ),
            // WebView
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryOrange,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

