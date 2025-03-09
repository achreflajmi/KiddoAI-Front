//webview_activity_widget.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewActivityWidget extends StatefulWidget {
  final String activityUrl;

  const WebViewActivityWidget({super.key, required this.activityUrl});

  @override
  State<WebViewActivityWidget> createState() => _WebViewActivityWidgetState();
}

class _WebViewActivityWidgetState extends State<WebViewActivityWidget> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)  // important for some weird cases where WebView has a white/black background overriding content
      ..loadRequest(Uri.parse(widget.activityUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Game Activity',
          style: TextStyle(
            fontFamily: 'Inter Tight',
            color: Colors.white,
            fontSize: 22.0,
          ),
        ),
        elevation: 2.0,
      ),
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
