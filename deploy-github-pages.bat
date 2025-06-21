@echo off
echo Deploying FlashMaster to GitHub Pages...

cd client

echo Cleaning previous builds...
flutter clean
flutter pub get

echo Building Flutter Web...
flutter build web --release --web-renderer canvaskit --base-href /grading_flashcard_app/

echo Copying build files...
cd ..
git checkout -b gh-pages 2>nul || git checkout gh-pages
git pull origin gh-pages 2>nul || echo "No remote gh-pages branch yet"

rem Clear existing files (except .git)
for /f "delims=" %%i in ('dir /b /a-d') do if not "%%i"==".git" del "%%i" >nul 2>&1
for /f "delims=" %%i in ('dir /b /ad') do if not "%%i"==".git" rmdir /s /q "%%i" >nul 2>&1

rem Copy new build files
xcopy "client\build\web\*" . /E /Y

rem Create .nojekyll file
echo. > .nojekyll

rem Create 404.html for SPA routing
copy index.html 404.html

echo Adding files to git...
git add .
git commit -m "Deploy Flutter web app - %date% %time%"

echo Pushing to gh-pages...
git push origin gh-pages

echo Switching back to main branch...
git checkout main

echo.
echo ✅ Deployment complete!
echo 🌐 Your app will be available at: https://yourusername.github.io/grading_flashcard_app/
echo.
echo Remember to:
echo 1. Update CORS_ORIGINS on Render to include your GitHub Pages URL
echo 2. Enable GitHub Pages in repository settings
echo 3. Wait 5-10 minutes for GitHub Pages to update
echo.
pause
