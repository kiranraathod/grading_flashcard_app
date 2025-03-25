import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/flashcard.dart';
import '../models/flashcard_set.dart';
import '../services/flashcard_service.dart';
import '../widgets/flashcard_term_widget.dart';

class CreateFlashcardScreen extends StatefulWidget {
  final FlashcardSet? editSet;

  const CreateFlashcardScreen({super.key, this.editSet});

  @override
  State<CreateFlashcardScreen> createState() => _CreateFlashcardScreenState();
}

class _CreateFlashcardScreenState extends State<CreateFlashcardScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _showDescription = false;
  List<Flashcard> _flashcards = [];

  @override
  void initState() {
    super.initState();
    if (widget.editSet != null) {
      _titleController.text = widget.editSet!.title;
      _descriptionController.text = widget.editSet!.description;
      _showDescription = widget.editSet!.description.isNotEmpty;
      _flashcards = List.from(widget.editSet!.flashcards);
    } else {
      // Initialize with two empty cards
      _addNewCard();
      _addNewCard();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addNewCard() {
    setState(() {
      _flashcards.add(
        Flashcard(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          question: '',
          answer: '',
        ),
      );
    });
  }

  void _updateCard(int index, String question, String answer) {
    setState(() {
      _flashcards[index] = Flashcard(
        id: _flashcards[index].id,
        question: question,
        answer: answer,
      );
    });
  }

  void _removeCard(int index) {
    setState(() {
      _flashcards.removeAt(index);
    });
  }

  void _saveFlashcardSet() async {
    // Remove empty flashcards
    final validFlashcards = _flashcards.where(
      (card) => card.question.isNotEmpty || card.answer.isNotEmpty
    ).toList();
    
    if (validFlashcards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one flashcard')),
      );
      return;
    }
    
    final flashcardService = Provider.of<FlashcardService>(context, listen: false);
    
    final newSet = FlashcardSet(
      id: widget.editSet?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.isNotEmpty ? _titleController.text : 'Untitled',
      description: _descriptionController.text,
      flashcards: validFlashcards,
      isDraft: true,
    );
    
    if (widget.editSet != null) {
      await flashcardService.updateFlashcardSet(newSet);
    } else {
      await flashcardService.createFlashcardSet(newSet);
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Flashcard set saved')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Flashcards'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _saveFlashcardSet,
              icon: const Icon(Icons.edit),
              label: const Text('Create'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF03DAC6),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Title',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Enter Title',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (!_showDescription)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _showDescription = true;
                    });
                  },
                  child: const Text('+ Add description'),
                ),
              ),
            if (_showDescription)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Enter Description',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _flashcards.length,
              separatorBuilder: (context, index) => Center(
                child: IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _addNewCard,
                ),
              ),
              itemBuilder: (context, index) {
                return FlashcardTermWidget(
                  initialTerm: _flashcards[index].question,
                  initialDefinition: _flashcards[index].answer,
                  onUpdate: (term, definition) {
                    _updateCard(index, term, definition);
                  },
                  onDelete: () => _removeCard(index),
                );
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _addNewCard,
              ),
            ),
            const SizedBox(height: 80), // Extra space for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewCard,
        backgroundColor: const Color(0xFF1A5E34),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
