import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart' hide PlayerState;

import '../../../core/constants/app_constants.dart';
import '../../../core/storage/preferences_service.dart';
import '../models/player_state.dart';

enum RepeatMode { off, one, all }

enum TrickMode { none, forward, backward }

class PlayerController extends ChangeNotifier {
  PlayerController({required this.player, PreferencesService? preferences})
    : _preferences = preferences ?? PreferencesService();

  final Player player;
  final PreferencesService _preferences;

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  Timer? _reverseTimer;
  bool _reverseSeekInFlight = false;
  Duration _reversePosition = Duration.zero;
  int _reverseGeneration = 0;

  PlayerStatus _status = PlayerStatus.idle;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  double _volume = AppConstants.defaultVolume;
  double _speed = AppConstants.defaultSpeed;

  double _lastNonZeroVolume = AppConstants.defaultVolume;

  bool _initialized = false;

  RepeatMode _repeatMode = RepeatMode.off;
  TrickMode _trickMode = TrickMode.none;
  double _trickSpeed = 1.0;

  String? _currentPath;

  PlayerStatus get status => _status;

  Duration get position => _position;

  Duration get duration => _duration;

  double get volume => _volume;

  double get speed => _speed;

  bool get muted => _volume <= 0.0;

  bool get isPlaying => _status == PlayerStatus.playing;

  bool get isBuffering => _status == PlayerStatus.buffering;

  String? get currentPath => _currentPath;

  RepeatMode get repeatMode => _repeatMode;

  TrickMode get trickMode => _trickMode;

  double get trickSpeed => _trickSpeed;

  List<AudioTrack> get audioTracks {
    return player.state.tracks.audio
        .where((track) => track.id != 'auto' && track.id != 'no')
        .toList(growable: false);
  }

  AudioTrack get selectedAudioTrack => player.state.track.audio;

  PlayerState get state => PlayerState(
    status: _status,
    position: _position,
    duration: _duration,
    volume: _volume,
    speed: _speed,
    muted: muted,
  );

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    final savedVolume = await _preferences.getVolume();

    _volume = savedVolume.clamp(0.0, 1.0).toDouble();

    if (_volume > 0.0) {
      _lastNonZeroVolume = _volume;
    }

    final savedSpeed = await _preferences.getSpeed();

    _speed = savedSpeed.clamp(0.5, 16.0).toDouble();

    final savedRepeat = await _preferences.getRepeatMode();

    _repeatMode = switch (savedRepeat) {
      1 => RepeatMode.one,
      2 => RepeatMode.all,
      _ => RepeatMode.off,
    };

    _subscriptions.add(
      player.stream.position.listen((value) {
        _position = value;

        if (_trickMode == TrickMode.backward) {
          _reversePosition = value;
        }

        notifyListeners();
      }),
    );

    _subscriptions.add(
      player.stream.duration.listen((value) {
        _duration = value;
        notifyListeners();
      }),
    );

    _subscriptions.add(
      player.stream.playing.listen((playing) {
        if (playing) {
          _status = PlayerStatus.playing;
        } else if (_status != PlayerStatus.idle &&
            _status != PlayerStatus.error) {
          _status = PlayerStatus.paused;
        }

        notifyListeners();
      }),
    );

    _subscriptions.add(
      player.stream.buffering.listen((buffering) {
        if (buffering) {
          _status = PlayerStatus.buffering;
        } else if (player.state.playing) {
          _status = PlayerStatus.playing;
        } else if (_status != PlayerStatus.idle) {
          _status = PlayerStatus.paused;
        }

        notifyListeners();
      }),
    );

    _subscriptions.add(
      player.stream.completed.listen((completed) {
        if (completed) {
          _status = PlayerStatus.completed;
          notifyListeners();
        }
      }),
    );

    _subscriptions.add(
      player.stream.volume.listen((volume) {
        _volume = (volume / 100.0).clamp(0.0, 1.0).toDouble();

        if (_volume > 0.0) {
          _lastNonZeroVolume = _volume;
        }

        notifyListeners();
      }),
    );

    _subscriptions.add(
      player.stream.rate.listen((rate) {
        if (_trickMode == TrickMode.none) {
          _speed = rate.clamp(0.5, 16.0).toDouble();
        }

        notifyListeners();
      }),
    );

    _subscriptions.add(
      player.stream.tracks.listen((_) {
        notifyListeners();
      }),
    );

    await player.setVolume(_volume * 100.0);
    await player.setRate(_speed);
    await _applyRepeatMode();

    notifyListeners();
  }

  Future<void> open(String path, {bool resume = false}) async {
    _status = PlayerStatus.loading;
    _currentPath = path;

    notifyListeners();

    try {
      await stopTrickMode();

      await player.open(Media(path), play: false);

      _position = Duration.zero;
      _duration = Duration.zero;

      if (resume) {
        final existingPosition = _position;

        if (existingPosition > Duration.zero) {
          await player.seek(existingPosition);
        }
      }

      _status = PlayerStatus.paused;

      notifyListeners();

      await player.play();
    } catch (_) {
      _status = PlayerStatus.error;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> play() async {
    if (_trickMode == TrickMode.backward) {
      await stopTrickMode();
    }

    await player.play();
  }

  Future<void> pause() async {
    await player.pause();
  }

  Future<void> playPause() async {
    if (_trickMode == TrickMode.backward) {
      await stopTrickMode();
      return;
    }

    await player.playOrPause();
  }

  Future<void> stop() async {
    await stopTrickMode();

    await player.stop();

    _position = Duration.zero;
    _duration = Duration.zero;
    _status = PlayerStatus.idle;
    _currentPath = null;

    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    final target = position < Duration.zero ? Duration.zero : position;

    final boundedTarget = _duration > Duration.zero && target > _duration
        ? _duration
        : target;

    if (_trickMode == TrickMode.backward) {
      _reversePosition = boundedTarget;
    }

    await player.seek(boundedTarget);

    _position = boundedTarget;

    notifyListeners();
  }

  Future<void> seekRelative(int seconds) async {
    await seek(_position + Duration(seconds: seconds));
  }

  Future<void> setVolume(double value) async {
    final next = value.clamp(0.0, 1.0).toDouble();

    if (next > 0.0) {
      _lastNonZeroVolume = next;
    }

    _volume = next;

    await player.setVolume(next * 100.0);
    await _preferences.saveVolume(next);

    notifyListeners();
  }

  Future<void> changeVolumeBy(double amount) async {
    await setVolume(_volume + amount);
  }

  Future<void> toggleMute() async {
    if (muted) {
      final restored = _lastNonZeroVolume > 0.0
          ? _lastNonZeroVolume
          : AppConstants.defaultVolume;

      await setVolume(restored);
      return;
    }

    _lastNonZeroVolume = _volume;

    await setVolume(0.0);
  }

  Future<void> setSpeed(double value) async {
    final next = value.clamp(0.5, 16.0).toDouble();

    await stopTrickMode();

    _speed = next;

    await player.setRate(next);

    if (next <= 2.0) {
      await _preferences.saveSpeed(next);
    }

    notifyListeners();
  }

  Future<void> changeSpeedBy(double amount) async {
    await setSpeed(_speed + amount);
  }

  Future<void> cycleForwardTrickMode() async {
    if (_trickMode == TrickMode.backward) {
      await stopTrickMode();
    }

    final next = switch (_trickMode) {
      TrickMode.none => 2.0,
      TrickMode.forward when _trickSpeed == 2.0 => 4.0,
      TrickMode.forward when _trickSpeed == 4.0 => 16.0,
      TrickMode.forward => 1.0,
      TrickMode.backward => 2.0,
    };

    if (next == 1.0) {
      await stopTrickMode();
      return;
    }

    _trickMode = TrickMode.forward;
    _trickSpeed = next;

    _stopReverseTimer();

    await player.setRate(next);
    await player.play();

    notifyListeners();
  }

  Future<void> cycleBackwardTrickMode() async {
    if (_trickMode == TrickMode.forward) {
      await stopTrickMode();
    }

    final next = switch (_trickMode) {
      TrickMode.none => 2.0,
      TrickMode.backward when _trickSpeed == 2.0 => 4.0,
      TrickMode.backward when _trickSpeed == 4.0 => 16.0,
      TrickMode.backward => 1.0,
      TrickMode.forward => 2.0,
    };

    if (next == 1.0) {
      await stopTrickMode();
      return;
    }

    _trickMode = TrickMode.backward;
    _trickSpeed = next;

    await _startReversePlayback();

    notifyListeners();
  }

  Future<void> _startReversePlayback() async {
    _stopReverseTimer();

    _reversePosition = _position;

    await player.pause();
    await player.setRate(1.0);

    // Reverse playback is implemented as controlled seeks because media_kit's
    // normal playback rate is forward-only. Keep the cadence high enough for
    // smooth motion, while ensuring only one seek can ever be in flight.
    _reverseTimer = Timer.periodic(
      const Duration(milliseconds: 33),
      (_) => _reverseTick(),
    );
  }

  Future<void> _reverseTick() async {
    if (_trickMode != TrickMode.backward ||
        _reverseSeekInFlight ||
        _duration <= Duration.zero) {
      return;
    }

    _reverseSeekInFlight = true;
    final generation = _reverseGeneration;

    try {
      const tickMilliseconds = 33;

      final milliseconds = (_trickSpeed * tickMilliseconds).round();
      final nextMilliseconds =
          _reversePosition.inMilliseconds - milliseconds;

      final target = Duration(
        milliseconds: nextMilliseconds < 0 ? 0 : nextMilliseconds,
      );

      _reversePosition = target;

      await player.seek(target);

      // A seek can complete after the user has switched modes. Do not let
      // that stale operation overwrite the new playback state.
      if (generation != _reverseGeneration ||
          _trickMode != TrickMode.backward) {
        return;
      }

      _position = target;

      if (target <= Duration.zero) {
        _stopReverseTimer();
        await player.pause();
      }

      notifyListeners();
    } catch (_) {
      // Seeking can fail transiently while media is being unloaded or
      // switched. Keep the player alive and let the next tick retry.
    } finally {
      _reverseSeekInFlight = false;
    }
  }

  Future<void> stopTrickMode() async {
    _stopReverseTimer();

    _trickMode = TrickMode.none;
    _trickSpeed = 1.0;

    await player.setRate(_speed);

    notifyListeners();
  }

  void _stopReverseTimer() {
    _reverseGeneration++;
    _reverseTimer?.cancel();
    _reverseTimer = null;
    _reverseSeekInFlight = false;
  }

  Future<void> cycleRepeatMode() async {
    _repeatMode = switch (_repeatMode) {
      RepeatMode.off => RepeatMode.one,
      RepeatMode.one => RepeatMode.all,
      RepeatMode.all => RepeatMode.off,
    };

    await _applyRepeatMode();

    await _preferences.saveRepeatMode(switch (_repeatMode) {
      RepeatMode.off => 0,
      RepeatMode.one => 1,
      RepeatMode.all => 2,
    });

    notifyListeners();
  }

  Future<void> _applyRepeatMode() async {
    final mode = switch (_repeatMode) {
      RepeatMode.off => PlaylistMode.none,
      RepeatMode.one => PlaylistMode.single,
      RepeatMode.all => PlaylistMode.loop,
    };

    await player.setPlaylistMode(mode);
  }

  Future<void> setAudioTrack(AudioTrack track) async {
    await player.setAudioTrack(track);
    notifyListeners();
  }

  @override
  void dispose() {
    _stopReverseTimer();

    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }

    _subscriptions.clear();

    unawaited(player.dispose());

    super.dispose();
  }
}
