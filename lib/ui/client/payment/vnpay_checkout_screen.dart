import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _vnpayReturnPathSuffix = '/api/Payments/vnpay-return';

bool isVnpayReturnUrl(String url) => Uri.tryParse(url)?.path.endsWith(_vnpayReturnPathSuffix) ?? false;

class VnpayCheckoutScreen extends StatefulWidget {
  final String paymentUrl;
  const VnpayCheckoutScreen({super.key, required this.paymentUrl});

  @override
  State<VnpayCheckoutScreen> createState() => _VnpayCheckoutScreenState();
}

class _VnpayCheckoutScreenState extends State<VnpayCheckoutScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onNavigationRequest: (request) {
            if (isVnpayReturnUrl(request.url)) {
              Navigator.of(context).pop(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán VNPay', style: TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
