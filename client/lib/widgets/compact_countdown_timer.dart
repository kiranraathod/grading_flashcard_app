import 'package:flutter/material.dart';
import 'dart:async';

/// Compact countdown timer for practice mode header
/// Material Design 3 compliant with preset controls
class CompactCountdownTimer extends StatefulWidget {
  final Function(bool isRunning, int timeRemaining)? onTimerStateChanged;
  final Function()? onTimerCompleted;
  final int initialDuration;
  final bool autoStart;

  const CompactCountdownTimer({
    super.key,
    this.onTimerStateChanged,
    this.onTimerCompleted,
    this.initialDuration = 300, // Default 5 minutes
    this.autoStart = false,
  });

  @override
  State<CompactCountdownTimer> createState() => _CompactCountdownTimerState();
}

class _CompactCountdownTimerState extends State<CompactCountdownTimer>
    with TickerProviderStateMixin {
  Timer? _timer;
  late int _timeRemaining;
  bool _isRunning = false;
  bool _showPresets = false;
  late AnimationController _pulseController;

  // Quick preset durations for educational contexts
  final List<TimerPreset> _presets = [
    TimerPreset(label: '1m', duration: 60),
    TimerPreset(label: '3m', duration: 180),
    TimerPreset(label: '5m', duration: 300),
    TimerPreset(label: '10m', duration: 600),
    TimerPreset(label: '25m', duration: 1500), // Pomodoro
  ];

  @override
  void initState() {
    super.initState();
    _timeRemaining = widget.initialDuration;
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startTimer();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_timeRemaining <= 0) return;
    
    setState(() {
      _isRunning = true;
      _showPresets = false;
    });
    
    _pulseController.repeat(reverse: true);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
        } else {
          _completeTimer();
        }
      });
      widget.onTimerStateChanged?.call(_isRunning, _timeRemaining);
    });
  }

  void _pauseTimer() {
    setState(() {
      _isRunning = false;
    });
    _timer?.cancel();
    _pulseController.stop();
    widget.onTimerStateChanged?.call(false, _timeRemaining);
  }

  void _resetTimer() {
    setState(() {
      _isRunning = false;
      _timeRemaining = widget.initialDuration;
    });
    _timer?.cancel();
    _pulseController.stop();
    widget.onTimerStateChanged?.call(false, _timeRemaining);
  }

  void _completeTimer() {
    setState(() {
      _isRunning = false;
      _timeRemaining = 0;
    });
    _timer?.cancel();
    _pulseController.stop();
    widget.onTimerCompleted?.call();
    widget.onTimerStateChanged?.call(false, 0);
    
    // Show completion animation/feedback
    _showCompletionFeedback();
  }

  void _showCompletionFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.timer_off,
              color: Theme.of(context).colorScheme.onInverseSurface,
            ),
            const SizedBox(width: 8),
            const Text('Time\'s up!'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inverseSurface,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _selectPreset(int duration) {
    if (!_isRunning) {
      setState(() {
        _timeRemaining = duration;
        _showPresets = false;
      });
      widget.onTimerStateChanged?.call(false, duration);
    }
  }

  Color _getTimerColor() {
    final theme = Theme.of(context);
    if (_timeRemaining <= 30) {
      return theme.colorScheme.error; // Red for last 30 seconds
    } else if (_timeRemaining <= 60) {
      return theme.colorScheme.tertiary; // Orange warning for last minute
    }
    return const Color(0xFF10B981); // Green for normal operation
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main timer display
        Row(
          children: [
            // Timer icon with background
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getTimerColor(),
                    shape: BoxShape.circle,
                    boxShadow: _isRunning
                        ? [
                            BoxShadow(
                              color: _getTimerColor().withValues(alpha: 0.4),
                              blurRadius: 8 * (1 + _pulseController.value * 0.5),
                              spreadRadius: 2 * _pulseController.value,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    _isRunning ? Icons.timer : Icons.timer_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                );
              },
            ),
            
            const SizedBox(width: 12),
            
            // Timer text
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (!_isRunning) {
                    setState(() {
                      _showPresets = !_showPresets;
                    });
                  }
                },
                child: Text(
                  'Time: ${_formatTime(_timeRemaining)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _getTimerColor(),
                  ),
                ),
              ),
            ),
            
            // Timer controls
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Start/Pause button
                IconButton(
                  onPressed: () {
                    if (_isRunning) {
                      _pauseTimer();
                    } else if (_timeRemaining > 0) {
                      _startTimer();
                    }
                  },
                  icon: Icon(
                    _isRunning ? Icons.pause : Icons.play_arrow,
                    size: 20,
                  ),
                  color: _getTimerColor(),
                  tooltip: _isRunning ? 'Pause timer' : 'Start timer',
                ),
                
                // Reset button
                IconButton(
                  onPressed: _resetTimer,
                  icon: const Icon(Icons.refresh, size: 18),
                  color: theme.colorScheme.onSurfaceVariant,
                  tooltip: 'Reset timer',
                ),
                
                // Settings button (show presets)
                if (!_isRunning)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showPresets = !_showPresets;
                      });
                    },
                    icon: Icon(
                      _showPresets ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                    ),
                    color: theme.colorScheme.onSurfaceVariant,
                    tooltip: 'Timer settings',
                  ),
              ],
            ),
          ],
        ),
        
        // Preset duration chips (collapsible)
        if (_showPresets && !_isRunning) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _presets.map((preset) {
              final isSelected = preset.duration == _timeRemaining;
              return ActionChip(
                label: Text(
                  preset.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                onPressed: () => _selectPreset(preset.duration),
                backgroundColor: isSelected 
                  ? theme.colorScheme.primary.withValues(alpha: 0.12)
                  : theme.colorScheme.surface,
                side: BorderSide(
                  color: isSelected 
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.5),
                  width: isSelected ? 1.5 : 1,
                ),
                labelStyle: TextStyle(
                  color: isSelected 
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

/// Data class for timer presets
class TimerPreset {
  final String label;
  final int duration; // in seconds

  const TimerPreset({
    required this.label,
    required this.duration,
  });
}
