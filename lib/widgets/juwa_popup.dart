import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import 'package:flutter/services.dart';
import '../services/settings_service.dart';
import '../theme.dart';

/// Production-ready luxury casino popup dialog.
///
/// Features:
/// - Adaptive multi-layer casino frame (zero-distortion at any aspect ratio)
/// - Metallic gold beveled rim with ambient golden glow
/// - Royal casino purple velvet interior with radial spotlight
/// - Perimeter casino bulb/rivet lights with glowing halo
/// - Centered diamond amethyst jewel crown with specular star glint
/// - 3D tactile close button (`assets/images/close.png`) with spring press feedback
/// - Regal title plaque with embossed metallic typography
/// - Recessed inner velvet card panel for crisp content contrast
/// - Smooth modal entrance scale & bounce transition
class JuwaPopup extends StatefulWidget {
  final String title;
  final Widget child;
  final double maxWidth;
  final String? subtitle;

  const JuwaPopup({
    super.key,
    required this.title,
    required this.child,
    this.maxWidth = 520,
    this.subtitle,
  });

  @override
  State<JuwaPopup> createState() => _JuwaPopupState();
}

class _JuwaPopupState extends State<JuwaPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _entranceAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _scaleAnim = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(parent: _entranceAnim, curve: Curves.easeOutBack),
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entranceAnim, curve: Curves.easeOut));
    _entranceAnim.forward();
  }

  @override
  void dispose() {
    _entranceAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final availH = mq.size.height - mq.viewInsets.bottom - 24;
    final availW = mq.size.width - 24;
    final effectiveMaxWidth = math.min(widget.maxWidth, availW);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      // Square: Dialog's default rounded shape also clips hit-testing, so
      // taps on the corner close button fell through to the barrier.
      shape: const RoundedRectangleBorder(),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: AnimatedBuilder(
        animation: _entranceAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: Opacity(opacity: _fadeAnim.value, child: child),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: effectiveMaxWidth,
            maxHeight: availH,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Outer atmospheric halo & metallic beveled frame. The padding
              // keeps the close button inside the Stack: Flutter only
              // hit-tests within bounds, so an overhanging button's outer
              // half fell through to the barrier and dismissed silently.
              Padding(
                padding: const EdgeInsets.only(top: 10, right: 8),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      // Deep outer ambient gold halo
                      BoxShadow(
                        color: JuwaColors.gold.withValues(alpha: 0.30),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                      // Drop shadow for 3D elevation
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.85),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: const _CasinoFramePainter(),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const RadialGradient(
                          center: Alignment(0, -0.4),
                          radius: 1.25,
                          colors: [
                            Color(0xFF320958), // Rich royal purple highlight
                            Color(0xFF1B0332), // Deep purple velvet
                            Color(0xFF0C0118), // Dark casino shadow edge
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 26, 16, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PopupHeader(
                            title: widget.title,
                            subtitle: widget.subtitle,
                          ),
                          const SizedBox(height: 10),
                          // Inner recessed card panel for crisp contrast
                          Flexible(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.38),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: JuwaColors.gold.withValues(
                                    alpha: 0.22,
                                  ),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: widget.child,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Centered top crown diamond gem
              Positioned(
                top: -4,
                child: IgnorePointer(child: _TopDiamondCrown()),
              ),

              // 3D tactile close button docked on top-right
              Positioned(
                top: 0,
                right: 0,
                child: JuwaCloseButton(
                  onTap: () {
                    // A second tap during the exit animation must not pop
                    // the screen underneath.
                    if (ModalRoute.of(context)?.isCurrent ?? false) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the luxury multi-layered metallic gold frame & rivets.
class _CasinoFramePainter extends CustomPainter {
  const _CasinoFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final outerRect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(outerRect, const Radius.circular(22));

    // Outer 3D Metallic Gold Bevel Stroke
    final outerBevelPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFF9D0), // Specular light highlight
          Color(0xFFFFD700), // Pure casino gold
          Color(0xFFC98D00), // Warm amber gold
          Color(0xFF7A4800), // Deep bronze shadow
          Color(0xFFFFE58A), // Bottom rim bounce highlight
        ],
        stops: [0.0, 0.25, 0.55, 0.85, 1.0],
      ).createShader(outerRect);
    canvas.drawRRect(rrect, outerBevelPaint);

    // Inner fine gold accent line
    final innerRRect = rrect.deflate(5.0);
    final innerLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = JuwaColors.gold.withValues(alpha: 0.45);
    canvas.drawRRect(innerRRect, innerLinePaint);

    // Casino Light Rivets along perimeter
    _drawRivets(canvas, size);
  }

  void _drawRivets(Canvas canvas, Size size) {
    const rivetRadius = 2.6;
    final rivetFill = Paint()
      ..shader = const RadialGradient(
        colors: [Colors.white, Color(0xFFFFE890), Color(0xFFFFA000)],
        stops: [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: rivetRadius));

    final rivetGlow = Paint()
      ..color = const Color(0xFFFFB300).withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // Determine rivet positions along the top, bottom, and side rails
    const inset = 3.0;
    final w = size.width;
    final h = size.height;

    final positions = <Offset>[];

    // Corner rivet pairs
    positions.add(const Offset(32, inset));
    positions.add(Offset(w - 32, inset));
    positions.add(Offset(32, h - inset));
    positions.add(Offset(w - 32, h - inset));

    // Horizontal rail rivets
    if (w > 260) {
      final stepX = (w - 180) / 4;
      for (var i = 1; i <= 3; i++) {
        // Skip rivets directly behind top diamond crown
        if ((90 + stepX * i - w / 2).abs() > 45) {
          positions.add(Offset(90 + stepX * i, inset));
        }
        positions.add(Offset(90 + stepX * i, h - inset));
      }
    }

    // Vertical rail rivets
    if (h > 180) {
      final stepY = (h - 80) / 3;
      for (var i = 1; i <= 2; i++) {
        positions.add(Offset(inset, 40 + stepY * i));
        positions.add(Offset(w - inset, 40 + stepY * i));
      }
    }

    for (final pos in positions) {
      canvas.drawCircle(pos, rivetRadius + 1.2, rivetGlow);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.drawCircle(Offset.zero, rivetRadius, rivetFill);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Ornate diamond crown centerpiece at the top of the frame.
class _TopDiamondCrown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: JuwaColors.gold.withValues(alpha: 0.4),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Gold diamond bezel
            Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFFAD6),
                      Color(0xFFFFD700),
                      Color(0xFF8E5900),
                      Color(0xFFFFE082),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            // Purple amethyst gem interior
            Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    center: Alignment(-0.3, -0.3),
                    radius: 0.9,
                    colors: [
                      Color(0xFFF396FF), // Specular jewel highlight
                      Color(0xFFA625DB), // Pure vibrant amethyst
                      Color(0xFF4C026F), // Deep purple shadow
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Center sparkle glint
            const Text(
              '✦',
              style: TextStyle(
                color: Color(0xFFFFF0FF),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Color(0xFFE040FB), blurRadius: 4)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ornate header plaque with shimmering gradient typography.
class _PopupHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _PopupHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _GoldWing(isLeft: true),
            const SizedBox(width: 8),
            Flexible(
              child: ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFFDE8),
                    Color(0xFFFFE082),
                    JuwaColors.gold,
                    Color(0xFFB57E00),
                  ],
                  stops: [0.0, 0.35, 0.70, 1.0],
                ).createShader(r),
                child: Text(
                  title.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const _GoldWing(isLeft: false),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: JuwaColors.textDim,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 6),
        // Gold ornamental divider
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Expanded(child: _GoldRule(alignEnd: true)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(width: 5, height: 5, color: JuwaColors.gold),
              ),
            ),
            const Expanded(child: _GoldRule(alignEnd: false)),
          ],
        ),
      ],
    );
  }
}

/// Shimmering tapered wing ornament flanking the title.
class _GoldWing extends StatelessWidget {
  final bool isLeft;
  const _GoldWing({required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: isLeft
          ? const [
              Text('✦', style: TextStyle(color: JuwaColors.gold, fontSize: 9)),
              SizedBox(width: 3),
              Text(
                '✦',
                style: TextStyle(color: Color(0xFFFFE082), fontSize: 13),
              ),
            ]
          : const [
              Text(
                '✦',
                style: TextStyle(color: Color(0xFFFFE082), fontSize: 13),
              ),
              SizedBox(width: 3),
              Text('✦', style: TextStyle(color: JuwaColors.gold, fontSize: 9)),
            ],
    );
  }
}

class _GoldRule extends StatelessWidget {
  final bool alignEnd;
  const _GoldRule({required this.alignEnd});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.5,
      constraints: const BoxConstraints(maxWidth: 80),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: alignEnd ? Alignment.centerLeft : Alignment.centerRight,
          end: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
          colors: [
            JuwaColors.gold.withValues(alpha: 0),
            JuwaColors.gold.withValues(alpha: 0.8),
          ],
        ),
      ),
    );
  }
}

/// 3D luxury close button using assets/images/close.png with tactile spring feedback.
class JuwaCloseButton extends StatefulWidget {
  final VoidCallback onTap;
  final double size;

  const JuwaCloseButton({super.key, required this.onTap, this.size = 44});

  @override
  State<JuwaCloseButton> createState() => _JuwaCloseButtonState();
}

class _JuwaCloseButtonState extends State<JuwaCloseButton> {
  bool _pressed = false;

  void _handleTap() {
    if (SettingsService.instance.haptics) {
      HapticFeedback.lightImpact();
    }
    AudioService.instance.play(GameSound.click);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _handleTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeInOut,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.65),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: JuwaColors.gold.withValues(alpha: 0.25),
                blurRadius: 6,
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/close.png',
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

/// 3D tactile arcade gold button used inside popups.
class JuwaButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final double? width;

  const JuwaButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.width,
  });

  @override
  State<JuwaButton> createState() => _JuwaButtonState();
}

class _JuwaButtonState extends State<JuwaButton> {
  bool _pressed = false;

  void _handleTap() {
    if (widget.onTap == null) return;
    if (SettingsService.instance.haptics) {
      HapticFeedback.lightImpact();
    }
    AudioService.instance.play(GameSound.click);
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled
            ? (_) {
                setState(() => _pressed = false);
                _handleTap();
              }
            : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: Container(
            width: widget.width,
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 11),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFF4B0), // Golden rim highlight
                  Color(0xFFFFD54F), // Bright gold
                  Color(0xFFFFA000), // Rich amber body
                  Color(0xFF8D5500), // Dark bronze bevel
                ],
                stops: [0.0, 0.28, 0.72, 1.0],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFFFF9C4), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: JuwaColors.gold.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 18, color: const Color(0xFF2A1500)),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.label.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF281400),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(color: Color(0x66FFFFFF), offset: Offset(0, 1)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
