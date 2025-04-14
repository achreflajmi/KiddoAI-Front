import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
// tutorial: Import the tutorial_coach_mark package
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
// tutorial: Import shared_preferences for saving tutorial state
import 'package:shared_preferences/shared_preferences.dart';
// tutorial: Import ImageFilter for blur effect
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

// tutorial: Add WidgetsBindingObserver to detect when the build is complete
class _IQTestScreenState extends State<IQTestScreen> with WidgetsBindingObserver {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _selectedAvatarName = AvatarSettings.defaultAvatarName;
  Map<String, dynamic> _currentTheme = {};

  // --- Tutorial Setup Variables ---
  // tutorial: Declare TutorialCoachMark instance
  TutorialCoachMark? _tutorialCoachMark;
  // tutorial: List to hold the tutorial targets
  List<TargetFocus> _targets = [];

  // tutorial: GlobalKeys to identify widgets for the tutorial
  final GlobalKey _keyQuestionTitle = GlobalKey();
  final GlobalKey _keyScore = GlobalKey();
  final GlobalKey _keyPattern = GlobalKey();
  final GlobalKey _keyDragTarget = GlobalKey();
  final GlobalKey _keyOption = GlobalKey(); // Key for the first draggable option
  final GlobalKey _keyProgress = GlobalKey();
  final GlobalKey _keyNextButton = GlobalKey();

  // tutorial: Preference key to check if tutorial was shown for this specific page
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
    // tutorial: Add observer to know when build is complete
    WidgetsBinding.instance.addObserver(this);
    // tutorial: Check if the tutorial needs to be shown when the page loads
    _checkIfTutorialShouldBeShown();
  }

  // tutorial: Ensure observer is removed when the widget is disposed
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose(); // Dispose existing resources
    // tutorial: Dismiss the tutorial if it's showing when the page is disposed
    if (_tutorialCoachMark?.isShowing ?? false) {
      _tutorialCoachMark!.finish();
    }
    super.dispose();
  }

  // tutorial: Override didChangeAppLifecycleState to handle app pauses during tutorial (optional but good practice)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // tutorial: If the app is paused while the tutorial is showing, dismiss it.
    if (state == AppLifecycleState.paused && (_tutorialCoachMark?.isShowing ?? false)) {
       _tutorialCoachMark?.finish();
    }
  }


  Future<void> _loadAvatarTheme() async {
    final avatar = await AvatarSettings.getCurrentAvatar();
    // tutorial: Ensure theme is loaded before potentially using its colors in the tutorial
    if (mounted) {
      setState(() {
        _selectedAvatarName = avatar['name']!;
        _currentTheme = _characterThemes[_selectedAvatarName]!;
      });
    }
  }

  void _playSound(String assetPath) async {
    // Check if mounted before playing sound
     if (mounted) {
        await _audioPlayer.play(AssetSource(assetPath));
     }
  }

  void _playInstruction(String soundPath) async {
    // Check if mounted before playing sound
    if (mounted) {
       await _audioPlayer.play(AssetSource(soundPath));
    }
  }

  // --- Tutorial Functions ---

  // tutorial: Checks SharedPreferences to see if the tutorial should be shown.
  void _checkIfTutorialShouldBeShown() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // tutorial: Default to 'false' if the key doesn't exist
    bool tutorialSeen = prefs.getBool(_tutorialPreferenceKey) ?? false;

    // tutorial: If tutorial hasn't been seen, initialize and schedule it to show
    if (!tutorialSeen) {
      // tutorial: Ensure the UI frame is rendered before trying to find widgets by keys
      WidgetsBinding.instance.addPostFrameCallback((_) {
         // tutorial: Add a small delay to ensure dynamic list items (like options) are built
         Future.delayed(const Duration(milliseconds: 500), () {
           // tutorial: Check if the widget is still mounted before initializing and showing
           if (mounted) {
              _initTargets(); // Prepare the tutorial steps
              _showTutorial(); // Show the tutorial sequence
           }
        });
      });
    }
  }

  // tutorial: Defines the steps (TargetFocus) for the tutorial.
  void _initTargets() {
    _targets.clear(); // tutorial: Clear previous targets if any

    // tutorial: Target 1: Question Title
    _targets.add(
      TargetFocus(
        identify: "questionTitle",
        keyTarget: _keyQuestionTitle,
        alignSkip: Alignment.topRight,
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

    // tutorial: Target 2: Score Area
    _targets.add(
      TargetFocus(
        identify: "scoreArea",
        keyTarget: _keyScore,
        alignSkip: Alignment.topLeft, // Adjusted skip alignment
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

    // tutorial: Target 3: The Pattern Image
    _targets.add(
      TargetFocus(
        identify: "patternImage",
        keyTarget: _keyPattern,
        alignSkip: Alignment.topRight,
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

    // tutorial: Target 4: The Drag Target Box
    _targets.add(
      TargetFocus(
        identify: "dragTargetBox",
        keyTarget: _keyDragTarget,
        alignSkip: Alignment.bottomRight, // Adjusted skip alignment
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top, // Show description above the box
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

    // tutorial: Target 5: First Draggable Option
    // tutorial: Note: This relies on _keyOption being assigned correctly in build() to the first item
    _targets.add(
      TargetFocus(
        identify: "draggableOption",
        keyTarget: _keyOption, // Make sure _keyOption is assigned to the first option widget
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top, // Show description above the options area
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

     // tutorial: Target 6: Progress Tracker
    _targets.add(
      TargetFocus(
        identify: "progressTracker",
        keyTarget: _keyProgress,
        alignSkip: Alignment.bottomRight, // Adjusted skip alignment
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
         shape: ShapeLightFocus.RRect, // Can be RRect to cover the row
         radius: 10,
      ),
    );

    // tutorial: Target 7: Next Button
    _targets.add(
      TargetFocus(
        identify: "nextButton",
        keyTarget: _keyNextButton,
        alignSkip: Alignment.bottomLeft, // Adjusted skip alignment
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

 // tutorial: Builds the content widget displayed for each tutorial step, styled like the example.
 Widget _buildTutorialContent({required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      // tutorial: Add margin similar to the example page for better spacing
      margin: const EdgeInsets.only(bottom: 20.0, left: 20.0, right: 20.0),
      decoration: BoxDecoration(
        color: _currentTheme['accentColor']?.withOpacity(0.9) ?? Colors.deepPurple, // tutorial: Use theme color or fallback
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: const [ // tutorial: Add a subtle shadow like the example
           BoxShadow(
             color: Colors.black26,
             blurRadius: 8,
             offset: Offset(0, 4),
           )
        ]
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: GoogleFonts.interTight( // tutorial: Use app's font or fallback
              fontWeight: FontWeight.bold,
              color: Colors.yellowAccent, // tutorial: Bright title color like example
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            description,
            style: GoogleFonts.interTight( // tutorial: Use app's font or fallback
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }


  // tutorial: Creates and shows the tutorial coach mark sequence.
  void _showTutorial() {
    // tutorial: Ensure targets are not empty and critical keys (like the first one) are likely available
     if (_targets.isEmpty || _keyQuestionTitle.currentContext == null) {
       print("Tutorial aborted: Targets not ready or context missing for initial items.");
       // tutorial: Optionally mark as seen even if aborted to prevent retries, or handle differently.
       // _markTutorialAsSeen();
       return;
     }

    _tutorialCoachMark = TutorialCoachMark(
      targets: _targets,
      // tutorial: Use a color from the theme for the shadow, similar to the example
      colorShadow: Colors.black.withOpacity(0.8),
      textSkip: "SKIP", // tutorial: Standard skip text
      paddingFocus: 5, // tutorial: Padding around the highlighted area
      opacityShadow: 0.8, // tutorial: Shadow opacity
      // tutorial: Apply blur effect like the example page
      imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      // tutorial: Custom Skip Button styled like the example page
       skipWidget: Container(
         padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
         decoration: BoxDecoration(
            color: Colors.redAccent, // tutorial: Consistent skip button color
            borderRadius: BorderRadius.circular(20),
         ),
         child: const Text("Skip All", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      onFinish: () {
        print("IQ Test Tutorial Finished");
        // tutorial: Mark as seen when finished
        _markTutorialAsSeen();
      },
      onClickTarget: (target) {
        print('onClickTarget: ${target.identify}');
        // tutorial: You could potentially add logic here, e.g., play a sound
      },
      onClickTargetWithTapPosition: (target, tapDetails) {
          print("target: ${target.identify}");
          print("clicked at position local: ${tapDetails.localPosition} - global: ${tapDetails.globalPosition}");
      },
      onClickOverlay: (target) {
        print('onClickOverlay: ${target.identify}');
        // tutorial: Advance to the next step when overlay is clicked
        // _tutorialCoachMark?.next(); // Be cautious with this, might conflict with target clicks
      },
      onSkip: () {
        print("IQ Test Tutorial Skipped");
        // tutorial: Also mark as seen if skipped
        _markTutorialAsSeen();
        return true; // tutorial: Return true to allow skip
      },
    )..show(context: context); // tutorial: Use cascade notation to show immediately
  }

  // tutorial: Saves a flag to SharedPreferences indicating the tutorial has been seen.
  void _markTutorialAsSeen() async {
     SharedPreferences prefs = await SharedPreferences.getInstance();
     await prefs.setBool(_tutorialPreferenceKey, true);
     print("Marked '$_tutorialPreferenceKey' as seen.");
  }
   // --- End Tutorial Functions ---


  @override
  Widget build(BuildContext context) {
    // tutorial: Ensure theme is loaded before building UI that depends on it
    final primaryColor = _currentTheme['primaryColor'] ?? const Color(0xFF049a02);
    final secondaryColor = _currentTheme['secondaryColor'] ?? Colors.yellow[50];
    final gradient = _currentTheme['gradient'] ?? [Colors.yellow[50]!, Colors.yellow[100]!];

    return ChangeNotifierProvider(
      create: (_) => IQTestViewModel(),
      child: Scaffold(
        backgroundColor: secondaryColor,
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: Text(
            'Kids IQ Test',
            style: GoogleFonts.interTight(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          elevation: 2,
           // tutorial: You could add a profile icon here and a key if needed for the tutorial later
           // actions: [ ... ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient as List<Color>, // Explicit cast
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Consumer<IQTestViewModel>(
              builder: (context, viewModel, child) {
                // tutorial: Ensure view model data is ready before building the main content
                if (viewModel.questions.isEmpty && !viewModel.isTestCompleted) {
                   // Show loading or placeholder if questions aren't ready
                   return const Center(child: CircularProgressIndicator());
                }
                if (viewModel.isTestCompleted) {
                  // tutorial: Tutorial won't show on the result screen, only on the question screen
                  return _buildResultScreen(context, viewModel);
                }
                // tutorial: Build the question screen where the tutorial keys will be attached
                return _buildQuestionScreen(context, viewModel);
              },
            ),
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          threadId: widget.threadId,
          currentIndex: 0,
          // tutorial: You could add a key to the bottom nav bar if needed for the tutorial
          // key: _keyBottomNav,
        ),
      ),
    );
  }

  Widget _buildQuestionScreen(BuildContext context, IQTestViewModel viewModel) {
    final question = viewModel.currentQuestion;

    // Avoid playing sound repeatedly if build is called multiple times due to state changes
    // Consider using a flag or checking player state if this becomes an issue
    // if (!viewModel.isAnswerSubmitted && !viewModel.isQuestionLocked(viewModel.currentQuestionIndex)) {
    //   _playInstruction('sounds/instruction_drag.mp3');
    // }

    double patternSize = MediaQuery.of(context).size.width * 0.30;
    double optionSize = MediaQuery.of(context).size.width * 0.20;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView( // Makes content scrollable if it overflows
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start, // Align items to top
                    children: [
                      // tutorial: Assign key to Question Title Text
                      Flexible( // Use Flexible to prevent overflow if text is long
                        child: Text(
                          "${viewModel.currentQuestionIndex + 1}. Question",
                           key: _keyQuestionTitle, // tutorial: Assign key here
                          style: GoogleFonts.interTight(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _currentTheme['accentColor'] ?? Colors.blue[800],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10), // Spacing
                      // tutorial: Assign key to the Row containing the score/stars
                      Row(
                        key: _keyScore, // tutorial: Assign key here
                        children: [
                          Text(
                            "Stars: ",
                            style: GoogleFonts.interTight(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _currentTheme['accentColor'] ?? Colors.blue[800],
                            ),
                          ),
                          // Animate stars appearance
                          ...List.generate(
                            viewModel.score,
                            (index) => TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0.5, end: 1), // Start slightly small
                              duration: Duration(milliseconds: 300 + index * 100), // Stagger animation
                              curve: Curves.elasticOut, // Bouncy effect
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: const Icon(Icons.star_rounded, color: Colors.amber, size: 26), // Rounded star
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(
                    // tutorial: Assign key to the Container wrapping the pattern
                    child: Container(
                        key: _keyPattern, // tutorial: Assign key here
                        child: _buildAnimatedPattern(question.pattern, patternSize.clamp(100, 250))
                    ),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    // tutorial: Assign key to Drag Target widget
                    child: DragTarget<int>(
                      key: _keyDragTarget, // tutorial: Assign key here
                      builder: (context, candidateData, rejectedData) {
                        // Enhanced visual feedback for drag target
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
                            color: Colors.grey.withOpacity(0.15), // Slightly transparent background
                            boxShadow: [ // Add glow effect
                               BoxShadow(
                                 color: glowColor,
                                 spreadRadius: isHovering ? 4 : 2,
                                 blurRadius: 8
                                )
                             ]
                          ),
                          child: Center(
                            child: viewModel.selectedOptionIndex != null
                                ? _buildGrid(question.options[viewModel.selectedOptionIndex!], patternSize.clamp(100, 250))
                                : Text( // Placeholder text
                                    "Drag Answer Here",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.interTight(
                                      fontSize: 18, // Adjusted size
                                      fontWeight: FontWeight.w600, // Semi-bold
                                      color: Colors.grey[700],
                                    ),
                                  ),
                          ),
                        );
                      },
                      // Only accept if the question isn't locked
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
                                   content: const Text("Almost there! Try once more next time!"),
                                   backgroundColor: _currentTheme['accentColor'] ?? Colors.red,
                                   duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating, // Floating snackbar
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
                  Text( // Instruction text
                    "Drag the correct answer to the box above:",
                    style: GoogleFonts.interTight(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: _currentTheme['accentColor'] ?? Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // GridView for draggable options
                  GridView.builder( // Use GridView.builder for potentially large lists
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(), // Disable scrolling within the grid
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // Number of columns
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.1, // Adjust aspect ratio for item size
                    ),
                    itemCount: question.options.length,
                    itemBuilder: (context, index) {
                       // tutorial: Assign key ONLY to the first option (index 0) for the tutorial target
                       final key = (index == 0) ? _keyOption : null;
                       return _buildDraggableOption(context, index, question, optionSize.clamp(80, 120), viewModel, key: key);
                    },
                  ),
                  const SizedBox(height: 20),
                  // tutorial: Assign key to the Container wrapping the progress tracker
                   Container(
                      key: _keyProgress, // tutorial: Assign key here
                      child: _buildProgressTracker(context, viewModel),
                   ),
                  const SizedBox(height: 20),
                  // Previous/Next Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       // Previous Button (no key needed for tutorial unless specified)
                      _buildAnimatedButton(
                        onPressed: viewModel.currentQuestionIndex > 0
                            ? () {
                                viewModel.goToQuestion(viewModel.currentQuestionIndex - 1);
                                _playSound('sounds/correct.mp3'); // Consider a different sound for navigation
                              }
                            : null, // Disabled if first question
                        icon: Icons.arrow_back_ios_new, // Updated icon
                        label: "Previous",
                        color: viewModel.currentQuestionIndex > 0
                            ? (_currentTheme['accentColor']?.withOpacity(0.8) ?? Colors.blue[700]!)
                            : Colors.grey.shade400, // Disabled color
                      ),
                      // tutorial: Assign key to the Container wrapping the Next button
                      Container(
                        key: _keyNextButton, // tutorial: Assign key here
                        child: _buildAnimatedButton(
                          onPressed: (viewModel.isAnswerSubmitted || viewModel.isQuestionLocked(viewModel.currentQuestionIndex))
                              ? () { // Only allow next if answered/locked
                                 viewModel.nextQuestion();
                                 _playSound('sounds/correct.mp3'); // Navigation sound
                                }
                              : null, // Disabled if not answered/locked
                          icon: Icons.arrow_forward_ios, // Updated icon
                          label: "Next",
                          color: (viewModel.isAnswerSubmitted || viewModel.isQuestionLocked(viewModel.currentQuestionIndex))
                              ? (_currentTheme['primaryColor'] ?? Colors.green)
                              : Colors.grey.shade400, // Disabled color
                        ),
                      ),
                    ],
                  ),
                   const SizedBox(height: 20), // Add some bottom padding
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

 // Updated Animated Button with better visual feedback and state management
 Widget _buildAnimatedButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
     // tutorial: This button widget itself doesn't need a key unless directly targeted
     // tutorial: Use ValueNotifier for local scale animation without rebuilding the whole state
     final ValueNotifier<double> scaleNotifier = ValueNotifier(1.0);

    return ValueListenableBuilder<double>(
        valueListenable: scaleNotifier,
        builder: (context, scale, child) {
           return GestureDetector(
             onTapDown: (_) {
               if (onPressed != null) {
                  scaleNotifier.value = 1.1; // Scale up on press down
               }
             },
             onTapUp: (_) {
                if (onPressed != null) {
                   scaleNotifier.value = 1.0; // Scale back down
                   onPressed(); // Execute action
                }
             },
             onTapCancel: () {
                scaleNotifier.value = 1.0; // Scale back down if tap is cancelled
             },
             child: Transform.scale(
               scale: scale,
               child: ElevatedButton.icon(
                 onPressed: onPressed, // Pass onPressed directly
                 icon: Icon(icon, size: 18), // Slightly smaller icon
                 label: Text(label, style: GoogleFonts.interTight(fontWeight: FontWeight.w600)),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: color,
                   foregroundColor: Colors.white,
                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), // Adjusted padding
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // More rounded
                   elevation: onPressed != null ? 4 : 0, // Add elevation when enabled
                   shadowColor: onPressed != null ? color.withOpacity(0.4) : Colors.transparent, // Shadow matches color
                   // Visual feedback for disabled state
                   disabledBackgroundColor: Colors.grey.shade300,
                   disabledForegroundColor: Colors.grey.shade600,
                 ),
               ),
             ),
           );
        },
     );
  }


  // Updated Draggable Option with key parameter and refined visuals
  Widget _buildDraggableOption(
      BuildContext context, int index, Question question, double size, IQTestViewModel viewModel, {GlobalKey? key}) { // tutorial: Accept optional key
    bool isLocked = viewModel.isQuestionLocked(viewModel.currentQuestionIndex);
    bool isSelected = viewModel.selectedOptionIndex == index;
    // Determine if this option is the correct one after submission
    bool isCorrect = isLocked && (index == question.correctOptionIndex);
    // Determine if this option was the incorrect one selected
    bool isIncorrectSelected = isLocked && isSelected && !isCorrect;

    // tutorial: Wrap the outermost widget with the key if provided
    return Container(
       key: key, // tutorial: Assign the key here if provided
       child: TweenAnimationBuilder(
          // tutorial: Animate entrance
          tween: Tween<double>(begin: 0.5, end: 1.0),
          duration: Duration(milliseconds: 500 + index * 100), // Staggered
          curve: Curves.easeOutBack,
          builder: (context, scaleValue, child) {
             return Transform.scale(
                scale: scaleValue,
                child: Opacity( // Fade in effect
                   opacity: scaleValue,
                   child: child,
                ),
             );
          },
          child: Draggable<int>(
             data: index,
             // Feedback widget (what is shown while dragging)
             feedback: Material(
               color: Colors.transparent,
               elevation: 8.0, // More pronounced shadow while dragging
               borderRadius: BorderRadius.circular(16), // Rounded feedback
               child: Transform.scale( // Slightly larger feedback
                 scale: 1.15,
                 child: Container(
                   width: size,
                   height: size,
                   decoration: BoxDecoration(
                     border: Border.all(color: _currentTheme['accentColor'] ?? Colors.blue, width: 3),
                     borderRadius: BorderRadius.circular(16),
                     boxShadow: [ // Softer shadow for feedback
                         BoxShadow(
                           color: (_currentTheme['accentColor'] ?? Colors.blue).withOpacity(0.4),
                           spreadRadius: 3,
                           blurRadius: 8,
                         ),
                       ],
                     // Semi-transparent background while dragging
                     color: Colors.white.withOpacity(0.8),
                   ),
                   child: ClipRRect(
                     borderRadius: BorderRadius.circular(14), // Consistent rounding
                     child: _buildGrid(question.options[index], size),
                   ),
                 ),
               ),
             ),
             // Child when dragging (placeholder left behind)
             childWhenDragging: Container(
               width: size,
               height: size,
               decoration: BoxDecoration(
                 border: Border.all(color: Colors.grey[300]!, width: 2),
                 borderRadius: BorderRadius.circular(16),
                 color: Colors.grey[200]?.withOpacity(0.5), // More subtle placeholder
               ),
             ),
             // Child widget (the actual option shown initially)
             child: AnimatedContainer( // Animate changes in appearance
                 duration: const Duration(milliseconds: 300),
                 width: size,
                 height: size,
                 decoration: BoxDecoration(
                   border: Border.all(
                     // Dynamic border based on state
                     color: isCorrect ? Colors.green.shade400 :
                            isIncorrectSelected ? Colors.red.shade400 :
                            isSelected ? (_currentTheme['accentColor'] ?? Colors.blue) :
                            Colors.grey[400]!,
                     width: isSelected || isLocked ? 3 : 2, // Thicker border if selected or locked
                   ),
                   borderRadius: BorderRadius.circular(16),
                   color: Colors.white.withOpacity(0.8), // Slightly transparent background
                   boxShadow: [ // Subtle shadow, more pronounced if selected
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
             // Only allow dragging if the question is not locked
             onDragStarted: isLocked ? null : () { _playSound('sounds/drag_start.mp3'); }, // Optional sound
              // Prevent dragging if locked
              maxSimultaneousDrags: isLocked ? 0 : 1,
           ),
       ),
    );
  }


  // Pattern Widget with animation
  Widget _buildAnimatedPattern(List<List<String>> pattern, double size) {
    // tutorial: The parent container already has the key (_keyPattern)
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 800), // Slightly faster animation
      curve: Curves.elasticOut, // Bouncy effect
      builder: (context, scaleValue, child) {
        return Transform.scale(
          scale: scaleValue,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: _currentTheme['accentColor'] ?? Colors.indigo, width: 3),
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withOpacity(0.7), // Background for the pattern
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
              borderRadius: BorderRadius.circular(14), // Inner clipping rounded
              child: _buildGrid(pattern, size),
            ),
          ),
        );
      },
    );
  }

  // Correct Answer Animation Overlay
  void _showCorrectAnswerAnimation(BuildContext context) {
     // tutorial: This function displays an overlay, not part of the main tutorial sequence
    OverlayState? overlayState = Overlay.of(context);
    OverlayEntry? entry;

    entry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: IgnorePointer( // Makes the overlay non-interactive
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Optional: Animated Confetti Background
              // Positioned.fill(
              //    child: CustomPaint(
              //       painter: ConfettiPainter(color: _currentTheme['primaryColor'] ?? Colors.yellow),
              //    ),
              // ),

               // Animated Star and Text
               Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   // Bouncing Star
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
                   // Fading & Scaling Text
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
                               "Awesome!", // Changed text
                               style: GoogleFonts.interTight(
                                 fontSize: 30,
                                 fontWeight: FontWeight.bold,
                                 color: Colors.white,
                               ),
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
    // Remove the overlay after a delay
    Future.delayed(const Duration(milliseconds: 2000), () {
        // Check if entry is still valid before removing
        entry?.remove();
        entry = null; // Help GC
    });
  }

   // Build Grid Cell (Image or Placeholder)
  Widget _buildGrid(List<List<String>> grid, [double size = 150]) {
     // tutorial: Helper function, not directly part of the tutorial sequence targets
     if (grid.isEmpty || grid[0].isEmpty) {
       return Container(color: Colors.grey[200], child: const Center(child: Text("?", style: TextStyle(fontSize: 40, color: Colors.grey)))); // Placeholder
     }
    String cell = grid[0][0]; // Assuming 1x1 grid structure based on usage

    return Container(
       color: Colors.white, // Ensure background for potentially transparent images
       width: size,
       height: size,
       child: cell == "?"
          ? const Center(
              child: Text(
                "?",
                style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            )
          : Image.asset(
              _getImagePath(cell),
              width: size,
              height: size,
              fit: BoxFit.contain, // Use contain to see the whole image
              // Add smooth loading effect
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
                print("Error loading image: $cell, $error"); // Log error
                return Container( // Error placeholder
                   color: Colors.red.shade50,
                   child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.red, size: 40),
                   ),
                );
              },
            ),
    );
  }

  // Get Image Path Helper
  String _getImagePath(String value) {
     // tutorial: Helper function, not directly part of the tutorial sequence targets
    // Ensure your asset paths are correct in pubspec.yaml and match these keys
    switch (value) {
      case "pencil_3l.png": return "assets/pencil_3l.png";
      case "pencil_2rd.png": return "assets/pencil_2rd.png";
      case "pencil_1r.png": return "assets/pencil_1r.png";
      case "pencil_3d.png": return "assets/pencil_3d.png";
      case "pencil_1l1d1r.png": return "assets/pencil_1l1d1r.png";
      case "cross_dots_pattern.png": return "assets/cross_dots_pattern.png";
      case "cross_dots_option_a.png": return "assets/cross_dots_option_a.png";
      case "cross_dots_option_b.png": return "assets/cross_dots_option_b.png";
      case "cross_dots_option_c.png": return "assets/cross_dots_option_c.png";
      case "cross_dots_option_d.png": return "assets/cross_dots_option_d.png";
      case "shape1_pattern.png": return "assets/shape1_pattern.png";
      case "shape1_option_a.png": return "assets/shape1_option_a.png";
      case "shape1_option_b.png": return "assets/shape1_option_b.png";
      case "shape1_option_c.png": return "assets/shape1_option_c.png";
      case "shape1_option_d.png": return "assets/shape1_option_d.png";
      case "colored_grid_pattern.png": return "assets/colored_grid_pattern.png";
      case "colored_grid_option_a.png": return "assets/colored_grid_option_a.png";
      case "colored_grid_option_b.png": return "assets/colored_grid_option_b.png";
      case "colored_grid_option_c.png": return "assets/colored_grid_option_c.png";
      case "colored_grid_option_d.png": return "assets/colored_grid_option_d.png";
      case "colored_squares_pattern.png": return "assets/colored_squares_pattern.png";
      case "colored_squares_option_a.png": return "assets/colored_squares_option_a.png";
      case "colored_squares_option_b.png": return "assets/colored_squares_option_b.png";
      case "colored_squares_option_c.png": return "assets/colored_squares_option_c.png";
      case "colored_squares_option_d.png": return "assets/colored_squares_option_d.png";
      case "colored_shapes_pattern.png": return "assets/colored_shapes_pattern.png";
      case "colored_shapes_option_a.png": return "assets/colored_shapes_option_a.png";
      case "colored_shapes_option_b.png": return "assets/colored_shapes_option_b.png";
      case "colored_shapes_option_c.png": return "assets/colored_shapes_option_c.png";
      case "colored_shapes_option_d.png": return "assets/colored_shapes_option_d.png";
      case "number_sequence_pattern.png": return "assets/number_sequence_pattern.png";
      case "number_sequence_option_a.png": return "assets/number_sequence_option_a.png";
      case "number_sequence_option_b.png": return "assets/number_sequence_option_b.png";
      case "number_sequence_option_c.png": return "assets/number_sequence_option_c.png";
      case "number_sequence_option_d.png": return "assets/number_sequence_option_d.png";
      default:
       print("Warning: Image path not found for '$value'. Using placeholder.");
       return "assets/placeholder.png"; // Make sure you have a placeholder asset
    }
  }

   // Build Progress Tracker Row
  Widget _buildProgressTracker(BuildContext context, IQTestViewModel viewModel) {
    // tutorial: The parent container has the key (_keyProgress)
    final rainbowColors = [ // More vibrant rainbow colors
      Colors.redAccent, Colors.orangeAccent, Colors.yellow.shade600, Colors.lightGreenAccent.shade700, Colors.blueAccent, Colors.indigoAccent, Colors.purpleAccent,
    ];
    final double itemSize = 40; // Size of each circle

    return SizedBox(
      height: itemSize + 10, // Height to accommodate circle + margin
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: viewModel.questions.length,
        padding: const EdgeInsets.symmetric(horizontal: 8), // Padding for the list ends
        itemBuilder: (context, index) {
          bool isCurrent = viewModel.currentQuestionIndex == index;
          bool isAnswered = viewModel.isQuestionLocked(index);
          bool isCorrect = isAnswered && (viewModel.answeredQuestions[index] == viewModel.questions[index].correctOptionIndex);

          Color circleColor;
          IconData? statusIcon;

          // Determine color and icon based on state
          if (isAnswered) {
             circleColor = isCorrect ? Colors.green.shade400 : Colors.orange.shade400;
             statusIcon = isCorrect ? Icons.check_circle_outline : Icons.cancel_outlined;
          } else if (isCurrent) {
             circleColor = _currentTheme['accentColor']?.withOpacity(0.9) ?? Colors.blue.shade400;
             statusIcon = Icons.edit_outlined; // Icon indicating current editable question
          } else {
             circleColor = rainbowColors[index % rainbowColors.length].withOpacity(0.6); // Rainbow color for unanswered
          }

          return GestureDetector(
            onTap: () {
              // Allow navigation only if the question has been answered or is reachable
              if (isAnswered || index <= viewModel.currentQuestionIndex) {
                 viewModel.goToQuestion(index);
              } else {
                 // Maybe show a snackbar indicating they need to answer previous ones
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                       content: Text("Reach question ${index + 1} first!"),
                       duration: const Duration(seconds: 1),
                       behavior: SnackBarBehavior.floating,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                       margin: const EdgeInsets.all(10),
                       ),
                  );
              }
            },
            child: Tooltip( // Add tooltip for accessibility/info
              message: isAnswered ? (isCorrect ? "Question ${index + 1}: Correct" : "Question ${index + 1}: Incorrect") : "Question ${index + 1}",
              child: TweenAnimationBuilder(
                 tween: Tween<double>(begin: 1.0, end: isCurrent ? 1.15 : 1.0), // Scale up current item
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
                         border: isCurrent ? Border.all(color: Colors.white, width: 2.5) : null, // Highlight current
                         boxShadow: [ // Add shadow for depth
                             BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 3,
                                offset: const Offset(1, 2),
                             ),
                          ],
                       ),
                       child: Center(
                         child: statusIcon != null
                             ? Icon(statusIcon, color: Colors.white, size: 20) // Show status icon
                             : Text( // Show number if no status icon
                                 "${index + 1}",
                                 style: const TextStyle(
                                   color: Colors.white,
                                   fontWeight: FontWeight.bold,
                                   fontSize: 16,
                                 ),
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

   // Build Result Screen
  Widget _buildResultScreen(BuildContext context, IQTestViewModel viewModel) {
     // tutorial: This screen appears after the test, tutorial won't trigger here.
    double percentage = viewModel.questions.isNotEmpty ? (viewModel.score / viewModel.questions.length) * 100 : 0;
    String iqCategory = viewModel.getIQCategory();
    Color categoryColor;
    IconData categoryIcon;
    String celebrationLottie;

    // Determine color, icon, and Lottie animation based on category
     switch (iqCategory) {
       case "Super Star":
         categoryColor = Colors.green.shade600;
         categoryIcon = Icons.emoji_events; // Trophy
         celebrationLottie = 'https://assets1.lottiefiles.com/packages/lf20_touohxv0.json'; // Confetti/Trophy Lottie
         break;
       case "Great Explorer":
         categoryColor = _currentTheme['accentColor'] ?? Colors.blue.shade600;
         categoryIcon = Icons.explore; // Binoculars/Map
         celebrationLottie = 'https://assets5.lottiefiles.com/packages/lf20_a3kesdek.json'; // Stars/Success Lottie
         break;
       default: // "Rising Talent" or others
         categoryColor = Colors.orange.shade600;
         categoryIcon = Icons.auto_awesome; // Sparkles
         celebrationLottie = 'https://assets9.lottiefiles.com/packages/lf20_l4fgppor.json'; // Simple success/thumbs up Lottie
         break;
     }

    return Stack(
      children: [
        // Background Confetti Painter
         Positioned.fill(
            child: IgnorePointer(
               child: CustomPaint(
                 painter: ConfettiPainter(color: _currentTheme['primaryColor'] ?? Colors.yellow),
                 size: Size.infinite,
                ),
            ),
         ),
          // Optional: Centered Lottie Animation behind the card
         Positioned.fill(
             child: Center(
                child: Lottie.network(
                   celebrationLottie,
                   height: MediaQuery.of(context).size.height * 0.5, // Adjust size
                   repeat: false, // Play once
                ),
             ),
          ),

         // Main Result Card
         Center(
           child: TweenAnimationBuilder(
             tween: Tween<double>(begin: 0.5, end: 1.0), // Scale-in animation
             duration: const Duration(milliseconds: 800),
             curve: Curves.elasticOut,
             builder: (context, scaleValue, child) {
               return Transform.scale(
                 scale: scaleValue,
                 child: Card(
                   elevation: 12, // Increased elevation
                   margin: const EdgeInsets.symmetric(horizontal: 20),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                   color: (_currentTheme['secondaryColor'] ?? Colors.white).withOpacity(0.98), // More opaque card
                   child: Container(
                     width: MediaQuery.of(context).size.width * 0.85,
                     padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Icon(categoryIcon, size: 60, color: categoryColor), // Larger Icon
                         const SizedBox(height: 15),
                         Text(
                           "Test Completed!",
                           textAlign: TextAlign.center,
                           style: GoogleFonts.interTight(
                             fontSize: 30, // Larger title
                             fontWeight: FontWeight.bold,
                             color: _currentTheme['primaryColor'] ?? Colors.green.shade800,
                           ),
                         ),
                         const SizedBox(height: 25),
                         // Animated score text
                         TweenAnimationBuilder(
                           tween: IntTween(begin: 0, end: viewModel.score),
                           duration: const Duration(seconds: 2),
                            curve: Curves.easeOutCubic,
                           builder: (context, int currentScore, child) {
                             return Text(
                               "Your Score: $currentScore / ${viewModel.questions.length}",
                               style: GoogleFonts.interTight(
                                 fontSize: 24, // Larger score text
                                 fontWeight: FontWeight.w600,
                                 color: _currentTheme['accentColor'] ?? Colors.blue.shade800,
                               ),
                             );
                           },
                         ),
                         const SizedBox(height: 20),
                         // Animated stars row
                         Row(
                           mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                               viewModel.score.clamp(0, 5), // Show up to 5 stars max for visual consistency
                               (index) => TweenAnimationBuilder(
                                 tween: Tween<double>(begin: 0.5, end: 1.0), // Star scale animation
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
                                              )
                                           ],
                                        ),
                                      ),
                                   );
                                 },
                               ),
                            ),
                         ),
                         const SizedBox(height: 25),
                         // Category display chip
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Slightly larger padding
                           decoration: BoxDecoration(
                             color: categoryColor.withOpacity(0.15),
                             borderRadius: BorderRadius.circular(30),
                             border: Border.all(color: categoryColor, width: 2.5), // Thicker border
                           ),
                           child: Text(
                             "You’re a $iqCategory!",
                             textAlign: TextAlign.center,
                             style: GoogleFonts.interTight(
                               fontSize: 22, // Larger category text
                               fontWeight: FontWeight.bold,
                               color: categoryColor,
                             ),
                           ),
                         ),
                         const SizedBox(height: 35),
                         // Play Again button
                         _buildAnimatedButton(
                           onPressed: () {
                              viewModel.resetTest();
                              _playSound('sounds/correct.mp3'); // Reset/start sound
                           },
                           icon: Icons.replay_rounded,
                           label: "Play Again",
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


// Confetti Painter (no changes needed from previous version)
class ConfettiPainter extends CustomPainter {
   // tutorial: Helper class, not directly part of the tutorial targets
  final math.Random random = math.Random();
  final Color? color; // Base color for confetti

  ConfettiPainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
     final List<Color> baseColors = color != null
         ? [ // Generate variations based on input color
             color!,
             HSLColor.fromColor(color!).withLightness((HSLColor.fromColor(color!).lightness * 0.8).clamp(0.0, 1.0)).toColor(),
             HSLColor.fromColor(color!).withSaturation((HSLColor.fromColor(color!).saturation * 1.2).clamp(0.0, 1.0)).toColor(),
             Colors.white.withOpacity(0.8), // Add semi-transparent white
           ]
         : [ // Default fallback colors
             Colors.redAccent, Colors.blueAccent, Colors.greenAccent, Colors.yellowAccent, Colors.purpleAccent, Colors.orangeAccent, Colors.white
            ];


    for (int i = 0; i < 100; i++) { // Number of confetti pieces
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      double confettiWidth = random.nextDouble() * 8 + 4; // Random width
      double confettiHeight = random.nextDouble() * 12 + 6; // Random height
      double angle = random.nextDouble() * math.pi; // Random rotation


      // Pick a random color from the palette
      paint.color = baseColors[random.nextInt(baseColors.length)].withOpacity(0.6 + random.nextDouble() * 0.4); // Vary opacity

       // Save canvas state, translate, rotate, draw, and restore
       canvas.save();
       canvas.translate(x, y);
       canvas.rotate(angle);
       // Draw slightly rounded rectangles for softer confetti
       canvas.drawRRect(
          RRect.fromRectAndRadius(
             Rect.fromLTWH(-confettiWidth / 2, -confettiHeight / 2, confettiWidth, confettiHeight),
             Radius.circular(2), // Small radius for rounded corners
          ),
          paint);
       canvas.restore();
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true; // Keep animating if needed (e.g., for dynamic confetti)
}