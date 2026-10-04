import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/widgets.dart';
import 'settings_service.dart';
import 'native_audio_backend.dart';

enum AudioScene { lobby, fortune, fish, vampire, wheel, plinko }

enum GameSound { click, drop, peg, reelStop, wheelTick, win, bigWin, error }

const soundFiles = <GameSound, String>{
  GameSound.click: 'click',
  GameSound.drop: 'drop',
  GameSound.peg: 'peg',
  GameSound.reelStop: 'reel_stop',
  GameSound.wheelTick: 'wheel_tick',
  GameSound.win: 'win',
  GameSound.bigWin: 'big_win',
  GameSound.error: 'error',
};

abstract class AudioBackend {
  Future<void> initialize();
  Future<void> music(String? asset);
  Future<void> reelLoop(bool playing);
  Future<void> effect(String asset, double volume);
  Future<void> silenceEffects();
  Future<void> dispose();
}

/// Owns the mix. Games emit events; they never create native audio players.
class AudioService with WidgetsBindingObserver {
  AudioService({AudioBackend? backend, SettingsService? settings})
    : _backend = backend,
      _settings = settings ?? SettingsService.instance;
  static final instance = AudioService();
  AudioBackend? _backend;
  final SettingsService _settings;
  final Map<Object, AudioScene> _scenes = {};
  final Set<Object> _reels = {};
  final Map<GameSound, DateTime> _lastEffect = {};
  bool _ready = false;
  bool _foreground = true;
  bool _disposed = false;
  int _revision = 0;
  Future<void> _queue = Future.value();
  String? lastError;

  Future<void> initialize() async {
    if (_ready || _disposed) return;
    try {
      _backend ??= Platform.isIOS ? IosAudioBackend() : NativeAudioBackend();
      await _backend!.initialize();
      _ready = true;
      WidgetsBinding.instance.addObserver(this);
      _settings.addListener(_sync);
      _sync();
    } catch (error) {
      lastError = '$error';
      debugPrint('Audio unavailable: $error');
    }
  }

  void enter(Object owner, AudioScene scene) {
    _scenes[owner] = scene;
    _sync();
  }

  void leave(Object owner) {
    _scenes.remove(owner);
    _reels.remove(owner);
    _sync();
  }

  void reels(Object owner, bool playing) {
    playing ? _reels.add(owner) : _reels.remove(owner);
    _sync();
  }

  void play(GameSound sound) {
    if (!_ready || _disposed || !_foreground || !_settings.sound) return;
    final now = DateTime.now();
    final gap = switch (sound) {
      GameSound.peg => 65,
      GameSound.wheelTick => 45,
      GameSound.win || GameSound.bigWin => 180,
      _ => 35,
    };
    final last = _lastEffect[sound];
    if (last != null && now.difference(last).inMilliseconds < gap) return;
    _lastEffect[sound] = now;
    final revision = _revision;
    unawaited(
      _safe(() async {
        if (revision != _revision || !_settings.sound || !_foreground) return;
        await _backend!.effect(
          'audio/sfx/${soundFiles[sound]}.wav',
          switch (sound) {
            GameSound.peg => .24,
            GameSound.wheelTick => .28,
            GameSound.click => .8,
            GameSound.bigWin => .7,
            _ => .52,
          },
        );
      }),
    );
  }

  void _sync() {
    final revision = ++_revision;
    if (!_ready || _disposed) return;
    _queue = _queue.then(
      (_) => _safe(() async {
        // Collapse rapid navigation/lifecycle updates to the newest state.
        if (revision != _revision) return;
        if (_disposed) return;
        final owner = _scenes.isEmpty ? null : _scenes.keys.last;
        final scene = owner == null ? null : _scenes[owner];
        await _backend!.music(
          _foreground && _settings.music && scene != null
              ? 'audio/music/${scene.name}.m4a'
              : null,
        );
        if (revision != _revision) return;
        await _backend!.reelLoop(
          _foreground && _settings.sound && _reels.contains(owner),
        );
        if (!_foreground || !_settings.sound) await _backend!.silenceEffects();
      }),
    );
  }

  Future<void> _safe(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      lastError = '$error';
      debugPrint('Audio playback error: $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  @visibleForTesting
  Future<void> get settled => _queue;

  Future<void> dispose() async {
    _disposed = true;
    _settings.removeListener(_sync);
    WidgetsBinding.instance.removeObserver(this);
    await _queue;
    await _backend?.dispose();
  }
}
