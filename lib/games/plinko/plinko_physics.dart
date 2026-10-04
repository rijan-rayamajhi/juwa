import 'dart:math';
import 'dart:ui';

/// Physics and rendering share this fixed board, scaled uniformly by the view.
class PlinkoPhysics {
  static const width = 900.0;
  static const height = 620.0;
  static const bucketY = 568.0;
  static const ballRadius = 9.0;
  static const pegRadius = 6.0;
  static const stepSeconds = 1 / 240;
  static const gravity = 1050.0;
  static final pegs = [
    for (var row = 0; row < 8; row++)
      for (var col = 0; col <= row; col++)
        Offset(450 + (col * 2 - row) * 50, 100 + row * 60),
  ];

  final Random random;
  final List<PlinkoBall> balls = [];
  final Map<int, double> pegFlashes = {};
  final Map<int, double> bucketFlashes = {};
  double _accumulator = 0;
  int _nextId = 0;
  int impactCount = 0;

  PlinkoPhysics({Random? random}) : random = random ?? Random();

  /// Fraction of a step not yet simulated; render at prev→current by this
  /// so motion stays smooth when frame and step rates don't line up.
  double get alpha => _accumulator / stepSeconds;

  PlinkoBall launch(int bet) {
    // Variation is only in the release, never a scripted choice at each peg.
    final ball = PlinkoBall(
      _nextId++,
      bet,
      450 + (random.nextDouble() - .5) * 32,
      (random.nextDouble() - .5) * 48,
    );
    // Rapid taps: never spawn inside a ball still at the top; queue the new
    // one just above the highest ball it would overlap.
    const gap = ballRadius * 2 + 1;
    for (var moved = true; moved;) {
      moved = false;
      for (final other in balls) {
        if ((other.x - ball.x).abs() < gap && (other.y - ball.y).abs() < gap) {
          ball.y = other.y - gap;
          moved = true;
        }
      }
    }
    ball.py = ball.y;
    balls.add(ball);
    return ball;
  }

  List<PlinkoBall> advance(double seconds) {
    final landed = <PlinkoBall>[];
    _accumulator += seconds;
    while (_accumulator + 1e-10 >= stepSeconds) {
      _accumulator -= stepSeconds;
      for (final flashes in [pegFlashes, bucketFlashes]) {
        flashes.updateAll((_, time) => time - stepSeconds);
        flashes.removeWhere((_, time) => time <= 0);
      }
      for (final ball in balls) {
        ball.px = ball.x;
        ball.py = ball.y;
        _step(ball);
      }
      _collideBalls();
      for (final ball in balls) {
        if (ball.bucket != null) landed.add(ball);
      }
      balls.removeWhere((ball) => ball.bucket != null);
    }
    return landed;
  }

  /// Balls bump instead of overlapping (rapid taps spawn them close).
  // ponytail: O(n²) pairs, fine for the handful of balls a player can have.
  void _collideBalls() {
    const contact = ballRadius * 2;
    for (var i = 0; i < balls.length; i++) {
      final a = balls[i];
      if (a.bucket != null) continue;
      for (var j = i + 1; j < balls.length; j++) {
        final b = balls[j];
        if (b.bucket != null) continue;
        final dx = b.x - a.x;
        final dy = b.y - a.y;
        final d2 = dx * dx + dy * dy;
        if (d2 >= contact * contact) continue;
        final distance = sqrt(d2);
        final nx = distance > .00001 ? dx / distance : 1.0;
        final ny = distance > .00001 ? dy / distance : 0.0;
        final push = (contact - distance) / 2;
        a.x -= nx * push;
        a.y -= ny * push;
        b.x += nx * push;
        b.y += ny * push;
        final approach = (b.vx - a.vx) * nx + (b.vy - a.vy) * ny;
        if (approach < 0) {
          // Equal masses, restitution .5.
          final impulse = -1.5 * approach / 2;
          a.vx -= impulse * nx;
          a.vy -= impulse * ny;
          b.vx += impulse * nx;
          b.vy += impulse * ny;
        }
      }
    }
  }

  void _step(PlinkoBall ball) {
    ball.age += stepSeconds;
    ball.vy += gravity * stepSeconds;
    ball.vx *= exp(-.12 * stepSeconds);
    ball.x += ball.vx * stepSeconds;
    ball.y += ball.vy * stepSeconds;
    const contact = ballRadius + pegRadius;
    for (var i = 0; i < pegs.length; i++) {
      final peg = pegs[i];
      final dx = ball.x - peg.dx;
      final dy = ball.y - peg.dy;
      final d2 = dx * dx + dy * dy;
      if (d2 >= contact * contact) continue;
      final distance = sqrt(d2);
      final nx = distance > .00001 ? dx / distance : 1.0;
      final ny = distance > .00001 ? dy / distance : 0.0;
      ball.x = peg.dx + nx * (contact + .01);
      ball.y = peg.dy + ny * (contact + .01);
      final normalSpeed = ball.vx * nx + ball.vy * ny;
      if (normalSpeed < 0) {
        // Inelastic collision: reflect the incoming normal velocity and lose energy.
        ball.vx -= 1.35 * normalSpeed * nx;
        ball.vy -= 1.35 * normalSpeed * ny;
        ball.vx *= .82;
        pegFlashes[i] = .16;
        impactCount++;
      }
    }
    if (ball.x < ballRadius) {
      ball.x = ballRadius;
      ball.vx = ball.vx.abs() * .48;
    } else if (ball.x > width - ballRadius) {
      ball.x = width - ballRadius;
      ball.vx = -ball.vx.abs() * .48;
    }
    ball.trailClock += stepSeconds;
    if (ball.trailClock >= 1 / 60) {
      ball.trailClock -= 1 / 60;
      ball.trail.add(Offset(ball.x, ball.y));
      if (ball.trail.length > 5) ball.trail.removeAt(0);
    }
    if (ball.y + ballRadius >= bucketY) {
      ball.bucket = (ball.x / 100).floor().clamp(0, 8);
      bucketFlashes[ball.bucket!] = .65;
    }
  }
}

class PlinkoBall {
  final int id;
  final int bet;
  double x;
  double y = 28;
  double vx;
  double vy = 0;
  double age = 0;
  double trailClock = 0;
  int? bucket;
  final List<Offset> trail = [];
  late double px = x, py = y; // position before the latest step
  PlinkoBall(this.id, this.bet, this.x, this.vx);

  Offset lerp(double t) => Offset(px + (x - px) * t, py + (y - py) * t);
}
