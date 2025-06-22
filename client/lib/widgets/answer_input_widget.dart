import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/theme_utils.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AnswerInputWidget extends StatefulWidget {
  final Function(String) onSubmit;
  final bool isDisabled;

  const AnswerInputWidget({
    super.key,
    required this.onSubmit,
    this.isDisabled = false,
  });

  @override
  State<AnswerInputWidget> createState() => _AnswerInputWidgetState();
}

class _AnswerInputWidgetState extends State<AnswerInputWidget> {
  final TextEditingController _controller = TextEditingController();
  int _wordCount = 0;
  static const int _maxWords = 200;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateWordCount);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateWordCount);
    _controller.dispose();
    super.dispose();
  }

  void _updateWordCount() {
    final text = _controller.text.trim();
    final words = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    setState(() {
      _wordCount = words;
    });
  }

  void _submitAnswer() {
    if (_controller.text.trim().isEmpty) {
      return;
    }
    
    if (_wordCount > _maxWords) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Answer exceeds $_maxWords word limit. Please shorten your response.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    widget.onSubmit(_controller.text.trim());
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Hint text about progress tracking
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: context.surfaceVariantColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: context.outlineColor),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: context.infoColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).submitToTrackProgress,
                    style: context.bodySmall?.copyWith(
                      color: context.onSurfaceVariantColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).typeYourAnswer,
              border: OutlineInputBorder(),
              helperText: '$_wordCount/$_maxWords words',
              helperStyle: TextStyle(
                color: _wordCount > _maxWords 
                    ? context.errorColor 
                    : context.onSurfaceVariantColor,
                fontSize: 12,
              ),
            ),
            maxLines: 3,
            minLines: 1,
            enabled: !widget.isDisabled,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: (widget.isDisabled || _wordCount > _maxWords) ? null : _submitAnswer,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: _wordCount > _maxWords ? Colors.grey : AppColors.primary,
              foregroundColor: context.onPrimaryColor,
            ),
            icon: const Icon(Icons.send),
            label: Text(AppLocalizations.of(context).submitAnswerUpdateProgress),
          ),
        ],
      ),
    );
  }
}
