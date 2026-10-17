"""Preview of the athlete figure style using skia (the same engine Flutter uses).
The drawing code mirrors lib/moves/fighter.dart (_AthletePainter).

    python3 tool/figure_preview.py OUT.png [move ...]
"""
import math
import os
import sys

import skia

sys.path.insert(0, os.path.dirname(__file__))
from poses import GUARD, MOVES, joints  # noqa: E402

BOX = (-70, -6, 140, 192)

# palette
NAVY_OUT = 0xFF040812
LEAD_A, LEAD_B = 0xFF5AA9FF, 0xFF1F55C9      # light -> dark
REAR_A, REAR_B = 0xFF2A5FB8, 0xFF0E2A66
BODY_A, BODY_B = 0xFF4E9BFF, 0xFF1A47AE
ACT_A, ACT_B = 0xFFB8F6FF, 0xFF2FC4FF
SHORTS = 0xFF0A1020
SHORTS_REAR = 0xFF060A14
STRIPE = 0xFF6FE7FF
GLOVE_A, GLOVE_B = 0xFFFF5A5F, 0xFFB3121D    # red gloves for contrast
GLOVE_RA, GLOVE_RB = 0xFFC23A40, 0xFF6E0A12


def d(a):
    r = math.radians(a)
    return (math.cos(r), math.sin(r))


def add(p, v, s=1.0):
    return (p[0] + v[0] * s, p[1] + v[1] * s)


def capsule(a, ra, b, rb):
    """Tapered capsule: hull of two circles, built from two lines and two arcs."""
    dx, dy = b[0] - a[0], b[1] - a[1]
    dist = math.hypot(dx, dy)
    path = skia.Path()
    if dist < 1e-3 or dist <= abs(ra - rb) + 1e-3:
        r = max(ra, rb)
        c = a if ra >= rb else b
        path.addCircle(c[0], c[1], r)
        return path
    th = math.atan2(dy, dx)
    phi = math.acos((ra - rb) / dist)
    deg = math.degrees
    path.moveTo(a[0] + ra * math.cos(th + phi), a[1] + ra * math.sin(th + phi))
    path.lineTo(b[0] + rb * math.cos(th + phi), b[1] + rb * math.sin(th + phi))
    path.arcTo(skia.Rect.MakeLTRB(b[0] - rb, b[1] - rb, b[0] + rb, b[1] + rb),
               deg(th + phi), -deg(2 * phi), False)
    path.lineTo(a[0] + ra * math.cos(th - phi), a[1] + ra * math.sin(th - phi))
    path.arcTo(skia.Rect.MakeLTRB(a[0] - ra, a[1] - ra, a[0] + ra, a[1] + ra),
               deg(th - phi), -deg(2 * math.pi - 2 * phi), False)
    path.close()
    return path


def union(*paths):
    out = paths[0]
    for p in paths[1:]:
        out = skia.Op(out, p, skia.PathOp.kUnion_PathOp)
    return out


def smooth_closed(pts):
    """Closed Catmull-Rom through pts as cubic beziers."""
    n = len(pts)
    path = skia.Path()
    path.moveTo(*pts[0])
    for i in range(n):
        p0, p1, p2, p3 = pts[(i - 1) % n], pts[i], pts[(i + 1) % n], pts[(i + 2) % n]
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        path.cubicTo(*c1, *c2, *p2)
    path.close()
    return path


def torso_path(p, j):
    u = d(p["t"])
    n = d(p["t"] - 90)  # forward
    hip = j["hip"]
    prof = [(-6, 9.0, 11.0), (4, 10.0, 12.0), (17, 8.6, 8.2), (29, 13.6, 9.6),
            (40, 12.6, 10.4), (47, 7.5, 8.0)]
    front = [add(add(hip, u, s), n, f) for s, f, _ in prof]
    back = [add(add(hip, u, s), n, -b) for s, _, b in prof]
    return smooth_closed(front + back[::-1])


def shorts_torso_path(p, j):
    u = d(p["t"])
    n = d(p["t"] - 90)
    hip = j["hip"]
    prof = [(-7, 9.5, 11.5), (4, 10.2, 12.2), (11, 9.0, 10.0)]
    front = [add(add(hip, u, s), n, f) for s, f, _ in prof]
    back = [add(add(hip, u, s), n, -b) for s, _, b in prof]
    return smooth_closed(front + back[::-1])


def lin(a, b, ca, cb):
    return skia.GradientShader.MakeLinear([skia.Point(*a), skia.Point(*b)], [ca, cb])


GAP = 0xFF060A15
LIGHT_A, LIGHT_B = (100, 180), (-30, 10)   # gradient runs from the light (upper front)


class Part:
    def __init__(self, path, ca, cb, rim, glow=False, gap=True, stripes=()):
        self.path, self.ca, self.cb, self.rim, self.glow, self.gap = path, ca, cb, rim, glow, gap
        self.stripes = stripes   # list of (path, color, width)


def figure_parts(p, limb=None):
    j = joints(p)
    parts = []
    u = d(p["t"])
    fw = d(p["t"] - 90)

    def side_cols(side, kind):
        if limb == side + kind:
            return ACT_A, ACT_B, 0xFFFFFFFF, True
        if side == "l":
            return LEAD_A, LEAD_B, 0xFFA8F0FF, False
        return REAR_A, REAR_B, 0xFF5B95E0, False

    def leg(side):
        h, k, a, toe = j[side + "h"], j[side + "k"], j[side + "a"], j[side + "toe"]
        ca, cb, rim, glow = side_cols(side, "l")
        fo = d(p[side + "fo"])
        heel = add(a, fo, -3.0)
        sd = d(p[side + "s"])
        calf = add(add(k, sd, 13 * p[side + "ss"]), d(p[side + "s"] - 90), 1.8)
        path = union(capsule(h, 9.6, k, 6.0), capsule(k, 6.3, a, 3.7), capsule(k, 5.8, calf, 6.4),
                     capsule(calf, 6.0, a, 3.7), capsule(heel, 3.8, toe, 2.4))
        parts.append(Part(path, ca, cb, rim, glow))
        # shorts leg
        td = d(p[side + "t"])
        knee_len = 44 * p[side + "ts"]
        end = add(h, td, min(24, knee_len * 0.55))
        sh_col = SHORTS if side == "l" else SHORTS_REAR
        stripe = skia.Path()
        side_off = d(p[side + "t"] + 90)
        stripe.moveTo(*add(add(h, td, 4), side_off, 0))
        stripe.lineTo(*add(end, td, -2))
        parts.append(Part(capsule(h, 10.4, end, 8.4), sh_col, sh_col, 0xFF22324F if side == "l" else 0xFF141E33,
                          stripes=[(stripe, STRIPE if side == "l" else 0xFF2A6C8E, 1.8)]))

    def arm(side):
        sp, e, w = j[side + "s"], j[side + "e"], j[side + "w"]
        ca, cb, rim, glow = side_cols(side, "a")
        parts.append(Part(union(capsule(sp, 7.0, e, 4.8), capsule(e, 5.0, w, 3.8)), ca, cb, rim, glow))
        fd = d(p[side + "f"])
        gc = add(w, fd, 4.6)
        glove = capsule(add(gc, fd, -2.6), 8.2, add(gc, fd, 3.0), 7.4)
        thumb = capsule(add(gc, d(p[side + "f"] + 90), 5.5), 3.2, add(add(gc, fd, 2), d(p[side + "f"] + 90), 6.2), 2.8)
        glove = union(glove, thumb)
        active = limb == side + "a"
        if active:
            g = (0xFFFF9EA3, 0xFFE0263A, 0xFFFFFFFF)
        elif side == "l":
            g = (GLOVE_A, GLOVE_B, 0xFFFFC2C4)
        else:
            g = (GLOVE_RA, GLOVE_RB, 0xFFD06A70)
        cuff = skia.Path()
        cuff.moveTo(*add(add(w, fd, 0.4), d(p[side + "f"] + 90), 5.6))
        cuff.lineTo(*add(add(w, fd, 0.4), d(p[side + "f"] - 90), 5.6))
        parts.append(Part(glove, g[0], g[1], g[2], active, stripes=[(cuff, 0xFF5A0810, 2.2)]))

    # the striking limb is drawn in front of everything
    front_rear_leg = limb == "rl"
    front_rear_arm = limb == "ra"
    if not front_rear_leg:
        leg("r")
    if not front_rear_arm:
        arm("r")

    # body: torso + neck + head as one silhouette
    head = j["head"]
    hu = d(p["t"] + p["hd"])
    hn = d(p["t"] + p["hd"] - 90)
    skull = skia.Path()
    skull.addCircle(head[0], head[1], 10.2)
    jaw = capsule(add(add(head, hu, -6.5), hn, 2.5), 6.0, add(add(head, hu, -2.5), hn, 6.0), 5.4)
    neck = capsule(add(j["hip"], u, 45), 5.6, add(head, hu, -6), 4.6)
    body = union(torso_path(p, j), neck, skull, jaw)
    hb = skia.Path()
    hb.moveTo(*add(add(head, hu, 3.5), hn, 12))
    hb.lineTo(*add(add(head, hu, 3.5), hn, -12))
    tail = skia.Path()
    tail.moveTo(*add(add(head, hu, 3.5), hn, -9))
    tail.quadTo(*add(add(head, hu, 0), hn, -17), *add(add(head, hu, -6), hn, -19))
    parts.append(Part(body, BODY_A, BODY_B, 0xFFA8F0FF, stripes=[(hb, STRIPE, 3.0)]))
    parts.append(("tail", tail))

    band = skia.Path()
    band.moveTo(*add(add(j["hip"], u, 10.5), fw, 9.4))
    band.lineTo(*add(add(j["hip"], u, 10.5), fw, -10.6))
    parts.append(Part(shorts_torso_path(p, j), SHORTS, SHORTS, 0xFF22324F,
                      stripes=[(band, STRIPE, 2.4)]))
    leg("l")
    arm("l")
    if front_rear_leg:
        leg("r")
    if front_rear_arm:
        arm("r")
    return parts


def draw(canvas, p, size, limb=None):
    W, H = size
    s = min(W / (BOX[2] - BOX[0]), H / (BOX[3] - BOX[1]))
    ox = (W - (BOX[2] - BOX[0]) * s) / 2
    oy = (H - (BOX[3] - BOX[1]) * s) / 2
    canvas.save()
    canvas.translate(ox - BOX[0] * s, oy + BOX[3] * s)
    canvas.scale(s, -s)  # model space, y up

    j = joints(p)
    sh = skia.Paint(Color=0x882E7BFF, AntiAlias=True,
                    MaskFilter=skia.MaskFilter.MakeBlur(skia.kNormal_BlurStyle, 5))
    canvas.drawOval(skia.Rect.MakeXYWH(j["hip"][0] - 42, -3.5, 84, 7), sh)

    parts = figure_parts(p, limb)
    tails = [x[1] for x in parts if isinstance(x, tuple)]
    parts = [x for x in parts if not isinstance(x, tuple)]
    for pt in parts:
        if pt.glow:
            canvas.drawPath(pt.path, skia.Paint(Color=0xAA35C8FF, AntiAlias=True,
                            MaskFilter=skia.MaskFilter.MakeBlur(skia.kNormal_BlurStyle, 7)))
    for pt in parts:
        if pt.gap:
            canvas.drawPath(pt.path, skia.Paint(Color=GAP, AntiAlias=True, Style=skia.Paint.kStroke_Style,
                                                StrokeWidth=2.6, StrokeJoin=skia.Paint.kRound_Join))
        # rim light: fill with rim colour, then the body gradient shifted away from the light
        canvas.save()
        canvas.clipPath(pt.path, skia.ClipOp.kIntersect, True)
        canvas.drawPath(pt.path, skia.Paint(Color=pt.rim, AntiAlias=True))
        canvas.translate(-1.5, -1.3)
        canvas.drawPath(pt.path, skia.Paint(AntiAlias=True, Shader=lin(LIGHT_A, LIGHT_B, pt.ca, pt.cb)))
        canvas.restore()
        for sp, col, w in pt.stripes:
            canvas.save()
            canvas.clipPath(pt.path, skia.ClipOp.kIntersect, True)
            canvas.drawPath(sp, skia.Paint(Color=col, AntiAlias=True, Style=skia.Paint.kStroke_Style,
                                           StrokeWidth=w, StrokeCap=skia.Paint.kRound_Cap))
            canvas.restore()
        if pt.stripes and pt.ca == BODY_A:
            for t in tails:
                canvas.drawPath(t, skia.Paint(Color=STRIPE, AntiAlias=True, Style=skia.Paint.kStroke_Style,
                                              StrokeWidth=2.6, StrokeCap=skia.Paint.kRound_Cap))
    canvas.restore()


def background(canvas, W, H):
    bg = skia.Paint(Shader=skia.GradientShader.MakeLinear(
        [skia.Point(0, 0), skia.Point(W, H)], [0xFF0B1630, 0xFF05070D, 0xFF0A1226]))
    canvas.drawRect(skia.Rect.MakeWH(W, H), bg)


def render(moves, out, tile=(300, 280)):
    frames = []
    for name in moves:
        m = MOVES[name]
        frames.append((name + " guard", GUARD, m["limb"]))
        for k in m["kfs"]:
            frames.append((name + " " + k["label"], k["pose"], m["limb"]))
    cols = 4
    rows = (len(frames) + cols - 1) // cols
    surf = skia.Surface(tile[0] * cols, tile[1] * rows)
    c = surf.getCanvas()
    c.clear(0xFF000000)
    font = skia.Font(None, 13)
    for i, (label, p, limb) in enumerate(frames):
        c.save()
        c.translate((i % cols) * tile[0], (i // cols) * tile[1])
        c.clipRect(skia.Rect.MakeWH(tile[0] - 4, tile[1] - 4))
        background(c, tile[0], tile[1])
        lim = {"la": "la", "ra": "ra", "ll": "ll", "rl": "rl"}.get(limb)
        draw(c, p, (tile[0] - 4, tile[1] - 4), lim if "guard" not in label else None)
        c.drawString(label, 6, 16, font, skia.Paint(Color=0xFFFFFFFF))
        c.restore()
    surf.makeImageSnapshot().save(out, skia.kPNG)
    print("wrote", out)


if __name__ == "__main__":
    out = sys.argv[1]
    moves = sys.argv[2:] or ["jab", "cross", "lhook", "rhigh", "teep", "lowkick"]
    render(moves, out)
