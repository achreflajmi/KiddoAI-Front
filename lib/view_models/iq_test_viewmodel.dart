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
    Question(
      [["pencil_3l.png"]],
      [
        [["pencil_2rd.png"]],
        [["pencil_1r.png"]],
        [["pencil_3d.png"]],
        [["pencil_1l1d1r.png"]],
      ],
      3,
    ),
    Question(
      [["cross_dots_pattern.png"]],
      [
        [["cross_dots_option_a.png"]],
        [["cross_dots_option_b.png"]],
        [["cross_dots_option_c.png"]],
        [["cross_dots_option_d.png"]],
      ],
      0,
    ),
    Question(
      [["shape1_pattern.png"]],
      [
        [["shape1_option_a.png"]],
        [["shape1_option_b.png"]],
        [["shape1_option_c.png"]],
        [["shape1_option_d.png"]],
      ],
      0,
    ),
    Question(
      [["colored_grid_pattern.png"]],
      [
        [["colored_grid_option_a.png"]],
        [["colored_grid_option_b.png"]],
        [["colored_grid_option_c.png"]],
        [["colored_grid_option_d.png"]],
      ],
      0,
    ),
    Question(
      [["colored_squares_pattern.png"]],
      [
        [["colored_squares_option_a.png"]],
        [["colored_squares_option_b.png"]],
        [["colored_squares_option_c.png"]],
        [["colored_squares_option_d.png"]],
      ],
      0,
    ),
    Question(
      [["colored_shapes_pattern.png"]],
      [
        [["colored_shapes_option_a.png"]],
        [["colored_shapes_option_b.png"]],
        [["colored_shapes_option_c.png"]],
        [["colored_shapes_option_d.png"]],
      ],
      3,
    ),
    Question(
      [["number_sequence_pattern.png"]],
      [
        [["number_sequence_option_a.png"]],
        [["number_sequence_option_b.png"]],
        [["number_sequence_option_c.png"]],
        [["number_sequence_option_d.png"]],
      ],
      0,
    ),
  ];

  int currentQuestionIndex = 0;
  int score = 0;
  bool isTestCompleted = false;
  int? selectedOptionIndex;
  bool isAnswerSubmitted = false;
  List<int?> answeredQuestions = [];
  List<bool> questionLocked = []; // Tracks if each question is locked after one answer

  IQTestViewModel() {
    answeredQuestions = List.generate(questions.length, (_) => null);
    questionLocked = List.generate(questions.length, (_) => false); // Initially all unlocked
  }

  Question get currentQuestion => questions[currentQuestionIndex];

  bool isQuestionLocked(int index) => questionLocked[index];

  void selectOption(int index) {
    if (questionLocked[currentQuestionIndex]) return; // Do nothing if already locked

    selectedOptionIndex = index;
    isAnswerSubmitted = true;
    answeredQuestions[currentQuestionIndex] = index;
    questionLocked[currentQuestionIndex] = true; // Lock after first submission

    if (index == currentQuestion.correctOptionIndex) {
      score++;
    }

    notifyListeners();
  }

  void nextQuestion() {
    if (selectedOptionIndex == null) {
      return;
    }

    if (currentQuestionIndex < questions.length - 1) {
      currentQuestionIndex++;
      selectedOptionIndex = answeredQuestions[currentQuestionIndex];
      isAnswerSubmitted = selectedOptionIndex != null;
    } else {
      isTestCompleted = true;
    }

    notifyListeners();
  }

  void goToQuestion(int index) {
    currentQuestionIndex = index;
    selectedOptionIndex = answeredQuestions[index];
    isAnswerSubmitted = selectedOptionIndex != null;
    notifyListeners();
  }

  void resetTest() {
    currentQuestionIndex = 0;
    score = 0;
    isTestCompleted = false;
    selectedOptionIndex = null;
    isAnswerSubmitted = false;
    answeredQuestions = List.generate(questions.length, (_) => null);
    questionLocked = List.generate(questions.length, (_) => false); // Reset locks
    notifyListeners();
  }

  String getIQCategory() {
    double percentage = (score / questions.length) * 100;
    if (percentage >= 80) return "Super Star";
    if (percentage >= 60) return "Great Explorer";
    return "Little Learner";
  }
}