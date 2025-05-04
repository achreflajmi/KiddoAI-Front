import 'dart:convert';
import 'dart:ffi'; 
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart'; 
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../widgets/saving_animation_widget.dart';



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
      ..setBackgroundColor(Colors.transparent)
      ..loadRequest(Uri.parse(widget.activityUrl))
      ..addJavaScriptChannel(
        'ReactNativeWebView',
        onMessageReceived: (JavaScriptMessage message) async {
          try {
            final data = message.message;
            final Map<String, dynamic> result = jsonDecode(data);
            final int score = result['score'] ?? 0;
            final double accuracy = (result['accuracy'] as num?)?.toDouble() ?? 0.0;

            // TODO: Update score and accuracy in the database
            print("Score: $score, Accuracy: $accuracy");
        //    final response = await http.post(
        //   Uri.parse(CurrentIP +":8083/KiddoAI/Activity/updateActivityLesson"),//172.20.10.13
        //   headers: {"Content-Type": "application/json"},
        //   body: jsonEncode({"accuracy": accuracy}), 
        // );
       // final react_run = await http.get(Uri.parse(ngrokUrl +"/closeActivity"));


            if (mounted) {// &&  react_run.statusCode == 200) {//response.statusCode == 200 &&
             
               // Show fullscreen loading animation dialog
                showGeneralDialog(
                  context: context,
                  barrierDismissible: false,
                  barrierColor: Colors.black.withOpacity(0.5),
                  transitionDuration: const Duration(milliseconds: 300),
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return const LoadingAnimationWidget(); // Your widget here
                  },
                );
            await Future.delayed(const Duration(seconds: 5));
              // Then pop back to previous screen
             Navigator.pop(context); // pop WebViewActivityWidget
             Navigator.pop(context); // pop the previous screen
            }
          } catch (e) {
            print("Error processing message: $e");
          }
        },
      );
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