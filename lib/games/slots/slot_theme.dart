import 'package:flutter/material.dart';
import '../../theme.dart';
import 'slot_config.dart';

/// Per-game skin + math. Both games share the 5x3 / 5-line engine and enum
/// slots; a theme only swaps art, labels, weights and paytable.
class SlotTheme {
  final String title;
  final String subtitle;
  final String paytableTitle;
  final String background;
  final String frame;
  final String thumb;

  /// Frame image aspect + hollow-window rect (fractions of frame w/h).
  final double frameAspect;
  final double winL, winR, winT, winB;

  /// Safe inner reel grid bounds (fractions of frame w/h) where the 5x3 symbols live.
  /// Insets symbols away from ornate frame borders, corals, and crests.
  final double gridL, gridR, gridT, gridB;

  final Map<Sym, String> symbolAssets;
  final Map<Sym, String> symbolLabels;
  final Map<Sym, int> weights;
  final Map<Sym, Map<int, int>> payTable;

  // Theming additions for authentic casino atmosphere
  final List<Color> reelColors;
  final Color reelBorderColor;
  final Color winGlowColor;
  final String category;
  final String tag;
  final int jackpotAmount;

  const SlotTheme({
    required this.title,
    required this.subtitle,
    required this.paytableTitle,
    required this.background,
    required this.frame,
    required this.thumb,
    required this.frameAspect,
    required this.winL,
    required this.winR,
    required this.winT,
    required this.winB,
    double? gridL,
    double? gridR,
    double? gridT,
    double? gridB,
    required this.symbolAssets,
    required this.symbolLabels,
    required this.weights,
    required this.payTable,
    this.reelColors = const [
      Color(0xFF140D07),
      Color(0xFF26190E),
      Color(0xFF140D07),
    ],
    this.reelBorderColor = const Color(0x3DF5C24B),
    this.winGlowColor = JuwaColors.gold,
    this.category = 'SLOTS',
    this.tag = 'HOT 🔥',
    this.jackpotAmount = 248900,
  }) : gridL = gridL ?? winL,
       gridR = gridR ?? winR,
       gridT = gridT ?? winT,
       gridB = gridB ?? winB;

  String assetFor(Sym s) =>
      symbolAssets[s] ?? 'assets/images/sym_${s.name}.png';
  String labelFor(Sym s) => symbolLabels[s] ?? s.name.toUpperCase();
}

/// Fortune 777 — the original classic skin (values from slot_config.dart).
const fortuneTheme = SlotTheme(
  title: 'FORTUNE 777',
  subtitle: '5 PAYLINES • 3×5 REELS',
  paytableTitle: 'Fortune 777 Paytable',
  background: 'assets/images/slot_background.png',
  frame: 'assets/images/slot_frame.png',
  thumb: 'assets/images/fortune777_thumb.png',
  frameAspect: 1672 / 941,
  winL: 0.0999,
  winR: 0.8989,
  winT: 0.2150,
  winB: 0.7700,
  gridL: 0.1140,
  gridR: 0.8860,
  gridT: 0.2350,
  gridB: 0.7520,
  reelColors: [Color(0xFF150E07), Color(0xFF2B1B0E), Color(0xFF150E07)],
  reelBorderColor: Color(0x4DF5C24B),
  winGlowColor: JuwaColors.gold,
  category: 'SLOTS',
  tag: 'HOT 🔥',
  jackpotAmount: 248900,
  symbolAssets: {
    Sym.seven: 'assets/images/sym_seven.png',
    Sym.bar: 'assets/images/sym_bar.png',
    Sym.bell: 'assets/images/sym_bell.png',
    Sym.cherry: 'assets/images/sym_cherry.png',
    Sym.lemon: 'assets/images/sym_lemon.png',
    Sym.watermelon: 'assets/images/sym_watermelon.png',
    Sym.grape: 'assets/images/sym_grape.png',
    Sym.wild: 'assets/images/sym_wild.png',
  },
  symbolLabels: {},
  weights: symbolWeights,
  payTable: payTable,
);

/// Fish Hunter — underwater treasure skin. Reuses the 8 enum slots:
/// wild=Dragon, seven=Bonus chest, bar=Shark, bell=Goldfish,
/// cherry=Turtle, lemon=Pearl, watermelon=Puffer, grape=Clownfish.
const fishTheme = SlotTheme(
  title: 'FISH HUNTER',
  subtitle: '5 PAYLINES • 3×5 REELS',
  paytableTitle: 'Fish Hunter Paytable',
  background: 'assets/images/fish_background.png',
  frame: 'assets/images/fish_frame.png',
  thumb: 'assets/images/fishhunter_thumb.png',
  frameAspect: 1672 / 941,
  winL: 0.0694,
  winR: 0.9306,
  winT: 0.1700,
  winB: 0.8500,
  gridL: 0.1140,
  gridR: 0.8860,
  gridT: 0.2280,
  gridB: 0.7620,
  reelColors: [Color(0xFF031428), Color(0xFF072648), Color(0xFF021020)],
  reelBorderColor: Color(0x5500E5FF),
  winGlowColor: Color(0xFF00E5FF),
  category: 'FISH',
  tag: 'POPULAR ⭐',
  jackpotAmount: 185420,
  symbolAssets: {
    Sym.wild: 'assets/images/fish_sym_wild.png',
    Sym.seven: 'assets/images/fish_sym_scatter.png',
    Sym.bar: 'assets/images/fish_sym_shark.png',
    Sym.bell: 'assets/images/fish_sym_goldfish.png',
    Sym.cherry: 'assets/images/fish_sym_turtle.png',
    Sym.lemon: 'assets/images/fish_sym_pearl.png',
    Sym.watermelon: 'assets/images/fish_sym_puffer.png',
    Sym.grape: 'assets/images/fish_sym_clownfish.png',
  },
  symbolLabels: {
    Sym.wild: 'WILD',
    Sym.seven: 'BONUS',
    Sym.bar: 'SHARK',
    Sym.bell: 'GOLDFISH',
    Sym.cherry: 'TURTLE',
    Sym.lemon: 'PEARL',
    Sym.watermelon: 'PUFFER',
    Sym.grape: 'CLOWNFISH',
  },
  weights: {
    Sym.wild: 2,
    Sym.seven: 4,
    Sym.bar: 6,
    Sym.bell: 8,
    Sym.cherry: 12,
    Sym.lemon: 14,
    Sym.watermelon: 14,
    Sym.grape: 16,
  },
  payTable: {
    Sym.wild: {3: 15, 4: 50, 5: 200},
    Sym.seven: {3: 10, 4: 40, 5: 150},
    Sym.bar: {3: 6, 4: 20, 5: 80},
    Sym.bell: {3: 5, 4: 15, 5: 60},
    Sym.cherry: {3: 3, 4: 10, 5: 40},
    Sym.lemon: {3: 2, 4: 8, 5: 25},
    Sym.watermelon: {3: 2, 4: 8, 5: 25},
    Sym.grape: {3: 2, 4: 6, 5: 20},
  },
);

/// Vampire Queen — gothic castle skin. Reuses the 8 enum slots:
/// wild=Queen, seven=Bonus coffin, bar=Lord, bell=Wolf,
/// cherry=Bat, lemon=Ring, watermelon=Rose, grape=Candelabra.
const vampireTheme = SlotTheme(
  title: 'VAMPIRE QUEEN',
  subtitle: '5 PAYLINES • 3×5 REELS',
  paytableTitle: 'Vampire Queen Paytable',
  background: 'assets/images/vampire_background.png',
  frame: 'assets/images/vampire_frame.png',
  thumb: 'assets/images/vampirequeen_thumb.png',
  frameAspect: 1672 / 941,
  winL: 0.0740,
  winR: 0.9260,
  winT: 0.1800,
  winB: 0.8450,
  gridL: 0.1250,
  gridR: 0.8750,
  gridT: 0.2380,
  gridB: 0.7520,
  reelColors: [Color(0xFF160718), Color(0xFF2A0D2E), Color(0xFF120510)],
  reelBorderColor: Color(0x55E5304A),
  winGlowColor: Color(0xFFE5304A),
  category: 'SLOTS',
  tag: 'NEW 🦇',
  jackpotAmount: 266600,
  symbolAssets: {
    Sym.wild: 'assets/images/vampire_sym_wild.png',
    Sym.seven: 'assets/images/vampire_sym_scatter.png',
    Sym.bar: 'assets/images/vampire_sym_lord.png',
    Sym.bell: 'assets/images/vampire_sym_wolf.png',
    Sym.cherry: 'assets/images/vampire_sym_bat.png',
    Sym.lemon: 'assets/images/vampire_sym_ring.png',
    Sym.watermelon: 'assets/images/vampire_sym_rose.png',
    Sym.grape: 'assets/images/vampire_sym_candle.png',
  },
  symbolLabels: {
    Sym.wild: 'WILD',
    Sym.seven: 'BONUS',
    Sym.bar: 'LORD',
    Sym.bell: 'WOLF',
    Sym.cherry: 'BAT',
    Sym.lemon: 'RING',
    Sym.watermelon: 'ROSE',
    Sym.grape: 'CANDLE',
  },
  weights: {
    Sym.wild: 2,
    Sym.seven: 4,
    Sym.bar: 6,
    Sym.bell: 8,
    Sym.cherry: 12,
    Sym.lemon: 14,
    Sym.watermelon: 14,
    Sym.grape: 16,
  },
  payTable: {
    Sym.wild: {3: 15, 4: 50, 5: 200},
    Sym.seven: {3: 10, 4: 40, 5: 150},
    Sym.bar: {3: 6, 4: 20, 5: 80},
    Sym.bell: {3: 5, 4: 15, 5: 60},
    Sym.cherry: {3: 3, 4: 10, 5: 40},
    Sym.lemon: {3: 2, 4: 8, 5: 25},
    Sym.watermelon: {3: 2, 4: 8, 5: 25},
    Sym.grape: {3: 2, 4: 6, 5: 20},
  },
);
