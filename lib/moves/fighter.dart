import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme.dart';
import 'pose_data.g.dart';

/// Animated vector fighter. Side view, facing right, orthodox stance.
/// The math here mirrors tool/poses.py, which is where poses are authored.

enum Limb { leadArm, rearArm, leadLeg, rearLeg }

class Pose {
  const Pose({
    this.hx = 0,
    this.hy = 84,
    this.t = 82,
    this.hd = 0,
    this.sh = 5,
    this.hs = 4,
    this.lu = -58,
    this.lf = 72,
    this.ru = -82,
    this.rf = 78,
    this.lt = -65,
    this.ls = -100,
    this.lfo = 0,
    this.rt = -112,
    this.rs = -105,
    this.rfo = -18,
    this.lus = 1,
    this.lfs = 1,
    this.rus = 1,
    this.rfs = 1,
    this.lts = 1,
    this.lss = 1,
    this.rts = 1,
    this.rss = 1,
  });

  final double hx, hy, t, hd, sh, hs;
  final double lu, lf, ru, rf;
  final double lt, ls, lfo, rt, rs, rfo;
  final double lus, lfs, rus, rfs, lts, lss, rts, rss;

  static double _l(double a, double b, double u) => a + (b - a) * u;

  static Pose lerp(Pose a, Pose b, double u) => Pose(
        hx: _l(a.hx, b.hx, u),
        hy: _l(a.hy, b.hy, u),
        t: _l(a.t, b.t, u),
        hd: _l(a.hd, b.hd, u),
        sh: _l(a.sh, b.sh, u),
        hs: _l(a.hs, b.hs, u),
        lu: _l(a.lu, b.lu, u),
        lf: _l(a.lf, b.lf, u),
        ru: _l(a.ru, b.ru, u),
        rf: _l(a.rf, b.rf, u),
        lt: _l(a.lt, b.lt, u),
        ls: _l(a.ls, b.ls, u),
        lfo: _l(a.lfo, b.lfo, u),
        rt: _l(a.rt, b.rt, u),
        rs: _l(a.rs, b.rs, u),
        rfo: _l(a.rfo, b.rfo, u),
        lus: _l(a.lus, b.lus, u),
        lfs: _l(a.lfs, b.lfs, u),
        rus: _l(a.rus, b.rus, u),
        rfs: _l(a.rfs, b.rfs, u),
        lts: _l(a.lts, b.lts, u),
        lss: _l(a.lss, b.lss, u),
        rts: _l(a.rts, b.rts, u),
        rss: _l(a.rss, b.rss, u),
      );
}

class Keyframe {
  const Keyframe(this.label, this.ms, this.hold, this.pose);

  final String label;
  final int ms;
  final int hold;
  final Pose pose;
}

/// Quadratic curve hint (start, control, end) in model space.
class Arrow {
  const Arrow(this.x0, this.y0, this.cx, this.cy, this.x1, this.y1);

  final double x0, y0, cx, cy, x1, y1;
}

class MoveClip {
  const MoveClip({
    required this.limb,
    required this.keyframes,
    required this.arrows,
  });

  final Limb? limb;
  final List<Keyframe> keyframes;
  final List<Arrow> arrows;

  Pose get impactPose => keyframes.last.pose;
}

// ------------------------------------------------------------------ geometry

const _torso = 52.0, _shoulder = 47.0, _neckHead = 19.0, _headR = 11.0;
const _upper = 30.0, _fore = 28.0, _thigh = 44.0, _shin = 42.0, _foot = 14.0;

/// Visible model area: x0, y0, x1, y1 (y up).
const _box = Rect.fromLTRB(-70, -6, 140, 192);

Offset _dir(double deg) {
  final r = deg * math.pi / 180;
  return Offset(math.cos(r), math.sin(r));
}

class Joints {
  Joints(Pose p) {
    hip = Offset(p.hx, p.hy);
    final fwd = _dir(p.t - 90);
    neck = hip + _dir(p.t) * _torso;
    final sh = hip + _dir(p.t) * _shoulder;
    head = neck + _dir(p.t + p.hd) * _neckHead;
    lShoulder = sh + fwd * p.sh;
    rShoulder = sh - fwd * p.sh;
    lHip = hip + fwd * p.hs;
    rHip = hip - fwd * p.hs;

    lElbow = lShoulder + _dir(p.lu) * (_upper * p.lus);
    lHand = lElbow + _dir(p.lf) * (_fore * p.lfs);
    rElbow = rShoulder + _dir(p.ru) * (_upper * p.rus);
    rHand = rElbow + _dir(p.rf) * (_fore * p.rfs);

    lKnee = lHip + _dir(p.lt) * (_thigh * p.lts);
    lAnkle = lKnee + _dir(p.ls) * (_shin * p.lss);
    lToe = lAnkle + _dir(p.lfo) * _foot;
    rKnee = rHip + _dir(p.rt) * (_thigh * p.rts);
    rAnkle = rKnee + _dir(p.rs) * (_shin * p.rss);
    rToe = rAnkle + _dir(p.rfo) * _foot;
  }

  late final Offset hip, neck, head;
  late final Offset lShoulder, rShoulder, lHip, rHip;
  late final Offset lElbow, lHand, rElbow, rHand;
  late final Offset lKnee, lAnkle, lToe, rKnee, rAnkle, rToe;

  /// The point that hits the target for a given limb.
  Offset effector(Limb limb, {bool knee = false}) {
    switch (limb) {
      case Limb.leadArm:
        return lHand;
      case Limb.rearArm:
        return rHand;
      case Limb.leadLeg:
        return knee ? lKnee : lAnkle;
      case Limb.rearLeg:
        return knee ? rKnee : rAnkle;
    }
  }
}

// ------------------------------------------------------------------ timeline

class _Seg {
  _Seg(this.from, this.to, this.start, this.dur, this.clip, this.label);

  final Pose from, to;
  final double start, dur;
  final int clip;
  final String label;
}

/// A list of clips played one after another, each returning to guard.
class FighterTimeline {
  FighterTimeline(
    this.clips, {
    this.leadIn = 350,
    this.returnMs = 260,
    this.tail = 700,
  }) {
    var t = 0.0;
    var cur = guardPose;
    void add(Pose to, double dur, int clip, String label) {
      _segs.add(_Seg(cur, to, t, dur, clip, label));
      t += dur;
      cur = to;
    }

    add(guardPose, leadIn, -1, '');
    for (var i = 0; i < clips.length; i++) {
      for (final k in clips[i].keyframes) {
        add(k.pose, k.ms.toDouble(), i, k.label);
        if (k.hold > 0) add(k.pose, k.hold.toDouble(), i, k.label);
      }
      add(guardPose, returnMs, i, '');
    }
    add(guardPose, tail, -1, '');
    total = t;
  }

  final List<MoveClip> clips;
  final double leadIn, returnMs, tail;
  final List<_Seg> _segs = [];
  late final double total;

  _Seg _segAt(double ms) {
    for (final s in _segs) {
      if (ms < s.start + s.dur) return s;
    }
    return _segs.last;
  }

  Pose poseAt(double ms) {
    final s = _segAt(ms);
    if (s.dur <= 0) return s.to;
    final u = ((ms - s.start) / s.dur).clamp(0.0, 1.0);
    final striking = s.to != guardPose;
    final e = striking
        ? Curves.easeOutCubic.transform(u)
        : Curves.easeInOutCubic.transform(u);
    return Pose.lerp(s.from, s.to, e);
  }

  int clipAt(double ms) => _segAt(ms).clip;

  String labelAt(double ms) => _segAt(ms).label;
}

// ------------------------------------------------------------------ painter

class FighterPainter extends CustomPainter {
  FighterPainter({
    required this.pose,
    this.highlight,
    this.trail = const [],
    this.arrows = const [],
    this.arrowOpacity = 1,
    this.ghost,
  });

  final Pose pose;
  final Limb? highlight;
  final List<Offset> trail;
  final List<Arrow> arrows;
  final double arrowOpacity;

  /// Optional faint pose drawn behind (e.g. the guard while striking).
  final Pose? ghost;

  static const _rear = Color(0xFF1E4FA6);
  static const _lead = Color(0xFF4A9EFF);
  static const _body = Color(0xFF5FB0FF);

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / _box.width, size.height / _box.height);
    final ox = (size.width - _box.width * s) / 2;
    final oy = (size.height - _box.height * s) / 2;
    Offset m(Offset p) =>
        Offset(ox + (p.dx - _box.left) * s, oy + (_box.bottom - p.dy) * s);

    // Floor
    final floorY = m(Offset.zero).dy;
    final floor = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, floorY),
        Offset(size.width, floorY),
        [
          Colors.transparent,
          AppColors.blue.withValues(alpha: 0.55),
          Colors.transparent,
        ],
        [0, 0.5, 1],
      )
      ..strokeWidth = 1.5 * s;
    canvas.drawLine(Offset(0, floorY), Offset(size.width, floorY), floor);

    final j = Joints(pose);
    final hipX = m(j.hip).dx;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(hipX, floorY), width: 70 * s, height: 7 * s),
      Paint()
        ..color = AppColors.blue.withValues(alpha: 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * s),
    );

    if (ghost != null) _figure(canvas, Joints(ghost!), m, s, ghostMode: true);

    // Arrows (direction hints)
    if (arrowOpacity > 0) {
      for (final a in arrows) {
        _arrow(canvas, a, m, s, arrowOpacity);
      }
    }

    // Motion trail
    if (trail.length > 1) {
      for (var i = 1; i < trail.length; i++) {
        final f = 1 - i / trail.length;
        canvas.drawLine(
          m(trail[i - 1]),
          m(trail[i]),
          Paint()
            ..color = AppColors.cyan.withValues(alpha: 0.55 * f)
            ..strokeWidth = (9 * f + 1) * s
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    _figure(canvas, j, m, s);
  }

  void _figure(Canvas canvas, Joints j, Offset Function(Offset) m, double s,
      {bool ghostMode = false}) {
    Color c(Color base, Limb limb) {
      if (ghostMode) return Colors.white.withValues(alpha: 0.07);
      return highlight == limb ? AppColors.cyan : base;
    }

    final bodyCol = ghostMode ? Colors.white.withValues(alpha: 0.07) : _body;

    void seg(Offset a, Offset b, double w, Color col, {bool glow = false}) {
      if (glow && !ghostMode) {
        canvas.drawLine(
          m(a),
          m(b),
          Paint()
            ..color = col.withValues(alpha: 0.45)
            ..strokeWidth = (w + 8) * s
            ..strokeCap = StrokeCap.round
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * s),
        );
      }
      canvas.drawLine(
        m(a),
        m(b),
        Paint()
          ..color = col
          ..strokeWidth = w * s
          ..strokeCap = StrokeCap.round,
      );
    }

    void dot(Offset p, double r, Color col, {bool glow = false}) {
      if (glow && !ghostMode) {
        canvas.drawCircle(
          m(p),
          (r + 5) * s,
          Paint()
            ..color = col.withValues(alpha: 0.5)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * s),
        );
      }
      canvas.drawCircle(m(p), r * s, Paint()..color = col);
    }

    // Rear side (behind)
    final ra = c(_rear, Limb.rearArm);
    final rl = c(_rear, Limb.rearLeg);
    final rlGlow = highlight == Limb.rearLeg;
    final raGlow = highlight == Limb.rearArm;
    seg(j.rHip, j.rKnee, 11, rl, glow: rlGlow);
    seg(j.rKnee, j.rAnkle, 9, rl, glow: rlGlow);
    seg(j.rAnkle, j.rToe, 6, rl);
    seg(j.rShoulder, j.rElbow, 9, ra, glow: raGlow);
    seg(j.rElbow, j.rHand, 8, ra, glow: raGlow);
    dot(j.rHand, 8.5, ra, glow: raGlow);

    // Body
    seg(j.hip, j.neck, 15, bodyCol);
    dot(j.head, _headR, bodyCol);
    if (!ghostMode) {
      // belt
      final fwd = _dir(pose.t - 90);
      final belt = j.hip + _dir(pose.t) * 3;
      seg(belt - fwd * 7, belt + fwd * 7, 4, const Color(0xFF0A1630));
    }

    // Lead side (front)
    final la = c(_lead, Limb.leadArm);
    final ll = c(_lead, Limb.leadLeg);
    final llGlow = highlight == Limb.leadLeg;
    final laGlow = highlight == Limb.leadArm;
    seg(j.lHip, j.lKnee, 11, ll, glow: llGlow);
    seg(j.lKnee, j.lAnkle, 9, ll, glow: llGlow);
    seg(j.lAnkle, j.lToe, 6, ll);
    seg(j.lShoulder, j.lElbow, 9, la, glow: laGlow);
    seg(j.lElbow, j.lHand, 8, la, glow: laGlow);
    dot(j.lHand, 8.5, la, glow: laGlow);
  }

  void _arrow(Canvas canvas, Arrow a, Offset Function(Offset) m, double s,
      double opacity) {
    final p0 = m(Offset(a.x0, a.y0));
    final c = m(Offset(a.cx, a.cy));
    final p1 = m(Offset(a.x1, a.y1));
    final path = Path()
      ..moveTo(p0.dx, p0.dy)
      ..quadraticBezierTo(c.dx, c.dy, p1.dx, p1.dy);
    final col = AppColors.gold.withValues(alpha: 0.9 * opacity);
    // dashed curve
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      final dash = 6 * s, gap = 4 * s;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + dash, metric.length)),
          Paint()
            ..color = col
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2 * s
            ..strokeCap = StrokeCap.round,
        );
        d += dash + gap;
      }
    }
    // arrow head, aligned with the curve's end tangent
    final dir = p1 - c;
    final len = dir.distance;
    if (len == 0) return;
    final u = dir / len;
    final n = Offset(-u.dy, u.dx);
    final h = 7 * s;
    final head = Path()
      ..moveTo(p1.dx + u.dx * h * 0.6, p1.dy + u.dy * h * 0.6)
      ..lineTo(p1.dx - u.dx * h + n.dx * h * 0.6, p1.dy - u.dy * h + n.dy * h * 0.6)
      ..lineTo(p1.dx - u.dx * h - n.dx * h * 0.6, p1.dy - u.dy * h - n.dy * h * 0.6)
      ..close();
    canvas.drawPath(head, Paint()..color = col);
  }

  @override
  bool shouldRepaint(covariant FighterPainter old) => true;
}

// ------------------------------------------------------------------ widgets

/// A still pose (used for step-by-step frames).
class FighterStill extends StatelessWidget {
  const FighterStill({
    super.key,
    required this.pose,
    this.highlight,
    this.arrows = const [],
    this.ghost,
  });

  final Pose pose;
  final Limb? highlight;
  final List<Arrow> arrows;
  final Pose? ghost;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: FighterPainter(
        pose: pose,
        highlight: highlight,
        arrows: arrows,
        ghost: ghost,
      ),
      size: Size.infinite,
    );
  }
}

/// Plays a list of move ids in a loop.
class FighterAnimation extends StatefulWidget {
  const FighterAnimation({
    super.key,
    required this.moveIds,
    this.speed = 1,
    this.playing = true,
    this.showArrows = false,
    this.onClipChanged,
    this.returnMs = 260,
  });

  final List<String> moveIds;
  final double speed;
  final bool playing;
  final bool showArrows;
  final int returnMs;

  /// Called with the index in [moveIds] being performed (-1 while in guard).
  final ValueChanged<int>? onClipChanged;

  @override
  State<FighterAnimation> createState() => _FighterAnimationState();
}

class _FighterAnimationState extends State<FighterAnimation>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  late FighterTimeline _timeline;
  double _ms = 0;
  Duration _last = Duration.zero;
  int _clip = -1;

  @override
  void initState() {
    super.initState();
    _build();
    _ticker = createTicker(_onTick);
    if (widget.playing) _ticker.start();
  }

  void _build() {
    final clips = [
      for (final id in widget.moveIds)
        if (moveClips[id] != null) moveClips[id]!,
    ];
    _timeline = FighterTimeline(clips, returnMs: widget.returnMs.toDouble());
  }

  @override
  void didUpdateWidget(FighterAnimation old) {
    super.didUpdateWidget(old);
    if (old.moveIds.join(',') != widget.moveIds.join(',') ||
        old.returnMs != widget.returnMs) {
      _build();
      _ms = 0;
    }
    if (widget.playing && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!widget.playing && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1000.0;
    _last = elapsed;
    setState(() {
      _ms = (_ms + dt * widget.speed) % _timeline.total;
    });
    final c = _timeline.clipAt(_ms);
    if (c != _clip) {
      _clip = c;
      widget.onClipChanged?.call(c);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pose = _timeline.poseAt(_ms);
    final clipIndex = _timeline.clipAt(_ms);
    final clip = clipIndex >= 0 ? _timeline.clips[clipIndex] : null;
    final limb = clip?.limb;

    final trail = <Offset>[];
    if (limb != null) {
      final knee = clip == moveClips['knee'];
      for (var i = 0; i < 16; i++) {
        final t = _ms - i * 14 * widget.speed.clamp(0.25, 2.0);
        if (t < 0 || _timeline.clipAt(t) != clipIndex) break;
        trail.add(Joints(_timeline.poseAt(t)).effector(limb, knee: knee));
      }
    }

    return CustomPaint(
      painter: FighterPainter(
        pose: pose,
        highlight: limb,
        trail: trail,
        arrows: widget.showArrows && clip != null ? clip.arrows : const [],
        arrowOpacity: 0.85,
      ),
      size: Size.infinite,
    );
  }
}
