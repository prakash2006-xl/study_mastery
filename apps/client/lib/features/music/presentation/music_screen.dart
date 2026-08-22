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

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isShuffle = false;
  int _repeatMode = 1; // 0: None, 1: All, 2: One

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    _audioPlayer.setVolume(_volume);

    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (_repeatMode == 2) {
        if (_isPlaying) _audioPlayer.play(_getCurrentSource());
      } else if (_repeatMode == 1 || _isShuffle) {
        _playNext();
      } else {
        // None: Stop if we reach the end
        final listLength = (_isUsingLocal && _localPlaylist.isNotEmpty) ? _localPlaylist.length : _assetPlaylist.length;
        if (_currentIndex == listLength - 1) {
          setState(() => _isPlaying = false);
        } else {
          _playNext();
        }
      }
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
    if (_isShuffle && listLength > 1) {
      int nextIndex;
      do {
        nextIndex = DateTime.now().millisecondsSinceEpoch % listLength;
      } while (nextIndex == _currentIndex);
      _currentIndex = nextIndex;
    } else {
      _currentIndex = (_currentIndex + 1) % listLength;
    }
    
    if (_isPlaying) {
      await _audioPlayer.play(_getCurrentSource());
    }
    setState(() {});
  }

  void _playPrevious() async {
    final listLength = (_isUsingLocal && _localPlaylist.isNotEmpty) ? _localPlaylist.length : _assetPlaylist.length;
    _currentIndex = (_currentIndex - 1 + listLength) % listLength;
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Expanded(
                          child: Slider(
                            value: _position.inSeconds.toDouble(),
                            min: 0,
                            max: _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 1.0,
                            onChanged: (val) {
                              _audioPlayer.seek(Duration(seconds: val.toInt()));
                            },
                          ),
                        ),
                        Text(
                          '${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.shuffle, 
                            color: _isShuffle ? theme.colorScheme.primary : Colors.grey,
                            size: 24,
                          ),
                          onPressed: () => setState(() => _isShuffle = !_isShuffle),
                          tooltip: 'Shuffle',
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.skip_previous, size: 36),
                          onPressed: playlist.isNotEmpty ? _playPrevious : null,
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
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            _repeatMode == 2 ? Icons.repeat_one : Icons.repeat,
                            color: _repeatMode == 0 ? Colors.grey : theme.colorScheme.primary,
                            size: 24,
                          ),
                          onPressed: () {
                            setState(() {
                              _repeatMode = (_repeatMode + 1) % 3;
                            });
                          },
                          tooltip: 'Repeat Mode',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(_isUsingLocal ? Icons.album : Icons.folder, size: 24),
                          onPressed: _toggleSource,
                          tooltip: 'Switch Source',
                        ),
                        IconButton(
                          icon: const Icon(Icons.file_download, size: 24),
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
