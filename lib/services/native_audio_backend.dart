import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'audio_service.dart';

/// Local assets only: no streaming, accounts, or background playback.
class NativeAudioBackend implements AudioBackend {
  final _music = AudioPlayer();
  final _reels = AudioPlayer();
  final Map<String, Future<AudioPool>> _pools = {};
  String? _track;
  bool _loopPlaying = false;
  Timer? _fade;
  Timer? _reelFade;
  int _musicGeneration = 0;
  int _effectGeneration = 0;
  final Map<String, int> _voices = {};
  final Set<Timer> _effectTimers = {};
  final Map<String, Duration> _durations = {};

  final _context = AudioContext(
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
    android: const AudioContextAndroid(
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
      stayAwake: false,
    ),
  );

  @override
  Future<void> initialize() async {
    // Set once, globally. On iOS every per-player setAudioContext re-applies
    // the AVAudioSession category, which drops out audio that is playing.
    await AudioPlayer.global.setAudioContext(_context);
    await _music.setReleaseMode(ReleaseMode.loop);
    await _reels.setReleaseMode(ReleaseMode.loop);
    await _reels.setSource(AssetSource('audio/sfx/reel_loop.wav'));
    await _reels.setVolume(.36);
    // Warm the sounds needed immediately. Other pools load on first use.
    await Future.wait(
      [
        'click',
        'peg',
        'drop',
        'reel_stop',
        'wheel_tick',
      ].map((name) => _pool('audio/sfx/$name.wav')),
    );
  }

  Future<AudioPool> _pool(String asset) => _pools.putIfAbsent(
    asset,
    () => AudioPool.create(
      source: AssetSource(asset),
      maxPlayers: 3,
      minPlayers: 1,
    ),
  );

  @override
  Future<void> music(String? asset) async {
    if (asset == _track) return;
    final generation = ++_musicGeneration;
    _fade?.cancel();
    await _music.setVolume(0);
    await _music.stop();
    _track = null;
    if (asset == null) return;
    if (generation != _musicGeneration) return;
    await _music.play(AssetSource(asset), volume: 0);
    if (generation != _musicGeneration) {
      await _music.stop();
      return;
    }
    _track = asset;
    var step = 0;
    _fade = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      step++;
      // Background music sits well below gameplay cues.
      unawaited(
        _music.setVolume(.25 * (step / 10).clamp(0, 1)).catchError((
          Object error,
        ) {
          timer.cancel();
        }),
      );
      if (step >= 10) timer.cancel();
    });
  }

  @override
  Future<void> reelLoop(bool playing) async {
    if (_loopPlaying == playing) return;
    _reelFade?.cancel();
    if (!playing) {
      await _reels.setVolume(0);
      // stop() rewinds, so each spin starts at 0 and never reaches the
      // loop seam (the file is longer than any spin).
      await _reels.stop();
    } else {
      await _reels.setVolume(0);
      await _reels.resume();
      var step = 0;
      _reelFade = Timer.periodic(const Duration(milliseconds: 20), (timer) {
        step++;
        unawaited(_reels.setVolume(.28 * (step / 5).clamp(0, 1)).catchError((Object _) {
          timer.cancel();
        }));
        if (step >= 5) timer.cancel();
      });
    }
    _loopPlaying = playing;
  }

  @override
  Future<void> effect(String asset, double volume) async {
    final generation = _effectGeneration;
    if ((_voices[asset] ?? 0) >= 3) return;
    _voices[asset] = (_voices[asset] ?? 0) + 1;
    var scheduled = false;
    try {
      final pool = await _pool(asset);
      final duration = _durations[asset] ??= await _wavDuration(asset);
      if (generation != _effectGeneration) return;
      final stop = await pool.start(volume: volume);
      if (generation != _effectGeneration) {
        await stop();
        return;
      }
      late Timer timer;
      timer = Timer(duration + const Duration(milliseconds: 40), () {
        _effectTimers.remove(timer);
        if (generation == _effectGeneration) {
          _voices[asset] = (_voices[asset] ?? 1) - 1;
          unawaited(stop().catchError((Object error) {}));
        }
      });
      _effectTimers.add(timer);
      scheduled = true;
    } finally {
      if (!scheduled && generation == _effectGeneration) {
        _voices[asset] = (_voices[asset] ?? 1) - 1;
      }
    }
  }

  Future<Duration> _wavDuration(String asset) async {
    final bytes = await rootBundle.load('assets/$asset');
    var offset = 12;
    var byteRate = 88200;
    var dataBytes = 0;
    while (offset + 8 <= bytes.lengthInBytes) {
      final id = String.fromCharCodes(
        bytes.buffer.asUint8List(bytes.offsetInBytes + offset, 4),
      );
      final length = bytes.getUint32(offset + 4, Endian.little);
      if (id == 'fmt ') byteRate = bytes.getUint32(offset + 16, Endian.little);
      if (id == 'data') {
        dataBytes = length;
        break;
      }
      offset += 8 + length + length % 2;
    }
    return Duration(microseconds: (dataBytes / byteRate * 1000000).round());
  }

  @override
  Future<void> silenceEffects() async {
    _effectGeneration++;
    for (final timer in _effectTimers) {
      timer.cancel();
    }
    _effectTimers.clear();
    _voices.clear();
    final pools = _pools.values.toList();
    _pools.clear();
    for (final future in pools) {
      await (await future).dispose();
    }
  }

  @override
  Future<void> dispose() async {
    _fade?.cancel();
    _reelFade?.cancel();
    await silenceEffects();
    await _music.dispose();
    await _reels.dispose();
  }
}

/// iOS: AVAudioPlayer via ios/Runner/AppDelegate.swift (gapless loops,
/// instant starts). Android keeps [NativeAudioBackend].
class IosAudioBackend implements AudioBackend {
  static const _ch = MethodChannel('juwa/audio');

  @override
  Future<void> initialize() => _ch.invokeMethod('initialize');

  @override
  Future<void> music(String? asset) =>
      _ch.invokeMethod('music', {'asset': asset});

  @override
  Future<void> reelLoop(bool playing) =>
      _ch.invokeMethod('reels', {'playing': playing});

  @override
  Future<void> effect(String asset, double volume) =>
      _ch.invokeMethod('effect', {'asset': asset, 'volume': volume});

  @override
  Future<void> silenceEffects() => _ch.invokeMethod('silence');

  @override
  Future<void> dispose() async {
    await music(null);
    await reelLoop(false);
    await silenceEffects();
  }
}
