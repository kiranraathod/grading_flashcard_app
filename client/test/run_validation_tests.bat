@echo off
REM Task 1.1 Validation Test Runner (Windows)
REM Automated test suite for SharedPreferences Data Validation implementation

echo 🔍 Task 1.1 Validation Test Suite
echo ==================================
echo Testing SharedPreferences Data Validation and Corruption Detection
echo.

REM Test results tracking
set TESTS_PASSED=0
set TESTS_FAILED=0
set TESTS_TOTAL=0

REM Check prerequisites
echo 📋 Checking Prerequisites
echo ------------------------

REM Check if Flutter is available
flutter --version >nul 2>&1
if %errorlevel% equ 0 (
    echo Flutter CLI: ✓ Available
) else (
    echo Flutter CLI: ✗ Not found
    echo Please install Flutter and ensure it's in your PATH
    exit /b 1
)

REM Check if we're in the right directory
if exist pubspec.yaml (
    echo Flutter Project: ✓ Found
) else (
    echo Flutter Project: ✗ pubspec.yaml not found
    echo Please run this script from the Flutter project root directory
    exit /b 1
)

REM Check for test files
echo.
if exist test\validation_test.dart (
    echo Test file validation_test.dart: ✓ Found
) else (
    echo Test file validation_test.dart: ⚠ Missing
)

if exist test\widget_test.dart (
    echo Test file widget_test.dart: ✓ Found
) else (
    echo Test file widget_test.dart: ⚠ Missing
)

echo.

REM Check for implementation files
echo 📁 Checking Implementation Files
echo -------------------------------

if exist lib\services\data_validation_service.dart (
    echo data_validation_service.dart: ✓ Found
) else (
    echo data_validation_service.dart: ✗ Missing
    echo Task 1.1 implementation appears incomplete
    exit /b 1
)

if exist lib\screens\data_validation_screen.dart (
    echo data_validation_screen.dart: ✓ Found
) else (
    echo data_validation_screen.dart: ✗ Missing
    echo Task 1.1 implementation appears incomplete
    exit /b 1
)

if exist lib\services\debug_service.dart (
    echo debug_service.dart: ✓ Found
) else (
    echo debug_service.dart: ✗ Missing
    echo Task 1.1 implementation appears incomplete
    exit /b 1
)

echo.

REM Install dependencies
echo 📦 Installing Dependencies
echo -------------------------
call flutter pub get

echo.

REM Run unit tests
echo 🧪 Running Unit Tests
echo --------------------

if exist test\validation_test.dart (
    echo Running Data Validation Service Tests...
    call flutter test test\validation_test.dart >nul 2>&1
    if %errorlevel% equ 0 (
        echo Data Validation Service Tests: ✓ PASSED
        set /a TESTS_PASSED+=1
    ) else (
        echo Data Validation Service Tests: ✗ FAILED
        echo   Run 'flutter test test\validation_test.dart' for details
        set /a TESTS_FAILED+=1
    )
    set /a TESTS_TOTAL+=1
) else (
    echo ⚠ Validation unit tests not found
)

echo.

REM Run widget tests
echo 🎨 Running Widget Tests
echo ----------------------

if exist test\widget_test.dart (
    echo Running Data Validation Screen Widget Tests...
    call flutter test test\widget_test.dart >nul 2>&1
    if %errorlevel% equ 0 (
        echo Widget Tests: ✓ PASSED
        set /a TESTS_PASSED+=1
    ) else (
        echo Widget Tests: ✗ FAILED
        echo   Run 'flutter test test\widget_test.dart' for details
        set /a TESTS_FAILED+=1
    )
    set /a TESTS_TOTAL+=1
) else (
    echo ⚠ Widget tests not found
)

echo.

REM Run integration tests
echo 🔗 Running Integration Tests
echo ----------------------------

echo Running Build Test...
call flutter build apk --debug --quiet >nul 2>&1
if %errorlevel% equ 0 (
    echo Build Test: ✓ PASSED
    set /a TESTS_PASSED+=1
) else (
    echo Build Test: ✗ FAILED
    set /a TESTS_FAILED+=1
)
set /a TESTS_TOTAL+=1

echo Running Static Analysis...
call flutter analyze --quiet >nul 2>&1
if %errorlevel% equ 0 (
    echo Static Analysis: ✓ PASSED
    set /a TESTS_PASSED+=1
) else (
    echo Static Analysis: ✗ FAILED
    set /a TESTS_FAILED+=1
)
set /a TESTS_TOTAL+=1

echo.

REM Manual test checklist
echo 📋 Manual Test Checklist
echo ------------------------
echo The following tests should be run manually:
echo.
echo 1. Navigate to /data-validation route in the app
echo 2. Verify validation screen loads and shows results
echo 3. Test console commands:
echo    - await DebugService.runDataValidation();
echo    - await DebugService.isReadyForMigration();
echo 4. Test with corrupted data scenarios
echo 5. Verify migration readiness assessment
echo.
echo See test\manual_testing_guide.md for detailed instructions
echo.

REM Display results summary
echo 📊 Test Results Summary
echo ======================
echo Total Tests: %TESTS_TOTAL%
echo Passed: %TESTS_PASSED%
echo Failed: %TESTS_FAILED%

if %TESTS_FAILED% equ 0 (
    echo.
    echo 🎉 All automated tests passed!
    echo ✅ Task 1.1 implementation appears to be working correctly
    echo.
    echo Next steps:
    echo 1. Run manual tests using test\manual_testing_guide.md
    echo 2. If all tests pass, proceed to Task 1.2 implementation
    echo 3. Use the validation system to identify data issues for repair
    exit /b 0
) else (
    echo.
    echo ❌ Some tests failed
    echo ⚠ Please fix failing tests before proceeding to Task 1.2
    echo.
    echo Debugging steps:
    echo 1. Run 'flutter test' for detailed error messages
    echo 2. Check implementation files for syntax errors
    echo 3. Verify all dependencies are properly installed
    echo 4. Review test expectations vs implementation
    exit /b 1
)
