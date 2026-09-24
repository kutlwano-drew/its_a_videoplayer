import 'package:flutter/foundation.dart';

enum PlayerStatus {
  idle,
  loading,
  playing,
  paused,
  buffering,
  completed,
  error,
}

@immutable
class PlayerState {
  const PlayerState({
    required this.status,
    required this.position,
    required this.duration,
    required this.volume,
    required this.speed,
    required this.muted,
  });

  final PlayerStatus status;
  final Duration position;
  final Duration duration;
  final double volume;
  final double speed;
  final bool muted;

  bool get isPlaying => status == PlayerStatus.playing;

  bool get isPaused => status == PlayerStatus.paused;

  bool get isBuffering => status == PlayerStatus.buffering;

  bool get hasDuration => duration > Duration.zero;

  double get progress {
    if (duration <= Duration.zero) {
      return 0.0;
    }

    return (position.inMicroseconds / duration.inMicroseconds)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  PlayerState copyWith({
    PlayerStatus? status,
    Duration? position,
    Duration? duration,
    double? volume,
    double? speed,
    bool? muted,
  }) {
    return PlayerState(
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
      muted: muted ?? this.muted,
    );
  }
}
