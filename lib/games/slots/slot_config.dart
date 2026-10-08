/// Fortune 777 — 5x3 classic slot configuration.
enum Sym { seven, bar, bell, cherry, lemon, watermelon, grape, wild }

extension SymAsset on Sym {
  String get asset => 'assets/images/sym_$name.png';
}

/// Relative reel weights, tuned so ~20% of spins pay back more than the bet
/// (simulated; RTP ~74%). Grape-heavy reels make frequent small line wins.
const Map<Sym, int> symbolWeights = {
  Sym.wild: 4,
  Sym.seven: 2,
  Sym.bar: 3,
  Sym.bell: 4,
  Sym.cherry: 5,
  Sym.lemon: 6,
  Sym.watermelon: 6,
  Sym.grape: 16,
};

/// Payout multiplier of the per-line bet, keyed by match count (3, 4, 5).
const Map<Sym, Map<int, int>> payTable = {
  Sym.wild: {3: 15, 4: 50, 5: 200},
  Sym.seven: {3: 10, 4: 40, 5: 150},
  Sym.bar: {3: 6, 4: 20, 5: 80},
  Sym.bell: {3: 5, 4: 15, 5: 60},
  Sym.cherry: {3: 3, 4: 10, 5: 40},
  Sym.lemon: {3: 2, 4: 8, 5: 25},
  Sym.watermelon: {3: 2, 4: 8, 5: 25},
  Sym.grape: {3: 2, 4: 6, 5: 20},
};

const int reels = 5;
const int rows = 3;

/// 5 paylines, each giving the row index (0=top,1=mid,2=bottom) per reel.
const List<List<int>> paylines = [
  [1, 1, 1, 1, 1], // middle
  [0, 0, 0, 0, 0], // top
  [2, 2, 2, 2, 2], // bottom
  [0, 1, 2, 1, 0], // V
  [2, 1, 0, 1, 2], // ^
];

/// Bet levels (total per spin). Per-line bet = total / paylines.length.
const List<int> betLevels = [50, 100, 250, 500, 1000];
