import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/flashcard_set.dart';
import '../screens/study_screen.dart';
import '../screens/create_flashcard_screen.dart';
import 'package:provider/provider.dart';
import '../services/flashcard_service.dart';

class FlashcardSetListWidget extends StatelessWidget {
  final List<FlashcardSet> flashcardSets;
  
  const FlashcardSetListWidget({
    super.key,
    required this.flashcardSets,
  });
  
  // Method to handle editing a flashcard set
  void _editSet(BuildContext context, FlashcardSet set) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateFlashcardScreen(editSet: set),
      ),
    );
  }
  
  // Method to handle deleting a flashcard set
  void _deleteSet(BuildContext context, FlashcardSet set) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).deleteFlashcardSet),
        content: Text(AppLocalizations.of(context).deleteConfirmation(set.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () {
              final flashcardService = Provider.of<FlashcardService>(context, listen: false);
              flashcardService.deleteFlashcardSet(set.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context).setDeletedMessage(set.title))),
              );
            },
            child: Text(AppLocalizations.of(context).delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  // Show the options menu for a flashcard set
  void _showOptions(BuildContext context, FlashcardSet set) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: Text(AppLocalizations.of(context).editFlashcardSet),
            onTap: () {
              Navigator.pop(context);
              _editSet(context, set);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: Text(AppLocalizations.of(context).deleteFlashcardSet),
            onTap: () {
              Navigator.pop(context);
              _deleteSet(context, set);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: flashcardSets.length,
      itemBuilder: (context, index) {
        final set = flashcardSets[index];
        
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudyScreen(set: set),
              ),
            );
          },
          onLongPress: () => _showOptions(context, set),
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey.shade200,
                        child: Icon(
                          Icons.description,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              set.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context).termsCount(set.termCount),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.star_border,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${set.rating} (${set.ratingCount})',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        tooltip: AppLocalizations.of(context).moreOptions,
                        onPressed: () => _showOptions(context, set),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
