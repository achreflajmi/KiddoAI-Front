import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../widgets/bottom_nav_bar.dart';

class WebViewIQTestScreen extends StatefulWidget {
  final String threadId;

  const WebViewIQTestScreen({super.key, required this.threadId});

  @override
  State<WebViewIQTestScreen> createState() => _WebViewIQTestScreenState();
}

class _WebViewIQTestScreenState extends State<WebViewIQTestScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        "flutter_channels",
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == "extractScore") {
            _extractScore();
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            Future.delayed(const Duration(seconds: 5), () {
              _detectResultsPage();
            });
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.test-guide.com/quizzes/kids-iq-test'));
  }

  /// Detects when the results page is loaded and triggers score extraction
  void _detectResultsPage() async {
    String jsCode = """
      (function() {
        let observer = new MutationObserver((mutations, obs) => {
          let bodyText = document.body.innerText;
          if (bodyText.includes("Kids IQ Test") && bodyText.includes("Results")) {
            console.log("Results page detected! Waiting 5 seconds...");
            setTimeout(() => {
              window.flutter_channels.postMessage("extractScore");
            }, 5000);
            obs.disconnect();
          }
        });

        observer.observe(document.body, { childList: true, subtree: true });
      })();
    """;

    _controller.runJavaScript(jsCode);
  }

  /// Extracts the score from the results page
  void _extractScore() async {
    String jsCode = """
      (function() {
        let elements = document.querySelectorAll('p, span, div'); 
        let scoreText = "not_found";
        
        for (let el of elements) {
          let match = el.innerText.match(/(\\d+) of 30/);
          if (match) {
            return match[1];
          }
        }

        return "not_found";
      })();
    """;

    try {
      Object? result = await _controller.runJavaScriptReturningResult(jsCode);
      String scoreText = result?.toString().replaceAll('"', '') ?? "0"; // Remove extra quotes from JSON return
      int score = int.tryParse(scoreText) ?? 0;

      print("Final Extracted Score: $score");

      if (score > 0) {
        _showResultDialog(score);
      } else {
        print("Score extraction failed.");
      }
    } catch (e) {
      print("JavaScript execution error: $e");
    }
  }

  /// Shows a dialog with the extracted score and IQ category
  void _showResultDialog(int score) {
    String iqCategory = _getIQCategory(score);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("IQ Test Result"),
          content: Text("Your Score: $score/30\nIQ Category: $iqCategory"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  /// Converts score to IQ category
  String _getIQCategory(int score) {
    if (score >= 27) return "Very Superior (130+)";
    if (score >= 25) return "Superior (121 - 130)";
    if (score >= 21) return "High Average (111 - 120)";
    if (score >= 13) return "Average (91 - 110)";
    if (score >= 9) return "Low Average (81 - 90)";
    return "Low (0 - 80)";
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          automaticallyImplyLeading: false,
          title: Text(
            'IQ Test',
            style: GoogleFonts.interTight(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          elevation: 2,
        ),
        body: SafeArea(
          child: WebViewWidget(
            controller: _controller,
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          threadId: widget.threadId,
          currentIndex: 0,
        ),
      ),
    );
  }
}