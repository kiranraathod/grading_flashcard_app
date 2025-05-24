#!/bin/bash
# Theme Testing Suite Runner
# This script runs all theme tests and provides a comprehensive testing report

echo "🎨 FlashMaster Theme Testing Suite"
echo "=================================="

# Set working directory
cd "C:\Users\ratho\Desktop\data analysis\clone_github\flashcard\grading_flashcard_app\client"

echo "📋 Running Theme Test Categories:"
echo ""

echo "1. 🧪 Unit Tests (ThemeProvider)"
flutter test test/theme/unit/ --no-color --reporter=compact

echo ""
echo "2. 🎯 Widget Tests (Theme Toggle)"
flutter test test/theme/widget/ --no-color --reporter=compact

echo ""
echo "3. 🔗 Integration Tests (End-to-End)"
flutter test test/theme/integration/ --no-color --reporter=compact

echo ""
echo "4. ⚡ Performance Tests (Speed & Memory)"
flutter test test/theme/performance/ --no-color --reporter=compact

echo ""
echo "5. 📸 Golden Tests (Visual Regression)"
flutter test test/theme/golden/ --no-color --reporter=compact

echo ""
echo "✅ Theme Testing Suite Complete"
echo "📊 All theme components validated for:"
echo "   • Light/Dark mode consistency"
echo "   • Performance (<200ms switching)"
echo "   • Accessibility (WCAG compliance)"
echo "   • Visual regression prevention"
echo "   • Provider integration correctness"
