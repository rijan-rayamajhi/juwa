import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../screens/popups.dart';
import '../../services/audio_service.dart';
import 'package:flutter/services.dart';
import '../../services/wallet_service.dart';
import '../../services/settings_service.dart';
import '../../theme.dart';
import '../../util.dart';
import '../../widgets/game_header.dart';
import '../../widgets/game_footer.dart';
import '../../widgets/coin_flow_overlay.dart';
import '../../widgets/juwa_popup.dart';
import '../../widgets/big_win_celebration_overlay.dart';
import 'wheel_config.dart';

class WheelScreen extends StatefulWidget {
  const WheelScreen({super.key});

  @override
  State<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends State<WheelScreen>
    with TickerProviderStateMixin {
  final _wallet = WalletService.instance;
  final _rng = Random();
  final _coinFlowController = CoinFlowController();

  late final AnimationController _spin;
  late final Animation<double> _curve;
  late final AnimationController _winCountController;
  int _pointerSegment = -1;
  Timer? _autoTimer;

  double _rotation = 0; // radians, clockwise
  double _from = 0, _to = 0;

  int _betIndex = 1;
  bool _spinning = false;
  bool _auto = false;
  int _lastWin = 0;
  int _displayedWin = 0;
  String? _banner;
  String? _bigWinTitle;

  int get _bet => wheelBets[_betIndex];

  @override
  void initState() {
    super.initState();
    AudioService.instance.enter(this, AudioScene.wheel);
    _spin =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 3600),
          )
          ..addListener(() {
            setState(() {
              _rotation = _from + (_to - _from) * _curve.value;
              final segment = (_rotation / (2 * pi / wheelSlices.length))
                  .floor();
              if (segment != _pointerSegment) {
                _pointerSegment = segment;
                if (_spinning) AudioService.instance.play(GameSound.wheelTick);
                if (_spin.value > .5) _haptic();
              }
            });
          })
          ..addStatusListener((s) {
            if (s == AnimationStatus.completed) _onLanded();
          });
    _curve = CurvedAnimation(parent: _spin, curve: Curves.easeOutCubic);

    _winCountController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 700),
        )..addListener(() {
          setState(
            () => _displayedWin =
                (_lastWin *
                        Curves.easeOutCubic.transform(
                          _winCountController.value,
                        ))
                    .round(),
          );
        });
  }

  @override
  void dispose() {
    AudioService.instance.leave(this);
    if (_spinning) _wallet.payout(wheelPayout(_pendingIndex, _bet));
    _autoTimer?.cancel();
    _spin.dispose();
    _winCountController.dispose();
    _coinFlowController.dispose();
    super.dispose();
  }

  void _haptic([bool heavy = false]) {
    if (!SettingsService.instance.haptics) return;
    heavy ? HapticFeedback.heavyImpact() : HapticFeedback.lightImpact();
  }

  void _setMaxBet() {
    if (_spinning) return;
    _haptic();
    setState(() => _betIndex = wheelBets.length - 1);
  }

  void _changeBet(int dir) {
    if (_spinning) return;
    final next = (_betIndex + dir).clamp(0, wheelBets.length - 1);
    if (next != _betIndex) {
      _haptic();
      setState(() => _betIndex = next);
    }
  }

  void _toggleAuto() {
    _haptic();
    setState(() => _auto = !_auto);
    if (_auto && !_spinning) {
      _startSpin();
    }
  }

  int _pendingIndex = 0;

  void _startSpin() {
    if (_spinning) return;
    if (!_wallet.bet(_bet, game: 'FORTUNE WHEEL')) {
      AudioService.instance.play(GameSound.error);
      if (_auto) {
        setState(() => _auto = false);
      }
      showOutOfCoinsDialog(context);
      return;
    }
    _autoTimer?.cancel();
    _winCountController.stop();
    _haptic();
    _pendingIndex = pickSlice(_rng);

    final seg = 2 * pi / wheelSlices.length;
    // Center of the winning wedge, clockwise from the top pointer.
    final center = _pendingIndex * seg + seg / 2;
    // Rotation that brings that center under the top pointer (angle 0).
    final desired = (2 * pi - center) % (2 * pi);
    final currentMod = _rotation % (2 * pi);
    final delta =
        (desired - currentMod) % (2 * pi) + 5 * 2 * pi; // 5 full turns

    _from = _rotation;
    _to = _rotation + delta;

    setState(() {
      _spinning = true;
      _lastWin = 0;
      _displayedWin = 0;
      _banner = null;
    });
    _spin.forward(from: 0);
  }

  void _onLanded() {
    final win = wheelPayout(_pendingIndex, _bet);
    _wallet.payout(win);
    final slice = wheelSlices[_pendingIndex];
    final isBig = slice.isJackpot || win >= _bet * 5;
    final bigTitle = slice.isJackpot
        ? 'JACKPOT!'
        : win >= _bet * 5
            ? 'BIG WIN!'
            : null;

    setState(() {
      _spinning = false;
      _lastWin = win;
      _bigWinTitle = bigTitle;
      _banner = win == 0
          ? 'TRY AGAIN'
          : slice.isJackpot
              ? 'JACKPOT!'
              : win >= _bet * 5
                  ? 'BIG WIN!'
                  : 'YOU WON';
    });
    if (win > 0) {
      AudioService.instance.play(
        win >= _bet * 5 ? GameSound.bigWin : GameSound.win,
      );
      _haptic(true);
      _winCountController.forward(from: 0);

      _coinFlowController.trigger(
        count: win >= _bet * 10 ? 30 : 20,
        start: Offset(
          MediaQuery.of(context).size.width / 2,
          MediaQuery.of(context).size.height / 2,
        ),
      );
    } else {
      _displayedWin = 0;
    }

    if (_auto && !isBig) {
      _autoTimer = Timer(const Duration(milliseconds: 1400), () {
        if (mounted && _auto && !_spinning && _bigWinTitle == null) {
          _startSpin();
        }
      });
    }
  }

  void _dismissBigWin() {
    setState(() => _bigWinTitle = null);
    if (_auto && !_spinning) {
      _autoTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted && _auto && !_spinning) {
          _startSpin();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/wheel_background.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black26, BlendMode.darken),
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                GameHeader(
                  title: 'FORTUNE WHEEL',
                  subtitle: 'SPIN TO WIN',
                  onInfo: () => _showPrizes(context),
                ),
                Expanded(child: Center(child: _wheel())),
                // Reusable Bottom Console Deck following the shared theme
                GameFooter(
                  bet: _bet,
                  onBetChange: _changeBet,
                  canDecreaseBet: _betIndex > 0,
                  canIncreaseBet: _betIndex < wheelBets.length - 1,
                  isMaxBet: _betIndex == wheelBets.length - 1,
                  onMaxBet: _setMaxBet,
                  lastWin: _lastWin,
                  displayedWin: _displayedWin,
                  isAuto: _auto,
                  onToggleAuto: _toggleAuto,
                  isSpinning: _spinning,
                  spinLabel: _spinning ? 'WAIT' : 'SPIN',
                  onSpin: _spinning ? null : _startSpin,
                ),
              ],
            ),

            // Golden Coin Flowing Animation Layer
            Positioned.fill(
              child: IgnorePointer(
                child: CoinFlowOverlay(controller: _coinFlowController),
              ),
            ),

            // Big Win Celebration Overlay with Play for Real & Manual Close
            if (_bigWinTitle != null)
              Positioned.fill(
                child: BigWinCelebrationOverlay(
                  title: _bigWinTitle!,
                  winAmount: _lastWin,
                  onClose: _dismissBigWin,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _wheel() {
    return LayoutBuilder(
      builder: (context, c) {
        // Maximize wheel size to proudly fill the central stage without clipping
        final size = min(
          c.maxWidth * 0.9,
          max(0.0, c.maxHeight - 10),
        ).clamp(0.0, 520.0);
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Stage drop shadow grounding the wheel on the red velvet podium
              Positioned(
                bottom: -size * 0.01,
                child: Container(
                  width: size * 0.65,
                  height: size * 0.08,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.elliptical(size * 0.65, size * 0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.75),
                        blurRadius: 18,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),

              // 1. Rotating wedges surface (CustomPaint spins smoothly)
              Transform.rotate(
                angle: _rotation,
                child: Padding(
                  // Inset so wedges sit inside the decorative rim
                  padding: EdgeInsets.all(size * 0.09),
                  child: CustomPaint(
                    size: Size.square(size * 0.82),
                    painter: _WheelPainter(),
                  ),
                ),
              ),

              // 2. Static Ornate Golden Marquee Rim with Jewels and Lights
              Image.asset(
                'assets/images/wheel_base.png',
                width: size,
                height: size,
                fit: BoxFit.contain,
              ),

              // 3. Static Ornate Central Hub Medallion
              Image.asset(
                'assets/images/wheel_hub.png',
                width: size * 0.24,
                height: size * 0.24,
              ),

              // 4. Static Top Jewel Pointer pointing cleanly down into the 12 o'clock wedge
              Positioned(
                top: -size * 0.02,
                child: Transform.rotate(
                  alignment: Alignment.topCenter,
                  angle: _spinning && !MediaQuery.disableAnimationsOf(context)
                      ? -.12 *
                            sin(
                              (_rotation / (2 * pi / wheelSlices.length) % 1) *
                                  pi,
                            )
                      : 0,
                  child: Image.asset(
                    'assets/images/wheel_pointer.png',
                    width: size * .18,
                    height: size * .22,
                  ),
                ),
              ),

              // 5. Win Announcement Plaque
              if (_banner != null && !_spinning)
                Positioned(
                  bottom: size * 0.04,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: .85, end: 1),
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 350),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: _bannerChip(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _bannerChip() {
    final win = _lastWin;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFA2B183E), Color(0xFA09040E)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JuwaColors.gold, width: 2),
        boxShadow: [
          BoxShadow(
            color: JuwaColors.gold.withValues(alpha: 0.6),
            blurRadius: 18,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _banner!,
            style: const TextStyle(
              color: JuwaColors.gold,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 2,
            ),
          ),
          if (win > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/coin.png', width: 18, height: 18),
                  const SizedBox(width: 5),
                  Text(
                    '+${formatCoins(win)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showPrizes(BuildContext context) {
    _haptic();
    showDialog(
      context: context,
      builder: (ctx) => JuwaPopup(
        title: 'Fortune Wheel Prizes',
        maxWidth: 460,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Text(
                'Each spin costs your bet. You win the landed wedge’s multiplier × bet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: JuwaColors.textDim, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            for (final s in _uniqueSlices())
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(width: 16, height: 16, color: s.color),
                    const SizedBox(width: 10),
                    Text(
                      s.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      s.multiplier == 0 ? 'no win' : '${s.multiplier}× bet',
                      style: const TextStyle(color: JuwaColors.gold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<WheelSlice> _uniqueSlices() {
    final seen = <String>{};
    final out = <WheelSlice>[];
    for (final s in wheelSlices) {
      if (seen.add(s.label)) out.add(s);
    }
    out.sort((a, b) => b.multiplier.compareTo(a.multiplier));
    return out;
  }
}

/// Draws the 8 colored wedges + gold dividers + labels, starting at the top
/// pointer and going clockwise (matches the spin math in the screen).
class _WheelPainter extends CustomPainter {
  static const seg = 2 * pi / 8;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final top = -pi / 2; // 12 o'clock in canvas coords

    final divider = Paint()
      ..color = JuwaColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.02;

    for (var i = 0; i < wheelSlices.length; i++) {
      final start = top + i * seg;
      final fill = Paint()
        ..color = wheelSlices[i].color
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, start, seg, true, fill);
      canvas.drawArc(rect, start, seg, true, divider);
      _label(canvas, center, radius, start + seg / 2, wheelSlices[i].label);
    }
  }

  void _label(
    Canvas canvas,
    Offset center,
    double radius,
    double mid,
    String text,
  ) {
    final isJackpot = text == 'x50';
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: isJackpot ? const Color(0xFF2B1400) : Colors.white,
          fontSize: radius * 0.13,
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: isJackpot ? JuwaColors.gold : Colors.black,
              blurRadius: isJackpot ? 2 : 4,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final pos = Offset(
      center.dx + cos(mid) * radius * 0.62,
      center.dy + sin(mid) * radius * 0.62,
    );
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(mid + pi / 2); // text reads outward
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
