@echo off
echo ==================================================
echo  🚀 Starting FlashMaster on Port 3000
echo ==================================================
echo.
echo Opening FlashMaster at: http://localhost:3000
echo.
cd /d "C:\Users\ratho\Desktop\data analysis\clone_github\flashcard\grading_flashcard_app\client"
flutter run -d chrome --web-port=3000
pause
