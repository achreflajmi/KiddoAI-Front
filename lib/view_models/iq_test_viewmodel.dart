// view_models/iq_test_viewmodel.dart
import 'package:flutter/material.dart';

class Question {
  final List<List<String>> pattern;
  final List<List<List<String>>> options;
  final int correctOptionIndex;

  Question(this.pattern, this.options, this.correctOptionIndex);
}

class IQTestViewModel extends ChangeNotifier {
  List<Question> questions = [
    // Question 1: Pencils
    Question(
      [["pencil_3l.png"]], // Pattern
      [
        [["pencil_2rd.png"]], // Option a
        [["pencil_1r.png"]],  // Option b
        [["pencil_3d.png"]],  // Option c
        [["pencil_1l1d1r.png"]], // Option d (correct answer)
      ],
      3, // Correct answer is option d (index 3)
    ),
    // Question 2: Cross with Colored Dots
    Question(
      [["cross_dots_pattern.png"]], // Pattern (3x3 grid with "?")
      [
        [["cross_dots_option_a.png"]], // Option a
        [["cross_dots_option_b.png"]], // Option b
        [["cross_dots_option_c.png"]], // Option c
        [["cross_dots_option_d.png"]], // Option d
      ],
      0, // Correct answer is option a (index 0), adjust if needed
    ),
    // Question 3: Shape Grid
    Question(
      [["shape1_pattern.png"]], // Pattern (3x3 grid with "?")
      [
        [["shape1_option_a.png"]], // Option a
        [["shape1_option_b.png"]], // Option b
        [["shape1_option_c.png"]], // Option c
        [["shape1_option_d.png"]], // Option d
      ],
      0, // Correct answer is option a (index 0), adjust if needed
    ),
    // Question 4: 3x3 Colored Grid
    Question(
      [["colored_grid_pattern.png"]], // Pattern (3x3 grid with "?")
      [
        [["colored_grid_option_a.png"]], // Option a
        [["colored_grid_option_b.png"]], // Option b
        [["colored_grid_option_c.png"]], // Option c
        [["colored_grid_option_d.png"]], // Option d
      ],
      0, // Correct answer is option a (index 0), adjust if needed
    ),
    // Question 5: Colored Squares
    Question(
      [["colored_squares_pattern.png"]], // Pattern (5x5 grid with "?")
      [
        [["colored_squares_option_a.png"]], // Option a
        [["colored_squares_option_b.png"]], // Option b
        [["colored_squares_option_c.png"]], // Option c
        [["colored_squares_option_d.png"]], // Option d
      ],
      0, // Correct answer is option a (index 0), adjust if needed
    ),
    // Question 6: Colored Shapes
    Question(
      [["colored_shapes_pattern.png"]], // Pattern (diagram with "?")
      [
        [["colored_shapes_option_a.png"]], // Option a
        [["colored_shapes_option_b.png"]], // Option b
        [["colored_shapes_option_c.png"]], // Option c
        [["colored_shapes_option_d.png"]], // Option d
      ],
      3, // Correct answer is option d (index 3), adjust if needed
    ),
    // Question 7: Number Sequence
    Question(
      [["number_sequence_pattern.png"]], // Pattern (placeholder, sequence with "?")
      [
        [["number_sequence_option_a.png"]], // Option a (5)
        [["number_sequence_option_b.png"]], // Option b (4)
        [["number_sequence_option_c.png"]], // Option c (3)
        [["number_sequence_option_d.png"]], // Option d (2)
      ],
      0, // Correct answer is option a (index 0, 5), adjust if needed
    ),
    // Question 8: Colored Circles
    Question(
      [["colored_circles_pattern.png"]], // Pattern (5x5 grid with "?")
      [
        [["colored_circles_option_a.png"]], // Option a
        [["colored_circles_option_b.png"]], // Option b
        [["colored_circles_option_c.png"]], // Option c
        [["colored_circles_option_d.png"]], // Option d
      ],
      3, // Correct answer is option d (index 3), adjust if needed
    ),
    // Question 9: Numerical Sequence
    Question(
      [["number_sequence2_pattern.png"]], // Pattern (3, 8, 23, 68, ?)
      [
        [["number_sequence2_option_a.png"]], // Option a (39)
        [["number_sequence2_option_b.png"]], // Option b (203)
        [["number_sequence2_option_c.png"]], // Option c (190)
        [["number_sequence2_option_d.png"]], // Option d (45)
      ],
      1, // Correct answer is option b (index 1, 203)
    ),
    // Question 10: Pyramid with Numbers
    Question(
      [["pyramid_numbers_pattern.png"]], // Pattern (pyramid with ?)
      [
        [["pyramid_numbers_option_a.png"]], // Option a (39)
        [["pyramid_numbers_option_b.png"]], // Option b (203)
        [["pyramid_numbers_option_c.png"]], // Option c (88)
        [["pyramid_numbers_option_d.png"]], // Option d (placeholder)
      ],
      0, // Correct answer is option a (index 0, 39), adjust if needed
    ),
    // Question 11: Colored Octagons
    Question(
      [["colored_octagons_pattern.png"]], // Pattern (2x2 grid with "?")
      [
        [["colored_octagons_option_a.png"]], // Option a
        [["colored_octagons_option_b.png"]], // Option b
        [["colored_octagons_option_c.png"]], // Option c
        [["colored_octagons_option_d.png"]], // Option d
      ],
      1, // Correct answer is option b (index 1), adjust if needed
    ),
  ];

  int currentQuestionIndex = 0;
  int score = 0;
  bool isTestCompleted = false;
  int? selectedOptionIndex;

  Question get currentQuestion => questions[currentQuestionIndex];

  void selectOption(int index) {
    selectedOptionIndex = index;
    notifyListeners();
  }

  void nextQuestion() {
    if (selectedOptionIndex == null) {
      return;
    }
    if (selectedOptionIndex == currentQuestion.correctOptionIndex) {
      score++;
    }
    selectedOptionIndex = null;
    if (currentQuestionIndex < questions.length - 1) {
      currentQuestionIndex++;
    } else {
      isTestCompleted = true;
    }
    notifyListeners();
  }

  void goToQuestion(int index) {
    currentQuestionIndex = index;
    selectedOptionIndex = null;
    notifyListeners();
  }

  void resetTest() {
    currentQuestionIndex = 0;
    score = 0;
    isTestCompleted = false;
    selectedOptionIndex = null;
    notifyListeners();
  }

  String getIQCategory() {
    double percentage = (score / questions.length) * 100;
    if (percentage >= 80) return "Above Average";
    if (percentage >= 60) return "Average";
    return "Below Average";
  }
}