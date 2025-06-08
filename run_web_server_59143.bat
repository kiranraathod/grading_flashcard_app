@echo off
echo ==================================================
echo  🌐 FlashMaster - Web Server Mode (Manual Browser)
echo ==================================================
echo.
echo Starting Flutter development server WITHOUT auto-launch
echo You can then manually open in incognito mode
echo.
cd /d "C:\Users\ratho\Desktop\data analysis\clone_github\flashcard\grading_flashcard_app\client"
echo ⚡ Starting server on http://localhost:59143
echo.
echo 🔓 NEXT STEPS:
echo 1. Wait for "lib/main.dart is being served at" message
echo 2. Open Chrome incognito: Ctrl+Shift+N
echo 3. Navigate to: http://localhost:59143
echo.
flutter run -d web-server --web-port=59143
pause