import 'package:flutter/material.dart';
import 'create_flashcard_screen.dart';

class ImportModalScreen extends StatelessWidget {
  const ImportModalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildOption(
            context,
            icon: Icons.cloud_download,
            iconColor: Colors.blue,
            title: 'Import flashcards',
            onTap: () {
              Navigator.pop(context);
              // Navigate to import screen - to be implemented
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Import feature coming soon')),
              );
            },
          ),
          _buildOption(
            context,
            icon: Icons.description,
            iconColor: Colors.grey,
            title: 'Flashcards',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateFlashcardScreen(),
                ),
              );
            },
          ),
          _buildOption(
            context,
            icon: Icons.create_new_folder,
            iconColor: Colors.grey,
            title: 'Create folder',
            onTap: () {
              Navigator.pop(context);
              // Folder creation to be implemented
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Folder creation coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withAlpha(30),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title),
      onTap: onTap,
    );
  }
}
