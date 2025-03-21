import 'package:flutter/material.dart';

// XP Progress widget
class XPProgress extends StatelessWidget {
  final int currentXP;
  final int maxXP;
  final int level;

  const XPProgress({
    super.key,
    required this.currentXP,
    required this.maxXP,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = currentXP / maxXP;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Level $level',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$currentXP / $maxXP XP',
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF61DAFB), Color(0xFF2A6F97)],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
