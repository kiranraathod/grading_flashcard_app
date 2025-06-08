@echo off
echo ==================================================
echo  🔓 FlashMaster - Direct Chrome Incognito Launch
echo ==================================================
echo.
echo This will automatically launch Chrome in incognito mode
echo If this fails, use run_web_server_59143.bat instead
echo.
cd /d "C:\Users\ratho\Desktop\data analysis\clone_github\flashcard\grading_flashcard_app\client"
echo Starting Flutter with Chrome incognito...
flutter run -d chrome --web-port=59143 --web-browser-flag="--incognito"
pause