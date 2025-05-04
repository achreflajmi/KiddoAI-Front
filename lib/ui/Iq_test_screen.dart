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
import 'dart:ui';
import 'HomePage.dart'; 
import 'dart:math' as math;
// Added for DashedBorderPainter (assuming this import is needed)
import 'package:flutter/rendering.dart';
import 'Home.dart';


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

   String _currentAvatarName = 'Gumball';
  String _avatarImage = 'assets/avatars/Gumball.png';
  Color _currentAvatarColor = const Color(0xFF2196F3);
  List<Color> _currentAvatarGradient = [
    const Color.fromARGB(255, 48, 131, 198),
    const Color(0xFFE3F2FD),
  ];

  // --- Theme Definition (_characterThemes Map) ---
  // Lines 40-78: Refined color palettes, added gradients, and NEW textColor and buttonTextColor keys.
  final Map<String, Map<String, dynamic>> _characterThemes = {
    'SpongeBob': {
      'primaryColor': const Color(0xFFFFD700), // Brighter Gold
      'secondaryColor': const Color(0xFFFFFACD), // Lemon Chiffon
      'accentColor': const Color(0xFF00BFFF), // Deep Sky Blue
      'gradient': const [Color(0xFFFFEA80), Color(0xFFFFD700)],
      'textColor': Colors.brown[700], // Dark Brown text
      'buttonTextColor': Colors.white,
    },
    'Gumball': {
      'primaryColor': const Color(0xFF1E90FF), // Dodger Blue
      'secondaryColor': const Color(0xFFE0FFFF), // Light Cyan
      'accentColor': const Color(0xFFFFA500), // Orange
      'gradient': const [Color(0xFF87CEFA), Color(0xFF1E90FF)], // LightSkyBlue to DodgerBlue
      'textColor': Colors.blueGrey[800],
      'buttonTextColor': Colors.white,
    },
    'SpiderMan': {
      'primaryColor': const Color(0xFFE50914), // Netflix Red
      'secondaryColor': const Color(0xFFFFF0F5), // Lavender Blush
      'accentColor': const Color(0xFF007AFF), // Apple Blue
      'gradient': const [Color(0xFFFF6B6B), Color(0xFFE50914)], // Light Red to Netflix Red
      'textColor': const Color(0xFF2A2A2A), // Very Dark Grey
      'buttonTextColor': Colors.white,
    },
    'HelloKitty': {
      'primaryColor': const Color(0xFFFF69B4), // Hot Pink
      'secondaryColor': const Color(0xFFFFF5FB), // Pink Lavender
      'accentColor': const Color(0xFFFF1493), // Deep Pink
      'gradient': const [Color(0xFFFFB6C1), Color(0xFFFF69B4)], // Light Pink to Hot Pink
      'textColor': Colors.pink[800],
      'buttonTextColor': Colors.white,
    },
    // Default theme if avatar not found
    'Default': {
      'primaryColor': const Color(0xFF4CAF50), // Green
      'secondaryColor': const Color(0xFFE8F5E9), // Light Green
      'accentColor': const Color(0xFF2196F3), // Blue
      'gradient': const [Color(0xFFA5D6A7), Color(0xFF4CAF50)], // Light Green to Green
      'textColor': Colors.black87,
      'buttonTextColor': Colors.white,
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
        // Use Default if avatar name not in themes
        _currentTheme = _characterThemes["Gumball"] ?? _characterThemes['Default']!;
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

// --- Tutorial Styling (_initTargets) ---
// Lines 127-132: Defined specific TextStyles using GoogleFonts.changa for tutorial text.
final tutorialTextStyle = GoogleFonts.changa( // Use a playful, readable font
  color: Colors.white,
  fontSize: 16,
  fontWeight: FontWeight.w500, // Slightly bolder for readability
);
final tutorialTitleStyle = GoogleFonts.changa( // Style for tutorial title
  fontSize: 20,
  fontWeight: FontWeight.bold,
  color: Colors.yellowAccent, // Make title stand out
);

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
    // Ensure _keyOption is assigned to the first option in GridView.builder
    // If GridView might be empty initially, this key needs careful handling.
     WidgetsBinding.instance.addPostFrameCallback((_) {
       if (_keyOption.currentContext != null) {
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
       }
     });


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
    // Ensure _keyNextButton is assigned correctly.
    // Need to add this key inside _buildQuestionScreen if not already present.
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
    // Use the current theme's accent color, falling back to deep purple if not available
    final accentColor = _currentTheme['accentColor'] as Color? ?? Colors.deepPurple;

    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 20.0, left: 20.0, right: 20.0),
      // Lines 141-149: Applied new styles and updated container styling in buildTutorialContent.
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.95), // Use theme accent color with opacity
        borderRadius: BorderRadius.circular(16.0), // More rounded corners
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end, // Keep RTL alignment
        children: <Widget>[
          Text(
            title,
            style: tutorialTitleStyle, // Applied title style
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 10.0),
          Text(
            description,
            style: tutorialTextStyle, // Applied description style
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  void _showTutorial() {
    if (_targets.isEmpty || _keyQuestionTitle.currentContext == null) {
      print("Tutorial aborted: Targets not ready or context missing for initial items.");
      // Try initializing targets again just in case keys weren't ready initially
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _initTargets();
          if (_targets.isNotEmpty && _keyQuestionTitle.currentContext != null) {
             _showTutorialInternal(); // Call internal show method
          } else {
             print("Tutorial aborted (second attempt): Targets still not ready.");
             _markTutorialAsSeen(); // Avoid getting stuck if tutorial can't show
          }
        }
      });
      return;
    }
     _showTutorialInternal(); // Call internal show method
  }

  void _showTutorialInternal() {
     // Ensure _currentTheme is loaded before accessing colors for skipWidget
    if (_currentTheme.isEmpty) {
      print("Tutorial show aborted: Theme not loaded yet.");
      // Optionally retry after a delay or mark as seen
      // Future.delayed(Duration(milliseconds: 100), () => _showTutorial());
      _markTutorialAsSeen();
      return;
    }

    _tutorialCoachMark = TutorialCoachMark(
      targets: _targets,
      colorShadow: Colors.black.withOpacity(0.8),
      textSkip: "تخطَ", // Already translated
      paddingFocus: 5,
      opacityShadow: 0.8,
      imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      // Lines 175-186: Updated skip button styling (color, rounding, shadow, font).
      skipWidget: Container( // More appealing skip button
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.redAccent.shade400, // Slightly deeper red
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 5,
                offset: const Offset(0, 2))
          ],
        ),
        child: Text(
          "تخطَ الكل",
          style: GoogleFonts.changa( // Use consistent font
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
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
    // Fallback to Default theme if _currentTheme is somehow empty
    final themeMap = _currentTheme.isNotEmpty ? _currentTheme : _characterThemes['Default']!;
    final primaryColor = themeMap['primaryColor'] as Color;
    final secondaryColor = themeMap['secondaryColor'] as Color;
    final textColor = themeMap['textColor'] as Color?; // Nullable
    final buttonTextColor = themeMap['buttonTextColor'] as Color;
    final gradient = themeMap['gradient'] as List<Color>? ?? [secondaryColor, secondaryColor]; // Fallback gradient

    // --- Main Build Method (Theme Setup) ---
    // Lines 198-207: Defined base TextStyles using GoogleFonts.changa and theme colors.
    final baseTextStyle = GoogleFonts.changa( // Using a child-friendly font
      color: textColor ?? Colors.black87, // Fallback color
      fontSize: 18,
    );
    final titleTextStyle = baseTextStyle.copyWith(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: primaryColor, // Use primary color for titles
    );
    final scoreTextStyle = baseTextStyle.copyWith( // This specific style doesn't seem directly used below, but defined here
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: themeMap['accentColor'] as Color? ?? _characterThemes['Default']!['accentColor'],
    );
    final buttonTextStyle = GoogleFonts.changa(
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: buttonTextColor,
    );

    // Lines 209-232: Created and configured ThemeData using defined styles and colors.
    final themeData = Theme.of(context).copyWith(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        secondary: themeMap['accentColor'] as Color? ?? _characterThemes['Default']!['accentColor'],
        background: secondaryColor,
        brightness: Brightness.light,
         // Ensure text colors contrast with background if needed
        onBackground: textColor ?? (ThemeData.estimateBrightnessForColor(secondaryColor) == Brightness.dark ? Colors.white : Colors.black),
        onPrimary: buttonTextColor,
        onSecondary: buttonTextColor, // Assuming accent color buttons also use buttonTextColor
      ),
      textTheme: TextTheme( // Applied Changa font to textTheme
        displayLarge: titleTextStyle, // For main titles
        headlineMedium: titleTextStyle.copyWith(fontSize: 22), // For section titles
        bodyLarge: baseTextStyle, // For body text
        bodyMedium: baseTextStyle.copyWith(fontSize: 16), // For smaller text
        labelLarge: buttonTextStyle, // For button text
      ),
      scaffoldBackgroundColor: secondaryColor,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: buttonTextColor, // Color for icons and title
        elevation: 4.0, // Add subtle shadow
        titleTextStyle: GoogleFonts.changa( // Applied Changa to AppBar title
          color: buttonTextColor,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true, // Center align title
      ),
      cardTheme: CardTheme( // Themed Card appearance
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        color: secondaryColor.withOpacity(0.95),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Standard card margin
      ),
      elevatedButtonTheme: ElevatedButtonThemeData( // Themed ElevatedButton
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: buttonTextColor,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16), // Generous padding
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // Very rounded
          textStyle: buttonTextStyle, // Applied Changa button style
          elevation: 5,
          shadowColor: primaryColor.withOpacity(0.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData( // Themed SnackBar
         backgroundColor: themeMap['accentColor'] as Color? ?? Colors.blue,
         contentTextStyle: baseTextStyle.copyWith(color: Colors.white), // Applied Changa font
         behavior: SnackBarBehavior.floating,
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
         elevation: 6,
         //margin: const EdgeInsets.all(15),
      )
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ChangeNotifierProvider(
        create: (_) => IQTestViewModel(),
        // Line 237: Applied the created themeData using Theme widget.
        child: Theme( // Apply the customized theme
          data: themeData,
          child: Scaffold(
            // Note: Scaffold background color is now set by themeData.scaffoldBackgroundColor
            appBar: AppBar(
              // Properties are now set by themeData.appBarTheme
              title: Text('اختبار الذكاء للأطفال'), // Text style from themeData.appBarTheme.titleTextStyle
              // elevation from themeData.appBarTheme.elevation etc.
            ),
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient, // Use gradient from theme map
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Consumer<IQTestViewModel>(
                  builder: (context, viewModel, child) {
                    // Ensure theme is loaded before building UI dependent on it
                    if (_currentTheme.isEmpty) {
                       return const Center(child: CircularProgressIndicator());
                    }
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
            bottomNavigationBar: null,
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionScreen(BuildContext context, IQTestViewModel viewModel) {
    final question = viewModel.currentQuestion;
    final theme = Theme.of(context); // Use the applied theme
    double patternSize = MediaQuery.of(context).size.width * 0.30;
    double optionSize = MediaQuery.of(context).size.width * 0.25; // Adjusted slightly for better spacing maybe

    // Line 261: Switched Column to ListView for scrollability.
    return ListView( // Use ListView for implicit scrolling if content overflows
      padding: const EdgeInsets.all(16.0), // Apply padding here instead of inner Column
      children: [
         Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             // Score Display (RTL: Right side)
             Row(
               key: _keyScore,
               children: [
                 // Line 267-272: Applied themed text style to score text.
                 Text(
                   "النجوم: ",
                   style: theme.textTheme.bodyLarge?.copyWith( // Applied theme style (Changa)
                     fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary // Use accent color
                   ),
                   textDirection: TextDirection.rtl,
                 ),
                 ...List.generate(
                   viewModel.score,
                   // Lines 276-285: Added shadows to stars and increased size.
                   (index) => TweenAnimationBuilder<double>(
                     tween: Tween<double>(begin: 0.5, end: 1),
                     duration: Duration(milliseconds: 300 + index * 100),
                     curve: Curves.elasticOut,
                     builder: (context, value, child) {
                       return Transform.scale(
                         scale: value,
                         child: Icon(
                             Icons.star_rounded,
                             color: Colors.amber.shade600, // Brighter amber
                             size: 30, // Slightly larger stars
                             shadows: [ // Added shadow
                               Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 3, offset: const Offset(1,1))
                             ],
                         ),
                       );
                     },
                   ),
                 ),
               ],
             ),
             // Question Title (RTL: Left side)
             Flexible(
               // Lines 290-297: Applied themed text style to question title.
               child: Text(
                 "السؤال ${viewModel.currentQuestionIndex + 1}",
                 key: _keyQuestionTitle,
                 style: theme.textTheme.headlineMedium, // Use headline style (Changa)
                 textAlign: TextAlign.left, // Align to the start (left in RTL)
                 textDirection: TextDirection.rtl,
               ),
             ),
           ],
         ),
         const SizedBox(height: 20),
         Center(
           child: Container(
             key: _keyPattern,
             child: _buildAnimatedPattern(question.pattern, patternSize.clamp(100, 250)),
           ),
         ),
         const SizedBox(height: 40),
         Center(
           // Lines 310-361: Major visual update to DragTarget using BoxDecoration, CustomPaint, DashedBorderPainter, animations, and increased rounding.
           child: DragTarget<int>(
             key: _keyDragTarget,
             builder: (context, candidateData, rejectedData) {
               bool isHovering = candidateData.isNotEmpty;
               bool hasSelection = viewModel.selectedOptionIndex != null;
               bool isLocked = viewModel.isQuestionLocked(viewModel.currentQuestionIndex);

               Color backgroundColor = Colors.grey.withOpacity(0.15);
               Color borderColor = Colors.grey.shade400;
               Color glowColor = Colors.transparent;
               double borderWidth = 2.0;
               List<double>? dashPattern = [5, 5]; // Default dash pattern

               if (hasSelection) {
                 final bool isCorrect = viewModel.selectedOptionIndex == question.correctOptionIndex;
                 if (isLocked) {
                   borderColor = isCorrect ? Colors.green.shade600 : Colors.red.shade600;
                   borderWidth = 3.0;
                   glowColor = borderColor.withOpacity(0.4);
                   dashPattern = null; // Solid border when locked
                   backgroundColor = isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1);
                 } else {
                   // Selected but not locked (shouldn't happen with auto-lock?)
                   borderColor = theme.colorScheme.secondary;
                   borderWidth = 3.0;
                   glowColor = theme.colorScheme.secondary.withOpacity(0.3);
                 }
               } else if (isHovering && !isLocked) {
                 borderColor = theme.colorScheme.secondary;
                 borderWidth = 3.0;
                 glowColor = theme.colorScheme.secondary.withOpacity(0.4);
                 dashPattern = [8, 4]; // Different dash pattern on hover
                 backgroundColor = theme.colorScheme.secondary.withOpacity(0.1);
               } else {
                 // Default state (empty, not hovered)
                 borderColor = theme.colorScheme.secondary.withOpacity(0.7);
               }

               double dragTargetSize = patternSize.clamp(100, 250);

               return AnimatedContainer(
                 duration: const Duration(milliseconds: 350),
                 curve: Curves.easeInOut,
                 width: dragTargetSize,
                 height: dragTargetSize,
                 decoration: BoxDecoration( // Use BoxDecoration for solid background and shadow
                   color: hasSelection ? Colors.white.withOpacity(0.7) : backgroundColor,
                   borderRadius: BorderRadius.circular(20), // More rounded
                   boxShadow: [
                     BoxShadow(
                       color: glowColor,
                       spreadRadius: isHovering || isLocked ? 4 : 2,
                       blurRadius: 10,
                     ),
                   ],
                 ),
                 child: CustomPaint( // Draw dashed border using CustomPaint
                   painter: DashedBorderPainter( // NEW Painter used (Ensure this class is defined)
                     color: borderColor,
                     strokeWidth: borderWidth,
                     radius: 20,
                     dashPattern: dashPattern,
                   ),
                   child: Center(
                     child: hasSelection
                         ? Padding( // Add padding around the placed item
                             padding: const EdgeInsets.all(4.0),
                             child: _buildGrid(question.options[viewModel.selectedOptionIndex!], dragTargetSize - 8), // Adjust size slightly
                           )
                         : Text( // Placeholder text styling
                             "اسحب الإجابة هنا",
                             textAlign: TextAlign.center,
                             style: theme.textTheme.bodyMedium?.copyWith( // Themed style (Changa)
                                 color: Colors.grey[600],
                                 fontWeight: FontWeight.w600),
                             textDirection: TextDirection.rtl,
                           ),
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
                       // SnackBar styling now comes from theme.snackBarTheme
                       content: const Text(
                         "قريب جدًا! حاول مرة أخرى في المرة القادمة!",
                         textDirection: TextDirection.rtl,
                       ),
                       duration: const Duration(seconds: 1),
                       // other properties like background, shape, margin from theme
                     ),
                   );
                 }
               }
             },
           ),
         ),
         const SizedBox(height: 30),
         // Lines 379-385: Applied themed style and centered instruction text.
         Text(
           "اسحب الإجابة الصحيحة إلى الصندوق أعلاه:",
           style: theme.textTheme.bodyLarge?.copyWith( // Applied theme style (Changa)
             fontWeight: FontWeight.w500,
              color: theme.colorScheme.secondary // Use accent color
           ),
           textAlign: TextAlign.center, // Center instruction
           textDirection: TextDirection.rtl,
         ),
         const SizedBox(height: 20),
         GridView.builder(
           shrinkWrap: true, // Important inside ListView
           physics: const NeverScrollableScrollPhysics(), // Important inside ListView
           // Lines 391-395: Increased spacing and set aspect ratio for GridView options.
           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
             crossAxisCount: 2, // Keep 2 options per row
             mainAxisSpacing: 20, // Increased spacing
             crossAxisSpacing: 20, // Increased spacing
             childAspectRatio: 1.0, // Make options square
           ),
           itemCount: question.options.length,
           itemBuilder: (context, index) {
             // Assign key to first option for tutorial if needed
             final key = (index == 0 && _keyOption.currentContext == null) ? _keyOption : null;
             return _buildDraggableOption(context, index, question, optionSize.clamp(80, 150), viewModel, key: key);
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
             // Next Button (RTL: Right side)
             Container(
               key: _keyNextButton, // Ensure key is assigned
               child: _buildAnimatedButton(
                 onPressed: (viewModel.isAnswerSubmitted || viewModel.isQuestionLocked(viewModel.currentQuestionIndex))
                     ? () {
                         viewModel.nextQuestion();
                         _playSound('sounds/correct.mp3');
                       }
                     : null,
                 icon: Icons.arrow_back_ios_new, // RTL: "Next" points left
                 label: "التالي",
                 color: theme.primaryColor, // Use theme's primary color for active state
                 // Disabled state color will be handled by the button itself using theme
                 textColor: theme.textTheme.labelLarge?.color, // Get button text color from theme
               ),
             ),
              // Previous Button (RTL: Left side)
             _buildAnimatedButton(
               onPressed: viewModel.currentQuestionIndex > 0
                   ? () {
                       viewModel.goToQuestion(viewModel.currentQuestionIndex - 1);
                       _playSound('sounds/correct.mp3');
                     }
                   : null,
               icon: Icons.arrow_forward_ios, // RTL: "Previous" points right
               label: "السابق",
               color: theme.colorScheme.secondary.withOpacity(0.9), // Use theme's accent color
               textColor: theme.textTheme.labelLarge?.color, // Get button text color from theme
             ),
           ],
         ),
         const SizedBox(height: 20), // Add some padding at the bottom
       ],
    );
  }

  // --- Animated Button Styling (_buildAnimatedButton) ---
  // Lines 423-460: Refactored to heavily rely on ElevatedButtonThemeData from the main theme for consistent styling (including font), handling disabled states, and adding press animations.
  Widget _buildAnimatedButton({
      required VoidCallback? onPressed,
      required IconData icon,
      required String label,
      required Color color, // This color is now used for the ACTIVE state background
      Color? textColor, // Optional override for text color, defaults to theme
  }) {
      final theme = Theme.of(context);
      final scaleNotifier = ValueNotifier<double>(1.0);

      return ValueListenableBuilder<double>(
          valueListenable: scaleNotifier,
          builder: (context, scale, child) {
              return GestureDetector(
                  onTapDown: (_) {
                      if (onPressed != null) scaleNotifier.value = 0.95; // Scale down slightly
                  },
                  onTapUp: (_) {
                      if (onPressed != null) {
                          // Delay slightly before scaling back up to let the press feedback register
                          Future.delayed(const Duration(milliseconds: 100), () {
                             if (mounted) scaleNotifier.value = 1.0; // Scale back up
                          });
                          onPressed(); // Trigger action
                      } else {
                         scaleNotifier.value = 1.0; // Ensure scale resets if disabled
                      }
                  },
                  onTapCancel: () {
                      scaleNotifier.value = 1.0; // Scale back up if tap is cancelled
                  },
                  child: Transform.scale(
                      scale: scale,
                      child: ElevatedButton.icon(
                          onPressed: onPressed,
                          icon: Icon(icon, size: 20), // Slightly larger icon
                          label: Text(label), // Text style applied by theme
                          style: theme.elevatedButtonTheme.style?.copyWith( // Start with theme style
                              backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                                  (Set<MaterialState> states) {
                                      if (states.contains(MaterialState.disabled)) {
                                          // Use theme's disabled color if available, else fallback
                                          return theme.elevatedButtonTheme.style?.backgroundColor?.resolve({MaterialState.disabled})
                                                 ?? Colors.grey.shade300; // Custom disabled background
                                      }
                                      // Use the provided color for active state
                                      return color;
                                  },
                              ),
                              foregroundColor: MaterialStateProperty.resolveWith<Color?>(
                                  (Set<MaterialState> states) {
                                      if (states.contains(MaterialState.disabled)) {
                                           // Use theme's disabled foreground color if available, else fallback
                                          return theme.elevatedButtonTheme.style?.foregroundColor?.resolve({MaterialState.disabled})
                                                 ?? Colors.grey.shade600; // Custom disabled foreground
                                      }
                                      // Use provided textColor or fallback to theme's button text color
                                      return textColor ?? theme.textTheme.labelLarge?.color ?? Colors.white;
                                  },
                              ),
                              elevation: MaterialStateProperty.resolveWith<double?>(
                                  (Set<MaterialState> states) {
                                      final baseElevation = theme.elevatedButtonTheme.style?.elevation?.resolve({}) ?? 5;
                                      if (states.contains(MaterialState.disabled)) return 0;
                                      if (states.contains(MaterialState.pressed)) return baseElevation + 3; // Higher elevation when pressed
                                      return baseElevation; // Default elevation
                                  }
                              ),
                              shadowColor: MaterialStateProperty.resolveWith<Color?>(
                                (Set<MaterialState> states) {
                                   if (states.contains(MaterialState.disabled)) return Colors.transparent;
                                   // Use the active color for the shadow tint
                                   return color.withOpacity(0.6);
                                }
                              ),
                              // Keep other properties from the theme like padding, shape, textStyle
                          ),
                      ),
                  ),
              );
          },
      );
  }


  // --- Draggable Option Styling (_buildDraggableOption) ---
  // Lines 463-548: Significant styling improvements using AnimatedContainer, theme colors, increased rounding, better shadows, and refined feedback/placeholder appearance.
  Widget _buildDraggableOption(
      BuildContext context, int index, Question question, double size, IQTestViewModel viewModel, {GlobalKey? key}) {
    final theme = Theme.of(context);
    bool isLocked = viewModel.isQuestionLocked(viewModel.currentQuestionIndex);
    bool isSelected = viewModel.selectedOptionIndex == index;
    bool isCorrect = isLocked && (index == question.correctOptionIndex);
    bool isIncorrectSelected = isLocked && isSelected && !isCorrect;

    // Determine border based on state
    Color borderColor;
    double borderWidth = 2.5;
    if (isCorrect) {
      borderColor = Colors.green.shade400;
      borderWidth = 3.5;
    } else if (isIncorrectSelected) {
      borderColor = Colors.red.shade400;
      borderWidth = 3.5;
    } else if (isSelected && isLocked) { // Handle case where a non-correct option was selected and now locked
      borderColor = Colors.grey.shade400; // Keep it grey if incorrect was locked
      borderWidth = 2.5;
    }
     else if (isSelected) { // Selected but not locked (e.g., before submit if submit wasn't immediate)
      borderColor = theme.colorScheme.secondary; // Use accent color when selected
      borderWidth = 3.5;
    }
     else {
        // Default state: not selected, not locked
        borderColor = Colors.grey.shade400;
     }

    return Container(
      key: key,
      child: TweenAnimationBuilder<double>( // Entrance animation
        tween: Tween<double>(begin: 0.5, end: 1.0),
        duration: Duration(milliseconds: 500 + index * 150), // Staggered entrance
        curve: Curves.easeOutBack,
        builder: (context, scaleValue, child) {
          return Transform.scale(
            scale: scaleValue,
            child: Opacity(
              opacity: scaleValue.clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: Draggable<int>(
          data: index, // Data payload is the option index
          feedback: Material( // Feedback widget shown while dragging
            color: Colors.transparent, // No background, just the styled container
            elevation: 10.0, // Higher elevation while dragging
            borderRadius: BorderRadius.circular(18), // Consistent rounding
            child: Transform.scale( // Make it slightly larger when dragging
              scale: 1.1,
              child: Container( // Styling for feedback item
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9), // Slightly transparent background
                  border: Border.all(color: theme.colorScheme.secondary, width: 3.5), // Use accent color for feedback border
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.secondary.withOpacity(0.5),
                      spreadRadius: 4,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ClipRRect( // Clip the image content
                  borderRadius: BorderRadius.circular(14), // Slightly smaller radius for content
                  child: _buildGrid(question.options[index], size),
                ),
              ),
            ),
          ),
          childWhenDragging: Container( // Placeholder left behind styling
            width: size,
            height: size,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!, width: 2),
              borderRadius: BorderRadius.circular(18),
              color: Colors.grey[200]?.withOpacity(0.6), // Faded placeholder
            ),
          ),
          // The actual option widget styling
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350), // Animation for border/shadow changes
            curve: Curves.easeInOut,
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85), // Semi-transparent background
              border: Border.all( // Animated border based on state
                color: borderColor,
                width: borderWidth,
              ),
              borderRadius: BorderRadius.circular(18), // Consistent rounded corners
              boxShadow: [ // Animated shadow based on state
                BoxShadow(
                  color: Colors.black.withOpacity(isSelected || isLocked ? 0.25 : 0.15),
                  spreadRadius: isSelected || isLocked ? 4 : 2,
                  blurRadius: isSelected || isLocked ? 8 : 4,
                  offset: const Offset(0, 3), // Subtle shadow
                ),
              ],
            ),
            child: ClipRRect( // Clip the inner image
              borderRadius: BorderRadius.circular(14), // Inner rounding for image
              child: _buildGrid(question.options[index], size),
            ),
          ),
           onDragStarted: isLocked ? null : () {
             _playSound('sounds/drag_start.mp3');
           },
           maxSimultaneousDrags: isLocked ? 0 : 1, // Prevent dragging locked options
        ),
      ),
    );
  }

  // --- Animated Pattern Styling (_buildAnimatedPattern) ---
  // Lines 551-578: Added padding, themed border/shadow, increased rounding.
  Widget _buildAnimatedPattern(List<List<String>> pattern, double size) {
     final theme = Theme.of(context);
    return TweenAnimationBuilder<double>( // Entrance animation for the pattern
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, scaleValue, child) {
        return Transform.scale(
          scale: scaleValue,
          child: Container(
            padding: const EdgeInsets.all(4), // Padding inside the border
            decoration: BoxDecoration(
              border: Border.all(
                  color: theme.colorScheme.secondary.withOpacity(0.8), // Use accent color for border
                  width: 3.5),
              borderRadius: BorderRadius.circular(20), // More rounded corners
              color: Colors.white.withOpacity(0.8), // Semi-transparent white background
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.secondary.withOpacity(0.4), // Shadow matching accent color
                  spreadRadius: 4,
                  blurRadius: 8,
                  offset: const Offset(0, 4), // Slightly offset shadow
                ),
              ],
            ),
            child: ClipRRect( // Clip the grid inside
              borderRadius: BorderRadius.circular(16), // Inner rounding
              child: _buildGrid(pattern, size - 8), // Adjust grid size for padding
            ),
          ),
        );
      },
    );
  }


  // --- Correct Answer Animation Styling (_showCorrectAnswerAnimation) ---
  // Lines 581-635: Added background blur/dimming, larger icon/text, themed colors, better shadows, rounded text bubble, and used GoogleFonts.changa.
  void _showCorrectAnswerAnimation(BuildContext context) {
    final theme = Theme.of(context);
    OverlayState? overlayState = Overlay.of(context);
    OverlayEntry? entry;

    entry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: IgnorePointer( // Prevent interaction with the overlay
          child: Container( // Use a container for potential background blur or dimming
             color: Colors.black.withOpacity(0.1), // Slight dimming
            child: BackdropFilter( // Optional: Blur background
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated Star Icon
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.5, end: 1.0),
                      duration: const Duration(milliseconds: 1200), // Slightly longer for bounce
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          // Use accent color for the star maybe? Or keep amber. Let's try accent.
                          child: Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 120), // Larger icon
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    // Animated Text Bubble
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0), // Start from 0 scale
                      duration: const Duration(milliseconds: 900), // Slightly longer for bounce
                      curve: Curves.elasticOut, // Bouncy effect
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: Container( // Styling for text bubble
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.95), // Use theme primary color
                                borderRadius: BorderRadius.circular(25), // Rounded bubble
                                boxShadow: [ // Improved shadow
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Text(
                                "مذهل!",
                                style: GoogleFonts.changa( // Consistent font
                                  fontSize: 32, // Larger text
                                  fontWeight: FontWeight.bold,
                                  // Use button text color defined in theme
                                  color: theme.textTheme.labelLarge?.color ?? Colors.white,
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
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(entry);
    Future.delayed(const Duration(milliseconds: 2500), () { // Slightly longer display time
      entry?.remove();
      entry = null;
    });
  }

  // --- Grid Placeholder Styling (_buildGrid) ---
  // Lines 640, 651, 669: Adjusted placeholder "?" styling (relative size, color).
  Widget _buildGrid(List<List<String>> grid, [double size = 150]) {
    final theme = Theme.of(context); // Get theme context
    if (grid.isEmpty || grid[0].isEmpty) {
      return Container(
        color: Colors.grey[200],
        width: size,
        height: size,
        child: Center(
          child: Text(
            "؟",
            // Line 640: Adjusted placeholder "?" styling (relative size, color).
             style: TextStyle(fontSize: size * 0.4, color: Colors.grey.shade500), // Relative size, adjusted color
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }
    String cell = grid[0][0];

    return Container(
      color: Colors.white, // Keep background white for images
      width: size,
      height: size,
      child: cell == "?"
          ? Center(
              child: Text(
                "؟",
                // Line 651: Adjusted placeholder "?" styling (relative size, color).
                 style: TextStyle(fontSize: size * 0.5, fontWeight: FontWeight.bold, color: Colors.grey.shade400),// Relative size, adjusted color
                textDirection: TextDirection.rtl,
              ),
            )
          : Image.asset(
              _getImagePath(cell),
              width: size,
              height: size,
              fit: BoxFit.contain, // Ensure the image fits within the bounds
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
                  child: Center(
                    child: Icon(Icons.error_outline, color: Colors.red.shade300, size: size * 0.4), // Themed error icon
                  ),
                );
              },
            ),
    );
  }


  String _getImagePath(String value) {
    // (Keep existing image path logic)
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
        // Ensure you have a placeholder image asset
        return "assets/placeholder.png"; // Make sure this asset exists
    }
  }

  // --- Progress Tracker Styling (_buildProgressTracker) ---
  // Lines 703-759: Increased item sizes, used themed colors, applied GoogleFonts.changa, used filled icons, added tooltips, improved shadows/borders, and used AnimatedContainer.
  Widget _buildProgressTracker(BuildContext context, IQTestViewModel viewModel) {
    final theme = Theme.of(context);
    // Define rainbow colors for fallback/unanswered states
    final List<Color> rainbowColors = [
      Colors.redAccent.shade200,
      Colors.orangeAccent.shade200,
      Colors.yellow.shade600,
      Colors.lightGreenAccent.shade400,
      Colors.cyan.shade300,
      Colors.blueAccent.shade100,
      Colors.purpleAccent.shade100,
    ];
    final double itemSize = 45; // Slightly larger circles
    final double currentItemSize = 55; // Even larger for current item

    return SizedBox(
      height: currentItemSize + 10, // Adjust height to fit the largest item + margin
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true, // Keep RTL flow
        itemCount: viewModel.questions.length,
        padding: const EdgeInsets.symmetric(horizontal: 8), // Padding for the list
        itemBuilder: (context, index) {
          bool isCurrent = viewModel.currentQuestionIndex == index;
          bool isAnswered = viewModel.isQuestionLocked(index);
          bool isCorrect = isAnswered &&
              (//viewModel.answeredQuestions.containsKey(index) &&
               viewModel.answeredQuestions[index] == viewModel.questions[index].correctOptionIndex);

          Color circleColor;
          IconData? statusIcon;
          double size = isCurrent ? currentItemSize : itemSize; // Animated size

          // Determine color and icon based on state
          if (isAnswered) {
            // Use themed colors for correct/incorrect if possible, else defaults
            circleColor = isCorrect
                ? Colors.green.shade400 // Consistent green for correct
                : Colors.orange.shade400; // Consistent orange for incorrect
            statusIcon = isCorrect ? Icons.check_circle : Icons.cancel; // Filled icons
          } else if (isCurrent) {
            // Use theme's accent color for current question
            circleColor = theme.colorScheme.secondary.withOpacity(0.95);
            statusIcon = Icons.edit_rounded; // Indicates current editable question
          } else {
            // Use rainbow colors for future, unanswered questions
            circleColor = rainbowColors[index % rainbowColors.length].withOpacity(0.7);
            // No icon for future questions, show number instead
          }

          return GestureDetector(
            onTap: () {
              // Allow navigation only to answered or the current question
              if (isAnswered || index == viewModel.currentQuestionIndex) {
                viewModel.goToQuestion(index);
              } else {
                // Optionally show a message that future questions aren't accessible yet
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "أكمل الأسئلة السابقة أولاً!", // Complete previous questions first!
                       textDirection: TextDirection.rtl,
                    ),
                    duration: const Duration(seconds: 1),
                    // Style from theme
                  ),
                );
              }
            },
            child: Tooltip( // Provide context on hover/long-press
              message: isAnswered
                  ? (isCorrect ? "السؤال ${index + 1}: صحيح" : "السؤال ${index + 1}: غير صحيح")
                  : isCurrent
                      ? "السؤال ${index + 1}: الحالي"
                      : "السؤال ${index + 1}", // Default tooltip
              preferBelow: false, // Show tooltip above
              textStyle: GoogleFonts.changa(fontSize: 14, color: Colors.white), // Themed tooltip text
              decoration: BoxDecoration( // Themed tooltip background
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8)
              ),
              child: AnimatedContainer( // Animate size change for current item
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: size,
                height: size,
                margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5), // Spacing between items
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle, // Perfectly circular
                  border: isCurrent ? Border.all(color: Colors.white.withOpacity(0.9), width: 3) : null, // White border for current
                  boxShadow: [ // Improved shadow
                    BoxShadow(
                      color: Colors.black.withOpacity(isCurrent ? 0.35 : 0.25), // Stronger shadow for current
                      blurRadius: isCurrent ? 6 : 4,
                      spreadRadius: 1,
                      offset: const Offset(1, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: statusIcon != null
                      ? Icon(statusIcon, color: Colors.white, size: size * 0.5) // Icon scales with circle
                      : Text(
                          "${index + 1}", // Question number if no icon
                          style: GoogleFonts.changa( // Use consistent font
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: size * 0.4, // Text scales with circle
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  // --- Result Screen Styling (_buildResultScreen) ---
  Widget _buildResultScreen(BuildContext context, IQTestViewModel viewModel) {
    final theme = Theme.of(context); // Use the applied theme
    double percentage = viewModel.questions.isNotEmpty ? (viewModel.score / viewModel.questions.length) * 100 : 0;
    String iqCategory = viewModel.getIQCategory();
    Color categoryColor;
    IconData categoryIcon;
    String celebrationLottie;

    // Translate IQ Category and set styles
    String translatedIqCategory;
    switch (iqCategory) {
      case "Super Star":
        translatedIqCategory = "نجم خارق";
        // Use a color that fits well with most themes, maybe a bright green or gold
        categoryColor = Colors.green.shade600;
        categoryIcon = Icons.emoji_events;
        celebrationLottie = 'https://assets1.lottiefiles.com/packages/lf20_touohxv0.json'; // Confetti burst
        break;
      case "Great Explorer":
        translatedIqCategory = "مستكشف عظيم";
        // Use the theme's accent color for this category
        categoryColor = theme.colorScheme.secondary;
        categoryIcon = Icons.explore;
        celebrationLottie = 'https://assets5.lottiefiles.com/packages/lf20_a3kesdek.json'; // Trophy or stars
        break;
      default: // "Rising Talent"
        translatedIqCategory = "موهبة صاعدة";
        // Use a warm color like orange or a muted version of primary
        categoryColor = Colors.orange.shade600;
        categoryIcon = Icons.auto_awesome; // Sparkles
        celebrationLottie = 'https://assets9.lottiefiles.com/packages/lf20_l4fgppor.json'; // Simple celebration
        break;
    }

    return Stack(
      alignment: Alignment.center, // Center stack children
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              // Line 835: Used themed color for ConfettiPainter.
              painter: ConfettiPainter(color: theme.primaryColor.withOpacity(0.7)), // Use theme color, slightly transparent
              size: Size.infinite,
            ),
          ),
        ),
        // Lines 841-852: Adjusted Lottie size/alignment.
        Positioned.fill(
           // Align Lottie slightly above center for better composition
          child: Align(
            alignment: const Alignment(0, -0.2), // Slightly above center
            child: Lottie.network(
              celebrationLottie,
              height: MediaQuery.of(context).size.height * 0.6, // Larger Lottie
              width: MediaQuery.of(context).size.width * 0.9,
              fit: BoxFit.contain,
              repeat: false, // Play animation once
            ),
          ),
        ),
        // Lines 856-945: Major redesign using themed Card, animations, inner gradient, themed TextStyles (Changa), larger fonts/icons, improved star animations, and replaced category text with a styled Chip.
        Center( // Center the main results card
          child: TweenAnimationBuilder<double>( // Entrance animation for the card
            tween: Tween<double>(begin: 0.5, end: 1.0),
            duration: const Duration(milliseconds: 900),
            curve: Curves.elasticOut,
            builder: (context, scaleValue, child) {
              return Transform.scale(
                scale: scaleValue,
                child: Opacity( // Fade in effect
                  opacity: scaleValue.clamp(0.0, 1.0),
                  child: Card( // Use themed Card (inherits shape, elevation, margin, base color from theme)
                    child: Container(
                      // Optional: Add subtle internal gradient matching theme
                      decoration: BoxDecoration(
                         gradient: LinearGradient(
                           colors: [
                            // Use scaffold background from theme for gradient base
                            theme.scaffoldBackgroundColor.withOpacity(1.0),
                            theme.scaffoldBackgroundColor.withOpacity(0.8),
                           ],
                           begin: Alignment.topLeft,
                           end: Alignment.bottomRight,
                         ),
                         // Ensure gradient respects card's rounded corners
                         borderRadius: (theme.cardTheme.shape as RoundedRectangleBorder?)?.borderRadius ?? BorderRadius.circular(20.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 25), // Increased padding
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.88), // Max width
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Fit content height
                        children: [
                          // Category Icon
                          Icon(categoryIcon, size: 70, color: categoryColor), // Larger icon
                          const SizedBox(height: 18),
                          // Title Text
                          Text(
                            "تم إكمال الاختبار!",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.displayLarge?.copyWith( // Themed style (Changa, size from theme)
                              // Optional override: use primary color if desired
                              color: theme.primaryColor,
                              fontSize: 32, // Larger title override
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 30),
                          // Animated Score Display
                          TweenAnimationBuilder<int>(
                            tween: IntTween(begin: 0, end: viewModel.score),
                            duration: const Duration(seconds: 1, milliseconds: 500), // Longer animation for score count
                            curve: Curves.easeOutCubic,
                            builder: (context, int currentScore, child) {
                              return Text(
                                "نتيجتك: $currentScore / ${viewModel.questions.length}",
                                style: theme.textTheme.headlineMedium?.copyWith( // Themed style (Changa, size from theme)
                                  // Optional overrides: use accent color, adjust weight/size
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 26, // Larger score text override
                                ),
                                textDirection: TextDirection.rtl,
                              );
                            },
                          ),
                          const SizedBox(height: 25),
                          // Animated Stars Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              viewModel.score.clamp(0, 5), // Max 5 stars visually, even if score is higher
                              (index) => TweenAnimationBuilder<double>( // Staggered star animation
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                duration: Duration(milliseconds: 800 + (index * 200)), // Staggered delay
                                curve: Curves.elasticOut, // Bouncy effect for stars
                                builder: (context, starScale, child) {
                                  return Transform.scale(
                                    scale: starScale,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 5.0), // Space between stars
                                      child: Icon(
                                        Icons.star_rounded,
                                        color: Colors.amber.shade600, // Brighter amber
                                        size: 50, // Larger stars
                                        shadows: [ // More pronounced shadow
                                          Shadow(
                                            color: Colors.black.withOpacity(0.35),
                                            blurRadius: 5,
                                            offset: const Offset(1.5, 1.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          // Category Chip/Badge
                          Chip( // Use a Chip for better styling
                             avatar: Icon(categoryIcon, size: 24, color: categoryColor), // Icon inside chip
                             label: Text(
                                "أنت $translatedIqCategory!",
                                style: GoogleFonts.changa( // Use consistent font
                                  fontSize: 20, // Adjust size for chip
                                  fontWeight: FontWeight.bold,
                                   // Label color should contrast with chip background
                                   // Let chip's labelStyle handle this, or set explicitly
                                   // color: categoryColor, // This might clash with light background
                                )
                             ),
                             backgroundColor: categoryColor.withOpacity(0.15), // Light background
                             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Chip padding
                             shape: StadiumBorder( // Pill shape
                                side: BorderSide(color: categoryColor, width: 2.0) // Border matching color
                             ),
                             // Use labelStyle for better text color control within Chip
                             labelStyle: TextStyle(
                                 color: categoryColor, // Ensure label color matches border/icon
                                 fontWeight: FontWeight.bold,
                                 fontSize: 20 // Ensure font size is applied here too
                             ),
                             elevation: 3, // Subtle elevation for the chip
                             shadowColor: categoryColor.withOpacity(0.3),
                          ),
                          const SizedBox(height: 40),
                          // Play Again Button
                        _buildAnimatedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('iqTestCompleted', true);
                          if (mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => HomePage(threadId: widget.threadId)),
                              (route) => false,
                            );
                          }
                        },
                        icon: Icons.check_circle_outline,
                        label: "ابدأ اللعب",        // Start
                        color: _currentTheme['primaryColor'] ?? Colors.green,
                      ),
                        ],
                      ),
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
} // End of _IQTestScreenState class

// --- Added Custom Painters/Helpers ---
// Lines 961-992: Added DashedBorderPainter class for custom borders.
// IMPORTANT: The actual code for DashedBorderPainter was NOT provided in the prompt.
// Adding a placeholder class definition. You need to provide the actual implementation.
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final List<double>? dashPattern; // e.g., [5, 5] for 5 pixels drawn, 5 pixels skip

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.radius = 0.0,
    this.dashPattern = const [5, 5], // Default dash pattern
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    if (dashPattern == null || dashPattern!.isEmpty) {
      // Draw solid border if no dash pattern
      canvas.drawRRect(rrect, paint);
    } else {
      // Draw dashed border
      Path path = Path()..addRRect(rrect);
      Path dashedPath = dashPath(path, dashArray: CircularIntervalList<double>(dashPattern!));
      canvas.drawPath(dashedPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false; // Adjust if properties change

  // Helper function to create dashed paths (you might need a package like 'path_drawing')
  // This is a simplified placeholder implementation.
  Path dashPath(Path source, {required CircularIntervalList<double> dashArray}) {
    final Path dest = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = dashArray.next;
        if (draw) {
          dest.addPath(metric.extractPath(distance, distance + len), Offset.zero);
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }
}

// Helper class for dashPath (needed by the placeholder implementation)
class CircularIntervalList<T> {
  CircularIntervalList(this._values);
  final List<T> _values;
  int _idx = 0;
  T get next {
    if (_idx >= _values.length) {
      _idx = 0;
    }
    return _values[_idx++];
  }
}


// Lines 1006-1064: Added/Refined ConfettiPainter and ConfettiParticle classes for themed confetti.
// IMPORTANT: The prompt only provided line numbers, not the refined code.
// Replacing the existing ConfettiPainter with the one provided in the ORIGINAL code block.
// Note: The refined version described in the prompt was not included.
class ConfettiPainter extends CustomPainter {
  final math.Random random = math.Random();
  final Color? color; // Base color for themeing

  ConfettiPainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    // Use provided theme color as base, or fallback to vibrant colors
    final List<Color> baseColors = color != null
        ? [
            color!,
            // Generate variations of the theme color
            HSLColor.fromColor(color!).withLightness((HSLColor.fromColor(color!).lightness * 0.8).clamp(0.0, 1.0)).toColor(),
            HSLColor.fromColor(color!).withSaturation((HSLColor.fromColor(color!).saturation * 1.2).clamp(0.0, 1.0)).toColor(),
            Colors.white.withOpacity(0.8), // Add white for contrast
          ]
        : [ // Fallback colors if no theme color provided
            Colors.redAccent, Colors.blueAccent, Colors.greenAccent,
            Colors.yellowAccent, Colors.purpleAccent, Colors.orangeAccent,
            Colors.white,
          ];

    // Draw a fixed number of confetti particles
    for (int i = 0; i < 100; i++) { // Keep number relatively low for performance
      // Random position
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;

      // Random size (rectangles)
      double confettiWidth = random.nextDouble() * 8 + 4; // Width between 4 and 12
      double confettiHeight = random.nextDouble() * 12 + 6; // Height between 6 and 18

      // Random rotation
      double angle = random.nextDouble() * math.pi * 2; // Full 360 degrees rotation

      // Random color from the generated palette with random opacity
      paint.color = baseColors[random.nextInt(baseColors.length)].withOpacity(0.6 + random.nextDouble() * 0.4); // Opacity 0.6 to 1.0

      // Draw the rotated rectangle
      canvas.save(); // Save canvas state before transforming
      canvas.translate(x, y); // Move to the confetti position
      canvas.rotate(angle); // Rotate the canvas
      // Draw the rectangle centered at the translated origin
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-confettiWidth / 2, -confettiHeight / 2, confettiWidth, confettiHeight),
          Radius.circular(2), // Slightly rounded corners
        ),
        paint,
      );
      canvas.restore(); // Restore canvas state
    }
  }

  @override
  // Repaint whenever the painter is rebuilt (e.g., on screen resize)
  // Could be optimized if confetti state was managed elsewhere.
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) => oldDelegate.color != color;
}

// No ConfettiParticle class was provided in the original code or the prompt's diff.
// The ConfettiPainter implementation above does not require it.