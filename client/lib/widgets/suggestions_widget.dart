import 'package:flutter/material.dart';

class SuggestionsWidget extends StatelessWidget {
  final List<String> suggestions;
  final String title;

  const SuggestionsWidget({
    super.key, 
    required this.suggestions,
    this.title = 'Improvement Suggestions',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  title.contains('Trouble') 
                      ? Icons.warning_amber_outlined 
                      : Icons.lightbulb_outline,
                  color: title.contains('Trouble') ? Colors.orange : Colors.amber,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...suggestions.map(
              (suggestion) => _buildSuggestionItem(suggestion),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(String suggestion) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.arrow_right, 
            color: title.contains('Trouble') ? Colors.orange : Colors.blue,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(suggestion)),
        ],
      ),
    );
  }
}
