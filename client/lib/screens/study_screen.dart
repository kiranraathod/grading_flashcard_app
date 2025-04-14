import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/study/study_bloc.dart';
import '../blocs/study/study_event.dart';
import '../blocs/study/study_state.dart';
import '../models/flashcard_set.dart';
import '../services/api_service.dart';
import '../services/speech_to_text_service.dart';
import '../utils/colors.dart';
import '../utils/design_system.dart';
import '../widgets/flashcard_widget.dart';
import '../widgets/answer_input_widget.dart';
import 'create_flashcard_screen.dart';
import 'result_screen.dart';

class StudyScreen extends StatelessWidget {
  final FlashcardSet set;
  
  const StudyScreen({super.key, required this.set});
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StudyBloc(
        apiService: ApiService(),
      )..add(StudyStarted(flashcardSet: set)),
      child: const StudyView(),
    );
  }
}

class StudyView extends StatefulWidget {
  const StudyView({super.key});

  @override
  State<StudyView> createState() => _StudyViewState();
}

class _StudyViewState extends State<StudyView> {
  late PageController _pageController;
  final SpeechToTextService _speechService = SpeechToTextService();
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _speechService.initialize();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  // Store a global key for the NavigatorState to be able to properly handle navigation
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  
  // Flag to track if result screen is currently displayed
  bool _isResultScreenShowing = false;
  
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StudyBloc, StudyState>(
      listener: (context, state) {
        // Handle error messages
        if (state.status == StudyStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'An error occurred')),
          );
        }
        
        // Update page controller when index changes
        if (_pageController.hasClients && 
            _pageController.page?.round() != state.currentIndex) {
          _pageController.animateToPage(
            state.currentIndex,
            duration: DS.durationMedium,
            curve: Curves.easeInOut,
          );
        }
        
        // Show result screen when a graded answer is available
        if (state.status == StudyStatus.loaded && 
            state.gradedAnswer != null && 
            !_isResultScreenShowing) {
          
          _isResultScreenShowing = true;
          
          // Use WidgetsBinding to avoid showing the dialog during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Get the bloc before navigation to ensure we have the correct instance
            final bloc = BlocProvider.of<StudyBloc>(context);
            
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) {
                return ResultScreen(
                  answer: state.gradedAnswer!,
                  correctAnswer: state.currentFlashcard!.answer,
                  onContinue: () {
                    // First dispatch the event to move to the next card
                    bloc.add(NextFlashcardRequested());
                    
                    // After a short delay, close the dialog to ensure state update happens first
                    Future.delayed(Duration(milliseconds: 100), () {
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                        _isResultScreenShowing = false;
                      }
                    });
                  },
                );
              },
            );
          });
        }
      },
      builder: (context, state) {
        final bloc = context.read<StudyBloc>();
        
        return Scaffold(
          appBar: AppBar(
            title: Text(state.flashcardSet?.title ?? 'Study'),
            actions: [
              // Edit button
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit this flashcard set',
                onPressed: () {
                  bloc.add(EditFlashcardSetRequested());
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateFlashcardScreen(
                        editSet: state.flashcardSet!,
                      ),
                    ),
                  );
                },
              ),
              // Bookmark button
              IconButton(
                icon: Icon(
                  state.isMarkedForReview ? Icons.bookmark : Icons.bookmark_border,
                  color: state.isMarkedForReview ? Colors.orange : null,
                ),
                tooltip: 'Mark for review',
                onPressed: () {
                  if (state.currentFlashcard != null) {
                    bloc.add(
                      FlashcardMarkedForReview(
                        flashcard: state.currentFlashcard!,
                        isMarked: !state.isMarkedForReview,
                      ),
                    );
                  }
                },
              ),
              // More options
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    bloc.add(EditFlashcardSetRequested());
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateFlashcardScreen(
                          editSet: state.flashcardSet!,
                        ),
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit Set'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Stack(
            children: [
              // Always show the flashcard content
              Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        if (index != state.currentIndex) {
                          if (index > state.currentIndex) {
                            bloc.add(NextFlashcardRequested());
                          } else {
                            bloc.add(PreviousFlashcardRequested());
                          }
                        }
                      },
                      itemCount: state.flashcardSet?.flashcards.length ?? 0,
                      itemBuilder: (context, index) {
                        return FlashcardWidget(
                          flashcard: state.flashcardSet!.flashcards[index],
                        );
                      },
                    ),
                  ),
                  AnswerInputWidget(
                    speechService: _speechService,
                    onSubmit: (answer) {
                      if (state.currentFlashcard != null) {
                        // Simply dispatch the event, the listener will handle showing the result
                        bloc.add(
                          FlashcardAnswered(
                            answer: answer,
                            flashcard: state.currentFlashcard!,
                          ),
                        );
                      }
                    },
                    isDisabled: state.status == StudyStatus.grading,
                  ),
                  Padding(
                    padding: EdgeInsets.all(DS.spacingM),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: state.canGoPrevious && state.status != StudyStatus.grading
                              ? () => bloc.add(PreviousFlashcardRequested())
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textOnPrimary,
                          ),
                          child: const Text('Previous'),
                        ),
                        Text(
                          '${state.currentIndex + 1}/${state.flashcardSet?.flashcards.length ?? 0}',
                          style: DS.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: state.canGoNext && state.status != StudyStatus.grading
                              ? () => bloc.add(NextFlashcardRequested())
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textOnPrimary,
                          ),
                          child: const Text('Next'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Show loading overlay during grading
              if (state.status == StudyStatus.grading)
                Container(
                  color: Color.fromRGBO(0, 0, 0, 0.5),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                        SizedBox(height: DS.spacingM),
                        Text(
                          'Grading your answer...',
                          style: DS.bodyLarge.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}