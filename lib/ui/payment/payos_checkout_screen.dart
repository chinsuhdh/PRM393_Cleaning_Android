import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _payosReturnPathSuffix = '/api/Payments/payos-return';

bool isPayosReturnUrl(String url) => Uri.tryParse(url)?.path.endsWith(_payosReturnPathSuffix) ?? false;

class PayosCheckoutScreen extends StatefulWidget {
  final String paymentUrl;
  const PayosCheckoutScreen({super.key, required this.paymentUrl});

  @override
  State<PayosCheckoutScreen> createState() => _PayosCheckoutScreenState();
}

class _PayosCheckoutScreenState extends State<PayosCheckoutScreen> {
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
            if (isPayosReturnUrl(request.url)) {
              Navigator.of(context).pop(true);
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
        title: const Text('Thanh toán payOS', style: TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(false),
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
