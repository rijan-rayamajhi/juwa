import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme.dart';

/// One wedge on the Fortune Wheel.
class WheelSlice {
  final String label;
  final int multiplier; // payout = multiplier * bet (0 = lose)
  final int weight; // relative landing odds
  final Color color;
  const WheelSlice(this.label, this.multiplier, this.weight, this.color);

  bool get isJackpot => multiplier >= 50;
}

/// 8 wedges, clockwise from the top pointer. Low multipliers are common,
/// the jackpot is rare. Payout = multiplier * bet.
const List<WheelSlice> wheelSlices = [
  WheelSlice('x2', 2, 20, Color(0xFF7E3FF2)),
  WheelSlice('LOSE', 0, 28, Color(0xFF2A2233)),
  WheelSlice('x5', 5, 8, Color(0xFFE5304A)),
  WheelSlice('x1', 1, 26, Color(0xFF3F6FF2)),
  WheelSlice('x10', 10, 4, JuwaColors.goldDark),
  WheelSlice('x2', 2, 20, Color(0xFF7E3FF2)),
  WheelSlice('x1', 1, 26, Color(0xFF3F6FF2)),
  WheelSlice('x50', 50, 1, JuwaColors.gold),
];

/// Cost-per-spin levels (reuses the coin economy scale).
const List<int> wheelBets = [50, 100, 250, 500, 1000];

/// Weighted pick of the winning slice index. [rng] injectable for tests.
int pickSlice(Random rng) {
  final total = wheelSlices.fold<int>(0, (s, w) => s + w.weight);
  var roll = rng.nextInt(total);
  for (var i = 0; i < wheelSlices.length; i++) {
    roll -= wheelSlices[i].weight;
    if (roll < 0) return i;
  }
  return wheelSlices.length - 1; // unreachable
}

/// Pure payout for a landed slice — the money path, kept testable.
int wheelPayout(int sliceIndex, int bet) =>
    wheelSlices[sliceIndex].multiplier * bet;
