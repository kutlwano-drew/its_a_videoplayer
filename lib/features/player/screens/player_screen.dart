import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/file_service.dart';
import '../../../core/services/window_service.dart';
import '../../../core/storage/playlist_store.dart';
import '../../../core/utils/file_utils.dart';
import '../../../features/ab_loop/controllers/ab_loop_controller.dart';
import '../../../features/playlist/controllers/playlist_controller.dart';
import '../../../features/shortcuts/controllers/shortcut_controller.dart';
import '../../../widgets/player/keyboard_help_dialog.dart';
import '../../../widgets/player/player_overlay.dart';
import '../../../widgets/playlist/playlist_panel.dart';
import '../../../widgets/states/no_video_state.dart';
import '../controllers/player_controller.dart';

enum CropMode { contain, cover, fill }

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player mediaPlayer;
  late final PlayerController playerController;
  late final PlaylistController playlist;
  late final ABLoopController abLoop;
  late final ShortcutController shortcuts;
  late final VideoController video;
  late final FocusNode _focusNode;

  late final StreamSubscription<bool> _completedSub;
  late final VoidCallback _playerListener;

  bool playlistVisible = false;
  bool playlistFullScreen = false;
  bool hasVideo = false;

  bool miniVideoVisible = true;
  bool metadataVisible = false;

  CropMode cropMode = CropMode.contain;

  Offset miniVideoOffset = const Offset(24, 24);

  Offset metadataOffset = const Offset(32, 32);

  bool _continuePromptVisible = false;
  String? _continuePath;
  Duration _continuePosition = Duration.zero;

  Timer? _continueTimer;

  @override
  void initState() {
    super.initState();

    mediaPlayer = Player();

    playerController = PlayerController(player: mediaPlayer);

    playlist = PlaylistController();

    abLoop = ABLoopController(playerController);

    shortcuts = ShortcutController();

    video = VideoController(mediaPlayer);

    _focusNode = FocusNode(debugLabel: 'video-player-focus')..requestFocus();

    _completedSub = mediaPlayer.stream.completed.listen(_onCompleted);

    _playerListener = _savePositionIntoPlaylist;

    playerController.addListener(_playerListener);

    _initialize();
  }

  Future<void> _initialize() async {
    await playerController.initialize();

    await playlist.restoreLast();

    if (!mounted || playlist.items.isEmpty) {
      return;
    }

    final currentIndex = playlist.currentIndex;

    if (currentIndex < 0 || currentIndex >= playlist.items.length) {
      return;
    }

    final path = playlist.items[currentIndex].path;

    final saved = playlist.positionFor(path);

    if (saved <
        const Duration(seconds: AppConstants.continueThresholdSeconds)) {
      return;
    }

    await _showStartupContinue(
      playlist.buildSnapshot(currentPosition: saved),
      path,
      saved,
    );
  }

  Future<void> _openFiles() async {
    final files = await FileService().pickVideos();

    if (files.isEmpty) {
      return;
    }

    await playlist.addFiles(files);

    final first = playlist.indexOf(files.first.path);

    if (first >= 0) {
      await _playIndex(first);
    }
  }

  Future<void> _playIndex(int index, {bool offerContinue = true}) async {
    if (index < 0 || index >= playlist.items.length) {
      return;
    }

    final path = playlist.items[index].path;

    final saved = playlist.positionFor(path);

    try {
      await playerController.open(path, resume: false);

      playlist.setCurrent(index);

      if (!mounted) {
        return;
      }

      setState(() {
        hasVideo = true;
        miniVideoVisible = true;
      });

      if (offerContinue &&
          saved >=
              const Duration(seconds: AppConstants.continueThresholdSeconds)) {
        _showContinuePrompt(path, saved);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to play ${fileName(path)}.')),
        );
      }
    }
  }

  Future<void> _showStartupContinue(
    PlaylistSnapshot snapshot,
    String path,
    Duration position,
  ) async {
    final result = await _showContinueChoice(path, position);

    if (!mounted) {
      return;
    }

    await playlist.loadSnapshot(snapshot);

    final index = playlist.indexOf(path);

    if (index < 0) {
      return;
    }

    if (result) {
      await _playIndex(index, offerContinue: false);

      await playerController.seek(position);
    } else {
      playlist.setCurrent(index);
      playlist.setPosition(path, position);

      setState(() {
        playlistVisible = true;
      });
    }
  }

  Future<bool> _showContinueChoice(String path, Duration position) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.70),
      builder: (_) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.86),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 430,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      color: AppColors.textPrimary,
                      size: 21,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Continue playback?',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  fileName(path),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Resume from ${_formatPosition(position)}?',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('No'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Yes'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return result ?? false;
  }

  void _showContinuePrompt(String path, Duration position) {
    _continueTimer?.cancel();

    setState(() {
      _continuePromptVisible = true;
      _continuePath = path;
      _continuePosition = position;
    });

    _continueTimer = Timer(
      const Duration(seconds: AppConstants.continuePromptSeconds),
      _dismissContinuePrompt,
    );
  }

  void _dismissContinuePrompt() {
    if (!mounted) {
      return;
    }

    setState(() {
      _continuePromptVisible = false;
      _continuePath = null;
    });
  }

  Future<void> _continuePlayback() async {
    final path = _continuePath;

    if (path == null) {
      return;
    }

    await playerController.seek(_continuePosition);

    _dismissContinuePrompt();
  }

  Future<void> _startOver() async {
    final path = _continuePath;

    if (path == null) {
      return;
    }

    playlist.setPosition(path, Duration.zero);

    await playerController.seek(Duration.zero);

    _dismissContinuePrompt();
  }

  Future<void> _onCompleted(bool completed) async {
    if (!completed || playlist.items.isEmpty) {
      return;
    }

    if (playerController.repeatMode == RepeatMode.one) {
      final current = playlist.currentIndex;

      if (current >= 0) {
        await _playIndex(current, offerContinue: false);
      }

      return;
    }

    final next = playlist.nextIndex(
      wrap: playerController.repeatMode == RepeatMode.all,
    );

    if (next >= 0) {
      await _playIndex(next, offerContinue: false);
    }
  }

  Future<void> _next() async {
    final next = playlist.nextIndex(
      wrap: playerController.repeatMode == RepeatMode.all,
    );

    if (next >= 0) {
      await _playIndex(next, offerContinue: false);
    }
  }

  Future<void> _previous() async {
    if (playerController.position.inSeconds > 3) {
      await playerController.seek(Duration.zero);
      return;
    }

    final previous = playlist.previousIndex(
      wrap: playerController.repeatMode == RepeatMode.all,
    );

    if (previous >= 0) {
      await _playIndex(previous, offerContinue: false);
    }
  }

  void _savePositionIntoPlaylist() {
    final path = playerController.currentPath;

    if (path != null && playerController.position > Duration.zero) {
      playlist.setPosition(path, playerController.position);
    }
  }

  Future<void> _savePlaylist() async {
    final uri = await playlist.saveToFile(
      currentPosition: playerController.position,
    );

    if (uri != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Playlist saved.')));
    }
  }

  Future<void> _loadPlaylist() async {
    final snapshot = await playlist.loadFromFile();

    if (!mounted || snapshot == null) {
      return;
    }

    setState(() {
      playlistVisible = true;
    });

    if (snapshot.currentPath != null) {
      final index = playlist.indexOf(snapshot.currentPath!);

      if (index >= 0) {
        await _playIndex(index, offerContinue: false);

        final seconds =
            snapshot.itemPositions[snapshot.currentPath!] ??
            snapshot.playlistPositionSeconds;

        if (seconds > 0) {
          await playerController.seek(
            Duration(milliseconds: (seconds * 1000).round()),
          );
        }
      }
    } else if (snapshot.currentIndex >= 0 &&
        snapshot.currentIndex < playlist.items.length) {
      await _playIndex(snapshot.currentIndex, offerContinue: false);
    }
  }

  void _cycleCropMode() {
    setState(() {
      cropMode = CropMode.values[(cropMode.index + 1) % CropMode.values.length];
    });
  }

  String get _cropLabel => switch (cropMode) {
    CropMode.contain => 'Fit: Contain',
    CropMode.cover => 'Fit: Crop',
    CropMode.fill => 'Fit: Stretch',
  };

  Future<void> _handleKey(KeyEvent event) async {
    final action = shortcuts.actionForEvent(event);

    if (action == null || event is! KeyDownEvent) {
      return;
    }

    switch (action) {
      case 'Play / Pause':
        await playerController.playPause();
        break;

      case 'Stop':
        await playerController.stop();
        break;

      case 'Fullscreen':
        await WindowService().toggleFullscreen();
        break;

      case 'Exit Fullscreen':
        if (await windowManager.isFullScreen()) {
          await windowManager.setFullScreen(false);
        }
        break;

      case 'Mute':
        await playerController.toggleMute();
        break;

      case 'Seek Backward 10s':
        await playerController.seekRelative(-10);
        break;

      case 'Seek Forward 10s':
        await playerController.seekRelative(10);
        break;

      case 'Seek Backward 5m':
        await playerController.seekRelative(-300);
        break;

      case 'Seek Forward 5m':
        await playerController.seekRelative(300);
        break;

      case 'Seek Backward 1m':
        await playerController.seekRelative(-60);
        break;

      case 'Seek Forward 1m':
        await playerController.seekRelative(60);
        break;

      case 'Seek Backward 3s':
        await playerController.seekRelative(-3);
        break;

      case 'Seek Forward 3s':
        await playerController.seekRelative(3);
        break;

      case 'Volume Up':
        await playerController.changeVolumeBy(0.10);
        break;

      case 'Volume Down':
        await playerController.changeVolumeBy(-0.10);
        break;

      case 'Volume Up 5%':
        await playerController.changeVolumeBy(0.05);
        break;

      case 'Volume Down 5%':
        await playerController.changeVolumeBy(-0.05);
        break;

      case 'Faster':
        await playerController.changeSpeedBy(0.25);
        break;

      case 'Slower':
        await playerController.changeSpeedBy(-0.25);
        break;

      case 'Normal Speed':
        await playerController.setSpeed(1.0);
        break;

      case 'Fast Forward':
        await playerController.cycleForwardTrickMode();
        break;

      case 'Rewind':
        await playerController.cycleBackwardTrickMode();
        break;

      case 'Previous Video':
        await _previous();
        break;

      case 'Next Video':
        await _next();
        break;

      case 'Repeat Mode':
        await playerController.cycleRepeatMode();
        break;

      case 'Audio Track':
        await _showAudioTrackDialog();
        break;

      case 'Crop Mode':
        _cycleCropMode();
        break;

      case 'Set A':
        abLoop.setA();
        break;

      case 'Set B':
        abLoop.setB();
        break;

      case 'Clear A-B':
        abLoop.clear();
        break;

      case 'Open File':
        await _openFiles();
        break;

      case 'Toggle Playlist':
        setState(() {
          playlistVisible = !playlistVisible;
        });
        break;

      case 'Jump To Start':
        await playerController.seek(Duration.zero);
        break;

      case 'Jump To End':
        if (playerController.duration > Duration.zero) {
          await playerController.seek(playerController.duration);
        }
        break;
    }
  }

  Future<void> _showAudioTrackDialog() async {
    final tracks = playerController.audioTracks;

    if (tracks.length < 2) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Audio track',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: SizedBox(
          width: 360,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: tracks.length,
            itemBuilder: (_, index) {
              final track = tracks[index];

              final selected =
                  track.id == playerController.selectedAudioTrack.id;

              return ListTile(
                leading: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.audiotrack_rounded,
                  color: selected ? AppColors.success : AppColors.textSecondary,
                ),
                title: Text(
                  track.title?.isNotEmpty == true
                      ? track.title!
                      : 'Audio ${index + 1}',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: track.language == null
                    ? null
                    : Text(
                        track.language!,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                onTap: () async {
                  await playerController.setAudioTrack(track);

                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showVideoContextMenu(Offset position) async {
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      color: AppColors.surfaceElevated,
      items: const [
        PopupMenuItem(value: 'play', child: Text('Play / Pause')),
        PopupMenuItem(value: 'open', child: Text('Open videos')),
        PopupMenuItem(value: 'playlist', child: Text('Playlist')),
        PopupMenuItem(value: 'audio', child: Text('Audio track')),
        PopupMenuItem(value: 'crop', child: Text('Crop / fit mode')),
        PopupMenuItem(value: 'repeat', child: Text('Repeat mode')),
        PopupMenuDivider(),
        PopupMenuItem(value: 'details', child: Text('Video details')),
        PopupMenuItem(value: 'fullscreen', child: Text('Fullscreen')),
      ],
    );

    switch (action) {
      case 'play':
        await playerController.playPause();
        break;

      case 'open':
        await _openFiles();
        break;

      case 'playlist':
        setState(() {
          playlistVisible = !playlistVisible;
        });
        break;

      case 'audio':
        await _showAudioTrackDialog();
        break;

      case 'crop':
        _cycleCropMode();
        break;

      case 'repeat':
        await playerController.cycleRepeatMode();
        break;

      case 'details':
        setState(() {
          metadataVisible = true;
        });
        break;

      case 'fullscreen':
        await WindowService().toggleFullscreen();
        break;
    }
  }

  Future<void> _revealFile() async {
    final path = playerController.currentPath;

    if (path == null) {
      return;
    }

    await revealFileInExplorer(path);
  }

  Widget _videoView({bool mini = false}) {
    final fit = switch (cropMode) {
      CropMode.contain => BoxFit.contain,
      CropMode.cover => BoxFit.cover,
      CropMode.fill => BoxFit.fill,
    };

    return Container(
      color: AppColors.videoBackground,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasVideo)
            GestureDetector(
              onDoubleTap: WindowService().toggleFullscreen,
              onSecondaryTapUp: (details) =>
                  _showVideoContextMenu(details.globalPosition),
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerSignal: (signal) {
                  if (signal is PointerScrollEvent) {
                    playerController.changeVolumeBy(
                      signal.scrollDelta.dy < 0 ? 0.05 : -0.05,
                    );
                  }
                },
                child: Video(
                  controller: video,
                  fit: fit,
                  controls: NoVideoControls,
                ),
              ),
            )
          else
            NoVideoState(onOpen: _openFiles),
          if (hasVideo)
            PlayerOverlay(
              controller: playerController,
              abLoop: abLoop,
              onOpen: _openFiles,
              onTogglePlaylist: () {
                setState(() {
                  playlistVisible = !playlistVisible;
                });
              },
              onKeyboardHelp: () => showKeyboardHelpDialog(context),
              onNext: _next,
              onPrevious: _previous,
              onMouseSeek: (delta) =>
                  playerController.seekRelative(delta.round()),
              playlistVisible: playlistVisible,
              cropModeLabel: _cropLabel,
              onCropMode: _cycleCropMode,
            ),
          if (mini)
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Material(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(18),
                    child: IconButton(
                      tooltip: 'Maximize video',
                      onPressed: () {
                        setState(() {
                          playlistFullScreen = false;
                        });
                      },
                      icon: const Icon(
                        Icons.open_in_full_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(18),
                    child: IconButton(
                      tooltip: 'Close video',
                      onPressed: () {
                        setState(() {
                          miniVideoVisible = false;
                        });
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _fullPlaylistView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        final miniWidth = (size.width * 0.32).clamp(260.0, 400.0).toDouble();

        final miniHeight = miniWidth * 0.6;

        final maxX = (size.width - miniWidth - 8).clamp(8.0, double.infinity);

        final maxY = (size.height - miniHeight - 8).clamp(8.0, double.infinity);

        final offset = Offset(
          miniVideoOffset.dx.clamp(8.0, maxX),
          miniVideoOffset.dy.clamp(8.0, maxY),
        );

        return Stack(
          children: [
            Positioned.fill(
              child: PlaylistPanel(
                controller: playlist,
                onClose: () {
                  setState(() {
                    playlistFullScreen = false;
                  });
                },
                onPlay: _playIndex,
                onOpen: _openFiles,
                onSave: _savePlaylist,
                onLoad: _loadPlaylist,
                fullScreen: true,
                onToggleFullScreen: () {
                  setState(() {
                    playlistFullScreen = false;
                  });
                },
              ),
            ),
            if (hasVideo && miniVideoVisible)
              Positioned(
                left: offset.dx,
                top: offset.dy,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      miniVideoOffset = Offset(
                        (miniVideoOffset.dx + details.delta.dx).clamp(
                          8.0,
                          maxX,
                        ),
                        (miniVideoOffset.dy + details.delta.dy).clamp(
                          8.0,
                          maxY,
                        ),
                      );
                    });
                  },
                  child: SizedBox(
                    width: miniWidth,
                    height: miniHeight,
                    child: _videoView(mini: true),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _metadataOverlay() {
    final path = playerController.currentPath;

    if (path == null) {
      return const SizedBox.shrink();
    }

    final file = File(path);

    final stat = file.existsSync() ? file.statSync() : null;

    final size = stat == null ? 'Unavailable' : _formatBytes(stat.size);

    final modified = stat == null
        ? 'Unavailable'
        : stat.modified.toLocal().toString();

    final params = mediaPlayer.state.videoParams;

    final resolution = params.dw != null && params.dh != null
        ? '${params.dw} × ${params.dh}'
        : 'Unavailable';

    final audio = playerController.audioTracks.isEmpty
        ? 'No selectable track'
        : '${playerController.audioTracks.length} track${playerController.audioTracks.length == 1 ? '' : 's'}';

    return Positioned(
      left: metadataOffset.dx,
      top: metadataOffset.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            metadataOffset += details.delta;
          });
        },
        child: Material(
          color: Colors.black.withOpacity(0.78),
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 9),
                      const Expanded(
                        child: Text(
                          'Video details',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            metadataVisible = false;
                          });
                        },
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                _meta(Icons.movie_outlined, 'Title', fileName(path)),
                _meta(
                  Icons.schedule_rounded,
                  'Duration',
                  _formatPosition(playerController.duration),
                ),
                _meta(Icons.aspect_ratio_rounded, 'Resolution', resolution),
                _meta(Icons.audiotrack_rounded, 'Audio', audio),
                _meta(Icons.sd_storage_outlined, 'File size', size),
                _meta(Icons.update_rounded, 'Modified', modified),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.folder_outlined,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'File path',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Show in folder',
                        onPressed: _revealFile,
                        icon: const Icon(Icons.folder_open_rounded),
                        color: AppColors.textPrimary,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(42, 0, 14, 14),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      path,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String title, String value) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: AppColors.textSecondary, size: 18),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
      ),
      subtitle: Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatPosition(Duration value) {
    final hours = value.inHours;

    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');

    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');

    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (_, event) {
        _handleKey(event);

        return KeyEventResult.handled;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            Positioned.fill(
              child: playlistFullScreen
                  ? _fullPlaylistView()
                  : Row(
                      children: [
                        Expanded(child: _videoView()),
                        if (playlistVisible)
                          SizedBox(
                            width: AppConstants.playlistWidth,
                            child: PlaylistPanel(
                              controller: playlist,
                              onClose: () {
                                setState(() {
                                  playlistVisible = false;
                                });
                              },
                              onPlay: _playIndex,
                              onOpen: _openFiles,
                              onSave: _savePlaylist,
                              onLoad: _loadPlaylist,
                              fullScreen: false,
                              onToggleFullScreen: () {
                                setState(() {
                                  playlistFullScreen = true;
                                });
                              },
                            ),
                          ),
                      ],
                    ),
            ),
            if (_continuePromptVisible)
              Positioned(
                left: 18,
                right: 18,
                bottom: 94,
                child: _continuePrompt(),
              ),
            if (metadataVisible) _metadataOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _continuePrompt() {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 470),
        padding: const EdgeInsets.fromLTRB(16, 13, 10, 13),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.78),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.history_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Continue ${_continuePath == null ? 'video' : fileName(_continuePath!)} from ${_formatPosition(_continuePosition)}?',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                ),
              ),
            ),
            TextButton(onPressed: _startOver, child: const Text('No')),
            FilledButton(
              onPressed: _continuePlayback,
              child: const Text('Yes'),
            ),
            IconButton(
              onPressed: _dismissContinuePrompt,
              icon: const Icon(Icons.close_rounded),
              color: AppColors.textSecondary,
              splashRadius: 18,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _continueTimer?.cancel();

    _completedSub.cancel();

    playerController.removeListener(_playerListener);

    unawaited(
      playlist.persistSavedFile(currentPosition: playerController.position),
    );

    _focusNode.dispose();
    shortcuts.dispose();
    playlist.dispose();
    abLoop.dispose();
    playerController.dispose();

    super.dispose();
  }
}
