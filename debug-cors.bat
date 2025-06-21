@echo off
echo ========================================
echo CORS Debugging for FlashMaster
echo ========================================
echo.

echo 1. Testing backend is alive...
curl -s https://grading-app-5o9m.onrender.com/api/ping
echo.
echo.

echo 2. Testing CORS with common localhost ports...
echo.

echo Testing port 3000...
curl -H "Origin: http://localhost:3000" -H "Access-Control-Request-Method: GET" -X OPTIONS https://grading-app-5o9m.onrender.com/api/ping
echo.

echo Testing port 8080...
curl -H "Origin: http://localhost:8080" -H "Access-Control-Request-Method: GET" -X OPTIONS https://grading-app-5o9m.onrender.com/api/ping
echo.

echo Testing port 58397...
curl -H "Origin: http://localhost:58397" -H "Access-Control-Request-Method: GET" -X OPTIONS https://grading-app-5o9m.onrender.com/api/ping
echo.

echo Testing 127.0.0.1:3000...
curl -H "Origin: http://127.0.0.1:3000" -H "Access-Control-Request-Method: GET" -X OPTIONS https://grading-app-5o9m.onrender.com/api/ping
echo.

echo ========================================
echo CORS Results Analysis:
echo ========================================
echo ✅ If you see "Access-Control-Allow-Origin" headers above, CORS is working
echo ❌ If you see errors or no CORS headers, CORS needs fixing
echo.
echo Next step: Check your current Chrome port...
echo.
pause
