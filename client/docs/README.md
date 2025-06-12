# Flashcard Application Documentation

Welcome to the documentation for the Flashcard Application. This directory contains guides, implementation details, and references for various aspects of the application.

## 🤖 Claude 4 Sonnet Quick Start Guides

- **[Claude RenderFlex Context Guide](CLAUDE_RENDERFLEX_CONTEXT_GUIDE.md)** - Essential instructions for Claude 4 Sonnet to quickly understand RenderFlex overflow issues and implement proper fixes
- **[General Codebase Context](../../../paste.txt)** - Comprehensive context instructions for understanding the overall project architecture and development patterns

## Table of Contents

1. [Performance Optimization](#performance-optimization)
2. [Authentication System](#authentication-system)
3. [Theme Documentation](#theme-documentation)
4. [Feature Implementation Guides](#feature-implementation-guides)
5. [UI Improvements](#ui-improvements)
6. [Bug Fixes](#bug-fixes)

## Performance Optimization

Documentation for storage and performance improvements across the application.

- **[UserService Hive Migration](performance_optimization/userservice_hive_migration.md)** - Complete migration from SharedPreferences to Hive for UserService
- **[UserService Migration Complete](performance_optimization/userservice_migration_complete.md)** - Implementation completion summary and validation

## Authentication System

Comprehensive documentation for the Flutter authentication system implementation, covering architecture decisions, challenges, patterns, and future recommendations.

- **[Authentication Documentation](authentication/README.md)** - Main authentication documentation index
  - [Implementation Approach](authentication/01_implementation_approach.md) - Complete architecture overview and implementation philosophy
  - [Challenges and Solutions](authentication/02_challenges_and_solutions.md) - Detailed problem-solving documentation for common issues
  - [Patterns and Best Practices](authentication/03_patterns_and_best_practices.md) - Proven patterns for state management, UI, storage, and testing
  - [Future Recommendations](authentication/04_future_recommendations.md) - Strategic roadmap for continued development and improvements

**Key Topics Covered:**
- Riverpod vs Provider state management decisions
- Guest user management with usage limits (3/5 actions)
- Supabase integration with secure storage
- Platform-specific authentication modals
- Guest-to-authenticated data migration patterns
- Cross-feature authentication state management
- Import conflict resolution and compilation fixes

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

- **[Claude RenderFlex Context Guide](CLAUDE_RENDERFLEX_CONTEXT_GUIDE.md)** - Comprehensive instructions for Claude 4 Sonnet to quickly gain context for RenderFlex overflow issues
- **[RenderFlex Overflow Fixes](bug_fixes/renderflex_overflow_fixes.md)** - Complete history and solutions for layout overflow issues
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