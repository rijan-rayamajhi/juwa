import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../screens/popups.dart';
import '../../services/audio_service.dart';
import 'package:flutter/services.dart';
import '../../services/wallet_service.dart';
import '../../services/settings_service.dart';
import '../../theme.dart';
import '../../widgets/juwa_popup.dart';
import '../../widgets/game_header.dart';
import '../../widgets/game_footer.dart';
import '../../widgets/coin_flow_overlay.dart';
import '../../widgets/big_win_celebration_overlay.dart';
import 'slot_config.dart';
import 'slot_engine.dart';
import 'slot_theme.dart';

class SlotScreen extends StatefulWidget {
  final SlotTheme theme;
  const SlotScreen({super.key, this.theme = fortuneTheme});

  @override
  State<SlotScreen> createState() => _SlotScreenState();
}

class _SlotScreenState extends State<SlotScreen> with TickerProviderStateMixin {
  SlotTheme get _theme => widget.theme;
  late final _engine = SlotEngine(null, _theme.weights, _theme.payTable);
  final _wallet = WalletService.instance;
  final _coinFlowController = CoinFlowController();

  late List<List<Sym>> _grid;
  final _stopped = List<bool>.filled(reels, true);
  Set<String> _winCells = {};
  List<LineWin> _activeWins = [];
  bool _spinning = false;
  bool _auto = false;
  int _betIndex = 1; // default 100
  int _lastWin = 0;
  int _displayedWin = 0;
  String? _celebrationTitle;

  late final AnimationController _reelMotion;
  final _visualRandom = math.Random();
  double _previousReelPhase = 0;
  final _incoming = List<Sym>.filled(reels, Sym.values.first);
  final List<Timer> _stopTimers = [];
  Timer? _autoTimer;
  Timer? _celebrationTimer;
  SpinResult? _pendingResult;

  // Controllers for smooth animations
  late final AnimationController _pulseController;
  late final AnimationController _winCountController;
  late final AnimationController _celebrationController;

  int get _bet => betLevels[_betIndex];

  @override
  void initState() {
    super.initState();
    AudioService.instance.enter(
      this,
      _theme.title == 'FISH HUNTER'
          ? AudioScene.fish
          : _theme.title == 'VAMPIRE QUEEN'
          ? AudioScene.vampire
          : AudioScene.fortune,
    );
    _grid = _engine.spin(0).grid;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _reelMotion =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 140),
        )..addListener(() {
          if (_reelMotion.value < _previousReelPhase) {
            for (var r = 0; r < reels; r++) {
              if (!_stopped[r]) {
                _grid[r] = [_incoming[r], ..._grid[r].take(rows - 1)];
                _incoming[r] =
                    Sym.values[_visualRandom.nextInt(Sym.values.length)];
              }
            }
          }
          _previousReelPhase = _reelMotion.value;
        });
    _winCountController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 800),
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

    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    AudioService.instance.leave(this);
    _reelMotion.stop();
    _autoTimer?.cancel();
    _celebrationTimer?.cancel();
    for (final t in _stopTimers) {
      t.cancel();
    }
    if (_spinning && _pendingResult != null) {
      _wallet.payout(_pendingResult!.totalWin);
    }
    _reelMotion.dispose();
    _coinFlowController.dispose();
    _pulseController.dispose();
    _winCountController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  void _triggerHaptic([bool heavy = false]) {
    if (SettingsService.instance.haptics) {
      if (heavy) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _setMaxBet() {
    if (_spinning) return;
    _triggerHaptic();
    setState(() => _betIndex = betLevels.length - 1);
  }

  void _changeBet(int dir) {
    if (_spinning) return;
    final next = (_betIndex + dir).clamp(0, betLevels.length - 1);
    if (next != _betIndex) {
      _triggerHaptic();
      setState(() => _betIndex = next);
    }
  }

  void _toggleAuto() {
    _triggerHaptic();
    setState(() => _auto = !_auto);
    if (_auto && !_spinning) {
      _spin();
    }
  }

  /// Quick Stop: immediately halts spinning reels and evaluates win
  void _quickStop() {
    if (!_spinning || _pendingResult == null) return;
    _reelMotion.stop();
    for (final t in _stopTimers) {
      t.cancel();
    }
    _stopTimers.clear();

    final result = _pendingResult!;
    for (var r = 0; r < reels; r++) {
      _stopped[r] = true;
      _grid[r] = result.grid[r];
    }
    _finish(result);
  }

  void _spin() {
    if (_spinning) {
      _quickStop();
      return;
    }

    if (!_wallet.bet(_bet, game: widget.theme.title)) {
      AudioService.instance.play(GameSound.error);
      showOutOfCoinsDialog(context);
      if (_auto) setState(() => _auto = false);
      return;
    }

    _autoTimer?.cancel();
    _celebrationTimer?.cancel();
    _celebrationController.stop();
    _triggerHaptic();
    final result = _engine.spin(_bet);
    _pendingResult = result;

    setState(() {
      _spinning = true;
      _winCells = {};
      _activeWins = [];
      _celebrationTitle = null;
      _lastWin = 0;
      _displayedWin = 0;
      for (var r = 0; r < reels; r++) {
        _stopped[r] = false;
      }
    });

    _pulseController.stop();
    _winCountController.stop();
    _previousReelPhase = 0;
    _reelMotion.value = 0;
    _reelMotion.repeat();
    AudioService.instance.reels(this, true);

    _stopTimers.clear();
    for (var r = 0; r < reels; r++) {
      final t = Timer(Duration(milliseconds: 400 + r * 220), () {
        if (!mounted || !_spinning) return;
        _triggerHaptic();
        AudioService.instance.play(GameSound.reelStop);
        setState(() {
          _stopped[r] = true;
          _grid[r] = result.grid[r];
        });
        if (r == reels - 1) {
          _reelMotion.stop();
          _finish(result);
        }
      });
      _stopTimers.add(t);
    }
  }

  void _finish(SpinResult result) {
    AudioService.instance.reels(this, false);
    AudioService.instance.play(GameSound.reelStop);
    if (result.totalWin > 0) {
      AudioService.instance.play(
        result.totalWin >= _bet * 4 ? GameSound.bigWin : GameSound.win,
      );
    }
    _pendingResult = null;
    _wallet.payout(result.totalWin);
    final cells = <String>{};
    for (final w in result.wins) {
      for (var r = 0; r < w.count; r++) {
        cells.add('${r}_${paylines[w.line][r]}');
      }
    }

    // Win celebration classification
    String? banner;
    if (result.totalWin > 0) {
      final mult = result.totalWin / _bet;
      if (mult >= 20) {
        banner = 'JACKPOT!';
      } else if (mult >= 10) {
        banner = 'MEGA WIN!';
      } else if (mult >= 4) {
        banner = 'BIG WIN!';
      }
    }

    setState(() {
      _spinning = false;
      _lastWin = result.totalWin;
      _winCells = cells;
      _activeWins = result.wins;
      _celebrationTitle = banner;
    });

    if (result.totalWin > 0) {
      _triggerHaptic(true);

      // Trigger flowing coin stream animation
      final isBig = (result.totalWin / _bet) >= 4;
      _coinFlowController.trigger(count: isBig ? 30 : 18);

      // Smooth animated count-up for WIN marquee
      if (!MediaQuery.disableAnimationsOf(context)) {
        _pulseController.repeat(reverse: true);
      }
      _winCountController.forward(from: 0);

      if (banner != null) {
        _celebrationController.forward(from: 0);
        // Do not auto-close Big Win; require manual close from player
      }
    }

    // Autoplay progression (only if not waiting for Big Win dismissal)
    if (_auto && banner == null) {
      if (_wallet.canBet(_bet)) {
        _autoTimer = Timer(const Duration(milliseconds: 700), () {
          if (mounted && _auto && !_spinning && _celebrationTitle == null) {
            _spin();
          }
        });
      } else {
        setState(() => _auto = false);
      }
    }
  }

  void _dismissCelebration() {
    _celebrationTimer?.cancel();
    _celebrationController.reverse().then((_) {
      if (mounted) {
        setState(() => _celebrationTitle = null);
        // If auto play was on, resume after celebration dismissed
        if (_auto && !_spinning) {
          if (_wallet.canBet(_bet)) {
            _autoTimer = Timer(const Duration(milliseconds: 400), () {
              if (mounted && _auto && !_spinning) _spin();
            });
          } else {
            setState(() => _auto = false);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final insets = media.padding;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_theme.background),
            fit: BoxFit.cover,
            colorFilter: const ColorFilter.mode(
              Colors.black38,
              BlendMode.darken,
            ),
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                // Reusable Top HUD
                GameHeader(
                  title: _theme.title,
                  subtitle: _theme.subtitle,
                  onInfo: () => _showPaytable(context),
                ),

                // Main Reels Frame Center
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10 + insets.left * 0.4,
                        vertical: 2,
                      ),
                      child: _reels(),
                    ),
                  ),
                ),

                // Reusable Bottom Console Deck
                GameFooter(
                  bet: _bet,
                  onBetChange: _changeBet,
                  canDecreaseBet: _betIndex > 0,
                  canIncreaseBet: _betIndex < betLevels.length - 1,
                  isMaxBet: _betIndex == betLevels.length - 1,
                  onMaxBet: _setMaxBet,
                  lastWin: _lastWin,
                  displayedWin: _displayedWin,
                  isAuto: _auto,
                  onToggleAuto: _toggleAuto,
                  isSpinning: _spinning,
                  onSpin: _spin,
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
            if (_celebrationTitle != null)
              Positioned.fill(
                child: FadeTransition(
                  opacity: _celebrationController,
                  child: BigWinCelebrationOverlay(
                    title: _celebrationTitle!,
                    winAmount: _lastWin,
                    onClose: _dismissCelebration,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // REELS & FRAME
  // ==========================================
  Widget _reels() {
    return LayoutBuilder(
      builder: (context, c) {
        double fw = c.maxWidth;
        double fh = fw / _theme.frameAspect;
        if (fh > c.maxHeight) {
          fh = c.maxHeight;
          fw = fh * _theme.frameAspect;
        }
        final winLeft = _theme.winL * fw;
        final winTop = _theme.winT * fh;
        final winW = (_theme.winR - _theme.winL) * fw;
        final winH = (_theme.winB - _theme.winT) * fh;

        final gridLeft = _theme.gridL * fw;
        final gridTop = _theme.gridT * fh;
        final gridW = (_theme.gridR - _theme.gridL) * fw;
        final gridH = (_theme.gridB - _theme.gridT) * fh;

        return SizedBox(
          width: fw,
          height: fh,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Dark Reel Backdrop Container (tucked cleanly behind frame)
              Positioned(
                left: winLeft,
                top: winTop,
                width: winW,
                height: winH,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: _theme.reelColors,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.85),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        // 3D Curved Cylinder Drum Vignette
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x99000000),
                                    Color(0x22000000),
                                    Colors.transparent,
                                    Colors.transparent,
                                    Color(0x22000000),
                                    Color(0x99000000),
                                  ],
                                  stops: [0.0, 0.14, 0.28, 0.72, 0.86, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Safe Reel Grid Container (symbols, dividers, payline lasers)
              Positioned(
                left: gridLeft,
                top: gridTop,
                width: gridW,
                height: gridH,
                child: Stack(
                  children: [
                    // 5 Reel Strips
                    Row(
                      children: [
                        for (var r = 0; r < reels; r++)
                          Expanded(child: _reelStrip(r)),
                      ],
                    ),

                    // Horizontal grid dividers between rows (smooth fade at left & right)
                    for (var row = 1; row < rows; row++)
                      Positioned(
                        top: row * (gridH / rows) - 0.6,
                        left: 0,
                        right: 0,
                        height: 1.2,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.transparent,
                                  _theme.reelBorderColor.withValues(
                                    alpha: 0.15,
                                  ),
                                  _theme.reelBorderColor.withValues(
                                    alpha: 0.45,
                                  ),
                                  _theme.reelBorderColor.withValues(
                                    alpha: 0.45,
                                  ),
                                  _theme.reelBorderColor.withValues(
                                    alpha: 0.15,
                                  ),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.08, 0.20, 0.80, 0.92, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Vertical grid dividers between reels (smooth fade at top & bottom)
                    for (var r = 1; r < reels; r++)
                      Positioned(
                        left: r * (gridW / reels) - 0.6,
                        top: 0,
                        bottom: 0,
                        width: 1.2,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  _theme.reelBorderColor.withValues(
                                    alpha: 0.15,
                                  ),
                                  _theme.reelBorderColor.withValues(
                                    alpha: 0.70,
                                  ),
                                  _theme.reelBorderColor.withValues(
                                    alpha: 0.70,
                                  ),
                                  _theme.reelBorderColor.withValues(
                                    alpha: 0.15,
                                  ),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.08, 0.20, 0.80, 0.92, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Winning paylines laser overlay
                    if (_activeWins.isNotEmpty)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, _) => CustomPaint(
                              painter: PaylinePainter(
                                wins: _activeWins,
                                color: _theme.winGlowColor,
                                pulse: _pulseController.value,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 3. Ornate Frame Overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: Image.asset(_theme.frame, fit: BoxFit.fill),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _reelStrip(int r) {
    final settled = Column(
      children: [
        for (var row = 0; row < rows; row++)
          Expanded(
            child: _cell(_grid[r][row], _winCells.contains('${r}_$row')),
          ),
      ],
    );
    if (_stopped[r]) {
      return TweenAnimationBuilder<double>(
        key: ValueKey('settled-$r-${_pendingResult.hashCode}'),
        tween: Tween(begin: _spinning ? -5.0 : 0.0, end: 0),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        builder: (context, y, child) =>
            Transform.translate(offset: Offset(0, y), child: child),
        child: settled,
      );
    }
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellHeight = constraints.maxHeight / rows;
          return AnimatedBuilder(
            animation: _reelMotion,
            builder: (context, _) {
              final phase = MediaQuery.disableAnimationsOf(context)
                  ? 0.0
                  : _reelMotion.value;
              return Stack(
                children: [
                  for (var row = -1; row < rows; row++)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: (row + phase) * cellHeight,
                      height: cellHeight,
                      child: Padding(
                        padding: const EdgeInsets.all(7),
                        child: _symbolImage(
                          row == -1 ? _incoming[r] : _grid[r][row],
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _cell(Sym sym, bool isWin) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glow = _pulseController.value;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: isWin
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: _theme.winGlowColor.withValues(
                    alpha: 0.18 + glow * 0.14,
                  ),
                  border: Border.all(color: _theme.winGlowColor, width: 2.2),
                  boxShadow: [
                    BoxShadow(
                      color: _theme.winGlowColor.withValues(
                        alpha: 0.5 + glow * 0.4,
                      ),
                      blurRadius: 10 + glow * 8,
                      spreadRadius: 1.5,
                    ),
                  ],
                )
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white.withValues(alpha: 0.015),
                ),
          padding: const EdgeInsets.all(4),
          child: isWin
              ? Transform.scale(scale: 1.0 + glow * 0.10, child: child)
              : child,
        );
      },
      child: _symbolImage(sym),
    );
  }

  Widget _symbolImage(Sym sym) {
    return Image.asset(
      _theme.assetFor(sym),
      fit: BoxFit.contain,
      errorBuilder: (c, e, s) => _fallbackTile(_theme.labelFor(sym)),
    );
  }

  Widget _fallbackTile(String label) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8E24AA), Color(0xFF4A148C)],
            ),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: JuwaColors.gold, width: 1.5),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: JuwaColors.gold,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // PAYTABLE & RULES DIALOG
  // ==========================================
  void _showPaytable(BuildContext context) {
    _triggerHaptic();
    showDialog(
      context: context,
      builder: (ctx) => JuwaPopup(
        title: _theme.paytableTitle,
        maxWidth: 580,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Subtitle
            const Center(
              child: Text(
                'Payouts are multiplied by line bet. 5 paylines win left-to-right.',
                textAlign: TextAlign.center,
                style: TextStyle(color: JuwaColors.textDim, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),

            // Paytable grid
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2.2),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(1.2),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: JuwaColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      child: Text(
                        'SYMBOL',
                        style: TextStyle(
                          color: JuwaColors.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          '5x',
                          style: TextStyle(
                            color: JuwaColors.gold,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          '4x',
                          style: TextStyle(
                            color: JuwaColors.gold,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          '3x',
                          style: TextStyle(
                            color: JuwaColors.gold,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                for (final entry in _theme.payTable.entries)
                  _paytableRow(entry.key, entry.value),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 10),

            // Wild rule
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF381B57).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: JuwaColors.gold.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.stars_rounded, color: JuwaColors.gold, size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'WILD substitutes for all symbols. Highest win only paid per line.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TableRow _paytableRow(Sym sym, Map<int, int> pays) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Image.asset(
                  _theme.assetFor(sym),
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) =>
                      const Icon(Icons.stars, color: JuwaColors.gold, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _theme.labelFor(sym),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '${pays[5] ?? 0}x',
              style: const TextStyle(
                color: JuwaColors.gold,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '${pays[4] ?? 0}x',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '${pays[3] ?? 0}x',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for glowing laser paylines on winning combinations.
class PaylinePainter extends CustomPainter {
  final List<LineWin> wins;
  final Color color;
  final double pulse;

  const PaylinePainter({
    required this.wins,
    required this.color,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (wins.isEmpty) return;

    final cellW = size.width / reels;
    final cellH = size.height / rows;

    for (final w in wins) {
      if (w.line >= paylines.length) continue;
      final lineDef = paylines[w.line];
      final path = Path();

      for (var r = 0; r < w.count; r++) {
        final cx = r * cellW + cellW / 2;
        final cy = lineDef[r] * cellH + cellH / 2;
        if (r == 0) {
          path.moveTo(cx, cy);
        } else {
          path.lineTo(cx, cy);
        }
      }

      // Outer glow laser
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.45 + pulse * 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0 + pulse * 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);

      canvas.drawPath(path, glowPaint);

      // Core white laser line
      final corePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(path, corePaint);

      // Node sparkles at cell centers
      for (var r = 0; r < w.count; r++) {
        final cx = r * cellW + cellW / 2;
        final cy = lineDef[r] * cellH + cellH / 2;
        canvas.drawCircle(
          Offset(cx, cy),
          4.0 + pulse * 1.5,
          Paint()..color = color,
        );
        canvas.drawCircle(Offset(cx, cy), 2.0, Paint()..color = Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PaylinePainter oldDelegate) => true;
}
