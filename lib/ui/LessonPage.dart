import 'package:flutter/material.dart';
import '../view_models/Lessons_ViewModel.dart';
import 'loading_animation_widget.dart';
import 'webview_activity_widget.dart';
import 'package:http/http.dart' as http;

class LessonsPage extends StatefulWidget {
  final String subjectName;

  const LessonsPage({super.key, required this.subjectName});

  @override
  State<LessonsPage> createState() => _LessonsPageState();
}

class _LessonsPageState extends State<LessonsPage> {
  final LessonsViewModel _viewModel = LessonsViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.fetchLessons(widget.subjectName);
  }

  Future<void> _openActivity(String description) async {
    // Show loading animation while waiting for response
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingAnimationWidget(),
    );

    final url = Uri.parse("http://172.20.10.6:8081/KiddoAI/Activity/Create/$description");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        // Close loading animation
        Navigator.pop(context);

        // Navigate to WebView page with the specified URL
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebViewActivityWidget(activityUrl: "http://172.20.10.6:8081/KiddoAI/Activity/html"),
          ),
        );
      } else {
        throw Exception("Failed to load activity");
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading activity: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.subjectName} Lessons")),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: _viewModel.lessons,
        builder: (context, lessons, _) {
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              final description = lesson['description'];
              final name = lesson['name']; // Assuming each lesson has a 'name' field

              return Card(
                elevation: 3,
                child: ListTile(
                  title: Text(name), // Display the name of the lesson
                  leading: const Icon(Icons.book),
                  onTap: () => _openActivity(description), // Fetch activity on tap using description
                ),
              );
            },
          );
        },
      ),
    );
  }
}
