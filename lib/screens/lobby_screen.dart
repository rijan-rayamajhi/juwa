import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import 'package:flutter/services.dart';
import '../widgets/top_bar.dart';
import '../theme.dart';
import '../services/settings_service.dart';
import '../games/slots/slot_screen.dart';
import '../games/slots/slot_theme.dart';
import '../games/wheel/wheel_screen.dart';
import '../games/plinko/plinko_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    AudioService.instance.enter(this, AudioScene.lobby);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    AudioService.instance.leave(this);
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerHaptic() {
    if (SettingsService.instance.haptics) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).padding;

    // The two premier arcade slot titles
    final games = [
      _GameItem(
        id: 'fortune777',
        title: 'FORTUNE 777',
        subtitle: '5 PAYLINES • 3×5',
        theme: fortuneTheme,
        thumb: fortuneTheme.thumb,
      ),
      _GameItem(
        id: 'fishhunter',
        title: 'FISH HUNTER',
        subtitle: '5 PAYLINES • 3×5',
        theme: fishTheme,
        thumb: fishTheme.thumb,
      ),
      _GameItem(
        id: 'vampirequeen',
        title: 'VAMPIRE QUEEN',
        subtitle: '5 PAYLINES • 3×5',
        theme: vampireTheme,
        thumb: vampireTheme.thumb,
      ),
      _GameItem(
        id: 'fortunewheel',
        title: 'FORTUNE WHEEL',
        subtitle: 'SPIN TO WIN',
        thumb: 'assets/images/wheel_thumb.png',
        builder: (_) => const WheelScreen(),
      ),
      _GameItem(
        id: 'plinko',
        title: 'PLINKO',
        subtitle: 'DROP & WIN',
        thumb: 'assets/images/plinko_thumb.png',
        builder: (_) => const PlinkoScreen(),
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/lobby_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.30),
                Colors.black.withValues(alpha: 0.10),
                Colors.black.withValues(alpha: 0.45),
              ],
            ),
          ),
          child: SafeArea(
            top: false,
            left: false,
            right: false,
            bottom: false,
            child: Column(
              children: [
                // Top HUD Bar (Avatar, Currencies, Logo, Bonus/Mail/Settings)
                const TopBar(),

                // Main Center Stage: Huge Arcade Game Cards
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final availH = constraints.maxHeight;
                      // Maximum vertical presence with authentic 2:3 card ratio
                      final cardH = (availH - 24).clamp(180.0, 310.0);
                      final cardW = cardH * (2 / 3);

                      return Center(
                        child: SizedBox(
                          height: cardH,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                              horizontal: 24 + insets.left * 0.7,
                            ),
                            itemCount: games.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 32),
                            itemBuilder: (context, idx) {
                              final game = games[idx];
                              return _LobbyGameCard(
                                game: game,
                                width: cardW,
                                height: cardH,
                                pulseAnim: _pulseController,
                                onTap: () {
                                  _triggerHaptic();
                                  AudioService.instance.play(GameSound.click);
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: game.destination,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 8 + insets.bottom * 0.5),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------
// DATA MODEL FOR LOBBY GAMES
// ------------------------------------------------------
class _GameItem {
  final String id;
  final String title;
  final String subtitle;
  final String thumb;
  final SlotTheme? theme; // slot games
  final WidgetBuilder? builder; // non-slot games (e.g. wheel)

  const _GameItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.thumb,
    this.theme,
    this.builder,
  }) : assert(theme != null || builder != null);

  WidgetBuilder get destination => builder ?? (_) => SlotScreen(theme: theme!);
}

// ------------------------------------------------------
// 3D ARCADE GAME CARD
// ------------------------------------------------------
class _LobbyGameCard extends StatefulWidget {
  final _GameItem game;
  final double width;
  final double height;
  final Animation<double> pulseAnim;
  final VoidCallback onTap;

  const _LobbyGameCard({
    required this.game,
    required this.width,
    required this.height,
    required this.pulseAnim,
    required this.onTap,
  });

  @override
  State<_LobbyGameCard> createState() => _LobbyGameCardState();
}

class _LobbyGameCardState extends State<_LobbyGameCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedBuilder(
          animation: widget.pulseAnim,
          builder: (context, child) {
            final glow = widget.pulseAnim.value;
            return Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Color.lerp(
                    JuwaColors.goldDark,
                    JuwaColors.gold,
                    glow,
                  )!,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.7),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: JuwaColors.gold.withValues(
                      alpha: 0.25 + glow * 0.22,
                    ),
                    blurRadius: 16 + glow * 8,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // High-Res Game Artwork
                    Image.asset(game.thumb, fit: BoxFit.cover),

                    // Ambient inner vignette
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.35),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.85),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),

                    // Bottom: Clean Title Ribbon
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.90),
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              game.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 6),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              game.subtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: JuwaColors.textDim,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
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
    );
  }
}
