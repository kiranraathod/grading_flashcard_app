import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../blocs/study/study_bloc.dart';
import '../blocs/study/study_event.dart';
import '../blocs/study/study_state.dart';
import '../models/flashcard_set.dart';
import '../services/api_service.dart';
import '../services/flashcard_service.dart';
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
    // Get a reference to the FlashcardService for updating progress
    final flashcardService = Provider.of<FlashcardService>(context, listen: false);
    
    // Create the bloc outside the build method to ensure it persists
    final studyBloc = StudyBloc(apiService: ApiService())
      ..add(StudyStarted(flashcardSet: set));
      
    return MultiBlocProvider(
      providers: [
        BlocProvider<StudyBloc>.value(
          value: studyBloc,
        ),
      ],
      child: Builder(
        builder: (context) {
          return WillPopScope(
            // Capture when user navigates back
            onWillPop: () async {
              try {
                final bloc = BlocProvider.of<StudyBloc>(context);
                if (bloc.state.flashcardSet != null) {
                  // Save progress when navigating back
                  await flashcardService.updateFlashcardSet(bloc.state.flashcardSet!);
                  debugPrint('Progress saved on back navigation');
                }
              } catch (e) {
                debugPrint('Error saving progress on back: $e');
              }
              return true;
            },
            child: StudyView(
              flashcardService: flashcardService,
            ),
          );
        }
      ),
    );
  }
}

class StudyView extends StatefulWidget {
  final FlashcardService flashcardService;
  
  const StudyView({super.key, required this.flashcardService});

  @override
  State<StudyView> createState() => _StudyViewState();
}

class _StudyViewState extends State<StudyView> with WidgetsBindingObserver {
  late PageController _pageController;
  final SpeechToTextService _speechService = SpeechToTextService();
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _speechService.initialize();
    
    // Add lifecycle observer to catch app pauses/resumes
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Save progress when app is paused or inactive
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveProgress();
    }
  }
  
  void _saveProgress() {
    final bloc = context.read<StudyBloc>();
    if (bloc.state.flashcardSet != null) {
      // Save immediately when a card is completed
      debugPrint('Saving progress from lifecycle change');
      widget.flashcardService.updateFlashcardSet(bloc.state.flashcardSet!);
    }
  }
  
  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }
  
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
          
          // Get the bloc before navigation to ensure we have the correct instance
          final bloc = BlocProvider.of<StudyBloc>(context);
          
          // IMPORTANT: Save progress immediately when a card is completed
          if (state.gradedAnswer!.grade == 'A' || 
              state.gradedAnswer!.grade == 'B' || 
              state.gradedAnswer!.grade == 'C') {
            // This is the critical part - save immediately after grading
            debugPrint('Saving progress after correct answer');
            widget.flashcardService.updateFlashcardSet(state.flashcardSet!);
          }
          
          // Use WidgetsBinding to avoid showing the dialog during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // Save progress before navigating back
                if (bloc.state.flashcardSet != null) {
                  debugPrint('Saving progress from manual back button');
                  widget.flashcardService.updateFlashcardSet(bloc.state.flashcardSet!);
                }
                // Use Navigator.of(context).pop() to ensure we're going back properly
                Navigator.of(context).pop();
              },
            ),
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
                  // Add Back button for web view
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: ElevatedButton(
                        onPressed: () {
                          // Save progress before navigating back
                          if (bloc.state.flashcardSet != null) {
                            debugPrint('Saving progress from web view back button');
                            widget.flashcardService.updateFlashcardSet(bloc.state.flashcardSet!);
                          }
                          // Use Navigator.of(context).pop() to ensure we're going back properly
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.black87,
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  ),
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
                        // Show a brief loading indicator to indicate processing
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Processing your answer...'),
                            duration: Duration(milliseconds: 500),
                          )
                        );
                        
                        // Dispatch the event, the listener will handle showing the result
                        // This is the only place where the answer is submitted and progress can be updated
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