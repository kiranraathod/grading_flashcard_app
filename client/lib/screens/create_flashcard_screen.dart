import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/flashcard.dart';
import '../models/flashcard_set.dart';
import '../services/flashcard_service.dart';
import '../widgets/flashcard_term_widget.dart';
import '../screens/import_modal_screen.dart';
import '../widgets/multi_action_fab.dart';
import '../utils/theme_utils.dart';
import 'create_interview_question_screen.dart';

class CreateFlashcardScreen extends StatefulWidget {
  final FlashcardSet? editSet;

  const CreateFlashcardScreen({super.key, this.editSet});

  @override
  State<CreateFlashcardScreen> createState() => _CreateFlashcardScreenState();
}

class _CreateFlashcardScreenState extends State<CreateFlashcardScreen> {
  final _titleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final List<Map<String, TextEditingController>> _terms = [];
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.editSet != null) {
      _isEditMode = true;
      _titleController.text = widget.editSet!.title;
      
      for (var flashcard in widget.editSet!.flashcards) {
        _terms.add({
          'term': TextEditingController(text: flashcard.question),
          'definition': TextEditingController(text: flashcard.answer),
        });
      }
    } else {
      _addTerm();
    }
  }

  void _addTerm() {
    setState(() {
      _terms.add({
        'term': TextEditingController(),
        'definition': TextEditingController(),
      });
    });
  }

  void _removeTerm(int index) {
    setState(() {
      _terms[index]['term']?.dispose();
      _terms[index]['definition']?.dispose();
      _terms.removeAt(index);
    });
  }

  void _saveFlashcardSet() async {
    if (_formKey.currentState!.validate()) {
      final flashcardService = Provider.of<FlashcardService>(context, listen: false);

      List<Flashcard> flashcards = _terms.map((term) {
        return Flashcard(
          id: '${DateTime.now().millisecondsSinceEpoch}_${_terms.indexOf(term)}',
          question: term['term']!.text,
          answer: term['definition']!.text,
        );
      }).toList();

      if (_isEditMode) {
        // Update existing set
        FlashcardSet updatedSet = widget.editSet!.copyWith(
          title: _titleController.text,
          description: '', // Empty description since field is removed
          flashcards: flashcards,
        );
        
        await flashcardService.updateFlashcardSet(updatedSet);
      } else {
        // Create new set
        FlashcardSet newSet = FlashcardSet(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          description: '', // Empty description since field is removed
          flashcards: flashcards,
        );

        await flashcardService.createFlashcardSet(newSet);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var term in _terms) {
      term['term']?.dispose();
      term['definition']?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.onSurfaceColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditMode ? 'Edit Flashcards' : 'Create Flashcards',
          style: TextStyle(color: context.onSurfaceColor),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const ImportModalScreen(),
            ),
          ),
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () {
                if (_terms.isNotEmpty) {
                  _saveFlashcardSet();
                }
              },
              icon: const Icon(Icons.check),
              label: Text(_isEditMode ? 'Update' : 'Create'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: context.onPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                style: context.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Enter Title',
                  hintStyle: context.bodyMedium?.copyWith(
                    color: context.onSurfaceVariantColor,
                  ),
                  filled: true,
                  fillColor: context.surfaceVariantColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                    borderSide: BorderSide(
                      color: context.primaryColor,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              for (int i = 0; i < _terms.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: FlashcardTermWidget(
                    initialTerm: _terms[i]['term']!.text,
                    initialDefinition: _terms[i]['definition']!.text,
                    onUpdate: (term, definition) {
                      _terms[i]['term']!.text = term;
                      _terms[i]['definition']!.text = definition;
                    },
                    onDelete: () => _removeTerm(i),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: MultiActionFab(
        backgroundColor: context.primaryColor,
        tooltip: 'Create new content',
        options: [
          MultiActionFabOption(
            label: 'Add Term',
            icon: Icons.add_card,
            onTap: _addTerm,
          ),
          MultiActionFabOption(
            label: 'Create Interview Question',
            icon: Icons.question_answer,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateInterviewQuestionScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
