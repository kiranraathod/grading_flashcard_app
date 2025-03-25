import 'package:flutter/material.dart';

class SuggestionsWidget extends StatelessWidget {
  final List<String> suggestions;

  const SuggestionsWidget({super.key, required this.suggestions});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Improvement Suggestions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
          const Icon(Icons.arrow_right, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text(suggestion)),
        ],
      ),
    );
  }
}
