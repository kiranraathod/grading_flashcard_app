@echo off
echo ========================================
echo FlashMaster: Testing Production Backend Connection
echo ========================================
echo.

echo ⏳ Step 1: Testing API connectivity...
curl -s https://grading-app-5o9m.onrender.com/api/ping
echo.
echo.

echo ⏳ Step 2: Testing database health...
curl -s https://grading-app-5o9m.onrender.com/api/database/ping
echo.
echo.

echo ⏳ Step 3: Testing default data endpoints...
curl -s https://grading-app-5o9m.onrender.com/api/default-data/health
echo.
echo.

echo ✅ If all above returned JSON responses, CORS is working!
echo.

echo ⏳ Step 4: Navigating to Flutter client...
cd /d "C:\Users\ratho\Desktop\data analysis\clone_github\flashcard\grading_flashcard_app\client"

echo.
echo ⏳ Step 5: Cleaning Flutter cache...
flutter clean
flutter pub get

echo.
echo 🚀 Step 6: Starting Flutter with production backend...
echo.
echo ✅ Backend URL: https://grading-app-5o9m.onrender.com
echo ✅ Database URL: https://saxopupmwfcfjxuflfrx.supabase.co  
echo ✅ CORS Origins: localhost ports enabled
echo ✅ Authentication: Ready for testing
echo.
echo Starting app in 3 seconds...
timeout /t 3 >nul

flutter run -d chrome --web-port=58397

echo.
echo ===========================================
echo 🎯 What to Look For:
echo ===========================================
echo ✅ SUCCESS INDICATORS:
echo   - App loads without network errors
echo   - Default flashcard sets appear
echo   - Default interview questions load
echo   - No CORS errors in browser console
echo   - Authentication modal can be triggered
echo.
echo ❌ IF ERRORS PERSIST:
echo   - Check Render deployment is complete
echo   - Verify CORS_ORIGINS was saved correctly
echo   - Wait 2-3 minutes for deployment
echo.
echo 🎯 AUTHENTICATION TESTING (Task 2.3):
echo   - Try 3 flashcard actions as guest
echo   - Authentication modal should appear
echo   - Test email/Google sign-in
echo   - Verify 5 actions available after auth
echo.
pause
