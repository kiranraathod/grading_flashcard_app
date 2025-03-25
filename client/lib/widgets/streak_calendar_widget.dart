import 'package:flutter/material.dart';

class StreakCalendarWidget extends StatelessWidget {
  final List<bool> streakDays;
  final int currentDay;

  const StreakCalendarWidget({
    super.key,
    required this.streakDays,
    required this.currentDay,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Learn how to start a streak',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final isActive = streakDays[index];
                final isCurrentDay = index == currentDay;

                return Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color:
                            isActive
                                ? Colors.grey.shade300
                                : Colors.grey.shade200,
                        shape: BoxShape.circle,
                        border:
                            isCurrentDay
                                ? Border.all(
                                  color: Colors.orange,
                                  width: 2,
                                  style: BorderStyle.solid,
                                )
                                : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getDayLabel(index),
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayLabel(int index) {
    switch (index) {
      case 0:
        return 'S';
      case 1:
        return 'M';
      case 2:
        return 'T';
      case 3:
        return 'W';
      case 4:
        return 'T';
      case 5:
        return 'F';
      case 6:
        return 'S';
      default:
        return '';
    }
  }
}
