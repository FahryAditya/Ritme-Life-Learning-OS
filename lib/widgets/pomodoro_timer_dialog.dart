import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class PomodoroTimerDialog extends StatefulWidget {
  final String taskTitle;
  final int bpm;
  final void Function(int minutes)? onSessionComplete;

  const PomodoroTimerDialog({
    super.key,
    required this.taskTitle,
    required this.bpm,
    this.onSessionComplete,
  });

  @override
  State<PomodoroTimerDialog> createState() => _PomodoroTimerDialogState();
}

class _PomodoroTimerDialogState extends State<PomodoroTimerDialog> {
  static const int _focusDurationSeconds = 25 * 60;
  static const int _breakDurationSeconds = 5 * 60;

  int _remainingSeconds = _focusDurationSeconds;
  bool _isRunning = false;
  bool _isBreak = false;
  Timer? _timer;
  String _selectedAmbient = 'Lo-Fi Ambient';

  final List<String> _ambientPresets = [
    'Lo-Fi Ambient',
    'Suara Hujan',
    'Hutan Calm',
    'Coffee Shop',
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted && _isRunning) {
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          _timer?.cancel();
          final wasBreak = _isBreak;
          setState(() {
            _isRunning = false;
            _isBreak = !_isBreak;
            _remainingSeconds = _isBreak ? _breakDurationSeconds : _focusDurationSeconds;
          });
          // Fire callback only when a FOCUS session completes (not break)
          if (!wasBreak) {
            widget.onSessionComplete?.call(25);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(wasBreak
                  ? 'Istirahat Selesai! Siap Sesi Fokus Berikutnya.'
                  : 'Sesi Fokus Selesai! Waktunya Istirahat 5 Menit.'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _isBreak ? _breakDurationSeconds : _focusDurationSeconds;
    });
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final totalSeconds = _isBreak ? _breakDurationSeconds : _focusDurationSeconds;
    final progressFraction = (_remainingSeconds / totalSeconds).clamp(0.0, 1.0);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Badge & Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isBreak ? Colors.green.shade100 : AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isBreak ? 'Sesi Istirahat' : 'Sesi Fokus Pomodoro',
                    style: TextStyle(
                      color: _isBreak ? Colors.green.shade900 : AppColors.onPrimaryFixed,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              widget.taskTitle.isNotEmpty ? widget.taskTitle : 'Tugas Fokus Ritme',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'BPM Audio Engine: ${widget.bpm} BPM',
              style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),

            // Circular Countdown Dial
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 170,
                  height: 170,
                  child: CircularProgressIndicator(
                    value: progressFraction,
                    strokeWidth: 10,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isBreak ? Colors.green : AppColors.primary,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(_remainingSeconds),
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isRunning ? 'Sedang Berjalan...' : 'Sesi Deda',
                      style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Ambient Sound Wave Visualizer Animation
            if (_isRunning) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(7, (idx) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: 4,
                    height: 10.0 + (idx % 3 * 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleY(
                        begin: 0.4,
                        end: 1.6,
                        duration: Duration(milliseconds: 250 + (idx * 90)),
                      );
                }),
              ),
              const SizedBox(height: 16),
            ],

            // Ambient Preset Selector Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _ambientPresets.map((preset) {
                  final isSelected = _selectedAmbient == preset;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(preset, style: const TextStyle(fontSize: 11)),
                      selected: isSelected,
                      selectedColor: AppColors.primaryFixed,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedAmbient = preset);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Controls (Play/Pause, Reset, Toggle Mode)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton.outlined(
                  onPressed: _resetTimer,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Reset Sesi',
                ),
                GestureDetector(
                  onTap: _toggleTimer,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: _isBreak
                          ? const LinearGradient(colors: [Colors.green, Colors.teal])
                          : AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isBreak ? Colors.green : AppColors.primary).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRunning ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _timer?.cancel();
                    setState(() {
                      _isBreak = !_isBreak;
                      _isRunning = false;
                      _remainingSeconds = _isBreak ? _breakDurationSeconds : _focusDurationSeconds;
                    });
                  },
                  child: Text(_isBreak ? 'Sesi Fokus' : 'Istirahat'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
