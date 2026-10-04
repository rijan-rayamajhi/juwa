import 'package:flutter/material.dart';
import 'game_press.dart';
import 'package:flutter/services.dart';
import '../services/settings_service.dart';
import '../theme.dart';
import '../util.dart';

/// Reusable casino bottom console deck / footer.
///
/// Features:
/// - Dark obsidian glass gradient panel with top gold hairline border
/// - Automatic safe area bottom padding
/// - Balanced 3-zone flex architecture:
///   - Left (flex 4): Bet Stepper & Max Bet Pill
///   - Center (flex 3): Glowing Win Marquee Display
///   - Right (flex 4): Auto Toggle & 3D Arcade Spin Button
/// - Each zone wrapped in [FittedBox] scaling to guarantee zero overflow on any device
class GameFooter extends StatelessWidget {
  final int bet;
  final ValueChanged<int>? onBetChange;
  final bool canDecreaseBet;
  final bool canIncreaseBet;
  final bool isMaxBet;
  final VoidCallback? onMaxBet;
  final int lastWin;
  final int? displayedWin;
  final bool isAuto;
  final VoidCallback? onToggleAuto;
  final bool isSpinning;
  final VoidCallback? onSpin;
  final String? spinLabel;
  final String betLabel;
  final Widget? customLeading;
  final Widget? customCenter;
  final Widget? customTrailing;

  const GameFooter({
    super.key,
    required this.bet,
    this.onBetChange,
    this.canDecreaseBet = true,
    this.canIncreaseBet = true,
    this.isMaxBet = false,
    this.onMaxBet,
    this.lastWin = 0,
    this.displayedWin,
    this.isAuto = false,
    this.onToggleAuto,
    this.isSpinning = false,
    this.onSpin,
    this.spinLabel,
    this.betLabel = 'TOTAL BET',
    this.customLeading,
    this.customCenter,
    this.customTrailing,
  });

  void _triggerHaptic() {
    if (SettingsService.instance.haptics) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).padding;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xE6140D22), Color(0xF50A0612), Color(0xFF040206)],
        ),
        border: Border(
          top: BorderSide(
            color: JuwaColors.gold.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        12 + insets.left,
        5,
        12 + insets.right,
        5 + insets.bottom * 0.5,
      ),
      child: SizedBox(
        height: 56,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Group: Bet controls + Max Bet
            Expanded(
              flex: 4,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child:
                      customLeading ??
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BetStepper(
                            bet: bet,
                            label: betLabel,
                            canMinus: !isSpinning && canDecreaseBet,
                            canPlus: !isSpinning && canIncreaseBet,
                            onMinus: () => onBetChange?.call(-1),
                            onPlus: () => onBetChange?.call(1),
                          ),
                          if (onMaxBet != null) ...[
                            const SizedBox(width: 8),
                            PillActionButton(
                              label: 'MAX BET',
                              icon: Icons.keyboard_double_arrow_up_rounded,
                              active: isMaxBet,
                              onTap: isSpinning
                                  ? null
                                  : () {
                                      _triggerHaptic();
                                      onMaxBet!();
                                    },
                            ),
                          ],
                        ],
                      ),
                ),
              ),
            ),

            // Center Group: WIN Display
            Expanded(
              flex: 3,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child:
                      customCenter ??
                      WinMarquee(
                        lastWin: lastWin,
                        displayedWin: displayedWin ?? lastWin,
                      ),
                ),
              ),
            ),

            // Right Group: Auto & Spin
            Expanded(
              flex: 4,
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child:
                      customTrailing ??
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onToggleAuto != null)
                            PillActionButton(
                              label: isAuto ? 'STOP' : 'AUTO',
                              icon: isAuto
                                  ? Icons.stop_rounded
                                  : Icons.autorenew_rounded,
                              active: isAuto,
                              isDanger: isAuto,
                              onTap: () {
                                _triggerHaptic();
                                onToggleAuto!();
                              },
                            ),
                          const SizedBox(width: 8),
                          ArcadeSpinButton(
                            isSpinning: isSpinning,
                            onTap: onSpin,
                            label: spinLabel,
                          ),
                        ],
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stepper control for adjusting bet levels.
class BetStepper extends StatelessWidget {
  final int bet;
  final String label;
  final bool canMinus;
  final bool canPlus;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const BetStepper({
    super.key,
    required this.bet,
    this.label = 'TOTAL BET',
    required this.canMinus,
    required this.canPlus,
    required this.onMinus,
    required this.onPlus,
  });

  void _triggerHaptic() {
    if (SettingsService.instance.haptics) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: JuwaColors.gold.withValues(alpha: 0.7),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _stepperBtn(
            icon: Icons.remove_rounded,
            enabled: canMinus,
            onTap: () {
              _triggerHaptic();
              onMinus();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: JuwaColors.textDim,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/coin.png',
                      width: 14,
                      height: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatCoins(bet),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _stepperBtn(
            icon: Icons.add_rounded,
            enabled: canPlus,
            onTap: () {
              _triggerHaptic();
              onPlus();
            },
          ),
        ],
      ),
    );
  }

  Widget _stepperBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GamePress(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.35,
        child: Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            gradient: JuwaColors.goldGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.black, size: 19),
        ),
      ),
    );
  }
}

/// Secondary action pill button (MAX BET, AUTO, etc.).
class PillActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final bool isDanger;
  final VoidCallback? onTap;

  const PillActionButton({
    super.key,
    required this.label,
    required this.icon,
    this.active = false,
    this.isDanger = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    Gradient bgGradient;
    Color borderColor;
    Color iconColor;
    Color textColor;

    if (active) {
      if (isDanger) {
        bgGradient = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE53935), Color(0xFFC62828), Color(0xFF8E0000)],
        );
        borderColor = const Color(0xFFFF8A80);
        iconColor = Colors.white;
        textColor = Colors.white;
      } else {
        bgGradient = JuwaColors.goldGradient;
        borderColor = Colors.white;
        iconColor = Colors.black;
        textColor = Colors.black;
      }
    } else {
      bgGradient = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF382352), Color(0xFF1E112E), Color(0xFF10071A)],
      );
      borderColor = JuwaColors.gold;
      iconColor = JuwaColors.gold;
      textColor = Colors.white;
    }

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: GamePress(
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: bgGradient,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1.3),
            boxShadow: [
              BoxShadow(
                color: active
                    ? (isDanger
                          ? const Color(0xFFD32F2F).withValues(alpha: 0.5)
                          : JuwaColors.gold.withValues(alpha: 0.4))
                    : Colors.black.withValues(alpha: 0.5),
                blurRadius: active ? 10 : 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 19, color: iconColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Marquee Win Badge with glowing aura and animated ticker value.
class WinMarquee extends StatelessWidget {
  final int lastWin;
  final int displayedWin;

  const WinMarquee({
    super.key,
    required this.lastWin,
    required this.displayedWin,
  });

  @override
  Widget build(BuildContext context) {
    final hasWin = lastWin > 0;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: hasWin
              ? [const Color(0xFF3D2307), const Color(0xFF1B0E02)]
              : [const Color(0xFF171120), const Color(0xFF0C0712)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasWin
              ? JuwaColors.gold
              : JuwaColors.gold.withValues(alpha: 0.4),
          width: hasWin ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: hasWin
                ? JuwaColors.gold.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.5),
            blurRadius: hasWin ? 10 : 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'WIN',
            style: TextStyle(
              color: JuwaColors.textDim,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 8),
          Image.asset('assets/images/coin.png', width: 19, height: 19),
          const SizedBox(width: 5),
          Text(
            hasWin ? '+${formatCoins(displayedWin)}' : '—',
            style: TextStyle(
              color: hasWin ? JuwaColors.gold : Colors.white60,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              shadows: hasWin
                  ? [const Shadow(color: JuwaColors.gold, blurRadius: 8)]
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// 3D Arcade Spin button with metallic bevel, glow, and loading spinner.
class ArcadeSpinButton extends StatelessWidget {
  final bool isSpinning;
  final VoidCallback? onTap;
  final String? label;

  const ArcadeSpinButton({
    super.key,
    required this.isSpinning,
    this.onTap,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GamePress(
      onTap: onTap,
      child: Container(
        height: 52,
        constraints: const BoxConstraints(minWidth: 120, maxWidth: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF7C6),
              Color(0xFFF5C24B),
              Color(0xFFD49410),
              Color(0xFF8C5803),
            ],
            stops: [0.0, 0.35, 0.7, 1.0],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFFDE7), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.65),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: JuwaColors.gold.withValues(alpha: 0.5),
              blurRadius: 14,
              spreadRadius: -2,
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: isSpinning
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Color(0xFF382302),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label ?? 'STOP',
                      style: const TextStyle(
                        color: Color(0xFF382302),
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                )
              : Text(
                  label ?? 'SPIN',
                  style: const TextStyle(
                    color: Color(0xFF382302),
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 2.2,
                    shadows: [
                      Shadow(
                        color: Color(0x77FFFFFF),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
