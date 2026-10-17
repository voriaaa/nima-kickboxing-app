"""Builds the launcher icon from the high-kick pose. Run: python3 tool/make_icon.py"""
import os, sys
from PIL import Image, ImageDraw, ImageFilter
sys.path.insert(0, os.path.dirname(__file__))
from poses import MOVES, joints, L

S = 1024
BLUE, CYAN, REAR = (46, 123, 255), (111, 231, 255), (30, 79, 166)


def fighter_layer(scale, cx, cy):
    p = MOVES["rhigh"]["kfs"][-1]["pose"]
    j = joints(p)
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    dr = ImageDraw.Draw(img)
    # centre the figure on its bounding box
    pts = [v for v in j.values()]
    xs = [q[0] for q in pts]; ys = [q[1] for q in pts]
    mx, my = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
    def P(q):
        return (cx + (q[0] - mx) * scale, cy - (q[1] - my) * scale)
    def seg(a, b, w, col):
        w *= scale
        dr.line([P(a), P(b)], fill=col, width=int(w))
        for q in (a, b):
            x, y = P(q); dr.ellipse([x - w/2, y - w/2, x + w/2, y + w/2], fill=col)
    def dot(q, r, col):
        x, y = P(q); r *= scale; dr.ellipse([x - r, y - r, x + r, y + r], fill=col)
    seg(j["rh"], j["rk"], 11, CYAN); seg(j["rk"], j["ra"], 9, CYAN); seg(j["ra"], j["rtoe"], 6, CYAN)
    seg(j["rs"], j["re"], 9, REAR); seg(j["re"], j["rw"], 8, REAR); dot(j["rw"], 8.5, REAR)
    seg(j["hip"], j["neck"], 15, BLUE); dot(j["head"], L["head_r"], BLUE)
    seg(j["lh"], j["lk"], 11, BLUE); seg(j["lk"], j["la"], 9, BLUE); seg(j["la"], j["ltoe"], 6, BLUE)
    seg(j["ls"], j["le"], 9, BLUE); seg(j["le"], j["lw"], 8, BLUE); dot(j["lw"], 8.5, BLUE)
    return img


def compose(bg, ring_r, scale):
    base = Image.new("RGBA", (S, S), bg)
    ring = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(ring)
    c = S / 2
    d.ellipse([c - ring_r, c - ring_r, c + ring_r, c + ring_r], outline=BLUE + (255,), width=int(S * 0.022))
    fig = fighter_layer(scale, c, c + S * 0.01)
    glow = Image.alpha_composite(ring, fig).filter(ImageFilter.GaussianBlur(S * 0.02))
    out = Image.alpha_composite(base, glow)
    out = Image.alpha_composite(out, ring)
    return Image.alpha_composite(out, fig)


here = os.path.join(os.path.dirname(__file__), "..", "assets", "icon")
compose((5, 7, 13, 255), S * 0.40, S * 0.0040).save(os.path.join(here, "icon.png"))
compose((0, 0, 0, 0), S * 0.30, S * 0.0029).save(os.path.join(here, "foreground.png"))
print("icons written")
