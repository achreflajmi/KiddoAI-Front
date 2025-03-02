import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../view_models/Lessons_ViewModel.dart';
import 'loading_animation_widget.dart';
import 'webview_activity_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';

class LessonsPage extends StatefulWidget {
  final String subjectName;

  const LessonsPage({super.key, required this.subjectName});

  @override
  State<LessonsPage> createState() => _LessonsPageState();
}

class _LessonsPageState extends State<LessonsPage> {
  final LessonsViewModel _viewModel = LessonsViewModel();
  bool _isLoading = false; // For displaying the loading state (SpongeBob GIF)
  String _lessonExplanation = ''; // Store the lesson explanation from the assistant
    final AudioPlayer _audioPlayer = AudioPlayer();


  @override
  void initState() {
    super.initState();
    _viewModel.fetchLessons(widget.subjectName);
  }
  Future<void> _generateAndPlayVoice(String text) async {
    try {
      final response = await http.post(
        Uri.parse('https://86fb-197-6-81-221.ngrok-free.app/generate-voice'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "text": text,
          "speaker_wav": "sounds/SpongBob.wav",
        }),
      );

      if (response.statusCode == 200) {
        final String audioUrl = 'http://172.20.10.9:8001/outputlive.wav';
        final cacheBuster = DateTime.now().millisecondsSinceEpoch;
        final uniqueUrl = '$audioUrl?cache=$cacheBuster';

        final headResponse = await http.head(Uri.parse(uniqueUrl));
        if (headResponse.statusCode != 200) {
          throw Exception('Audio file not found');
        }

        await _audioPlayer.play(UrlSource(audioUrl));
        print("Audio played successfully");
      } else {
        print("Error generating voice: ${response.body}");
      }
    } catch (e) {
      print("Error in voice generation/playback: $e");
    }
  }
  // This method handles fetching and displaying the lesson explanation
  Future<void> _teachLesson(String lessonName, String subjectName) async {
    setState(() {
      _isLoading = true; // Show GIF when the lesson is being processed
      _lessonExplanation = ''; // Clear the explanation before fetching a new one
    });

    // Fetch threadId from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final threadId = prefs.getString('threadId') ?? ''; // Get threadId or empty if not found

    if (threadId.isEmpty) {
      setState(() {
        _lessonExplanation = 'No threadId found. Please login again.';
        _isLoading = false;
      });
      return;
    }

    final url = Uri.parse('https://8fd8-102-154-202-95.ngrok-free.app/KiddoAI/chat/teach_lesson');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'threadId': threadId,
          'lessonName': lessonName,
          'subjectName': subjectName,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _lessonExplanation = jsonDecode(response.body)['response'];
          _generateAndPlayVoice(_lessonExplanation);
        });
      } else {
        throw Exception('Failed to load lesson explanation');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        _isLoading = false; // Hide the GIF once the explanation is fetched
      });
    }
  }

  // This method checks the activity URL and opens it in a WebView if 200 OK is received
  Future<void> _checkAndOpenActivity(String description) async {
    // Show loading animation while waiting for response
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingAnimationWidget(),
    );

    final activityUrl = "https://8fd8-102-154-202-95.ngrok-free.app/KiddoAI/Activity/Create/$description";
    final activityPageUrl = "https://8fd8-102-154-202-95.ngrok-free.app/KiddoAI/Activity/html";

    // Check if the activity URL is valid (returns 200 OK)
    bool isActivityReady = false;

    try {
      while (!isActivityReady) {
        final response = await http.get(Uri.parse(activityUrl));

        if (response.statusCode == 200) {
          isActivityReady = true;
        } else {
          // Wait for a short interval before retrying
          await Future.delayed(Duration(seconds: 2));
        }
      }

      // Close the loading animation
      Navigator.pop(context);

      // Now that the activity is ready, navigate to the WebView
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebViewActivityWidget(activityUrl: activityPageUrl),
        ),
      );
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
      body: ValueListenableBuilder<List<Map<String, dynamic>>>( // Listening for lessons
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
                  onTap: () {
                    // When tapping the lesson, only execute the activity part
                    _checkAndOpenActivity(description);
                  },
                  trailing: IconButton(
                    icon: Icon(Icons.play_arrow), // Button to teach the lesson
                    onPressed: () {
                      // When pressing the button, execute the teach lesson method
                      _teachLesson(name, widget.subjectName);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}