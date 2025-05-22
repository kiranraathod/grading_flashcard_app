import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/design_system.dart';
import '../utils/spacing_components.dart';

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
            label: AppLocalizations.of(context).termLabel,
            controller: _termController,
            hasImageOption: true,
          ),
          DSSpacing.verticalL,
          _buildInputField(
            label: AppLocalizations.of(context).definitionLabel,
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
            width: DS.buttonHeightXl + 4, // 60px
            height: DS.buttonHeightXl + 4, // 60px
            margin: EdgeInsets.only(right: DS.spacingM),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade300,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
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
                borderRadius: BorderRadius.circular(DS.borderRadiusLarge),
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
