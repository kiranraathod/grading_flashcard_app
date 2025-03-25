import 'package:flutter/material.dart';

class FlashcardTermWidget extends StatefulWidget {
  final String initialTerm;
  final String initialDefinition;
  final Function(String, String) onUpdate;
  final VoidCallback onDelete;

  const FlashcardTermWidget({
    super.key,
    this.initialTerm = '',
    this.initialDefinition = '',
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<FlashcardTermWidget> createState() => _FlashcardTermWidgetState();
}

class _FlashcardTermWidgetState extends State<FlashcardTermWidget> {
  late TextEditingController _termController;
  late TextEditingController _definitionController;

  @override
  void initState() {
    super.initState();
    _termController = TextEditingController(text: widget.initialTerm);
    _definitionController = TextEditingController(text: widget.initialDefinition);
    
    _termController.addListener(_notifyUpdate);
    _definitionController.addListener(_notifyUpdate);
  }

  @override
  void dispose() {
    _termController.removeListener(_notifyUpdate);
    _definitionController.removeListener(_notifyUpdate);
    _termController.dispose();
    _definitionController.dispose();
    super.dispose();
  }

  void _notifyUpdate() {
    widget.onUpdate(_termController.text, _definitionController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          _buildInputField(
            label: 'Term',
            controller: _termController,
            hasImageOption: true,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Definition',
            controller: _definitionController,
            hasImageOption: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool hasImageOption = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasImageOption)
          Container(
            width: 60,
            height: 60,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade300,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.image,
              color: Colors.grey.shade400,
            ),
          ),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: label,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            maxLines: null,
          ),
        ),
      ],
    );
  }
}
