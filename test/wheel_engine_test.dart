import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:juwa/games/wheel/wheel_config.dart';

void main() {
  test('pickSlice always returns a valid index', () {
    final rng = Random(1);
    for (var i = 0; i < 1000; i++) {
      final idx = pickSlice(rng);
      expect(idx, inInclusiveRange(0, wheelSlices.length - 1));
    }
  });

  test('payout equals multiplier times bet and is never negative', () {
    for (var i = 0; i < wheelSlices.length; i++) {
      final p = wheelPayout(i, 100);
      expect(p, wheelSlices[i].multiplier * 100);
      expect(p, greaterThanOrEqualTo(0));
    }
  });

  test('LOSE wedge pays zero', () {
    final lose = wheelSlices.indexWhere((s) => s.multiplier == 0);
    expect(wheelPayout(lose, 500), 0);
  });
}
