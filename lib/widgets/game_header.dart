import 'package:flutter/material.dart';
import 'game_press.dart';
import 'package:flutter/services.dart';
import '../services/settings_service.dart';
import '../services/wallet_service.dart';
import '../theme.dart';
import '../util.dart';
import '../screens/popups.dart';
import 'top_bar.dart';

/// Reusable full-bleed casino game header HUD.
///
/// Features:
/// - Edge-to-edge dark luxury gradient scrim
/// - Safe area inset handling without double padding
/// - Left action cluster: Back button, Info/Help button, and live Sound toggle
/// - Centered Vegas game title plaque with gold stars and subtitle
/// - Right currency cluster: Animated Coins & Gems chips with '+' actions
/// - 3-zone balanced flex layout with [FittedBox] scaling to guarantee zero overflow
class GameHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final VoidCallback? onInfo;
  final bool showCurrencies;
  final List<Widget>? customActions;
  final Widget? customTrailing;
  final VoidCallback? onGetCoins;

  const GameHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.onInfo,
    this.showCurrencies = true,
    this.customActions,
    this.customTrailing,
    this.onGetCoins,
  });

  void _triggerHaptic() {
    if (SettingsService.instance.haptics) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).padding;
    final topPad = insets.top > 0 ? insets.top + 2 : 8.0;
    final wallet = WalletService.instance;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xE6080512), Color(0x99080512), Color(0x00080512)],
          stops: [0.0, 0.65, 1.0],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        12 + insets.left,
        topPad,
        12 + insets.right,
        6,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Wing: Navigation & Game Utilities
          Expanded(
            flex: 5,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HeaderCircleButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () {
                        _triggerHaptic();
                        if (onBack != null) {
                          onBack!();
                        } else {
                          Navigator.of(context).maybePop();
                        }
                      },
                    ),
                    if (onInfo != null) ...[
                      const SizedBox(width: 8),
                      HeaderCircleButton(
                        icon: Icons.help_outline_rounded,
                        onTap: () {
                          _triggerHaptic();
                          onInfo!();
                        },
                      ),
                    ],
                    if (customActions != null) ...[
                      const SizedBox(width: 8),
                      ...customActions!,
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Center: Vegas Marquee Plaque
          Expanded(
            flex: 6,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: TitlePlaque(title: title, subtitle: subtitle),
              ),
            ),
          ),

          // Right Wing: Currency Chips
          Expanded(
            flex: 5,
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child:
                    customTrailing ??
                    (showCurrencies
                        ? AnimatedBuilder(
                            animation: wallet,
                            builder: (context, _) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CurrencyPill(
                                  icon: 'assets/images/coin.png',
                                  value: formatCoins(wallet.coins),
                                  onPlus:
                                      onGetCoins ??
                                      () => showGetCoinsPopup(context),
                                ),
                                const SizedBox(width: 10),
                                CurrencyPill(
                                  icon: 'assets/images/gem.png',
                                  value: '${wallet.gems}',
                                  onPlus:
                                      onGetCoins ??
                                      () => showGetCoinsPopup(context),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable circular header button with gold bezel and amethyst glass fill.
class HeaderCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const HeaderCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return GamePress(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C203E), Color(0xFF140D20)],
          ),
          border: Border.all(
            color: JuwaColors.gold.withValues(alpha: 0.85),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: JuwaColors.gold.withValues(alpha: 0.15),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(icon, color: JuwaColors.gold, size: size * 0.52),
      ),
    );
  }
}

/// Vegas-styled title plaque with metallic gold text and stars.
class TitlePlaque extends StatelessWidget {
  final String title;
  final String? subtitle;

  const TitlePlaque({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 3.5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2B183E), Color(0xFF150A22), Color(0xFF09040E)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: JuwaColors.gold.withValues(alpha: 0.75),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: JuwaColors.gold.withValues(alpha: 0.18),
            blurRadius: 10,
            spreadRadius: -1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: JuwaColors.gold, size: 12),
              const SizedBox(width: 6),
              ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFF9DE),
                    JuwaColors.gold,
                    Color(0xFFB8860B),
                  ],
                ).createShader(r),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 4,
                        offset: Offset(0, 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.star, color: JuwaColors.gold, size: 12),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 1),
            Text(
              subtitle!,
              style: TextStyle(
                color: JuwaColors.textDim.withValues(alpha: 0.85),
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
