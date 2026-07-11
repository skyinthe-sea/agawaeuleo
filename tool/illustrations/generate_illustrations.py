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


# ───────────────────────── 기존 16종 일러스트 ─────────────────────────
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


# ─────────────────── 신규 16종 (아기 9 + 산모 7) ───────────────────
# 산모 카드는 품위 있는 추상화 — 신체 직접 묘사 대신 곡선·상징 중심.


def rot_cmds(pts, cx, cy, angle, scale=1.0):
    """로컬 좌표 pts 를 angle(도) 회전·scale 후 (cx,cy)로 평행이동."""
    a = math.radians(angle)
    ca, sa = math.cos(a), math.sin(a)
    out = []
    for c in pts:
        if c[0] == "Z":
            out.append(("Z",))
            continue
        vals = list(c[1:])
        t = [c[0]]
        for i in range(0, len(vals), 2):
            x, y = vals[i] * scale, vals[i + 1] * scale
            t += [cx + x * ca - y * sa, cy + x * sa + y * ca]
        out.append(tuple(t))
    return out


def il_thrush():
    # 방긋 벌린 입 클로즈업 + 혀 위 얼룩(하프톤) + 입천장 쪽 하얀 반점
    mouth = circle_cmds(62, 62, 30, ry=26)
    tongue = [
        ("M", 42, 68), ("C", 46, 60, 78, 60, 82, 68),
        ("C", 82, 80, 74, 87, 62, 87), ("C", 50, 87, 42, 80, 42, 68), ("Z",),
    ]
    return [
        plus_shape(18, 24, 5, 2.4), plus_shape(103, 20, 4, 2.2),
        sq_shape(106, 88, 3.4, True),
        shape(mouth, fill="paper", sw=3),
        shape(tongue, fill="paper", dots=True, sw=2.2),
        shape(circle_cmds(52, 50, 3.0), fill="paper", sw=1.8),
        shape(circle_cmds(66, 47, 2.4), fill="paper", sw=1.6),
        shape(circle_cmds(74, 54, 2.0), fill="paper", sw=1.6),
    ]


def il_umbilical():
    # 아기 배 클로즈업 + 배꼽(이중 링) + 거즈 패치 + 반짝
    belly = circle_cmds(58, 66, 30, ry=27)
    return [
        plus_shape(18, 24, 5, 2.4), sq_shape(14, 92, 3.4, True),
        star_shape(105, 46, 3.4, sw=1.5),
        shape(belly, fill="paper", dots=True, sw=3, dot_bounds=(28, 80, 88, 94)),
        shape(circle_cmds(58, 64, 6.5), fill="paper", sw=2.4),
        shape([("M", 55, 64), ("C", 56, 66.5, 60, 66.5, 61, 64)], sw=1.8),
        # 거즈(격자 무늬)
        shape(rrect_cmds(82, 14, 24, 18, 3), fill="paper", sw=2.2),
        shape([("M", 90, 14), ("L", 90, 32)], sw=1.2),
        shape([("M", 98, 14), ("L", 98, 32)], sw=1.2),
        shape([("M", 82, 20), ("L", 106, 20)], sw=1.2),
        shape([("M", 82, 26), ("L", 106, 26)], sw=1.2),
        star_shape(32, 20, 5),
    ]


def il_birthmark():
    # 아기 얼굴 + 이마·눈두덩 옅은 반점(하프톤 패치)
    hair = [("M", 58, 37), ("C", 57, 32.5, 61.5, 30.5, 63.5, 34)]
    return [
        plus_shape(18, 22, 5, 2.4), plus_shape(102, 18, 4, 2.2),
        sq_shape(106, 90, 3.4, True),
        shape(circle_cmds(60, 64, 26), fill="paper", sw=3),
        shape(hair, sw=2),
        shape(circle_cmds(50, 49, 6.0, ry=5.0), fill="paper", dots=True, sw=1.8),
        shape(circle_cmds(70, 54.5, 3.8, ry=3.0), fill="paper", dots=True, sw=1.6),
        shape([("M", 46, 62), ("C", 48, 65, 52, 65, 54, 62)], sw=2.2),
        shape([("M", 66, 62), ("C", 68, 65, 72, 65, 74, 62)], sw=2.2),
        shape([("M", 57, 74), ("C", 59, 76, 61, 76, 63, 74)], sw=2),
    ]


def il_hormonal():
    # 포대기 아기 상반신 + 가슴 작은 원 2개 + 물결(호르몬 흐름)
    swaddle = capsule_cmds(60, 60, 60, 84, 18)
    hair = [("M", 58, 23), ("C", 57, 18.5, 61.5, 16.5, 63.5, 20)]
    return [
        plus_shape(18, 24, 5, 2.4), sq_shape(16, 92, 3.4, True),
        plus_shape(104, 22, 4, 2.2),
        shape(swaddle, fill="paper", dots=True, sw=3, dot_bounds=(40, 82, 80, 104)),
        # V자 포대기 여밈 + 가슴 작은 멍울 2개(여밈 아래)
        shape([("M", 48, 54), ("L", 60, 64)], sw=1.8),
        shape([("M", 72, 54), ("L", 60, 64)], sw=1.8),
        shape(circle_cmds(53, 71, 2.8), fill="paper", sw=1.8),
        shape(circle_cmds(67, 71, 2.8), fill="paper", sw=1.8),
        shape(circle_cmds(60, 36, 15), fill="paper", sw=3),
        shape(hair, sw=2),
        shape([("M", 53, 34), ("C", 54.5, 36, 56.5, 36, 58, 34)], sw=2),
        shape([("M", 62, 34), ("C", 63.5, 36, 65.5, 36, 67, 34)], sw=2),
        shape([("M", 58, 42), ("C", 59.3, 43.5, 60.7, 43.5, 62, 42)], sw=1.8),
        # 물결
        shape([("M", 90, 52), ("C", 93, 48, 96, 56, 99, 52),
               ("C", 102, 48, 105, 56, 108, 52)], sw=1.8),
        shape([("M", 92, 61), ("C", 95, 57, 98, 65, 101, 61),
               ("C", 104, 57, 107, 65, 110, 61)], sw=1.6),
    ]


def il_dimple():
    # 엎드린 아기 뒷모습 — 엉덩이 위 꼬리뼈 보조개 점
    hair = [("M", 60, 27), ("C", 59, 22.5, 63.5, 20.5, 65.5, 24)]
    return [
        plus_shape(18, 24, 5, 2.4), plus_shape(100, 18, 4, 2.2),
        sq_shape(106, 66, 3.4, True),
        shape(circle_cmds(62, 38, 12), fill="paper", sw=3),
        shape(hair, sw=2),
        shape(circle_cmds(62, 72, 28, ry=23), fill="paper", dots=True, sw=3,
              dot_bounds=(34, 82, 90, 96)),
        shape([("M", 62, 70), ("C", 60.5, 76, 60.5, 84, 62, 92)], sw=2),
        shape(circle_cmds(62, 62, 2.6), fill="dot", sw=1.4),
        shape(circle_cmds(48, 97, 6, ry=7), fill="paper", sw=2.2),
        shape(circle_cmds(76, 97, 6, ry=7), fill="paper", sw=2.2),
    ]


def il_tongue_tie():
    # 벌린 입(입술 이중 링) + 들어 올린 하트 혀(밑 홈) + 혀 밑 띠
    tongue = [
        ("M", 48, 68), ("C", 48, 56, 53, 50, 60, 50),
        ("C", 67, 50, 72, 56, 72, 68),
        ("C", 72, 74, 68, 78, 64, 78),
        ("C", 62, 78, 61, 76, 60, 73.5),
        ("C", 59, 76, 58, 78, 56, 78),
        ("C", 52, 78, 48, 74, 48, 68), ("Z",),
    ]
    return [
        plus_shape(18, 22, 5, 2.4), plus_shape(103, 24, 4, 2.2),
        sq_shape(104, 88, 3.4, True),
        shape(circle_cmds(60, 62, 30, ry=27), fill="paper", sw=3),
        shape(circle_cmds(60, 63, 23, ry=20), fill="paper", dots=True, sw=2.2),
        # 들린 혀 밑 띠(혀-입바닥 연결)
        shape([("M", 60, 74), ("L", 60, 84.5)], sw=2),
        shape(tongue, fill="paper", sw=2.4),
    ]


def il_vaccine():
    # 둥근 주사기(위) + 반창고 붙인 팔뚝(아래) + 별
    return [
        star_shape(24, 12, 4, sw=1.5), star_shape(102, 50, 5.5),
        plus_shape(104, 88, 4, 2.2), sq_shape(16, 90, 3.4, True),
        # 주사기
        shape([("M", 36, 24), ("L", 25, 24)], sw=1.8),
        shape(rrect_cmds(36, 16, 40, 16, 6), fill="paper", dots=True, sw=2.6,
              dot_bounds=(34, 14, 58, 34)),
        shape([("M", 48, 26), ("L", 48, 32)], sw=1.4),
        shape([("M", 56, 26), ("L", 56, 32)], sw=1.4),
        shape([("M", 64, 26), ("L", 64, 32)], sw=1.4),
        shape([("M", 78, 12), ("L", 78, 36)], sw=2.2),
        shape([("M", 78, 24), ("L", 90, 24)], sw=2.4),
        shape(rrect_cmds(90, 18, 5, 12, 2), fill="paper", sw=2),
        # 팔뚝 + 소매 + 반창고
        shape(capsule_cmds(38, 84, 88, 72, 12), fill="paper", sw=3),
        shape(rrect_cmds(24, 68, 16, 26, 5), fill="paper", dots=True, sw=2.6),
        shape(capsule_cmds(60, 76, 74, 72, 5.5), fill="paper", dots=True,
              sw=2, dot_bounds=(63, 66, 71, 82)),
    ]


def il_formula():
    # 젖병(좌) + 분유 스푼(아래) + 김 오르는 포트(우)
    teat_dome = [("M", 34, 49), ("C", 34, 42, 38, 38, 42, 38),
                 ("C", 46, 38, 50, 42, 50, 49), ("Z",)]
    nipple = [("M", 39, 38), ("C", 39, 33.5, 40.5, 31, 42, 31),
              ("C", 43.5, 31, 45, 33.5, 45, 38), ("Z",)]
    return [
        plus_shape(17, 22, 5, 2.4), plus_shape(106, 26, 4, 2.2),
        sq_shape(14, 90, 3.4, True),
        squiggle(76, 50, 13), squiggle(88, 48, 14),
        # 젖병
        shape(rrect_cmds(30, 54, 24, 40, 8), fill="paper", dots=True, sw=2.8,
              dot_bounds=(28, 72, 56, 96)),
        shape([("M", 30, 72), ("L", 54, 72)], sw=1.8),
        shape(rrect_cmds(28, 49, 28, 7, 3), fill="paper", sw=2.2),
        shape(teat_dome, fill="paper", sw=2.2),
        shape(nipple, fill="paper", sw=2),
        # 포트
        shape([("M", 66, 70), ("C", 60, 69, 59, 75, 66, 77)], fill="paper", sw=2),
        shape(circle_cmds(82, 76, 17, ry=15), fill="paper", sw=3),
        shape([("M", 97, 70), ("C", 106, 71, 106, 80, 97, 82)], sw=2.4),
        shape(circle_cmds(82, 61, 13, ry=4), fill="paper", sw=2.2),
        shape(circle_cmds(82, 55, 2.6), fill="paper", sw=2),
        # 분유 스푼
        shape(circle_cmds(62, 102, 6, ry=5), fill="paper", dots=True, sw=2),
        shape([("M", 68, 101), ("L", 79, 97)], sw=2.4),
    ]


def il_milk_storage():
    # 날짜 라벨 붙은 모유 저장팩 + 눈꽃 결정
    return [
        plus_shape(18, 22, 5, 2.4), plus_shape(100, 20, 4, 2.2),
        sq_shape(16, 92, 3.4, True),
        shape(rrect_cmds(36, 30, 42, 62, 6), fill="paper", dots=True, sw=3,
              dot_bounds=(34, 64, 80, 94)),
        shape([("M", 36, 38), ("L", 78, 38)], sw=1.6),
        shape([("M", 36, 42), ("L", 78, 42)], sw=1.6),
        shape([("M", 36, 64), ("L", 78, 64)], sw=1.8),
        # 라벨(날짜 줄 2개)
        shape(rrect_cmds(44, 46, 26, 13, 2), fill="paper", sw=2),
        shape([("M", 48, 50.5), ("L", 66, 50.5)], sw=1.4),
        shape([("M", 48, 54.5), ("L", 58, 54.5)], sw=1.4),
        # 눈꽃(6갈래 결정)
        shape([("M", 99, 44), ("L", 99, 60)], sw=1.8),
        shape([("M", 92, 48), ("L", 106, 56)], sw=1.8),
        shape([("M", 106, 48), ("L", 92, 56)], sw=1.8),
        star_shape(100, 78, 4, sw=1.5),
    ]


def il_lochia():
    # 아래로 지는 꽃잎 3장 — 진한(액센트 면) → 하프톤 → 옅은(선만)
    petal = [
        ("M", 0, -9), ("C", 6.5, -6.5, 7.5, 0.5, 3.5, 7),
        ("C", 1.5, 10, -1.5, 10, -3.5, 7),
        ("C", -7.5, 0.5, -6.5, -6.5, 0, -9), ("Z",),
    ]
    return [
        plus_shape(18, 24, 4.5, 2.2), sq_shape(104, 92, 3.2, True),
        star_shape(102, 70, 4.5, sw=1.5),
        shape(rot_cmds(petal, 80, 28, -25, 10 / 9), fill="dot", sw=1.6),
        shape([("M", 88, 42), ("C", 84, 46, 82, 50, 82, 54)], sw=1.2),
        shape(rot_cmds(petal, 60, 56, 20, 10 / 9), fill="paper", dots=True, sw=2),
        shape([("M", 68, 72), ("C", 64, 76, 62, 79, 62, 83)], sw=1.2),
        shape(rot_cmds(petal, 42, 84, -15), fill="paper", sw=2),
    ]


def il_baby_blues():
    # 엄마 옆얼굴 실루엣 + 작은 구름·빗방울 + 구름 뒤 해(희망)
    profile = [
        ("M", 56, 52),
        ("C", 54, 58, 53, 62, 51, 66),
        ("C", 49.5, 68.5, 49.5, 69.5, 51, 70),
        ("C", 50, 72.5, 51, 74, 52.5, 74.5),
        ("C", 51.5, 77, 52.5, 79, 55, 80),
        ("C", 58, 83, 62, 86, 66, 87),
        ("C", 68, 90, 69, 93, 69, 97),
        ("L", 88, 97),
        ("C", 88, 88, 90, 78, 90, 66),
        ("C", 90, 50, 80, 42, 70, 42),
        ("C", 65, 42, 58, 46, 56, 52), ("Z",),
    ]
    cloud = [
        ("M", 28, 30), ("C", 26, 23, 34, 19, 39, 22),
        ("C", 41, 15, 52, 15, 54, 22), ("C", 61, 20, 63, 28, 57, 31),
        ("C", 54, 33, 31, 33, 28, 30), ("Z",),
    ]
    return [
        sq_shape(106, 88, 3.4, True), plus_shape(18, 88, 4, 2.2),
        # 해(구름 뒤 — 먼저 그린다)
        shape(circle_cmds(62, 14, 8), fill="paper", sw=2.4),
        shape([("M", 72, 8), ("L", 76, 5)], sw=1.8),
        shape([("M", 74, 16), ("L", 79, 15)], sw=1.8),
        shape(cloud, fill="paper", dots=True, sw=2.4, dot_bounds=(26, 26, 62, 34)),
        shape(drop_cmds(36, 42, 6), fill="dot", sw=1.4),
        shape(drop_cmds(46, 48, 5.5), fill="dot", sw=1.4),
        shape(profile, fill="paper", sw=3),
        shape(circle_cmds(88, 52, 7), fill="paper", dots=True, sw=2.2),
        shape([("M", 57, 64), ("C", 58.5, 66, 61, 66, 62.5, 64.5)], sw=1.8),
    ]


def il_engorgement():
    # 가슴 곡선 추상(수묵 능선) + 온기 파선 + 냉찜질팩
    mound = [
        ("M", 28, 90), ("C", 32, 62, 60, 50, 80, 58),
        ("C", 94, 64, 100, 78, 97, 90), ("Z",),
    ]
    return [
        plus_shape(18, 24, 5, 2.4), sq_shape(14, 92, 3.4, True),
        squiggle(56, 44, 12), squiggle(68, 40, 12), squiggle(80, 44, 12),
        shape(mound, fill="paper", dots=True, sw=3, dot_bounds=(78, 58, 102, 92)),
        shape([("M", 38, 90), ("C", 42, 70, 60, 62, 76, 68)], sw=1.8),
        shape(circle_cmds(66, 74, 3.2), fill="dot", sw=1.2),
        # 냉찜질팩(눈꽃)
        shape(rrect_cmds(84, 14, 26, 17, 7), fill="paper", sw=2.4),
        shape([("M", 97, 17), ("L", 97, 28)], sw=1.5),
        shape([("M", 92, 19.5), ("L", 102, 25.5)], sw=1.5),
        shape([("M", 102, 19.5), ("L", 92, 25.5)], sw=1.5),
    ]


def il_nipple_care():
    # 연고 튜브 + 수유패드 + 밴드
    return [
        plus_shape(18, 24, 5, 2.4), sq_shape(16, 90, 3.4, True),
        star_shape(104, 54, 4, sw=1.5),
        # 튜브
        shape(rrect_cmds(28, 60, 34, 19, 4), fill="paper", sw=2.6),
        shape([("M", 30.5, 60), ("L", 30.5, 79)], sw=1.6),
        shape(rrect_cmds(34, 65, 16, 9, 2), fill="paper", sw=1.6),
        shape([("M", 37, 69.5), ("L", 47, 69.5)], sw=1.4),
        shape([("M", 62, 64.5), ("L", 68, 66), ("L", 68, 73),
               ("L", 62, 74.5), ("Z",)], fill="paper", sw=2),
        shape(rrect_cmds(68, 63.5, 9, 12, 2.5), fill="paper", dots=True, sw=2.2),
        # 수유패드(이중 링)
        shape(circle_cmds(88, 32, 15), fill="paper", dots=True, sw=2.6),
        shape(circle_cmds(88, 32, 8), fill="paper", sw=1.6),
        # 밴드
        shape(capsule_cmds(80, 86, 102, 78, 6.5), fill="paper", dots=True,
              sw=2.4, dot_bounds=(87, 74, 95, 92)),
    ]


def il_breastfeeding():
    # 요람 수유 실루엣 — 수묵 곡선 중심(엄마 머리 + 품 곡선 + 포대기 아기)
    return [
        plus_shape(18, 88, 4, 2.2), sq_shape(104, 92, 3.2, True),
        star_shape(100, 20, 4.5, sw=1.5),
        # 품(팔) 곡선
        shape([("M", 50, 38), ("C", 36, 48, 30, 64, 36, 78),
               ("C", 42, 92, 64, 98, 80, 90), ("C", 86, 87, 90, 82, 92, 76)], sw=3),
        shape([("M", 78, 40), ("C", 88, 48, 92, 60, 90, 72)], sw=2.2),
        # 엄마 머리(숙임) + 낮은 쪽머리
        shape(circle_cmds(64, 30, 13), fill="paper", sw=3),
        shape(circle_cmds(76, 34, 5.5), fill="paper", dots=True, sw=2),
        shape([("M", 56, 32), ("C", 57, 34, 59, 34, 60, 32)], sw=1.8),
        # 품 안의 아기
        shape(capsule_cmds(52, 72, 74, 76, 10), fill="paper", dots=True,
              sw=2.6, dot_bounds=(48, 74, 84, 88)),
        shape(circle_cmds(44, 68, 9), fill="paper", sw=2.6),
        shape([("M", 41, 67), ("C", 42, 68.5, 44, 68.5, 45, 67)], sw=1.6),
    ]


def il_milk_supply():
    # 눈금 젖병 반쯤 + 물음표 곡선
    teat_dome = [("M", 40, 37), ("C", 40, 30, 45, 26, 51, 26),
                 ("C", 57, 26, 62, 30, 62, 37), ("Z",)]
    nipple = [("M", 47, 26), ("C", 47, 21, 49, 18.5, 51, 18.5),
              ("C", 53, 18.5, 55, 21, 55, 26), ("Z",)]
    return [
        plus_shape(18, 24, 5, 2.4), sq_shape(16, 92, 3.4, True),
        plus_shape(104, 80, 4, 2.2),
        shape(rrect_cmds(36, 42, 30, 52, 9), fill="paper", dots=True, sw=3,
              dot_bounds=(34, 70, 68, 96)),
        shape([("M", 36, 70), ("L", 66, 70)], sw=2),
        shape([("M", 60, 50), ("L", 66, 50)], sw=1.4),
        shape([("M", 60, 58), ("L", 66, 58)], sw=1.4),
        shape([("M", 60, 66), ("L", 66, 66)], sw=1.4),
        shape([("M", 60, 78), ("L", 66, 78)], sw=1.4),
        shape([("M", 60, 86), ("L", 66, 86)], sw=1.4),
        shape(rrect_cmds(34, 37, 34, 8, 3), fill="paper", sw=2.2),
        shape(teat_dome, fill="paper", sw=2.2),
        shape(nipple, fill="paper", sw=2),
        # 물음표
        shape([("M", 80, 42), ("C", 80, 32, 97, 32, 97, 42),
               ("C", 97, 51, 88.5, 50, 88.5, 60)], sw=3),
        shape(circle_cmds(88.5, 69, 2.4), fill="ink"),
    ]


def il_recovery():
    # 김 오르는 찻잔 + 담요 방석 + 새싹
    cup = [
        ("M", 38, 56), ("C", 38, 72, 45, 82, 58, 82),
        ("C", 71, 82, 78, 72, 78, 56), ("Z",),
    ]
    return [
        plus_shape(18, 24, 5, 2.4), sq_shape(14, 74, 3.4, True),
        star_shape(100, 26, 4.5, sw=1.5),
        squiggle(50, 44, 12), squiggle(64, 42, 13),
        shape([("M", 78, 60), ("C", 88, 58, 90, 68, 79, 73)], sw=2.4),
        shape(cup, fill="paper", sw=3),
        shape(circle_cmds(58, 56, 20, ry=6), fill="paper", sw=2.4),
        shape(circle_cmds(58, 56, 14, ry=3.8), fill="paper", dots=True, sw=1.8),
        # 방석·담요
        shape(rrect_cmds(28, 88, 64, 16, 8), fill="paper", dots=True, sw=2.6,
              dot_bounds=(26, 96, 94, 106)),
        shape([("M", 34, 96), ("L", 86, 96)], sw=1.4),
        # 새싹
        shape([("M", 97, 90), ("C", 99, 92, 105, 92, 107, 90)], sw=1.8),
        shape([("M", 102, 88), ("C", 102, 82, 102, 77, 102, 72)], sw=2),
        shape([("M", 102, 77), ("C", 93, 75, 89, 67, 93, 61),
               ("C", 99, 58, 103, 68, 102, 77), ("Z",)], fill="paper", sw=1.8),
        shape([("M", 102, 74), ("C", 110, 70, 113, 61, 108, 56),
               ("C", 102, 54, 100, 65, 102, 74), ("Z",)], fill="paper", sw=1.8),
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
    # 신규 16종 (콘텐츠 계약 §1 — order_index 17~32)
    "thrush": ("아구창", il_thrush),
    "umbilical": ("배꼽·제대", il_umbilical),
    "birthmark": ("반점·각질", il_birthmark),
    "hormonal": ("가성생리·멍울", il_hormonal),
    "dimple": ("엉덩이 딤플", il_dimple),
    "tongue_tie": ("설소대", il_tongue_tie),
    "vaccine": ("예방접종", il_vaccine),
    "formula": ("분유 타기", il_formula),
    "milk_storage": ("모유 보관", il_milk_storage),
    "lochia": ("오로", il_lochia),
    "baby_blues": ("산후 우울감", il_baby_blues),
    "engorgement": ("젖몸살·유선염", il_engorgement),
    "nipple_care": ("유두 통증", il_nipple_care),
    "breastfeeding": ("모유수유 시작", il_breastfeeding),
    "milk_supply": ("모유량 고민", il_milk_supply),
    "recovery": ("산후 회복", il_recovery),
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
// 증상 32종 일러스트의 벡터 오퍼레이션 데이터. 렌더 엔진은
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
