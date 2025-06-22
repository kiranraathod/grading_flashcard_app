import 'package:flutter/material.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';

/// Material Design 3 compliant countdown timer widget for practice mode
/// Includes preset time buttons and customizable timer interface
class PracticeCountdownTimer extends StatefulWidget {
  final Function(bool isRunning, int timeRemaining)? onTimerStateChanged;
  final Function()? onTimerCompleted;
  final Function(int selectedSeconds)? onTimeSelected;
  final int? initialDuration;
  final bool autoStart;

  const PracticeCountdownTimer({
    super.key,
    this.onTimerStateChanged,
    this.onTimerCompleted,
    this.onTimeSelected,
    this.initialDuration,
    this.autoStart = false,
  });

  @override
  State<PracticeCountdownTimer> createState() => _PracticeCountdownTimerState();
}

class _PracticeCountdownTimerState extends State<PracticeCountdownTimer> {
  late CountDownController _controller;
  int _selectedDuration = 300; // Default 5 minutes
  bool _isRunning = false;
  int _currentTimeRemaining = 0;

  // Material Design 3 preset durations for educational contexts
  final List<TimerPreset> _presets = [
    TimerPreset(label: '1 min', duration: 60, icon: Icons.speed),
    TimerPreset(label: '3 min', duration: 180, icon: Icons.timer_3_outlined),
    TimerPreset(label: '5 min', duration: 300, icon: Icons.timer_outlined),
    TimerPreset(label: '10 min', duration: 600, icon: Icons.timer_10_outlined),
    TimerPreset(label: '25 min', duration: 1500, icon: Icons.work_outline), // Pomodoro
  ];

  @override
  void initState() {
    super.initState();
    _controller = CountDownController();
    
    if (widget.initialDuration != null) {
      _selectedDuration = widget.initialDuration!;
    }
    _currentTimeRemaining = _selectedDuration;
    
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startTimer();
      });
    }
  }

  @override
  void dispose() {
    // Note: CountDownController doesn't have a dispose method
    // The controller lifecycle is managed by the circular_countdown_timer widget
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
    });
    _controller.start();
    widget.onTimerStateChanged?.call(true, _currentTimeRemaining);
  }

  void _pauseTimer() {
    setState(() {
      _isRunning = false;
    });
    _controller.pause();
    widget.onTimerStateChanged?.call(false, _currentTimeRemaining);
  }

  void _resumeTimer() {
    setState(() {
      _isRunning = true;
    });
    _controller.resume();
    widget.onTimerStateChanged?.call(true, _currentTimeRemaining);
  }

  void _resetTimer() {
    setState(() {
      _isRunning = false;
      _currentTimeRemaining = _selectedDuration;
    });
    _controller.reset();
    widget.onTimerStateChanged?.call(false, _selectedDuration);
  }

  void _selectPreset(int duration) {
    if (!_isRunning) {
      setState(() {
        _selectedDuration = duration;
        _currentTimeRemaining = duration;
      });
      _controller.reset();
      widget.onTimeSelected?.call(duration);
      widget.onTimerStateChanged?.call(false, duration);
    }
  }

  void _onTimerComplete() {
    setState(() {
      _isRunning = false;
      _currentTimeRemaining = 0;
    });
    widget.onTimerCompleted?.call();
    widget.onTimerStateChanged?.call(false, 0);
  }

  void _onTimerChange(String timeStamp) {
    // Extract seconds from MM:SS format
    final parts = timeStamp.split(':');
    if (parts.length == 2) {
      final minutes = int.tryParse(parts[0]) ?? 0;
      final seconds = int.tryParse(parts[1]) ?? 0;
      final totalSeconds = (minutes * 60) + seconds;
      
      setState(() {
        _currentTimeRemaining = totalSeconds;
      });
      widget.onTimerStateChanged?.call(_isRunning, totalSeconds);
    }
  }

  Color _getTimerColor() {
    final theme = Theme.of(context);
    if (_currentTimeRemaining <= 30) {
      return theme.colorScheme.error; // Red for last 30 seconds
    } else if (_currentTimeRemaining <= 60) {
      return theme.colorScheme.tertiary; // Orange warning for last minute
    }
    return theme.colorScheme.primary; // Primary color for normal operation
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Timer preset buttons
            if (!_isRunning) ...[
              Text(
                'Set Timer Duration',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presets.map((preset) {
                  final isSelected = preset.duration == _selectedDuration;
                  return FilterChip(
                    avatar: Icon(
                      preset.icon,
                      size: 18,
                      color: isSelected 
                        ? colorScheme.onPrimary 
                        : colorScheme.primary,
                    ),
                    label: Text(preset.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) _selectPreset(preset.duration);
                    },
                    selectedColor: colorScheme.primary,
                    checkmarkColor: colorScheme.onPrimary,
                    labelStyle: TextStyle(
                      color: isSelected 
                        ? colorScheme.onPrimary 
                        : colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected 
                        ? colorScheme.primary 
                        : colorScheme.outline,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Countdown timer display
            CircularCountDownTimer(
              duration: _selectedDuration,
              initialDuration: 0,
              controller: _controller,
              width: 120,
              height: 120,
              ringColor: colorScheme.outline.withValues(alpha: 0.2),
              fillColor: _getTimerColor(),
              backgroundColor: colorScheme.surface,
              strokeWidth: 8.0,
              strokeCap: StrokeCap.round,
              textStyle: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              isReverse: false,
              isReverseAnimation: true,
              autoStart: false,
              onStart: () {
                setState(() {
                  _isRunning = true;
                });
              },
              onComplete: _onTimerComplete,
              onChange: _onTimerChange,
              timeFormatterFunction: (defaultFormatterFunction, duration) {
                // Custom formatter for MM:SS display
                final minutes = duration.inMinutes;
                final seconds = duration.inSeconds % 60;
                return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
              },
            ),

            const SizedBox(height: 16),

            // Timer control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Start/Pause button
                FilledButton.icon(
                  onPressed: () {
                    if (_isRunning) {
                      _pauseTimer();
                    } else if (_currentTimeRemaining > 0) {
                      if (_currentTimeRemaining == _selectedDuration) {
                        _startTimer();
                      } else {
                        _resumeTimer();
                      }
                    }
                  },
                  icon: Icon(
                    _isRunning ? Icons.pause : Icons.play_arrow,
                    size: 20,
                  ),
                  label: Text(_isRunning ? 'Pause' : 'Start'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _isRunning 
                      ? colorScheme.secondary 
                      : colorScheme.primary,
                    foregroundColor: _isRunning 
                      ? colorScheme.onSecondary 
                      : colorScheme.onPrimary,
                  ),
                ),

                // Reset button
                FilledButton.tonalIcon(
                  onPressed: _resetTimer,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('Reset'),
                ),
              ],
            ),

            // Time remaining indicator
            const SizedBox(height: 8),
            if (_currentTimeRemaining != _selectedDuration)
              Text(
                'Time remaining: ${_formatTime(_currentTimeRemaining)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

/// Data class for timer presets
class TimerPreset {
  final String label;
  final int duration; // in seconds
  final IconData icon;

  const TimerPreset({
    required this.label,
    required this.duration,
    required this.icon,
  });
}
