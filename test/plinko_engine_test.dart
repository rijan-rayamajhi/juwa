import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:juwa/games/plinko/plinko_config.dart';

void main() {
  test('bucketOf counts right moves and stays in range', () {
    final rng = Random(3);
    for (var i = 0; i < 1000; i++) {
      final b = bucketOf(dropPath(rng));
      expect(b, inInclusiveRange(0, plinkoRows));
    }
  });

  test('multipliers table matches bucket count', () {
    expect(plinkoMultipliers.length, plinkoRows + 1);
    expect(plinkoBucketColors.length, plinkoRows + 1);
  });

  test('payout equals round(bet*multiplier) and is never negative', () {
    for (var b = 0; b <= plinkoRows; b++) {
      final p = plinkoPayout(b, 100);
      expect(p, (100 * plinkoMultipliers[b]).round());
      expect(p, greaterThanOrEqualTo(0));
    }
  });

  test('center bucket is the low-pay bucket', () {
    final center = plinkoRows ~/ 2;
    for (var b = 0; b <= plinkoRows; b++) {
      expect(plinkoMultipliers[center], lessThanOrEqualTo(plinkoMultipliers[b]));
    }
  });
}
