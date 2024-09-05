import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum PrivacyPolicyPageStatus { loading, noInternet, error }

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

    await _controller.setNavigationDelegate(NavigationDelegate(onUrlChange: (change) {
      if (change.url == null || Uri.tryParse(change.url!)?.scheme != 'sdk') return;

      final result = Uri.parse(change.url!).pathSegments.last == 'accept';
      Navigator.of(context).pop(result);
    }));
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
