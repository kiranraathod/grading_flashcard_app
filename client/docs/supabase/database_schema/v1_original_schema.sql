# FlashMaster Supabase Schema v1 - Original Implementation
# Simple, functional schema for basic FlashMaster functionality
# Date: 2025-06-10 (Implementing original 2025-06-04 design)

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- CORE TABLES (Original v1 Design)
-- =============================================================================

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

-- =============================================================================
-- BASIC FUNCTIONS (Manual Setup Required)
-- =============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER categories_updated_at BEFORE UPDATE ON categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER flashcard_sets_updated_at BEFORE UPDATE ON flashcard_sets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- =============================================================================
-- BASIC SECURITY (Manual RLS Setup)
-- =============================================================================

-- Enable RLS on tables (you'll need to create policies manually)
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE flashcard_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE flashcards ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE interview_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_activity ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_activity ENABLE ROW LEVEL SECURITY;

-- Basic user isolation policies
CREATE POLICY "Users can manage own categories" ON categories
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own flashcard sets" ON flashcard_sets
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage flashcards in their sets" ON flashcards
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM flashcard_sets 
      WHERE flashcard_sets.id = flashcards.set_id 
      AND flashcard_sets.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can manage own progress" ON user_progress
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own interview questions" ON interview_questions
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own activity" ON user_activity
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own weekly activity" ON weekly_activity
  FOR ALL USING (auth.uid() = user_id);

-- =============================================================================
-- SAMPLE DATA (Optional)
-- =============================================================================

-- Insert sample categories (you'll need to do this for each user manually)
-- INSERT INTO categories (user_id, name, description) VALUES
--   ('user-uuid-here', 'Data Analysis', 'Questions about data analysis techniques'),
--   ('user-uuid-here', 'Machine Learning', 'ML algorithms and concepts'),
--   ('user-uuid-here', 'SQL', 'Database queries and design');

-- Schema v1 deployment complete!
-- 
-- Manual setup still required:
-- 1. Create categories for each new user
-- 2. Set up additional RLS policies as needed
-- 3. Add indexes for performance (optional)
-- 4. Implement guest user tracking (if needed)
