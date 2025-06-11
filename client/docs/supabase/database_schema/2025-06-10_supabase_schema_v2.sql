# FlashMaster - Complete Supabase Database Schema
# Version: 2.0 - Authentication Ready
# Date: 2025-06-10
# 
# This schema includes all tables, RLS policies, functions, and triggers
# needed for the FlashMaster application with authentication support.

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- CORE TABLES
-- =============================================================================

-- Categories table for organizing flashcards and questions
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  internal_id TEXT NOT NULL, -- For mapping legacy categories
  description TEXT,
  color_hex TEXT DEFAULT '#6366f1', -- Primary color for theming
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  -- Ensure unique category names per user
  UNIQUE(user_id, name),
  -- Ensure unique internal_id per user for backwards compatibility
  UNIQUE(user_id, internal_id)
);

-- Flashcard sets table for organizing flashcards
CREATE TABLE flashcard_sets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  is_draft BOOLEAN DEFAULT false,
  is_public BOOLEAN DEFAULT false, -- For sharing functionality
  rating DECIMAL(3,2) DEFAULT 0.0,
  rating_count INTEGER DEFAULT 0,
  flashcard_count INTEGER DEFAULT 0, -- Denormalized for performance
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Individual flashcards table
CREATE TABLE flashcards (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  set_id UUID REFERENCES flashcard_sets(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  order_index INTEGER NOT NULL,
  hint TEXT, -- Optional hint for the flashcard
  difficulty TEXT DEFAULT 'medium', -- easy, medium, hard
  tags TEXT[], -- Array of tags for better organization
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  -- Ensure unique order within a set
  UNIQUE(set_id, order_index)
);

-- User progress tracking for flashcards
CREATE TABLE user_progress (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  flashcard_id UUID REFERENCES flashcards(id) ON DELETE CASCADE,
  is_completed BOOLEAN DEFAULT false,
  is_marked_for_review BOOLEAN DEFAULT false,
  difficulty_rating INTEGER DEFAULT 3, -- 1-5 scale for spaced repetition
  review_count INTEGER DEFAULT 0,
  last_reviewed_at TIMESTAMP WITH TIME ZONE,
  next_review_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  PRIMARY KEY (user_id, flashcard_id)
);

-- Interview questions table
CREATE TABLE interview_questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  question_text TEXT NOT NULL,
  category TEXT NOT NULL, -- Legacy compatibility field
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  subtopic TEXT,
  difficulty TEXT DEFAULT 'medium', -- easy, medium, hard, expert
  suggested_answer TEXT, -- AI-generated or user-provided answer
  tags TEXT[], -- Array of tags
  is_draft BOOLEAN DEFAULT false,
  is_favorite BOOLEAN DEFAULT false,
  practice_count INTEGER DEFAULT 0,
  last_practiced_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User activity tracking (recent views)
CREATE TABLE user_activity (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  activity_type TEXT NOT NULL, -- 'flashcard_view', 'interview_practice', 'set_study', etc.
  item_type TEXT NOT NULL, -- 'flashcard', 'flashcard_set', 'interview_question'
  item_id UUID NOT NULL,
  parent_id UUID, -- For flashcards, this would be the set_id
  metadata JSONB DEFAULT '{}', -- Flexible data storage
  viewed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  -- Index for efficient recent activity queries
  INDEX idx_user_activity_recent (user_id, viewed_at DESC)
);

-- Weekly activity tracking for analytics
CREATE TABLE weekly_activity (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  week_start DATE NOT NULL, -- Monday of the week
  flashcards_studied INTEGER DEFAULT 0,
  interview_questions_practiced INTEGER DEFAULT 0,
  total_study_time_minutes INTEGER DEFAULT 0,
  grading_actions_used INTEGER DEFAULT 0, -- Track usage for limits
  activity_data JSONB DEFAULT '{}', -- Detailed breakdown
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  PRIMARY KEY (user_id, week_start)
);

-- User preferences and settings
CREATE TABLE user_preferences (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  theme_mode TEXT DEFAULT 'system', -- light, dark, system
  language_code TEXT DEFAULT 'en',
  daily_goal INTEGER DEFAULT 10, -- Daily flashcard goal
  reminder_enabled BOOLEAN DEFAULT true,
  reminder_time TIME DEFAULT '09:00',
  spaced_repetition_enabled BOOLEAN DEFAULT true,
  sound_effects_enabled BOOLEAN DEFAULT true,
  haptic_feedback_enabled BOOLEAN DEFAULT true,
  preferences_data JSONB DEFAULT '{}', -- Additional flexible preferences
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Guest session tracking (for usage limits)
CREATE TABLE guest_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_token TEXT NOT NULL UNIQUE, -- Client-generated session identifier
  grading_actions_used INTEGER DEFAULT 0,
  last_action_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP + INTERVAL '24 hours'),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- FUNCTIONS AND TRIGGERS
-- =============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to all relevant tables
CREATE TRIGGER categories_updated_at BEFORE UPDATE ON categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER flashcard_sets_updated_at BEFORE UPDATE ON flashcard_sets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER flashcards_updated_at BEFORE UPDATE ON flashcards
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER user_progress_updated_at BEFORE UPDATE ON user_progress
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER interview_questions_updated_at BEFORE UPDATE ON interview_questions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER weekly_activity_updated_at BEFORE UPDATE ON weekly_activity
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER user_preferences_updated_at BEFORE UPDATE ON user_preferences
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Function to update flashcard count in sets
CREATE OR REPLACE FUNCTION update_flashcard_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE flashcard_sets 
    SET flashcard_count = flashcard_count + 1 
    WHERE id = NEW.set_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE flashcard_sets 
    SET flashcard_count = flashcard_count - 1 
    WHERE id = OLD.set_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Apply flashcard count trigger
CREATE TRIGGER flashcard_count_trigger 
  AFTER INSERT OR DELETE ON flashcards
  FOR EACH ROW EXECUTE FUNCTION update_flashcard_count();

-- Function to create default categories for new users
CREATE OR REPLACE FUNCTION create_default_categories()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO categories (user_id, name, internal_id, is_default) VALUES
    (NEW.id, 'Data Analysis', 'data_analysis', true),
    (NEW.id, 'Machine Learning', 'machine_learning', true),
    (NEW.id, 'SQL', 'sql', true),
    (NEW.id, 'Python', 'python', true),
    (NEW.id, 'Web Development', 'web_development', true),
    (NEW.id, 'Statistics', 'statistics', true),
    (NEW.id, 'General', 'general', true);
    
  -- Create default user preferences
  INSERT INTO user_preferences (user_id) VALUES (NEW.id);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to create default categories for new users
CREATE TRIGGER create_user_defaults 
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION create_default_categories();

-- =============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================

-- Enable RLS on all tables
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE flashcard_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE flashcards ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE interview_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_activity ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_activity ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE guest_sessions ENABLE ROW LEVEL SECURITY;

-- Categories policies
CREATE POLICY "Users can manage their own categories" ON categories
  FOR ALL USING (auth.uid() = user_id);

-- Flashcard sets policies
CREATE POLICY "Users can manage their own flashcard sets" ON flashcard_sets
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view public flashcard sets" ON flashcard_sets
  FOR SELECT USING (is_public = true);

-- Flashcards policies
CREATE POLICY "Users can manage flashcards in their sets" ON flashcards
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM flashcard_sets 
      WHERE flashcard_sets.id = flashcards.set_id 
      AND flashcard_sets.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can view flashcards in public sets" ON flashcards
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM flashcard_sets 
      WHERE flashcard_sets.id = flashcards.set_id 
      AND flashcard_sets.is_public = true
    )
  );

-- User progress policies
CREATE POLICY "Users can manage their own progress" ON user_progress
  FOR ALL USING (auth.uid() = user_id);

-- Interview questions policies
CREATE POLICY "Users can manage their own interview questions" ON interview_questions
  FOR ALL USING (auth.uid() = user_id);

-- User activity policies
CREATE POLICY "Users can manage their own activity" ON user_activity
  FOR ALL USING (auth.uid() = user_id);

-- Weekly activity policies
CREATE POLICY "Users can manage their own weekly activity" ON weekly_activity
  FOR ALL USING (auth.uid() = user_id);

-- User preferences policies
CREATE POLICY "Users can manage their own preferences" ON user_preferences
  FOR ALL USING (auth.uid() = user_id);

-- Guest sessions policies (no RLS needed as these are session-based)
CREATE POLICY "Anyone can manage guest sessions" ON guest_sessions
  FOR ALL USING (true);

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- Categories indexes
CREATE INDEX idx_categories_user_id ON categories(user_id);
CREATE INDEX idx_categories_internal_id ON categories(user_id, internal_id);

-- Flashcard sets indexes
CREATE INDEX idx_flashcard_sets_user_id ON flashcard_sets(user_id);
CREATE INDEX idx_flashcard_sets_category_id ON flashcard_sets(category_id);
CREATE INDEX idx_flashcard_sets_public ON flashcard_sets(is_public) WHERE is_public = true;

-- Flashcards indexes
CREATE INDEX idx_flashcards_set_id ON flashcards(set_id);
CREATE INDEX idx_flashcards_order ON flashcards(set_id, order_index);

-- User progress indexes
CREATE INDEX idx_user_progress_user_id ON user_progress(user_id);
CREATE INDEX idx_user_progress_next_review ON user_progress(user_id, next_review_at) 
  WHERE next_review_at IS NOT NULL;

-- Interview questions indexes
CREATE INDEX idx_interview_questions_user_id ON interview_questions(user_id);
CREATE INDEX idx_interview_questions_category_id ON interview_questions(category_id);
CREATE INDEX idx_interview_questions_category ON interview_questions(user_id, category);

-- User activity indexes
CREATE INDEX idx_user_activity_user_recent ON user_activity(user_id, viewed_at DESC);
CREATE INDEX idx_user_activity_item ON user_activity(user_id, item_type, item_id);

-- Weekly activity indexes
CREATE INDEX idx_weekly_activity_user_week ON weekly_activity(user_id, week_start DESC);

-- Guest sessions indexes
CREATE INDEX idx_guest_sessions_token ON guest_sessions(session_token);
CREATE INDEX idx_guest_sessions_expires ON guest_sessions(expires_at);

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

-- Function to clean up expired guest sessions
CREATE OR REPLACE FUNCTION cleanup_expired_guest_sessions()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM guest_sessions WHERE expires_at < CURRENT_TIMESTAMP;
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Function to get user statistics
CREATE OR REPLACE FUNCTION get_user_stats(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
  stats JSON;
BEGIN
  SELECT json_build_object(
    'total_flashcard_sets', (
      SELECT COUNT(*) FROM flashcard_sets WHERE user_id = p_user_id
    ),
    'total_flashcards', (
      SELECT COUNT(*) FROM flashcards f
      JOIN flashcard_sets fs ON f.set_id = fs.id
      WHERE fs.user_id = p_user_id
    ),
    'total_interview_questions', (
      SELECT COUNT(*) FROM interview_questions WHERE user_id = p_user_id
    ),
    'completed_flashcards', (
      SELECT COUNT(*) FROM user_progress WHERE user_id = p_user_id AND is_completed = true
    ),
    'this_week_activity', (
      SELECT COALESCE(
        (flashcards_studied + interview_questions_practiced), 0
      ) FROM weekly_activity 
      WHERE user_id = p_user_id 
      AND week_start = date_trunc('week', CURRENT_DATE)::date
    )
  ) INTO stats;
  
  RETURN stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- SAMPLE DATA SEEDING FUNCTIONS
-- =============================================================================

-- Function to seed sample flashcard data for a user
CREATE OR REPLACE FUNCTION seed_sample_data(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
  data_analysis_category_id UUID;
  python_category_id UUID;
  sample_set_id UUID;
BEGIN
  -- Get category IDs
  SELECT id INTO data_analysis_category_id FROM categories 
  WHERE user_id = p_user_id AND internal_id = 'data_analysis';
  
  SELECT id INTO python_category_id FROM categories 
  WHERE user_id = p_user_id AND internal_id = 'python';
  
  -- Create sample flashcard set
  INSERT INTO flashcard_sets (user_id, title, description, category_id)
  VALUES (
    p_user_id,
    'Data Analysis Fundamentals',
    'Essential concepts for data analysis interviews',
    data_analysis_category_id
  ) RETURNING id INTO sample_set_id;
  
  -- Add sample flashcards
  INSERT INTO flashcards (set_id, question, answer, order_index, difficulty) VALUES
    (sample_set_id, 'What is the difference between population and sample?', 'Population is the entire group being studied, while sample is a subset of the population used to make inferences about the population.', 1, 'easy'),
    (sample_set_id, 'What is the Central Limit Theorem?', 'The Central Limit Theorem states that the sampling distribution of the sample mean approaches a normal distribution as the sample size increases, regardless of the population distribution.', 2, 'medium'),
    (sample_set_id, 'What is p-value?', 'P-value is the probability of obtaining test results at least as extreme as the observed results, assuming the null hypothesis is true.', 3, 'medium');
    
  -- Add sample interview questions
  INSERT INTO interview_questions (user_id, question_text, category, category_id, difficulty) VALUES
    (p_user_id, 'Explain the difference between supervised and unsupervised learning.', 'machine_learning', (SELECT id FROM categories WHERE user_id = p_user_id AND internal_id = 'machine_learning'), 'medium'),
    (p_user_id, 'How would you handle missing data in a dataset?', 'data_analysis', data_analysis_category_id, 'medium'),
    (p_user_id, 'What is the difference between list and tuple in Python?', 'python', python_category_id, 'easy');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- MIGRATION HELPERS
-- =============================================================================

-- Function to migrate data from old category system to new
CREATE OR REPLACE FUNCTION migrate_legacy_categories(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
  -- Update interview questions to use category_id instead of just category string
  UPDATE interview_questions iq
  SET category_id = c.id
  FROM categories c
  WHERE iq.user_id = p_user_id
  AND c.user_id = p_user_id
  AND (
    c.internal_id = iq.category 
    OR LOWER(c.name) = LOWER(iq.category)
  )
  AND iq.category_id IS NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- SETUP COMPLETION
-- =============================================================================

-- Create a view for easy user stats access
CREATE VIEW user_dashboard_stats AS
SELECT 
  u.id as user_id,
  u.email,
  COUNT(DISTINCT fs.id) as flashcard_sets_count,
  COUNT(DISTINCT f.id) as flashcards_count,
  COUNT(DISTINCT iq.id) as interview_questions_count,
  COUNT(DISTINCT CASE WHEN up.is_completed THEN up.flashcard_id END) as completed_flashcards,
  COALESCE(wa.flashcards_studied, 0) as this_week_flashcards,
  COALESCE(wa.interview_questions_practiced, 0) as this_week_interviews
FROM auth.users u
LEFT JOIN flashcard_sets fs ON u.id = fs.user_id
LEFT JOIN flashcards f ON fs.id = f.set_id
LEFT JOIN interview_questions iq ON u.id = iq.user_id
LEFT JOIN user_progress up ON u.id = up.user_id
LEFT JOIN weekly_activity wa ON u.id = wa.user_id AND wa.week_start = date_trunc('week', CURRENT_DATE)::date
GROUP BY u.id, u.email, wa.flashcards_studied, wa.interview_questions_practiced;

-- Grant necessary permissions for the view
GRANT SELECT ON user_dashboard_stats TO authenticated;

-- Create policy for the view
CREATE POLICY "Users can view their own dashboard stats" ON user_dashboard_stats
  FOR SELECT USING (auth.uid() = user_id);

-- Schema deployment complete!
-- 
-- To complete setup:
-- 1. Run this schema in your Supabase SQL editor
-- 2. Configure authentication providers in Supabase Auth settings
-- 3. Set up any required webhooks or edge functions
-- 4. Test the RLS policies with sample data
--
-- Usage limits are now handled through:
-- - weekly_activity table for authenticated users
-- - guest_sessions table for anonymous users
