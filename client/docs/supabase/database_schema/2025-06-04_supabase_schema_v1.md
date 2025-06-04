# Supabase Database Schema - v1 (2025-06-04)

This document outlines the initial proposed database schema for the FlashMaster application's migration to Supabase, based on the 'Flashcard Application Migration Readiness Assessment Report'. This schema will be versioned (via GitHub and filename conventions) and updated as development progresses.

## Proposed SQL DDL

```sql
-- Users table (managed by Supabase Auth)
-- Automatically created by Supabase

-- Categories table
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Flashcard sets table
CREATE TABLE flashcard_sets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  title TEXT NOT NULL,
  description TEXT,
  is_draft BOOLEAN DEFAULT false,
  rating DECIMAL(3,2) DEFAULT 0,
  rating_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Flashcards table
CREATE TABLE flashcards (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  set_id UUID REFERENCES flashcard_sets(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  order_index INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User progress table
CREATE TABLE user_progress (
  user_id UUID REFERENCES auth.users(id),
  flashcard_id UUID REFERENCES flashcards(id) ON DELETE CASCADE,
  is_completed BOOLEAN DEFAULT false,
  is_marked_for_review BOOLEAN DEFAULT false,
  last_reviewed TIMESTAMP WITH TIME ZONE,
  review_count INTEGER DEFAULT 0,
  PRIMARY KEY (user_id, flashcard_id)
);

-- Interview questions table
CREATE TABLE interview_questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  text TEXT NOT NULL,
  category TEXT NOT NULL,
  subtopic TEXT NOT NULL,
  difficulty TEXT NOT NULL,
  answer TEXT,
  category_id TEXT,
  is_draft BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User activity/recent views table
CREATE TABLE user_activity (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  item_type TEXT NOT NULL, -- 'flashcard' or 'interview_question'
  item_id UUID NOT NULL,
  parent_id UUID,
  viewed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  metadata JSONB
);

-- Weekly activity tracking
CREATE TABLE weekly_activity (
  user_id UUID REFERENCES auth.users(id),
  week_start DATE NOT NULL,
  activity_data JSONB NOT NULL,
  PRIMARY KEY (user_id, week_start)
);
```