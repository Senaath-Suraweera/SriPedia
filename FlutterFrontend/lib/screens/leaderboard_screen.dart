import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/leaderboard_provider.dart';
import '../widgets/neumorphic_widgets.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _selectedFilter = 'daily_quizzes';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);

    try {
      // Make sure we don't use the 'listen' parameter in a build method
      final provider = Provider.of<LeaderboardProvider>(context, listen: false);
      await provider.loadLeaderboard(category: _selectedFilter);
    } catch (e) {
      print('Error loading leaderboard: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load leaderboard: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Use this helper method to select a date and reload data
  void _handleDateChange(String newDate) {
    if (!mounted) return;

    // Get the provider without listening
    final provider = Provider.of<LeaderboardProvider>(context, listen: false);

    // Update the date without triggering a notification
    provider.setSelectedDate(newDate);

    // Schedule the reload after the current build is complete
    Future.microtask(() {
      if (mounted) {
        _loadLeaderboard();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: const Color(0xFF192734),
        elevation: 0,
      ),
      body: Consumer<LeaderboardProvider>(
        builder: (context, leaderboardProvider, child) {
          if (_isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF61DAFB)),
              ),
            );
          }

          if (leaderboardProvider.errorMessage != null) {
            return Center(
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
                    'Error: ${leaderboardProvider.errorMessage}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  NeumorphicButton(
                    onPressed: _loadLeaderboard,
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF61DAFB),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final leaderboardData = leaderboardProvider.leaderboardData;
          final dateOptions = leaderboardProvider.availableDates;

          if (leaderboardData.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.emoji_events,
                    color: Color(0xFF61DAFB),
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No leaderboard data available yet',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  if (dateOptions.isNotEmpty) const SizedBox(height: 24),
                  const Text(
                    'Try selecting a different date',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Filter row
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                color: const Color(0xFF192734),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter Leaderboard',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF252836),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            dropdownColor: const Color(0xFF252836),
                            style: const TextStyle(color: Colors.white),
                            value: _selectedFilter,
                            items: const [
                              DropdownMenuItem(
                                value: 'daily_quizzes',
                                child: Text('Daily Quizzes'),
                              ),
                              // Add other categories here if needed
                            ],
                            onChanged: (value) {
                              if (value != null && value != _selectedFilter) {
                                setState(() => _selectedFilter = value);
                                _loadLeaderboard();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (dateOptions.isNotEmpty)
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                filled: true,
                                fillColor: const Color(0xFF252836),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              dropdownColor: const Color(0xFF252836),
                              style: const TextStyle(color: Colors.white),
                              value: leaderboardProvider.selectedDate,
                              items: dateOptions
                                  .map((date) => DropdownMenuItem(
                                        value: date,
                                        child: Text(date),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null &&
                                    value != leaderboardProvider.selectedDate) {
                                  // Use the new handler method instead of directly calling methods
                                  _handleDateChange(value);
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Leaderboard header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: const [
                    SizedBox(width: 40),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'User',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Score',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),

              // Leaderboard list
              Expanded(
                child: ListView.builder(
                  itemCount: leaderboardData.length,
                  itemBuilder: (context, index) {
                    final entry = leaderboardData[index];
                    final isCurrentUser = leaderboardProvider
                        .isCurrentUser(entry['userId'] as String);
                    final position = index + 1;

                    // Background color based on position
                    Color itemColor = const Color(0xFF252836);
                    if (position == 1) {
                      itemColor = const Color(0xFF2A6F97).withOpacity(0.3);
                    } else if (position == 2) {
                      itemColor = const Color(0xFF2A6F97).withOpacity(0.2);
                    } else if (position == 3) {
                      itemColor = const Color(0xFF2A6F97).withOpacity(0.1);
                    } else if (isCurrentUser) {
                      itemColor = Colors.amber.withOpacity(0.1);
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: itemColor,
                        borderRadius: BorderRadius.circular(12),
                        border: isCurrentUser
                            ? Border.all(
                                color: const Color(0xFF61DAFB), width: 1.5)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: _buildPositionBadge(position),
                        title: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                entry['username'] as String? ?? 'Unknown User',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: isCurrentUser
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                '${entry['score']}',
                                style: TextStyle(
                                  color: _getScoreColor(position),
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPositionBadge(int position) {
    Color badgeColor;
    Widget content;

    switch (position) {
      case 1:
        badgeColor = Colors.amber;
        content = const Icon(Icons.emoji_events, color: Colors.white, size: 20);
        break;
      case 2:
        badgeColor = Colors.grey[300]!;
        content = Text(
          '$position',
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        );
        break;
      case 3:
        badgeColor = Colors.brown[300]!;
        content = Text(
          '$position',
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        );
        break;
      default:
        badgeColor = Colors.grey[700]!;
        content = Text(
          '$position',
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        );
    }

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
      ),
      child: Center(child: content),
    );
  }

  Color _getScoreColor(int position) {
    switch (position) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[300]!;
      case 3:
        return Colors.brown[300]!;
      default:
        return Colors.white;
    }
  }
}
