import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:its_a_videoplayer/features/player/controllers/player_controller.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/window_service.dart';
import '../../core/utils/duration_utils.dart';
import '../../features/ab_loop/controllers/ab_loop_controller.dart';
import '../../features/player/models/player_state.dart';
import 'seek_bar.dart';

class PlayerOverlay extends StatefulWidget {
  const PlayerOverlay({
    super.key,
    required this.controller,
    required this.abLoop,
    required this.onOpen,
    required this.onTogglePlaylist,
    required this.onKeyboardHelp,
    required this.onNext,
    required this.onPrevious,
    required this.onMouseSeek,
    required this.playlistVisible,
    required this.cropModeLabel,
    required this.onCropMode,
  });

  final PlayerController controller;
  final ABLoopController abLoop;

  final VoidCallback onOpen;
  final VoidCallback onTogglePlaylist;
  final VoidCallback onKeyboardHelp;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  final ValueChanged<double> onMouseSeek;

  final bool playlistVisible;

  final String cropModeLabel;
  final VoidCallback onCropMode;

  @override
  State<PlayerOverlay> createState() => _PlayerOverlayState();
}

class _PlayerOverlayState extends State<PlayerOverlay> {
  bool _visible = true;
  bool _audioOpen = false;

  DateTime _lastInteraction = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      opaque: false,
      onHover: (_) => _wake(),
      child: AnimatedBuilder(
        animation: Listenable.merge([widget.controller, widget.abLoop]),
        builder: (context, _) {
          final state = widget.controller.state;

          final showControls = _visible || state.status != PlayerStatus.playing;

          final duration = state.duration;
          final position = state.position;

          final max = duration.inMilliseconds
              .toDouble()
              .clamp(1.0, double.infinity)
              .toDouble();

          final value = position.inMilliseconds
              .toDouble()
              .clamp(0.0, max)
              .toDouble();

          return Stack(
            children: [
              if (showControls)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _controls(value, max, position, duration),
                ),
              if (_audioOpen) _audioMenu(),
            ],
          );
        },
      ),
    );
  }

  void _wake() {
    _lastInteraction = DateTime.now();

    if (!_visible && mounted) {
      setState(() {
        _visible = true;
      });
    }

    _scheduleHide();
  }

  void _scheduleHide() {
    Future<void>.delayed(
      const Duration(seconds: AppConstants.controlHideDelaySeconds),
      () {
        if (!mounted || !widget.controller.isPlaying) {
          return;
        }

        if (DateTime.now().difference(_lastInteraction).inSeconds >=
            AppConstants.controlHideDelaySeconds) {
          setState(() {
            _visible = false;
          });
        }
      },
    );
  }

  Widget _controls(
    double value,
    double max,
    Duration position,
    Duration duration,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final horizontalPadding = width < 520
            ? 8.0
            : width < 900
            ? 12.0
            : 14.0;

        final verticalTop = width < 520 ? 18.0 : 22.0;
        final verticalBottom = width < 520 ? 6.0 : 10.0;

        return Container(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            verticalTop,
            horizontalPadding,
            verticalBottom,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xEE000000)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SeekBar(
                value: value,
                max: max,
                a: widget.abLoop.a,
                b: widget.abLoop.b,
                onChanged: (next) {
                  widget.controller.seek(Duration(milliseconds: next.round()));
                },
                onWheel: widget.onMouseSeek,
              ),
              const SizedBox(height: 2),
              _primaryControls(position, duration, width),
              const SizedBox(height: 2),
              _secondaryControls(width),
            ],
          ),
        );
      },
    );
  }

  Widget _primaryControls(Duration position, Duration duration, double width) {
    final compact = width < 520;

    return Row(
      children: [
        _button(Icons.skip_previous_rounded, 'Previous', widget.onPrevious),
        _button(
          widget.controller.isPlaying
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          widget.controller.isPlaying ? 'Pause' : 'Play',
          widget.controller.playPause,
        ),
        _button(Icons.skip_next_rounded, 'Next', widget.onNext),
        const SizedBox(width: 4),
        _volume(
          widget.controller.volume,
          widget.controller.muted,
          compact,
          width,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${formatDuration(position)} / ${formatDuration(duration)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: compact ? 10 : 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _secondaryControls(double width) {
    final compact = width < 520;

    final children = <Widget>[
      _trickControls(),
      _abGroup(),
      _audioButton(),
      _speedMenu(),
      _repeatButton(),
      _button(Icons.crop_rounded, widget.cropModeLabel, widget.onCropMode),
      _button(
        Icons.keyboard_rounded,
        'Keyboard controls',
        widget.onKeyboardHelp,
      ),
      _button(
        widget.playlistVisible
            ? Icons.queue_music_rounded
            : Icons.queue_music_outlined,
        widget.playlistVisible ? 'Hide playlist' : 'Show playlist',
        widget.onTogglePlaylist,
      ),
      _button(Icons.folder_open_rounded, 'Open videos', widget.onOpen),
      _button(
        Icons.fullscreen_rounded,
        'Fullscreen',
        WindowService().toggleFullscreen,
      ),
    ];

    /*
     * Keep the same controls.
     *
     * Wide:
     *   Everything stays on one row, right aligned as before.
     *
     * Medium:
     *   The same controls wrap when required.
     *
     * Compact:
     *   The same compact set remains visible.
     *
     * There is deliberately NO overflow / three-dot menu here.
     */
    if (compact) {
      return _compactSecondaryControls();
    }

    return _responsiveSecondaryRow(
      children,
      alignment: width < 800 ? WrapAlignment.start : WrapAlignment.center,
    );
  }

  Widget _compactSecondaryControls() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 2,
        runSpacing: 2,
        children: [
          _trickControls(),
          _audioButton(),
          _speedMenu(),
          _repeatButton(),
          _button(
            widget.playlistVisible
                ? Icons.queue_music_rounded
                : Icons.queue_music_outlined,
            widget.playlistVisible ? 'Hide playlist' : 'Show playlist',
            widget.onTogglePlaylist,
          ),
          _button(
            Icons.fullscreen_rounded,
            'Fullscreen',
            WindowService().toggleFullscreen,
          ),
        ],
      ),
    );
  }

  Widget _responsiveSecondaryRow(
    List<Widget> children, {
    required WrapAlignment alignment,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: alignment,
          runAlignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 2,
          runSpacing: 2,
          children: children,
        ),
      ),
    );
  }

  Widget _volume(
    double volume,
    bool muted,
    bool compact,
    double availableWidth,
  ) {
    return Listener(
      onPointerSignal: (signal) {
        if (signal is PointerScrollEvent) {
          widget.controller.changeVolumeBy(
            signal.scrollDelta.dy < 0
                ? AppConstants.volumeWheelStep
                : -AppConstants.volumeWheelStep,
          );
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _button(
            muted || volume <= 0
                ? Icons.volume_off_rounded
                : Icons.volume_up_rounded,
            'Mute',
            widget.controller.toggleMute,
          ),
          if (!compact)
            SizedBox(
              width: availableWidth * 0.08,
              child: SliderTheme(
                data: const SliderThemeData(trackHeight: 3),
                child: Slider(
                  value: volume.clamp(0.0, 1.0).toDouble(),
                  min: 0,
                  max: 1,
                  onChanged: widget.controller.setVolume,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _trickControls() {
    final mode = widget.controller.trickMode;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _trickButton(
          icon: Icons.fast_rewind_rounded,
          tooltip: 'Rewind',
          mode: TrickMode.backward,
          onPressed: widget.controller.cycleBackwardTrickMode,
        ),
        if (mode == TrickMode.backward) _trickSpeedLabel(),
        _trickButton(
          icon: Icons.fast_forward_rounded,
          tooltip: 'Fast forward',
          mode: TrickMode.forward,
          onPressed: widget.controller.cycleForwardTrickMode,
        ),
        if (mode == TrickMode.forward) _trickSpeedLabel(),
      ],
    );
  }

  Widget _trickButton({
    required IconData icon,
    required String tooltip,
    required TrickMode mode,
    required Future<void> Function() onPressed,
  }) {
    final active = widget.controller.trickMode == mode;

    return IconButton(
      tooltip: tooltip,
      onPressed: () async {
        await onPressed();

        if (mounted) {
          setState(() {});
        }
      },
      icon: Icon(icon),
      color: active ? AppColors.success : AppColors.textPrimary,
      splashRadius: 19,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _trickSpeedLabel() {
    return Padding(
      padding: const EdgeInsets.only(left: 1, right: 3),
      child: Text(
        '${widget.controller.trickSpeed.round()}x',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _speedMenu() {
    return PopupMenuButton<double>(
      tooltip: 'Playback speed',
      color: AppColors.surfaceElevated,
      onSelected: widget.controller.setSpeed,
      itemBuilder: (_) => const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
          .map(
            (speed) =>
                PopupMenuItem<double>(value: speed, child: Text('${speed}x')),
          )
          .toList(),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          '${widget.controller.speed.toStringAsFixed(2)}x',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
        ),
      ),
    );
  }

  Widget _audioButton() {
    final count = widget.controller.audioTracks.length;

    return IconButton(
      tooltip: count > 1 ? 'Audio tracks' : 'Audio',
      onPressed: count > 1
          ? () {
              setState(() {
                _audioOpen = !_audioOpen;
              });
            }
          : null,
      icon: const Icon(Icons.audiotrack_rounded),
      color: count > 1 ? AppColors.textPrimary : AppColors.textMuted,
      splashRadius: 19,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _audioMenu() {
    final tracks = widget.controller.audioTracks;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 80,
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Material(
            color: Colors.black.withOpacity(0.86),
            borderRadius: BorderRadius.circular(9),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.35,
                maxHeight: MediaQuery.sizeOf(context).height * 0.4,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < tracks.length; index++)
                      _audioTrackTile(tracks[index], index),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _audioTrackTile(dynamic track, int index) {
    final selected = track.id == widget.controller.selectedAudioTrack.id;

    return ListTile(
      dense: true,
      leading: Icon(
        selected ? Icons.check_circle_rounded : Icons.audiotrack_rounded,
        color: selected ? AppColors.success : AppColors.textSecondary,
        size: 19,
      ),
      title: Text(
        track.title?.isNotEmpty == true ? track.title! : 'Audio ${index + 1}',
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
      ),
      subtitle: track.language == null
          ? null
          : Text(
              track.language!,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
            ),
      onTap: () async {
        await widget.controller.setAudioTrack(track);

        if (mounted) {
          setState(() {
            _audioOpen = false;
          });
        }
      },
    );
  }

  Widget _abGroup() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _abButton('A', widget.abLoop.aSet, widget.abLoop.setA),
          _abButton('B', widget.abLoop.bSet, widget.abLoop.setB),
          IconButton(
            tooltip: 'Clear A-B loop',
            onPressed: widget.abLoop.clear,
            icon: const Icon(Icons.close_rounded, size: 16),
            color: AppColors.textSecondary,
            splashRadius: 17,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _abButton(String text, bool active, VoidCallback onPressed) {
    return Material(
      color: active ? AppColors.success : Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(7),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Text(
            text,
            style: TextStyle(
              color: active ? Colors.white : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _repeatButton() {
    final mode = widget.controller.repeatMode;

    final tooltip = switch (mode) {
      RepeatMode.off => 'Repeat: Off',
      RepeatMode.one => 'Repeat: Current video',
      RepeatMode.all => 'Repeat: Playlist',
    };

    final icon = mode == RepeatMode.one
        ? Icons.repeat_one_rounded
        : Icons.repeat_rounded;

    return IconButton(
      tooltip: tooltip,
      onPressed: widget.controller.cycleRepeatMode,
      icon: Icon(icon),
      color: mode == RepeatMode.off ? AppColors.textPrimary : AppColors.success,
      splashRadius: 19,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _button(IconData icon, String tooltip, VoidCallback onPressed) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      color: AppColors.textPrimary,
      splashRadius: 19,
      visualDensity: VisualDensity.compact,
    );
  }
}
