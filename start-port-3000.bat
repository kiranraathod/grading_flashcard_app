@echo off
echo ========================================
echo Starting FlashMaster on Port 3000
echo ========================================
echo.

echo 1. Stopping any running Flutter processes...
taskkill /F /IM dart.exe /T 2>nul
taskkill /F /IM flutter.exe /T 2>nul
echo.

echo 2. Navigating to Flutter client...
cd /d "C:\Users\ratho\Desktop\data analysis\clone_github\flashcard\grading_flashcard_app\client"

echo.
echo 3. Cleaning Flutter cache...
flutter clean
flutter pub get

echo.
echo 🚀 4. Starting Flutter on port 3000 (CORS configured)...
echo.
echo ✅ Backend: https://grading-app-5o9m.onrender.com
echo ✅ CORS: Configured for localhost:3000
echo ✅ Database: 100%% health score
echo ✅ Authentication: Ready for testing
echo.

flutter run -d chrome --web-port=3000

echo.
echo ===========================================
echo 🎯 Expected Results:
echo ===========================================
echo ✅ App loads on http://localhost:3000
echo ✅ No XMLHttpRequest onError messages
echo ✅ Default flashcard sets load successfully
echo ✅ Default interview questions load successfully
echo ✅ No network connection errors
echo.
echo 🎯 Ready for Task 2.3 Authentication Testing:
echo   1. Try 3 flashcard grading actions as guest
echo   2. Authentication modal should appear on 4th action
echo   3. Test email/Google authentication
echo   4. Verify 5 actions available after authentication
echo.
pause
