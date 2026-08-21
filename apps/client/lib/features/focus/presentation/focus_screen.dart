import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/application/dashboard_provider.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  int _totalSeconds = 25 * 60;
  int _secondsRemaining = 25 * 60;
  bool _isRunning = false;
  Timer? _timer;
  DateTime? _startTime;

  void _setDuration(int minutes) {
    if (_isRunning) return;
    setState(() {
      _totalSeconds = minutes * 60;
      _secondsRemaining = _totalSeconds;
    });
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      _startTime ??= DateTime.now();
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
        } else {
          _timer?.cancel();
          setState(() => _isRunning = false);
          _saveSession();
        }
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = _totalSeconds;
      _isRunning = false;
      _startTime = null;
    });
  }

  void _saveSession() {
    if (_startTime != null) {
      final int duration = _totalSeconds - _secondsRemaining;
      if (duration > 60) {
        ref.read(studySessionNotifierProvider.notifier).addStudySession(
          _startTime!,
          DateTime.now(),
          duration,
        );
      }
    }
    _resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final String seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    final double progress = 1 - (_secondsRemaining / _totalSeconds);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Timer', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildModeButton('Pomodoro', 25, _totalSeconds == 25 * 60, theme),
                const SizedBox(width: 16),
                _buildModeButton('Short Break', 5, _totalSeconds == 5 * 60, theme),
                const SizedBox(width: 16),
                _buildModeButton('Long Break', 15, _totalSeconds == 15 * 60, theme),
              ],
            ),
            const SizedBox(height: 64),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 300,
                  height: 300,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 16,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$minutes:$seconds',
                      style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
                    ),
                    const Text('REMAINING', style: TextStyle(fontSize: 14, color: Colors.grey, letterSpacing: 2)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 64),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _resetTimer,
                  icon: const Icon(Icons.refresh, size: 32),
                  color: Colors.grey,
                ),
                const SizedBox(width: 32),
                GestureDetector(
                  onTap: _toggleTimer,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(_isRunning ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 48),
                  ),
                ),
                const SizedBox(width: 32),
                IconButton(
                  onPressed: () {
                    _timer?.cancel();
                    _saveSession(); // End early
                  },
                  icon: const Icon(Icons.stop, size: 32),
                  color: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(String label, int minutes, bool isSelected, ThemeData theme) {
    return ActionChip(
      label: Text(label),
      onPressed: () => _setDuration(minutes),
      backgroundColor: isSelected ? theme.colorScheme.primary.withOpacity(0.2) : Colors.transparent,
      side: BorderSide(color: isSelected ? theme.colorScheme.primary : Colors.grey),
      labelStyle: TextStyle(color: isSelected ? theme.colorScheme.primary : Colors.grey),
    );
  }
}
