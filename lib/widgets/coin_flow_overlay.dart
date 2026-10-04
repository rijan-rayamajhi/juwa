import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/settings_service.dart';
import '../theme.dart';

/// Controller to trigger coin flow animations from any game event.
class CoinFlowController extends ChangeNotifier {
  int _burstId = 0;
  int _coinCount = 20;
  Offset? _customStart;
  Offset? _customEnd;

  int get burstId => _burstId;
  int get coinCount => _coinCount;
  Offset? get customStart => _customStart;
  Offset? get customEnd => _customEnd;

  /// Trigger a flowing shower of golden coins.
  ///
  /// [count]: Number of coins to animate (e.g. 16 for small win, 30 for big win).
  /// [start]: Custom launch origin (defaults to center reels).
  /// [end]: Custom absorption destination (defaults to top-right coin balance).
  void trigger({int count = 20, Offset? start, Offset? end}) {
    _burstId++;
    _coinCount = count;
    _customStart = start;
    _customEnd = end;
    notifyListeners();
  }
}

/// Production-ready 60-120fps animated coin flowing overlay.
///
/// Features:
/// - Smooth quadratic Bezier trajectory from winning reels to wallet balance
/// - Staggered multi-coin fountain stream effect
/// - 3D coin tumbling flip perspective illusion
/// - Sparkling gold particle trail
/// - Automatic safe area offset targeting
/// - Haptic sound-ready feedback during stream
class CoinFlowOverlay extends StatefulWidget {
  final CoinFlowController controller;

  const CoinFlowOverlay({super.key, required this.controller});

  @override
  State<CoinFlowOverlay> createState() => _CoinFlowOverlayState();
}

class _CoinFlowOverlayState extends State<CoinFlowOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  final List<_CoinParticle> _particles = [];
  final math.Random _rng = math.Random();
  bool _isPlaying = false;
  int _lastBurstId = 0;
  int _lastHapticStep = -1;

  @override
  void initState() {
    super.initState();
    _anim =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1600),
          )
          ..addListener(_onTick)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              if (mounted) {
                setState(() {
                  _isPlaying = false;
                  _particles.clear();
                });
              }
            }
          });

    widget.controller.addListener(_onControllerTrigger);
  }

  @override
  void didUpdateWidget(CoinFlowOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerTrigger);
      widget.controller.addListener(_onControllerTrigger);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerTrigger);
    _anim.dispose();
    super.dispose();
  }

  void _onControllerTrigger() {
    if (widget.controller.burstId != _lastBurstId) {
      _lastBurstId = widget.controller.burstId;
      _spawnBurst(
        widget.controller.coinCount,
        widget.controller.customStart,
        widget.controller.customEnd,
      );
    }
  }

  void _spawnBurst(int count, Offset? customStart, Offset? customEnd) {
    if (!mounted) return;

    final media = MediaQuery.of(context);
    if (media.disableAnimations) return;
    _lastHapticStep = -1;
    final size = media.size;
    final insets = media.padding;

    // Default start: Center of reels / screen
    final start = customStart ?? Offset(size.width * 0.50, size.height * 0.52);

    // Default end: Top-right coin pill in header
    final end =
        customEnd ?? Offset(size.width - insets.right - 140, insets.top + 22);

    _particles.clear();
    for (var i = 0; i < count; i++) {
      // Staggered launch delays for flowing trail
      final delay = (i / count) * 0.40 + (_rng.nextDouble() * 0.05);
      final duration = 0.50 + (_rng.nextDouble() * 0.08);

      _particles.add(
        _CoinParticle(
          p0:
              start +
              Offset(
                (_rng.nextDouble() - 0.5) * 60,
                (_rng.nextDouble() - 0.5) * 35,
              ),
          p2:
              end +
              Offset(
                (_rng.nextDouble() - 0.5) * 16,
                (_rng.nextDouble() - 0.5) * 10,
              ),
          p1: Offset(
            (start.dx + end.dx) * 0.5 + (_rng.nextDouble() - 0.5) * 90,
            math.min(start.dy, end.dy) - (70 + _rng.nextDouble() * 110),
          ),
          delay: delay,
          duration: duration,
          size: 22.0 + _rng.nextDouble() * 10.0,
          spinSpeed:
              (_rng.nextBool() ? 1 : -1) * (2.0 + _rng.nextDouble() * 3.0),
          tumbleSpeed: 8.0 + _rng.nextDouble() * 8.0,
        ),
      );
    }

    if (SettingsService.instance.haptics) {
      HapticFeedback.lightImpact();
    }

    setState(() {
      _isPlaying = true;
    });

    _anim.forward(from: 0);
  }

  void _onTick() {
    if (!_isPlaying) return;
    // Periodic subtle haptic vibration as coins stream in
    if (SettingsService.instance.haptics &&
        _anim.value > 0.3 &&
        _anim.value < 0.8) {
      final step = (_anim.value * 20).toInt();
      if (step % 4 == 0 && step != _lastHapticStep) {
        _lastHapticStep = step;
        HapticFeedback.selectionClick();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPlaying || _particles.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, _) {
            final t = _anim.value;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (final p in _particles) _buildParticleWidget(p, t),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildParticleWidget(_CoinParticle p, double globalT) {
    if (globalT < p.delay) return const SizedBox.shrink();
    final localT = (globalT - p.delay) / p.duration;
    if (localT > 1.0) return const SizedBox.shrink();

    // Quadratic Bezier interpolation
    final oneMinus = 1.0 - localT;
    final x =
        oneMinus * oneMinus * p.p0.dx +
        2.0 * oneMinus * localT * p.p1.dx +
        localT * localT * p.p2.dx;
    final y =
        oneMinus * oneMinus * p.p0.dy +
        2.0 * oneMinus * localT * p.p1.dy +
        localT * localT * p.p2.dy;

    // Scale animation: pop in, travel at full size, shrink as it absorbs
    double scale = 1.0;
    if (localT < 0.15) {
      scale = 0.3 + (localT / 0.15) * 0.75;
    } else if (localT > 0.80) {
      scale = 1.05 - ((localT - 0.80) / 0.20) * 0.70;
    } else {
      scale = 1.05;
    }

    // 3D Coin tumbling perspective (horizontal compression oscillation)
    final tumble = math
        .cos(localT * math.pi * p.tumbleSpeed)
        .abs()
        .clamp(0.2, 1.0);
    final rotation = localT * math.pi * p.spinSpeed;

    // Opacity fade at very start & finish
    double opacity = 1.0;
    if (localT < 0.08) {
      opacity = (localT / 0.08).clamp(0.0, 1.0);
    } else if (localT > 0.90) {
      opacity = ((1.0 - localT) / 0.10).clamp(0.0, 1.0);
    }

    return Positioned(
      left: x - p.size * 0.5,
      top: y - p.size * 0.5,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: rotation,
          child: Transform.scale(
            scaleX: scale * tumble,
            scaleY: scale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Subtle golden ambient aura
                Container(
                  width: p.size * 1.1,
                  height: p.size * 1.1,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: JuwaColors.gold.withValues(alpha: 0.35),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                // Golden coin asset
                Image.asset(
                  'assets/images/coin.png',
                  width: p.size,
                  height: p.size,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CoinParticle {
  final Offset p0;
  final Offset p1;
  final Offset p2;
  final double delay;
  final double duration;
  final double size;
  final double spinSpeed;
  final double tumbleSpeed;

  const _CoinParticle({
    required this.p0,
    required this.p1,
    required this.p2,
    required this.delay,
    required this.duration,
    required this.size,
    required this.spinSpeed,
    required this.tumbleSpeed,
  });
}
