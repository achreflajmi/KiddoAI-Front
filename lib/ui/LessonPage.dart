import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import '../view_models/Lessons_ViewModel.dart';
import '../widgets/loading_animation_widget.dart';
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

class _LessonsPageState extends State<LessonsPage> with TickerProviderStateMixin {
  final LessonsViewModel _viewModel = LessonsViewModel();
  bool _isLoading = false;
  String _lessonExplanation = '';
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _listAnimationController;
  late AnimationController _explanationAnimationController;
  late AnimationController _headerAnimationController;
  bool _showExplanation = false;
  bool _isPlayingAudio = false;

  // Map of subject names to their respective colors
  final Map<String, Color> _subjectColors = {
    'Math': Color(0xFF4CAF50),
    'Science': Color(0xFF2196F3),
    'English': Color(0xFFF44336),
    'History': Color(0xFFFF9800),
    'Art': Color(0xFF9C27B0),
    'Music': Color(0xFF3F51B5),
  };

  // Map of subject names to their respective icons
  final Map<String, IconData> _subjectIcons = {
    'Math': Icons.calculate,
    'Science': Icons.science,
    'English': Icons.menu_book,
    'History': Icons.history_edu,
    'Art': Icons.palette,
    'Music': Icons.music_note,
  };

  // Map of subject names to their respective background images
  final Map<String, String> _subjectBackgrounds = {
    'Math': 'https://img.freepik.com/free-vector/hand-drawn-math-background_23-2148157511.jpg',
    'Science': 'https://img.freepik.com/free-vector/hand-drawn-science-background_23-2148499325.jpg',
    'English': 'https://img.freepik.com/free-vector/hand-drawn-english-background_23-2149483602.jpg',
    'History': 'https://img.freepik.com/free-vector/hand-drawn-history-background_23-2148161527.jpg',
    'Art': 'https://img.freepik.com/free-vector/hand-drawn-art-background_23-2149483554.jpg',
    'Music': 'https://img.freepik.com/free-vector/hand-drawn-music-background_23-2148523557.jpg',
  };

  @override
  void initState() {
    super.initState();
    _viewModel.fetchLessons(widget.subjectName);

    _listAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _explanationAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _headerAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _listAnimationController.forward();
    _headerAnimationController.forward();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlayingAudio = state == PlayerState.playing;
      });
    });
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    _explanationAnimationController.dispose();
    _headerAnimationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Color _getSubjectColor() {
    return _subjectColors[widget.subjectName] ?? Color(0xFF795548);
  }

  IconData _getSubjectIcon() {
    return _subjectIcons[widget.subjectName] ?? Icons.school;
  }

  String _getSubjectBackground() {
    return _subjectBackgrounds[widget.subjectName] ?? '';
  }

 Future<void> _initializeVoice(String text) async {
  try {
    final baseUrl = 'https://f661-196-184-87-113.ngrok-free.app';
    final response = await http.post(
      Uri.parse('$baseUrl/initialize-voice'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "text": text,
        "speaker_wav": "sounds/SpongBob.wav",
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final requestId = data['request_id'] as String;
      final totalParts = data['total_parts'] as int;
      print("Initialized with requestId: $requestId, totalParts: $totalParts");

      // Start polling and playing parts
      int currentPart = 1;
      while (currentPart <= totalParts) {
        String? audioUrl;
        while (audioUrl == null) {
          final statusResponse = await http.get(
            Uri.parse('$baseUrl/part-status/$requestId/$currentPart'),
          );
          if (statusResponse.statusCode == 200) {
            final statusData = jsonDecode(statusResponse.body);
            if (statusData['status'] == 'done') {
              audioUrl = statusData['audio_url'];
              print("Part $currentPart ready: $audioUrl");
            } else {
              print("Waiting for part $currentPart to be ready...");
              await Future.delayed(Duration(seconds: 1));
            }
          } else {
            throw Exception('Error checking status for part $currentPart: ${statusResponse.body}');
          }
        }

        // Play the part as soon as it's ready
        print("Playing part $currentPart: $audioUrl");
        await _audioPlayer.play(UrlSource(audioUrl));
        await _audioPlayer.onPlayerComplete.first;
        print("Finished playing part $currentPart");
        currentPart++;
      }
      print("All parts played successfully");
    } else {
      print("Error initializing voice: ${response.body}");
    }
  } catch (e) {
    print("Error in voice initialization/playback: $e");
  }
}


  // Helper function to fetch audio URL
  Future<String> _getAudioUrl(String requestId, int partNumber) async {
    final baseUrl = 'https://f661-196-184-87-113.ngrok-free.app';
    final partResponse = await http.get(
      Uri.parse('$baseUrl/get-part/$requestId/$partNumber'),
    );
    if (partResponse.statusCode == 200) {
      final partData = jsonDecode(partResponse.body);
      return '$baseUrl${partData['audio_file']}';
    } else {
      throw Exception('Error fetching part $partNumber: ${partResponse.body}');
    }
  }

  Future<void> _teachLesson(String lessonName, String subjectName) async {
    setState(() {
      _isLoading = true;
      _lessonExplanation = '';
      _showExplanation = false;
    });

    final prefs = await SharedPreferences.getInstance();
    final threadId = prefs.getString('threadId') ?? '';

    if (threadId.isEmpty) {
      setState(() {
        _lessonExplanation = 'No threadId found. Please login again.';
        _isLoading = false;
      });
      return;
    }

    final url = Uri.parse('https://a607-102-27-195-209.ngrok-free.app/KiddoAI/chat/teach_lesson');

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
        // Try to decode as JSON first
        try {
          final decodedResponse = jsonDecode(response.body);
          if (decodedResponse is Map && decodedResponse.containsKey('response')) {
            setState(() {
              _lessonExplanation = decodedResponse['response'] as String? ?? '';
              _isLoading = false;
              _showExplanation = true;
            });
          } else {
            // If not a valid JSON object with 'response', treat it as plain text
            setState(() {
              _lessonExplanation = response.body;
              _isLoading = false;
              _showExplanation = true;
            });
          }
        } catch (e) {
          // If JSON decoding fails, assume it's plain text
          setState(() {
            _lessonExplanation = response.body;
            _isLoading = false;
            _showExplanation = true;
          });
        }

        _explanationAnimationController.reset();
        _explanationAnimationController.forward();

        _initializeVoice(_lessonExplanation);
      } else {
        throw Exception('Failed to load lesson explanation: Status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false;
        _lessonExplanation = 'Failed to load lesson. Please try again.';
        _showExplanation = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading lesson: $e"),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
        ),
      );
    }
  }

Future<void> _checkAndOpenActivity(String lessonName,String subjectName,int level) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingAnimationWidget(),
    );

    final activityUrl = "http://172.20.10.13:8083/KiddoAI/Activity/saveProblem";
    final activityPageUrl = "http://172.20.10.13:8080/";

    bool isActivityReady = false;

    try {
     
        final response = await http.post(
          Uri.parse(activityUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "lesson": lessonName,
            "subject": subjectName,
            "level": level,
          }), 
        );
        //final react_run = await http.get(Uri.parse("https://f086-102-157-72-42.ngrok-free.app/openActivity"));

        if (response.statusCode == 200) {// && react_run.statusCode == 200) {
          isActivityReady = true;
        } else {
          await Future.delayed(Duration(seconds: 2));
        }
     

      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebViewActivityWidget(activityUrl: activityPageUrl),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading activity: $e"),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color subjectColor = _getSubjectColor();
    final IconData subjectIcon = _getSubjectIcon();
    final String backgroundImage = _getSubjectBackground();

    return Scaffold(
      body: Stack(
        children: [
          // Background with pattern
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              image: backgroundImage.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(backgroundImage),
                      fit: BoxFit.cover,
                      opacity: 0.05,
                    )
                  : null,
            ),
          ),
          
          CustomScrollView(
            physics: BouncingScrollPhysics(),
            slivers: [
              // Animated Header
              SliverAppBar(
                expandedHeight: 200.0,
                floating: false,
                pinned: true,
                stretch: true,
                backgroundColor: subjectColor,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return FlexibleSpaceBar(
                      titlePadding: EdgeInsets.only(left: 16, bottom: 16),
                      title: AnimatedBuilder(
                        animation: _headerAnimationController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _headerAnimationController.value,
                            child: child,
                          );
                        },
                        child: Text(
                          "${widget.subjectName} Lessons",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Gradient background
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                                colors: [
                                  subjectColor,
                                  subjectColor.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                          
                          // Pattern overlay
                          Opacity(
                            opacity: 0.1,
                            child: Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(
                                    'https://www.transparenttextures.com/patterns/cubes.png',
                                  ),
                                  repeat: ImageRepeat.repeat,
                                ),
                              ),
                            ),
                          ),
                          
                          // Subject icon (large, decorative)
                          Positioned(
                            right: -20,
                            bottom: -20,
                            child: AnimatedBuilder(
                              animation: _headerAnimationController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _headerAnimationController.value * 0.1,
                                  child: Opacity(
                                    opacity: 0.2 * _headerAnimationController.value,
                                    child: Icon(
                                      subjectIcon,
                                      size: 180,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          
                          // Content
                          Positioned(
                            left: 20,
                            bottom: 60,
                            child: AnimatedBuilder(
                              animation: _headerAnimationController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(
                                    (1 - _headerAnimationController.value) * -50,
                                    0,
                                  ),
                                  child: Opacity(
                                    opacity: _headerAnimationController.value,
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            subjectIcon,
                                            size: 30,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 15),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Let's explore",
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.9),
                                                fontSize: 14,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              widget.subjectName,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.info_outline, color: Colors.white),
                    onPressed: () {
                      // Show info about the subject
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Row(
                            children: [
                              Icon(subjectIcon, color: subjectColor),
                              SizedBox(width: 10),
                              Text("About ${widget.subjectName}"),
                            ],
                          ),
                          content: Text(
                            "This section contains all the lessons for ${widget.subjectName}. "
                            "Tap on 'Learn' to get an explanation or 'Start Activity' to practice what you've learned!",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("Got it!"),
                              style: TextButton.styleFrom(
                                foregroundColor: subjectColor,
                              ),
                            ),
                          ],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.bookmark_border, color: Colors.white),
                    onPressed: () {
                      // Bookmark functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Subject bookmarked!"),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          margin: EdgeInsets.all(10),
                          backgroundColor: subjectColor,
                        ),
                      );
                    },
                  ),
                  SizedBox(width: 8),
                ],
              ),
              
              // Loading indicator
              if (_isLoading)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Column(
                        children: [
                          Lottie.network(
                            'https://assets10.lottiefiles.com/packages/lf20_2LdL1k.json',
                            height: 150,
                            errorBuilder: (context, error, stackTrace) {
                              return CircularProgressIndicator(
                                color: subjectColor,
                                strokeWidth: 3,
                              );
                            },
                          ),
                          SizedBox(height: 20),
                          Text(
                            "Loading your lesson...",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "This might take a moment",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // Lesson explanation card
              if (_showExplanation)
                SliverToBoxAdapter(
                  child: AnimatedBuilder(
                    animation: _explanationAnimationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          0,
                          (1 - _explanationAnimationController.value) * 50,
                        ),
                        child: Opacity(
                          opacity: _explanationAnimationController.value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: subjectColor.withOpacity(0.15),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                        border: Border.all(
                          color: subjectColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with close button
                          Container(
                            padding: EdgeInsets.fromLTRB(20, 20, 10, 15),
                            decoration: BoxDecoration(
                              color: subjectColor.withOpacity(0.05),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: subjectColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.lightbulb,
                                    color: subjectColor,
                                    size: 22,
                                  ),
                                ),
                                SizedBox(width: 15),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Lesson Explanation",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: subjectColor,
                                      ),
                                    ),
                                    Text(
                                      "Listen and learn",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                Spacer(),
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.grey.shade700),
                                  onPressed: () {
                                    setState(() {
                                      _showExplanation = false;
                                      _audioPlayer.stop();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          
                          // Content
                          Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Audio status indicator
                                if (_isPlayingAudio)
                                  Container(
                                    margin: EdgeInsets.only(bottom: 15),
                                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: subjectColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: subjectColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "Audio playing...",
                                          style: TextStyle(
                                            color: subjectColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                
                                // Explanation text
                                Text(
                                  _lessonExplanation,
                                  style: TextStyle(
                                    fontSize: 16,
                                    height: 1.6,
                                    color: Colors.black87,
                                  ),
                                ),
                                
                                // Audio controls
                                Container(
                                  margin: EdgeInsets.only(top: 20),
                                  padding: EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.volume_up,
                                        color: subjectColor,
                                        size: 22,
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          "Audio narration",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                      _isPlayingAudio
                                          ? ElevatedButton.icon(
                                              icon: Icon(Icons.pause, size: 18),
                                              label: Text("Pause"),
                                              onPressed: () {
                                                _audioPlayer.pause();
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: subjectColor,
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                            )
                                          : ElevatedButton.icon(
                                              icon: Icon(Icons.play_arrow, size: 18),
                                              label: Text("Play"),
                                              onPressed: () {
                                                _initializeVoice(_lessonExplanation);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: subjectColor,
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // Available Lessons header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, _showExplanation ? 10 : 20, 20, 5),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: subjectColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.book,
                          color: subjectColor,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Available Lessons",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: subjectColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.filter_list,
                              color: subjectColor,
                              size: 16,
                            ),
                            SizedBox(width: 5),
                            Text(
                              "Filter",
                              style: TextStyle(
                                fontSize: 12,
                                color: subjectColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Lessons list
              ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: _viewModel.lessons,
                builder: (context, lessons, _) {
                  if (lessons.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Lottie.network(
                              'https://assets10.lottiefiles.com/packages/lf20_wnqlfojb.json',
                              height: 150,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.error, size: 50, color: Colors.red);
                              },
                            ),
                            SizedBox(height: 20),
                            Text(
                              'No lessons available yet!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _viewModel.fetchLessons(widget.subjectName);
                                });
                              },
                              icon: Icon(Icons.refresh),
                              label: Text("Refresh"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: subjectColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final lesson = lessons[index];
                        //final description = lesson['description'];
                        final name = lesson['name'];
                        final level = lesson['level'];

                        // Create a staggered animation for each item
                        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _listAnimationController,
                            curve: Interval(
                              (index / lessons.length) * 0.5,
                              ((index + 1) / lessons.length) * 0.5 + 0.5,
                              curve: Curves.easeOut,
                            ),
                          ),
                        );

                        return AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                (1 - animation.value) * 100,
                                0,
                              ),
                              child: Opacity(
                                opacity: animation.value,
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.grey.shade100,
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  _checkAndOpenActivity(name,widget.subjectName,level);
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: subjectColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.school,
                                              color: subjectColor,
                                              size: 30,
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.access_time,
                                                      size: 14,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      "10-15 min",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Container(
                                                      width: 4,
                                                      height: 4,
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey.shade400,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Icon(
                                                      Icons.star,
                                                      size: 14,
                                                      color: Colors.amber,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      "Beginner",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 15),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              icon: Icon(Icons.play_circle_outline, size: 18),
                                              label: Text("Start Activity"),
                                              onPressed: () {
                                                _checkAndOpenActivity(name,widget.subjectName,level);
                                              },
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: subjectColor,
                                                side: BorderSide(color: subjectColor),
                                                padding: EdgeInsets.symmetric(vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              icon: Icon(Icons.lightbulb_outline, size: 18),
                                              label: Text("Learn"),
                                              onPressed: () {
                                                _teachLesson(name, widget.subjectName);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: subjectColor,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                padding: EdgeInsets.symmetric(vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: lessons.length,
                    ),
                  );
                },
              ),
              
              // Bottom padding
              SliverToBoxAdapter(
                child: SizedBox(height: 30),
              ),
            ],
          ),
          
          // Floating action button for quick actions
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                // Show quick actions menu
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (context) => Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: EdgeInsets.only(bottom: 20),
                        ),
                        Text(
                          "Quick Actions",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildQuickActionItem(
                              icon: Icons.bookmark,
                              label: "Bookmark",
                              color: Colors.blue,
                              onTap: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Subject bookmarked!"),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                            _buildQuickActionItem(
                              icon: Icons.share,
                              label: "Share",
                              color: Colors.green,
                              onTap: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Sharing is not available yet"),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                            _buildQuickActionItem(
                              icon: Icons.help_outline,
                              label: "Help",
                              color: Colors.orange,
                              onTap: () {
                                Navigator.pop(context);
                                // Show help dialog
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
              backgroundColor: subjectColor,
              child: Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}