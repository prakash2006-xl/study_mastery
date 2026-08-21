import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../core/database/dashboard_repository.dart';
import 'widgets/global_ai_chat.dart';
import 'widgets/premium_sidebar.dart';
import '../application/dashboard_provider.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return _AlarmManagerWrapper(
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      drawer: isWideScreen ? null : Drawer(
        child: PremiumSidebar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            _goBranch(index);
            Navigator.pop(context); // close drawer
          },
        ),
      ),
      body: isWideScreen
          ? Row(
              children: [
                PremiumSidebar(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _goBranch,
                ),
                Expanded(child: navigationShell),
              ],
            )
          : Column(
              children: [
                AppBar(
                  title: const Text('PLOS', style: TextStyle(fontWeight: FontWeight.bold)),
                  leading: Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                ),
                Expanded(child: navigationShell),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => const GlobalAiChat(),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        tooltip: 'Global AI Companion',
        child: const Icon(Icons.psychology, size: 32),
      ),
    );
  }

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _AlarmManagerWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const _AlarmManagerWrapper({required this.child});
  @override
  ConsumerState<_AlarmManagerWrapper> createState() => _AlarmManagerWrapperState();
}

class _AlarmManagerWrapperState extends ConsumerState<_AlarmManagerWrapper> {
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Set<String> _triggeredAlarms = {};

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 15), _checkAlarms);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _checkAlarms(Timer timer) {
    final alarmsState = ref.read(alarmNotifierProvider);
    alarmsState.whenData((alarms) {
      final now = DateTime.now();
      for (final alarm in alarms) {
        if (!alarm.isEnabled) continue;
        if (_triggeredAlarms.contains(alarm.id)) continue;
        
        if (alarm.time.year == now.year &&
            alarm.time.month == now.month &&
            alarm.time.day == now.day &&
            alarm.time.hour == now.hour &&
            alarm.time.minute == now.minute) {
          _triggerAlarm(alarm);
        }
      }
    });
  }

  void _triggerAlarm(Alarm alarm) async {
    _triggeredAlarms.add(alarm.id);
    
    // Check if custom audio exists
    Source audioSource = AssetSource('audio/lofi_1.mp3');
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final audioDir = Directory(p.join(appDir.path, 'custom_audio'));
      if (await audioDir.exists()) {
        final files = audioDir.listSync().where((f) => f.path.toLowerCase().endsWith('.mp3')).toList();
        if (files.isNotEmpty) {
          audioSource = DeviceFileSource(files.first.path);
        }
      }
    } catch (_) {}

    // Play sound
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(audioSource);
    
    if (!mounted) return;
    
    // Show dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.alarm, color: Colors.purpleAccent, size: 28),
            SizedBox(width: 8),
            Text('Alarm'),
          ],
        ),
        content: Text('Time for: ${alarm.label}', style: const TextStyle(fontSize: 18)),
        actions: [
          ElevatedButton(
            onPressed: () {
              _audioPlayer.stop();
              // Disable the alarm
              ref.read(alarmNotifierProvider.notifier).toggleAlarm(alarm);
              Navigator.pop(ctx);
            },
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch alarms to ensure provider is initialized
    ref.watch(alarmNotifierProvider);
    return widget.child;
  }
}
