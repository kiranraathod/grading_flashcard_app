# Task 1.1 Manual Testing Guide

## Overview
This guide provides step-by-step instructions for manually testing the Task 1.1 implementation (SharedPreferences Data Validation and Corruption Detection) to ensure it works correctly.

## Prerequisites
- Flutter application running in debug mode
- Access to the application UI
- Access to debug console for developer commands

## Test Scenarios

### Scenario 1: Basic Validation Screen Access
**Objective**: Verify the validation screen is accessible and functional

**Steps**:
1. Run the Flutter application in debug mode
2. Navigate to the validation screen using one of these methods:
   - Add navigation button in the app UI
   - Use deep link: Navigate to `/data-validation` route
   - Manually navigate via route in debug mode

**Expected Results**:
- ✅ Screen loads without errors
- ✅ Auto-runs validation on screen load
- ✅ Shows loading indicator initially
- ✅ Displays validation results after completion
- ✅ Shows clear migration readiness status

### Scenario 2: Console Command Testing
**Objective**: Verify debug console commands work correctly

**Steps**:
1. Open Flutter debug console
2. Run the following commands:
   ```dart
   // Test basic validation
   await DebugService.runDataValidation();
   
   // Test readiness check
   bool ready = await DebugService.isReadyForMigration();
   print('Migration ready: $ready');
   
   // Test summary
   String summary = await DebugService.getValidationSummary();
   print('Summary: $summary');
   
   // Test detailed validation
   await DebugService.runDetailedValidation();
   ```

**Expected Results**:
- ✅ Commands execute without throwing exceptions
- ✅ Validation report printed to console
- ✅ Clear migration status (BLOCKED/READY) displayed
- ✅ Issue counts and details shown
- ✅ Actionable recommendations provided

### Scenario 3: Issue Detection Testing
**Objective**: Verify the system detects data corruption issues correctly

**Test Setup**: Create corrupted data scenarios by modifying SharedPreferences data (use Flutter Inspector or debug tools)

#### Sub-test 3a: Missing categoryId Detection
**Data Setup**: 
- Create interview questions without `categoryId` field
- Or set `categoryId` to null

**Expected Results**:
- ✅ Detects as CRITICAL ERROR
- ✅ Provides specific error message about Supabase filtering
- ✅ Migration status shows BLOCKED
- ✅ Suggests appropriate categoryId values

#### Sub-test 3b: Boolean Type Issues
**Data Setup**:
- Set boolean fields (`isDraft`, `isStarred`, `isCompleted`) to string values like `"false"` instead of `false`

**Expected Results**:
- ✅ Detects as WARNING
- ✅ Identifies specific fields with type issues
- ✅ Recommends proper boolean conversion

#### Sub-test 3c: Invalid Enum Values
**Data Setup**:
- Set `difficulty` field to invalid values like `"expert"` or `"beginner"`

**Expected Results**:
- ✅ Detects as ERROR
- ✅ Lists valid enum values (`entry`, `mid`, `senior`)
- ✅ Provides clear correction guidance

### Scenario 4: Valid Data Testing
**Objective**: Verify the system correctly identifies when data is migration-ready

**Test Setup**: Ensure all stored data has:
- Valid `categoryId` fields for all interview questions
- Proper boolean types for all boolean fields
- Valid enum values for difficulty levels
- Required fields present in all data objects

**Expected Results**:
- ✅ Migration status shows READY
- ✅ Green status indicators in UI
- ✅ Console commands return `isReadyForMigration() == true`
- ✅ No critical errors or regular errors in report
- ✅ Only warnings or suggestions may be present

### Scenario 5: UI Interaction Testing
**Objective**: Verify all UI components work correctly

**Steps**:
1. Access validation screen
2. Wait for validation to complete
3. Test the following interactions:
   - Click refresh button to re-run validation
   - Expand/collapse issue sections
   - Review issue details in expanded sections
   - Check color coding (red for errors, green for ready)
   - Verify issue count chips show correct numbers

**Expected Results**:
- ✅ All UI interactions work smoothly
- ✅ Refresh re-runs validation successfully
- ✅ Issue sections expand to show detailed information
- ✅ Color coding matches severity levels
- ✅ Issue counts are accurate

### Scenario 6: Error Handling Testing
**Objective**: Verify the system handles edge cases gracefully

#### Sub-test 6a: Empty Data
**Data Setup**: Clear all SharedPreferences data

**Expected Results**:
- ✅ System doesn't crash
- ✅ Reports warnings for missing data
- ✅ No critical errors for empty state
- ✅ Provides guidance about initial data setup

#### Sub-test 6b: Corrupted JSON
**Data Setup**: Manually corrupt JSON data in SharedPreferences

**Expected Results**:
- ✅ System doesn't crash
- ✅ Detects JSON corruption as error
- ✅ Provides clear error message
- ✅ Continues validation of other data

#### Sub-test 6c: Network/System Issues
**Data Setup**: Test during low memory or system stress

**Expected Results**:
- ✅ Graceful degradation
- ✅ Clear error messages if validation fails
- ✅ System remains stable

## Test Results Checklist

### Critical Functionality
- [ ] Validation screen accessible via `/data-validation` route
- [ ] Auto-runs validation on screen load
- [ ] Console commands (`DebugService`) work correctly
- [ ] Detects missing `categoryId` fields as CRITICAL errors
- [ ] Detects boolean type issues as warnings
- [ ] Detects invalid enum values as errors
- [ ] Shows READY status for valid data
- [ ] Shows BLOCKED status for invalid data

### User Experience
- [ ] Clear visual status indicators (green/red)
- [ ] Issue counts displayed accurately
- [ ] Expandable sections for issue details
- [ ] Refresh functionality works
- [ ] Loading states shown appropriately
- [ ] Error messages are actionable

### Developer Experience  
- [ ] Console output is comprehensive and readable
- [ ] Validation can be automated via `DebugService`
- [ ] Migration readiness easily checkable
- [ ] Detailed analysis available for debugging
- [ ] Integration points clear for Task 1.2

### Error Handling
- [ ] Handles empty data gracefully
- [ ] Handles corrupted JSON without crashing
- [ ] Provides meaningful error messages
- [ ] Continues validation despite individual failures
- [ ] System remains stable under stress

## Performance Testing

### Load Testing
**Test**: Run validation with large datasets
- Create 100+ interview questions with various issues
- Create 50+ flashcard sets with structure problems
- Measure validation completion time
- Verify memory usage remains reasonable

**Expected Results**:
- ✅ Completes within reasonable time (<10 seconds for large datasets)
- ✅ Memory usage remains stable
- ✅ UI remains responsive during validation
- ✅ All issues detected accurately regardless of dataset size

### Stress Testing
**Test**: Run validation multiple times in sequence
- Execute validation 10 times consecutively
- Mix console commands and UI-triggered validation
- Monitor for memory leaks or performance degradation

**Expected Results**:
- ✅ Consistent performance across multiple runs
- ✅ No memory leaks detected
- ✅ Results remain consistent and accurate
- ✅ System stability maintained

## Troubleshooting Common Issues

### Issue: Validation screen not accessible
**Cause**: Route not properly registered
**Solution**: Check `lib/main.dart` for `/data-validation` route

### Issue: Console commands not working
**Cause**: DebugService not properly imported
**Solution**: Verify import and check for compilation errors

### Issue: False positive/negative detection
**Cause**: Validation logic may need adjustment
**Solution**: Review validation rules in `DataValidationService`

### Issue: UI not updating after validation
**Cause**: State management issue
**Solution**: Check `setState()` calls in `DataValidationScreen`

## Success Criteria

The Task 1.1 implementation passes manual testing when:

✅ **All test scenarios pass** without critical failures  
✅ **Migration readiness assessment is accurate** and actionable  
✅ **Developer tools work reliably** for automated testing  
✅ **User interface is intuitive** and provides clear guidance  
✅ **Error handling is robust** and system remains stable  
✅ **Performance is acceptable** for realistic data sizes  

## Next Steps After Testing

1. **If tests pass**: Proceed to Task 1.2 implementation
2. **If issues found**: Document specific failures and fix before continuing
3. **If performance issues**: Optimize validation algorithms
4. **If UI issues**: Improve user experience before task handoff

---

**Testing Status**: Use this checklist to track testing progress  
**Last Updated**: December 2024  
**Tester**: _[Your Name]_  
**Test Environment**: _[Debug/Release/Device Info]_
