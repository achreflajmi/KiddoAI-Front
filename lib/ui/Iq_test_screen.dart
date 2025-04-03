// ui/iq_test_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../view_models/iq_test_viewmodel.dart';
import '../widgets/bottom_nav_bar.dart';

class IQTestScreen extends StatelessWidget {
  final String threadId;

  const IQTestScreen({super.key, required this.threadId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => IQTestViewModel(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Color(0xFF049a02),
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
        body: SafeArea(
          child: Consumer<IQTestViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.isTestCompleted) {
                return _buildResultScreen(context, viewModel);
              }
              return _buildQuestionScreen(context, viewModel);
            },
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          threadId: threadId,
          currentIndex: 0,
        ),
      ),
    );
  }

  Widget _buildQuestionScreen(BuildContext context, IQTestViewModel viewModel) {
    final question = viewModel.currentQuestion;

    // Responsive sizing based on screen width
    double patternSize = MediaQuery.of(context).size.width * 0.30; // Reduced to 30% of screen width
    double optionSize = MediaQuery.of(context).size.width * 0.25;  // Kept at 25% of screen width

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${viewModel.currentQuestionIndex + 1}. Question",
              style: GoogleFonts.interTight(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Center( // Center the pattern image
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal, // Enable horizontal scrolling
                child: _buildGrid(question.pattern, patternSize.clamp(100, 250)), // Pattern size clamp at (100, 250)
              ),
            ),
            const SizedBox(height: 50), // Spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text("a."),
                    GestureDetector(
                      onTap: () {
                        viewModel.selectOption(0);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: viewModel.selectedOptionIndex == 0
                                ? Colors.blue
                                : Colors.grey,
                            width: viewModel.selectedOptionIndex == 0 ? 3 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _buildGrid(question.options[0], optionSize.clamp(80, 120)), // Option size clamp at (80, 120)
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text("b."),
                    GestureDetector(
                      onTap: () {
                        viewModel.selectOption(1);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: viewModel.selectedOptionIndex == 1
                                ? Colors.blue
                                : Colors.grey,
                            width: viewModel.selectedOptionIndex == 1 ? 3 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _buildGrid(question.options[1], optionSize.clamp(80, 120)), // Option size clamp at (80, 120)
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 50), // Spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text("c."),
                    GestureDetector(
                      onTap: () {
                        viewModel.selectOption(2);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: viewModel.selectedOptionIndex == 2
                                ? Colors.blue
                                : Colors.grey,
                            width: viewModel.selectedOptionIndex == 2 ? 3 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _buildGrid(question.options[2], optionSize.clamp(80, 120)), // Option size clamp at (80, 120)
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text("d."),
                    GestureDetector(
                      onTap: () {
                        viewModel.selectOption(3);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: viewModel.selectedOptionIndex == 3
                                ? Colors.blue
                                : Colors.grey,
                            width: viewModel.selectedOptionIndex == 3 ? 3 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _buildGrid(question.options[3], optionSize.clamp(80, 120)), // Option size clamp at (80, 120)
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 50), // Spacing
            _buildProgressTracker(context, viewModel),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Review feature not implemented yet')),
                    );
                  },
                  child: const Text("Review Question"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (viewModel.selectedOptionIndex == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please select an answer before proceeding')),
                      );
                      return;
                    }
                    viewModel.nextQuestion();
                  },
                  child: const Text("Next"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<List<String>> grid, [double size = 150]) { // Default size kept at 150
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: grid.asMap().entries.map((rowEntry) {
        int rowIndex = rowEntry.key;
        List<String> row = rowEntry.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: row.asMap().entries.map((cellEntry) {
            int colIndex = cellEntry.key;
            String cell = cellEntry.value;
            return Container(
              width: size,
              height: size,
              margin: EdgeInsets.all(8), // Margin for spacing
              child: cell == "?"
                  ? Center(
                      child: Text(
                        "?",
                        style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
                      ),
                    )
                  : Image.asset(
                      _getImagePath(cell),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            "No Image",
                            style: TextStyle(fontSize: 16, color: Colors.red),
                          ),
                        );
                      },
                    ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  String _getImagePath(String value) {
    switch (value) {
      // Question 1: Pencils
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

      // Question 2: Cross with Colored Dots
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

      // Question 3: Shape Grid
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

      // Question 4: 3x3 Colored Grid
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

      // Question 5: Colored Squares
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

      // Question 6: Colored Shapes
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

      // Question 7: Number Sequence
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

      // Question 8: Colored Circles
      case "colored_circles_pattern.png":
        return "assets/colored_circles_pattern.png";
      case "colored_circles_option_a.png":
        return "assets/colored_circles_option_a.png";
      case "colored_circles_option_b.png":
        return "assets/colored_circles_option_b.png";
      case "colored_circles_option_c.png":
        return "assets/colored_circles_option_c.png";
      case "colored_circles_option_d.png":
        return "assets/colored_circles_option_d.png";

      // Question 9: Numerical Sequence
      case "number_sequence2_pattern.png":
        return "assets/number_sequence2_pattern.png";
      case "number_sequence2_option_a.png":
        return "assets/number_sequence2_option_a.png";
      case "number_sequence2_option_b.png":
        return "assets/number_sequence2_option_b.png";
      case "number_sequence2_option_c.png":
        return "assets/number_sequence2_option_c.png";
      case "number_sequence2_option_d.png":
        return "assets/number_sequence2_option_d.png";

      // Question 10: Pyramid with Numbers
      case "pyramid_numbers_pattern.png":
        return "assets/pyramid_numbers_pattern.png";
      case "pyramid_numbers_option_a.png":
        return "assets/pyramid_numbers_option_a.png";
      case "pyramid_numbers_option_b.png":
        return "assets/pyramid_numbers_option_b.png";
      case "pyramid_numbers_option_c.png":
        return "assets/pyramid_numbers_option_c.png";
      case "pyramid_numbers_option_d.png":
        return "assets/pyramid_numbers_option_d.png";

      // Question 11: Colored Octagons
      case "colored_octagons_pattern.png":
        return "assets/colored_octagons_pattern.png";
      case "colored_octagons_option_a.png":
        return "assets/colored_octagons_option_a.png";
      case "colored_octagons_option_b.png":
        return "assets/colored_octagons_option_b.png";
      case "colored_octagons_option_c.png":
        return "assets/colored_octagons_option_c.png";
      case "colored_octagons_option_d.png":
        return "assets/colored_octagons_option_d.png";

      // Default fallback
      default:
        return "assets/placeholder.png";
    }
  }

  Widget _buildProgressTracker(BuildContext context, IQTestViewModel viewModel) {
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: List.generate(viewModel.questions.length, (index) {
        return GestureDetector(
          onTap: () {
            viewModel.goToQuestion(index);
          },
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            color: viewModel.currentQuestionIndex == index ? Colors.blue : Colors.grey[300],
            child: Text(
              "${index + 1}",
              style: TextStyle(
                color: viewModel.currentQuestionIndex == index ? Colors.white : Colors.black,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildResultScreen(BuildContext context, IQTestViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Test Completed!",
              style: GoogleFonts.interTight(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              "Your Score: ${viewModel.score}/${viewModel.questions.length}",
              style: GoogleFonts.interTight(fontSize: 20),
            ),
            const SizedBox(height: 10),
            Text(
              "IQ Category: ${viewModel.getIQCategory()}",
              style: GoogleFonts.interTight(fontSize: 20),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                viewModel.resetTest();
              },
              child: Text(
                "Restart Test",
                style: GoogleFonts.interTight(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}