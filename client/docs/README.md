# Flashcard Application Documentation

Welcome to the documentation for the Flashcard Application. This directory contains guides, implementation details, and references for various aspects of the application.

## Table of Contents

1. [Theme Documentation](#theme-documentation)
2. [Feature Implementation Guides](#feature-implementation-guides)
3. [UI Improvements](#ui-improvements)
4. [Bug Fixes](#bug-fixes)

## Theme Documentation

The app uses a comprehensive Material 3-based theming system with support for light and dark modes.

- **[Theme Documentation](theme_documentation/README.md)** - Main theme documentation index
  - [Grey Theme Implementation](theme_documentation/grey_theme_implementation.md) - Previous grey theme details
  - [Teal Color Implementation](theme_documentation/teal_color_implementation.md) - Current teal theme implementation guide
  - [Teal Color Implementation Report](theme_documentation/teal_color_implementation_report.md) - Migration report from grey to teal
  - [Teal UI Components Guide](theme_documentation/teal_ui_components_guide.md) - Visual guide to UI components with teal theme

## Feature Implementation Guides

Detailed guides for implementing specific features in the application.

- **[Job Description Question Generator](job_description_question_generator.md)** - Implementation guide for generating interview questions from job descriptions
- **[Recent Tab Implementation](features/recent_tab_implementation.md)** - Documentation for the Recent tab feature implementation
- **[Mock Interview Simulation](features/mock_interview_simulation.md)** - Guide for the mock interview simulation feature

## UI Improvements

Documentation for UI enhancements and improvements.

- **[Dark Mode UI Improvements](ui_improvements/dark_mode_ui_improvements.md)** - Enhancements to improve dark mode readability
- **[View Answer Improvements](ui_improvements/view_answer_improvements.md)** - Changes to improve the View Answer button

## Bug Fixes

Details about bug fixes and code improvements.

- **[Answer View Dark Mode Fix](bug_fixes/answer_view_dark_mode_fix.md)** - Fix for answer view visibility in dark mode
- **[Deprecated Method Fixes](bug_fixes/deprecated_method_fixes.md)** - Fixes for deprecated withOpacity methods
- **[Deprecation and Dead Code Fixes](bug_fixes/deprecation_and_dead_code_fixes.md)** - Comprehensive fixes for deprecation warnings
- **[Interview Question Card Fixes](bug_fixes/interview_question_card_fixes.md)** - Fixes for interview question cards

## Contributing to Documentation

When adding new documentation:

1. Place implementation guides in the appropriate category folder
2. Update this README.md with links to new documentation
3. Use Markdown formatting for consistency
4. Include code examples where relevant
5. Add screenshots for visual components

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Material 3 Design Guidelines](https://m3.material.io/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)