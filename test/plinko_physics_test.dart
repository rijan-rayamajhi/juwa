import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:juwa/games/plinko/plinko_physics.dart';

void main() {
  test('gravity accelerates smoothly before the first collision', () {
    final physics = PlinkoPhysics(random: Random(7));
    final ball = physics.launch(100);
    final start = ball.y;
    physics.advance(.05);
    final firstDistance = ball.y - start;
    final speed = ball.vy;
    physics.advance(.05);
    expect(ball.y - start - firstDistance, greaterThan(firstDistance));
    expect(ball.vy, greaterThan(speed));
    expect(ball.vy, closeTo(PlinkoPhysics.gravity * .1, .001));
  });

  test('fixed steps produce identical outcomes at different frame rates', () {
    final a = PlinkoPhysics(random: Random(12));
    final b = PlinkoPhysics(random: Random(12));
    final aa = a.launch(100);
    final bb = b.launch(100);
    for (var i = 0; i < 240; i++) {
      a.advance(1 / 60);
    }
    for (var i = 0; i < 120; i++) {
      b.advance(1 / 30);
    }
    expect(aa.x, closeTo(bb.x, .0001));
    expect(aa.y, closeTo(bb.y, .0001));
    expect(aa.bucket, bb.bucket);
  });

  test('1000 releases settle, stay contained and spread to both sides', () {
    final physics = PlinkoPhysics(random: Random(42));
    final histogram = List.filled(9, 0);
    for (var i = 0; i < 1000; i++) {
      final ball = physics.launch(100);
      for (var frame = 0; frame < 1200 && ball.bucket == null; frame++) {
        physics.advance(1 / 60);
        expect(ball.x, inInclusiveRange(9, 891));
        expect(ball.x.isFinite && ball.y.isFinite, isTrue);
      }
      expect(ball.bucket, isNotNull, reason: 'Release $i stalled');
      histogram[ball.bucket!]++;
      expect(
        physics.advance(.1),
        isEmpty,
        reason: 'A ball must land only once',
      );
    }
    final left = histogram.take(4).reduce((a, b) => a + b);
    final right = histogram.skip(5).reduce((a, b) => a + b);
    expect(left, greaterThan(100));
    expect(right, greaterThan(100));
    expect((left - right).abs(), lessThan(120));
    // Useful distribution evidence, not a prescribed payout distribution.
    // ignore: avoid_print
    print('Physics landing counts: $histogram');
  });

  test('rapid drops never leave balls overlapping each other', () {
    final physics = PlinkoPhysics(random: Random(7));
    for (var i = 0; i < 10; i++) {
      physics.launch(100); // ten taps in the same frame
    }
    var maxOverlap = 0.0;
    for (var f = 0; f < 600 && physics.balls.isNotEmpty; f++) {
      physics.advance(1 / 120);
      expect(physics.alpha, inInclusiveRange(0, 1));
      final b = physics.balls;
      for (var i = 0; i < b.length; i++) {
        for (var j = i + 1; j < b.length; j++) {
          final d = sqrt(pow(b[i].x - b[j].x, 2) + pow(b[i].y - b[j].y, 2));
          maxOverlap = max(maxOverlap, PlinkoPhysics.ballRadius * 2 - d);
        }
      }
    }
    expect(physics.balls, isEmpty, reason: 'all balls land');
    // Resolved every step; allow a sliver where a peg pushes back.
    expect(maxOverlap, lessThan(PlinkoPhysics.ballRadius));
  });
}
