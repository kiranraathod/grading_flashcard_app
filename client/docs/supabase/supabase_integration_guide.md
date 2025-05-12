# Supabase Integration Guide for FlashMaster App

This guide outlines the steps required to integrate Supabase with the FlashMaster app, transforming it from a local storage-based application to a cloud-based solution with enhanced functionality.

## Table of Contents

1. [Introduction to Supabase](#introduction-to-supabase)
2. [Setup and Configuration](#setup-and-configuration)
3. [Authentication Implementation](#authentication-implementation)
4. [Database Migration and Schema Design](#database-migration-and-schema-design)
5. [Storage Integration](#storage-integration)
6. [Realtime Functionality](#realtime-functionality)
7. [Security Implementation](#security-implementation)
8. [Testing and Deployment](#testing-and-deployment)
9. [Appendix: Schema Reference](#appendix-schema-reference)

## Introduction to Supabase

Supabase is an open-source Firebase alternative that provides a suite of tools to develop applications, including:

- Authentication services
- PostgreSQL database
- Storage for files
- Realtime functionality
- Edge Functions for server-side operations

By integrating Supabase with our Flutter app, we can:

- Move from local storage to cloud storage for user data
- Implement user authentication and profile management
- Enable cross-device synchronization of flashcards
- Add collaborative features
- Improve app security with Row Level Security
- Support progress tracking and goals

## Setup and Configuration

### Task 1: Create a Supabase Project

**Subtasks:**
- [ ] Sign up for a Supabase account
- [ ] Create a new project in Supabase dashboard
- [ ] Note the API URL and API key for your project
- [ ] Configure CORS settings for your application domains

### Task 2: Install and Configure Supabase in the Flutter App

**Subtasks:**
- [ ] Add the Supabase Flutter dependency to `pubspec.yaml`:
  ```yaml
  dependencies:
    supabase_flutter: ^1.10.25
  ```
- [ ] Run `flutter pub get` to install the dependency
- [ ] Create a Supabase configuration file in the project:
  - Create `lib/utils/supabase_config.dart` to store configuration values
  - Add appropriate environment variables handling for different environments

### Task 3: Initialize Supabase in the App

**Subtasks:**
- [ ] Update the `main.dart` file to initialize Supabase before the app starts
- [ ] Create a global Supabase client instance for use throughout the app
- [ ] Implement error handling for initialization failures
- [ ] Set up logging for Supabase interactions (development mode only)

## Authentication Implementation

### Task 4: Set Up Authentication in Supabase Dashboard

**Subtasks:**
- [ ] Configure authentication providers (email/password, social logins, etc.)
- [ ] Set up email templates for authentication events
- [ ] Configure redirect URLs for deep linking
- [ ] Test authentication flow in the Supabase dashboard

### Task 5: Create Authentication UI

**Subtasks:**
- [ ] Create a login screen
- [ ] Create a registration screen
- [ ] Implement password reset functionality
- [ ] Create profile management screen
- [ ] Design and implement error messages for authentication issues
- [ ] Add user profile settings for goal tracking

### Task 6: Implement Authentication Logic

**Subtasks:**
- [ ] Implement email/password authentication
- [ ] Add social login functionality if required
- [ ] Implement JWT token management (storage and refreshing)
- [ ] Create session management service to handle auth state
- [ ] Implement deep linking for authentication flows
- [ ] Modify app routing to respect authentication state

### Task 7: Platform-Specific Authentication Setup

**Subtasks:**
- [ ] Configure Android manifests for authentication providers
- [ ] Configure iOS Info.plist for authentication providers
- [ ] Set up deep linking on all platforms (Android, iOS, web)
- [ ] Test authentication flow on all supported platforms

## Database Migration and Schema Design

### Task 8: Design Database Schema

**Subtasks:**
- [ ] Create `users` table with profile information, preferences, and goal settings
- [ ] Create `categories` table for top-level organization (Decks, Interview Questions, etc.)
- [ ] Create `collections` table for question sets and flashcard decks with:
  - Type classification (company-specific, topic-based, etc.)
  - Metadata (question counts, completion status, etc.)
- [ ] Create `questions` table for individual flashcards and interview questions
- [ ] Create `user_progress` table to track completion status and practice history
- [ ] Create `weekly_activity` table to support goal tracking (5/7 days feature)
- [ ] Create appropriate indexes for search, filtering, and sorting
- [ ] Document the schema design with diagrams reflecting the app's UI organization

### Task 9: Implement Row Level Security (RLS)

**Subtasks:**
- [ ] Create RLS policies for the `categories` table (owner access)
- [ ] Create RLS policies for the `collections` table (owner access)
- [ ] Create RLS policies for the `questions` table (owner access)
- [ ] Create RLS policies for the `user_progress` table (owner access)
- [ ] Create RLS policies for the `weekly_activity` table (owner access)
- [ ] Add policies for shared content (if implementing collaborative features)
- [ ] Test RLS policies using the Supabase SQL editor
- [ ] Document RLS policies for future reference

### Task 10: Implement Job Description Questions Generator

**Subtasks:**
- [ ] Create database tables for storing job descriptions
- [ ] Design schema for AI-generated questions from job descriptions
- [ ] Implement database functions for question generation process
- [ ] Create tracking for question generation history
- [ ] Add metadata for generated question attribution

### Task 11: Migrate Local Data Model to Supabase

**Subtasks:**
- [ ] Update data models to match the hierarchical structure shown in the UI
- [ ] Create model classes for all database tables (categories, collections, questions, etc.)
- [ ] Implement data validation for Supabase integration
- [ ] Add functions to convert between local and cloud models
- [ ] Create mapping for progress tracking and practice history

### Task 12: Implement Data Migration Service

**Subtasks:**
- [ ] Create a service to migrate existing local data to Supabase
- [ ] Implement conflict resolution for data migration
- [ ] Add progress indicators for the migration process
- [ ] Implement fallback mechanisms for migration failures
- [ ] Test migration with various data sets
- [ ] Create backup of local data before migration

## Storage Integration

### Task 13: Configure Supabase Storage

**Subtasks:**
- [ ] Create appropriate storage buckets for app assets
- [ ] Configure access policies for each bucket
- [ ] Set up public/private access rules
- [ ] Configure file size limits
- [ ] Document storage structure

### Task 14: Implement File Upload Functionality

**Subtasks:**
- [ ] Create service for file uploads to Supabase Storage
- [ ] Implement image compression before upload
- [ ] Add progress indicators for file uploads
- [ ] Implement retry mechanisms for failed uploads
- [ ] Create file metadata management

### Task 15: Integrate Storage with App Features

**Subtasks:**
- [ ] Update user profile to support avatar images
- [ ] Add image support for flashcards and questions
- [ ] Support attachments for interview questions and answers
- [ ] Implement caching for downloaded images
- [ ] Create clean-up routines for temporary files
- [ ] Ensure proper error handling for file operations

## Realtime Functionality

### Task 16: Enable Realtime Features in Supabase

**Subtasks:**
- [ ] Configure realtime functionality in Supabase dashboard
- [ ] Identify which tables need realtime updates (user_progress, collections, etc.)
- [ ] Set up channels for different data types
- [ ] Document expected realtime behavior

### Task 17: Implement Realtime Listeners

**Subtasks:**
- [ ] Create a service to manage Supabase realtime subscriptions
- [ ] Implement listeners for collection changes (for filtered views)
- [ ] Implement listeners for question/flashcard changes
- [ ] Implement listeners for user progress updates (for goal tracking)
- [ ] Create UI updates based on realtime events
- [ ] Add "Recent" view based on realtime activity

### Task 18: Add Collaborative Features

**Subtasks:**
- [ ] Design and implement shared question collections
- [ ] Create invitation system for collaboration
- [ ] Implement permission management for shared resources
- [ ] Add UI for collaborative features
- [ ] Test collaborative scenarios with multiple users

## Security Implementation

### Task 19: Secure Data Access

**Subtasks:**
- [ ] Review and enhance RLS policies
- [ ] Implement JWT validation for API requests
- [ ] Create security audit logging
- [ ] Test security measures with penetration testing
- [ ] Document security measures
- [ ] Add data sanitization for user inputs

### Task 20: Implement Offline Support with Sync

**Subtasks:**
- [ ] Create local cache of user data for offline use
- [ ] Implement sync mechanism for offline changes
- [ ] Add conflict resolution for concurrent changes
- [ ] Create UI indicators for sync status
- [ ] Test sync with various network conditions
- [ ] Ensure goal tracking works offline

## Testing and Deployment

### Task 21: Testing

**Subtasks:**
- [ ] Create unit tests for Supabase integration
- [ ] Implement integration tests for authentication
- [ ] Test data synchronization scenarios
- [ ] Test goal tracking and progress updates
- [ ] Create test suites for topic browsing and filtering
- [ ] Perform performance testing
- [ ] Test on all supported platforms and devices

### Task 22: Deployment and Monitoring

**Subtasks:**
- [ ] Set up monitoring for Supabase usage
- [ ] Create alerts for critical errors
- [ ] Implement analytics for feature usage
- [ ] Add tracking for question generation feature usage
- [ ] Document deployment process
- [ ] Create rollback procedures for emergencies

## Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Flutter SDK](https://pub.dev/packages/supabase_flutter)
- [Flutter Authentication Guide](https://supabase.com/docs/guides/getting-started/tutorials/with-flutter)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Supabase Storage Documentation](https://supabase.com/docs/guides/storage)
- [Supabase Realtime Documentation](https://supabase.com/docs/guides/realtime)

## Implementation Timeline

| Phase | Tasks | Estimated Duration |
|-------|-------|-------------------|
| Setup & Auth | Tasks 1-7 | 1-2 weeks |
| Database | Tasks 8-12 | 2-3 weeks |
| Storage | Tasks 13-15 | 1-2 weeks |
| Realtime | Tasks 16-18 | 1-2 weeks |
| Security & Testing | Tasks 19-22 | 2-3 weeks |

Total estimated time: 7-12 weeks depending on team size and experience with Supabase.

## Appendix: Schema Reference

### Proposed Database Schema

```sql
-- Users table
CREATE TABLE users (
  id UUID REFERENCES auth.users NOT NULL PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  theme_preference TEXT DEFAULT 'system',
  daily_goal_count INTEGER DEFAULT 10,
  weekly_goal_days INTEGER DEFAULT 5,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Categories table (Decks, Interview Questions, etc.)
CREATE TABLE categories (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES users NOT NULL,
  name TEXT NOT NULL,
  display_order INTEGER DEFAULT 0,
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Collections table (sets of questions/flashcards)
CREATE TABLE collections (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES users NOT NULL,
  category_id UUID REFERENCES categories NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  topic TEXT,
  company_name TEXT,
  is_draft BOOLEAN DEFAULT FALSE,
  question_count INTEGER DEFAULT 0,
  rating DECIMAL(3,1) DEFAULT 0.0,
  rating_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Questions table (individual flashcards or interview questions)
CREATE TABLE questions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES users NOT NULL,
  collection_id UUID REFERENCES collections NOT NULL,
  question_text TEXT NOT NULL,
  answer_text TEXT NOT NULL,
  is_generated BOOLEAN DEFAULT FALSE,
  source TEXT,
  tags TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User progress for each question
CREATE TABLE user_progress (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES users NOT NULL,
  question_id UUID REFERENCES questions NOT NULL,
  is_completed BOOLEAN DEFAULT FALSE,
  is_marked_for_review BOOLEAN DEFAULT FALSE,
  last_practiced TIMESTAMP WITH TIME ZONE,
  next_review_date TIMESTAMP WITH TIME ZONE,
  grade TEXT,
  review_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, question_id)
);

-- Weekly activity tracking for goals
CREATE TABLE weekly_activity (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES users NOT NULL,
  activity_date DATE NOT NULL,
  questions_practiced INTEGER DEFAULT 0,
  questions_completed INTEGER DEFAULT 0,
  time_spent_seconds INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, activity_date)
);

-- Job descriptions for question generation
CREATE TABLE job_descriptions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES users NOT NULL,
  title TEXT NOT NULL,
  company TEXT,
  description TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Example RLS Policies

```sql
-- RLS policy for collections
ALTER TABLE collections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own collections"
  ON collections FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own collections"
  ON collections FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own collections"
  ON collections FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own collections"
  ON collections FOR DELETE
  USING (auth.uid() = user_id);

-- Similar policies would be created for questions, user_progress, etc.
```

This database schema supports all the features visible in the UI screenshots, including:
- Hierarchical organization of content (categories → collections → questions)
- Different types of collections (topic-based, company-specific)
- Progress tracking and goal monitoring
- Rating and metadata for collections
- Support for the "Create Questions from Job Description" feature
