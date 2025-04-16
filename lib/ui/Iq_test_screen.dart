import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' show ImageFilter;
import 'package:lottie/lottie.dart';
import '../view_models/iq_test_viewmodel.dart';
import '../widgets/bottom_nav_bar.dart';
import '../models/avatar_settings.dart';
import 'dart:math' as math;

class IQTestScreen extends StatefulWidget {
  final String threadId;

  const IQTestScreen({super.key, required this.threadId});

  @override
  _IQTestScreenState createState() => _IQTestScreenState();
}

class _IQTestScreenState extends State<IQTestScreen> with WidgetsBindingObserver {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _selectedAvatarName = AvatarSettings.defaultAvatarName;
  Map<String, dynamic> _currentTheme = {};

  // --- Tutorial Setup Variables ---
  TutorialCoachMark? _tutorialCoachMark;
  List<TargetFocus> _targets = [];

  final GlobalKey _keyQuestionTitle = GlobalKey();
  final GlobalKey _keyScore = GlobalKey();
  final GlobalKey _keyPattern = GlobalKey();
  final GlobalKey _keyDragTarget = GlobalKey();
  final GlobalKey _keyOption = GlobalKey();
  final GlobalKey _keyProgress = GlobalKey();
  final GlobalKey _keyNextButton = GlobalKey();

  final String _tutorialPreferenceKey = 'iqTestTutorialShown';
  // --- End Tutorial Setup Variables ---

  final Map<String, Map<String, dynamic>> _characterThemes = {
    'SpongeBob': {
      'primaryColor': const Color(0xFFFFEB3B),
      'secondaryColor': const Color(0xFFFFF9C4),
      'accentColor': Colors.blue,
      'gradient': const [Color.fromARGB(255, 206, 190, 46), Color(0xFFFFF9C4)],
    },
    'Gumball': {
      'primaryColor': const Color(0xFF2196F3),
      'secondaryColor': const Color(0xFFE3F2FD),
      'accentColor': Colors.orange,
      'gradient': const [Color.fromARGB(255, 48, 131, 198), Color(0xFFE3F2FD)],
    },
    'SpiderMan': {
      'primaryColor': const Color.fromARGB(255, 227, 11, 18),
      'secondaryColor': const Color(0xFFFFEBEE),
      'accentColor': Colors.blue,
      'gradient': const [Color.fromARGB(255, 203, 21, 39), Color(0xFFFFEBEE)],
    },
    'HelloKitty': {
      'primaryColor': const Color(0xFFFF80AB),
      'secondaryColor': const Color(0xFFFCE4EC),
      'accentColor': Colors.red,
      'gradient': const [Color.fromARGB(255, 255, 131, 174), Color(0xFFFCE4EC)],
    },
  };

  @override
  void initState() {
    super.initState();
    _loadAvatarTheme();
    WidgetsBinding.instance.addObserver(this);
    _checkIfTutorialShouldBeShown();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    if (_tutorialCoachMark?.isShowing ?? false) {
      _tutorialCoachMark!.finish();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused && (_tutorialCoachMark?.isShowing ?? false)) {
      _tutorialCoachMark?.finish();
    }
  }

  Future<void> _loadAvatarTheme() async {
    final avatar = await AvatarSettings.getCurrentAvatar();
    if (mounted) {
      setState(() {
        _selectedAvatarName = avatar['name']!;
        _currentTheme = _characterThemes[_selectedAvatarName]!;
      });
    }
  }

  void _playSound(String assetPath) async {
    if (mounted) {
      await _audioPlayer.play(AssetSource(assetPath));
    }
  }

  void _playInstruction(String soundPath) async {
    if (mounted) {
      await _audioPlayer.play(AssetSource(soundPath));
    }
  }

  // --- Tutorial Functions ---
  void _checkIfTutorialShouldBeShown() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool tutorialSeen = prefs.getBool(_tutorialPreferenceKey) ?? false;

    if (!tutorialSeen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _initTargets();
            _showTutorial();
          }
        });
      });
    }
  }

  void _initTargets() {
    _targets.clear();

    // Target 1: Question Title
    _targets.add(
      TargetFocus(
        identify: "questionTitle",
        keyTarget: _keyQuestionTitle,
        alignSkip: Alignment.topLeft, // Adjusted for RTL
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: _buildTutorialContent(
              title: "وقت الأسئلة!",
              description: "هذا يُخبرك بأي سؤال وصلت. تابع التقدّم!",
            ),
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 10,
      ),
    );

    // Target 2: Score Area
    _targets.add(
      TargetFocus(
        identify: "scoreArea",
        keyTarget: _keyScore,
        alignSkip: Alignment.topRight, // Adjusted for RTL
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: _buildTutorialContent(
              title: "نجومك!",
              description: "رائع! شاهد كم نجمة جمعت للإجابات الصحيحة!",
            ),
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 15,
      ),
    );

    // Target 3: The Pattern Image
    _targets.add(
      TargetFocus(
        identify: "patternImage",
        keyTarget: _keyPattern,
        alignSkip: Alignment.topLeft, // Adjusted for RTL
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: _buildTutorialContent(
              title: "انظر جيدًا!",
              description: "هذا هو النمط. اعثر على القطعة التي تناسب المكان الفارغ!",
            ),
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 20,
      ),
    );

    // Target 4: The Drag Target Box
    _targets.add(
      TargetFocus(
        identify: "dragTargetBox",
        keyTarget: _keyDragTarget,
        alignSkip: Alignment.bottomLeft, // Adjusted for RTL
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _buildTutorialContent(
              title: "اسحب هنا!",
              description: "وجدت القطعة المناسبة؟ اسحبها إلى هذا الصندوق الخاص!",
            ),
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 20,
      ),
    );

    // Target 5: First Draggable Option
    _targets.add(
      TargetFocus(
        identify: "draggableOption",
        keyTarget: _keyOption,
        alignSkip: Alignment.topLeft, // Adjusted for RTL
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _buildTutorialContent(
              title: "اختر بحكمة!",
              description: "اختر الإجابة الصحيحة من بين هذه الخيارات واسحبها للأعلى!",
            ),
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 15,
      ),
    );

    // Target 6: Progress Tracker
    _targets.add(
      TargetFocus(
        identify: "progressTracker",
        keyTarget: _keyProgress,
        alignSkip: Alignment.bottomLeft, // Adjusted for RTL
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _buildTutorialContent(
              title: "رحلتك!",
              description: "شاهد تقدمك! الأخضر يعني إجابة صحيحة، والبرتقالي يعني أعد المحاولة. اضغط للعودة!",
            ),
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 10,
      ),
    );

    // Target 7: Next Button
    _targets.add(
      TargetFocus(
        identify: "nextButton",
        keyTarget: _keyNextButton,
        alignSkip: Alignment.bottomRight, // Adjusted for RTL
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _buildTutorialContent(
              title: "إلى الأمام!",
              description: "بعد أن تجيب، اضغط هنا للانتقال إلى التحدي التالي!",
            ),
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 10,
      ),
    );
  }

  Widget _buildTutorialContent({required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 20.0, left: 20.0, right: 20.0),
      decoration: BoxDecoration(
        color: _currentTheme['accentColor']?.withOpacity(0.9) ?? Colors.deepPurple,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end, // Adjusted for RTL
        children: <Widget>[
          Text(
            title,
            style: GoogleFonts.interTight(
              fontWeight: FontWeight.bold,
              color: Colors.yellowAccent,
              fontSize: 20,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 8.0),
          Text(
            description,
            style: GoogleFonts.interTight(
              color: Colors.white,
              fontSize: 16,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  void _showTutorial() {
    if (_targets.isEmpty || _keyQuestionTitle.currentContext == null) {
      print("Tutorial aborted: Targets not ready or context missing for initial items.");
      return;
    }

    _tutorialCoachMark = TutorialCoachMark(
      targets: _targets,
      colorShadow: Colors.black.withOpacity(0.8),
      textSkip: "تخطَ", // Translated: SKIP
      paddingFocus: 5,
      opacityShadow: 0.8,
      imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      skipWidget: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "تخطَ الكل", // Translated: Skip All
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          textDirection: TextDirection.rtl,
        ),
      ),
      onFinish: () {
        print("IQ Test Tutorial Finished");
        _markTutorialAsSeen();
      },
      onClickTarget: (target) {
        print('onClickTarget: ${target.identify}');
      },
      onClickTargetWithTapPosition: (target, tapDetails) {
        print("target: ${target.identify}");
        print("clicked at position local: ${tapDetails.localPosition} - global: ${tapDetails.globalPosition}");
      },
      onClickOverlay: (target) {
        print('onClickOverlay: ${target.identify}');
      },
      onSkip: () {
        print("IQ Test Tutorial Skipped");
        _markTutorialAsSeen();
        return true;
      },
    )..show(context: context);
  }

  void _markTutorialAsSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialPreferenceKey, true);
    print("Marked '$_tutorialPreferenceKey' as seen.");
  }
  // --- End Tutorial Functions ---

  @override
  Widget build(BuildContext context) {
    final primaryColor = _currentTheme['primaryColor'] ?? const Color(0xFF049a02);
    final secondaryColor = _currentTheme['secondaryColor'] ?? Colors.yellow[50];
    final gradient = _currentTheme['gradient'] ?? [Colors.yellow[50]!, Colors.yellow[100]!];

    return Directionality(
      textDirection: TextDirection.rtl, // Added for RTL
      child: ChangeNotifierProvider(
        create: (_) => IQTestViewModel(),
        child: Scaffold(
          backgroundColor: secondaryColor,
          appBar: AppBar(
            backgroundColor: primaryColor,
            title: Text(
              'اختبار الذكاء للأطفال', // Translated: Kids IQ Test
              style: GoogleFonts.interTight(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
              textDirection: TextDirection.rtl,
            ),
            elevation: 2,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient as List<Color>,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Consumer<IQTestViewModel>(
                builder: (context, viewModel, child) {
                  if (viewModel.questions.isEmpty && !viewModel.isTestCompleted) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (viewModel.isTestCompleted) {
                    return _buildResultScreen(context, viewModel);
                  }
                  return _buildQuestionScreen(context, viewModel);
                },
              ),
            ),
          ),
          bottomNavigationBar: BottomNavBar(
            threadId: widget.threadId,
            currentIndex: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionScreen(BuildContext context, IQTestViewModel viewModel) {
    final question = viewModel.currentQuestion;
    double patternSize = MediaQuery.of(context).size.width * 0.30;
    double optionSize = MediaQuery.of(context).size.width * 0.20;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end, // Adjusted for RTL
                children: [
   Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      key: _keyScore,
      children: [
        Text(
          "النجوم: ",
          style: GoogleFonts.interTight(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _currentTheme['accentColor'] ?? Colors.blue[800],
          ),
          textDirection: TextDirection.rtl,
        ),
        ...List.generate(
          viewModel.score,
          (index) => TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.5, end: 1),
            duration: Duration(milliseconds: 300 + index * 100),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: const Icon(Icons.star_rounded, color: Colors.amber, size: 26),
              );
            },
          ),
        ),
      ],
    ),
    Flexible(
      child: Text(
        "السؤال ${viewModel.currentQuestionIndex + 1}",
        key: _keyQuestionTitle,
        style: GoogleFonts.interTight(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: _currentTheme['accentColor'] ?? Colors.blue[800],
        ),
        textDirection: TextDirection.rtl,
      ),
    ),
  ].reversed.toList().cast<Widget>(), // ✅ Correct use of reversed
)
,
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      key: _keyPattern,
                      child: _buildAnimatedPattern(question.pattern, patternSize.clamp(100, 250)),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: DragTarget<int>(
                      key: _keyDragTarget,
                      builder: (context, candidateData, rejectedData) {
                        bool isHovering = candidateData.isNotEmpty;
                        bool isCorrectlyAnswered = viewModel.isAnswerSubmitted && viewModel.selectedOptionIndex == question.correctOptionIndex;
                        bool isIncorrectlyAnswered = viewModel.isAnswerSubmitted && viewModel.selectedOptionIndex != question.correctOptionIndex;

                        Color borderColor = Colors.grey;
                        double borderWidth = 2.0;
                        Color glowColor = Colors.transparent;

                        if (isHovering && !viewModel.isQuestionLocked(viewModel.currentQuestionIndex)) {
                          borderColor = Colors.green.shade400;
                          borderWidth = 4.0;
                          glowColor = Colors.green.withOpacity(0.3);
                        } else if (isCorrectlyAnswered) {
                          borderColor = Colors.green;
                          borderWidth = 3.0;
                          glowColor = Colors.green.withOpacity(0.5);
                        } else if (isIncorrectlyAnswered) {
                          borderColor = Colors.red;
                          borderWidth = 3.0;
                          glowColor = Colors.red.withOpacity(0.5);
                        } else {
                          borderColor = _currentTheme['accentColor']?.withOpacity(0.6) ?? Colors.grey;
                          borderWidth = 2.0;
                        }

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: patternSize.clamp(100, 250),
                          height: patternSize.clamp(100, 250),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: borderColor,
                              width: borderWidth,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey.withOpacity(0.15),
                            boxShadow: [
                              BoxShadow(
                                color: glowColor,
                                spreadRadius: isHovering ? 4 : 2,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Center(
                            child: viewModel.selectedOptionIndex != null
                                ? _buildGrid(question.options[viewModel.selectedOptionIndex!], patternSize.clamp(100, 250))
                                : Text(
                                    "اسحب الإجابة هنا", // Translated: Drag Answer Here
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.interTight(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                          ),
                        );
                      },
                      onWillAcceptWithDetails: (details) => !viewModel.isQuestionLocked(viewModel.currentQuestionIndex),
                      onAcceptWithDetails: (details) {
                        final int optionIndex = details.data;
                        if (!viewModel.isQuestionLocked(viewModel.currentQuestionIndex)) {
                          viewModel.selectOption(optionIndex);
                          if (optionIndex == question.correctOptionIndex) {
                            _playSound('sounds/correct.mp3');
                            _playInstruction('sounds/yay_got_it.mp3');
                            _showCorrectAnswerAnimation(context);
                          } else {
                            _playSound('sounds/oops.mp3');
                            _playInstruction('sounds/try_again.mp3');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  "قريب جدًا! حاول مرة أخرى في المرة القادمة!", // Translated
                                  textDirection: TextDirection.rtl,
                                ),
                                backgroundColor: _currentTheme['accentColor'] ?? Colors.red,
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                margin: const EdgeInsets.all(10),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "اسحب الإجابة الصحيحة إلى الصندوق أعلاه:", // Translated
                    style: GoogleFonts.interTight(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: _currentTheme['accentColor'] ?? Colors.blue[800],
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: question.options.length,
                    itemBuilder: (context, index) {
                      final key = (index == 0) ? _keyOption : null;
                      return _buildDraggableOption(context, index, question, optionSize.clamp(80, 120), viewModel, key: key);
                    },
                  ),
                  const SizedBox(height: 20),
                  Container(
                    key: _keyProgress,
                    child: _buildProgressTracker(context, viewModel),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        key: _keyNextButton,
                        child: _buildAnimatedButton(
                          onPressed: (viewModel.isAnswerSubmitted || viewModel.isQuestionLocked(viewModel.currentQuestionIndex))
                              ? () {
                                  viewModel.nextQuestion();
                                  _playSound('sounds/correct.mp3');
                                }
                              : null,
                          icon: Icons.arrow_back_ios_new, // Reversed for RTL
                          label: "التالي", // Translated: Next
                          color: (viewModel.isAnswerSubmitted || viewModel.isQuestionLocked(viewModel.currentQuestionIndex))
                              ? (_currentTheme['primaryColor'] ?? Colors.green)
                              : Colors.grey.shade400,
                        ),
                      ),
                      _buildAnimatedButton(
                        onPressed: viewModel.currentQuestionIndex > 0
                            ? () {
                                viewModel.goToQuestion(viewModel.currentQuestionIndex - 1);
                                _playSound('sounds/correct.mp3');
                              }
                            : null,
                        icon: Icons.arrow_forward_ios, // Reversed for RTL
                        label: "السابق", // Translated: Previous
                        color: viewModel.currentQuestionIndex > 0
                            ? (_currentTheme['accentColor']?.withOpacity(0.8) ?? Colors.blue[700]!)
                            : Colors.grey.shade400,
                      ),
                    ].reversed.toList(), // Reversed for RTL
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final ValueNotifier<double> scaleNotifier = ValueNotifier(1.0);

    return ValueListenableBuilder<double>(
      valueListenable: scaleNotifier,
      builder: (context, scale, child) {
        return GestureDetector(
          onTapDown: (_) {
            if (onPressed != null) {
              scaleNotifier.value = 1.1;
            }
          },
          onTapUp: (_) {
            if (onPressed != null) {
              scaleNotifier.value = 1.0;
              onPressed();
            }
          },
          onTapCancel: () {
            scaleNotifier.value = 1.0;
          },
          child: Transform.scale(
            scale: scale,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(
                label,
                style: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                textDirection: TextDirection.rtl,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: onPressed != null ? 4 : 0,
                shadowColor: onPressed != null ? color.withOpacity(0.4) : Colors.transparent,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDraggableOption(
      BuildContext context, int index, Question question, double size, IQTestViewModel viewModel, {GlobalKey? key}) {
    bool isLocked = viewModel.isQuestionLocked(viewModel.currentQuestionIndex);
    bool isSelected = viewModel.selectedOptionIndex == index;
    bool isCorrect = isLocked && (index == question.correctOptionIndex);
    bool isIncorrectSelected = isLocked && isSelected && !isCorrect;

    return Container(
      key: key,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.5, end: 1.0),
        duration: Duration(milliseconds: 500 + index * 100),
        curve: Curves.easeOutBack,
        builder: (context, scaleValue, child) {
          return Transform.scale(
            scale: scaleValue,
            child: Opacity(
              opacity: scaleValue,
              child: child,
            ),
          );
        },
        child: Draggable<int>(
          data: index,
          feedback: Material(
            color: Colors.transparent,
            elevation: 8.0,
            borderRadius: BorderRadius.circular(16),
            child: Transform.scale(
              scale: 1.15,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  border: Border.all(color: _currentTheme['accentColor'] ?? Colors.blue, width: 3),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (_currentTheme['accentColor'] ?? Colors.blue).withOpacity(0.4),
                      spreadRadius: 3,
                      blurRadius: 8,
                    ),
                  ],
                  color: Colors.white.withOpacity(0.8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _buildGrid(question.options[index], size),
                ),
              ),
            ),
          ),
          childWhenDragging: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!, width: 2),
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey[200]?.withOpacity(0.5),
            ),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: size,
            height: size,
            decoration: BoxDecoration(
              border: Border.all(
                color: isCorrect
                    ? Colors.green.shade400
                    : isIncorrectSelected
                        ? Colors.red.shade400
                        : isSelected
                            ? (_currentTheme['accentColor'] ?? Colors.blue)
                            : Colors.grey[400]!,
                width: isSelected || isLocked ? 3 : 2,
              ),
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withOpacity(0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isSelected ? 0.2 : 0.1),
                  spreadRadius: isSelected ? 3 : 1,
                  blurRadius: isSelected ? 6 : 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _buildGrid(question.options[index], size),
            ),
          ),
          onDragStarted: isLocked ? null : () {
            _playSound('sounds/drag_start.mp3');
          },
          maxSimultaneousDrags: isLocked ? 0 : 1,
        ),
      ),
    );
  }

  Widget _buildAnimatedPattern(List<List<String>> pattern, double size) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, scaleValue, child) {
        return Transform.scale(
          scale: scaleValue,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: _currentTheme['accentColor'] ?? Colors.indigo, width: 3),
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withOpacity(0.7),
              boxShadow: [
                BoxShadow(
                  color: (_currentTheme['accentColor'] ?? Colors.indigo).withOpacity(0.3),
                  spreadRadius: 3,
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _buildGrid(pattern, size),
            ),
          ),
        );
      },
    );
  }

  void _showCorrectAnswerAnimation(BuildContext context) {
    OverlayState? overlayState = Overlay.of(context);
    OverlayEntry? entry;

    entry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: IgnorePointer(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.5, end: 1.0),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Icon(Icons.star_rounded, color: _currentTheme['accentColor'] ?? Colors.amber, size: 100),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Opacity(
                          opacity: value,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: (_currentTheme['primaryColor'] ?? Colors.green).withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Text(
                              "مذهل!", // Translated: Awesome!
                              style: GoogleFonts.interTight(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    overlayState.insert(entry);
    Future.delayed(const Duration(milliseconds: 2000), () {
      entry?.remove();
      entry = null;
    });
  }

  Widget _buildGrid(List<List<String>> grid, [double size = 150]) {
    if (grid.isEmpty || grid[0].isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Text(
            "؟", // Arabic question mark
            style: TextStyle(fontSize: 40, color: Colors.grey),
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }
    String cell = grid[0][0];

    return Container(
      color: Colors.white,
      width: size,
      height: size,
      child: cell == "?"
          ? const Center(
              child: Text(
                "؟", // Arabic question mark
                style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.grey),
                textDirection: TextDirection.rtl,
              ),
            )
          : Image.asset(
              _getImagePath(cell),
              width: size,
              height: size,
              fit: BoxFit.contain,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: child,
                );
              },
              errorBuilder: (context, error, stackTrace) {
                print("Error loading image: $cell, $error");
                return Container(
                  color: Colors.red.shade50,
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.red, size: 40),
                  ),
                );
              },
            ),
    );
  }

  String _getImagePath(String value) {
    switch (value) {
      case "pencil_3l.png":
        return "assets/pencil_3l.png";
      case "pencil_2rd.png":
        return "assets/pencil_2rd.png";
      case "pencil_1r.png":
        return "assets/pencil_1r.png";
      case "pencil_3d.png":
        return "assets/pencil_3d.png";
      case "pencil_1l1d1r.png":
        return "assets/pencil_1l1d1r.png";
      case "cross_dots_pattern.png":
        return "assets/cross_dots_pattern.png";
      case "cross_dots_option_a.png":
        return "assets/cross_dots_option_a.png";
      case "cross_dots_option_b.png":
        return "assets/cross_dots_option_b.png";
      case "cross_dots_option_c.png":
        return "assets/cross_dots_option_c.png";
      case "cross_dots_option_d.png":
        return "assets/cross_dots_option_d.png";
      case "shape1_pattern.png":
        return "assets/shape1_pattern.png";
      case "shape1_option_a.png":
        return "assets/shape1_option_a.png";
      case "shape1_option_b.png":
        return "assets/shape1_option_b.png";
      case "shape1_option_c.png":
        return "assets/shape1_option_c.png";
      case "shape1_option_d.png":
        return "assets/shape1_option_d.png";
      case "colored_grid_pattern.png":
        return "assets/colored_grid_pattern.png";
      case "colored_grid_option_a.png":
        return "assets/colored_grid_option_a.png";
      case "colored_grid_option_b.png":
        return "assets/colored_grid_option_b.png";
      case "colored_grid_option_c.png":
        return "assets/colored_grid_option_c.png";
      case "colored_grid_option_d.png":
        return "assets/colored_grid_option_d.png";
      case "colored_squares_pattern.png":
        return "assets/colored_squares_pattern.png";
      case "colored_squares_option_a.png":
        return "assets/colored_squares_option_a.png";
      case "colored_squares_option_b.png":
        return "assets/colored_squares_option_b.png";
      case "colored_squares_option_c.png":
        return "assets/colored_squares_option_c.png";
      case "colored_squares_option_d.png":
        return "assets/colored_squares_option_d.png";
      case "colored_shapes_pattern.png":
        return "assets/colored_shapes_pattern.png";
      case "colored_shapes_option_a.png":
        return "assets/colored_shapes_option_a.png";
      case "colored_shapes_option_b.png":
        return "assets/colored_shapes_option_b.png";
      case "colored_shapes_option_c.png":
        return "assets/colored_shapes_option_c.png";
      case "colored_shapes_option_d.png":
        return "assets/colored_shapes_option_d.png";
      case "number_sequence_pattern.png":
        return "assets/number_sequence_pattern.png";
      case "number_sequence_option_a.png":
        return "assets/number_sequence_option_a.png";
      case "number_sequence_option_b.png":
        return "assets/number_sequence_option_b.png";
      case "number_sequence_option_c.png":
        return "assets/number_sequence_option_c.png";
      case "number_sequence_option_d.png":
        return "assets/number_sequence_option_d.png";
      default:
        print("Warning: Image path not found for '$value'. Using placeholder.");
        return "assets/placeholder.png";
    }
  }

  Widget _buildProgressTracker(BuildContext context, IQTestViewModel viewModel) {
    final rainbowColors = [
      Colors.redAccent,
      Colors.orangeAccent,
      Colors.yellow.shade600,
      Colors.lightGreenAccent.shade700,
      Colors.blueAccent,
      Colors.indigoAccent,
      Colors.purpleAccent,
    ];
    final double itemSize = 40;

    return SizedBox(
      height: itemSize + 10,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true, // Added for RTL
        itemCount: viewModel.questions.length,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, index) {
          bool isCurrent = viewModel.currentQuestionIndex == index;
          bool isAnswered = viewModel.isQuestionLocked(index);
          bool isCorrect = isAnswered && (viewModel.answeredQuestions[index] == viewModel.questions[index].correctOptionIndex);

          Color circleColor;
          IconData? statusIcon;

          if (isAnswered) {
            circleColor = isCorrect ? Colors.green.shade400 : Colors.orange.shade400;
            statusIcon = isCorrect ? Icons.check_circle_outline : Icons.cancel_outlined;
          } else if (isCurrent) {
            circleColor = _currentTheme['accentColor']?.withOpacity(0.9) ?? Colors.blue.shade400;
            statusIcon = Icons.edit_outlined;
          } else {
            circleColor = rainbowColors[index % rainbowColors.length].withOpacity(0.6);
          }

          return GestureDetector(
            onTap: () {
              if (isAnswered || index <= viewModel.currentQuestionIndex) {
                viewModel.goToQuestion(index);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "ابدأ بالسؤال ${index + 1} أولاً!", // Translated
                      textDirection: TextDirection.rtl,
                    ),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(10),
                  ),
                );
              }
            },
            child: Tooltip(
              message: isAnswered
                  ? (isCorrect ? "السؤال ${index + 1}: صحيح" : "السؤال ${index + 1}: غير صحيح") // Translated
                  : "السؤال ${index + 1}", // Translated
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 1.0, end: isCurrent ? 1.15 : 1.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: itemSize,
                      height: itemSize,
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                      decoration: BoxDecoration(
                        color: circleColor,
                        shape: BoxShape.circle,
                        border: isCurrent ? Border.all(color: Colors.white, width: 2.5) : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 3,
                            offset: const Offset(1, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: statusIcon != null
                            ? Icon(statusIcon, color: Colors.white, size: 20)
                            : Text(
                                "${index + 1}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultScreen(BuildContext context, IQTestViewModel viewModel) {
    double percentage = viewModel.questions.isNotEmpty ? (viewModel.score / viewModel.questions.length) * 100 : 0;
    String iqCategory = viewModel.getIQCategory();
    Color categoryColor;
    IconData categoryIcon;
    String celebrationLottie;

    // Translate IQ Category
    String translatedIqCategory;
    switch (iqCategory) {
      case "Super Star":
        translatedIqCategory = "نجم خارق";
        categoryColor = Colors.green.shade600;
        categoryIcon = Icons.emoji_events;
        celebrationLottie = 'https://assets1.lottiefiles.com/packages/lf20_touohxv0.json';
        break;
      case "Great Explorer":
        translatedIqCategory = "مستكشف عظيم";
        categoryColor = _currentTheme['accentColor'] ?? Colors.blue.shade600;
        categoryIcon = Icons.explore;
        celebrationLottie = 'https://assets5.lottiefiles.com/packages/lf20_a3kesdek.json';
        break;
      default:
        translatedIqCategory = "موهبة صاعدة";
        categoryColor = Colors.orange.shade600;
        categoryIcon = Icons.auto_awesome;
        celebrationLottie = 'https://assets9.lottiefiles.com/packages/lf20_l4fgppor.json';
        break;
    }

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: ConfettiPainter(color: _currentTheme['primaryColor'] ?? Colors.yellow),
              size: Size.infinite,
            ),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Lottie.network(
              celebrationLottie,
              height: MediaQuery.of(context).size.height * 0.5,
              repeat: false,
            ),
          ),
        ),
        Center(
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.5, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, scaleValue, child) {
              return Transform.scale(
                scale: scaleValue,
                child: Card(
                  elevation: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  color: (_currentTheme['secondaryColor'] ?? Colors.white).withOpacity(0.98),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(categoryIcon, size: 60, color: categoryColor),
                        const SizedBox(height: 15),
                        Text(
                          "تم إكمال الاختبار!", // Translated: Test Completed!
                          textAlign: TextAlign.center,
                          style: GoogleFonts.interTight(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: _currentTheme['primaryColor'] ?? Colors.green.shade800,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 25),
                        TweenAnimationBuilder(
                          tween: IntTween(begin: 0, end: viewModel.score),
                          duration: const Duration(seconds: 2),
                          curve: Curves.easeOutCubic,
                          builder: (context, int currentScore, child) {
                            return Text(
                              "نتيجتك: $currentScore / ${viewModel.questions.length}", // Translated
                              style: GoogleFonts.interTight(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: _currentTheme['accentColor'] ?? Colors.blue.shade800,
                              ),
                              textDirection: TextDirection.rtl,
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            viewModel.score.clamp(0, 5),
                            (index) => TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0.5, end: 1.0),
                              duration: Duration(milliseconds: 600 + (200 * index)),
                              curve: Curves.elasticOut,
                              builder: (context, starScale, child) {
                                return Transform.scale(
                                  scale: starScale,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    child: Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber.shade600,
                                      size: 45,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: categoryColor, width: 2.5),
                          ),
                          child: Text(
                            "أنت $translatedIqCategory!", // Translated
                            textAlign: TextAlign.center,
                            style: GoogleFonts.interTight(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: categoryColor,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                        const SizedBox(height: 35),
                        _buildAnimatedButton(
                          onPressed: () {
                            viewModel.resetTest();
                            _playSound('sounds/correct.mp3');
                          },
                          icon: Icons.replay_rounded,
                          label: "العب مجددًا", // Translated: Play Again
                          color: _currentTheme['primaryColor'] ?? Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final math.Random random = math.Random();
  final Color? color;

  ConfettiPainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    final List<Color> baseColors = color != null
        ? [
            color!,
            HSLColor.fromColor(color!).withLightness((HSLColor.fromColor(color!).lightness * 0.8).clamp(0.0, 1.0)).toColor(),
            HSLColor.fromColor(color!).withSaturation((HSLColor.fromColor(color!).saturation * 1.2).clamp(0.0, 1.0)).toColor(),
            Colors.white.withOpacity(0.8),
          ]
        : [
            Colors.redAccent,
            Colors.blueAccent,
            Colors.greenAccent,
            Colors.yellowAccent,
            Colors.purpleAccent,
            Colors.orangeAccent,
            Colors.white,
          ];

    for (int i = 0; i < 100; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      double confettiWidth = random.nextDouble() * 8 + 4;
      double confettiHeight = random.nextDouble() * 12 + 6;
      double angle = random.nextDouble() * math.pi;

      paint.color = baseColors[random.nextInt(baseColors.length)].withOpacity(0.6 + random.nextDouble() * 0.4);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-confettiWidth / 2, -confettiHeight / 2, confettiWidth, confettiHeight),
          Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}