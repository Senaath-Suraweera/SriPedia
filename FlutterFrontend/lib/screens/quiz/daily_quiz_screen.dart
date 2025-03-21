import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/neumorphic_widgets.dart';
import 'quiz_result_screen.dart';

class DailyQuizScreen extends StatefulWidget {
  const DailyQuizScreen({super.key});

  @override
  State<DailyQuizScreen> createState() => _DailyQuizScreenState();
}

class _DailyQuizScreenState extends State<DailyQuizScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Animation<double>? _questionAnimation;
  int? _selectedOption;
  bool _showAnswer = false;
  bool _showNext = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _questionAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    // Load quiz questions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      quizProvider.loadDailyQuiz();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleOptionSelected(int optionIndex) {
    if (_showAnswer) return; // Prevent selecting after answer is shown

    setState(() {
      _selectedOption = optionIndex;
      _showAnswer = true;
    });

    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    quizProvider.answerQuestion(optionIndex);

    // Show "Next" button with delay for better UX
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showNext = true;
        });
      }
    });
  }

  void _goToNextQuestion() {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);

    // If quiz is completed, show results
    if (quizProvider.quizCompleted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const QuizResultScreen(),
        ),
      );
      return;
    }

    // Explicitly tell the provider to move to the next question
    quizProvider.nextQuestion();

    // Reset animation
    _animationController.reset();

    setState(() {
      _selectedOption = null;
      _showAnswer = false;
      _showNext = false;
    });

    // Start animation for next question
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, quizProvider, child) {
        // Show loading indicator
        if (quizProvider.isLoading) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Daily Quiz'),
              backgroundColor: const Color(0xFF192734),
            ),
            body: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF61DAFB)),
              ),
            ),
          );
        }

        // Show error message
        if (quizProvider.errorMessage != null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Daily Quiz'),
              backgroundColor: const Color(0xFF192734),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${quizProvider.errorMessage}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  NeumorphicButton(
                    onPressed: () {
                      quizProvider.loadDailyQuiz();
                    },
                    child: const Text(
                      'Try Again',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF61DAFB),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final currentQuestion = quizProvider.currentQuestion;

        if (currentQuestion == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Daily Quiz'),
              backgroundColor: const Color(0xFF192734),
            ),
            body: const Center(
              child: Text('No questions available',
                  style: TextStyle(color: Colors.white)),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(quizProvider.currentQuizDate != null
                ? 'Quiz: ${quizProvider.currentQuizDate}'
                : 'Daily Quiz'),
            backgroundColor: const Color(0xFF192734),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: const Color(0xFF252836),
                      title: const Text('Quit Quiz?',
                          style: TextStyle(color: Colors.white)),
                      content: const Text(
                        'Your progress will be lost.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        TextButton(
                          child: const Text('Quit'),
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            actions: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A6F97),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  'Score: ${quizProvider.score}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // Progress bar
              Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Flexible(
                      flex: quizProvider.currentQuestionIndex + 1,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF61DAFB), Color(0xFF2A6F97)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Flexible(
                      flex: quizProvider.questions.length -
                          (quizProvider.currentQuestionIndex + 1),
                      child: Container(),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Question ${quizProvider.currentQuestionIndex + 1}/${quizProvider.questions.length}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.timer, color: Colors.grey[400], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '10 points',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Question card with animation
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ScaleTransition(
                    scale: _questionAnimation!,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF252836),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentQuestion.question,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Options
                        ...List.generate(currentQuestion.options.length,
                            (index) {
                          final option = currentQuestion.options[index];
                          bool isCorrect =
                              index == currentQuestion.correctOption;
                          bool isSelected = _selectedOption == index;
                          bool showCorrect = _showAnswer && isCorrect;
                          bool showWrong =
                              _showAnswer && isSelected && !isCorrect;

                          Color borderColor = Colors.transparent;
                          if (showCorrect) {
                            borderColor = Colors.green;
                          } else if (showWrong) {
                            borderColor = Colors.red;
                          } else if (isSelected) {
                            borderColor = const Color(0xFF61DAFB);
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () {
                                if (!_showAnswer) {
                                  _handleOptionSelected(index);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF252836),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: borderColor,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    if (!_showAnswer || isSelected || isCorrect)
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _showAnswer && isCorrect
                                            ? Colors.green
                                            : _showAnswer &&
                                                    isSelected &&
                                                    !isCorrect
                                                ? Colors.red
                                                : isSelected
                                                    ? const Color(0xFF61DAFB)
                                                    : Colors.grey[700],
                                      ),
                                      child: Center(
                                        child: _showAnswer && isCorrect
                                            ? const Icon(Icons.check,
                                                color: Colors.white, size: 16)
                                            : _showAnswer &&
                                                    isSelected &&
                                                    !isCorrect
                                                ? const Icon(Icons.close,
                                                    color: Colors.white,
                                                    size: 16)
                                                : Text(
                                                    String.fromCharCode(65 +
                                                        index), // A, B, C, D
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: _showAnswer &&
                                                  (isCorrect ||
                                                      (isSelected &&
                                                          !isCorrect))
                                              ? isCorrect
                                                  ? Colors.green
                                                  : Colors.red
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),

                        // Explanation (only shown after answering)
                        if (_showAnswer && currentQuestion.explanation != null)
                          AnimatedOpacity(
                            opacity: _showAnswer ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 500),
                            child: Container(
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A6F97).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color:
                                      const Color(0xFF61DAFB).withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.info_outline,
                                          color: Color(0xFF61DAFB), size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Explanation',
                                        style: TextStyle(
                                          color: Color(0xFF61DAFB),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    currentQuestion.explanation!,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Next button (only shown after answering)
              if (_showNext)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: NeumorphicButton(
                    onPressed: _goToNextQuestion,
                    child: Text(
                      quizProvider.quizCompleted
                          ? 'See Results'
                          : 'Next Question',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF61DAFB),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
