# FlashMaster Supabase Integration Context

## 📋 Overview

This document outlines the planned Supabase integration for FlashMaster, a Flutter flashcard application. The integration will replace the current server-driven default data system with a full-featured backend-as-a-service solution.

## 🎯 Current State (Post Task 5.1)

### ✅ Completed Migration
- **Status**: Successfully migrated from hardcoded client data to server-driven data
- **Architecture**: FastAPI server with 6 default data endpoints
- **Client Services**: HTTP client, caching, and default data services implemented
- **Data Flow**: Client → FastAPI Server → LLM Services (Google Gemini)

### 🏗️ Current Architecture Components

#### Server Side (Python FastAPI)
```
├── API Routes (6 endpoints)
│   ├── GET /api/default-data/health
│   ├── GET /api/default-data/categories
│   ├── GET /api/default-data/flashcard-sets
│   ├── GET /api/default-data/interview-questions
│   ├── GET /api/default-data/category-counts
│   └── GET /api/default-data/
├── Services Layer
│   ├── DefaultDataService
│   ├── LLM Service (Google Gemini)
│   └── Job Description Service
└── Data Models
    ├── DefaultFlashcardSetResponse
    ├── DefaultInterviewQuestionResponse
    └── DefaultCategoryResponse
```

#### Client Side (Flutter)
```
├── Services
│   ├── HttpClientService (with retry & timeout)
│   ├── CacheManager (SharedPreferences)
│   ├── DefaultDataService (server integration)
│   └── CategoryConfigService
├── State Management (BLoC)
└── UI Layer (Screens & Widgets)
```

## 🎯 Supabase Integration Plan

### 🗄️ Database Schema Design

Based on the architecture diagram, the following PostgreSQL schema will be implemented:

```sql
-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE,
    full_name VARCHAR(255),
    avatar_url TEXT,
    subscription_tier VARCHAR(50) DEFAULT 'free',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Categories table
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    color VARCHAR(7), -- Hex color code
    icon VARCHAR(50),
    is_default BOOLEAN DEFAULT false,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Collections table (flashcard sets)
CREATE TABLE collections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category_id UUID REFERENCES categories(id),
    created_by UUID REFERENCES users(id) NOT NULL,
    is_public BOOLEAN DEFAULT false,
    is_draft BOOLEAN DEFAULT true,
    rating DECIMAL(3,2) DEFAULT 0.0,
    rating_count INTEGER DEFAULT 0,
    difficulty_level VARCHAR(20), -- 'beginner', 'intermediate', 'advanced'
    estimated_time_minutes INTEGER,
    tags TEXT[], -- Array of tags
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Questions table (flashcards and interview questions)
CREATE TABLE questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_text TEXT NOT NULL,
    answer_text TEXT NOT NULL,
    question_type VARCHAR(20) NOT NULL, -- 'flashcard', 'interview', 'multiple_choice'
    collection_id UUID REFERENCES collections(id),
    category_id UUID REFERENCES categories(id),
    subtopic VARCHAR(255),
    difficulty VARCHAR(20), -- 'entry', 'mid', 'senior'
    order_index INTEGER,
    is_starred BOOLEAN DEFAULT false,
    created_by UUID REFERENCES users(id) NOT NULL,
    metadata JSONB, -- Flexible field for question-specific data
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User Progress table
CREATE TABLE user_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) NOT NULL,
    question_id UUID REFERENCES questions(id) NOT NULL,
    collection_id UUID REFERENCES collections(id),
    is_completed BOOLEAN DEFAULT false,
    is_correct BOOLEAN,
    attempts_count INTEGER DEFAULT 0,
    last_attempt_score DECIMAL(5,2),
    time_spent_seconds INTEGER,
    last_reviewed_at TIMESTAMP WITH TIME ZONE,
    next_review_at TIMESTAMP WITH TIME ZONE,
    review_interval_days INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, question_id)
);

-- Weekly Activity table
CREATE TABLE weekly_activity (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) NOT NULL,
    week_start_date DATE NOT NULL,
    questions_answered INTEGER DEFAULT 0,
    correct_answers INTEGER DEFAULT 0,
    time_spent_minutes INTEGER DEFAULT 0,
    streak_days INTEGER DEFAULT 0,
    collections_studied UUID[], -- Array of collection IDs
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, week_start_date)
);

-- Add indexes for better performance
CREATE INDEX idx_questions_category_id ON questions(category_id);
CREATE INDEX idx_questions_collection_id ON questions(collection_id);
CREATE INDEX idx_questions_created_by ON questions(created_by);
CREATE INDEX idx_user_progress_user_id ON user_progress(user_id);
CREATE INDEX idx_user_progress_question_id ON user_progress(question_id);
CREATE INDEX idx_weekly_activity_user_id ON weekly_activity(user_id);
CREATE INDEX idx_collections_created_by ON collections(created_by);
CREATE INDEX idx_collections_category_id ON collections(category_id);
```

### 🔐 Row Level Security (RLS) Policies

```sql
-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_activity ENABLE ROW LEVEL SECURITY;

-- Users can only view/edit their own profile
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

-- Public categories are viewable by all, private categories by creator
CREATE POLICY "View public categories" ON categories
    FOR SELECT USING (is_default = true OR created_by = auth.uid());

-- Users can view public collections and their own collections
CREATE POLICY "View accessible collections" ON collections
    FOR SELECT USING (is_public = true OR created_by = auth.uid());

CREATE POLICY "Users manage own collections" ON collections
    FOR ALL USING (created_by = auth.uid());

-- Users can view questions from accessible collections
CREATE POLICY "View accessible questions" ON questions
    FOR SELECT USING (
        collection_id IN (
            SELECT id FROM collections 
            WHERE is_public = true OR created_by = auth.uid()
        )
    );

CREATE POLICY "Users manage own questions" ON questions
    FOR ALL USING (created_by = auth.uid());

-- Users can only access their own progress
CREATE POLICY "Users access own progress" ON user_progress
    FOR ALL USING (user_id = auth.uid());

-- Users can only access their own activity
CREATE POLICY "Users access own activity" ON weekly_activity
    FOR ALL USING (user_id = auth.uid());
```

## 🚀 Migration Strategy

### Phase 1: Infrastructure Setup
- [ ] Set up Supabase project
- [ ] Configure authentication providers
- [ ] Implement database schema
- [ ] Set up Row Level Security policies
- [ ] Configure real-time subscriptions

### Phase 2: Service Layer Migration
- [ ] Create Supabase client service
- [ ] Implement authentication service
- [ ] Replace DefaultDataService with Supabase queries
- [ ] Implement real-time data synchronization
- [ ] Add offline-first capabilities with local database

### Phase 3: Feature Enhancement
- [ ] User registration and authentication
- [ ] Personal flashcard collections
- [ ] Progress tracking and analytics
- [ ] Social features (sharing collections)
- [ ] Advanced search and filtering

### Phase 4: Advanced Features
- [ ] Real-time collaboration
- [ ] Spaced repetition algorithm
- [ ] Performance analytics
- [ ] Export/import functionality

## 🔧 Implementation Details

### 📱 Client-Side Changes

#### New Dependencies
```yaml
# pubspec.yaml additions
dependencies:
  supabase_flutter: ^2.3.4
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  connectivity_plus: ^5.0.2
```

#### Service Architecture
```dart
// New services to implement
class SupabaseService {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  final SupabaseClient client = Supabase.instance.client;
  
  // Authentication methods
  Future<AuthResponse> signUp(String email, String password);
  Future<AuthResponse> signIn(String email, String password);
  Future<void> signOut();
  
  // Data methods
  Future<List<Collection>> getUserCollections();
  Future<List<Question>> getQuestions(String collectionId);
  Future<void> saveProgress(UserProgress progress);
}

class AuthService extends ChangeNotifier {
  User? _user;
  bool get isAuthenticated => _user != null;
  
  Future<void> initialize();
  Future<bool> signUp(String email, String password);
  Future<bool> signIn(String email, String password);
  Future<void> signOut();
}

class OfflineDataService {
  // Hive-based local storage for offline capabilities
  Future<void> syncToLocal(List<Collection> collections);
  Future<List<Collection>> getLocalCollections();
  Future<void> syncToServer();
}
```

### 🗄️ Data Models Update

```dart
// Enhanced models for Supabase integration
class User {
  final String id;
  final String email;
  final String? username;
  final String? fullName;
  final String? avatarUrl;
  final String subscriptionTier;
  final DateTime createdAt;
  
  // Supabase integration methods
  factory User.fromSupabase(Map<String, dynamic> json);
  Map<String, dynamic> toSupabase();
}

class Collection {
  final String id;
  final String title;
  final String? description;
  final String? categoryId;
  final String createdBy;
  final bool isPublic;
  final bool isDraft;
  final double rating;
  final int ratingCount;
  final List<String> tags;
  final List<Question> questions;
  
  // Supabase integration methods
  factory Collection.fromSupabase(Map<String, dynamic> json);
  Map<String, dynamic> toSupabase();
}

class UserProgress {
  final String id;
  final String userId;
  final String questionId;
  final String? collectionId;
  final bool isCompleted;
  final bool? isCorrect;
  final int attemptsCount;
  final double? lastAttemptScore;
  final int? timeSpentSeconds;
  final DateTime? lastReviewedAt;
  final DateTime? nextReviewAt;
  
  factory UserProgress.fromSupabase(Map<String, dynamic> json);
  Map<String, dynamic> toSupabase();
}
```

## 🔄 Real-time Features

### Supabase Realtime Integration
```dart
class RealtimeService {
  late RealtimeChannel _channel;
  
  void initializeRealtime() {
    _channel = Supabase.instance.client
        .channel('flashmaster_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'collections',
          callback: (payload) => _handleCollectionUpdate(payload),
        )
        .subscribe();
  }
  
  void _handleCollectionUpdate(PostgresChangePayload payload) {
    // Handle real-time collection updates
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        _onCollectionAdded(payload.newRecord);
        break;
      case PostgresChangeEvent.update:
        _onCollectionUpdated(payload.newRecord);
        break;
      case PostgresChangeEvent.delete:
        _onCollectionDeleted(payload.oldRecord);
        break;
    }
  }
}
```

## 📊 Analytics & Performance

### Progress Tracking Queries
```sql
-- User performance analytics
CREATE OR REPLACE FUNCTION get_user_stats(user_uuid UUID)
RETURNS TABLE (
    total_questions_answered INTEGER,
    correct_percentage DECIMAL,
    current_streak INTEGER,
    total_study_time INTEGER,
    collections_completed INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_questions_answered,
        (COUNT(*) FILTER (WHERE is_correct = true) * 100.0 / COUNT(*))::DECIMAL as correct_percentage,
        COALESCE(MAX(streak_days), 0)::INTEGER as current_streak,
        COALESCE(SUM(time_spent_minutes), 0)::INTEGER as total_study_time,
        COUNT(DISTINCT collection_id)::INTEGER as collections_completed
    FROM user_progress up
    LEFT JOIN weekly_activity wa ON wa.user_id = up.user_id
    WHERE up.user_id = user_uuid
    AND up.is_completed = true;
END;
$$ LANGUAGE plpgsql;
```

## 🔐 Authentication Flow

### Supabase Auth Integration
```dart
class AuthenticationScreen extends StatefulWidget {
  @override
  _AuthenticationScreenState createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final AuthService _authService = AuthService();
  
  Future<void> _handleGoogleSignIn() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        Provider.google,
        redirectTo: 'com.flashmaster.app://login-callback',
      );
    } catch (error) {
      _showError(error.toString());
    }
  }
  
  Future<void> _handleEmailSignIn(String email, String password) async {
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      Navigator.pushReplacementNamed(context, '/home');
    } catch (error) {
      _showError(error.toString());
    }
  }
}
```

## 🧪 Testing Strategy

### Integration Tests
```dart
// Test Supabase integration
group('Supabase Integration Tests', () {
  late SupabaseService supabaseService;
  
  setUpAll(() async {
    await Supabase.initialize(
      url: 'test_supabase_url',
      anonKey: 'test_anon_key',
    );
    supabaseService = SupabaseService();
  });
  
  test('should fetch user collections', () async {
    // Test collection fetching
    final collections = await supabaseService.getUserCollections();
    expect(collections, isA<List<Collection>>());
  });
  
  test('should save user progress', () async {
    // Test progress saving
    final progress = UserProgress(/* test data */);
    await supabaseService.saveProgress(progress);
    // Verify progress was saved
  });
});
```

## 📈 Performance Considerations

### Optimization Strategies
1. **Pagination**: Implement cursor-based pagination for large datasets
2. **Caching**: Maintain local cache with Hive for offline support
3. **Real-time Subscriptions**: Use selective subscriptions to reduce bandwidth
4. **Image Storage**: Utilize Supabase Storage for user-generated content
5. **Edge Functions**: Implement server-side logic for complex operations

### Database Optimization
```sql
-- Optimized queries with proper indexing
CREATE INDEX CONCURRENTLY idx_user_progress_composite 
ON user_progress(user_id, is_completed, last_reviewed_at);

CREATE INDEX CONCURRENTLY idx_questions_search 
ON questions USING gin(to_tsvector('english', question_text || ' ' || answer_text));
```

## 🚀 Deployment Strategy

### Environment Configuration
```dart
// Environment-specific Supabase configuration
class SupabaseConfig {
  static const String devUrl = 'https://dev-project.supabase.co';
  static const String prodUrl = 'https://prod-project.supabase.co';
  
  static String get url => kDebugMode ? devUrl : prodUrl;
  static String get anonKey => kDebugMode ? devAnonKey : prodAnonKey;
}
```

### Migration Scripts
```sql
-- Data migration from current system to Supabase
-- Insert default categories
INSERT INTO categories (id, name, description, color, icon, is_default) VALUES
('uuid-tech', 'Technical Knowledge', 'Programming and technical concepts', '#E3F2FD', 'article', true),
('uuid-applied', 'Applied Skills', 'Practical application skills', '#E8F5E8', 'build', true),
('uuid-behavioral', 'Behavioral Questions', 'Soft skills and behavioral topics', '#FFFDE7', 'people', true);

-- Migrate existing flashcard data
-- (Custom script based on current DefaultDataService data)
```

## 🎯 Success Metrics

### KPIs to Track
- User engagement (DAU, session length)
- Content creation (collections created per user)
- Learning progress (completion rates, accuracy)
- Performance (app load times, sync speeds)
- Reliability (uptime, error rates)

## 📝 Next Steps

### Immediate Actions
1. **Set up Supabase project** and configure basic authentication
2. **Implement database schema** with proper RLS policies
3. **Create migration scripts** to transfer existing data
4. **Update client services** to use Supabase instead of FastAPI
5. **Implement authentication flow** in Flutter app

### Future Enhancements
- **AI-powered recommendations** using user progress data
- **Collaborative learning** features with real-time updates
- **Advanced analytics** dashboard for progress tracking
- **Mobile-first PWA** version for broader accessibility

---

**Note**: This integration will transform FlashMaster from a server-dependent application to a fully-featured, scalable, multi-user platform while maintaining the excellent architectural foundation established in Task 5.1.
