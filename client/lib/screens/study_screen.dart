import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../blocs/study/study_bloc.dart';
import '../blocs/study/study_event.dart';
import '../blocs/study/study_state.dart';
import '../blocs/recent_view/recent_view_bloc.dart';
import '../blocs/recent_view/recent_view_event.dart';
import '../models/flashcard_set.dart';
import '../models/simple_auth_state.dart';
import '../services/api_service.dart';
import '../services/flashcard_service.dart';
import '../services/speech_to_text_service.dart';
import '../services/unified_action_middleware.dart';
import '../utils/theme_utils.dart';
import '../utils/design_system.dart';
import '../utils/app_localizations_extension.dart';
import '../widgets/flashcard_widget.dart';
import '../widgets/answer_input_widget.dart';
import '../widgets/auth/authentication_modal.dart';
import 'create_flashcard_screen.dart';
import 'result_screen.dart';


class StudyScreen extends riverpod.ConsumerWidget {
  final FlashcardSet set;
  
  const StudyScreen({super.key, required this.set});
  
  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    // Get a reference to the FlashcardService for updating progress
    final flashcardService = Provider.of<FlashcardService>(context, listen: false);
    
    // 🔧 FIX: Capture ref for use in nested callbacks
    final widgetRef = ref;
    
    // 🆕 Use Consumer to get Riverpod ref for action tracking
    return riverpod.Consumer(
      builder: (context, ref, child) {
        // Create the study bloc with Riverpod ref for action tracking
        final studyBloc = StudyBloc(
          apiService: ApiService(),
          flashcardService: flashcardService,
          ref: ref, // 🆕 Pass Riverpod ref for action tracking
        )..add(StudyStarted(flashcardSet: set));
        
        // No longer create a new RecentViewBloc here as we're using the global one
        
        return BlocProvider<StudyBloc>.value(
          value: studyBloc,
          child: StudyView(
            flashcardService: flashcardService,
            widgetRef: widgetRef, // 🔧 FIX: Pass ref to StatefulWidget
          ),
        );
      },
    );
  }
}

class StudyView extends StatefulWidget {
  final FlashcardService flashcardService;
  final riverpod.WidgetRef widgetRef; // 🔧 FIX: Accept ref for authentication
  
  const StudyView({
    super.key, 
    required this.flashcardService,
    required this.widgetRef, // 🔧 FIX: Required ref parameter
  });

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
    
    // Record flashcard view when first opening a flashcard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Get the current state from the StudyBloc
      final studyState = context.read<StudyBloc>().state;
      
      // If we have a valid flashcard set and current flashcard, record the view
      if (studyState.flashcardSet != null && studyState.currentFlashcard != null) {
        context.read<RecentViewBloc>().add(
          RecordFlashcardView(
            flashcard: studyState.currentFlashcard!,
            set: studyState.flashcardSet!,
          ),
        );
      }
    });
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
        // Handle authentication required
        if (state.status == StudyStatus.authenticationRequired) {
          debugPrint('🚫 StudyScreen: Authentication required - showing auth modal');
          
          // 🔧 FIX: Dismiss result screen if it's showing to prevent conflicts
          if (_isResultScreenShowing) {
            debugPrint('🔧 StudyScreen: Dismissing result screen before showing auth modal');
            _isResultScreenShowing = false;
            if (context.mounted) {
              Navigator.of(context, rootNavigator: false).popUntil((route) => route.isFirst);
            }
          }
          
          // Show authentication modal
          AuthenticationModal.show(context).then((_) {
            debugPrint('🔍 StudyScreen: Auth modal dismissed');
            
            if (context.mounted) {
              // 🔧 FIX: Resume study session without resetting everything
              debugPrint('🔄 StudyScreen: Resuming study session after authentication');
              context.read<StudyBloc>().add(StudyResumedAfterAuth());
            }
          });
        }
        
        // Handle error messages
        if (state.status == StudyStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'An error occurred')),
          );
        }
        
        // Handle deck completion - navigate back to home screen
        if (state.status == StudyStatus.completed) {
          debugPrint('🏁 StudyScreen: Deck completed - navigating to home screen');
          
          // Use post frame callback to ensure navigation happens after build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(context).pop(); // Return to home screen
            }
          });
        }
        
        // Update page controller when index changes
        if (_pageController.hasClients && 
            _pageController.page?.round() != state.currentIndex) {
          _pageController.animateToPage(
            state.currentIndex,
            duration: DS.durationMedium,
            curve: Curves.easeInOut,
          );
          
          // Record flashcard view when changing to a new card
          if (state.flashcardSet != null && state.currentFlashcard != null) {
            context.read<RecentViewBloc>().add(
              RecordFlashcardView(
                flashcard: state.currentFlashcard!,
                set: state.flashcardSet!,
              ),
            );
          }
        }
        
        // Show result screen when a graded answer is available AND authentication is not required
        if (state.status == StudyStatus.loaded && 
            state.gradedAnswer != null && 
            !_isResultScreenShowing) {
          
          debugPrint('🎯 StudyScreen: Showing result dialog for graded answer (auth not required)');
          _isResultScreenShowing = true;
          
          // Get the bloc before navigation to ensure we have the correct instance
          final bloc = BlocProvider.of<StudyBloc>(context);
          
          // IMPORTANT: Save progress immediately when a card is completed
          if ((state.gradedAnswer!.score ?? 0) >= 70) {
            // This is the critical part - save immediately after grading
            debugPrint('Saving progress after correct answer');
            widget.flashcardService.updateFlashcardSet(state.flashcardSet!);
            
            // FIXED: Record the view again to update timestamp in Recent tab
            if (state.currentFlashcard != null) {
              context.read<RecentViewBloc>().add(
                RecordFlashcardView(
                  flashcard: state.currentFlashcard!,
                  set: state.flashcardSet!,
                ),
              );
              debugPrint('Recorded flashcard view after grading');
            }
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
                    // Check if we're on the last card
                    if (state.isLastCard) {
                      // Complete the deck instead of trying to go next
                      debugPrint('🏁 Continue from last card - completing deck');
                      bloc.add(DeckCompleted());
                    } else {
                      // Move to next card
                      debugPrint('🔄 Continue to next card');
                      bloc.add(NextFlashcardRequested());
                    }
                    
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
            title: Text(state.flashcardSet?.title ?? AppLocalizations.of(context).study),
            actions: [
              // Edit button
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: AppLocalizations.of(context).editSet,
                onPressed: () async {
                  bloc.add(EditFlashcardSetRequested());
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateFlashcardScreen(
                        editSet: state.flashcardSet!,
                      ),
                    ),
                  );
                  
                  // After returning from edit screen, refresh the flashcard set in StudyBloc
                  final updatedSet = widget.flashcardService.getFlashcardSet(state.flashcardSet!.id);
                  if (updatedSet != null) {
                    bloc.add(UpdateFlashcardSet(flashcardSet: updatedSet));
                    debugPrint('StudyBloc updated with edited flashcard set');
                  }
                },
              ),
              // Bookmark button
              IconButton(
                icon: Icon(
                  state.isMarkedForReview ? Icons.bookmark : Icons.bookmark_border,
                  color: state.isMarkedForReview ? context.warningColor : null,
                ),
                tooltip: AppLocalizations.of(context).markForReview,
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
                onSelected: (value) async {
                  if (value == 'edit') {
                    bloc.add(EditFlashcardSetRequested());
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateFlashcardScreen(
                          editSet: state.flashcardSet!,
                        ),
                      ),
                    );
                    
                    // After returning from edit screen, refresh the flashcard set in StudyBloc
                    final updatedSet = widget.flashcardService.getFlashcardSet(state.flashcardSet!.id);
                    if (updatedSet != null) {
                      bloc.add(UpdateFlashcardSet(flashcardSet: updatedSet));
                      debugPrint('StudyBloc updated with edited flashcard set');
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text(AppLocalizations.of(context).editSetMenuItem),
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
                          backgroundColor: context.surfaceColor,
                          foregroundColor: context.onSurfaceColor,
                        ),
                        child: Text(AppLocalizations.of(context).back),
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
                    onSubmit: (answer) async {
                      if (state.currentFlashcard != null) {
                        // 🎯 NEW: Authentication enforcement at UI level
                        final middleware = widget.widgetRef.read(unifiedActionMiddlewareProvider);
                        
                        // Check if user can perform this action (shows auth modal if needed)
                        final canProceed = await middleware.checkQuotaOnly(
                          ActionType.flashcardGrading,
                          context: context,
                          source: 'StudyScreen.onSubmit',
                        );
                        
                        if (!canProceed) {
                          debugPrint('🚫 StudyScreen: Action blocked by quota enforcement');
                          // Don't proceed with grading - user cancelled or still blocked
                          return;
                        }
                        
                        debugPrint('✅ StudyScreen: Quota check passed - proceeding with grading');
                        
                        // 🔧 FIX: Check if widget is still mounted before using context
                        if (!mounted) return;
                        
                        // Show a brief loading indicator to indicate processing
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context).processingAnswer),
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
                    isDisabled: state.status == StudyStatus.grading || state.status == StudyStatus.authenticationRequired,
                  ),
                  Padding(
                    padding: EdgeInsets.all(DS.spacingM),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: state.canGoPrevious && state.status != StudyStatus.grading && state.status != StudyStatus.authenticationRequired
                              ? () => bloc.add(PreviousFlashcardRequested())
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.primaryColor,
                            foregroundColor: context.onPrimaryColor,
                          ),
                          child: Text(AppLocalizations.of(context).previous),
                        ),
                        Text(
                          AppLocalizations.of(context).cardCountFormat(
                            state.currentIndex + 1, 
                            state.flashcardSet?.flashcards.length ?? 0
                          ),
                          style: context.titleMedium,
                        ),
                        ElevatedButton(
                          onPressed: (state.canGoNext || state.isLastCard) && 
                                   state.status != StudyStatus.grading && 
                                   state.status != StudyStatus.authenticationRequired
                              ? () {
                                  if (state.isLastCard) {
                                    // On last card, complete the deck
                                    bloc.add(DeckCompleted());
                                  } else {
                                    // On other cards, go to next
                                    bloc.add(NextFlashcardRequested());
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: state.isLastCard 
                                ? context.successColor  // Different color for finish
                                : context.primaryColor,
                            foregroundColor: context.onPrimaryColor,
                          ),
                          child: Text(
                            state.isLastCard 
                                ? "Finish"  // Hardcoded for now - can be localized later
                                : AppLocalizations.of(context).next
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Show loading overlay during grading
              if (state.status == StudyStatus.grading)
                Container(
                  color: context.surfaceColor.withOpacityFix(0.5),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
                        ),
                        SizedBox(height: DS.spacingM),
                        Text(
                          L10nExt.of(context).gradingAnswer,
                          style: context.bodyLarge?.copyWith(color: context.onSurfaceColor),
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