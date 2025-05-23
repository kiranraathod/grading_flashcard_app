import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/design_system.dart';
import '../utils/theme_utils.dart';

class StreakCalendarWidget extends StatelessWidget {
  final int streakDays;
  final int weeklyGoal;
  final int daysCompleted;
  final List<String> weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  StreakCalendarWidget({
    super.key,
    required this.streakDays,
    required this.weeklyGoal,
    required this.daysCompleted,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate progress percentage
    final int progressPercent = (daysCompleted / weeklyGoal * 100).round();

    return Container(
      padding: const EdgeInsets.all(DS.spacingL),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: DS.borderLarge,
        border: Border.all(color: context.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Learning Streak',
                    style: context.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Keep studying daily to build your streak!',
                    style: context.bodyMedium?.copyWith(
                      color: context.onSurfaceVariantColor,
                    ),
                  ),
                ],
              ),
              
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: DS.borderMedium,
                  border: Border.all(
                    color: context.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 16,
                      color: context.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$streakDays Day Streak',
                      style: context.bodySmall?.copyWith(
                        color: context.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Calendar
          Container(
            margin: const EdgeInsets.only(top: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                // Determine the day style
                bool isToday = index == 1; // Mock: Monday is today
                bool isPast = index < 1; // Days before today
                
                Color bgColor = Colors.grey.shade100;
                Color textColor = Colors.grey.shade400;
                Border? border;
                
                if (isToday) {
                  bgColor = Color.fromRGBO(16, 185, 129, 0.1); // AppColors.primary with 0.1 opacity
                  textColor = AppColors.primary;
                  border = Border.all(
                    color: AppColors.primary,
                    width: 2,
                  );
                } else if (isPast) {
                  bgColor = AppColors.primary;
                  textColor = Colors.white;
                }
                
                return Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                        border: border,
                      ),
                      child: Center(
                        child: Text(
                          weekdays[index],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isToday ? 'Today' : '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          
          // Progress bar
          Container(
            margin: const EdgeInsets.only(top: 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Weekly Goal: $daysCompleted/$weeklyGoal days',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '$progressPercent%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 
                            (progressPercent / 100) * 0.75, // Adjust for padding
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}