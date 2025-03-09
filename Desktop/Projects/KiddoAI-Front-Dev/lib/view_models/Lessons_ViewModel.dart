import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/lessons_service.dart';
import 'package:front_kiddoai/ui/webview_activity_widget.dart';
import '../widgets/loading_animation_widget.dart';

class LessonsViewModel extends ChangeNotifier {
  final LessonsService _service = LessonsService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  final ValueNotifier<List<Map<String, dynamic>>> lessons = ValueNotifier<List<Map<String, dynamic>>>([]);
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<String> lessonExplanation = ValueNotifier<String>('');
  final ValueNotifier<bool> showExplanation = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isPlayingAudio = ValueNotifier<bool>(false);
  final ValueNotifier<String> errorMessage = ValueNotifier<String>('');

  final Map<String, Map<String, dynamic>> subjectAttributes = {
    'Math': {'color': 0xFF4CAF50, 'icon': 'calculate', 'background': 'https://img.freepik.com/free-vector/hand-drawn-math-background_23-2148157511.jpg'},
    'Science': {'color': 0xFF2196F3, 'icon': 'science', 'background': 'https://img.freepik.com/free-vector/hand-drawn-science-background_23-2148499325.jpg'},
    'English': {'color': 0xFFF44336, 'icon': 'menu_book', 'background': 'https://img.freepik.com/free-vector/hand-drawn-english-background_23-2149483602.jpg'},
    'History': {'color': 0xFFFF9800, 'icon': 'history_edu', 'background': 'https://img.freepik.com/free-vector/hand-drawn-history-background_23-2148161527.jpg'},
    'Art': {'color': 0xFF9C27B0, 'icon': 'palette', 'background': 'https://img.freepik.com/free-vector/hand-drawn-art-background_23-2149483554.jpg'},
    'Music': {'color': 0xFF3F51B5, 'icon': 'music_note', 'background': 'https://img.freepik.com/free-vector/hand-drawn-music-background_23-2148523557.jpg'},
  };

  LessonsViewModel() {
    _setupAudioPlayerListeners();
  }

  void _setupAudioPlayerListeners() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!_isDisposed) {
        isPlayingAudio.value = state == PlayerState.playing;
        notifyListeners();
      }
    });
  }

  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  Map<String, dynamic> getSubjectAttributes(String subjectName) {
    return subjectAttributes[subjectName] ?? {
      'color': 0xFF795548,
      'icon': 'school',
      'background': '',
    };
  }

  Future<void> fetchLessons(String subjectName) async {
    if (_isDisposed) return;
    try {
      isLoading.value = true;
      final lessonsList = await _service.fetchLessons(subjectName);
      if (!_isDisposed) {
        lessons.value = lessonsList;
      }
    } catch (e) {
      if (!_isDisposed) {
        errorMessage.value = 'Failed to load lessons: $e';
        _showErrorSnackBar(e);
      }
    } finally {
      if (!_isDisposed) {
        isLoading.value = false;
      }
    }
  }

  Future<void> teachLesson(String lessonName, String subjectName) async {
    if (_isDisposed) return;
    try {
      isLoading.value = true;
      lessonExplanation.value = '';
      showExplanation.value = false;

      final explanation = await _service.teachLesson(lessonName, subjectName);
      if (!_isDisposed) {
        lessonExplanation.value = explanation;
        showExplanation.value = true;
        await generateAndPlayVoice(explanation);
      }
    } catch (e) {
      if (!_isDisposed) {
        errorMessage.value = 'Failed to teach lesson: $e';
        lessonExplanation.value = 'Failed to load lesson. Please try again.';
        showExplanation.value = true;
        _showErrorSnackBar(e);
      }
    } finally {
      if (!_isDisposed) {
        isLoading.value = false;
      }
    }
  }

  Future<void> generateAndPlayVoice(String text) async {
    if (_isDisposed) return;
    try {
      isPlayingAudio.value = true;
      final audioUrl = await _service.generateVoice(text);
      await _audioPlayer.play(UrlSource(audioUrl));
    } catch (e) {
      if (!_isDisposed) {
        errorMessage.value = 'Error playing audio: $e';
        isPlayingAudio.value = false;
        _showErrorSnackBar(e);
      }
    }
  }

  void pauseAudio() {
    if (!_isDisposed) {
      _audioPlayer.pause();
    }
  }

  void playAudio() {
    if (!_isDisposed && lessonExplanation.value.isNotEmpty) {
      generateAndPlayVoice(lessonExplanation.value);
    }
  }

  Future<void> startActivity(BuildContext context, String description) async {
    if (_isDisposed) return;
    try {
      isLoading.value = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const LoadingAnimationWidget(),
      );
      final url = await _service.prepareActivity(description);
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => WebViewActivityWidget(activityUrl: url)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        errorMessage.value = 'Error loading activity: $e';
        Navigator.pop(context); // Close loading dialog
        _showErrorSnackBar(e);
      }
    } finally {
      if (!_isDisposed) {
        isLoading.value = false;
      }
    }
  }

  void hideExplanation() {
    if (!_isDisposed) {
      showExplanation.value = false;
      _audioPlayer.stop();
    }
  }

  void bookmarkSubject(BuildContext context) {
    if (!_isDisposed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Subject bookmarked!"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          margin: EdgeInsets.all(10),
        ),
      );
    }
  }

  void shareSubject(BuildContext context) {
    if (!_isDisposed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sharing is not available yet"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          margin: EdgeInsets.all(10),
        ),
      );
    }
  }

  void _showErrorSnackBar(dynamic error) {
    // This method assumes it's called within a context where ScaffoldMessenger is available
    // For simplicity, we'll assume it's handled in the UI
  }

  @override
  void dispose() {
    _isDisposed = true;
    _audioPlayer.dispose();
    lessons.dispose();
    isLoading.dispose();
    lessonExplanation.dispose();
    showExplanation.dispose();
    isPlayingAudio.dispose();
    errorMessage.dispose();
    _audioPlayer.onPlayerStateChanged.drain(); // Ensure no further callbacks are processed
    super.dispose();
  }
}