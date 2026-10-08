import 'package:flutter/material.dart';
import '../../screens/popups.dart';
import '../../services/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import '../../services/wallet_service.dart';
import '../../services/settings_service.dart';
import '../../theme.dart';
import '../../util.dart';
import '../../widgets/game_header.dart';
import '../../widgets/game_footer.dart';
import '../../widgets/juwa_popup.dart';
import '../../widgets/big_win_celebration_overlay.dart';
import 'plinko_config.dart';
import 'plinko_physics.dart';

class PlinkoScreen extends StatefulWidget {
  const PlinkoScreen({super.key});

  @override
  State<PlinkoScreen> createState() => _PlinkoScreenState();
}

class _PlinkoScreenState extends State<PlinkoScreen>
    with SingleTickerProviderStateMixin {
  final _wallet = WalletService.instance;
  final _physics = PlinkoPhysics();
  final _frame = ValueNotifier<int>(0); // repaints the live layer only
  late final Ticker _ticker;
  Duration _previousTick = Duration.zero;
  int _betIndex = 1;
  int _lastWin = 0;
  int _totalPaid = 0;
  int _totalStaked = 0;
  int _launched = 0;
  String? _bigWinTitle;
  int _bigWinAmount = 0;
  int get _bet => plinkoBets[_betIndex];

  @override
  void initState() {
    super.initState();
    AudioService.instance.enter(this, AudioScene.plinko);
    _ticker = createTicker(_tick);
  }

  void _tick(Duration elapsed) {
    final seconds = (elapsed - _previousTick).inMicroseconds / 1000000;
    _previousTick = elapsed;
    // Resume gently after a suspended frame; fixed substeps prevent tunnelling.
    final impactsBefore = _physics.impactCount;
    final landed = _physics.advance(seconds.clamp(0.0, .1));
    if (_physics.impactCount > impactsBefore) {
      AudioService.instance.play(GameSound.peg);
    }
    for (final ball in landed) {
      final payout = plinkoPayout(ball.bucket!, ball.bet);
      _wallet.payout(payout);
      _lastWin = payout;
      _totalPaid += payout;
      final isBig = payout >= ball.bet * 5;
      if (isBig) {
        _bigWinTitle = payout >= ball.bet * 10 ? 'JACKPOT!' : 'BIG WIN!';
        _bigWinAmount = payout;
      }
      AudioService.instance.play(
        payout >= ball.bet * 3 ? GameSound.bigWin : GameSound.reelStop,
      );
    }
    if (landed.isNotEmpty) _haptic();
    final stopped = _physics.balls.isEmpty && _physics.bucketFlashes.isEmpty;
    if (stopped) _ticker.stop();
    _frame.value++;
    // Rebuild the header/footer/status only when their numbers change,
    // not every frame.
    if (landed.isNotEmpty || stopped) setState(() {});
  }

  void _dismissBigWin() {
    setState(() => _bigWinTitle = null);
  }

  @override
  void dispose() {
    AudioService.instance.leave(this);
    _ticker.dispose();
    _frame.dispose();
    // Finish the same simulation on route removal so every charged ball settles.
    for (var i = 0; i < 300 && _physics.balls.isNotEmpty; i++) {
      for (final ball in _physics.advance(.1)) {
        _wallet.payout(plinkoPayout(ball.bucket!, ball.bet));
      }
    }
    // A pathological stalled ball is refunded, never assigned a random prize.
    for (final ball in _physics.balls) {
      _wallet.payout(ball.bet);
    }
    super.dispose();
  }

  void _haptic([bool heavy = false]) {
    if (!SettingsService.instance.haptics) return;
    heavy ? HapticFeedback.heavyImpact() : HapticFeedback.lightImpact();
  }

  void _changeBet(int dir) {
    final next = (_betIndex + dir).clamp(0, plinkoBets.length - 1);
    if (next != _betIndex) {
      _haptic();
      setState(() => _betIndex = next);
    }
  }

  void _dropChip() {
    if (!_wallet.bet(_bet, game: 'PLINKO')) {
      AudioService.instance.play(GameSound.error);
      showOutOfCoinsDialog(context);
      return;
    }
    _haptic();
    setState(() {
      _physics.launch(_bet);
      AudioService.instance.play(GameSound.drop);
      _totalStaked += _bet;
      _launched++;
    });
    if (!_ticker.isActive) {
      _previousTick = Duration.zero;
      _ticker.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/plinko_background.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Color(0x55090016), BlendMode.darken),
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                GameHeader(
                  title: 'PLINKO',
                  subtitle: 'DROP & WIN',
                  onInfo: () => _showPrizes(context),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: LayoutBuilder(
                      builder: (context, c) {
                        return Center(
                          child: AspectRatio(
                            aspectRatio: PlinkoPhysics.width / PlinkoPhysics.height,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Static pegs/buckets: painted once, cached.
                                const RepaintBoundary(
                                  child: CustomPaint(painter: _BoardPainter()),
                                ),
                                // Clipped: queued balls wait just above the board.
                                ClipRect(
                                  child: RepaintBoundary(
                                    child: CustomPaint(
                                      painter: _PlinkoPainter(_physics, _frame),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                _winLine(),
                _console(),
              ],
            ),

            // Big Win Celebration Overlay with Play for Real & Manual Close
            if (_bigWinTitle != null)
              Positioned.fill(
                child: BigWinCelebrationOverlay(
                  title: _bigWinTitle!,
                  winAmount: _bigWinAmount,
                  onClose: _dismissBigWin,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _winLine() {
    final active = _physics.balls.length;
    final net = _totalPaid - _totalStaked;
    final message = active > 0
        ? '$active ${active == 1 ? 'BALL' : 'BALLS'} IN PLAY • TAP DROP TO ADD A BALL'
        : _launched == 0
        ? 'ONE TAP • ONE BALL'
        : 'PAYOUT ${formatCoins(_totalPaid)} • NET ${net >= 0 ? '+' : '−'}${formatCoins(net.abs())}';
    return SizedBox(
      height: 20,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            message,
            style: const TextStyle(
              color: JuwaColors.gold,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _console() => GameFooter(
    bet: _bet,
    betLabel: 'BET / BALL',
    onBetChange: _changeBet,
    canDecreaseBet: _betIndex > 0,
    canIncreaseBet: _betIndex < plinkoBets.length - 1,
    isMaxBet: _betIndex == plinkoBets.length - 1,
    onMaxBet: () => setState(() => _betIndex = plinkoBets.length - 1),
    lastWin: _lastWin,
    isSpinning: false,
    spinLabel: 'DROP',
    onSpin: _dropChip,
  );

  void _showPrizes(BuildContext context) {
    _haptic();
    showDialog(
      context: context,
      builder: (ctx) => JuwaPopup(
        title: 'Plinko Prizes',
        maxWidth: 460,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Text(
                'Each tap drops one ball and costs the displayed bet. Tap again to add another ball while the others fall. Gravity and peg collisions determine the landing bucket. Each ball pays its bucket multiplier × the bet when it was released. Changing your bet affects only new balls.',
                textAlign: TextAlign.center,
                style: TextStyle(color: JuwaColors.textDim, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < plinkoMultipliers.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: plinkoBucketColors[i],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_fmtMult(plinkoMultipliers[i])}×',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _fmtMult(double m) =>
    m == m.roundToDouble() ? m.toInt().toString() : '$m';

/// Static board, same geometry as the collision solver. Never repaints.
class _BoardPainter extends CustomPainter {
  const _BoardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / PlinkoPhysics.width);
    for (final p in PlinkoPhysics.pegs) {
      canvas.drawCircle(
        p,
        9,
        Paint()
          ..color = JuwaColors.gold.withValues(alpha: .15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      _peg(canvas, p, const Color(0xFFFFF3BD));
    }
    for (var i = 0; i < plinkoMultipliers.length; i++) {
      final color = plinkoBucketColors[i];
      final rect = _bucketRect(i);
      final rounded = RRect.fromRectAndRadius(rect, const Radius.circular(8));
      canvas.drawRRect(
        rounded,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(color, Colors.white, .24)!,
              color,
              Color.lerp(color, Colors.black, .35)!,
            ],
          ).createShader(rect),
      );
      canvas.drawRRect(
        rounded,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white30,
      );
      _text(canvas, '${_fmtMult(plinkoMultipliers[i])}×', rect.center, 24);
    }
    canvas.restore();
  }

  void _text(Canvas canvas, String value, Offset center, double fontSize) {
    final text = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w900,
          shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => false;
}

Rect _bucketRect(int i) =>
    Rect.fromLTWH(i * 100.0 + 3, PlinkoPhysics.bucketY, 94, 48);

void _peg(Canvas canvas, Offset p, Color highlight) => canvas.drawCircle(
  p,
  PlinkoPhysics.pegRadius,
  Paint()
    ..shader = RadialGradient(
      center: const Alignment(-.4, -.5),
      colors: [highlight, const Color(0xFFE5B447), const Color(0xFF876025)],
    ).createShader(Rect.fromCircle(center: p, radius: PlinkoPhysics.pegRadius)),
);

/// Live layer: peg/bucket flashes and balls, repainted each tick via [repaint].
class _PlinkoPainter extends CustomPainter {
  final PlinkoPhysics physics;
  _PlinkoPainter(this.physics, Listenable repaint) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / PlinkoPhysics.width);
    for (final i in physics.pegFlashes.keys) {
      final p = PlinkoPhysics.pegs[i];
      canvas.drawCircle(
        p,
        14,
        Paint()
          ..color = JuwaColors.gold.withValues(alpha: .5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      _peg(canvas, p, Colors.white);
    }
    for (final i in physics.bucketFlashes.keys) {
      final rounded = RRect.fromRectAndRadius(
        _bucketRect(i),
        const Radius.circular(8),
      );
      canvas.drawRRect(
        rounded,
        Paint()
          ..color = plinkoBucketColors[i].withValues(alpha: .7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      canvas.drawRRect(
        rounded,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = const Color(0xFFFFF4C7),
      );
    }
    final t = physics.alpha.clamp(0.0, 1.0);
    for (final ball in physics.balls) {
      for (var i = 0; i < ball.trail.length; i++) {
        canvas.drawCircle(
          ball.trail[i],
          3 + i * .8,
          Paint()..color = JuwaColors.gold.withValues(alpha: .025 * i),
        );
      }
      final chip = ball.lerp(t);
      canvas.drawCircle(
        chip,
        14,
        Paint()
          ..color = JuwaColors.gold.withValues(alpha: .3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawCircle(
        chip,
        PlinkoPhysics.ballRadius,
        Paint()
          ..shader =
              const RadialGradient(
                center: Alignment(-.35, -.45),
                colors: [Colors.white, Color(0xFFFFE69A), Color(0xFFBC7A17)],
              ).createShader(
                Rect.fromCircle(center: chip, radius: PlinkoPhysics.ballRadius),
              ),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PlinkoPainter oldDelegate) =>
      oldDelegate.physics != physics;
}
