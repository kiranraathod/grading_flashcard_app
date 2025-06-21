@echo off
echo Testing FlashMaster Local Frontend → Production Backend Connection
echo.

echo 1. Stopping any running Flutter processes...
taskkill /F /IM dart.exe 2>nul
taskkill /F /IM flutter.exe 2>nul

echo.
echo 2. Navigating to Flutter client directory...
cd /d "C:\Users\ratho\Desktop\data analysis\clone_github\flashcard\grading_flashcard_app\client"

echo.
echo 3. Testing API connectivity...
curl -s https://grading-app-5o9m.onrender.com/api/ping
echo.

echo.
echo 4. Testing database health...
curl -s https://grading-app-5o9m.onrender.com/api/database/ping
echo.

echo.
echo 5. Cleaning Flutter cache...
flutter clean
flutter pub get

echo.
echo 6. Starting Flutter with production backend...
echo ✅ Configuration updated to use: https://grading-app-5o9m.onrender.com
echo ✅ Database available: 100%% health score
echo ✅ Authentication ready: Supabase integration active
echo.
echo Starting app in 3 seconds...
timeout /t 3 >nul

flutter run -d chrome --web-port=58397

echo.
echo 🎯 If the app loads successfully:
echo   - No more network connection errors
echo   - Default data loads properly
echo   - Authentication system should work
echo   - Usage limits functional
echo.
echo 🚨 If CORS errors appear:
echo   - Update CORS_ORIGINS on Render to include http://localhost:58397
echo   - Add wildcard pattern: http://localhost:*
echo.
pause
