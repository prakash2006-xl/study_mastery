import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
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
    final playlist = _isUsingLocal ? _localPlaylist : _assetPlaylist;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Player', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            // Now playing card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Container(
                padding: const EdgeInsets.all(32),
                width: double.infinity,
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isUsingLocal ? Icons.library_music : Icons.radio, 
                        size: 64, 
                        color: theme.colorScheme.primary
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _isUsingLocal ? 'Local Library' : '24/7 Lo-Fi Radio',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      playlist.isNotEmpty ? p.basename(playlist[_currentIndex % playlist.length]) : 'No tracks',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(_isUsingLocal ? Icons.album : Icons.folder, size: 28),
                          onPressed: _toggleSource,
                          tooltip: 'Switch Source',
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.skip_previous, size: 36),
                          onPressed: playlist.isNotEmpty ? () {
                            setState(() {
                              _currentIndex = (_currentIndex - 1 + playlist.length) % playlist.length;
                            });
                            if (_isPlaying) _audioPlayer.play(_getCurrentSource());
                          } : null,
                        ),
                        const SizedBox(width: 16),
                        FloatingActionButton(
                          onPressed: playlist.isNotEmpty ? _togglePlay : null,
                          backgroundColor: theme.colorScheme.primary,
                          child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 36),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.skip_next, size: 36),
                          onPressed: playlist.isNotEmpty ? _playNext : null,
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.file_download, size: 28),
                          onPressed: _importAudio,
                          tooltip: 'Import Local Audio',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.volume_down),
                        Expanded(
                          child: Slider(
                            value: _volume,
                            onChanged: (val) {
                              setState(() => _volume = val);
                              _audioPlayer.setVolume(val);
                            },
                          ),
                        ),
                        const Icon(Icons.volume_up),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Track list
            Expanded(
              child: Card(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: playlist.length,
                  itemBuilder: (context, index) {
                    final track = playlist[index];
                    final isCurrent = index == (_currentIndex % playlist.length);
                    return ListTile(
                      leading: Icon(
                        isCurrent ? Icons.volume_up : Icons.music_note,
                        color: isCurrent ? theme.colorScheme.primary : Colors.grey,
                      ),
                      title: Text(
                        p.basename(track),
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCurrent ? theme.colorScheme.primary : null,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _currentIndex = index;
                        });
                        if (_isPlaying) _audioPlayer.play(_getCurrentSource());
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
