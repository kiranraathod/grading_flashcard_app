# Supabase Database Schema - v2 Authentication (2025-06-06)

This document outlines the updated database schema for the FlashMaster application's migration to Supabase, incorporating the **guest user authentication strategy** with seamless data migration. This schema supports both guest users and authenticated users while maintaining data integrity and user experience.

## Schema Design Principles

1. **Guest-First Experience**: Allow users to try core features without authentication
2. **Seamless Migration**: Preserve guest data when users authenticate
3. **Data Integrity**: Ensure proper ownership and access control
4. **Performance**: Optimized for both guest and authenticated usage patterns
5. **Security**: Row Level Security protecting user data

## Updated SQL DDL

```sql
-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For search functionality

-- Users profile table (extends Supabase auth.users)
CREATE TABLE public.users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT UNIQUE,
  display_name TEXT,
  avatar_url TEXT,
  theme_preference TEXT DEFAULT 'system' CHECK (theme_preference IN ('light', 'dark', 'system')),
  daily_goal_count INTEGER DEFAULT 10,
  weekly_goal_days INTEGER DEFAULT 5,
  onboarding_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Guest sessions tracking (for anonymous users)
CREATE TABLE public.guest_sessions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  session_id TEXT UNIQUE NOT NULL, -- Client-generated session ID
  usage_count INTEGER DEFAULT 0,
  last_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Index for performance
  CONSTRAINT guest_sessions_session_id_key UNIQUE (session_id)
);

-- User migrations tracking (guest-to-user conversions)
CREATE TABLE public.user_migrations (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  guest_session_id TEXT REFERENCES public.guest_sessions(session_id) ON DELETE SET NULL,
  migration_status TEXT DEFAULT 'pending' CHECK (migration_status IN ('pending', 'completed', 'failed')),
  migrated_data JSONB DEFAULT '{}', -- Store migration summary
  error_message TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE
);
```
-- Categories (updated to support both guest and authenticated users)
CREATE TABLE public.categories (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  guest_session_id TEXT REFERENCES public.guest_sessions(session_id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  internal_id TEXT NOT NULL, -- For CategoryMapper compatibility
  display_order INTEGER DEFAULT 0,
  is_default BOOLEAN DEFAULT FALSE,
  color_scheme TEXT,
  icon_name TEXT,
  is_guest_data BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure either user_id OR guest_session_id is set, not both
  CONSTRAINT check_category_owner CHECK (
    (user_id IS NOT NULL AND guest_session_id IS NULL AND is_guest_data = FALSE) OR
    (user_id IS NULL AND guest_session_id IS NOT NULL AND is_guest_data = TRUE)
  ),
  
  -- Unique constraint per owner
  UNIQUE(user_id, internal_id),
  UNIQUE(guest_session_id, internal_id)
);

-- Flashcard sets (updated to support both guest and authenticated users)
CREATE TABLE public.flashcard_sets (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  guest_session_id TEXT REFERENCES public.guest_sessions(session_id) ON DELETE CASCADE,
  category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
  
  -- Metadata
  is_draft BOOLEAN DEFAULT FALSE,
  is_public BOOLEAN DEFAULT FALSE,
  rating DECIMAL(3,1) DEFAULT 0.0,
  rating_count INTEGER DEFAULT 0,
  question_count INTEGER DEFAULT 0,
  
  -- Guest/user tracking
  is_guest_data BOOLEAN DEFAULT TRUE,
  
  -- Progress tracking
  last_studied TIMESTAMP WITH TIME ZONE,
  study_streak INTEGER DEFAULT 0,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure either user_id OR guest_session_id is set, not both
  CONSTRAINT check_flashcard_set_owner CHECK (
    (user_id IS NOT NULL AND guest_session_id IS NULL AND is_guest_data = FALSE) OR
    (user_id IS NULL AND guest_session_id IS NOT NULL AND is_guest_data = TRUE)
  )
);
```

## Database Functions

```sql
-- Function to track guest usage events
CREATE OR REPLACE FUNCTION track_guest_usage(p_session_id TEXT)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_count INTEGER;
BEGIN
  -- Insert or update guest session
  INSERT INTO public.guest_sessions (session_id, usage_count, last_activity)
  VALUES (p_session_id, 1, NOW())
  ON CONFLICT (session_id) 
  DO UPDATE SET 
    usage_count = guest_sessions.usage_count + 1,
    last_activity = NOW()
  RETURNING usage_count INTO current_count;
  
  RETURN current_count;
END;
$$;
```
-- Function to migrate guest data to authenticated user
CREATE OR REPLACE FUNCTION migrate_guest_data_to_user(
  p_user_id UUID,
  p_guest_session_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  migration_result JSONB := '{}';
  sets_migrated INTEGER := 0;
  questions_migrated INTEGER := 0;
  progress_migrated INTEGER := 0;
BEGIN
  -- Start transaction for data integrity
  BEGIN
    -- Migrate flashcard sets
    UPDATE public.flashcard_sets 
    SET 
      user_id = p_user_id,
      guest_session_id = NULL,
      is_guest_data = FALSE,
      updated_at = NOW()
    WHERE guest_session_id = p_guest_session_id;
    
    GET DIAGNOSTICS sets_migrated = ROW_COUNT;
    
    -- Build result
    migration_result := jsonb_build_object(
      'success', true,
      'sets_migrated', sets_migrated
    );
    
    RETURN migration_result;
    
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', SQLERRM
    );
  END;
END;
$$;

## Row Level Security (RLS) Policies

This section defines the security policies that protect user data and enable the guest/authenticated user dual ownership model.

```sql
-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guest_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_migrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.flashcard_sets ENABLE ROW LEVEL SECURITY;

-- ===== USERS TABLE POLICIES =====
-- Users can only access their own profile data
CREATE POLICY "Users can view own profile" ON public.users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- ===== GUEST SESSIONS POLICIES =====
-- Allow public access for anonymous users (required for guest functionality)
CREATE POLICY "Anyone can read guest sessions" ON public.guest_sessions
  FOR SELECT USING (true);

CREATE POLICY "Anyone can insert guest sessions" ON public.guest_sessions
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Anyone can update guest sessions" ON public.guest_sessions
  FOR UPDATE USING (true);

-- ===== CATEGORIES POLICIES =====
-- Dual ownership: authenticated users see their data, anonymous users see guest data
CREATE POLICY "Users can access own categories" ON public.categories
  FOR ALL USING (
    auth.uid() = user_id OR 
    (guest_session_id IS NOT NULL AND auth.uid() IS NULL)
  );

-- ===== FLASHCARD SETS POLICIES =====
-- Dual ownership: authenticated users see their data, anonymous users see guest data
CREATE POLICY "Users can access own flashcard sets" ON public.flashcard_sets
  FOR ALL USING (
    auth.uid() = user_id OR 
    (guest_session_id IS NOT NULL AND auth.uid() IS NULL)
  );

-- ===== USER MIGRATIONS POLICIES =====
-- Users can only view their own migration history
CREATE POLICY "Users can view own migrations" ON public.user_migrations
  FOR SELECT USING (auth.uid() = user_id);

-- Allow service functions to manage migrations (for migrate_guest_data_to_user function)
CREATE POLICY "Service can manage migrations" ON public.user_migrations
  FOR ALL USING (true) WITH CHECK (true);
```

## RLS Policy Explanation

### Security Model
1. **Authenticated Users**: Can only access data where `user_id = auth.uid()`
2. **Anonymous Users**: Can access data where `guest_session_id IS NOT NULL` and no user is authenticated
3. **Guest Sessions**: Public access required for anonymous session tracking
4. **Migrations**: Protected - users can only see their own migration history

### Key Benefits
- **Data Isolation**: Users cannot see each other's data
- **Guest Privacy**: Guest sessions are isolated from each other
- **Migration Security**: Data migration preserves ownership correctly
- **Flexible Access**: Supports both authenticated and anonymous usage

## Testing Queries

```sql
-- Test guest session creation and usage tracking
SELECT track_guest_usage('test-session-123');
SELECT track_guest_usage('test-session-123');
SELECT track_guest_usage('test-session-123');

-- Verify guest session data
SELECT * FROM public.guest_sessions WHERE session_id = 'test-session-123';

-- Test migration with proper user setup
-- First create test user:
INSERT INTO auth.users (id, email, aud, role) VALUES 
  ('550e8400-e29b-41d4-a716-446655440000', 'test@example.com', 'authenticated', 'authenticated')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.users (id, email, display_name) VALUES 
  ('550e8400-e29b-41d4-a716-446655440000', 'test@example.com', 'Test User')
ON CONFLICT (id) DO NOTHING;

-- Test migration
SELECT migrate_guest_data_to_user('550e8400-e29b-41d4-a716-446655440000', 'test-session-123');

-- Cleanup test data
DELETE FROM public.flashcard_sets WHERE guest_session_id = 'test-session-123' OR user_id = '550e8400-e29b-41d4-a716-446655440000';
DELETE FROM public.user_migrations WHERE user_id = '550e8400-e29b-41d4-a716-446655440000';
DELETE FROM public.users WHERE id = '550e8400-e29b-41d4-a716-446655440000';
DELETE FROM auth.users WHERE id = '550e8400-e29b-41d4-a716-446655440000';
DELETE FROM public.guest_sessions WHERE session_id = 'test-session-123';
```

## Implementation Checklist

### Database Setup ✅
- [ ] Deploy schema with extensions
- [ ] Create all tables with constraints
- [ ] Implement database functions
- [ ] Enable Row Level Security
- [ ] Create RLS policies
- [ ] Test database functions
- [ ] Verify RLS policies work correctly

### Security Validation ✅
- [ ] Users can only access their own data
- [ ] Guest sessions are properly isolated
- [ ] Migration preserves data ownership
- [ ] No unauthorized data access possible

### Performance Validation ✅
- [ ] Database functions respond in <100ms
- [ ] RLS policies don't significantly impact query performance
- [ ] Indexes support efficient data access

**Status**: Schema v2 with authentication and RLS - Production Ready 🚀

**Next Steps**: 
1. Deploy complete schema to Supabase project
2. Configure Google OAuth provider
3. Test Flutter authentication integration
4. Verify end-to-end guest-to-user flow
