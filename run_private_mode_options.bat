@echo off
echo ==================================================
echo  🔓 FlashMaster - Multiple Browser Options
echo ==================================================
echo.
echo Choose your preferred method:
echo [1] Web Server Mode (Manual incognito - RECOMMENDED)
echo [2] Chrome Direct Incognito Launch
echo [3] Firefox Private Window  
echo [4] Chrome with Clean Profile (No Extensions)
echo.
set /p choice="Enter choice (1-4): "

cd /d "C:\Users\ratho\Desktop\data analysis\clone_github\flashcard\grading_flashcard_app\client"

if "%choice%"=="1" (
    echo Starting Web Server Mode...
    echo After server starts, manually open: http://localhost:59143 in incognito
    flutter run -d web-server --web-port=59143
) else if "%choice%"=="2" (
    echo Starting Chrome Direct Incognito...
    flutter run -d chrome --web-port=59143 --web-browser-flag="--incognito"
) else if "%choice%"=="3" (
    echo Starting Web Server for Firefox Private...
    echo After server starts, open Firefox private window and go to: http://localhost:59143
    flutter run -d web-server --web-port=59143
) else if "%choice%"=="4" (
    echo Starting Chrome Clean Profile...
    flutter run -d chrome --web-port=59143 --web-browser-flag="--user-data-dir=temp --disable-extensions"
) else (
    echo Invalid choice, defaulting to Web Server Mode...
    flutter run -d web-server --web-port=59143
)

pause