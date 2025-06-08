@echo off
echo ==================================================
echo  🔓 Starting FlashMaster in INCOGNITO MODE on Port 59143
echo ==================================================
echo.
echo This will bypass browser cache/cookies for clean OAuth testing
echo Opening FlashMaster at: http://localhost:59143 (Incognito)
echo.
cd /d "C:\Users\ratho\Desktop\data analysis\clone_github\flashcard\grading_flashcard_app\client"
flutter run -d chrome --web-port=59143 --web-browser-flag="--incognito"
pause