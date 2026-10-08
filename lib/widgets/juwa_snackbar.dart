import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../theme.dart';

/// Luxury Juwa casino-themed snack bar banner.
///
/// Features:
/// - Beveled metallic gold gradient border
/// - Deep luxury casino obsidian/velvet interior
/// - Golden ambient aura glow and deep drop shadows
/// - Smart currency/badge icon detection (coins, gems, level up, mail)
/// - Stylized high-contrast arcade typography with glowing accents
/// - Centered floating pill layout perfectly sized for landscape arcade displays
class JuwaSnackBarBanner extends StatelessWidget {
  final String message;
  final Widget? icon;
  final VoidCallback? onDismiss;

  const JuwaSnackBarBanner({
    super.key,
    required this.message,
    this.icon,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 480,
          minWidth: 240,
        ),
        child: GestureDetector(
          onTap: onDismiss ?? () => ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar(),
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(1.5), // Metallic golden rim border
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFF9C4), // Golden rim highlight
                  Color(0xFFFFD54F), // Bright gold
                  Color(0xFFFFA000), // Rich amber
                  Color(0xFF8D5500), // Dark bronze bevel
                ],
                stops: [0.0, 0.25, 0.75, 1.0],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFC107).withValues(alpha: 0.35),
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.85),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF281C10), // Rich dark espresso/velvet
                    Color(0xFF140D07), // Deep obsidian
                  ],
                ),
                borderRadius: BorderRadius.circular(20.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Leading emblem/icon
                  _buildLeadingBadge(),
                  const SizedBox(width: 10),

                  // Formatted message text
                  Flexible(
                    child: Text.rich(
                      TextSpan(children: _buildSpans(message)),
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            blurRadius: 4,
                            offset: Offset(0, 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Trailing clear / close button
                  _buildTrailingClearButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingBadge() {
    if (icon != null) return icon!;

    final lower = message.toLowerCase();

    // Level up reward badge
    if (lower.contains('level up')) {
      return Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF59D), Color(0xFFFFB300), Color(0xFFFF8F00)],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x66FFC107),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(
          Icons.military_tech_rounded,
          size: 20,
          color: Color(0xFF3E2723),
        ),
      );
    }

    // Both coins and gems present
    if (lower.contains('coin') && lower.contains('gem')) {
      return SizedBox(
        width: 38,
        height: 28,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: 2,
              child: Image.asset(
                'assets/images/coin.png',
                width: 23,
                height: 23,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              right: 0,
              top: 3,
              child: Image.asset(
                'assets/images/gem.png',
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      );
    }

    // Coins only or refill
    if (lower.contains('coin') || lower.contains('refill')) {
      return Image.asset(
        'assets/images/coin.png',
        width: 26,
        height: 26,
        fit: BoxFit.contain,
      );
    }

    // Gems only
    if (lower.contains('gem')) {
      return Image.asset(
        'assets/images/gem.png',
        width: 25,
        height: 25,
        fit: BoxFit.contain,
      );
    }

    // Mail or gift
    if (lower.contains('mail') || lower.contains('gift')) {
      return Image.asset(
        'assets/images/mail.png',
        width: 26,
        height: 26,
        fit: BoxFit.contain,
      );
    }

    // Reset progress
    if (lower.contains('reset')) {
      return Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: JuwaColors.gold.withValues(alpha: 0.15),
          border: Border.all(color: JuwaColors.gold, width: 1),
        ),
        child: const Icon(
          Icons.restart_alt_rounded,
          size: 18,
          color: JuwaColors.gold,
        ),
      );
    }

    // Generic casino star
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: JuwaColors.gold.withValues(alpha: 0.18),
        border: Border.all(color: JuwaColors.gold, width: 1),
      ),
      child: const Icon(
        Icons.stars_rounded,
        size: 18,
        color: JuwaColors.gold,
      ),
    );
  }

  Widget _buildTrailingClearButton(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss ?? () => ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFFFD54F).withValues(alpha: 0.18),
          border: Border.all(
            color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
            width: 0.8,
          ),
        ),
        child: const Icon(
          Icons.close_rounded,
          size: 13,
          color: Color(0xFFFFD54F),
        ),
      ),
    );
  }

  List<InlineSpan> _buildSpans(String text) {
    final spans = <InlineSpan>[];
    final regex = RegExp(
      r'(LEVEL UP!?|\+[0-9,]+|[0-9]+,[0-9]+|[0-9]+(?=\s*(?:coins|gems))|\bcoins\b|\bgems\b|Claimed|Refilled|Exchanged)',
      caseSensitive: false,
    );

    int lastIndex = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ));
      }

      final matchedText = match.group(0)!;
      final lower = matchedText.toLowerCase();
      TextStyle style;

      if (lower.startsWith('level up')) {
        style = const TextStyle(
          color: Color(0xFFFFD54F),
          fontSize: 14.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        );
      } else if (lower == 'claimed' || lower == 'refilled' || lower == 'exchanged') {
        style = const TextStyle(
          color: Color(0xFFFFF9C4),
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        );
      } else if (lower == 'coins' || lower.contains('coins')) {
        style = const TextStyle(
          color: Color(0xFFFFD54F),
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
        );
      } else if (lower == 'gems' || lower.contains('gems')) {
        style = const TextStyle(
          color: Color(0xFF4FC3F7),
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
        );
      } else if (lower.startsWith('+') || RegExp(r'^[0-9,]+$').hasMatch(matchedText)) {
        final lookAhead = text.substring(match.end).toLowerCase();
        if (lookAhead.trimLeft().startsWith('gem')) {
          style = const TextStyle(
            color: Color(0xFF00E5FF),
            fontSize: 14,
            fontWeight: FontWeight.w900,
          );
        } else {
          style = const TextStyle(
            color: Color(0xFFFFE082),
            fontSize: 14,
            fontWeight: FontWeight.w900,
          );
        }
      } else {
        style = const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
        );
      }

      spans.add(TextSpan(text: matchedText, style: style));
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
      ));
    }

    return spans;
  }
}

/// Builds a floating, theme-consistent Juwa SnackBar.
/// Defaults to a bottom margin of 82.0 to float cleanly above game consoles.
SnackBar buildJuwaSnackBar({
  required String message,
  Widget? icon,
  Duration duration = const Duration(milliseconds: 2600),
  double bottomMargin = 82.0,
  VoidCallback? onDismiss,
}) {
  return SnackBar(
    content: JuwaSnackBarBanner(
      message: message,
      icon: icon,
      onDismiss: onDismiss,
    ),
    backgroundColor: Colors.transparent,
    elevation: 0,
    behavior: SnackBarBehavior.floating,
    padding: EdgeInsets.zero,
    margin: EdgeInsets.only(bottom: bottomMargin),
    duration: duration,
    dismissDirection: DismissDirection.horizontal,
  );
}

/// Displays a themed Juwa SnackBar in the given [BuildContext].
/// Automatically computes safe bottom margin so it clears bottom arcade footers cleanly.
void showJuwaSnackBar(
  BuildContext context,
  String message, {
  Widget? icon,
  GameSound? sound,
  Duration duration = const Duration(milliseconds: 2600),
  double? bottomMargin,
}) {
  if (sound != null) {
    AudioService.instance.play(sound);
  }
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final insets = MediaQuery.maybeOf(context)?.padding ?? EdgeInsets.zero;
  final effectiveBottom = bottomMargin ?? (80.0 + (insets.bottom * 0.5));
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(buildJuwaSnackBar(
      message: message,
      icon: icon,
      duration: duration,
      bottomMargin: effectiveBottom,
      onDismiss: () => messenger.hideCurrentSnackBar(),
    ));
}

/// Displays a themed Juwa SnackBar via a [ScaffoldMessengerState].
void showJuwaMessengerSnackBar(
  ScaffoldMessengerState? messenger,
  String message, {
  Widget? icon,
  GameSound? sound,
  Duration duration = const Duration(milliseconds: 3200),
  double bottomMargin = 82.0,
}) {
  if (messenger == null) return;
  if (sound != null) {
    AudioService.instance.play(sound);
  }
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(buildJuwaSnackBar(
      message: message,
      icon: icon,
      duration: duration,
      bottomMargin: bottomMargin,
      onDismiss: () => messenger.hideCurrentSnackBar(),
    ));
}
