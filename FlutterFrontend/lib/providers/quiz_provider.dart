import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz_model.dart';
import '../services/firebase_service.dart';
import '../services/realtime_database_service.dart';

class QuizProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final RealtimeDatabaseService _realtimeDBService = RealtimeDatabaseService();
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  List<int> _userAnswers = [];
  List<bool> _isCorrect = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _quizCompleted = false;
  int _score = 0;
  String? _currentQuizDate;

  // Getters
  List<Question> get questions => _questions;
  int get currentQuestionIndex => _currentQuestionIndex;
  Question? get currentQuestion =>
      _questions.isNotEmpty && _currentQuestionIndex < _questions.length
          ? _questions[_currentQuestionIndex]
          : null;
  List<int> get userAnswers => _userAnswers;
  List<bool> get isCorrect => _isCorrect;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get quizCompleted => _quizCompleted;
  int get score => _score;
  int get correctAnswers => _isCorrect.where((correct) => correct).length;
  String? get currentQuizDate => _currentQuizDate;

  // Load quiz questions from Realtime Database
  Future<void> loadDailyQuiz() async {
    _setLoading(true);
    _clearError();
    _resetQuiz();

    try {
      // Get most recent quiz date
      final latestQuizDate =
          await _realtimeDBService.getMostRecentDailyQuizDate();

      if (latestQuizDate == null) {
        print('No daily quizzes available in Realtime Database');
        _loadDummyQuestions();
        _setLoading(false);
        notifyListeners();
        return;
      }

      print('Loading daily quiz for date: $latestQuizDate');
      _currentQuizDate = latestQuizDate;

      // Get questions for this date
      final questionsData =
          await _realtimeDBService.getDailyQuizQuestions(latestQuizDate);

      if (questionsData.isEmpty) {
        print('No questions found for quiz date: $latestQuizDate');
        _loadDummyQuestions();
      } else {
        print(
            'Loaded ${questionsData.length} questions from Realtime Database');

        // Process and convert questions
        _questions = _processQuestionsFromRealtimeDB(questionsData);

        if (_questions.isEmpty) {
          print('Failed to process questions, using dummy data');
          _loadDummyQuestions();
        }
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print('Error loading daily quiz from Realtime Database: $e');

      // Fallback to dummy questions
      _loadDummyQuestions();
      _setError('Error loading quiz: $e');
      _setLoading(false);
      notifyListeners();
    }
  }

  // Process questions from Realtime Database format
  List<Question> _processQuestionsFromRealtimeDB(
      List<Map<String, dynamic>> questionsData) {
    final processed = <Question>[];

    try {
      for (int i = 0; i < questionsData.length && i < 10; i++) {
        final question = questionsData[i];

        if (question.containsKey('question')) {
          // Basic question data
          final questionText =
              question['question'] as String? ?? 'Unknown question';

          // Options - generate if not provided
          List<String> options;
          if (question.containsKey('options') && question['options'] is List) {
            options =
                (question['options'] as List).map((e) => e.toString()).toList();
          } else {
            // Generate dummy options if not provided
            options = [
              'Option A',
              'Option B',
              'Option C',
              'Option D',
            ];
          }

          // Use provided correct option or default to first
          int correctOption = 0;
          if (question.containsKey('correctOption')) {
            correctOption = question['correctOption'] as int? ?? 0;
          }

          // Process explanation if available
          String? explanation;
          if (question.containsKey('explanation')) {
            explanation = question['explanation'] as String?;
          }

          // Process points if available
          int points = question['points'] as int? ?? 10;

          processed.add(Question(
            id: question['id'] as String? ?? i.toString(),
            question: questionText,
            options: options,
            correctOption: correctOption,
            explanation: explanation,
            points: points,
          ));
        }
      }
    } catch (e) {
      print('Error processing questions from Realtime DB: $e');
    }

    return processed;
  }

  // Answer current question but don't move to next automatically
  void answerQuestion(int optionIndex) {
    if (_currentQuestionIndex >= _questions.length) return;

    final correctAnswer = _questions[_currentQuestionIndex].correctOption;
    final isAnswerCorrect = optionIndex == correctAnswer;
    final questionPoints = _questions[_currentQuestionIndex].points;

    _userAnswers.add(optionIndex);
    _isCorrect.add(isAnswerCorrect);

    if (isAnswerCorrect) {
      _score += questionPoints;
    }

    // Check if this was the last question
    if (_currentQuestionIndex == _questions.length - 1) {
      _quizCompleted = true;
      _saveQuizResult();
    }

    // Remove the automatic increment of currentQuestionIndex that was here

    notifyListeners();
  }

  // Save quiz result to Firebase
  Future<void> _saveQuizResult() async {
    if (!_quizCompleted) return;

    try {
      final userId = _firebaseService.currentUser?.uid;
      if (userId == null) return;

      // Update user points
      await _firebaseService.updateUserPoints(_score);

      // Save quiz attempt to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('quizAttempts')
          .add({
        'quizId': 'daily',
        'date': FieldValue.serverTimestamp(),
        'score': _score,
        'totalQuestions': _questions.length,
        'correctAnswers': correctAnswers,
        'userAnswers': _userAnswers,
      });
    } catch (e) {
      print('Error saving quiz result: $e');
    }
  }

  // Reset quiz state
  void _resetQuiz() {
    _questions = [];
    _currentQuestionIndex = 0;
    _userAnswers = [];
    _isCorrect = [];
    _quizCompleted = false;
    _score = 0;
  }

  // Move to next question (will be called explicitly by the button)
  void nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  // Check if current question is answered
  bool isCurrentQuestionAnswered() {
    return _userAnswers.length > _currentQuestionIndex;
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Load dummy questions for testing
  void _loadDummyQuestions() {
    _questions = [
      Question(
        id: '1',
        question: 'What is the capital of Sri Lanka?',
        options: ['Colombo', 'Kandy', 'Sri Jayewardenepura Kotte', 'Galle'],
        correctOption: 2,
        explanation:
            'Sri Jayewardenepura Kotte is the official capital, while Colombo is the commercial capital.',
      ),
      Question(
        id: '2',
        question: 'Which river is the longest in Sri Lanka?',
        options: [
          'Mahaweli River',
          'Kelani River',
          'Malwathu Oya',
          'Kalu Ganga'
        ],
        correctOption: 0,
        explanation:
            'Mahaweli River is the longest river in Sri Lanka with a length of 335 km.',
      ),
      Question(
        id: '3',
        question:
            'Which Sri Lankan cricketer has scored the most international centuries?',
        options: [
          'Sanath Jayasuriya',
          'Mahela Jayawardene',
          'Kumar Sangakkara',
          'Aravinda de Silva'
        ],
        correctOption: 2,
        explanation:
            'Kumar Sangakkara has scored the most international centuries for Sri Lanka.',
      ),
      Question(
        id: '4',
        question:
            'In which year did Sri Lanka gain independence from British rule?',
        options: ['1948', '1950', '1947', '1952'],
        correctOption: 0,
        explanation:
            'Sri Lanka (then Ceylon) gained independence from British rule on February 4, 1948.',
      ),
      Question(
        id: '5',
        question:
            'Which of these is NOT a UNESCO World Heritage Site in Sri Lanka?',
        options: ['Sigiriya', 'Anuradhapura', 'Jaffna Fort', 'Kandy'],
        correctOption: 2,
        explanation:
            'Jaffna Fort is not a UNESCO World Heritage Site, although it is historically significant.',
      ),
      Question(
        id: '6',
        question: 'What is the main religion practiced in Sri Lanka?',
        options: ['Hinduism', 'Buddhism', 'Islam', 'Christianity'],
        correctOption: 1,
        explanation:
            'Buddhism is the predominant religion in Sri Lanka, practiced by about 70% of the population.',
      ),
      Question(
        id: '7',
        question: 'Which famous explorer first landed in Sri Lanka in 1505?',
        options: [
          'Christopher Columbus',
          'Vasco da Gama',
          'Ferdinand Magellan',
          'Lourenço de Almeida'
        ],
        correctOption: 3,
        explanation:
            'Portuguese explorer Lourenço de Almeida first arrived in Sri Lanka in 1505.',
      ),
      Question(
        id: '8',
        question: 'What is the national flower of Sri Lanka?',
        options: ['Lotus', 'Nil Mahanel', 'Water Lily', 'Orchid'],
        correctOption: 1,
        explanation:
            'The blue water lily (Nil Mahanel) is the national flower of Sri Lanka.',
      ),
      Question(
        id: '9',
        question:
            'Which Sri Lankan leader served as Prime Minister for the longest period?',
        options: [
          'D.S. Senanayake',
          'Sirimavo Bandaranaike',
          'J.R. Jayewardene',
          'Ranil Wickremesinghe'
        ],
        correctOption: 1,
        explanation:
            'Sirimavo Bandaranaike served as Prime Minister for a total of 18 years across three terms.',
      ),
      Question(
        id: '10',
        question: 'Which mountain is the tallest in Sri Lanka?',
        options: [
          'Adam\'s Peak',
          'Kirigalpotta',
          'Pidurutalagala',
          'Knuckles Mountain'
        ],
        correctOption: 2,
        explanation:
            'Pidurutalagala is the tallest mountain in Sri Lanka at 2,524 meters above sea level.',
      ),
    ];
  }
}
