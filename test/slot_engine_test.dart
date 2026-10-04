import 'package:flutter_test/flutter_test.dart';
import 'package:juwa/games/slots/slot_config.dart';
import 'package:juwa/games/slots/slot_engine.dart';

void main() {
  final engine = SlotEngine();

  List<List<Sym>> gridFromRows(List<List<Sym>> rowsList) {
    // rowsList is [row0(5), row1(5), row2(5)] -> convert to grid[reel][row].
    return List.generate(
        reels, (r) => [for (var row = 0; row < rows; row++) rowsList[row][r]]);
  }

  test('five sevens on middle line pays 5-of-a-kind', () {
    final grid = gridFromRows([
      [Sym.grape, Sym.grape, Sym.grape, Sym.grape, Sym.grape],
      [Sym.seven, Sym.seven, Sym.seven, Sym.seven, Sym.seven],
      [Sym.lemon, Sym.lemon, Sym.lemon, Sym.lemon, Sym.lemon],
    ]);
    final res = engine.evaluate(grid, 100); // perLine = 20
    final mid = res.wins.firstWhere((w) => w.line == 0);
    expect(mid.symbol, Sym.seven);
    expect(mid.count, 5);
    expect(mid.amount, payTable[Sym.seven]![5]! * 20);
  });

  test('wild substitutes to complete a line', () {
    final grid = gridFromRows([
      [Sym.grape, Sym.grape, Sym.grape, Sym.grape, Sym.grape],
      [Sym.bell, Sym.wild, Sym.bell, Sym.cherry, Sym.lemon],
      [Sym.lemon, Sym.lemon, Sym.lemon, Sym.lemon, Sym.lemon],
    ]);
    final res = engine.evaluate(grid, 100); // perLine=20
    final mid = res.wins.firstWhere((w) => w.line == 0);
    expect(mid.symbol, Sym.bell);
    expect(mid.count, 3); // bell, wild, bell
    expect(mid.amount, payTable[Sym.bell]![3]! * 20);
  });

  test('no matches pays zero', () {
    final grid = gridFromRows([
      [Sym.grape, Sym.lemon, Sym.grape, Sym.lemon, Sym.grape],
      [Sym.cherry, Sym.lemon, Sym.cherry, Sym.lemon, Sym.cherry],
      [Sym.bell, Sym.grape, Sym.bell, Sym.grape, Sym.bell],
    ]);
    final res = engine.evaluate(grid, 100);
    expect(res.totalWin, 0);
    expect(res.wins, isEmpty);
  });

  test('spin never returns negative or non-integer win', () {
    for (var i = 0; i < 500; i++) {
      final res = engine.spin(100);
      expect(res.totalWin, greaterThanOrEqualTo(0));
    }
  });
}
