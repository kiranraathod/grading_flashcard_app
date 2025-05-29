#!/bin/bash

# Task 1.1 Validation Test Runner
# Automated test suite for SharedPreferences Data Validation implementation

echo "🔍 Task 1.1 Validation Test Suite"
echo "=================================="
echo "Testing SharedPreferences Data Validation and Corruption Detection"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Function to run a test and capture results
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "Running $test_name... "
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAILED${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Function to run Flutter tests
run_flutter_test() {
    local test_file="$1"
    local test_name="$2"
    
    echo -n "Running $test_name... "
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    if flutter test "$test_file" > /dev/null 2>&1; then
        echo -e "${GREEN}PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAILED${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${YELLOW}  Run 'flutter test $test_file' for details${NC}"
    fi
}

# Check prerequisites
echo "📋 Checking Prerequisites"
echo "------------------------"

# Check if Flutter is available
if command -v flutter &> /dev/null; then
    echo -e "Flutter CLI: ${GREEN}✓ Available${NC}"
else
    echo -e "Flutter CLI: ${RED}✗ Not found${NC}"
    echo "Please install Flutter and ensure it's in your PATH"
    exit 1
fi

# Check if we're in the right directory
if [ -f "pubspec.yaml" ]; then
    echo -e "Flutter Project: ${GREEN}✓ Found${NC}"
else
    echo -e "Flutter Project: ${RED}✗ pubspec.yaml not found${NC}"
    echo "Please run this script from the Flutter project root directory"
    exit 1
fi

# Check for test files
TEST_FILES=(
    "test/validation_test.dart"
    "test/widget_test.dart"
)

for test_file in "${TEST_FILES[@]}"; do
    if [ -f "$test_file" ]; then
        echo -e "Test file $test_file: ${GREEN}✓ Found${NC}"
    else
        echo -e "Test file $test_file: ${YELLOW}⚠ Missing${NC}"
    fi
done

echo ""

# Check for implementation files
echo "📁 Checking Implementation Files"
echo "-------------------------------"

IMPL_FILES=(
    "lib/services/data_validation_service.dart"
    "lib/screens/data_validation_screen.dart"
    "lib/services/debug_service.dart"
)

for impl_file in "${IMPL_FILES[@]}"; do
    if [ -f "$impl_file" ]; then
        echo -e "$impl_file: ${GREEN}✓ Found${NC}"
    else
        echo -e "$impl_file: ${RED}✗ Missing${NC}"
        echo "Task 1.1 implementation appears incomplete"
        exit 1
    fi
done

echo ""

# Run dependency check
echo "📦 Installing Dependencies"
echo "-------------------------"
flutter pub get

echo ""

# Run unit tests
echo "🧪 Running Unit Tests"
echo "--------------------"

if [ -f "test/validation_test.dart" ]; then
    run_flutter_test "test/validation_test.dart" "Data Validation Service Tests"
else
    echo -e "${YELLOW}⚠ Validation unit tests not found${NC}"
fi

echo ""

# Run widget tests
echo "🎨 Running Widget Tests"
echo "----------------------"

if [ -f "test/widget_test.dart" ]; then
    run_flutter_test "test/widget_test.dart" "Data Validation Screen Widget Tests"
else
    echo -e "${YELLOW}⚠ Widget tests not found${NC}"
fi

echo ""

# Run integration tests
echo "🔗 Running Integration Tests"
echo "----------------------------"

# Test if the app builds successfully
run_test "Build Test" "flutter build apk --debug --quiet"

# Test if analysis passes
run_test "Static Analysis" "flutter analyze --quiet"

echo ""

# Run manual test validation
echo "📋 Manual Test Checklist"
echo "------------------------"
echo "The following tests should be run manually:"
echo ""
echo "1. Navigate to /data-validation route in the app"
echo "2. Verify validation screen loads and shows results"
echo "3. Test console commands:"
echo "   - await DebugService.runDataValidation();"
echo "   - await DebugService.isReadyForMigration();"
echo "4. Test with corrupted data scenarios"
echo "5. Verify migration readiness assessment"
echo ""
echo "See test/manual_testing_guide.md for detailed instructions"

echo ""

# Display results summary
echo "📊 Test Results Summary"
echo "======================"
echo -e "Total Tests: ${BLUE}$TESTS_TOTAL${NC}"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 All automated tests passed!${NC}"
    echo -e "${GREEN}✅ Task 1.1 implementation appears to be working correctly${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Run manual tests using test/manual_testing_guide.md"
    echo "2. If all tests pass, proceed to Task 1.2 implementation"
    echo "3. Use the validation system to identify data issues for repair"
else
    echo ""
    echo -e "${RED}❌ Some tests failed${NC}"
    echo -e "${YELLOW}⚠ Please fix failing tests before proceeding to Task 1.2${NC}"
    echo ""
    echo "Debugging steps:"
    echo "1. Run 'flutter test' for detailed error messages"
    echo "2. Check implementation files for syntax errors"
    echo "3. Verify all dependencies are properly installed"
    echo "4. Review test expectations vs implementation"
fi

echo ""

# Migration readiness check
echo "🚀 Migration Readiness Assessment"
echo "================================="
echo "Based on automated tests:"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "Implementation Status: ${GREEN}✅ COMPLETE${NC}"
    echo -e "Test Coverage: ${GREEN}✅ PASSING${NC}"
    echo -e "Ready for Task 1.2: ${GREEN}✅ YES${NC}"
    echo ""
    echo "The Task 1.1 implementation is ready for production use."
    echo "You can proceed with confidence to Task 1.2 (Data Repair)."
else
    echo -e "Implementation Status: ${YELLOW}⚠ ISSUES FOUND${NC}"
    echo -e "Test Coverage: ${RED}❌ FAILING${NC}"
    echo -e "Ready for Task 1.2: ${RED}❌ NO${NC}"
    echo ""
    echo "Please resolve test failures before proceeding to Task 1.2."
fi

echo ""
echo "🔍 For detailed testing guidance, see:"
echo "   - test/manual_testing_guide.md"
echo "   - docs/supabase/Critical Issues Before Supabase Migration/task_1.1.md"

# Exit with appropriate code
if [ $TESTS_FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi
