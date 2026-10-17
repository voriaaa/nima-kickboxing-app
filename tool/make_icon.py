"""Builds the launcher icon from the high-kick pose in the athlete style.
Run: python3 tool/make_icon.py   (needs: pip install skia-python)"""
import os
import sys

import skia

sys.path.insert(0, os.path.dirname(__file__))
from figure_preview import draw  # noqa: E402
from poses import MOVES  # noqa: E402

S = 1024
HERE = os.path.join(os.path.dirname(__file__), "..", "assets", "icon")
POSE = MOVES["rhigh"]["kfs"][-1]["pose"]


def make(path, background, ring_r, fig_size, fig_offset):
    surf = skia.Surface(S, S)
    c = surf.getCanvas()
    c.clear(skia.ColorTRANSPARENT)
    if background:
        c.drawRect(skia.Rect.MakeWH(S, S), skia.Paint(Shader=skia.GradientShader.MakeRadial(
            skia.Point(S / 2, S * 0.42), S * 0.75, [0xFF13264D, 0xFF05070D])))
    ring = skia.Paint(Color=0xFF2E7BFF, AntiAlias=True, Style=skia.Paint.kStroke_Style, StrokeWidth=S * 0.022)
    glow = skia.Paint(Color=0xAA2E7BFF, AntiAlias=True, Style=skia.Paint.kStroke_Style, StrokeWidth=S * 0.04,
                      MaskFilter=skia.MaskFilter.MakeBlur(skia.kNormal_BlurStyle, S * 0.02))
    c.drawCircle(S / 2, S / 2, ring_r, glow)
    c.drawCircle(S / 2, S / 2, ring_r, ring)
    c.save()
    c.translate(S / 2 - fig_size / 2 + fig_offset[0], S / 2 - fig_size / 2 + fig_offset[1])
    draw(c, POSE, (fig_size, fig_size), "rl")
    c.restore()
    surf.makeImageSnapshot().save(path, skia.kPNG)


make(os.path.join(HERE, "icon.png"), True, S * 0.40, S * 0.95, (S * 0.105, S * 0.02))
make(os.path.join(HERE, "foreground.png"), False, S * 0.29, S * 0.68, (S * 0.075, S * 0.015))
print("icons written")
