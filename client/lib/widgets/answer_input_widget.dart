import 'package:flutter/material.dart';
import '../services/speech_to_text_service.dart';

class AnswerInputWidget extends StatefulWidget {
  final SpeechToTextService speechService;
  final Function(String) onSubmit;

  const AnswerInputWidget({
    super.key,
    required this.speechService,
    required this.onSubmit,
  });

  @override
  State<AnswerInputWidget> createState() => _AnswerInputWidgetState();
}

class _AnswerInputWidgetState extends State<AnswerInputWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _isListening = false;
  bool _isSpeechAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkSpeechAvailability();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkSpeechAvailability() async {
    final isAvailable = await widget.speechService.initialize();
    setState(() {
      _isSpeechAvailable = isAvailable;
    });
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
    });

    final result = await widget.speechService.startListening();

    setState(() {
      _controller.text = result;
      _isListening = false;
    });
  }

  void _stopListening() {
    widget.speechService.stopListening();
    setState(() {
      _isListening = false;
    });
  }

  void _submitAnswer() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onSubmit(_controller.text.trim());
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Type your answer...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              if (_isSpeechAvailable)
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : null,
                  ),
                  onPressed: _isListening ? _stopListening : _startListening,
                  tooltip:
                      _isListening ? 'Stop listening' : 'Start speech to text',
                ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submitAnswer,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Submit Answer'),
          ),
        ],
      ),
    );
  }
}
