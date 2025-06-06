# Supabase Project Setup Guide
## Step-by-Step Instructions for Database Configuration

### 1. Create Supabase Project

1. Go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Click "New project"
3. Choose organization (or create one)
4. Project details:
   - **Name**: `flashmaster-production`
   - **Database Password**: Generate a strong password (save it!)
   - **Region**: Choose closest to your users
   - **Pricing Plan**: Start with Free tier
5. Click "Create new project"
6. Wait for project initialization (2-3 minutes)

### 2. Get Project Configuration

Once project is ready:
1. Go to **Settings** → **API**
2. Copy these values:
   - **Project URL**: `https://[project-id].supabase.co`
   - **Anon (public) key**: `eyJ...` (long string)
3. Update your Flutter app:

```dart
// Add to utils/config.dart or use environment variables
AppConfig.setSupabaseConfig(
  url: 'https://your-project-id.supabase.co',
  anonKey: 'your-anon-key-here',
);
```

### 3. Deploy Database Schema

1. Go to **SQL Editor** in Supabase dashboard
2. Click "New query"
3. Copy and paste the complete schema from:
   `client/docs/supabase/database_schema/2025-06-06_supabase_schema_v2_auth.md`
4. Click "Run" to execute
5. Verify tables were created in **Table Editor**

### 4. Test Database Functions

In SQL Editor, run these test queries:

```sql
-- Test guest session creation
SELECT track_guest_usage('test-session-123');

-- Verify data
SELECT * FROM guest_sessions WHERE session_id = 'test-session-123';

-- Test multiple calls (should increment)
SELECT track_guest_usage('test-session-123');
SELECT track_guest_usage('test-session-123');

-- Should show usage_count = 3
SELECT * FROM guest_sessions WHERE session_id = 'test-session-123';
```

### 5. Configure Google OAuth

#### A. Create Google OAuth Application
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create new project or select existing one
3. Enable **Google+ API**
4. Go to **Credentials** → **Create Credentials** → **OAuth 2.0 Client IDs**
5. Application type: **Web application**
6. Authorized redirect URIs:
   ```
   https://your-project-id.supabase.co/auth/v1/callback
   ```

#### B. Configure in Supabase
1. Go to **Authentication** → **Providers** in Supabase
2. Enable **Google** provider
3. Enter from Google Console:
   - **Client ID**: From Google OAuth credentials
   - **Client Secret**: From Google OAuth credentials
4. Save configuration

#### C. Test OAuth Flow
1. In SQL Editor, create a test redirect:
```sql
SELECT auth.sign_in_with_oauth('google', 'https://your-project-id.supabase.co/auth/v1/callback');
```

### 6. Enable Authentication in Flutter App

Update your app configuration:

```dart
// Enable authentication features for testing
AppConfig.enableUsageLimits = true;
AppConfig.enforceAuthentication = true;

// Or use debug panel to toggle these settings
```

### 7. Verify Complete Setup

Test the complete flow:
1. **Open Flutter app** with debug panel
2. **Enable authentication features** via debug panel
3. **Perform 3 actions** (should trigger auth popup)
4. **Click "Sign in with Google"** (should open browser)
5. **Complete Google OAuth** (should return to app authenticated)
6. **Verify unlimited access** after authentication

Expected results:
- Guest session created and tracked
- Authentication popup appears at limit
- Google OAuth completes successfully
- User data migrated from guest session
- Unlimited access after authentication
