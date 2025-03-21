import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Temporarily commented out the confetti import until package is installed
// import 'package:confetti/confetti.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/neumorphic_widgets.dart';

class QuizResultScreen extends StatefulWidget {
  const QuizResultScreen({super.key});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  // Temporarily commented out confetti controller
  // late ConfettiController _confettiController;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    // _confettiController = ConfettiController(duration: const Duration(seconds: 5));

    // Start celebration animation if score is good
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      if (quizProvider.correctAnswers >= 7) {
        setState(() {
          _showCelebration = true;
        });
        // _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    // _confettiController.dispose();
    super.dispose();
  }

  String _getPerformanceMessage(int correct, int total) {
    final percentage = (correct / total) * 100;

    if (percentage >= 90) return 'Outstanding!';
    if (percentage >= 75) return 'Great job!';
    if (percentage >= 60) return 'Good work!';
    if (percentage >= 40) return 'Not bad!';
    return 'Keep practicing!';
  }

  Color _getPerformanceColor(int correct, int total) {
    final percentage = (correct / total) * 100;

    if (percentage >= 90) return Colors.amber;
    if (percentage >= 75) return Colors.green;
    if (percentage >= 60) return const Color(0xFF61DAFB);
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, quizProvider, child) {
        final correctCount = quizProvider.correctAnswers;
        final totalQuestions = quizProvider.questions.length;
        final score = quizProvider.score;
        final performanceMessage =
            _getPerformanceMessage(correctCount, totalQuestions);
        final performanceColor =
            _getPerformanceColor(correctCount, totalQuestions);

        return Scaffold(
          body: Stack(
            children: [
              // Alternative celebration effect when score is good
              if (_showCelebration)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Stack(
                      children: List.generate(20, (index) {
                        return Positioned(
                          left:
                              (index * 20) % MediaQuery.of(context).size.width,
                          top: ((index * 37) %
                                  MediaQuery.of(context).size.height) -
                              20,
                          child: TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: Duration(seconds: 1 + index % 3),
                            builder: (context, double value, child) {
                              return Opacity(
                                opacity: 1 - value,
                                child: Transform.translate(
                                  offset: Offset(0, value * 100),
                                  child: Icon(
                                    Icons.star,
                                    color: [
                                      Colors.amber,
                                      Colors.blue,
                                      Colors.red,
                                      Colors.green
                                    ][index % 4],
                                    size: 20.0 + (index % 10),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                ),

              // Content
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Trophy or Medal
                        Icon(
                          correctCount >= 7 ? Icons.emoji_events : Icons.stars,
                          size: 100,
                          color: performanceColor,
                        ),
                        const SizedBox(height: 24),

                        // Performance message
                        Text(
                          performanceMessage,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: performanceColor,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Score card
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
                              BoxShadow(
                                color: Colors.white.withOpacity(0.1),
                                offset: const Offset(-4, -4),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Score',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$score',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: performanceColor,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _StatItem(
                                      icon: Icons.check_circle,
                                      color: Colors.green,
                                      value: correctCount,
                                      label: 'Correct',
                                    ),
                                    Container(
                                      height: 40,
                                      width: 1,
                                      color: Colors.white24,
                                    ),
                                    _StatItem(
                                      icon: Icons.cancel,
                                      color: Colors.red,
                                      value: totalQuestions - correctCount,
                                      label: 'Wrong',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Return to home button
                        NeumorphicButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // Optionally, to ensure going back to home:
                            // Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.home, color: Color(0xFF61DAFB)),
                              SizedBox(width: 12),
                              Text(
                                'Return to Home',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF61DAFB),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Try again button
                        TextButton(
                          onPressed: () {
                            // Load new quiz and navigate back to quiz screen
                            final quizProvider = Provider.of<QuizProvider>(
                                context,
                                listen: false);
                            quizProvider.loadDailyQuiz();
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Try Again',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
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

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
