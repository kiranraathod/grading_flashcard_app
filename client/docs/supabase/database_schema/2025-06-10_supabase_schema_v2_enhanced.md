# Supabase Database Schema - v2 (2025-06-10)

This document outlines the **production-ready** database schema for the FlashMaster application's Supabase migration. This schema builds upon v1 with comprehensive authentication support, security policies, performance optimizations, and advanced features.

## Schema Evolution

- **v1 (2025-06-04)**: Basic table structure for core functionality
- **v2 (2025-06-10)**: Production-ready with authentication, security, and advanced features

## Key Improvements in v2

### 🔒 Security & Authentication
- **Row Level Security (RLS)** enabled on all tables
- **User data isolation** with comprehensive policies
- **Guest session management** for usage limits
- **Public sharing support** for flashcard sets

### ⚡ Performance & Scalability
- **Strategic indexes** for common query patterns
- **Denormalized counts** for fast reads
- **Automated data maintenance** with triggers
- **Efficient pagination** support

### 🚀 Advanced Features
- **User preferences** management
- **Spaced repetition** ready with progress tracking
- **Tagging system** with flexible arrays
- **Analytics tracking** with weekly activity
- **Legacy compatibility** for migration from local storage

### 🔧 Developer Experience
- **Automated triggers** for data consistency
- **Default data seeding** for new users
- **Migration helper functions**
- **Utility functions** for common operations

## Complete Schema Deployment

The complete SQL schema is available in: `lib/supabase_schema.sql`

This file contains:
- ✅ All table definitions with enhanced fields
- ✅ Row Level Security policies
- ✅ Performance indexes
- ✅ Automated triggers and functions
- ✅ Default data seeding
- ✅ Migration helpers
- ✅ Utility functions

## Core Tables Overview

### Authentication & Users
- `auth.users` (Supabase managed)
- `user_preferences` - User settings and preferences
- `guest_sessions` - Anonymous user session tracking

### Content Organization
- `categories` - Flashcard/question categorization with legacy support
- `flashcard_sets` - Collections with sharing and analytics
- `flashcards` - Individual cards with tags and difficulty

### Learning & Progress
- `user_progress` - Spaced repetition and completion tracking
- `interview_questions` - Practice questions with categorization
- `user_activity` - Recent views and activity tracking
- `weekly_activity` - Usage analytics and limit enforcement

## Deployment Instructions

### Step 1: Deploy Schema
```sql
-- Run the complete schema from lib/supabase_schema.sql
-- This creates all tables, policies, functions, and triggers
```

### Step 2: Enable Authentication
```dart
// In lib/utils/config.dart
static bool enableAuthentication = true;
static bool enableUsageLimits = true;
static bool enableGuestTracking = true;
```

### Step 3: Test System
1. **Guest Experience**: Test 3-action limit
2. **Authentication**: Test sign-up/sign-in flow
3. **Data Migration**: Test local-to-cloud data sync
4. **Usage Expansion**: Test 5-action limit for authenticated users

## Migration from v1

If you previously deployed v1 schema:

```sql
-- Add missing columns and features
ALTER TABLE categories ADD COLUMN internal_id TEXT;
ALTER TABLE categories ADD COLUMN color_hex TEXT DEFAULT '#6366f1';
ALTER TABLE categories ADD COLUMN is_default BOOLEAN DEFAULT false;

-- Enable RLS (see full migration in lib/supabase_schema.sql)
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
-- ... additional migration steps
```

## Advanced Features Ready

- 🌐 **Multi-device sync** - Real-time updates
- 👥 **Collaboration** - Public flashcard sharing
- 📈 **Analytics** - Comprehensive user tracking
- 🎯 **Spaced Repetition** - Algorithm-ready progress
- 🏷️ **Tagging** - Flexible organization
- ⭐ **Favorites** - User preference tracking

## Security Model

### Row Level Security
```sql
-- Users can only access their own data
CREATE POLICY "Users can manage their own categories" ON categories
  FOR ALL USING (auth.uid() = user_id);

-- Support for public sharing
CREATE POLICY "Users can view public flashcard sets" ON flashcard_sets
  FOR SELECT USING (is_public = true);
```

### Guest Session Security
```sql
-- Anonymous users tracked by session token
-- Automatic cleanup of expired sessions
-- No personal data stored for guests
```

## Performance Considerations

### Optimized Queries
- **Recent activity**: Efficient time-based ordering
- **User progress**: Fast review queue generation  
- **Search**: Full-text search ready
- **Analytics**: Pre-aggregated weekly data

### Scalability Features
- **UUID primary keys** for horizontal scaling
- **JSONB fields** for flexible metadata
- **Denormalized counts** for fast dashboards
- **Efficient foreign key relationships**

## Production Readiness

✅ **Security**: Complete RLS implementation  
✅ **Performance**: Optimized indexes and queries  
✅ **Scalability**: Designed for growth  
✅ **Maintainability**: Clear structure and documentation  
✅ **Migration**: Backward compatibility maintained  
✅ **Testing**: Comprehensive test data support  

## Next Steps

1. **Deploy**: Run `lib/supabase_schema.sql` in Supabase
2. **Configure**: Enable authentication features in app
3. **Test**: Verify complete user journey
4. **Monitor**: Track usage and performance
5. **Extend**: Add real-time features and advanced analytics

---

**Schema Status**: ✅ **Production Ready**  
**Last Updated**: 2025-06-10  
**Compatible With**: FlashMaster Authentication v2.0
