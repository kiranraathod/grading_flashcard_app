import 'package:flutter/material.dart';
import '../utils/design_system.dart';

class CreateDeckCard extends StatelessWidget {
  final VoidCallback onTap;

  const CreateDeckCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: DS.borderLarge,
          border: Border.all(
            color: Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 32, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                'Create New Deck',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
