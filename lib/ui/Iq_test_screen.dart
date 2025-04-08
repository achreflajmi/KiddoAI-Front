import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
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

class _IQTestScreenState extends State<IQTestScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _selectedAvatarName = AvatarSettings.defaultAvatarName;
  Map<String, dynamic> _currentTheme = {};

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
  }

  Future<void> _loadAvatarTheme() async {
    final avatar = await AvatarSettings.getCurrentAvatar();
    setState(() {
      _selectedAvatarName = avatar['name']!;
      _currentTheme = _characterThemes[_selectedAvatarName]!;
    });
  }

  void _playSound(String assetPath) async {
    await _audioPlayer.play(AssetSource(assetPath));
  }

  void _playInstruction(String soundPath) async {
    await _audioPlayer.play(AssetSource(soundPath));
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => IQTestViewModel(),
      child: Scaffold(
        backgroundColor: _currentTheme['secondaryColor'] ?? Colors.yellow[50],
        appBar: AppBar(
          backgroundColor: _currentTheme['primaryColor'] ?? const Color(0xFF049a02),
          title: Text(
            'Kids IQ Test',
            style: GoogleFonts.interTight(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          elevation: 2,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _currentTheme['gradient'] ?? [Colors.yellow[50]!, Colors.yellow[100]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Consumer<IQTestViewModel>(
              builder: (context, viewModel, child) {
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
    );
  }

  Widget _buildQuestionScreen(BuildContext context, IQTestViewModel viewModel) {
    final question = viewModel.currentQuestion;

    if (!viewModel.isAnswerSubmitted && !viewModel.isQuestionLocked(viewModel.currentQuestionIndex)) {
      _playInstruction('sounds/instruction_drag.mp3');
    }

    double patternSize = MediaQuery.of(context).size.width * 0.30;
    double optionSize = MediaQuery.of(context).size.width * 0.20;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${viewModel.currentQuestionIndex + 1}. Question",
                        style: GoogleFonts.interTight(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _currentTheme['accentColor'] ?? Colors.blue[800],
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            "Stars: ",
                            style: GoogleFonts.interTight(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _currentTheme['accentColor'] ?? Colors.blue[800],
                            ),
                          ),
                          ...List.generate(
                            viewModel.score,
                            (index) => TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 500),
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: const Icon(Icons.star, color: Colors.amber, size: 24),
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
                    child: _buildAnimatedPattern(question.pattern, patternSize.clamp(100, 250)),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: DragTarget<int>(
                      builder: (context, candidateData, rejectedData) {
                        return TweenAnimationBuilder(
                          tween: Tween<double>(begin: 3, end: 5),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeInOut,
                          builder: (context, borderWidth, child) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: patternSize.clamp(100, 250),
                              height: patternSize.clamp(100, 250),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: candidateData.isNotEmpty
                                      ? Colors.green
                                      : (viewModel.isAnswerSubmitted
                                          ? (viewModel.selectedOptionIndex == question.correctOptionIndex
                                              ? Colors.green
                                              : Colors.red)
                                          : _currentTheme['accentColor'] ?? Colors.grey),
                                  width: viewModel.selectedOptionIndex == null && !viewModel.isQuestionLocked(viewModel.currentQuestionIndex)
                                      ? borderWidth
                                      : (candidateData.isNotEmpty ? 4 : 3),
                                ),
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.grey.withOpacity(0.2),
                                boxShadow: viewModel.selectedOptionIndex == question.correctOptionIndex
                                    ? [BoxShadow(color: Colors.green.withOpacity(0.5), spreadRadius: 2, blurRadius: 8)]
                                    : null,
                              ),
                              child: Center(
                                child: viewModel.selectedOptionIndex != null
                                    ? _buildGrid(question.options[viewModel.selectedOptionIndex!], patternSize.clamp(100, 250))
                                    : Text(
                                        "Drag your answer here!",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.interTight(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                              ),
                            );
                          },
                        );
                      },
                      onWillAccept: (data) => !viewModel.isQuestionLocked(viewModel.currentQuestionIndex),
                      onAccept: (int optionIndex) {
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
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "Drag the correct answer to the box above:",
                    style: GoogleFonts.interTight(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: _currentTheme['accentColor'] ?? Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1,
                    children: List.generate(question.options.length, (index) {
                      return _buildDraggableOption(context, index, question, optionSize.clamp(80, 120), viewModel);
                    }),
                  ),
                  const SizedBox(height: 20),
                  _buildProgressTracker(context, viewModel),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildAnimatedButton(
                        onPressed: viewModel.currentQuestionIndex > 0
                            ? () {
                                viewModel.goToQuestion(viewModel.currentQuestionIndex - 1);
                                _playSound('sounds/correct.mp3');
                              }
                            : null,
                        icon: Icons.arrow_back,
                        label: "Previous",
                        color: viewModel.currentQuestionIndex > 0
                            ? _currentTheme['accentColor'] ?? Colors.blue[700]!
                            : Colors.grey,
                      ),
                      _buildAnimatedButton(
                        onPressed: () {
                          if (viewModel.selectedOptionIndex == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please drag an answer to the question box first')),
                            );
                            return;
                          }
                          viewModel.nextQuestion();
                          _playSound('sounds/correct.mp3');
                        },
                        icon: Icons.arrow_forward,
                        label: "Next",
                        color: _currentTheme['primaryColor'] ?? Colors.green,
                      ),
                    ],
                  ),
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
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 1.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      builder: (context, scale, child) {
        return GestureDetector(
          onTapDown: (_) {
            if (onPressed != null) {
              setState(() => scale = 1.1);
            }
          },
          onTapUp: (_) {
            if (onPressed != null) {
              setState(() => scale = 1.0);
              onPressed();
            }
          },
          child: Transform.scale(
            scale: scale,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDraggableOption(
      BuildContext context, int index, Question question, double size, IQTestViewModel viewModel) {
    bool isLocked = viewModel.isQuestionLocked(viewModel.currentQuestionIndex);
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      builder: (context, double value, child) {
        return GestureDetector(
          onPanUpdate: (_) => !isLocked ? setState(() {}) : null,
          child: Draggable<int>(
            data: index,
            feedback: Material(
              elevation: 6.0,
              borderRadius: BorderRadius.circular(12),
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 1.0, end: 1.2),
                duration: const Duration(milliseconds: 200),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        border: Border.all(color: _currentTheme['accentColor'] ?? Colors.blue, width: 3),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (_currentTheme['accentColor'] ?? Colors.blue).withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _buildGrid(question.options[index], size),
                      ),
                    ),
                  );
                },
              ),
            ),
            childWhenDragging: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!, width: 2),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
              ),
            ),
            child: Transform.translate(
              offset: Offset(math.sin((value * 2 * math.pi) + index) * 3, 0),
              child: Transform.scale(
                scale: 1.05,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: viewModel.selectedOptionIndex == index
                          ? _currentTheme['accentColor'] ?? Colors.blue
                          : Colors.grey[400]!,
                      width: viewModel.selectedOptionIndex == index ? 4 : 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _buildGrid(question.options[index], size),
                  ),
                ),
              ),
            ),
            onDragStarted: isLocked ? null : () {},
          ),
        );
      },
    );
  }

  Widget _buildAnimatedPattern(List<List<String>> pattern, double size) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: _currentTheme['accentColor'] ?? Colors.indigo, width: 3),
              borderRadius: BorderRadius.circular(16),
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
    _playSound('sounds/correct.mp3');
    OverlayState? overlayState = Overlay.of(context);
    OverlayEntry? entry;

    entry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: ConfettiPainter(color: _currentTheme['primaryColor']),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 2 * math.pi),
                    duration: const Duration(milliseconds: 1000),
                    builder: (context, angle, child) {
                      return Transform.rotate(
                        angle: angle,
                        child: Icon(Icons.star, color: _currentTheme['accentColor'] ?? Colors.amber, size: 60),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 700),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            color: (_currentTheme['primaryColor'] ?? Colors.green).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            "Great job!",
                            style: GoogleFonts.interTight(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    overlayState.insert(entry);
    Future.delayed(const Duration(milliseconds: 2000), () => entry?.remove());
  }

  Widget _buildGrid(List<List<String>> grid, [double size = 150]) {
    String cell = grid[0][0];
    return SizedBox(
      width: size,
      height: size,
      child: cell == "?"
          ? const Center(
              child: Text(
                "?",
                style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
              ),
            )
          : Image.asset(
              _getImagePath(cell),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Text("No Image", style: TextStyle(fontSize: 16, color: Colors.red)),
                );
              },
            ),
    );
  }

  String _getImagePath(String value) {
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
      default: return "assets/placeholder.png";
    }
  }

  Widget _buildProgressTracker(BuildContext context, IQTestViewModel viewModel) {
    final rainbowColors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
    ];
    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: viewModel.questions.length,
        itemBuilder: (context, index) {
          bool isCurrent = viewModel.currentQuestionIndex == index;
          bool isAnswered = viewModel.isQuestionLocked(index);
          bool isCorrect = isAnswered && viewModel.answeredQuestions[index] == viewModel.questions[index].correctOptionIndex;

          return GestureDetector(
            onTap: () => viewModel.goToQuestion(index),
            child: TweenAnimationBuilder(
              tween: Tween<double>(begin: 1.0, end: isAnswered ? 1.2 : 1.0),
              duration: const Duration(milliseconds: 300),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 50,
                    height: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? _currentTheme['accentColor'] ?? Colors.blue
                          : (isAnswered
                              ? (isCorrect ? Colors.green : Colors.orange)
                              : rainbowColors[index % rainbowColors.length]),
                      shape: BoxShape.circle,
                      boxShadow: isCurrent
                          ? [BoxShadow(color: (_currentTheme['accentColor'] ?? Colors.blue).withOpacity(0.5), blurRadius: 4, spreadRadius: 1)]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        "${index + 1}",
                        style: TextStyle(
                          color: isCurrent || isAnswered ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultScreen(BuildContext context, IQTestViewModel viewModel) {
    double percentage = (viewModel.score / viewModel.questions.length) * 100;
    String iqCategory = viewModel.getIQCategory();
    Color categoryColor = iqCategory == "Super Star"
        ? Colors.green
        : iqCategory == "Great Explorer"
            ? _currentTheme['accentColor'] ?? Colors.blue
            : Colors.orange;

    return Stack(
      children: [
        CustomPaint(painter: ConfettiPainter(color: _currentTheme['primaryColor']), size: Size.infinite),
        Center(
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: _currentTheme['secondaryColor']?.withOpacity(0.9),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Test Completed!",
                          style: GoogleFonts.interTight(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _currentTheme['primaryColor'],
                          ),
                        ),
                        const SizedBox(height: 20),
                        TweenAnimationBuilder(
                          tween: Tween<int>(begin: 0, end: viewModel.score),
                          duration: const Duration(seconds: 2),
                          builder: (context, int value, child) {
                            return Text(
                              "Your Score: $value/${viewModel.questions.length}",
                              style: GoogleFonts.interTight(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _currentTheme['accentColor'],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            (percentage / 20).ceil(),
                            (index) => TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0, end: 1),
                              duration: Duration(milliseconds: 500 + (300 * index)),
                              curve: Curves.bounceOut,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: Icon(Icons.star, color: _currentTheme['accentColor'] ?? Colors.amber, size: 50),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: categoryColor, width: 2),
                          ),
                          child: Text(
                            "You’re a $iqCategory!",
                            style: GoogleFonts.interTight(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: categoryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildAnimatedButton(
                          onPressed: () => viewModel.resetTest(),
                          icon: Icons.replay,
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

class ConfettiPainter extends CustomPainter {
  final math.Random random = math.Random();
  final Color? color;

  ConfettiPainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 100; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      double confettiSize = random.nextDouble() * 10 + 5;
      Color confettiColor = color != null
          ? Color.fromARGB(
              200,
              (color!.red + random.nextInt(100) - 50).clamp(0, 255),
              (color!.green + random.nextInt(100) - 50).clamp(0, 255),
              (color!.blue + random.nextInt(100) - 50).clamp(0, 255))
          : Color.fromARGB(200, random.nextInt(255), random.nextInt(255), random.nextInt(255));
      canvas.drawRect(Rect.fromLTWH(x, y, confettiSize, confettiSize), Paint()..color = confettiColor);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}