"""장면 전용 소품(증상별) — `characters.py`의 공용 소품을 보충한다."""
from __future__ import annotations

import math

from clay import (
    Clay, arc, bezier_pts, capsule, circle, cloud, drop, ellipse, heart,
    polygon, polyline, rbox, rpolygon, star,
)
from characters import (
    BLUSH, BROWN, BUTTER, CORAL, CREAM, EYE, GREY, HAIR, HONEY, LILAC, LILAC_DEEP, MILK,
    MINT, MINT_DEEP, PEACH, PINK, PINK_DEEP, RED, SKIN, SKY, SKY_DEEP, TEAR, WHITE,
    _top, curl, dot_ball, sparkle,
)


def tissue_box(c: Clay, x, y, s=1.0, box=PINK, tissue=WHITE):
    top = _top(c, x, y)
    c.blob(rbox(x, y, 30 * s, 20 * s, 6 * s), box, bevel=6 * s, height=7 * s, mode="max", lift=top, k=1, gloss=0.25, tag="box")
    c.paint(rbox(x, y - 7.5 * s, 14 * s, 3.2 * s, 1.6 * s), "#E07A93", soft=0.3, on="box")
    puff = cloud(x, y - 13 * s, 16 * s, 12 * s)
    c.blob(puff, tissue, bevel=4 * s, height=5 * s, mode="max", lift=top + 3 * s, k=1, gloss=0.12)
    c.paint(heart(x + 7 * s, y + 3 * s, 3 * s), WHITE, soft=0.3, on="box")


def teether(c: Clay, x, y, s=1.0, ring=BUTTER, bead=MINT_DEEP):
    top = _top(c, x, y)
    ring_shape = circle(x, y, 9.5 * s) - circle(x, y, 5.2 * s)
    c.blob(ring_shape, ring, bevel=2.2 * s, height=3.2 * s, mode="max", lift=top + 1, k=1, gloss=0.35)
    for a in (200, 250, 300):
        bx = x + 7.4 * s * math.cos(math.radians(a))
        by = y + 7.4 * s * math.sin(math.radians(a))
        c.blob(circle(bx, by, 2.4 * s), bead, bevel=2.4 * s, height=2.2 * s, gloss=0.4)


def bib(c: Clay, cx, top, s=1.0, color=PINK, deco=WHITE):
    shape = (ellipse(cx, top + 9 * s, 17 * s, 13 * s) - ellipse(cx, top - 1 * s, 9 * s, 6 * s))
    c.blob(shape, color, bevel=3.5 * s, height=3.5 * s, gloss=0.2, tag="bib")
    c.paint(heart(cx, top + 11 * s, 3.4 * s), deco, soft=0.3, on="bib")
    # 가장자리 스캘럽 점.
    for i in range(9):
        a = math.radians(20 + i * 17.5)
        c.paint(circle(cx + 14.5 * s * math.cos(a), top + 9 * s + 10.6 * s * math.sin(a), 0.9 * s), deco, soft=0.2, on="bib")


def fan(c: Clay, x, y, s=1.0, body=MINT, blade=WHITE, hub=PINK_DEEP):
    top = _top(c, x, y)
    c.blob(capsule(x, y + 8 * s, x, y + 21 * s, 2.6 * s), body, bevel=2.6 * s, height=3 * s, mode="max", lift=top, gloss=0.3)
    c.blob(ellipse(x, y + 23 * s, 9 * s, 3.4 * s), body, bevel=3 * s, height=3.4 * s, mode="max", lift=top, k=1, gloss=0.3)
    c.blob(circle(x, y, 13 * s), body, bevel=4 * s, height=4 * s, mode="max", lift=top + 1, k=1, gloss=0.3, tag="fan")
    c.paint(circle(x, y, 10.6 * s), "#E9F7F1", soft=0.3, on="fan")
    for a in (0, 120, 240):
        bx = x + 5.2 * s * math.cos(math.radians(a - 90))
        by = y + 5.2 * s * math.sin(math.radians(a - 90))
        c.blob(ellipse(bx, by, 3.6 * s, 5.8 * s, deg=a), blade, bevel=2 * s, height=2 * s, gloss=0.3)
    c.blob(circle(x, y, 2.4 * s), hub, bevel=2.4 * s, height=2.6 * s, gloss=0.4)


def magnifier(c: Clay, x, y, s=1.0, deg=40.0, rim=SKY_DEEP, handle=PINK_DEEP):
    top = _top(c, x, y)
    hx = x + 16 * s * math.cos(math.radians(deg))
    hy = y + 16 * s * math.sin(math.radians(deg))
    c.blob(capsule(x + 9 * s * math.cos(math.radians(deg)), y + 9 * s * math.sin(math.radians(deg)), hx, hy, 2.9 * s),
           handle, bevel=2.9 * s, height=3.2 * s, mode="max", lift=top + 1, gloss=0.35)
    c.blob(circle(x, y, 10 * s) - circle(x, y, 7.2 * s), rim, bevel=1.6 * s, height=3.2 * s, mode="max", lift=top + 1.5, k=0.8, gloss=0.4)
    c.blob(circle(x, y, 7.4 * s), "#E8F4FC", bevel=5 * s, height=1.4 * s, mode="max", lift=top + 1.5, gloss=0.9, tag="lens")
    c.paint(ellipse(x - 2.6 * s, y - 2.8 * s, 2.2 * s, 1.2 * s, deg=-40), WHITE, soft=0.4, on="lens")


def speech_bubble(c: Clay, x, y, w, h, color=WHITE, tail="left"):
    top = _top(c, x, y)
    body = rbox(x, y, w, h, h * 0.48)
    tx = x - w * 0.28 if tail == "left" else x + w * 0.28
    tip = (tx - (6 if tail == "left" else -6), y + h * 0.5 + 6)
    tri = polygon([(tx - 4, y + h * 0.2), (tx + 4, y + h * 0.2), tip]).dilate(0.8)
    c.blob(body.smooth(tri, 2.0), color, bevel=h * 0.3, height=h * 0.28, mode="max", lift=top, k=1, gloss=0.18, tag="bubble")


def exclaim(c: Clay, x, y, h, color=CORAL):
    top = _top(c, x, y)
    c.blob(capsule(x, y - h * 0.5, x, y + h * 0.12, h * 0.13, h * 0.09), color, bevel=h * 0.12, height=h * 0.14, mode="max", lift=top + 0.5, gloss=0.3)
    c.blob(circle(x, y + h * 0.42, h * 0.12), color, bevel=h * 0.12, height=h * 0.13, mode="max", lift=top + 0.5, gloss=0.3)


def question(c: Clay, x, y, h, color=LILAC_DEEP):
    top = _top(c, x, y)
    r = h * 0.26
    pts = []
    for i in range(0, 25):
        t = i / 24
        a = math.radians(190 + 250 * t)
        pts.append((x + r * math.cos(a), y - h * 0.22 + r * math.sin(a)))
    pts += bezier_pts(pts[-1], (x, y + 0.02 * h), (x, y + 0.05 * h), (x, y + h * 0.15), 8)[1:]
    c.blob(polyline(pts, h * 0.1), color, bevel=h * 0.1, height=h * 0.12, mode="max", lift=top + 0.5, gloss=0.3)
    c.blob(circle(x, y + h * 0.4, h * 0.11), color, bevel=h * 0.11, height=h * 0.12, mode="max", lift=top + 0.5, gloss=0.3)


def syringe(c: Clay, x, y, s=1.0, deg=-40.0, body=SKY, plunger=PINK_DEEP, tip=GREY):
    def R(shape):
        return shape.rotate(deg, x, y)
    top = _top(c, x, y)
    c.blob(R(rbox(x - 14 * s, y, 5 * s, 12 * s, 2.2 * s)), plunger, bevel=2.2 * s, height=2.6 * s, mode="max", lift=top, gloss=0.3)
    c.blob(R(rbox(x - 8 * s, y, 6 * s, 4 * s, 1.6 * s)), plunger, bevel=1.6 * s, height=2 * s, mode="max", lift=top, gloss=0.3)
    c.blob(R(rbox(x + 2 * s, y, 20 * s, 10 * s, 4.5 * s)), body, bevel=4.5 * s, height=5 * s, mode="max", lift=top + 0.5, k=1, gloss=0.4, tag="syr")
    for i in range(3):
        c.paint(R(capsule(x - 3 * s + i * 4.5 * s, y - 4.6 * s, x - 3 * s + i * 4.5 * s, y - 2.2 * s, 0.55 * s)), WHITE, soft=0.2, on="syr")
    c.blob(R(capsule(x + 12 * s, y, x + 19 * s, y, 1.4 * s, 0.9 * s)), tip, bevel=1.2 * s, height=1.4 * s, mode="max", lift=top + 0.5, gloss=0.5)


def formula_can(c: Clay, x, y, s=1.0, body=BUTTER, lid=PINK, label=WHITE):
    top = _top(c, x, y)
    c.blob(rbox(x, y, 26 * s, 30 * s, 7 * s), body, bevel=6 * s, height=7 * s, mode="max", lift=top, k=1, gloss=0.28, tag="can")
    c.blob(rbox(x, y - 15 * s, 28 * s, 7 * s, 3.5 * s), lid, bevel=3.5 * s, height=4 * s, mode="max", lift=top + 2, k=1, gloss=0.3)
    c.paint(ellipse(x, y + 2 * s, 8.5 * s, 7.5 * s), label, soft=0.3, on="can")
    c.paint(heart(x, y + 2 * s, 3.6 * s), PINK_DEEP, soft=0.3, on="can")


def scoop(c: Clay, x, y, s=1.0, color=WHITE, powder=CREAM, deg=-20.0):
    top = _top(c, x, y)
    c.blob(capsule(x + 5 * s, y, x + 17 * s, y - 2 * s, 1.8 * s).rotate(deg, x, y), color, bevel=1.8 * s, height=2 * s, mode="max", lift=top + 1, gloss=0.3)
    c.blob(ellipse(x, y, 6.4 * s, 4.8 * s, deg=deg), color, bevel=3 * s, height=3.6 * s, mode="max", lift=top + 1.5, k=0.8, gloss=0.3)
    c.blob(ellipse(x, y - 1.5 * s, 4.8 * s, 3.2 * s, deg=deg), powder, bevel=3 * s, height=2.2 * s, gloss=0.08)


def milk_bag(c: Clay, x, y, s=1.0, bag=MILK, zip_color=PINK_DEEP, milk="#FFF2D8"):
    """모유 저장팩 — 둥근 파우치 + 핑크 지퍼 + 날짜 라벨 + 반쯤 찬 모유."""
    top = _top(c, x, y)
    shape = rbox(x, y + 1 * s, 30 * s, 40 * s, 9 * s).smooth(ellipse(x, y + 16 * s, 16 * s, 8 * s), 3 * s)
    c.blob(shape, bag, bevel=8 * s, height=7 * s, mode="max", lift=top, k=1, gloss=0.35, tag="bag")
    c.paint(ellipse(x, y + 14 * s, 14 * s, 11 * s) & rbox(x, y + 16 * s, 40 * s, 24 * s, 0), milk, soft=0.8, on="bag")
    c.blob(rbox(x, y - 16 * s, 32 * s, 5 * s, 2.5 * s), zip_color, bevel=2.2 * s, height=2.6 * s, mode="max", lift=top + 3 * s, k=0.8, gloss=0.35)
    c.paint(rbox(x, y - 3 * s, 17 * s, 8 * s, 2.5 * s), WHITE, soft=0.3, on="bag")
    c.paint(heart(x - 4.5 * s, y - 3 * s, 2.0 * s), PINK_DEEP, soft=0.2, on="bag")
    for i in range(2):
        c.paint(capsule(x - 0.5 * s + i * 4 * s, y - 3 * s, x + 1.5 * s + i * 4 * s, y - 3 * s, 0.7 * s), GREY, soft=0.2, on="bag")


def snowflake(c: Clay, x, y, r, color=SKY_DEEP):
    top = _top(c, x, y)
    w = r * 0.16
    parts = None
    for a in (0, 60, 120):
        dx, dy = r * math.cos(math.radians(a)), r * math.sin(math.radians(a))
        seg = capsule(x - dx, y - dy, x + dx, y + dy, w)
        parts = seg if parts is None else parts | seg
    c.blob(parts, color, bevel=w, height=w * 1.2, mode="max", lift=top + 0.5, gloss=0.35)
    for a in range(0, 360, 60):
        c.blob(circle(x + r * math.cos(math.radians(a)), y + r * math.sin(math.radians(a)), w * 1.5), color, bevel=w * 1.5, height=w * 1.5, gloss=0.4)


def petal(c: Clay, x, y, s=1.0, deg=0.0, color=PINK):
    top = _top(c, x, y)
    shape = (circle(x, y + 3 * s, 6.5 * s) | polygon([(x - 6 * s, y + 1 * s), (x + 6 * s, y + 1 * s), (x, y - 10 * s)]).dilate(1.2 * s))
    notch = circle(x, y + 10.2 * s, 2.2 * s)
    c.blob((shape - notch).rotate(deg, x, y), color, bevel=3.5 * s, height=3.5 * s, mode="max", lift=top, k=0.6, gloss=0.25)


def sun(c: Clay, x, y, r, color=BUTTER, ray=HONEY, face=True):
    top = _top(c, x, y)
    for i in range(8):
        a = math.radians(i * 45 + 22.5)
        c.blob(capsule(x + r * 1.28 * math.cos(a), y + r * 1.28 * math.sin(a), x + r * 1.62 * math.cos(a), y + r * 1.62 * math.sin(a), r * 0.13),
               ray, bevel=r * 0.13, height=r * 0.15, mode="max", lift=top, gloss=0.3)
    c.blob(circle(x, y, r), color, bevel=r * 0.8, height=r * 0.7, mode="max", lift=top + 0.5, k=0.8, gloss=0.25, tag="sun")
    if face:
        for sx in (-1, 1):
            c.blob(arc(x + sx * r * 0.36, y - r * 0.02, r * 0.16, 200, 340, r * 0.06), EYE, bevel=r * 0.06, height=r * 0.05)
        c.paint(circle(x - r * 0.52, y + r * 0.28, r * 0.17), BLUSH, soft=r * 0.08, on="sun")
        c.paint(circle(x + r * 0.52, y + r * 0.28, r * 0.17), BLUSH, soft=r * 0.08, on="sun")


def leaf(c: Clay, x, y, s=1.0, deg=0.0, color=MINT_DEEP, vein=None):
    top = _top(c, x, y)
    shape = (circle(x - 6.5 * s, y, 11 * s) & circle(x + 6.5 * s, y, 11 * s)).rotate(deg, x, y)
    c.blob(shape, color, bevel=3.5 * s, height=3.2 * s, mode="max", lift=top, k=0.6, gloss=0.25, tag="leaf")
    if vein:
        c.paint(capsule(x, y - 7.5 * s, x, y + 7.5 * s, 0.5 * s).rotate(deg, x, y), vein, soft=0.2, on="leaf")


def sprout_pot(c: Clay, x, y, s=1.0, pot=CORAL, rim=PEACH):
    top = _top(c, x, y)
    c.blob(capsule(x, y - 6 * s, x, y - 16 * s, 1.5 * s), MINT_DEEP, bevel=1.5 * s, height=1.8 * s, mode="max", lift=top, gloss=0.2)
    leaf(c, x - 6 * s, y - 19 * s, 0.62 * s, deg=-50, color=MINT_DEEP)
    leaf(c, x + 6 * s, y - 20 * s, 0.7 * s, deg=50, color=MINT)
    body = polygon([(x - 11 * s, y - 6 * s), (x + 11 * s, y - 6 * s), (x + 8 * s, y + 11 * s), (x - 8 * s, y + 11 * s)]).dilate(1.6 * s)
    c.blob(body, pot, bevel=5 * s, height=6 * s, mode="max", lift=top + 1, k=1, gloss=0.25)
    c.blob(rbox(x, y - 6.5 * s, 27 * s, 6 * s, 3 * s), rim, bevel=3 * s, height=3.5 * s, mode="max", lift=top + 3, k=1, gloss=0.25)


def cotton_ball(c: Clay, x, y, r, color=WHITE):
    top = _top(c, x, y)
    shape = circle(x, y, r * 0.8)
    for a in range(0, 360, 60):
        shape = shape.smooth(circle(x + r * 0.5 * math.cos(math.radians(a)), y + r * 0.5 * math.sin(math.radians(a)), r * 0.5), r * 0.2)
    c.blob(shape, color, bevel=r * 0.6, height=r * 0.7, mode="max", lift=top, k=0.8, gloss=0.08)


def lotion(c: Clay, x, y, s=1.0, body=PEACH, pump=WHITE, label=WHITE):
    top = _top(c, x, y)
    c.blob(capsule(x, y - 16 * s, x, y - 22 * s, 1.8 * s), pump, bevel=1.8 * s, height=2 * s, mode="max", lift=top + 1, gloss=0.3)
    c.blob(capsule(x, y - 22 * s, x + 7 * s, y - 22 * s, 1.8 * s), pump, bevel=1.8 * s, height=2 * s, mode="max", lift=top + 1, gloss=0.3)
    c.blob(rbox(x, y - 15 * s, 9 * s, 5 * s, 2 * s), pump, bevel=2 * s, height=2.5 * s, mode="max", lift=top + 1, gloss=0.3)
    c.blob(rbox(x, y, 20 * s, 28 * s, 7 * s), body, bevel=6 * s, height=7 * s, mode="max", lift=top, k=1, gloss=0.3, tag="lotion")
    c.paint(rbox(x, y + 2 * s, 12 * s, 11 * s, 3 * s), label, soft=0.3, on="lotion")
    c.paint(heart(x, y + 2 * s, 2.6 * s), PINK_DEEP, soft=0.3, on="lotion")


def diaper_bag(c: Clay, x, y, s=1.0, body=PINK, flap=PINK_DEEP, strap=PEACH):
    top = _top(c, x, y)
    c.blob(arc(x, y - 16 * s, 15 * s, 195, 345, 2.6 * s), strap, bevel=2.6 * s, height=3 * s, mode="max", lift=top, gloss=0.25)
    shape = polygon([(x - 26 * s, y - 14 * s), (x + 26 * s, y - 14 * s), (x + 29 * s, y + 20 * s), (x - 29 * s, y + 20 * s)]).dilate(4 * s)
    c.blob(shape, body, bevel=10 * s, height=10 * s, mode="max", lift=top + 1, k=1, gloss=0.2, tag="dbag")
    c.paint(rbox(x, y - 8 * s, 58 * s, 12 * s, 6 * s) & rbox(x, y - 14 * s, 70 * s, 22 * s, 0), flap, soft=0.4, on="dbag")
    c.paint(heart(x, y + 7 * s, 5 * s), WHITE, soft=0.3, on="dbag")
    c.blob(circle(x, y - 2 * s, 2.6 * s), BUTTER, bevel=2.6 * s, height=2.4 * s, gloss=0.5)


def swaddle(c: Clay, cx, cy, s=1.0, color=PINK, trim=WHITE):
    """포대기로 싼 아가 몸통(머리는 소비처가 위에 얹는다)."""
    body = ellipse(cx, cy, 22 * s, 30 * s)
    c.blob(body, color, bevel=16 * s, height=13 * s, gloss=0.12, tag="swaddle")
    # 감싼 천의 겹 — 대각선 두 자락.
    c.blob(polygon([(cx - 21 * s, cy - 14 * s), (cx + 18 * s, cy + 6 * s), (cx + 14 * s, cy + 22 * s), (cx - 20 * s, cy + 4 * s)]).dilate(2 * s) & body.dilate(-1.2 * s),
           color, bevel=4 * s, height=3 * s, gloss=0.12, tag="swaddle")
    c.paint(capsule(cx - 19 * s, cy - 12 * s, cx + 17 * s, cy + 7 * s, 1.1 * s), trim, soft=0.3, on="swaddle", alpha=0.9)
    for (px, py) in ((-8, 14), (6, -10), (-12, -2), (10, 18)):
        c.paint(heart(cx + px * s, cy + py * s, 2.0 * s), trim, soft=0.3, on="swaddle", alpha=0.85)


def back_head(c: Clay, cx, cy, s=1.0, skin=SKIN):
    """뒤돌아 앉은 아가 뒷머리(귀 + 배냇머리 + 뒷머리 솜털)."""
    for sx in (-1, 1):
        c.blob(circle(cx + sx * 29.5 * s, cy + 3 * s, 6.4 * s), skin, bevel=6.4 * s, height=6 * s, tag="face")
    c.blob(ellipse(cx, cy, 30 * s, 27.5 * s), skin, bevel=21 * s, height=15 * s, mode="max", k=2.2 * s, tag="face", gloss=0.12)
    curl(c, cx, cy, s)


def bubbles(c: Clay, pts, color="#E9F3FC"):
    for (x, y, r) in pts:
        top = _top(c, x, y)
        c.blob(circle(x, y, r), color, bevel=r, height=r * 0.95, mode="max", lift=top, gloss=0.95, tag="bubble")
        c.paint(ellipse(x - r * 0.35, y - r * 0.4, r * 0.28, r * 0.18, deg=-35), WHITE, soft=r * 0.1, on="bubble")


def swatch(c: Clay, x, y, r, color):
    top = _top(c, x, y)
    c.blob(circle(x, y, r), WHITE, bevel=r * 0.6, height=r * 0.5, mode="max", lift=top, gloss=0.2, tag="sw")
    c.blob(circle(x, y, r * 0.66), color, bevel=r * 0.5, height=r * 0.35, gloss=0.25)


def cabbage_leaf(c: Clay, x, y, s=1.0, deg=0.0, color="#CDEBB0", vein="#EAF7DD"):
    top = _top(c, x, y)
    shape = ellipse(x, y, 16 * s, 19 * s).smooth(circle(x - 9 * s, y - 10 * s, 8 * s), 3 * s).smooth(circle(x + 9 * s, y - 11 * s, 8 * s), 3 * s)
    c.blob(shape.rotate(deg, x, y), color, bevel=5 * s, height=4 * s, mode="max", lift=top, k=1, gloss=0.2, tag="cab")
    c.paint(capsule(x, y + 16 * s, x, y - 14 * s, 0.9 * s).rotate(deg, x, y), vein, soft=0.3, on="cab")
    for sy, sx in ((-4, -1), (-4, 1), (5, -1), (5, 1)):
        c.paint(capsule(x, y + sy * s, x + sx * 10 * s, y + sy * s - 7 * s, 0.6 * s).rotate(deg, x, y), vein, soft=0.3, on="cab")


def gel_pack(c: Clay, x, y, s=1.0, color=PINK, deg=-10.0):
    top = _top(c, x, y)
    c.blob(heart(x, y, 16 * s, deg), color, bevel=7 * s, height=6 * s, mode="max", lift=top, k=1, gloss=0.55, tag="gel")
    for (px, py) in ((-6, -4), (4, 2), (-1, 8), (7, -6)):
        c.paint(circle(x + px * s, y + py * s, 1.2 * s), WHITE, soft=0.4, on="gel", alpha=0.8)


def nursing_pad(c: Clay, x, y, r, color=CREAM, stitch=PINK_DEEP):
    top = _top(c, x, y)
    c.blob(circle(x, y, r), color, bevel=r * 0.7, height=r * 0.35, mode="max", lift=top, k=0.8, gloss=0.1, tag="pad")
    c.paint(circle(x, y, r * 0.72) - circle(x, y, r * 0.64), stitch, soft=0.25, on="pad", alpha=0.5)
    c.paint(heart(x, y, r * 0.28), stitch, soft=0.2, on="pad", alpha=0.8)


def bandaid_round(c: Clay, x, y, r, color=PEACH, pad=CREAM):
    top = _top(c, x, y)
    c.blob(circle(x, y, r), color, bevel=r * 0.35, height=r * 0.2, mode="max", lift=top, k=0.5, gloss=0.2, tag="ba")
    c.paint(heart(x, y, r * 0.45), pad, soft=0.3, on="ba")


def clock(c: Clay, x, y, r, body=SKY, face=WHITE):
    top = _top(c, x, y)
    for sx in (-1, 1):
        c.blob(circle(x + sx * r * 0.62, y - r * 0.86, r * 0.34), body, bevel=r * 0.3, height=r * 0.3, mode="max", lift=top, gloss=0.3)
    c.blob(circle(x, y, r), body, bevel=r * 0.5, height=r * 0.5, mode="max", lift=top + 0.5, k=0.8, gloss=0.3, tag="clk")
    c.paint(circle(x, y, r * 0.74), face, soft=0.3, on="clk")
    c.blob(capsule(x, y, x, y - r * 0.5, r * 0.09), EYE, bevel=r * 0.08, height=r * 0.08)
    c.blob(capsule(x, y, x + r * 0.38, y + r * 0.1, r * 0.09), EYE, bevel=r * 0.08, height=r * 0.08)
    c.blob(circle(x, y, r * 0.12), PINK_DEEP, bevel=r * 0.12, height=r * 0.12)


def water_glass(c: Clay, x, y, s=1.0, glass="#E3F1FB", water=SKY):
    top = _top(c, x, y)
    body = polygon([(x - 10 * s, y - 13 * s), (x + 10 * s, y - 13 * s), (x + 8 * s, y + 13 * s), (x - 8 * s, y + 13 * s)]).dilate(1.6 * s)
    c.blob(body, glass, bevel=5 * s, height=5 * s, mode="max", lift=top, k=1, gloss=0.8, tag="glass")
    c.paint(polygon([(x - 9.2 * s, y - 3 * s), (x + 9.2 * s, y - 3 * s), (x + 7.8 * s, y + 12.5 * s), (x - 7.8 * s, y + 12.5 * s)]), water, soft=0.4, on="glass")
    c.paint(capsule(x - 5.5 * s, y - 9 * s, x - 5 * s, y + 7 * s, 0.9 * s), WHITE, soft=0.3, on="glass", alpha=0.8)


__all__ = [n for n in dir() if not n.startswith("__")]
_ = (BROWN, LILAC, MINT, RED, SKY, TEAR, dot_ball, sparkle, drop, rpolygon, star)
