import 'package:flutter/material.dart';
import '../services/real_money_service.dart';
import '../theme.dart';
import '../util.dart';
import 'juwa_popup.dart';

/// Luxury Big Win / Mega Win / Jackpot celebration modal dialog.
///
/// Features:
/// - Manual close button (X) and 'COLLECT & CONTINUE' button (no forced auto-dismiss)
/// - Prominent 'PLAY FOR REAL MONEY' action button redirecting to SpinnerLog
/// - Beveled metallic gold casino frame with radiant purple velvet backdrop
/// - Specular coin & trophy win counter with bold arcade typography
class BigWinCelebrationOverlay extends StatelessWidget {
  final String title;
  final int winAmount;
  final VoidCallback onClose;
  final VoidCallback? onPlayReal;

  const BigWinCelebrationOverlay({
    super.key,
    required this.title,
    required this.winAmount,
    required this.onClose,
    this.onPlayReal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      alignment: Alignment.center,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = (constraints.maxWidth - 32).clamp(240.0, 420.0);
          return SingleChildScrollView(
            child: Container(
              width: maxW,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFF9C4), // Golden rim
                Color(0xFFFFD54F),
                Color(0xFFFFA000),
                Color(0xFF8D5500),
              ],
              stops: [0.0, 0.28, 0.72, 1.0],
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
                blurRadius: 32,
                spreadRadius: 4,
              ),
              const BoxShadow(
                color: Colors.black,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(2.5),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2C103C), // Royal purple velvet
                  Color(0xFF14071C),
                ],
              ),
              borderRadius: BorderRadius.circular(23.5),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Corner Close Button (X)
                Positioned(
                  top: -6,
                  right: -6,
                  child: GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black54,
                        border: Border.all(
                          color: JuwaColors.gold.withValues(alpha: 0.7),
                          width: 1.2,
                        ),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glowing Crown / Trophy Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Color(0x66FFD54F), Colors.transparent],
                        ),
                      ),
                      child: const Icon(
                        Icons.military_tech_rounded,
                        color: Color(0xFFFFD54F),
                        size: 44,
                      ),
                    ),

                    // Title with gradient shimmer
                    ShaderMask(
                      shaderCallback: (r) => const LinearGradient(
                        colors: [
                          Color(0xFFFFFFFF),
                          Color(0xFFFFF9C4),
                          Color(0xFFFFD54F),
                          Color(0xFFFF8F00),
                        ],
                      ).createShader(r),
                      child: Text(
                        title.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.2,
                          shadows: [
                            Shadow(color: Colors.black, blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Win Payout
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E1C0A), Color(0xFF120B04)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFFD54F).withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/coin.png',
                            width: 26,
                            height: 26,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+${formatCoins(winAmount)}',
                            style: const TextStyle(
                              color: Color(0xFFFFD54F),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // REAL MONEY High-Stakes CTA Card
                    GestureDetector(
                      onTap: () {
                        if (onPlayReal != null) {
                          onPlayReal!();
                        } else {
                          launchRealMoneyPortal(context);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF69F0AE), // Emerald neon
                              Color(0xFFFFD54F), // Gold shine
                              Color(0xFF00C853),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E676)
                                  .withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF143419), Color(0xFF0B1F0E)],
                            ),
                            borderRadius: BorderRadius.circular(14.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.monetization_on_rounded,
                                color: Color(0xFFFFD54F),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Text(
                                      'PLAY WITH REAL MONEY',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Color(0xFFFFD54F),
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      'Cash out real jackpots on SpinnerLog',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Color(0xFFB9F6CA),
                                        fontSize: 9.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF00E676),
                                      Color(0xFF1B5E20),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'PLAY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Manual Continue Button
                    JuwaButton(
                      label: 'Collect & Continue',
                      icon: Icons.check_circle_outline_rounded,
                      onTap: onClose,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  ),
);
  }
}
