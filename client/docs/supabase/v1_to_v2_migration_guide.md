# Migration Guide: v1 to v2 Schema Upgrade

## Overview
If you started with v1 and want to upgrade to v2, this guide provides step-by-step migration instructions.

## Pre-Migration Checklist
- [ ] **Backup your data**: Export all data from v1 tables
- [ ] **Test migration on staging**: Never run directly on production
- [ ] **Update application code**: Ensure v2 services are implemented
- [ ] **Schedule downtime**: Brief maintenance window recommended

## Migration Steps

### Step 1: Backup Existing Data
```sql
-- Export existing data (run in Supabase SQL Editor)
COPY categories TO '/tmp/categories_backup.csv' DELIMITER ',' CSV HEADER;
COPY flashcard_sets TO '/tmp/flashcard_sets_backup.csv' DELIMITER ',' CSV HEADER;
COPY flashcards TO '/tmp/flashcards_backup.csv' DELIMITER ',' CSV HEADER;
COPY user_progress TO '/tmp/user_progress_backup.csv' DELIMITER ',' CSV HEADER;
COPY interview_questions TO '/tmp/interview_questions_backup.csv' DELIMITER ',' CSV HEADER;
COPY user_activity TO '/tmp/user_activity_backup.csv' DELIMITER ',' CSV HEADER;
COPY weekly_activity TO '/tmp/weekly_activity_backup.csv' DELIMITER ',' CSV HEADER;
```

### Step 2: Add New Columns to Existing Tables
```sql
-- Enhance categories table
ALTER TABLE categories ADD COLUMN IF NOT EXISTS internal_id TEXT;
ALTER TABLE categories ADD COLUMN IF NOT EXISTS color_hex TEXT DEFAULT '#6366f1';
ALTER TABLE categories ADD COLUMN IF NOT EXISTS is_default BOOLEAN DEFAULT false;

-- Add unique constraint for backwards compatibility
ALTER TABLE categories ADD CONSTRAINT unique_user_internal_id 
  UNIQUE(user_id, internal_id);

-- Enhance flashcard_sets table
ALTER TABLE flashcard_sets ADD COLUMN IF NOT EXISTS category_id UUID 
  REFERENCES categories(id) ON DELETE SET NULL;
ALTER TABLE flashcard_sets ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT false;
ALTER TABLE flashcard_sets ADD COLUMN IF NOT EXISTS flashcard_count INTEGER DEFAULT 0;

-- Enhance flashcards table
ALTER TABLE flashcards ADD COLUMN IF NOT EXISTS hint TEXT;
ALTER TABLE flashcards ADD COLUMN IF NOT EXISTS difficulty TEXT DEFAULT 'medium';
ALTER TABLE flashcards ADD COLUMN IF NOT EXISTS tags TEXT[];
ALTER TABLE flashcards ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

-- Enhance user_progress table
ALTER TABLE user_progress ADD COLUMN IF NOT EXISTS difficulty_rating INTEGER DEFAULT 3;
ALTER TABLE user_progress ADD COLUMN IF NOT EXISTS next_review_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE user_progress ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE user_progress ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

-- Enhance interview_questions table
ALTER TABLE interview_questions ADD COLUMN IF NOT EXISTS question_text TEXT;
ALTER TABLE interview_questions ADD COLUMN IF NOT EXISTS category_id UUID 
  REFERENCES categories(id) ON DELETE SET NULL;
ALTER TABLE interview_questions ADD COLUMN IF NOT EXISTS suggested_answer TEXT;
ALTER TABLE interview_questions ADD COLUMN IF NOT EXISTS tags TEXT[];
ALTER TABLE interview_questions ADD COLUMN IF NOT EXISTS is_favorite BOOLEAN DEFAULT false;
ALTER TABLE interview_questions ADD COLUMN IF NOT EXISTS practice_count INTEGER DEFAULT 0;
ALTER TABLE interview_questions ADD COLUMN IF NOT EXISTS last_practiced_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE interview_questions ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

-- Update interview_questions to use question_text
UPDATE interview_questions SET question_text = text WHERE question_text IS NULL;

-- Enhance user_activity table
ALTER TABLE user_activity ADD COLUMN IF NOT EXISTS activity_type TEXT DEFAULT 'view';
```

### Step 3: Create New Tables
```sql
-- Create user_preferences table
CREATE TABLE IF NOT EXISTS user_preferences (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  theme_mode TEXT DEFAULT 'system',
  language_code TEXT DEFAULT 'en',
  daily_goal INTEGER DEFAULT 10,
  reminder_enabled BOOLEAN DEFAULT true,
  reminder_time TIME DEFAULT '09:00',
  spaced_repetition_enabled BOOLEAN DEFAULT true,
  sound_effects_enabled BOOLEAN DEFAULT true,
  haptic_feedback_enabled BOOLEAN DEFAULT true,
  preferences_data JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create guest_sessions table
CREATE TABLE IF NOT EXISTS guest_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_token TEXT NOT NULL UNIQUE,
  grading_actions_used INTEGER DEFAULT 0,
  last_action_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP + INTERVAL '24 hours'),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

### Step 4: Add Enhanced Functions and Triggers
```sql
-- Add enhanced update trigger function (if not exists)
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add triggers for new columns
CREATE TRIGGER user_preferences_updated_at BEFORE UPDATE ON user_preferences
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER interview_questions_updated_at BEFORE UPDATE ON interview_questions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER user_progress_updated_at BEFORE UPDATE ON user_progress
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Add flashcard count maintenance
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

CREATE TRIGGER flashcard_count_trigger 
  AFTER INSERT OR DELETE ON flashcards
  FOR EACH ROW EXECUTE FUNCTION update_flashcard_count();

-- Add default data creation function
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
    
  INSERT INTO user_preferences (user_id) VALUES (NEW.id);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_user_defaults 
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION create_default_categories();
```

### Step 5: Migrate Existing Data
```sql
-- Set internal_id for existing categories
UPDATE categories SET internal_id = LOWER(REPLACE(name, ' ', '_'))
WHERE internal_id IS NULL;

-- Set is_default for existing categories
UPDATE categories SET is_default = true;

-- Update flashcard counts for existing sets
UPDATE flashcard_sets 
SET flashcard_count = (
  SELECT COUNT(*) FROM flashcards 
  WHERE flashcards.set_id = flashcard_sets.id
);

-- Create preferences for existing users
INSERT INTO user_preferences (user_id)
SELECT id FROM auth.users 
WHERE id NOT IN (SELECT user_id FROM user_preferences);

-- Migrate interview questions to use category_id
UPDATE interview_questions iq
SET category_id = c.id
FROM categories c
WHERE iq.user_id = c.user_id
AND (
  c.internal_id = iq.category 
  OR LOWER(c.name) = LOWER(iq.category)
)
AND iq.category_id IS NULL;
```

### Step 6: Add Enhanced Security Policies
```sql
-- Add new RLS policies for new tables
CREATE POLICY "Users can manage their own preferences" ON user_preferences
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Anyone can manage guest sessions" ON guest_sessions
  FOR ALL USING (true);

-- Add enhanced policies for existing tables
CREATE POLICY "Users can view public flashcard sets" ON flashcard_sets
  FOR SELECT USING (is_public = true);

CREATE POLICY "Users can view flashcards in public sets" ON flashcards
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM flashcard_sets 
      WHERE flashcard_sets.id = flashcards.set_id 
      AND flashcard_sets.is_public = true
    )
  );
```

### Step 7: Add Performance Indexes
```sql
-- Add v2 performance indexes
CREATE INDEX IF NOT EXISTS idx_categories_internal_id ON categories(user_id, internal_id);
CREATE INDEX IF NOT EXISTS idx_flashcard_sets_category_id ON flashcard_sets(category_id);
CREATE INDEX IF NOT EXISTS idx_flashcard_sets_public ON flashcard_sets(is_public) WHERE is_public = true;
CREATE INDEX IF NOT EXISTS idx_flashcards_order ON flashcards(set_id, order_index);
CREATE INDEX IF NOT EXISTS idx_user_progress_next_review ON user_progress(user_id, next_review_at) 
  WHERE next_review_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_interview_questions_category_id ON interview_questions(category_id);
CREATE INDEX IF NOT EXISTS idx_user_activity_user_recent ON user_activity(user_id, viewed_at DESC);
CREATE INDEX IF NOT EXISTS idx_guest_sessions_token ON guest_sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_guest_sessions_expires ON guest_sessions(expires_at);
```

### Step 8: Add Utility Functions
```sql
-- Add utility functions from v2
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
    )
  ) INTO stats;
  
  RETURN stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Step 9: Update Application Code
After database migration, update your Flutter app:

1. **Replace v1 services** with v2 services:
   - Remove `basic_auth_service_v1.dart`
   - Use existing v2 services: `SupabaseService`, `AuthenticationService`, `GuestUserManager`

2. **Update configuration**:
   ```dart
   // Enable v2 features
   static bool enableAuthentication = true;
   static bool enableUsageLimits = true;
   static bool enableGuestTracking = true;
   ```

3. **Replace UI components**:
   - Remove `simple_auth_dialog_v1.dart`
   - Use existing `AuthenticationModal` (Material Design 3)

### Step 10: Verify Migration
```sql
-- Verify all data migrated correctly
SELECT 
  'categories' as table_name,
  COUNT(*) as v1_count,
  COUNT(CASE WHEN internal_id IS NOT NULL THEN 1 END) as v2_enhanced
FROM categories
UNION ALL
SELECT 
  'flashcard_sets',
  COUNT(*),
  COUNT(CASE WHEN flashcard_count IS NOT NULL THEN 1 END)
FROM flashcard_sets
UNION ALL
SELECT 
  'user_preferences',
  (SELECT COUNT(*) FROM auth.users),
  COUNT(*)
FROM user_preferences;

-- Check that all users have preferences
SELECT 
  u.id as user_id,
  u.email,
  CASE WHEN up.user_id IS NOT NULL THEN 'Has Preferences' ELSE 'Missing Preferences' END as status
FROM auth.users u
LEFT JOIN user_preferences up ON u.id = up.user_id;

-- Verify category relationships
SELECT 
  iq.id,
  iq.category as old_category,
  c.name as new_category_name,
  iq.category_id IS NOT NULL as has_category_id
FROM interview_questions iq
LEFT JOIN categories c ON iq.category_id = c.id
LIMIT 10;
```

## Post-Migration Testing

### Test All v2 Features:
1. **Authentication** - Sign up/sign in/sign out
2. **Guest tracking** - Usage limits and session management
3. **Data relationships** - Category mappings work correctly
4. **Performance** - Queries use new indexes
5. **Security** - RLS policies protect data correctly
6. **Automation** - Triggers maintain data consistency

### Rollback Plan (If Needed)
If migration fails, you can rollback by:
1. Restoring from backups
2. Removing new columns: `ALTER TABLE ... DROP COLUMN ...`
3. Dropping new tables: `DROP TABLE user_preferences, guest_sessions;`
4. Removing new triggers and functions

## Migration Complete ✅
Your database is now upgraded to v2 with all enhanced features:
- ✅ Enhanced security with comprehensive RLS
- ✅ Guest user tracking and usage limits
- ✅ Performance optimization with strategic indexes
- ✅ Automated data management with triggers
- ✅ Advanced features ready for implementation
- ✅ All existing data preserved and enhanced
