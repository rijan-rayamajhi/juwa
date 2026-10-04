import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var audio: JuwaAudio?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "JuwaAudio") {
      audio = JuwaAudio(registrar: registrar)
    }
  }
}

/// iOS audio on AVAudioPlayer: numberOfLoops = -1 loops sample-accurately
/// (audioplayers loops by seek-on-end, which gaps) and prepared players
/// start instantly, so short clicks are not lost.
final class JuwaAudio {
  private let registrar: FlutterPluginRegistrar
  private let channel: FlutterMethodChannel
  private var music: AVAudioPlayer?
  private var musicAsset: String?
  private var reels: AVAudioPlayer?
  private var pools: [String: [AVAudioPlayer]] = [:]

  init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
    channel = FlutterMethodChannel(name: "juwa/audio", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return result(nil) }
      let args = call.arguments as? [String: Any] ?? [:]
      switch call.method {
      case "initialize":
        // Ambient: mixes with other apps and respects the silent switch.
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        try? AVAudioSession.sharedInstance().setActive(true)
        self.reels = self.player("audio/sfx/reel_loop.wav")
        self.reels?.numberOfLoops = -1
      case "music":
        self.setMusic(args["asset"] as? String)
      case "reels":
        self.setReels(args["playing"] as? Bool ?? false)
      case "effect":
        if let asset = args["asset"] as? String {
          self.effect(asset, Float(args["volume"] as? Double ?? 1))
        }
      case "silence":
        self.pools.values.joined().forEach { $0.stop() }
      default:
        return result(FlutterMethodNotImplemented)
      }
      result(nil)
    }
  }

  private func player(_ asset: String) -> AVAudioPlayer? {
    let key = registrar.lookupKey(forAsset: "assets/" + asset)
    guard let path = Bundle.main.path(forResource: key, ofType: nil),
      let p = try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
    else { return nil }
    p.prepareToPlay()
    return p
  }

  private func setMusic(_ asset: String?) {
    guard asset != musicAsset else { return }
    if let old = music {
      old.setVolume(0, fadeDuration: 0.25)
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { old.stop() }
    }
    music = nil
    musicAsset = asset
    guard let asset = asset, let p = player(asset) else { return }
    p.numberOfLoops = -1
    p.volume = 0
    p.play()
    // Background music sits well below gameplay cues.
    p.setVolume(0.25, fadeDuration: 0.4)
    music = p
  }

  private func setReels(_ playing: Bool) {
    guard let r = reels else { return }
    if playing {
      guard !r.isPlaying else { return }
      r.currentTime = 0
      r.volume = 0.28
      r.play()
    } else {
      r.stop()
    }
  }

  private func effect(_ asset: String, _ volume: Float) {
    var pool = pools[asset] ?? []
    let p: AVAudioPlayer
    if let free = pool.first(where: { !$0.isPlaying }) {
      p = free
    } else if pool.count < 4, let fresh = player(asset) {
      // At most 4 overlapping voices per sound.
      p = fresh
      pool.append(fresh)
      pools[asset] = pool
    } else {
      return
    }
    p.currentTime = 0
    p.volume = volume
    p.play()
  }
}
