import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/dashboard_provider.dart';

class FocusTimer extends ConsumerStatefulWidget {
  const FocusTimer({super.key});

  @override
  ConsumerState<FocusTimer> createState() => _FocusTimerState();
}

class _FocusTimerState extends ConsumerState<FocusTimer> {
  int _totalSeconds = 25 * 60;
  int _secondsRemaining = 25 * 60;
  bool _isRunning = false;
  Timer? _timer;
  DateTime? _startTime;

  void _setCustomTime() async {
    final controller = TextEditingController(text: (_totalSeconds ~/ 60).toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom Timer (minutes)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'e.g., 25',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                Navigator.pop(ctx, val);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      _timer?.cancel();
      setState(() {
        _totalSeconds = result * 60;
        _secondsRemaining = _totalSeconds;
        _isRunning = false;
        _startTime = null;
      });
    }
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
      if (duration > 60) { // Only save if more than 1 minute
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Focus Timer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(Icons.tune, color: Colors.grey.shade400, size: 20),
                  onPressed: _setCustomTime,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Spacer(),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$minutes:$seconds',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const Text('Focus Time', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    const Text('Pomodoro', style: TextStyle(fontSize: 10, color: Colors.blueAccent)),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {}, // For skipping/modes
                  icon: const Icon(Icons.skip_next, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _toggleTimer,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(_isRunning ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 28),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _resetTimer,
                  icon: const Icon(Icons.refresh, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
