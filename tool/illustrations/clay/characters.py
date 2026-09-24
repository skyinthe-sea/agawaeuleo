"""몽글 클레이 캐릭터·소품 라이브러리 — 모든 장면이 이 부품을 조합한다.

주인공 "아가": 크고 둥근 머리 + 양 귀 + 정수리의 **배냇머리 한 가닥**(브랜드 마크 —
앱 아이콘·스플래시와 같은 모티프) + 점 눈·볼터치·코 방울 + 표정별 입.
"엄마": 같은 얼굴 문법 + 초콜릿색 머리(똥머리 + 옆머리) + 분홍 머리핀.

치수는 전부 머리 반지름 기준 배율 s(=1이면 머리 가로 반지름 30단위)로 잡아,
장면이 캐릭터를 크게/작게 불러도 비례와 먹선(튜브) 굵기가 같이 움직인다.
"""
from __future__ import annotations

import math

from clay import (
    Clay, Shape, arc, bezier_pts, capsule, circle, cloud, curve, drop, ellipse, heart,
    moon, polygon, polyline, rbox, rpolygon, star,
)

# ───────────────────────────── 팔레트 ─────────────────────────────
# 레퍼런스(크림 바탕 + 복숭아 피부 + 캐러멜 머리 + 코랄 입)에서 뽑고,
# 카테고리 파스텔(딸기·버터·민트·하늘·라일락)을 더했다. 앱 토큰과 톤을 맞춘다.
SKIN = "#F8D5C8"
SKIN_MOM = "#F6D2C3"
BLUSH = "#F5ABA0"
EYE = "#3D3230"
MOUTH = "#EE7B73"
MOUTH_IN = "#D9605D"
TONGUE = "#F7A39B"
HAIR = "#C98840"  # 아가 배냇머리(캐러멜)
HAIR_MOM = "#6E4636"  # 엄마 머리(초콜릿)

PINK = "#F7B9C5"
PINK_DEEP = "#EE8EA2"
PEACH = "#F9C6A8"
CORAL = "#F29079"
RED = "#EE6F6B"
BUTTER = "#FBE3A1"
HONEY = "#F3C46C"
MINT = "#B9E3D2"
MINT_DEEP = "#7FC5AB"
SKY = "#BCDCF3"
SKY_DEEP = "#88BFE7"
LILAC = "#D8C9F1"
LILAC_DEEP = "#B39EE4"
CREAM = "#FFF4E6"
MILK = "#FFFBF4"
WHITE = "#FFFDF9"
BROWN = "#B27B5A"
BROWN_DEEP = "#8C5A41"
GREY = "#DCD2CC"
GREY_DEEP = "#B7AAA3"
TEAR = "#A6D3F4"
YELLOW_SKIN = "#F6DDA0"  # 황달 톤


def _p(cx, cy, s, x, y):
    """머리 로컬 좌표(단위, s=1 기준) → 장면 좌표."""
    return cx + x * s, cy + y * s


# ───────────────────────────── 얼굴 부품 ─────────────────────────────

def eyes(c: Clay, cx, cy, s, kind="dot", dx=12.5, y=1.0, look=(0.0, 0.0)):
    """눈 한 쌍.

    dot     점 눈(레퍼런스)            wide  조금 큰 동그란 눈(놀람)
    happy   ∩ 웃는 감은 눈             cry   ∩ 꽉 감은 눈 + 짧은 속눈썹
    sleep   ∪ 잠든 눈                  squint > < 찡그린 눈
    tired   반쯤 감긴 눈(윗꺼풀 선)
    """
    lx, ly = look
    for sx in (-1, 1):
        ex, ey = _p(cx, cy, s, sx * dx + lx, y + ly)
        if kind in ("dot", "wide"):
            r = (2.25 if kind == "dot" else 3.0) * s
            c.blob(circle(ex, ey, r), EYE, bevel=r, height=r * 0.8, gloss=0.7, tag="eye")
            if kind == "wide":
                c.paint(circle(ex - r * 0.3, ey - r * 0.35, r * 0.28), "#FFFFFF", soft=0.2, on="eye")
        elif kind == "happy":
            c.blob(arc(ex, ey + 1.2 * s, 3.4 * s, 200, 340, 0.95 * s), EYE, bevel=0.95 * s, height=0.8 * s, gloss=0.4)
        elif kind == "cry":
            c.blob(arc(ex, ey + 1.6 * s, 3.6 * s, 195, 345, 1.0 * s), EYE, bevel=1.0 * s, height=0.85 * s, gloss=0.4)
        elif kind == "sleep":
            c.blob(arc(ex, ey - 1.0 * s, 3.4 * s, 20, 160, 0.95 * s), EYE, bevel=0.95 * s, height=0.8 * s, gloss=0.4)
        elif kind == "squint":
            # 바깥쪽이 벌어진 ">" "<".
            ox = -sx * 1.6 * s
            pts = [(ex - ox + sx * 1.8 * s, ey - 2.4 * s), (ex + ox - sx * 1.2 * s, ey), (ex - ox + sx * 1.8 * s, ey + 2.4 * s)]
            if sx == 1:
                pts = [(ex + 2.0 * s, ey - 2.4 * s), (ex - 1.6 * s, ey), (ex + 2.0 * s, ey + 2.4 * s)]
            else:
                pts = [(ex - 2.0 * s, ey - 2.4 * s), (ex + 1.6 * s, ey), (ex - 2.0 * s, ey + 2.4 * s)]
            c.blob(polyline(pts, 0.95 * s), EYE, bevel=0.95 * s, height=0.8 * s, gloss=0.4)
        elif kind == "wink":
            if sx < 0:
                r = 2.25 * s
                c.blob(circle(ex, ey, r), EYE, bevel=r, height=r * 0.8, gloss=0.7, tag="eye")
            else:
                c.blob(arc(ex, ey + 1.2 * s, 3.4 * s, 200, 340, 0.95 * s), EYE, bevel=0.95 * s, height=0.8 * s, gloss=0.4)
        elif kind == "tired":
            r = 2.3 * s
            c.blob(circle(ex, ey + 0.6 * s, r), EYE, bevel=r, height=r * 0.7, gloss=0.6, tag="eye")
            c.blob(capsule(ex - 3.2 * s, ey - 0.9 * s, ex + 3.2 * s, ey - 0.9 * s, 1.1 * s), SKIN, bevel=1.1 * s, height=1.4 * s, tag="face")


def brows(c: Clay, cx, cy, s, kind="worry", color=None):
    color = color or "#B98A6E"
    for sx in (-1, 1):
        bx, by = _p(cx, cy, s, sx * 12.5, -7.5)
        if kind == "worry":  # 안쪽이 올라간 八
            a = (bx - sx * 3.2 * s, by - 1.2 * s)
            b = (bx + sx * 3.0 * s, by + 1.0 * s)
        else:  # 찡그림(안쪽이 내려감)
            a = (bx - sx * 3.2 * s, by + 1.0 * s)
            b = (bx + sx * 3.0 * s, by - 1.0 * s)
        c.blob(capsule(*a, *b, 0.8 * s), color, bevel=0.8 * s, height=0.7 * s, gloss=0.2)


def cheeks(c: Clay, cx, cy, s, dx=20.5, y=9.5, r=6.8, color=BLUSH, alpha=1.0, on="face"):
    for sx in (-1, 1):
        px, py = _p(cx, cy, s, sx * dx, y)
        c.paint(circle(px, py, r * s), color, soft=1.3 * s, on=on, alpha=alpha)


def nose(c: Clay, cx, cy, s, skin=SKIN):
    nx, ny = _p(cx, cy, s, 0, 5.0)
    c.blob(circle(nx, ny, 2.2 * s), skin, bevel=2.2 * s, height=2.0 * s, tag="face", gloss=0.14)


def mouth(c: Clay, cx, cy, s, kind="open", on="face"):
    """입 데칼.

    open   레퍼런스의 반달 웃음(윗변 평평, 아래 둥글게)
    smile  작은 곡선 웃음(튜브)
    wail   세로로 크게 벌린 우는 입
    o      작은 동그란 입(놀람·딸꾹)
    small  작은 반달
    wavy   물결 입(불편)
    frown  ∩ 입꼬리 내림
    """
    mx, my = _p(cx, cy, s, 0, 11.0)
    if kind == "open":
        m = circle(mx, my - 0.5 * s, 7.6 * s) & rbox(mx, my + 5.5 * s, 30 * s, 12 * s, 0)
        c.paint(m, MOUTH, soft=0.25 * s, depth=1.1 * s, on=on, gloss=0.05)
        c.paint(ellipse(mx, my + 5.0 * s, 3.6 * s, 1.6 * s), TONGUE, soft=0.6 * s, on=on)
    elif kind == "small":
        m = circle(mx, my - 0.5 * s, 4.6 * s) & rbox(mx, my + 3.5 * s, 20 * s, 8 * s, 0)
        c.paint(m, MOUTH, soft=0.25 * s, depth=0.8 * s, on=on, gloss=0.05)
    elif kind == "wail":
        m = ellipse(mx, my + 2.0 * s, 5.4 * s, 6.8 * s)
        c.paint(m, MOUTH_IN, soft=0.25 * s, depth=1.6 * s, on=on, gloss=0.05)
        c.paint(ellipse(mx, my + 6.0 * s, 3.4 * s, 2.0 * s), TONGUE, soft=0.6 * s, on=on)
    elif kind == "o":
        c.paint(ellipse(mx, my + 1.0 * s, 2.6 * s, 3.0 * s), MOUTH_IN, soft=0.25 * s, depth=1.0 * s, on=on)
    elif kind == "smile":
        c.blob(arc(mx, my - 2.5 * s, 4.6 * s, 25, 155, 0.9 * s), MOUTH_IN, bevel=0.9 * s, height=0.6 * s, gloss=0.1)
    elif kind == "wavy":
        pts = [(mx - 5.2 * s + i * 10.4 * s / 12, my + 1.2 * s * math.sin(i / 12 * math.pi * 2.0)) for i in range(13)]
        c.blob(polyline(pts, 0.85 * s), MOUTH_IN, bevel=0.85 * s, height=0.6 * s, gloss=0.1)
    elif kind == "frown":
        c.blob(arc(mx, my + 3.4 * s, 4.0 * s, 205, 335, 0.9 * s), MOUTH_IN, bevel=0.9 * s, height=0.6 * s, gloss=0.1)


def tear_drops(c: Clay, cx, cy, s, sides=(-1, 1), n=1, fall=0.0):
    """눈꼬리에서 떨어지는 굵은 눈물(유리알 광택)."""
    for sx in sides:
        for i in range(n):
            tx, ty = _p(cx, cy, s, sx * (20.0 + i * 2.0), 5.5 + i * 8.0 + fall)
            r = (3.3 - i * 0.7) * s
            c.blob(drop(tx, ty, r, tip=1.95, deg=-sx * 12), TEAR, bevel=r, height=r * 1.15,
                   mode="max", lift=_top(c, tx, ty) + 0.5 * s, gloss=0.95)


def _top(c: Clay, x, y):
    """현재 캔버스에서 (x,y) 지점의 높이 — 'max' 물체를 표면 위로 띄울 때."""
    i = min(max(int(y * c.s), 0), c.px - 1)
    j = min(max(int(x * c.s), 0), c.px - 1)
    return float(c.Z[i, j])


# ───────────────────────────── 머리 ─────────────────────────────

def curl(c: Clay, cx, cy, s=1.0, color=HAIR):
    """배냇머리 한 가닥 — 정수리에서 솟아 오른쪽으로 물음표처럼 말린 점토 국수."""
    bx, by = cx, cy - 23 * s
    pts = bezier_pts((bx, by), (bx - 1 * s, by - 7 * s), (bx + 2 * s, by - 13 * s), (bx + 7 * s, by - 12 * s), 16)
    ox, oy = bx + 6.2 * s, by - 8.2 * s
    for i in range(1, 25):
        t = i / 24
        ang = math.radians(-100 + 250 * t)
        rad = (3.9 - 1.6 * t) * s
        pts.append((ox + rad * math.cos(ang), oy + rad * math.sin(ang)))
    c.blob(polyline(pts, 2.3 * s, 1.35 * s), color, bevel=2.3 * s, height=2.6 * s, gloss=0.14, tag="hair")


def baby_head(c: Clay, cx, cy, s=1.0, eye="dot", mouth_kind="open", hair="curl",
              skin=SKIN, blush=True, brow=None, tears=False, tilt=0.0, hat=None, tear_sides=(-1, 1)):
    """아가 머리. (cx,cy) = 얼굴 중심, s = 배율(머리 가로 반지름 30·s)."""
    # 귀 — 머리 뒤에 붙은 작은 반구.
    for sx in (-1, 1):
        ex, ey = _p(cx, cy, s, sx * 29.5, 3.0)
        c.blob(circle(ex, ey, 6.4 * s), skin, bevel=6.4 * s, height=6.0 * s, tag="face")
        c.paint(circle(ex + sx * 0.6 * s, ey, 3.0 * s), BLUSH, soft=1.5 * s, on="face", alpha=0.45)
    # 얼굴 — 살짝 납작한 호빵.
    c.blob(ellipse(cx, cy, 30 * s, 27.5 * s), skin, bevel=21 * s, height=15 * s,
           mode="max", k=2.2 * s, tag="face", gloss=0.12)
    if hair == "curl":
        curl(c, cx, cy, s)
    elif hair == "tuft":
        hx, hy = _p(cx, cy, s, 0, -25.0)
        for dx, ang in ((-4.5, -118), (0, -90), (4.5, -62)):
            L = 8.0 * s
            bx = hx + dx * s
            c.blob(capsule(bx, hy + 1.5 * s, bx + L * math.cos(math.radians(ang)), hy + L * math.sin(math.radians(ang)), 2.0 * s, 1.1 * s),
                   HAIR, bevel=2.0 * s, height=2.2 * s, tag="hair")
    if hat:
        hat(c, cx, cy, s)
    eyes(c, cx, cy, s, eye)
    if brow:
        brows(c, cx, cy, s, brow)
    if blush:
        cheeks(c, cx, cy, s)
    nose(c, cx, cy, s, skin)
    mouth(c, cx, cy, s, mouth_kind)
    if tears:
        tear_drops(c, cx, cy, s, sides=tear_sides, n=1 if tears is True else tears)


def mom_head(c: Clay, cx, cy, s=1.0, eye="happy", mouth_kind="smile", brow=None, blush=True, pin=PINK_DEEP):
    """엄마 머리 — 초콜릿 똥머리 + 옆머리 + 앞머리 + 머리핀."""
    # 뒷머리(얼굴 뒤로 어깨까지).
    back = rbox(cx, cy + 4 * s, 70 * s, 62 * s, 28 * s)
    c.blob(back, HAIR_MOM, bevel=12 * s, height=8 * s, tag="hair", gloss=0.1)
    # 똥머리.
    c.blob(circle(cx + 4 * s, cy - 37 * s, 12 * s), HAIR_MOM, bevel=12 * s, height=12 * s, mode="max", lift=4 * s, k=2 * s, tag="hair", gloss=0.1)
    for sx in (-1, 1):
        ex, ey = _p(cx, cy, s, sx * 29.0, 4.0)
        c.blob(circle(ex, ey, 5.6 * s), SKIN_MOM, bevel=5.6 * s, height=5.0 * s, mode="max", lift=7 * s, k=1.5 * s, tag="face")
    c.blob(ellipse(cx, cy + 1 * s, 28.5 * s, 28 * s), SKIN_MOM, bevel=20 * s, height=14 * s, mode="max", lift=7 * s, k=2.2 * s, tag="face", gloss=0.12)
    # 앞머리 — 이마를 덮는 둥근 커튼(가운데 가르마).
    bang = (ellipse(cx - 12 * s, cy - 21 * s, 20 * s, 11 * s, deg=12) | ellipse(cx + 12 * s, cy - 21 * s, 20 * s, 11 * s, deg=-12))
    bang = bang & circle(cx, cy + 1 * s, 30.5 * s)
    c.blob(bang, HAIR_MOM, bevel=6 * s, height=6 * s, tag="hair", gloss=0.1)
    # 머리핀.
    px, py = _p(cx, cy, s, 17, -21)
    c.blob(rbox(px, py, 10 * s, 3.8 * s, 1.9 * s, deg=-28), pin, bevel=1.9 * s, height=2.2 * s, gloss=0.35)
    eyes(c, cx, cy + 2 * s, s, eye, dx=12.0)
    if brow:
        brows(c, cx, cy + 3 * s, s, brow, color="#8E6453")
    if blush:
        cheeks(c, cx, cy + 2 * s, s, dx=19.5, r=6.2)
    nose(c, cx, cy + 1.5 * s, s, SKIN_MOM)
    mouth(c, cx, cy + 1.5 * s, s, mouth_kind)


# ───────────────────────────── 몸 ─────────────────────────────

def baby_body(c: Clay, cx, top, s=1.0, color=MINT, arms="down", legs=True, skin=SKIN, collar=None):
    """앉은 아가 몸통(우주복). top = 목 위치(머리 중심에서 +24·s 정도)."""
    body = ellipse(cx, top + 17 * s, 21 * s, 19 * s)
    c.blob(body, color, bevel=15 * s, height=12 * s, tag="body", gloss=0.1)
    if collar:
        c.paint(ellipse(cx, top + 3 * s, 10 * s, 5 * s), collar, soft=0.4 * s, on="body")
    if legs:
        for sx in (-1, 1):
            fx, fy = cx + sx * 12 * s, top + 33 * s
            c.blob(ellipse(fx, fy, 8.5 * s, 6.2 * s), color, bevel=6 * s, height=6 * s, mode="max", lift=_top(c, fx, fy - 6 * s) * 0.4, k=2 * s, tag="body")
            c.blob(ellipse(fx + sx * 1.5 * s, fy + 1.5 * s, 5.2 * s, 4.2 * s), skin, bevel=4 * s, height=4.5 * s, tag="face")
    if arms == "down":
        for sx in (-1, 1):
            ax, ay = cx + sx * 17 * s, top + 10 * s
            c.blob(capsule(ax, ay, ax + sx * 5 * s, ay + 12 * s, 5.2 * s), color, bevel=5 * s, height=5 * s, tag="body")
            c.blob(circle(ax + sx * 5.5 * s, ay + 15.5 * s, 4.4 * s), skin, bevel=4.4 * s, height=4.4 * s, tag="face")
    elif arms == "up":
        for sx in (-1, 1):
            ax, ay = cx + sx * 17 * s, top + 8 * s
            c.blob(capsule(ax, ay, ax + sx * 9 * s, ay - 9 * s, 5.2 * s), color, bevel=5 * s, height=5 * s, tag="body")
            c.blob(circle(ax + sx * 10 * s, ay - 11 * s, 4.4 * s), skin, bevel=4.4 * s, height=4.4 * s, tag="face")
    elif arms == "belly":
        for sx in (-1, 1):
            ax, ay = cx + sx * 16 * s, top + 8 * s
            c.blob(capsule(ax, ay, cx + sx * 5 * s, top + 17 * s, 5.0 * s), color, bevel=5 * s, height=5 * s, tag="body")
            c.blob(circle(cx + sx * 4.5 * s, top + 18 * s, 4.4 * s), skin, bevel=4.4 * s, height=4.4 * s, tag="face")


def hand(c: Clay, x, y, s=1.0, skin=SKIN):
    c.blob(circle(x, y, 4.4 * s), skin, bevel=4.4 * s, height=4.4 * s, mode="max", lift=_top(c, x, y), k=1.2 * s, tag="face")


def open_hand(c: Clay, x, y, s=1.0, deg=0.0, skin=SKIN_MOM):
    """토닥이는 어른 손바닥(손바닥 + 네 손가락 + 엄지)."""
    top = _top(c, x, y)
    parts = ellipse(x, y, 9 * s, 10 * s)
    for i, dx in enumerate((-6.0, -2.0, 2.0, 6.0)):
        L = (8.5, 10.5, 10.0, 8.0)[i] * s
        parts = parts.smooth(capsule(x + dx * s, y - 4 * s, x + dx * 1.15 * s, y - 4 * s - L, 2.2 * s), 1.2 * s)
    parts = parts.smooth(capsule(x - 7 * s, y + 2 * s, x - 13 * s, y - 3 * s, 2.4 * s), 1.2 * s)
    c.blob(parts.rotate(deg, x, y), skin, bevel=4 * s, height=4.5 * s, mode="max", lift=top + 1, k=1.2, gloss=0.14, tag="palm")


# ───────────────────────────── 소품 ─────────────────────────────

def sparkle(c: Clay, x, y, r=4.0, color=BUTTER):
    """네 갈래 반짝이(둥근 별)."""
    pts = []
    for i in range(8):
        rad = r if i % 2 == 0 else r * 0.38
        a = math.radians(-90 + i * 45)
        pts.append((x + rad * math.cos(a), y + rad * math.sin(a)))
    c.blob(rpolygon(pts, r * 0.08), color, bevel=r * 0.35, height=r * 0.45, mode="max", lift=_top(c, x, y), gloss=0.3)


def dot_ball(c: Clay, x, y, r, color, gloss=0.2):
    c.blob(circle(x, y, r), color, bevel=r, height=r * 0.9, mode="max", lift=_top(c, x, y), gloss=gloss)


def heart_blob(c: Clay, x, y, s, color=PINK_DEEP, deg=0.0, lift=None):
    c.blob(heart(x, y, s, deg), color, bevel=s * 0.55, height=s * 0.5, mode="max",
           lift=_top(c, x, y) if lift is None else lift, k=0.8, gloss=0.3)


def star_blob(c: Clay, x, y, r, color=BUTTER, deg=-90.0):
    c.blob(star(x, y, r, inner=0.52, deg=deg, round_r=r * 0.12), color, bevel=r * 0.4, height=r * 0.45,
           mode="max", lift=_top(c, x, y), gloss=0.3)


def cloud_blob(c: Clay, x, y, w, h, color=WHITE, lift=None):
    c.blob(cloud(x, y, w, h), color, bevel=h * 0.32, height=h * 0.3, mode="max",
           lift=_top(c, x, y) if lift is None else lift, k=1.0, gloss=0.12, tag="cloud")


def water_drop(c: Clay, x, y, r, color=TEAR, deg=0.0):
    c.blob(drop(x, y, r, tip=1.9, deg=deg), color, bevel=r, height=r * 1.05, mode="max", lift=_top(c, x, y), gloss=0.9)


def z_letter(c: Clay, x, y, h, color=LILAC_DEEP):
    w = h * 0.9
    pts = [(x - w / 2, y - h / 2), (x + w / 2, y - h / 2), (x - w / 2, y + h / 2), (x + w / 2, y + h / 2)]
    r = h * 0.14
    c.blob(polyline(pts, r), color, bevel=r, height=r * 1.1, mode="max", lift=_top(c, x, y) + 1, gloss=0.2)


def swirl(c: Clay, x, y, r, color=CORAL, turns=1.6, w=1.1):
    pts = []
    n = 40
    for i in range(n + 1):
        t = i / n
        a = t * turns * 2 * math.pi
        rad = r * (0.2 + 0.8 * t)
        pts.append((x + rad * math.cos(a), y + rad * math.sin(a)))
    c.blob(polyline(pts, w), color, bevel=w, height=w * 1.1, mode="max", lift=_top(c, x, y) + 0.5, gloss=0.2)


def wave_lines(c: Clay, x, y, w, color, n=3, gap=5.5, amp=1.3, r=1.0, vertical=True):
    """피어오르는 물결 선(열기·김·향)."""
    for k in range(n):
        ox = x + (k - (n - 1) / 2) * gap
        pts = []
        for i in range(17):
            t = i / 16
            if vertical:
                pts.append((ox + amp * math.sin(t * math.pi * 2), y - t * w))
            else:
                pts.append((x + t * w, y + (k - (n - 1) / 2) * gap + amp * math.sin(t * math.pi * 2)))
        c.blob(polyline(pts, r, r * 0.7), color, bevel=r, height=r, mode="max", lift=_top(c, ox, y) + 0.3, gloss=0.2)


def bottle(c: Clay, x, y, s=1.0, body=SKY, cap=PINK, milk=MILK, deg=0.0, level=0.62, marks=True):
    """젖병 — 둥근 몸통 + 뚜껑 링 + 젖꼭지. (x,y)=몸통 중심."""
    def R(shape: Shape) -> Shape:
        return shape.rotate(deg, x, y) if deg else shape
    top = _top(c, x, y)
    c.blob(R(rbox(x, y, 20 * s, 30 * s, 8 * s)), body, bevel=8 * s, height=8 * s, mode="max", lift=top, k=1.0, gloss=0.35, tag="bottle")
    # 우유(아래 칸) — 창에 비친 우유.
    lvl = y + 15 * s - 30 * s * level
    c.paint(R(rbox(x, y + 3 * s, 14 * s, 22 * s, 5.5 * s) & rbox(x, (lvl + y + 15 * s) / 2, 30 * s, (y + 15 * s - lvl), 0)), milk, soft=0.4 * s, on="bottle")
    if marks:
        for i in range(3):
            my = y - 6 * s + i * 5 * s
            c.paint(R(capsule(x - 7.5 * s, my, x - 4.5 * s, my, 0.55 * s)), "#FFFFFF", soft=0.2 * s, on="bottle", alpha=0.8)
    c.blob(R(rbox(x, y - 16.5 * s, 22 * s, 7 * s, 3.2 * s)), cap, bevel=3.2 * s, height=4 * s, mode="max", lift=top + 2 * s, k=0.8 * s, gloss=0.3)
    c.blob(R(ellipse(x, y - 24 * s, 5.6 * s, 6.4 * s)), BUTTER, bevel=5 * s, height=5 * s, mode="max", lift=top + 1 * s, k=1.2 * s, gloss=0.25)


def thermometer(c: Clay, x1, y1, x2, y2, s=1.0, fill=RED, level=0.7):
    top = _top(c, (x1 + x2) / 2, (y1 + y2) / 2)
    c.blob(capsule(x1, y1, x2, y2, 4.2 * s), WHITE, bevel=4.2 * s, height=4.2 * s, mode="max", lift=top, k=1, gloss=0.4, tag="thermo")
    c.blob(circle(x2, y2, 6.2 * s), WHITE, bevel=6 * s, height=6 * s, mode="max", lift=top, k=1.5, gloss=0.4, tag="thermo")
    lx = x2 + (x1 - x2) * level
    ly = y2 + (y1 - y2) * level
    c.paint(capsule(x2, y2, lx, ly, 1.7 * s), fill, soft=0.2, on="thermo")
    c.paint(circle(x2, y2, 4.0 * s), fill, soft=0.3, on="thermo")


def pacifier(c: Clay, x, y, s=1.0, shield=PINK, ring=BUTTER, deg=0.0):
    top = _top(c, x, y)
    c.blob(arc(x, y + 7 * s, 6.5 * s, 20, 160, 1.9 * s).rotate(deg, x, y), ring, bevel=1.9 * s, height=2.2 * s, mode="max", lift=top + 1, gloss=0.35)
    c.blob(ellipse(x, y, 11 * s, 7.5 * s, deg=deg), shield, bevel=5 * s, height=5 * s, mode="max", lift=top + 2 * s, k=1, gloss=0.35)
    c.blob(circle(x, y, 3.2 * s), WHITE, bevel=3 * s, height=3.4 * s, gloss=0.4)


def diaper(c: Clay, x, y, s=1.0, color=WHITE, tab=SKY, deco=PINK):
    top = _top(c, x, y)
    shape = polygon([(x - 18 * s, y - 10 * s), (x + 18 * s, y - 10 * s), (x + 13 * s, y + 2 * s),
                     (x + 5 * s, y + 11 * s), (x - 5 * s, y + 11 * s), (x - 13 * s, y + 2 * s)]).dilate(3 * s)
    c.blob(shape, color, bevel=7 * s, height=7 * s, mode="max", lift=top, k=1, gloss=0.18, tag="diaper")
    c.paint(capsule(x - 17 * s, y - 10 * s, x + 17 * s, y - 10 * s, 2.0 * s), tab, soft=0.4, on="diaper")
    c.paint(heart(x, y + 1 * s, 3.4 * s), deco, soft=0.3, on="diaper")


def tube(c: Clay, x, y, s=1.0, deg=-30.0, body=PINK, cap=WHITE, label=WHITE):
    """연고·크림 튜브."""
    top = _top(c, x, y)
    shape = polygon([(x - 8 * s, y - 14 * s), (x + 8 * s, y - 14 * s), (x + 5.5 * s, y + 13 * s), (x - 5.5 * s, y + 13 * s)]).dilate(2 * s)
    c.blob(shape.rotate(deg, x, y), body, bevel=6 * s, height=6 * s, mode="max", lift=top, k=1, gloss=0.3, tag="tube")
    c.paint(rbox(x, y - 1 * s, 9 * s, 9 * s, 2.5 * s).rotate(deg, x, y), label, soft=0.3, on="tube")
    c.paint(heart(x, y - 1.5 * s, 2.4 * s).rotate(deg, x, y), body, soft=0.3, on="tube")
    cx2, cy2 = x + math.sin(math.radians(-deg)) * 18 * s, y + math.cos(math.radians(-deg)) * 18 * s
    c.blob(rbox(cx2, cy2, 9 * s, 7 * s, 2.4 * s, deg=deg), cap, bevel=2.4 * s, height=3.5 * s, mode="max", lift=top + 1, k=1, gloss=0.35)


def bandage(c: Clay, x, y, s=1.0, deg=-30.0, color=PEACH, pad=CREAM):
    top = _top(c, x, y)
    c.blob(rbox(x, y, 30 * s, 10 * s, 5 * s, deg=deg), color, bevel=3.5 * s, height=3 * s, mode="max", lift=top, k=1, gloss=0.2, tag="band")
    c.paint(rbox(x, y, 10 * s, 7 * s, 1.5 * s, deg=deg), pad, soft=0.3, on="band")
    for i in (-1, 1):
        for j in (-1, 1):
            px = x + math.cos(math.radians(deg)) * i * 10.5 * s - math.sin(math.radians(deg)) * j * 1.6 * s
            py = y + math.sin(math.radians(deg)) * i * 10.5 * s + math.cos(math.radians(deg)) * j * 1.6 * s
            c.paint(circle(px, py, 0.6 * s), "#E3A488", soft=0.2, on="band")


def cup(c: Clay, x, y, s=1.0, color=PINK, liquid=HONEY, steam=True):
    top = _top(c, x, y)
    body = rbox(x, y, 24 * s, 20 * s, 7 * s) & rbox(x, y + 4 * s, 30 * s, 24 * s, 0)
    c.blob(arc(x + 12 * s, y + 1 * s, 5 * s, -80, 80, 2.0 * s), color, bevel=2 * s, height=2.4 * s, mode="max", lift=top + 1, gloss=0.3)
    c.blob(body.dilate(0), color, bevel=6 * s, height=7 * s, mode="max", lift=top + 1, k=1, gloss=0.3, tag="cup")
    c.blob(ellipse(x, y - 7.6 * s, 10 * s, 2.6 * s), liquid, bevel=1.5 * s, height=1.0 * s, gloss=0.4)
    c.blob(ellipse(x, y + 12 * s, 16 * s, 3.4 * s), WHITE, bevel=2.5 * s, height=2.5 * s, mode="max", lift=top, k=1, gloss=0.3)
    if steam:
        wave_lines(c, x, y - 12 * s, 11 * s, "#FFFFFF", n=2, gap=6 * s, amp=1.2 * s, r=1.1 * s)
