import 'package:flutter/material.dart';
import '../utils/colors.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Logo
          Row(
            children: [
              Icon(Icons.book_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'FlashMaster',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 24),
          
          // Search bar
          Expanded(
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey.shade400, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Find flashcards on any topic',
                        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.only(bottom: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // User actions (simplified)
          IconButton(
            icon: Icon(Icons.emoji_events_outlined, color: Colors.grey.shade600, size: 20),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            splashRadius: 20,
          ),
          
          const SizedBox(width: 12),
          
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Colors.grey.shade600, size: 20),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            splashRadius: 20,
          ),
          
          const SizedBox(width: 12),
          
          // Profile button (simplified)
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.grey.shade200,
            child: const Icon(Icons.person, color: Colors.grey, size: 16),
          ),
          
          Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400, size: 14),
        ],
      ),
    );
  }
}