class Question {
  final String id;
  final String question;
  final List<String> options;
  final int correctOption;
  final String? explanation;
  final int points;

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOption,
    this.explanation,
    this.points = 10,
  });

  factory Question.fromMap(String id, Map<String, dynamic> data) {
    return Question(
      id: id,
      question: data['question'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctOption: data['correctOption'] ?? 0,
      explanation: data['explanation'],
      points: data['points'] ?? 10,
    );
  }
}

class QuizAttempt {
  final String quizId;
  final List<int> userAnswers;
  final List<bool> isCorrect;
  final int score;
  final int totalQuestions;
  final int correctAnswers;

  QuizAttempt({
    required this.quizId,
    required this.userAnswers,
    required this.isCorrect,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
  });
}
