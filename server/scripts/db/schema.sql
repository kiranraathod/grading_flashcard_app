-- Database Schema for Flashcard Grading App
-- Run this in the Supabase SQL Editor to create the necessary tables and functions

-- Users table (integrates with Supabase Auth)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    username TEXT UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Flashcards table
CREATE TABLE IF NOT EXISTS public.flashcards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    category TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Flashcard grades table
CREATE TABLE IF NOT EXISTS public.flashcard_grades (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    card_id UUID REFERENCES public.flashcards(id) NOT NULL,
    user_answer TEXT NOT NULL,
    grade TEXT NOT NULL,
    feedback TEXT,
    suggestions JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- User feedback table
CREATE TABLE IF NOT EXISTS public.user_feedback (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    card_id UUID REFERENCES public.flashcards(id) NOT NULL,
    feedback TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- User progress table (for spaced repetition)
CREATE TABLE IF NOT EXISTS public.user_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    card_id UUID REFERENCES public.flashcards(id) NOT NULL,
    confidence_level SMALLINT DEFAULT 0,
    ease_factor REAL DEFAULT 2.5,
    interval INTEGER DEFAULT 1,
    repetitions INTEGER DEFAULT 0,
    next_review_date TIMESTAMP WITH TIME ZONE DEFAULT now(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Study sessions table
CREATE TABLE IF NOT EXISTS public.study_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE DEFAULT now(),
    end_time TIMESTAMP WITH TIME ZONE,
    cards_studied INTEGER DEFAULT 0
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.flashcards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.flashcard_grades ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.study_sessions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Profiles: users can only read/update their own profile
CREATE POLICY "Users can view their own profile" 
    ON public.profiles FOR SELECT 
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" 
    ON public.profiles FOR UPDATE 
    USING (auth.uid() = id);

-- Flashcards: users can CRUD their own flashcards
CREATE POLICY "Users can manage their own flashcards" 
    ON public.flashcards FOR ALL 
    USING (auth.uid() = user_id);

-- Flashcard grades: users can only access their own grades
CREATE POLICY "Users can access their own grades" 
    ON public.flashcard_grades FOR ALL 
    USING (auth.uid() = user_id);

-- User feedback: users can only access their own feedback
CREATE POLICY "Users can access their own feedback" 
    ON public.user_feedback FOR ALL 
    USING (auth.uid() = user_id);

-- User progress: users can only access their own progress
CREATE POLICY "Users can access their own progress" 
    ON public.user_progress FOR ALL 
    USING (auth.uid() = user_id);

-- Study sessions: users can only access their own sessions
CREATE POLICY "Users can access their own study sessions" 
    ON public.study_sessions FOR ALL 
    USING (auth.uid() = user_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers for updated_at
CREATE TRIGGER update_profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_flashcards_updated_at
BEFORE UPDATE ON public.flashcards
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_progress_updated_at
BEFORE UPDATE ON public.user_progress
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to get due cards
CREATE OR REPLACE FUNCTION get_due_cards(user_uuid UUID, card_limit INTEGER)
RETURNS TABLE (
    id UUID,
    card_id UUID,
    question TEXT,
    answer TEXT,
    confidence_level SMALLINT,
    next_review_date TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        up.id,
        up.card_id,
        f.question,
        f.answer,
        up.confidence_level,
        up.next_review_date
    FROM
        public.user_progress up
    JOIN
        public.flashcards f ON up.card_id = f.id
    WHERE
        up.user_id = user_uuid
        AND up.next_review_date <= NOW()
    ORDER BY
        up.next_review_date ASC
    LIMIT
        card_limit;
END;
$$ LANGUAGE plpgsql;

-- Create hook to create a profile when a new user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username)
  VALUES (NEW.id, NEW.email);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Set up the trigger to call the function after a user is inserted
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
