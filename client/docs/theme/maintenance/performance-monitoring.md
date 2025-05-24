# Performance Monitoring for Theme System

**Guidelines for Monitoring and Optimizing Theme Performance**

## 🎯 Performance Targets

### Benchmarks
- **Theme Switch Time**: <150ms (target: <200ms)
- **Animation Frame Rate**: 60fps maintained
- **Memory Usage**: No leaks during theme changes
- **Battery Impact**: Minimal drain from theme operations

## 📊 Monitoring Metrics

### Key Performance Indicators
```dart
// Theme switch duration
final stopwatch = Stopwatch()..start();
themeProvider.toggleTheme();
await Future.delayed(Duration.zero); // Next frame
stopwatch.stop();
final switchDuration = stopwatch.elapsed;

// Frame render time
WidgetsBinding.instance.addTimingsCallback((timings) {
  final frameTime = timings.last.totalSpan;
  // Log if > 16.67ms (60fps threshold)
});
```

### Performance Test Pattern
```dart
testWidgets('theme switch performance', (tester) async {
  await tester.pumpWidget(/* setup */);
  
  final duration = await ThemeTestUtils.measureThemeSwitchTime(tester);
  
  expect(duration, lessThan(Duration(milliseconds: 150)));
});
```

## ⚡ Optimization Techniques

### RepaintBoundary Usage
```dart
RepaintBoundary(
  child: AnimatedContainer(
    duration: context.themeTransitionDuration,
    color: context.surfaceColor,
    child: content,
  ),
)
```

### Efficient State Management
```dart
// ✅ Good - targeted rebuilds
Consumer<ThemeProvider>(
  builder: (context, themeProvider, _) => ThemedWidget(),
)

// ❌ Avoid - unnecessary rebuilds
Provider.of<ThemeProvider>(context) // Rebuilds entire subtree
```

### Caching Theme Properties
```dart
Widget build(BuildContext context) {
  final appTheme = context.appTheme; // Cache once
  final isDark = context.isDarkMode;  // Cache once
  
  return Container(
    color: isDark ? appTheme.surfaceDark : appTheme.surfaceLight,
  );
}
```

## 🔧 Performance Debugging

### Flutter Inspector
- Monitor widget rebuilds during theme changes
- Check for unnecessary State updates
- Verify RepaintBoundary effectiveness

### Performance Overlay
```dart
MaterialApp(
  showPerformanceOverlay: true, // Enable in debug mode
  // ... app configuration
)
```

### Custom Performance Monitoring
```dart
class ThemePerformanceMonitor {
  static final _themeSwitchTimes = <Duration>[];
  
  static void recordThemeSwitch(Duration duration) {
    _themeSwitchTimes.add(duration);
    
    if (duration > Duration(milliseconds: 200)) {
      debugPrint('⚠️ Slow theme switch: ${duration.inMilliseconds}ms');
    }
  }
  
  static double get averageSwitchTime {
    if (_themeSwitchTimes.isEmpty) return 0;
    final total = _themeSwitchTimes.fold<int>(
      0, 
      (sum, duration) => sum + duration.inMilliseconds,
    );
    return total / _themeSwitchTimes.length;
  }
}
```

## 📱 Device-Specific Considerations

### Low-End Device Optimization
```dart
// Reduce animations on low-end devices
Duration getThemeTransitionDuration() {
  final isLowEndDevice = /* device capability check */;
  return isLowEndDevice 
    ? Duration(milliseconds: 100) 
    : Duration(milliseconds: 150);
}
```

### Battery Optimization
```dart
// Reduce theme change frequency if battery is low
bool shouldAllowThemeChange() {
  final batteryLevel = /* battery API call */;
  return batteryLevel > 0.2; // 20%
}
```

## 🔍 Continuous Monitoring

### CI/CD Performance Tests
```yaml
# .github/workflows/performance.yml
- name: Run performance tests
  run: |
    flutter test test/theme/performance/
    flutter drive --driver=test_driver/integration_test.dart \
                  --target=integration_test/theme_performance_test.dart
```

### Analytics Integration
```dart
// Track theme performance metrics
void logThemePerformance(Duration switchTime) {
  analytics.logEvent('theme_switch_performance', {
    'duration_ms': switchTime.inMilliseconds,
    'is_slow': switchTime.inMilliseconds > 200,
    'device_info': /* device information */,
  });
}
```

---

**Regular performance monitoring ensures the theme system maintains excellent user experience across all devices and scenarios.**
