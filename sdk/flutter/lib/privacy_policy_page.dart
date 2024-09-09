import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PrivacyPolicyPage extends StatefulWidget {
  final Uri url;
  const PrivacyPolicyPage({required this.url, super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  final WebViewController _controller = WebViewController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _controller.loadRequest(widget.url);
    await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);

    await _controller.setNavigationDelegate(NavigationDelegate(
      onNavigationRequest: (request) {
        final uri = Uri.tryParse(request.url);
        if (uri == null || uri.scheme != 'sdk') return NavigationDecision.navigate;

        final result = uri.pathSegments.last == 'accept';
        Navigator.of(context).pop(result);
        return NavigationDecision.prevent;
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: true,
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
