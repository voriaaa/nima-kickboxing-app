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

const _torso = 52.0, _shoulder = 47.0, _neckHead = 19.0;
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
  _Seg(this.from, this.to, this.start, this.dur, this.clip, this.label, this.impact);

  final Pose from, to;
  final double start, dur;
  final int clip;
  final String label;

  /// True for the hold right after the final (impact) keyframe of a clip.
  final bool impact;
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
    void add(Pose to, double dur, int clip, String label, {bool impact = false}) {
      _segs.add(_Seg(cur, to, t, dur, clip, label, impact));
      t += dur;
      cur = to;
    }

    add(guardPose, leadIn, -1, '');
    for (var i = 0; i < clips.length; i++) {
      final kfs = clips[i].keyframes;
      for (var k = 0; k < kfs.length; k++) {
        add(kfs[k].pose, kfs[k].ms.toDouble(), i, kfs[k].label);
        final last = k == kfs.length - 1;
        if (kfs[k].hold > 0) {
          add(kfs[k].pose, kfs[k].hold.toDouble(), i, kfs[k].label, impact: last);
        }
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
    final striking = !identical(s.to, guardPose);
    final e = striking
        ? Curves.easeOutCubic.transform(u)
        : Curves.easeInOutCubic.transform(u);
    return Pose.lerp(s.from, s.to, e);
  }

  int clipAt(double ms) => _segAt(ms).clip;

  String labelAt(double ms) => _segAt(ms).label;

  /// 1 right at impact, fading to 0 over the impact hold; 0 elsewhere.
  double impactAt(double ms) {
    final s = _segAt(ms);
    if (!s.impact || s.dur <= 0) return 0;
    return 1 - ((ms - s.start) / s.dur).clamp(0.0, 1.0);
  }
}

// ------------------------------------------------------------------ drawing
// Mirrors tool/figure_preview.py. Everything is drawn in model space (y up).

const _gapColor = Color(0xFF060A15);
const _leadA = Color(0xFF5AA9FF), _leadB = Color(0xFF1F55C9);
const _rearA = Color(0xFF2A5FB8), _rearB = Color(0xFF0E2A66);
const _bodyA = Color(0xFF4E9BFF), _bodyB = Color(0xFF1A47AE);
const _actA = Color(0xFFB8F6FF), _actB = Color(0xFF2FC4FF);
const _shorts = Color(0xFF0A1020), _shortsRear = Color(0xFF060A14);
const _stripe = Color(0xFF6FE7FF);
const _gloveA = Color(0xFFFF5A5F), _gloveB = Color(0xFFB3121D);
const _gloveRA = Color(0xFFC23A40), _gloveRB = Color(0xFF6E0A12);
const _lightA = Offset(100, 180), _lightB = Offset(-30, 10);

Offset _add(Offset p, Offset v, [double s = 1]) => p + v * s;

/// Tapered capsule: hull of two circles, built from two lines and two arcs.
Path _capsule(Offset a, double ra, Offset b, double rb) {
  final dx = b.dx - a.dx, dy = b.dy - a.dy;
  final dist = math.sqrt(dx * dx + dy * dy);
  final path = Path();
  if (dist < 1e-3 || dist <= (ra - rb).abs() + 1e-3) {
    final c = ra >= rb ? a : b;
    return path..addOval(Rect.fromCircle(center: c, radius: math.max(ra, rb)));
  }
  final th = math.atan2(dy, dx);
  final phi = math.acos(((ra - rb) / dist).clamp(-1.0, 1.0));
  path.moveTo(a.dx + ra * math.cos(th + phi), a.dy + ra * math.sin(th + phi));
  path.lineTo(b.dx + rb * math.cos(th + phi), b.dy + rb * math.sin(th + phi));
  path.arcTo(Rect.fromCircle(center: b, radius: rb), th + phi, -2 * phi, false);
  path.lineTo(a.dx + ra * math.cos(th - phi), a.dy + ra * math.sin(th - phi));
  path.arcTo(Rect.fromCircle(center: a, radius: ra), th - phi,
      -(2 * math.pi - 2 * phi), false);
  path.close();
  return path;
}

Path _union(List<Path> paths) {
  var out = paths.first;
  for (final p in paths.skip(1)) {
    out = Path.combine(PathOperation.union, out, p);
  }
  return out;
}

/// Closed Catmull-Rom curve through [pts].
Path _smoothClosed(List<Offset> pts) {
  final n = pts.length;
  final path = Path()..moveTo(pts[0].dx, pts[0].dy);
  for (var i = 0; i < n; i++) {
    final p0 = pts[(i - 1 + n) % n], p1 = pts[i];
    final p2 = pts[(i + 1) % n], p3 = pts[(i + 2) % n];
    final c1 = p1 + (p2 - p0) / 6;
    final c2 = p2 - (p3 - p1) / 6;
    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
  }
  return path..close();
}

Path _profile(Offset hip, double t, List<List<double>> prof) {
  final u = _dir(t), n = _dir(t - 90);
  final front = [for (final r in prof) hip + u * r[0] + n * r[1]];
  final back = [for (final r in prof) hip + u * r[0] - n * r[2]];
  return _smoothClosed([...front, ...back.reversed]);
}

Path _line(Offset a, Offset b) => Path()
  ..moveTo(a.dx, a.dy)
  ..lineTo(b.dx, b.dy);

class _Stripe {
  const _Stripe(this.path, this.color, this.width);
  final Path path;
  final Color color;
  final double width;
}

class _Part {
  _Part(this.path, this.ca, this.cb, this.rim,
      {this.glow = false, this.stripes = const [], this.after = const []});

  final Path path;
  final Color ca, cb, rim;
  final bool glow;
  final List<_Stripe> stripes;

  /// Strokes drawn unclipped after this part (headband tails).
  final List<_Stripe> after;
}

List<_Part> _buildParts(Pose p, Limb? active) {
  final j = Joints(p);
  final parts = <_Part>[];
  final u = _dir(p.t);
  final fw = _dir(p.t - 90);

  (Color, Color, Color, bool) cols(bool lead, Limb limb) {
    if (active == limb) return (_actA, _actB, Colors.white, true);
    return lead
        ? (_leadA, _leadB, const Color(0xFFA8F0FF), false)
        : (_rearA, _rearB, const Color(0xFF5B95E0), false);
  }

  void leg(bool lead) {
    final h = lead ? j.lHip : j.rHip;
    final k = lead ? j.lKnee : j.rKnee;
    final a = lead ? j.lAnkle : j.rAnkle;
    final toe = lead ? j.lToe : j.rToe;
    final ta = lead ? p.lt : p.rt;
    final sa = lead ? p.ls : p.rs;
    final fa = lead ? p.lfo : p.rfo;
    final ts = lead ? p.lts : p.rts;
    final ss = lead ? p.lss : p.rss;
    final c = cols(lead, lead ? Limb.leadLeg : Limb.rearLeg);
    final heel = _add(a, _dir(fa), -3.0);
    final calf = _add(_add(k, _dir(sa), 13 * ss), _dir(sa - 90), 1.8);
    parts.add(_Part(
      _union([
        _capsule(h, 9.6, k, 6.0),
        _capsule(k, 6.3, a, 3.7),
        _capsule(k, 5.8, calf, 6.4),
        _capsule(calf, 6.0, a, 3.7),
        _capsule(heel, 3.8, toe, 2.4),
      ]),
      c.$1, c.$2, c.$3,
      glow: c.$4,
    ));
    // shorts leg
    final td = _dir(ta);
    final end = _add(h, td, math.min(24.0, 44 * ts * 0.55));
    final shCol = lead ? _shorts : _shortsRear;
    parts.add(_Part(
      _capsule(h, 10.4, end, 8.4),
      shCol, shCol,
      lead ? const Color(0xFF22324F) : const Color(0xFF141E33),
      stripes: [
        _Stripe(_line(_add(h, td, 4), _add(end, td, -2)),
            lead ? _stripe : const Color(0xFF2A6C8E), 1.8),
      ],
    ));
  }

  void arm(bool lead) {
    final sp = lead ? j.lShoulder : j.rShoulder;
    final e = lead ? j.lElbow : j.rElbow;
    final w = lead ? j.lHand : j.rHand;
    final fa = lead ? p.lf : p.rf;
    final limb = lead ? Limb.leadArm : Limb.rearArm;
    final c = cols(lead, limb);
    parts.add(_Part(
      _union([_capsule(sp, 7.0, e, 4.8), _capsule(e, 5.0, w, 3.8)]),
      c.$1, c.$2, c.$3,
      glow: c.$4,
    ));
    final fd = _dir(fa);
    final side = _dir(fa + 90);
    final gc = _add(w, fd, 4.6);
    final glove = _union([
      _capsule(_add(gc, fd, -2.6), 8.2, _add(gc, fd, 3.0), 7.4),
      _capsule(_add(gc, side, 5.5), 3.2, _add(_add(gc, fd, 2), side, 6.2), 2.8),
    ]);
    final isActive = active == limb;
    final g = isActive
        ? (const Color(0xFFFF9EA3), const Color(0xFFE0263A), Colors.white)
        : lead
            ? (_gloveA, _gloveB, const Color(0xFFFFC2C4))
            : (_gloveRA, _gloveRB, const Color(0xFFD06A70));
    final cuffC = _add(w, fd, 0.4);
    parts.add(_Part(
      glove, g.$1, g.$2, g.$3,
      glow: isActive,
      stripes: [
        _Stripe(_line(_add(cuffC, side, 5.6), _add(cuffC, side, -5.6)),
            const Color(0xFF5A0810), 2.2),
      ],
    ));
  }

  // The striking limb is drawn in front of everything.
  final rearLegFront = active == Limb.rearLeg;
  final rearArmFront = active == Limb.rearArm;
  if (!rearLegFront) leg(false);
  if (!rearArmFront) arm(false);

  // Body: torso + neck + head as one silhouette
  final head = j.head;
  final hu = _dir(p.t + p.hd);
  final hn = _dir(p.t + p.hd - 90);
  final skull = Path()..addOval(Rect.fromCircle(center: head, radius: 10.2));
  final jaw = _capsule(_add(_add(head, hu, -6.5), hn, 2.5), 6.0,
      _add(_add(head, hu, -2.5), hn, 6.0), 5.4);
  final neck = _capsule(_add(j.hip, u, 45), 5.6, _add(head, hu, -6), 4.6);
  final torso = _profile(j.hip, p.t, const [
    [-6, 9.0, 11.0],
    [4, 10.0, 12.0],
    [17, 8.6, 8.2],
    [29, 13.6, 9.6],
    [40, 12.6, 10.4],
    [47, 7.5, 8.0],
  ]);
  final band = _line(_add(_add(head, hu, 3.5), hn, 12), _add(_add(head, hu, 3.5), hn, -12));
  final tail = Path()
    ..moveTo(_add(_add(head, hu, 3.5), hn, -9).dx, _add(_add(head, hu, 3.5), hn, -9).dy)
    ..quadraticBezierTo(
      _add(_add(head, hu, 0), hn, -17).dx,
      _add(_add(head, hu, 0), hn, -17).dy,
      _add(_add(head, hu, -6), hn, -19).dx,
      _add(_add(head, hu, -6), hn, -19).dy,
    );
  parts.add(_Part(
    _union([torso, neck, skull, jaw]),
    _bodyA, _bodyB, const Color(0xFFA8F0FF),
    stripes: [_Stripe(band, _stripe, 3.0)],
    after: [_Stripe(tail, _stripe, 2.6)],
  ));

  final waist = _add(j.hip, u, 10.5);
  parts.add(_Part(
    _profile(j.hip, p.t, const [
      [-7, 9.5, 11.5],
      [4, 10.2, 12.2],
      [11, 9.0, 10.0],
    ]),
    _shorts, _shorts, const Color(0xFF22324F),
    stripes: [_Stripe(_line(_add(waist, fw, 9.4), _add(waist, fw, -10.6)), _stripe, 2.4)],
  ));

  leg(true);
  arm(true);
  if (rearLegFront) leg(false);
  if (rearArmFront) arm(false);
  return parts;
}

class FighterPainter extends CustomPainter {
  FighterPainter({
    required this.pose,
    this.highlight,
    this.trail = const [],
    this.arrows = const [],
    this.arrowOpacity = 1,
    this.impact = 0,
    this.impactPoint,
  });

  final Pose pose;
  final Limb? highlight;
  final List<Offset> trail;
  final List<Arrow> arrows;
  final double arrowOpacity;

  /// 0..1 strength of the hit flash drawn at [impactPoint].
  final double impact;
  final Offset? impactPoint;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / _box.width, size.height / _box.height);
    final ox = (size.width - _box.width * s) / 2;
    final oy = (size.height - _box.height * s) / 2;
    canvas.save();
    canvas.translate(ox - _box.left * s, oy + _box.bottom * s);
    canvas.scale(s, -s); // model space, y up

    // floor line + shadow
    canvas.drawLine(
      Offset(_box.left, 0),
      Offset(_box.right, 0),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(_box.left, 0),
          Offset(_box.right, 0),
          [Colors.transparent, AppColors.blue.withValues(alpha: 0.5), Colors.transparent],
          [0, 0.5, 1],
        )
        ..strokeWidth = 1.2,
    );
    final j = Joints(pose);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(j.hip.dx, 0), width: 84, height: 7),
      Paint()
        ..color = const Color(0x882E7BFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    if (arrowOpacity > 0) {
      for (final a in arrows) {
        _arrow(canvas, a, arrowOpacity);
      }
    }

    if (trail.length > 1) {
      for (var i = 1; i < trail.length; i++) {
        final f = 1 - i / trail.length;
        canvas.drawLine(
          trail[i - 1],
          trail[i],
          Paint()
            ..color = AppColors.cyan.withValues(alpha: 0.5 * f)
            ..strokeWidth = 12 * f + 1
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
    }

    _figure(canvas);

    if (impact > 0 && impactPoint != null) _burst(canvas, impactPoint!, impact);
    canvas.restore();
  }

  void _figure(Canvas canvas) {
    final parts = _buildParts(pose, highlight);
    for (final pt in parts) {
      if (pt.glow) {
        canvas.drawPath(
          pt.path,
          Paint()
            ..color = const Color(0xAA35C8FF)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
        );
      }
    }
    final gap = Paint()
      ..color = _gapColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeJoin = StrokeJoin.round;
    for (final pt in parts) {
      canvas.drawPath(pt.path, gap);
      // Rim light: fill with the rim colour, then the gradient shifted away from the light.
      canvas.save();
      canvas.clipPath(pt.path);
      canvas.drawPath(pt.path, Paint()..color = pt.rim);
      canvas.translate(-1.5, -1.3);
      canvas.drawPath(
        pt.path,
        Paint()..shader = ui.Gradient.linear(_lightA, _lightB, [pt.ca, pt.cb]),
      );
      canvas.restore();
      if (pt.stripes.isNotEmpty) {
        canvas.save();
        canvas.clipPath(pt.path);
        for (final st in pt.stripes) {
          canvas.drawPath(st.path, _strokePaint(st));
        }
        canvas.restore();
      }
      for (final st in pt.after) {
        canvas.drawPath(st.path, _strokePaint(st));
      }
    }
  }

  Paint _strokePaint(_Stripe st) => Paint()
    ..color = st.color
    ..style = PaintingStyle.stroke
    ..strokeWidth = st.width
    ..strokeCap = StrokeCap.round;

  void _burst(Canvas canvas, Offset c, double k) {
    final r0 = 10 + (1 - k) * 8;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9 * k)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + 0.3;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + d * r0, c + d * (r0 + 6 + 4 * k), paint);
    }
    canvas.drawCircle(
      c,
      r0 - 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = AppColors.cyan.withValues(alpha: 0.8 * k),
    );
  }

  void _arrow(Canvas canvas, Arrow a, double opacity) {
    final p0 = Offset(a.x0, a.y0), c = Offset(a.cx, a.cy), p1 = Offset(a.x1, a.y1);
    final path = Path()
      ..moveTo(p0.dx, p0.dy)
      ..quadraticBezierTo(c.dx, c.dy, p1.dx, p1.dy);
    final col = AppColors.gold.withValues(alpha: 0.9 * opacity);
    final stroke = Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, math.min(d + 5, metric.length)), stroke);
        d += 8.5;
      }
    }
    final dir = p1 - c;
    final len = dir.distance;
    if (len == 0) return;
    final u = dir / len;
    final n = Offset(-u.dy, u.dx);
    const h = 6.5;
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

/// A still pose (used for cards and step-by-step frames).
class FighterStill extends StatelessWidget {
  const FighterStill({
    super.key,
    required this.pose,
    this.highlight,
    this.arrows = const [],
  });

  final Pose pose;
  final Limb? highlight;
  final List<Arrow> arrows;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: FighterPainter(pose: pose, highlight: highlight, arrows: arrows),
        size: Size.infinite,
      ),
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
    final knee = identical(clip, moveClips['knee']);

    final trail = <Offset>[];
    if (limb != null) {
      for (var i = 0; i < 16; i++) {
        final t = _ms - i * 14 * widget.speed.clamp(0.25, 2.0);
        if (t < 0 || _timeline.clipAt(t) != clipIndex) break;
        trail.add(Joints(_timeline.poseAt(t)).effector(limb, knee: knee));
      }
    }
    final impact = limb == null ? 0.0 : _timeline.impactAt(_ms);

    return RepaintBoundary(
      child: CustomPaint(
        painter: FighterPainter(
          pose: pose,
          highlight: limb,
          trail: trail,
          arrows: widget.showArrows && clip != null ? clip.arrows : const [],
          arrowOpacity: 0.85,
          impact: impact,
          impactPoint: limb == null ? null : Joints(pose).effector(limb, knee: knee),
        ),
        size: Size.infinite,
      ),
    );
  }
}
