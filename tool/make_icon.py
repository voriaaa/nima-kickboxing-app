"""Builds the launcher icon: a clenched fist with boxing hand wraps.
Run: python3 tool/make_icon.py   (needs: pip install skia-python)
Optional: python3 tool/make_icon.py /tmp/preview.png  -> also writes a preview sheet."""
import os
import sys

import skia

S = 1024
HERE = os.path.join(os.path.dirname(__file__), "..", "assets", "icon")


def P(color=None, style=None, w=None, shader=None, blur=None):
    p = skia.Paint(AntiAlias=True)
    if color is not None:
        p.setColor(color)
    if style == "stroke":
        p.setStyle(skia.Paint.kStroke_Style)
        p.setStrokeWidth(w)
        p.setStrokeCap(skia.Paint.kRound_Cap)
    if shader is not None:
        p.setShader(shader)
    if blur:
        p.setMaskFilter(skia.MaskFilter.MakeBlur(skia.kNormal_BlurStyle, blur))
    return p


def rrect(x, y, w, h, r):
    p = skia.Path()
    p.addRRect(skia.RRect.MakeRectXY(skia.Rect.MakeXYWH(x, y, w, h), r, r))
    return p


def lin(x0, y0, x1, y1, colors):
    return skia.GradientShader.MakeLinear([skia.Point(x0, y0), skia.Point(x1, y1)], colors)


def fist(c):
    """Draws the fist in a 1000x1000 box (knuckles toward the viewer)."""
    skin = [0xFFF0B98A, 0xFFC98456]
    skin_dark = 0xFF9A5C36

    # forearm + wrist
    arm = skia.Path()
    arm.moveTo(345, 1000)
    arm.lineTo(372, 690)
    arm.lineTo(628, 690)
    arm.lineTo(655, 1000)
    arm.close()
    c.drawPath(arm, P(shader=lin(340, 0, 660, 0, [0xFFC98456, 0xFFF0B98A, 0xFFBD7A4D])))

    # back of the hand
    hand = rrect(285, 330, 430, 400, 120)
    c.drawPath(hand, P(shader=lin(285, 330, 715, 730, skin)))

    # four fingers (curled), drawn as rounded blocks with dividers
    fx = [290, 396, 502, 608]
    for i, x in enumerate(fx):
        f = rrect(x, 255 + (14 if i in (0, 3) else 0) - (10 if i == 1 else 0), 102, 230, 50)
        c.drawPath(f, P(shader=lin(x, 255, x + 102, 485, [0xFFF7C9A0, 0xFFD18F5F])))
        c.drawPath(f, P(color=0x55712E12, style="stroke", w=5))
    # knuckle highlights
    for i, x in enumerate(fx):
        y = 285 + (14 if i in (0, 3) else 0) - (10 if i == 1 else 0)
        c.drawOval(skia.Rect.MakeXYWH(x + 26, y + 6, 50, 24), P(color=0x66FFFFFF, blur=7))

    # thumb folded across the fingers
    c.save()
    c.rotate(-6, 500, 520)
    thumb = rrect(312, 462, 392, 112, 56)
    c.drawPath(thumb, P(shader=lin(0, 462, 0, 574, [0xFFF3BE92, 0xFFC27D50])))
    c.drawPath(thumb, P(color=0x66712E12, style="stroke", w=5))
    c.restore()

    # ---- hand wraps (cloth) ----
    region = skia.Path()
    region.addPath(rrect(285, 330, 430, 400, 120))
    region.addPath(arm)
    clip = skia.Path()
    clip.addRect(skia.Rect.MakeLTRB(0, 600, 1000, 1000))
    c.save()
    c.clipPath(clip, skia.ClipOp.kIntersect, True)
    c.clipPath(region, skia.ClipOp.kIntersect, True)

    cloth = lin(0, 600, 0, 1000, [0xFFFFFFFF, 0xFFD6DEEC])
    c.drawRect(skia.Rect.MakeLTRB(0, 600, 1000, 1000), P(shader=cloth))
    # diagonal wrap strips
    step = 92
    for k in range(-2, 9):
        y0 = 600 + k * step
        strip = skia.Path()
        strip.moveTo(250, y0 + 70)
        strip.lineTo(750, y0 - 60)
        strip.lineTo(750, y0 - 60 + 78)
        strip.lineTo(250, y0 + 70 + 78)
        strip.close()
        c.drawPath(strip, P(shader=lin(0, y0 - 60, 0, y0 + 150,
                                       [0xFFFFFFFF, 0xFFE9EEF8, 0xFFBBC7DD])))
        c.drawLine(250, y0 + 70 + 78, 750, y0 - 60 + 78, P(color=0x66294A8F, style="stroke", w=6))
    # blue edge band at the cuff
    c.drawRect(skia.Rect.MakeLTRB(0, 604, 1000, 640), P(color=0xFF2E7BFF))
    c.drawRect(skia.Rect.MakeLTRB(0, 604, 1000, 612), P(color=0xFF6FE7FF))
    c.restore()
    # shadow under the knuckles / wrap on skin
    c.drawLine(300, 606, 700, 606, P(color=0x66000000, style="stroke", w=8, blur=6))

    # impact lines
    for (x0, y0, x1, y1) in [(140, 215, 235, 275), (860, 215, 765, 275), (500, 70, 500, 175),
                             (255, 110, 310, 195), (745, 110, 690, 195)]:
        c.drawLine(x0, y0, x1, y1, P(color=0xFF6FE7FF, style="stroke", w=22))


def make(path, background, ring_r, size, dx, dy):
    surf = skia.Surface(S, S)
    c = surf.getCanvas()
    c.clear(skia.ColorTRANSPARENT)
    if background:
        c.drawRect(skia.Rect.MakeWH(S, S), P(shader=skia.GradientShader.MakeRadial(
            skia.Point(S / 2, S * 0.42), S * 0.75, [0xFF13264D, 0xFF05070D])))
    c.drawCircle(S / 2, S / 2, ring_r, P(color=0xAA2E7BFF, style="stroke", w=S * 0.04, blur=S * 0.02))
    c.drawCircle(S / 2, S / 2, ring_r, P(color=0xFF2E7BFF, style="stroke", w=S * 0.022))
    # clip the fist to the ring so the forearm ends cleanly inside the circle
    ring = skia.Path()
    ring.addCircle(S / 2, S / 2, ring_r - S * 0.011)
    c.save()
    c.clipPath(ring, skia.ClipOp.kIntersect, True)
    c.translate(S / 2 - size / 2 + dx, S / 2 - size / 2 + dy)
    c.scale(size / 1000, size / 1000)
    fist(c)
    c.restore()
    surf.makeImageSnapshot().save(path, skia.kPNG)


make(os.path.join(HERE, "icon.png"), True, S * 0.42, S * 0.80, 0, S * 0.03)
make(os.path.join(HERE, "foreground.png"), False, S * 0.30, S * 0.56, 0, S * 0.02)
print("icons written")

if len(sys.argv) > 1:
    sheet = skia.Surface(2 * S, S)
    sc = sheet.getCanvas()
    sc.clear(0xFF222222)
    for i, n in enumerate(("icon.png", "foreground.png")):
        img = skia.Image.open(os.path.join(HERE, n))
        sc.drawImage(img, i * S, 0)
    sheet.makeImageSnapshot().save(sys.argv[1], skia.kPNG)
