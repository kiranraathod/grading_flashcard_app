# FlashMaster Documentation

Welcome to the comprehensive documentation for the FlashMaster application. This documentation provides detailed information about the architecture, features, and implementation details of the FlashMaster app.

## Documentation Structure

### Architecture Documentation
- [Dark Mode Implementation](architecture/dark_mode.md) - Detailed guide on the implementation of dark mode in the application
- [Refactoring Documentation](architecture/REFACTORING.md) - Overview of major refactoring efforts to modernize the codebase
- [Tab Implementation](architecture/tab_implementation.md) - Implementation details of the "Recent" tab functionality

### Server Documentation
- [Migration Guide](server/MIGRATION_GUIDE.md) - Guide for the migration from Flask to FastAPI
- [Server README](server/readme.md) - Overview of the server implementation and API endpoints

### Features Documentation
- Check the [features directory](features/) for documentation on specific features

### UI Improvements
- Check the [ui_improvements directory](ui_improvements/) for documentation on UI enhancements

### Bug Fixes
- Check the [bug_fixes directory](bug_fixes/) for documentation on resolved issues

## Key Technologies

The FlashMaster application uses the following key technologies:

1. **Flutter** - Cross-platform UI framework for building the mobile application
2. **BLoC Pattern** - State management approach for clean separation of UI and business logic
3. **FastAPI** - Backend API framework for grading and suggestions
4. **LLM Integration** - Large Language Model integration for intelligent grading

## Getting Started

For new developers, we recommend:

1. Start with the [Refactoring Documentation](architecture/REFACTORING.md) to understand the overall architecture
2. Review the feature-specific documentation to understand implemented functionality
3. Check the server documentation to understand the backend API

## Contribution Guidelines

When contributing to the documentation:

1. Place feature-specific documentation in the appropriate subdirectory
2. Use Markdown format for all documentation files
3. Include code examples where appropriate
4. Update this index when adding new documentation