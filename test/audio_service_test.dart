import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:juwa/services/audio_service.dart';
import 'package:juwa/services/settings_service.dart';

class FakeAudio implements AudioBackend {
  String? track;
  bool loop = false;
  bool disposed = false;
  int silences = 0;
  final effects = <String>[];
  @override
  Future<void> initialize() async {}
  @override
  Future<void> music(String? asset) async {
    track = asset;
  }

  @override
  Future<void> reelLoop(bool playing) async {
    loop = playing;
  }

  @override
  Future<void> effect(String asset, double volume) async {
    effects.add(asset);
  }

  @override
  Future<void> silenceEffects() async {
    silences++;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeAudio backend;
  late AudioService audio;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.instance.load();
    backend = FakeAudio();
    audio = AudioService(backend: backend);
    await audio.initialize();
    await audio.settled;
  });
  tearDown(() async {
    await audio.dispose();
  });

  test(
    'Every game restores the lobby music on exit without overlapping loops',
    () async {
      final lobby = Object();
      audio.enter(lobby, AudioScene.lobby);
      for (final scene in AudioScene.values.skip(1)) {
        final game = Object();
        audio.enter(game, scene);
        await audio.settled;
        expect(backend.track, 'audio/music/${scene.name}.m4a');
        audio.reels(game, true);
        await audio.settled;
        expect(backend.loop, isTrue);
        audio.leave(game);
        await audio.settled;
        expect(backend.track, 'audio/music/lobby.m4a');
        expect(backend.loop, isFalse);
      }
      audio.leave(lobby);
      await audio.settled;
      expect(backend.track, isNull);
    },
  );

  test(
    'Music and sound mute independently, and paused apps silence everything',
    () async {
      final game = Object();
      audio.enter(game, AudioScene.fortune);
      audio.reels(game, true);
      await audio.settled;
      SettingsService.instance.setMusic(false);
      await audio.settled;
      expect(backend.track, isNull);
      expect(backend.loop, isTrue);
      audio.play(GameSound.click);
      expect(backend.effects, hasLength(1));
      SettingsService.instance.setMusic(true);
      SettingsService.instance.setSound(false);
      await audio.settled;
      expect(backend.track, 'audio/music/fortune.m4a');
      expect(backend.loop, isFalse);
      audio.play(GameSound.win);
      expect(backend.effects, hasLength(1));
      SettingsService.instance.setSound(true);
      audio.didChangeAppLifecycleState(AppLifecycleState.paused);
      await audio.settled;
      expect(backend.track, isNull);
      expect(backend.loop, isFalse);
      audio.play(GameSound.bigWin);
      expect(backend.effects, hasLength(1));
      audio.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await audio.settled;
      expect(backend.track, 'audio/music/fortune.m4a');
      expect(backend.loop, isTrue);
      expect(backend.silences, greaterThan(0));
    },
  );

  test('Rapid peg contacts are throttled without suppressing other cues', () {
    for (var i = 0; i < 50; i++) {
      audio.play(GameSound.peg);
    }
    audio.play(GameSound.drop);
    expect(backend.effects, ['audio/sfx/peg.wav', 'audio/sfx/drop.wav']);
  });

  test('Every referenced asset and third-party license is bundled', () {
    for (final scene in AudioScene.values) {
      expect(
        File('assets/audio/music/${scene.name}.m4a').lengthSync(),
        greaterThan(10000),
      );
    }
    for (final name in [...soundFiles.values, 'reel_loop']) {
      final bytes = File('assets/audio/sfx/$name.wav').readAsBytesSync();
      expect(String.fromCharCodes(bytes.take(4)), 'RIFF');
      expect(bytes.length, greaterThan(100));
    }
    for (final pack in ['casino-audio', 'interface-sounds']) {
      expect(
        File('assets/audio/licenses/kenney-$pack.txt').readAsStringSync(),
        contains('CC0'),
      );
    }
  });
}
