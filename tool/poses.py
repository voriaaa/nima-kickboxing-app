"""Source of truth for the animated fighter poses.

Run:  python3 tool/poses.py preview OUT_DIR   -> PNG contact sheets for checking poses
      python3 tool/poses.py dart              -> rewrites lib/moves/pose_data.g.dart

Model space: side view, fighter faces +x (right), orthodox stance (left foot forward),
y points UP, the floor is y = 0. Angles are absolute degrees: 0 = forward (+x),
90 = up, -90 = down. The lead (left) side is nearer the viewer and drawn on top.
The forward kinematics here must match lib/moves/fighter.dart exactly.
"""

import math
import os
import sys

# Segment lengths (model units). Keep in sync with fighter.dart.
L = dict(torso=52, shoulder=47, neck_head=19, head_r=11, upper=30, fore=28,
         thigh=44, shin=42, foot=14)

FIELDS = ["hx", "hy", "t", "hd", "sh", "hs",
          "lu", "lf", "ru", "rf",
          "lt", "ls", "lfo", "rt", "rs", "rfo",
          "lus", "lfs", "rus", "rfs", "lts", "lss", "rts", "rss"]

GUARD = dict(hx=0, hy=84, t=82, hd=0, sh=5, hs=4,
             lu=-58, lf=72, ru=-82, rf=78,
             lt=-65, ls=-100, lfo=0, rt=-112, rs=-105, rfo=-18,
             lus=1, lfs=1, rus=1, rfs=1, lts=1, lss=1, rts=1, rss=1)


def pose(**over):
    p = dict(GUARD)
    for k, v in over.items():
        assert k in p, k
        p[k] = v
    return p


def kf(label, ms, hold=0, **over):
    return dict(label=label, ms=ms, hold=hold, pose=pose(**over))


# Support-leg pose used by most kicks (standing on one leg under the hip).
STAND_ON_LEAD = dict(lt=-88, ls=-93, lfo=-5)
STAND_ON_REAR = dict(rt=-95, rs=-92, rfo=-8)
REAR_ARM_SWING = dict(ru=-128, rf=-112)   # rear arm swings down and back on rear kicks
LEAD_ARM_SWING = dict(lu=-132, lf=-118)

MOVES = {
    "guard": dict(limb=None, kfs=[
        kf("گارد", 450, 150, hy=82, lts=1.0),
        kf("گارد", 450, 150),
    ], arrows=[]),

    "jab": dict(limb="la", kfs=[
        kf("ضربه", 200, 140, hx=4, t=78, sh=7, lu=6, lf=6, lfo=0),
    ], arrows=[((48, 147), (70, 149), (92, 147))]),

    "cross": dict(limb="ra", kfs=[
        kf("ضربه", 230, 140, hx=7, t=74, sh=-4, ru=6, rf=6, lu=-62, lf=82,
           rt=-102, rs=-122, rfo=-48),
    ], arrows=[((50, 147), (72, 149), (96, 147))]),

    "lhook": dict(limb="la", kfs=[
        kf("آمادگی", 160, 0, hx=2, t=80, lu=-20, lus=0.7, lf=40, lfo=-10),
        kf("ضربه", 180, 150, hx=4, t=78, sh=2, lu=8, lus=0.55, lf=4, lfs=0.95, lfo=-35),
    ], arrows=[((16, 150), (52, 172), (70, 146))]),

    "rhook": dict(limb="ra", kfs=[
        kf("آمادگی", 160, 0, hx=4, t=78, sh=0, ru=-25, rus=0.7, rf=45),
        kf("ضربه", 200, 150, hx=7, t=75, sh=-5, ru=8, rus=0.55, rf=4, rfs=0.95,
           lu=-62, lf=82, rt=-102, rs=-122, rfo=-50),
    ], arrows=[((6, 152), (48, 176), (70, 147))]),

    "lupper": dict(limb="la", kfs=[
        kf("آمادگی", 220, 60, hy=78, t=74, lu=-95, lf=40, lt=-58, ls=-110, rt=-118, rs=-98),
        kf("ضربه", 200, 140, hy=86, t=86, lu=-35, lf=86, lfo=-20),
    ], arrows=[((38, 108), (52, 120), (44, 160))]),

    "rupper": dict(limb="ra", kfs=[
        kf("آمادگی", 220, 60, hy=78, t=74, ru=-100, rf=35, lt=-58, ls=-110, rt=-118, rs=-98),
        kf("ضربه", 220, 140, hx=6, hy=86, t=80, sh=-4, ru=-38, rf=86, lu=-62, lf=82,
           rt=-102, rs=-122, rfo=-50),
    ], arrows=[((34, 106), (50, 118), (42, 162))]),

    "teep": dict(limb="ll", kfs=[
        kf("بالا آوردن زانو", 260, 60, hx=-6, t=92, lt=28, ls=-78, lfo=10, **STAND_ON_REAR),
        kf("ضربه", 200, 160, hx=-8, t=102, lt=12, ls=10, lfo=95, **STAND_ON_REAR),
    ], arrows=[((60, 108), (86, 110), (112, 106))]),

    "lowkick": dict(limb="rl", kfs=[
        kf("ضربه", 300, 150, hx=6, t=102, rt=-28, rs=-24, rfo=-22,
           **STAND_ON_LEAD, **REAR_ARM_SWING),
    ], arrows=[((-34, 30), (24, 6), (86, 58))]),

    "midkick": dict(limb="rl", kfs=[
        kf("بالا آوردن زانو", 230, 0, hx=2, t=96, rt=-8, rs=-100, rfo=-50, **STAND_ON_LEAD),
        kf("ضربه", 230, 150, hx=4, t=110, rt=4, rs=6, rfo=4,
           **STAND_ON_LEAD, **REAR_ARM_SWING),
    ], arrows=[((-34, 40), (30, 20), (96, 92))]),

    "rhigh": dict(limb="rl", kfs=[
        kf("بالا آوردن زانو", 240, 0, hx=2, t=100, rt=10, rs=-92, rfo=-40, **STAND_ON_LEAD),
        kf("ضربه", 240, 160, hx=2, t=122, rt=42, rs=46, rfo=46,
           **STAND_ON_LEAD, **REAR_ARM_SWING),
    ], arrows=[((-34, 50), (40, 34), (92, 150))]),

    "lhigh": dict(limb="ll", kfs=[
        kf("تعویض پا", 200, 0, hx=-10, hy=82, t=90, lt=-80, ls=-95, rt=-90, rs=-92),
        kf("چرخش", 220, 0, hx=-12, t=104, lt=-5, ls=-90, lfo=-30, **STAND_ON_REAR),
        kf("ضربه", 240, 160, hx=-14, t=124, lt=44, ls=48, lfo=48,
           **STAND_ON_REAR, **LEAD_ARM_SWING),
    ], arrows=[((-4, 52), (54, 40), (86, 152))]),

    "sidekick": dict(limb="ll", kfs=[
        kf("جمع کردن", 260, 60, hx=-8, t=112, lt=40, ls=-62, lfo=-40, **STAND_ON_REAR),
        kf("ضربه", 200, 160, hx=-10, t=128, lt=6, ls=4, lfo=-70, **STAND_ON_REAR),
    ], arrows=[((58, 96), (86, 98), (114, 96))]),

    "knee": dict(limb="rl", kfs=[
        kf("گرفتن", 220, 0, hx=4, t=88, lu=18, lf=30, ru=14, rf=30),
        kf("ضربه", 220, 150, hx=6, hy=88, t=98, lu=-12, lf=20, ru=-16, rf=18,
           rt=62, rs=-92, rfo=-62, **STAND_ON_LEAD),
    ], arrows=[((-14, 56), (24, 66), (40, 114))]),

    "slip": dict(limb=None, kfs=[
        kf("جاخالی", 220, 220, hx=6, hy=80, t=68, hd=-10, lt=-58, ls=-108, rt=-118, rs=-100),
    ], arrows=[((24, 168), (36, 160), (44, 148))]),

    "duck": dict(limb=None, kfs=[
        kf("زیر رفتن", 260, 220, hx=2, hy=64, t=62, hd=-6,
           lt=-30, ls=-118, rt=-138, rs=-92, rfo=-30,
           lu=-70, lf=70, ru=-90, rf=74),
    ], arrows=[((-4, 160), (6, 128), (4, 110))]),

    "check": dict(limb="ll", kfs=[
        kf("بلاک", 220, 260, hx=-4, t=88, lt=52, ls=-82, lfo=10,
           lu=-40, lf=88, **STAND_ON_REAR),
    ], arrows=[]),

    "leanback": dict(limb=None, kfs=[
        kf("عقب کشیدن", 240, 220, hx=-10, t=108, hd=10,
           lt=-56, ls=-92, rt=-118, rs=-108, rfo=-10),
    ], arrows=[((40, 156), (24, 162), (8, 158))]),
}


def d(a):
    r = math.radians(a)
    return (math.cos(r), math.sin(r))


def add(p, v, s=1.0):
    return (p[0] + v[0] * s, p[1] + v[1] * s)


def joints(p):
    hip = (p["hx"], p["hy"])
    fwd = d(p["t"] - 90)
    neck = add(hip, d(p["t"]), L["torso"])
    sh = add(hip, d(p["t"]), L["shoulder"])
    head = add(neck, d(p["t"] + p["hd"]), L["neck_head"])
    j = dict(hip=hip, neck=neck, head=head)
    j["ls"] = add(sh, fwd, p["sh"])
    j["rs"] = add(sh, fwd, -p["sh"])
    j["lh"] = add(hip, fwd, p["hs"])
    j["rh"] = add(hip, fwd, -p["hs"])
    for s in "lr":
        e = add(j[s + "s"], d(p[s + "u"]), L["upper"] * p[s + "us"])
        w = add(e, d(p[s + "f"]), L["fore"] * p[s + "fs"])
        k = add(j[s + "h"], d(p[s + "t"]), L["thigh"] * p[s + "ts"])
        a = add(k, d(p[s + "s"]), L["shin"] * p[s + "ss"])
        toe = add(a, d(p[s + "fo"]), L["foot"])
        j[s + "e"], j[s + "w"], j[s + "k"], j[s + "a"], j[s + "toe"] = e, w, k, a, toe
    return j


# ---------------------------------------------------------------- preview

BOX = (-70, -6, 140, 192)  # x0, y0, x1, y1 in model units


def render(p, size=360, limb=None, arrows=()):
    from PIL import Image, ImageDraw
    ss = 3
    W = int(size * ss)
    sx = W / (BOX[2] - BOX[0])
    H = int((BOX[3] - BOX[1]) * sx)
    img = Image.new("RGB", (W, H), (6, 9, 18))
    dr = ImageDraw.Draw(img)

    def P(q):
        return ((q[0] - BOX[0]) * sx, (BOX[3] - q[1]) * sx)

    def seg(a, b, w, col):
        w = w * sx
        dr.line([P(a), P(b)], fill=col, width=int(w))
        for q in (a, b):
            x, y = P(q)
            dr.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill=col)

    def circ(q, r, col):
        x, y = P(q)
        r = r * sx
        dr.ellipse([x - r, y - r, x + r, y + r], fill=col)

    dr.line([P((BOX[0], 0)), P((BOX[2], 0))], fill=(30, 50, 90), width=int(1.5 * sx))
    j = joints(p)
    rear, lead, body, act = (31, 84, 170), (79, 163, 255), (92, 170, 255), (120, 235, 255)

    def col(side, part):
        tag = side + part
        return act if limb == tag else (lead if side == "l" else rear)

    for s in ("r",):
        seg(j["rs"], j["re"], 9, col("r", "a")); seg(j["re"], j["rw"], 8, col("r", "a"))
        circ(j["rw"], 8.5, col("r", "a"))
        seg(j["rh"], j["rk"], 11, col("r", "l")); seg(j["rk"], j["ra"], 9, col("r", "l"))
        seg(j["ra"], j["rtoe"], 6, col("r", "l"))
    seg(j["hip"], j["neck"], 15, body)
    circ(j["head"], L["head_r"], body)
    seg(j["lh"], j["lk"], 11, col("l", "l")); seg(j["lk"], j["la"], 9, col("l", "l"))
    seg(j["la"], j["ltoe"], 6, col("l", "l"))
    seg(j["ls"], j["le"], 9, col("l", "a")); seg(j["le"], j["lw"], 8, col("l", "a"))
    circ(j["lw"], 8.5, col("l", "a"))
    for a, c, b in arrows:
        pts = []
        for i in range(21):
            u = i / 20
            pts.append(((1 - u) ** 2 * a[0] + 2 * (1 - u) * u * c[0] + u * u * b[0],
                        (1 - u) ** 2 * a[1] + 2 * (1 - u) * u * c[1] + u * u * b[1]))
        dr.line([P(q) for q in pts], fill=(255, 200, 60), width=int(2 * sx))
        circ(b, 3, (255, 200, 60))
    return img.resize((size, int(H / ss)))


def preview(out):
    from PIL import Image, ImageDraw
    os.makedirs(out, exist_ok=True)
    tiles = []
    for name, m in MOVES.items():
        frames = [("گارد", GUARD)] + [(k["label"], k["pose"]) for k in m["kfs"]]
        for i, (_, p) in enumerate(frames):
            last = i == len(frames) - 1
            tiles.append((f"{name} {i}", render(p, 240, m["limb"], m["arrows"] if last else ())))
    cols = 6
    w, h = tiles[0][1].size
    rows = (len(tiles) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * w, rows * (h + 18)), (0, 0, 0))
    dr = ImageDraw.Draw(sheet)
    for i, (label, im) in enumerate(tiles):
        x, y = (i % cols) * w, (i // cols) * (h + 18)
        sheet.paste(im, (x, y + 18))
        dr.text((x + 4, y + 3), label, fill=(255, 255, 255))
    sheet.save(os.path.join(out, "sheet.png"))
    print("wrote", os.path.join(out, "sheet.png"), sheet.size)


# ---------------------------------------------------------------- dart output

def fmt(v):
    v = round(float(v), 3)
    return str(int(v)) + ".0" if v == int(v) else repr(v)


def dart_pose(p, indent):
    parts = [f"{k}: {fmt(p[k])}" for k in FIELDS if k in GUARD and (p[k] != GUARD[k] or k in ("hx", "hy"))]
    return "Pose(" + ", ".join(parts) + ")"


def dart():
    lines = [
        "// GENERATED by tool/poses.py — do not edit by hand.",
        "// Edit tool/poses.py and run: python3 tool/poses.py dart",
        "",
        "import 'fighter.dart';",
        "",
        "const guardPose = " + "Pose();",
        "",
        "const moveClips = <String, MoveClip>{",
    ]
    for name, m in MOVES.items():
        lines.append(f"  '{name}': MoveClip(")
        lines.append(f"    limb: {('Limb.' + {'la': 'leadArm', 'ra': 'rearArm', 'll': 'leadLeg', 'rl': 'rearLeg'}[m['limb']]) if m['limb'] else 'null'},")
        lines.append("    keyframes: [")
        for k in m["kfs"]:
            lines.append(f"      Keyframe('{k['label']}', {k['ms']}, {k['hold']},")
            lines.append(f"          {dart_pose(k['pose'], 10)}),")
        lines.append("    ],")
        lines.append("    arrows: [")
        for a, c, b in m["arrows"]:
            lines.append(f"      Arrow({fmt(a[0])}, {fmt(a[1])}, {fmt(c[0])}, {fmt(c[1])}, {fmt(b[0])}, {fmt(b[1])}),")
        lines.append("    ],")
        lines.append("  ),")
    lines.append("};")
    path = os.path.join(os.path.dirname(__file__), "..", "lib", "moves", "pose_data.g.dart")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print("wrote", os.path.normpath(path))


if __name__ == "__main__":
    if sys.argv[1] == "preview":
        preview(sys.argv[2])
    else:
        dart()
