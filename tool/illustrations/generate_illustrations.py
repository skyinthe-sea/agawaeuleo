#!/usr/bin/env python3
"""아가왜울어 증상 일러스트 생성기 — 단일 소스(ops) → SVG 미리보기 + Dart 코드.

스타일 계약(콜릭 트라이얼에서 확정):
- 뷰박스 120. 주 외곽선 3.0, 보조선 2.0~2.2. 하프톤 도트 r1.35 / step4.8(오프셋 격자).
- 면 = paper, 선 = ink, 도트·물방울 = dot(accent). 스파클 = 십자(+)·사각(▪) 2~4개.
- 텍스트 레인 회피: vb x<24 & 30<y<65 영역은 비워 둔다(카드 태그라인이 침범).

ops 모델(모두 이 파일 안에서만):
  shape(cmds, fill='none'|'paper'|'ink'|'dot', dots=False, sw=0.0,
        sharp=False, dot_bounds=None)
  cmds = [('M',x,y),('L',x,y),('C',x1,y1,x2,y2,x,y),('Z',)]
"""
import math
import pathlib

VB = 120
K = 0.5522847498  # 원 → 큐빅 근사 상수

LIGHT = ("#FBF7EF", "#26292B", "#FFFDF9", "#3E6B7A")  # bg, ink, paper, dot
DARK = ("#232019", "#ECE7DC", "#2C281F", "#6FA0B0")

DOT_R = 1.35
DOT_STEP = 4.8


# ───────────────────────── ops 프리미티브 ─────────────────────────

def shape(cmds, fill="none", dots=False, sw=0.0, sharp=False, dot_bounds=None):
    return {
        "cmds": cmds, "fill": fill, "dots": dots, "sw": sw,
        "sharp": sharp, "dot_bounds": dot_bounds,
    }


def circle_cmds(cx, cy, r, rx=None, ry=None):
    rx = r if rx is None else rx
    ry = r if ry is None else ry
    kx, ky = K * rx, K * ry
    return [
        ("M", cx - rx, cy),
        ("C", cx - rx, cy - ky, cx - kx, cy - ry, cx, cy - ry),
        ("C", cx + kx, cy - ry, cx + rx, cy - ky, cx + rx, cy),
        ("C", cx + rx, cy + ky, cx + kx, cy + ry, cx, cy + ry),
        ("C", cx - kx, cy + ry, cx - rx, cy + ky, cx - rx, cy),
        ("Z",),
    ]


def rrect_cmds(x, y, w, h, r):
    k = K * r
    x2, y2 = x + w, y + h
    return [
        ("M", x + r, y),
        ("L", x2 - r, y),
        ("C", x2 - r + k, y, x2, y + r - k, x2, y + r),
        ("L", x2, y2 - r),
        ("C", x2, y2 - r + k, x2 - r + k, y2, x2 - r, y2),
        ("L", x + r, y2),
        ("C", x + r - k, y2, x, y2 - r + k, x, y2 - r),
        ("L", x, y + r),
        ("C", x, y + r - k, x + r - k, y, x + r, y),
        ("Z",),
    ]


def capsule_cmds(x1, y1, x2, y2, r):
    dx, dy = x2 - x1, y2 - y1
    L = math.hypot(dx, dy)
    ux, uy = dx / L, dy / L
    px, py = -uy, ux
    k = K * r
    a = (x1 + px * r, y1 + py * r)
    b = (x2 + px * r, y2 + py * r)
    c = (x2 - px * r, y2 - py * r)
    e = (x1 - px * r, y1 - py * r)
    # 끝단 반원 2개를 각각 큐빅 2개로.
    def cap(p_from, center, p_to):
        # 반원: p_from → (center+u*r) → p_to  (진행 방향 u쪽으로 볼록)
        mx, my = center
        tipx, tipy = mx + (ux if center == (x2, y2) else -ux) * r, my + (uy if center == (x2, y2) else -uy) * r
        u_ = (ux, uy) if center == (x2, y2) else (-ux, -uy)
        return [
            ("C", p_from[0] + u_[0] * k, p_from[1] + u_[1] * k,
             tipx + px * k * (1 if center == (x2, y2) else -1) * 1, tipy + py * k * (1 if center == (x2, y2) else -1) * 1,
             tipx, tipy),
            ("C", tipx - px * k * (1 if center == (x2, y2) else -1) * 1, tipy - py * k * (1 if center == (x2, y2) else -1) * 1,
             p_to[0] + u_[0] * k, p_to[1] + u_[1] * k,
             p_to[0], p_to[1]),
        ]
    cmds = [("M", *a), ("L", *b)]
    cmds += cap(b, (x2, y2), c)
    cmds += [("L", *e)]
    cmds += cap(e, (x1, y1), a)
    cmds += [("Z",)]
    return cmds


def drop_cmds(cx, cy, s):
    """물방울(위 뾰족·아래 볼록). s = 전체 높이 스케일(기준 8)."""
    f = s / 8.0
    base = [
        ("M", 33, 27), ("C", 31, 30.8, 31.8, 33.8, 34.6, 34),
        ("C", 37.4, 34.2, 38, 31, 35.8, 27.4),
        ("C", 35, 26.1, 33.7, 26.1, 33, 27), ("Z",),
    ]
    ox, oy = 34.5, 30.2  # 기준 도형 중심
    out = []
    for c in base:
        if c[0] == "Z":
            out.append(("Z",))
        else:
            vals = list(c[1:])
            t = [c[0]]
            for i in range(0, len(vals), 2):
                t += [cx + (vals[i] - ox) * f, cy + (vals[i + 1] - oy) * f]
            out.append(tuple(t))
    return out


def plus_shape(cx, cy, r, w):
    return shape([("M", cx - r, cy), ("L", cx + r, cy),
                  ("M", cx, cy - r), ("L", cx, cy + r)], sw=w)


def sq_shape(cx, cy, s, filled):
    h = s / 2
    cmds = [("M", cx - h, cy - h), ("L", cx + h, cy - h), ("L", cx + h, cy + h),
            ("L", cx - h, cy + h), ("Z",)]
    if filled:
        return shape(cmds, fill="ink")
    return shape(cmds, sw=1.6, sharp=True)


def star_shape(cx, cy, r, sw=1.8):
    """오목 다이아(반짝임 별)."""
    p = 0.22 * r
    return shape([
        ("M", cx, cy - r), ("C", cx + p * 0.4, cy - p, cx + p, cy - p * 0.4, cx + r, cy),
        ("C", cx + p, cy + p * 0.4, cx + p * 0.4, cy + p, cx, cy + r),
        ("C", cx - p * 0.4, cy + p, cx - p, cy + p * 0.4, cx - r, cy),
        ("C", cx - p, cy - p * 0.4, cx - p * 0.4, cy - p, cx, cy - r), ("Z",),
    ], fill="paper", sw=sw)


def squiggle(cx, cy, h=16, w=1.8):
    """위로 솟는 열기/김 물결."""
    return shape([("M", cx, cy), ("C", cx - 4, cy - h * 0.33, cx + 4, cy - h * 0.66, cx, cy - h)], sw=w)


def ache_arc(cx, cy, flip=False, sw=2.0):
    """욱신 표시 ')' 아크."""
    d = -1 if flip else 1
    return shape([("M", cx, cy - 7), ("C", cx + 5 * d, cy - 3.5, cx + 5 * d, cy + 3.5, cx, cy + 7)], sw=sw)


# ───────────────────────── 16종 일러스트 ─────────────────────────
# 각 함수: list[shape]. 그리는 순서 = 레이어 순서.

def il_tummy_pain():
    body = [
        ("M", 36, 79), ("C", 36, 63, 46, 56, 60, 56), ("C", 74, 56, 84, 63, 84, 79),
        ("C", 84, 93, 74, 101, 60, 101), ("C", 46, 101, 36, 93, 36, 79), ("Z",),
    ]
    swirl = [("M", 60, 73.5), ("C", 65.5, 73.5, 68, 78, 64.5, 82),
             ("C", 61.5, 85.2, 56.5, 83.5, 57, 79.5), ("C", 57.4, 76.8, 60.8, 76.8, 61.4, 79)]
    hair = [("M", 58, 19), ("C", 57, 14.5, 61.5, 12.5, 63.5, 16)]
    return [
        plus_shape(17, 22, 5, 2.4), plus_shape(103, 18, 4, 2.2),
        sq_shape(12, 92, 3.4, True), sq_shape(106, 46, 4.0, False),
        shape(circle_cmds(46, 102.5, 6.8), fill="paper", sw=2),
        shape(circle_cmds(74, 102.5, 6.8), fill="paper", sw=2),
        shape(body, fill="paper", dots=True, sw=3),
        shape(circle_cmds(60, 80, 12.5), fill="paper", sw=2),
        shape(swirl, sw=1.8),
        shape(circle_cmds(45, 75, 5.2), fill="paper", sw=2),
        shape(circle_cmds(75, 75, 5.2), fill="paper", sw=2),
        shape(circle_cmds(60, 38, 20), fill="paper", sw=3),
        shape(hair, sw=2),
        shape([("M", 46, 32), ("L", 51, 34.5), ("L", 46, 37)], sw=2.2),
        shape([("M", 74, 32), ("L", 69, 34.5), ("L", 74, 37)], sw=2.2),
        shape(circle_cmds(60, 44, 4.6, ry=3.6), fill="ink"),
        shape(drop_cmds(34.5, 30.2, 8), fill="dot", sw=1.4),
        shape(drop_cmds(85.5, 30.2, 8), fill="dot", sw=1.4),
    ]


def il_teething():
    tooth = [
        ("M", 40, 46), ("C", 40, 30, 50, 24, 60, 24), ("C", 70, 24, 80, 30, 80, 46),
        ("C", 80, 58, 76, 66, 73, 78), ("C", 71, 86, 64, 86, 63, 78),
        ("C", 62, 71, 58, 71, 57, 78), ("C", 56, 86, 49, 86, 47, 78),
        ("C", 44, 66, 40, 58, 40, 46), ("Z",),
    ]
    return [
        plus_shape(20, 20, 5, 2.4), plus_shape(101, 26, 4, 2.2),
        sq_shape(58, 11, 3.6, False), sq_shape(104, 54, 3.2, True),
        shape(tooth, fill="paper", dots=True, sw=3, dot_bounds=(38, 22, 82, 44)),
        ache_arc(30, 46, flip=True), ache_arc(90, 46),
        shape(drop_cmds(94, 74, 7), fill="dot", sw=1.4),
    ]


def il_newborn_rash():
    hair = [("M", 58, 35), ("C", 57, 30.5, 61.5, 28.5, 63.5, 32)]
    return [
        plus_shape(19, 21, 5, 2.4), plus_shape(102, 20, 4, 2.2),
        sq_shape(105, 48, 3.6, False),
        squiggle(46, 26, 14), squiggle(74, 26, 14),
        shape(circle_cmds(60, 66, 26), fill="paper", sw=3),
        shape(hair, sw=2),
        # 감은 눈(둥근 ⌣ 아님 — 차분한 ⌒)
        shape([("M", 46, 62), ("C", 48, 65, 52, 65, 54, 62)], sw=2.2),
        shape([("M", 66, 62), ("C", 68, 65, 72, 65, 74, 62)], sw=2.2),
        shape([("M", 57, 74), ("C", 59, 76, 61, 76, 63, 74)], sw=2),
        # 양볼 붉은 기(도트 패치)
        shape(circle_cmds(43, 71, 7), fill="paper", dots=True, sw=1.8),
        shape(circle_cmds(77, 71, 7), fill="paper", dots=True, sw=1.8),
    ]


def il_stool_color():
    diaper = [
        ("M", 32, 42), ("L", 88, 42), ("C", 94, 42, 97, 46, 96, 51),
        ("C", 93, 73, 78, 88, 60, 88), ("C", 42, 88, 27, 73, 24, 51),
        ("C", 23, 46, 26, 42, 32, 42), ("Z",),
    ]
    return [
        plus_shape(18, 22, 5, 2.4), plus_shape(103, 18, 4, 2.2),
        sq_shape(14, 90, 3.4, True),
        # 허리 탭(기저귀 인상 강화)
        shape(rrect_cmds(22, 36, 14, 9, 3), fill="paper", sw=2.2),
        shape(rrect_cmds(84, 36, 14, 9, 3), fill="paper", sw=2.2),
        shape(diaper, fill="paper", dots=True, sw=3, dot_bounds=(22, 40, 98, 52)),
        shape([("M", 25, 53), ("L", 95, 53)], sw=2),
        # 돋보기(색 확인)
        shape(circle_cmds(76, 66, 13), fill="paper", dots=True, sw=2.6),
        shape([("M", 85, 76), ("L", 97, 90)], sw=3.4),
    ]


def il_burp():
    bottle = rrect_cmds(46, 48, 28, 48, 9)
    teat_dome = [("M", 50, 48), ("C", 50, 39, 54, 34, 60, 34),
                 ("C", 66, 34, 70, 39, 70, 48), ("Z",)]
    nipple = [("M", 56, 34), ("C", 56, 28, 58, 25, 60, 25),
              ("C", 62, 25, 64, 28, 64, 34), ("Z",)]
    return [
        plus_shape(20, 24, 5, 2.4), sq_shape(100, 52, 3.6, False),
        # 삼킨 공기(위로 뜨는 기포)
        shape(circle_cmds(88, 30, 3.4), sw=2),
        shape(circle_cmds(96, 20, 2.4), sw=1.8),
        shape(circle_cmds(80, 16, 2.0), sw=1.6),
        shape(bottle, fill="paper", dots=True, sw=3, dot_bounds=(44, 72, 76, 98)),
        shape([("M", 46, 72), ("L", 74, 72)], sw=2),  # 분유 수위선
        shape(rrect_cmds(44, 44, 32, 8, 3), fill="paper", sw=2.2),  # 목 링
        shape(teat_dome, fill="paper", sw=2.2),
        shape(nipple, fill="paper", sw=2),
        # 눈금
        shape([("M", 68, 56), ("L", 74, 56)], sw=1.6),
        shape([("M", 68, 63), ("L", 74, 63)], sw=1.6),
    ]


def il_spit_up():
    # 오목한 네크라인의 턱받이 + 흘린 방울
    bib = [
        ("M", 38, 42), ("C", 34, 56, 34, 68, 40, 80),
        ("C", 48, 94, 72, 94, 80, 80), ("C", 86, 68, 86, 56, 82, 42),
        ("C", 74, 54, 46, 54, 38, 42), ("Z",),
    ]
    return [
        plus_shape(19, 22, 5, 2.4), plus_shape(102, 16, 4, 2.2),
        sq_shape(14, 88, 3.4, True),
        # 목끈(어깨 끝에서 위로)
        shape([("M", 38, 42), ("L", 31, 32)], sw=2.2),
        shape([("M", 82, 42), ("L", 89, 32)], sw=2.2),
        shape(bib, fill="paper", dots=True, sw=3),
        shape(drop_cmds(94, 62, 8), fill="dot", sw=1.4),
        shape(drop_cmds(101, 76, 6.5), fill="dot", sw=1.4),
    ]


def il_runny_nose():
    box = rrect_cmds(30, 54, 60, 38, 7)
    tissue = [
        ("M", 50, 56), ("C", 48, 46, 54, 40, 58, 32),
        ("C", 60, 28, 64, 28, 65, 32), ("C", 67, 40, 73, 46, 70, 56), ("Z",),
    ]
    return [
        plus_shape(18, 22, 5, 2.4), plus_shape(100, 18, 4, 2.2),
        sq_shape(104, 42, 3.6, False),
        shape(tissue, fill="paper", sw=2.2),
        shape(box, fill="paper", dots=True, sw=3, dot_bounds=(28, 68, 92, 94)),
        shape(circle_cmds(60, 60, 16, ry=5), fill="paper", sw=2),  # 상판 슬롯
        shape([("M", 48, 60), ("L", 72, 60)], sw=2),
        shape(drop_cmds(100, 70, 8), fill="dot", sw=1.4),
    ]


def il_fever():
    # 대각 체온계(캡슐) + 수은주 + 열 물결
    return [
        plus_shape(20, 24, 5, 2.4), sq_shape(16, 90, 3.4, True),
        squiggle(92, 34, 16), squiggle(103, 42, 14),
        shape(capsule_cmds(44, 82, 88, 38, 8), fill="paper", sw=3),
        shape(circle_cmds(41, 85, 10.5), fill="paper", dots=True, sw=3),
        shape([("M", 48, 78), ("L", 72, 54)], sw=3.4),  # 수은주(도트색이면 좋지만 선은 ink 유지)
        shape([("M", 70, 46), ("L", 75, 51)], sw=1.8),
        shape([("M", 77, 39), ("L", 82, 44)], sw=1.8),
    ]


def il_rash():
    arm = capsule_cmds(46, 74, 92, 60, 13)
    return [
        plus_shape(20, 22, 5, 2.4), plus_shape(102, 24, 4, 2.2),
        sq_shape(106, 88, 3.4, True),
        # 가려움 표시
        shape([("M", 58, 40), ("L", 62, 46)], sw=1.8),
        shape([("M", 68, 36), ("L", 72, 42)], sw=1.8),
        shape([("M", 78, 34), ("L", 82, 40)], sw=1.8),
        shape(arm, fill="paper", sw=3),
        shape(rrect_cmds(34, 58, 14, 30, 5), fill="paper", dots=True, sw=2.6),  # 소매
        # 반점(도트색 + 얇은 테)
        shape(circle_cmds(60, 66, 3.0), fill="dot", sw=1.2),
        shape(circle_cmds(72, 74, 2.4), fill="dot", sw=1.2),
        shape(circle_cmds(80, 62, 2.7), fill="dot", sw=1.2),
        shape(circle_cmds(66, 78, 2.0), fill="dot", sw=1.2),
        shape(circle_cmds(88, 70, 2.2), fill="dot", sw=1.2),
    ]


def il_sleep_moon():
    crescent = [
        ("M", 74, 34),
        ("C", 52, 34, 36, 48, 36, 66), ("C", 36, 84, 52, 98, 74, 98),
        ("C", 78, 98, 82, 97, 85, 96),
        ("C", 68, 92, 58, 80, 58, 66), ("C", 58, 52, 68, 40, 85, 36),
        ("C", 82, 35, 78, 34, 74, 34), ("Z",),
    ]
    z1 = [("M", 84, 52), ("L", 96, 52), ("L", 84, 66), ("L", 96, 66)]
    z2 = [("M", 96, 74), ("L", 105, 74), ("L", 96, 84), ("L", 105, 84)]
    return [
        plus_shape(20, 20, 5, 2.4),
        star_shape(94, 26, 6), star_shape(106, 44, 3.6, sw=1.5),
        shape(crescent, fill="paper", dots=True, sw=3),
        shape([("M", 44, 62), ("C", 46, 65, 50, 65, 52, 62)], sw=2.2),  # 감은 눈
        shape(z1, sw=2.4), shape(z2, sw=2),
    ]


def il_constipation():
    pot = [
        ("M", 36, 52), ("C", 36, 68, 41, 79, 49, 84), ("L", 71, 84),
        ("C", 79, 79, 84, 68, 84, 52), ("Z",),
    ]
    return [
        plus_shape(20, 22, 5, 2.4), sq_shape(104, 66, 3.6, False),
        # 기다림 '···'
        shape(circle_cmds(88, 28, 1.9), fill="ink"),
        shape(circle_cmds(95, 33, 1.9), fill="ink"),
        shape(circle_cmds(100, 40, 1.9), fill="ink"),
        shape(pot, fill="paper", sw=3),
        shape(circle_cmds(60, 52, 26, ry=9.5), fill="paper", sw=3),  # 시트
        shape(circle_cmds(60, 52, 14, ry=5), fill="paper", dots=True, sw=2.2),  # 구멍
        shape(rrect_cmds(40, 84, 40, 10, 4), fill="paper", dots=True, sw=2.6),  # 받침
        shape(drop_cmds(30, 66, 7), fill="dot", sw=1.4),  # 끙끙 땀
    ]


def il_diarrhea():
    return [
        plus_shape(19, 20, 5, 2.4), plus_shape(101, 18, 4, 2.2),
        sq_shape(14, 86, 3.4, True),
        # 롤 몸통
        shape([("M", 36, 42), ("L", 36, 66), ("C", 36, 76, 46, 82, 58, 82),
               ("C", 70, 82, 80, 76, 80, 66), ("L", 80, 42), ("Z",)],
              fill="paper", dots=True, sw=3, dot_bounds=(34, 52, 82, 84)),
        shape(circle_cmds(58, 42, 22, ry=10), fill="paper", sw=3),  # 윗면
        shape(circle_cmds(58, 42, 7, ry=3.2), fill="paper", sw=2.2),  # 심
        # 풀린 휴지 자락
        shape([("M", 80, 58), ("C", 88, 62, 90, 68, 90, 76), ("L", 90, 94),
               ("L", 82, 90), ("L", 82, 76), ("C", 82, 70, 80, 66, 76, 63)],
              fill="paper", sw=2.2),
        shape(drop_cmds(100, 74, 8), fill="dot", sw=1.4),
        shape(drop_cmds(95, 88, 6.5), fill="dot", sw=1.4),
    ]


def il_hiccup():
    return [
        plus_shape(18, 26, 5, 2.4), sq_shape(16, 88, 3.4, True),
        # '딸꾹' 버블(+ ! )
        shape(circle_cmds(92, 26, 13), fill="paper", sw=2.4),
        shape([("M", 84, 36), ("L", 80, 44), ("L", 90, 38)], fill="paper", sw=2),
        shape([("M", 92, 19), ("L", 92, 29)], sw=2.6),
        shape(circle_cmds(92, 34.5, 1.7), fill="ink"),
        # 공갈젖꼭지
        shape(circle_cmds(56, 66, 22, ry=14), fill="paper", dots=True, sw=3),  # 방패
        shape([("M", 48, 52), ("C", 48, 44, 52, 40, 56, 40),
               ("C", 60, 40, 64, 44, 64, 52), ("Z",)], fill="paper", sw=2.2),  # 꼭지
        shape(circle_cmds(56, 90, 9), sw=3),  # 고리
        shape(rrect_cmds(50, 78, 12, 6, 3), fill="paper", sw=2),  # 손잡이 목
    ]


def il_prickly_heat():
    # 선풍기(더위 식히기) + 땀방울
    def petal(angle):
        """허브(58,56) 기준 회전 꽃잎 날개."""
        a = math.radians(angle)
        ca, sa = math.cos(a), math.sin(a)
        pts = [
            ("M", 0, -5), ("C", 8, -9, 16, -8, 17.5, -1),
            ("C", 18.5, 5, 10, 7, 3, 4.5), ("Z",),
        ]
        out = []
        for c in pts:
            if c[0] == "Z":
                out.append(("Z",))
                continue
            vals = list(c[1:])
            t = [c[0]]
            for i in range(0, len(vals), 2):
                x, y = vals[i], vals[i + 1]
                t += [58 + x * ca - y * sa, 56 + x * sa + y * ca]
            out.append(tuple(t))
        return out

    return [
        plus_shape(17, 22, 5, 2.4), sq_shape(103, 74, 3.6, False),
        shape(drop_cmds(96, 24, 8), fill="dot", sw=1.4),
        shape(drop_cmds(105, 40, 6.5), fill="dot", sw=1.4),
        # 받침대
        shape([("M", 58, 80), ("L", 58, 94)], sw=3),
        shape(rrect_cmds(44, 94, 28, 8, 4), fill="paper", dots=True, sw=2.4),
        # 보호망 원 + 날개 3 + 허브
        shape(circle_cmds(58, 56, 25), fill="paper", sw=3),
        shape(petal(-90), fill="paper", dots=True, sw=2),
        shape(petal(30), fill="paper", dots=True, sw=2),
        shape(petal(150), fill="paper", dots=True, sw=2),
        shape(circle_cmds(58, 56, 4.5), fill="paper", sw=2.2),
    ]


def il_jaundice():
    swaddle = capsule_cmds(42, 82, 72, 82, 13)
    return [
        plus_shape(18, 24, 5, 2.4), sq_shape(16, 94, 3.2, True),
        # 광선치료 램프 갓(돔) + 코드 + 빛줄기
        shape([("M", 70, 32), ("C", 70, 18, 106, 18, 106, 32), ("Z",)],
              fill="paper", dots=True, sw=2.6),
        shape([("M", 88, 20), ("L", 88, 10)], sw=2.2),
        shape([("M", 76, 38), ("L", 68, 50)], sw=1.8),
        shape([("M", 88, 40), ("L", 86, 54)], sw=1.8),
        shape([("M", 100, 38), ("L", 104, 52)], sw=1.8),
        # 포대기에 싸여 누운 아기 + 머리
        shape(swaddle, fill="paper", dots=True, sw=3),
        shape(circle_cmds(88, 82, 12), fill="paper", sw=3),
        shape([("M", 84, 80), ("C", 85, 82, 87, 82, 88, 80)], sw=2),   # 감은 눈
        shape([("M", 92, 80), ("C", 93, 82, 95, 82, 96, 80)], sw=2),
        shape([("M", 86, 68), ("C", 86, 64.5, 90, 63.5, 91, 66.5)], sw=1.8),  # 머리카락
    ]


def il_eye_care():
    eye = [
        ("M", 34, 60), ("C", 46, 43, 82, 43, 94, 60),
        ("C", 82, 77, 46, 77, 34, 60), ("Z",),
    ]
    return [
        plus_shape(18, 24, 5, 2.4), plus_shape(100, 16, 4, 2.2),
        sq_shape(14, 92, 3.4, True),
        # 속눈썹
        shape([("M", 47, 46), ("L", 44, 40)], sw=2),
        shape([("M", 63, 43), ("L", 63, 36)], sw=2),
        shape([("M", 79, 46), ("L", 82, 40)], sw=2),
        shape(eye, fill="paper", sw=3),
        shape(circle_cmds(64, 60, 11.5), fill="paper", dots=True, sw=2.4),  # 홍채
        shape(circle_cmds(64, 60, 4.2), fill="ink"),  # 동공
        shape(drop_cmds(92, 76, 8), fill="dot", sw=1.4),  # 눈물
        shape(circle_cmds(38, 68, 2.0), fill="dot", sw=1.2),  # 눈곱
        shape(circle_cmds(43, 72, 1.6), fill="dot", sw=1.2),
    ]


ILLUSTRATIONS = {
    "tummy_pain": ("배앓이", il_tummy_pain),
    "teething": ("이앓이", il_teething),
    "newborn_rash": ("태열", il_newborn_rash),
    "stool_color": ("변 색깔 이상", il_stool_color),
    "burp": ("트림 안 나옴", il_burp),
    "spit_up": ("게워냄", il_spit_up),
    "runny_nose": ("콧물·코막힘", il_runny_nose),
    "fever": ("열", il_fever),
    "rash": ("발진", il_rash),
    "sleep_moon": ("수면퇴행", il_sleep_moon),
    "constipation": ("변비", il_constipation),
    "diarrhea": ("설사", il_diarrhea),
    "hiccup": ("딸꾹질", il_hiccup),
    "prickly_heat": ("땀띠", il_prickly_heat),
    "jaundice": ("황달", il_jaundice),
    "eye_care": ("눈곱·눈물", il_eye_care),
}


# ───────────────────────── SVG 렌더 ─────────────────────────

def cmds_to_d(cmds):
    out = []
    for c in cmds:
        if c[0] == "Z":
            out.append("Z")
        else:
            out.append(c[0] + " " + " ".join(f"{v:.2f}" for v in c[1:]))
    return " ".join(out)


def bounds_of(cmds):
    xs, ys = [], []
    for c in cmds:
        if c[0] == "Z":
            continue
        vals = c[1:]
        xs += [vals[i] for i in range(0, len(vals), 2)]
        ys += [vals[i] for i in range(1, len(vals), 2)]
    return min(xs), min(ys), max(xs), max(ys)


_seq = [0]


def svg_shape(s, ink, paper, dot):
    fillmap = {"none": "none", "paper": paper, "ink": ink, "dot": dot}
    parts = []
    d = cmds_to_d(s["cmds"])
    fill = fillmap[s["fill"]]
    if s["fill"] != "none":
        parts.append(f'<path d="{d}" fill="{fill}"/>')
    if s["dots"]:
        _seq[0] += 1
        cid = f"c{_seq[0]}"
        x0, y0, x1, y1 = s["dot_bounds"] or bounds_of(s["cmds"])
        x0 -= DOT_R; y0 -= DOT_R; x1 += DOT_R; y1 += DOT_R
        rows = [f'<defs><clipPath id="{cid}"><path d="{d}"/></clipPath></defs>',
                f'<g clip-path="url(#{cid})">']
        j = 0
        y = y0
        while y <= y1:
            x = x0 + (DOT_STEP / 2 if j % 2 else 0)
            while x <= x1:
                rows.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{DOT_R}" fill="{dot}"/>')
                x += DOT_STEP
            y += DOT_STEP
            j += 1
        rows.append("</g>")
        parts.append("".join(rows))
    if s["sw"] > 0:
        cap = "butt" if s["sharp"] else "round"
        join = "miter" if s["sharp"] else "round"
        parts.append(
            f'<path d="{d}" fill="none" stroke="{ink}" stroke-width="{s["sw"]}" '
            f'stroke-linecap="{cap}" stroke-linejoin="{join}"/>'
        )
    return "".join(parts)


def svg_single(key, colors, size=480, bg=True):
    bgc, ink, paper, dot = colors
    p = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {VB} {VB}" width="{size}" height="{size}">']
    if bg:
        p.append(f'<rect width="{VB}" height="{VB}" fill="{bgc}" rx="14"/>')
    for s in ILLUSTRATIONS[key][1]():
        p.append(svg_shape(s, ink, paper, dot))
    p.append("</svg>")
    return "".join(p)


def contact_sheet(colors, cols=4):
    bgc, ink, paper, dot = colors
    keys = list(ILLUSTRATIONS)
    rows = (len(keys) + cols - 1) // cols
    cell, pad, label_h = 130, 8, 16
    W = cols * (cell + pad) + pad
    H = rows * (cell + label_h + pad) + pad
    p = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W*3}" height="{H*3}">',
         f'<rect width="{W}" height="{H}" fill="{bgc}"/>']
    for i, key in enumerate(keys):
        name = ILLUSTRATIONS[key][0]
        cx = pad + (i % cols) * (cell + pad)
        cy = pad + (i // cols) * (cell + label_h + pad)
        p.append(f'<g transform="translate({cx},{cy})">')
        p.append(f'<rect width="{cell}" height="{cell}" fill="{paper}" rx="12" stroke="{ink}" stroke-opacity="0.15"/>')
        p.append(f'<g transform="translate(5,5) scale({(cell-10)/VB})">')
        for s in ILLUSTRATIONS[key][1]():
            p.append(svg_shape(s, ink, paper, dot))
        p.append("</g>")
        p.append(f'<text x="{cell/2}" y="{cell + 12}" text-anchor="middle" font-size="9" fill="{ink}" font-family="sans-serif">{name} ({key})</text>')
        p.append("</g>")
    p.append("</svg>")
    return "".join(p)


# ───────────────────────── Dart 코드젠 ─────────────────────────

DART_HEADER = """\
// GENERATED CODE — 직접 수정 금지.
//
// 원본: tool/illustrations/generate_illustrations.py
// 재생성: python3 tool/illustrations/generate_illustrations.py --dart
//
// 증상 16종 일러스트의 벡터 오퍼레이션 데이터. 렌더 엔진은
// `symptom_illustration.dart`의 `IllustrationShape`/페인터가 담당한다.

import 'symptom_illustration.dart';

/// `emoji_or_icon` 키 → 일러스트 셰이프 목록(그리는 순서 = 레이어 순서).
const Map<String, List<IllustrationShape>> symptomIllustrationShapes =
    <String, List<IllustrationShape>>{
"""

OPCODE = {"M": 0, "L": 1, "C": 2, "Z": 9}


def dart_shape(s):
    nums = []
    for c in s["cmds"]:
        nums.append(str(OPCODE[c[0]]))
        nums += [f"{v:g}" for v in c[1:]]
    args = [f"<double>[{', '.join(nums)}]"]
    if s["fill"] != "none":
        args.append(f"fill: IllustrationFill.{s['fill']}")
    if s["dots"]:
        args.append("dots: true")
    if s["sw"] > 0:
        args.append(f"strokeWidth: {s['sw']:g}")
    if s["sharp"]:
        args.append("sharp: true")
    if s["dot_bounds"]:
        b = ", ".join(f"{v:g}" for v in s["dot_bounds"])
        args.append(f"dotBounds: <double>[{b}]")
    return f"    IllustrationShape({', '.join(args)}),"


def dart_file():
    out = [DART_HEADER]
    for key, (name, fn) in ILLUSTRATIONS.items():
        out.append(f"  // {name}")
        out.append(f"  '{key}': <IllustrationShape>[")
        for s in fn():
            out.append(dart_shape(s))
        out.append("  ],")
    out.append("};")
    return "\n".join(out) + "\n"


if __name__ == "__main__":
    import sys
    here = pathlib.Path(__file__).parent
    repo = here.parent.parent
    preview = here / "preview"
    preview.mkdir(exist_ok=True)
    (preview / "sheet_light.svg").write_text(contact_sheet(LIGHT))
    (preview / "sheet_dark.svg").write_text(contact_sheet(DARK))
    if "--dart" in sys.argv:
        out = repo / "lib/presentation/widgets/symptom/symptom_illustration_data.dart"
        out.write_text(dart_file())
        print(f"wrote {out} — dart format 후 커밋할 것")
    print("ok (미리보기: tool/illustrations/preview/)")
