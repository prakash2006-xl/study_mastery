import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class KeepFocusedWidget extends StatefulWidget {
  const KeepFocusedWidget({super.key});

  @override
  State<KeepFocusedWidget> createState() => _KeepFocusedWidgetState();
}

class _KeepFocusedWidgetState extends State<KeepFocusedWidget> with SingleTickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  double _volume = 0.5;

  final List<String> _assetPlaylist = [
    'audio/lofi_1.mp3',
    'audio/lofi_2.mp3',
    'audio/lofi_3.mp3',
  ];
  
  List<String> _localPlaylist = [];
  bool _isUsingLocal = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _audioPlayer.setVolume(_volume);

    _audioPlayer.onPlayerComplete.listen((event) {
      _playNext();
    });
    
    _loadLocalAudio();
  }

  Future<void> _loadLocalAudio() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final audioDir = Directory(p.join(appDir.path, 'custom_audio'));
      if (await audioDir.exists()) {
        final files = audioDir.listSync();
        setState(() {
          _localPlaylist = files
              .where((f) => f.path.toLowerCase().endsWith('.mp3'))
              .map((f) => f.path)
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading local audio: $e');
    }
  }

  Future<void> _importAudio() async {
    PlatformFile? result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
    );

    if (result != null && result.path != null) {
      try {
        final File sourceFile = File(result.path!);
        final appDir = await getApplicationDocumentsDirectory();
        final audioDir = Directory(p.join(appDir.path, 'custom_audio'));
        
        if (!await audioDir.exists()) {
          await audioDir.create(recursive: true);
        }
        
        final String newPath = p.join(audioDir.path, result.name);
        await sourceFile.copy(newPath);
        
        await _loadLocalAudio();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported ${result.name}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error importing file: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
  
  Source _getCurrentSource() {
    if (_isUsingLocal && _localPlaylist.isNotEmpty) {
      return DeviceFileSource(_localPlaylist[_currentIndex % _localPlaylist.length]);
    } else {
      return AssetSource(_assetPlaylist[_currentIndex % _assetPlaylist.length]);
    }
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(_getCurrentSource());
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _playNext() async {
    final listLength = (_isUsingLocal && _localPlaylist.isNotEmpty) ? _localPlaylist.length : _assetPlaylist.length;
    _currentIndex = (_currentIndex + 1) % listLength;
    if (_isPlaying) {
      await _audioPlayer.play(_getCurrentSource());
    }
    setState(() {});
  }
  
  void _toggleSource() async {
    if (_localPlaylist.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please import local MP3 files first.')),
      );
      return;
    }
    
    setState(() {
      _isUsingLocal = !_isUsingLocal;
      _currentIndex = 0; // Reset index when switching
    });
    
    if (_isPlaying) {
      await _audioPlayer.play(_getCurrentSource());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String trackName = _isUsingLocal && _localPlaylist.isNotEmpty
        ? p.basenameWithoutExtension(_localPlaylist[_currentIndex % _localPlaylist.length])
        : 'Lo-Fi Beats';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.music_note, size: 20, color: Colors.purpleAccent),
                    const SizedBox(width: 8),
                    const Text('Keep Focused', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.download, size: 16, color: Colors.grey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Import Custom MP3',
                      onPressed: _importAudio,
                    ),
                  ],
                ),
                InkWell(
                  onTap: _toggleSource,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _isUsingLocal ? Colors.purpleAccent : Colors.transparent, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Icon(_isPlaying ? Icons.speaker : Icons.speaker_notes_off, size: 12, color: _isUsingLocal ? Colors.purpleAccent : Colors.grey),
                        const SizedBox(width: 4),
                        Text(trackName.length > 12 ? '${trackName.substring(0, 10)}...' : trackName, 
                          style: TextStyle(fontSize: 10, color: _isUsingLocal ? Colors.purpleAccent : Colors.grey)
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                GestureDetector(
                  onTap: _togglePlay,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Lo-Fi Study • Deep Focus', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_isUsingLocal ? 'Local MP3' : '24/7 Radio', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: List.generate(15, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      width: 2,
                      height: _isPlaying ? (index % 5 + 1) * 4.0 : 2.0, // flat line if paused
                      color: theme.colorScheme.primary.withOpacity(0.5),
                    );
                  }),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _playNext,
                  child: const Icon(Icons.skip_next, size: 16, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _volume = _volume > 0 ? 0.0 : 0.5;
                      _audioPlayer.setVolume(_volume);
                    });
                  },
                  child: Icon(_volume > 0 ? Icons.volume_up : Icons.volume_off, size: 16, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
