import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme.dart';

/// Eight rows of pegs and nine payout buckets. Live drops use PlinkoPhysics.
const int plinkoRows = 8;

/// Multiplier per bucket, left→right. Symmetric, edges pay big; only the
/// outer two buckets each side profit (~17% of live physics drops).
const List<double> plinkoMultipliers = [50, 10, 1, 1, 0.5, 1, 1, 10, 50];

const List<int> plinkoBets = [50, 100, 250, 500, 1000];

/// Bucket colors, left→right (edges gold = jackpot).
const List<Color> plinkoBucketColors = [
  JuwaColors.gold,
  Color(0xFFE5304A),
  Color(0xFF7E3FF2),
  Color(0xFF3F6FF2),
  Color(0xFF2A2233),
  Color(0xFF3F6FF2),
  Color(0xFF7E3FF2),
  Color(0xFFE5304A),
  JuwaColors.gold,
];

/// Random drop path: `true` = right at each row. Length == [plinkoRows].
List<bool> dropPath(Random rng) =>
    List.generate(plinkoRows, (_) => rng.nextBool());

/// Landing bucket index (0..plinkoRows) = number of right moves.
int bucketOf(List<bool> path) => path.where((r) => r).length;

/// Pure payout for a landed bucket — the money path, kept testable.
int plinkoPayout(int bucket, int bet) =>
    (bet * plinkoMultipliers[bucket]).round();
