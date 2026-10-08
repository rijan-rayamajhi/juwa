import 'package:flutter/material.dart';
import 'game_press.dart';
import 'package:flutter/services.dart';
import '../services/wallet_service.dart';
import '../services/settings_service.dart';
import '../theme.dart';
import '../util.dart';
import '../screens/popups.dart';

import '../services/real_money_service.dart';

/// Lobby top bar: VIP avatar + currencies (left), centered Juwa logo (center),
/// and menu/utility icons with active notification badges (right).
class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = WalletService.instance;
    final insets = MediaQuery.of(context).padding;
    final topInset = insets.top;

    return AnimatedBuilder(
      animation: wallet,
      builder: (context, _) => Container(
        padding: EdgeInsets.fromLTRB(
          14 + insets.left,
          topInset > 0 ? topInset + 4 : 8,
          14 + insets.right,
          6,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xF0080512), Color(0x99080512), Color(0x00080512)],
            stops: [0.0, 0.65, 1.0],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ---- Left: VIP Avatar + Currencies ----
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
                      _PlayerAvatar(onTap: () => showProfilePopup(context)),
                      const SizedBox(width: 12),
                      CurrencyPill(
                        icon: 'assets/images/coin.png',
                        value: formatCoins(wallet.coins),
                        onPlus: () => showGetCoinsPopup(context),
                      ),
                      const SizedBox(width: 8),
                      CurrencyPill(
                        icon: 'assets/images/gem.png',
                        value: '${wallet.gems}',
                        onPlus: () => showGetCoinsPopup(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ---- Center: Centered Juwa Logo ----
            Expanded(
              flex: 4,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 52),
                    child: Image.asset(
                      'assets/images/juwa_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),

            // ---- Right: Action & Utility Icons ----
            Expanded(
              flex: 5,
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Real Money Action Button
                      const RealCashTopPill(),
                      const SizedBox(width: 8),
                      _LobbyIconButton(
                        asset: 'assets/images/bonus.png',
                        tooltip: 'Daily Bonus',
                        badge: wallet.bonusReady,
                        onTap: () => showGetCoinsPopup(context),
                      ),
                      const SizedBox(width: 6),
                      _LobbyIconButton(
                        asset: 'assets/images/mail.png',
                        tooltip: 'Mailbox',
                        badge: wallet.mail.isNotEmpty,
                        onTap: () => showMailPopup(context),
                      ),
                      const SizedBox(width: 6),
                      _LobbyIconButton(
                        asset: 'assets/images/settings.png',
                        tooltip: 'Settings',
                        onTap: () => showSettingsPopup(context),
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

/// Glowing casino pill button for Real Cash / Real Money play.
class RealCashTopPill extends StatelessWidget {
  const RealCashTopPill({super.key});

  @override
  Widget build(BuildContext context) {
    return GamePress(
      onTap: () => launchRealMoneyPortal(context),
      child: Container(
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFF59D), // Gold highlight
              Color(0xFFFFD54F),
              Color(0xFFFF8F00),
              Color(0xFF43A047), // Emerald neon
            ],
            stops: [0.0, 0.35, 0.7, 1.0],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF43A047).withValues(alpha: 0.55),
              blurRadius: 8,
              spreadRadius: 1.0,
            ),
            const BoxShadow(
              color: Colors.black54,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1B5E20), // Casino Emerald Green
                Color(0xFF003300),
              ],
            ),
            borderRadius: BorderRadius.circular(18.5),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.monetization_on_rounded,
                color: Color(0xFFFFD54F),
                size: 14,
              ),
              SizedBox(width: 4),
              Text(
                'PLAY REAL',
                style: TextStyle(
                  color: Color(0xFFFFF9C4),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  shadows: [
                    Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// VIP Player avatar with metallic gold ring and VIP badge.
class _PlayerAvatar extends StatelessWidget {
  final VoidCallback onTap;
  const _PlayerAvatar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GamePress(
      onTap: () {
        if (SettingsService.instance.haptics) {
          HapticFeedback.lightImpact();
        }
        onTap();
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: JuwaColors.goldGradient,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: JuwaColors.gold.withValues(alpha: 0.3),
                  blurRadius: 6,
                ),
              ],
            ),
            padding: const EdgeInsets.all(2.0),
            child: ClipOval(
              child: Image.asset(
                'assets/images/avatar_default.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            bottom: -3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B1D59), Color(0xFF1B0B2E)],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: JuwaColors.gold, width: 1),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 3),
                ],
              ),
              child: Text(
                'LV ${WalletService.instance.level}',
                style: const TextStyle(
                  color: JuwaColors.gold,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CurrencyPill extends StatelessWidget {
  final String icon;
  final String value;
  final VoidCallback onPlus;
  const CurrencyPill({
    super.key,
    required this.icon,
    required this.value,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.centerLeft,
      children: [
        _pill(),
        Positioned(left: -4, child: _CurrencyIcon(icon)),
      ],
    );
  }

  Widget _pill() {
    return Container(
      // Gold gradient border via an outer gradient container.
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        gradient: JuwaColors.goldGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.only(left: 28, right: 4),
        constraints: const BoxConstraints(minWidth: 76),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A2118), Color(0xFF0E0B07)],
          ),
          borderRadius: BorderRadius.circular(21),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFFFDF3C0),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                shadows: [Shadow(color: Colors.black, blurRadius: 3)],
              ),
            ),
            const SizedBox(width: 6),
            _PlusButton(onTap: onPlus),
          ],
        ),
      ),
    );
  }
}

/// Oversized currency icon that overlaps the left edge of the pill.
class _CurrencyIcon extends StatelessWidget {
  final String icon;
  const _CurrencyIcon(this.icon);
  @override
  Widget build(BuildContext context) =>
      Image.asset(icon, width: 28, height: 28);
}

class _PlusButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PlusButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GamePress(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            center: Alignment(-0.3, -0.4),
            radius: 1.0,
            colors: [Color(0xFFFDF3B8), JuwaColors.gold, Color(0xFF9A6B00)],
          ),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF6B4E00), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 3,
            ),
          ],
        ),
        padding: const EdgeInsets.all(3),
        child: const Icon(Icons.add, color: Color(0xFF3A2800), size: 16),
      ),
    );
  }
}

class _LobbyIconButton extends StatelessWidget {
  final String asset;
  final VoidCallback onTap;
  final bool badge;
  final String? tooltip;

  const _LobbyIconButton({
    required this.asset,
    required this.onTap,
    this.badge = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return GamePress(
      onTap: () {
        if (SettingsService.instance.haptics) {
          HapticFeedback.lightImpact();
        }
        onTap();
      },
      child: Tooltip(
        message: tooltip ?? '',
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
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
              padding: const EdgeInsets.all(6),
              child: Image.asset(asset, fit: BoxFit.contain),
            ),
            if (badge)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53935).withValues(alpha: 0.6),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
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
