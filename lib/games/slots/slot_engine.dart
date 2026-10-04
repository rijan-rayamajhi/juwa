import 'dart:math';
import 'slot_config.dart';

/// One winning payline.
class LineWin {
  final int line;
  final Sym symbol;
  final int count;
  final int amount;
  const LineWin(this.line, this.symbol, this.count, this.amount);
}

/// Outcome of a spin.
class SpinResult {
  final List<List<Sym>> grid; // grid[reel][row]
  final List<LineWin> wins;
  final int totalWin;
  const SpinResult(this.grid, this.wins, this.totalWin);
}

class SlotEngine {
  final Random _rng;
  final List<Sym> _weighted;
  final Map<Sym, Map<int, int>> _payTable;

  SlotEngine([
    Random? rng,
    Map<Sym, int>? weights,
    Map<Sym, Map<int, int>>? pays,
  ]) : _rng = rng ?? Random(),
       _weighted = _buildWeightedPool(weights ?? symbolWeights),
       _payTable = pays ?? payTable;

  static List<Sym> _buildWeightedPool(Map<Sym, int> weights) {
    final pool = <Sym>[];
    weights.forEach((sym, w) {
      for (var i = 0; i < w; i++) {
        pool.add(sym);
      }
    });
    return pool;
  }

  Sym _randomSymbol() => _weighted[_rng.nextInt(_weighted.length)];

  // ponytail: cells are independent weighted draws, not fixed reel strips —
  // fine for an offline social slot; swap to reel strips if RTP tuning matters.
  List<List<Sym>> _randomGrid() =>
      List.generate(reels, (_) => List.generate(rows, (_) => _randomSymbol()));

  SpinResult spin(int totalBet) {
    final grid = _randomGrid();
    return evaluate(grid, totalBet);
  }

  /// Pure evaluation of a grid — separated so it can be unit-tested.
  SpinResult evaluate(List<List<Sym>> grid, int totalBet) {
    final perLine = totalBet ~/ paylines.length;
    final wins = <LineWin>[];
    int total = 0;

    for (var l = 0; l < paylines.length; l++) {
      final cells = [for (var r = 0; r < reels; r++) grid[r][paylines[l][r]]];
      final win = _evalLine(l, cells, perLine);
      if (win != null) {
        wins.add(win);
        total += win.amount;
      }
    }
    return SpinResult(grid, wins, total);
  }

  LineWin? _evalLine(int line, List<Sym> cells, int perLine) {
    // Pay symbol = first non-wild; count consecutive matches (wild substitutes).
    Sym? paySym;
    for (final c in cells) {
      if (c != Sym.wild) {
        paySym = c;
        break;
      }
    }

    // All wild line.
    if (paySym == null) {
      final amt = (_payTable[Sym.wild]![reels] ?? 0) * perLine;
      return amt > 0 ? LineWin(line, Sym.wild, reels, amt) : null;
    }

    int symCount = 0;
    for (final c in cells) {
      if (c == paySym || c == Sym.wild) {
        symCount++;
      } else {
        break;
      }
    }

    int leadWild = 0;
    for (final c in cells) {
      if (c == Sym.wild) {
        leadWild++;
      } else {
        break;
      }
    }

    final symAmt = (_payTable[paySym]?[symCount] ?? 0) * perLine;
    final wildAmt = (_payTable[Sym.wild]?[leadWild] ?? 0) * perLine;

    if (symAmt >= wildAmt && symAmt > 0) {
      return LineWin(line, paySym, symCount, symAmt);
    }
    if (wildAmt > 0) {
      return LineWin(line, Sym.wild, leadWild, wildAmt);
    }
    return null;
  }
}
