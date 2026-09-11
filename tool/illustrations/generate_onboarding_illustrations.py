#!/usr/bin/env python3
"""아가왜울어 온보딩 일러스트 생성기 — 단일 소스(ops) → SVG 미리보기 + Dart 코드.

증상 일러스트(generate_illustrations.py)와 같은 ops 모델·렌더 엔진·스타일 계약을
그대로 쓴다(프리미티브도 그 파일에서 가져온다). 다른 점은 **뷰박스 240** 하나 —
온보딩 히어로는 ~260dp로 그려지므로, 선 두께 수치(주 3.0 · 보조 2.2 · 미세 1.6)를
그대로 두고 뷰박스만 키워 화면상 먹선 굵기가 홈 카드와 같은 결로 보이게 한다.

장면 서사: 우는 아기(왜 울까?) → 케어 가방(필요한 용품) → 구름 위 잠(기록·안심).

재생성: python3 tool/illustrations/generate_onboarding_illustrations.py --dart
"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import generate_illustrations as g  # noqa: E402

shape = g.shape
circle_cmds = g.circle_cmds
rrect_cmds = g.rrect_cmds
capsule_cmds = g.capsule_cmds
drop_cmds = g.drop_cmds
rot_cmds = g.rot_cmds
plus_shape = g.plus_shape
sq_shape = g.sq_shape
star_shape = g.star_shape

VB = 240


def tf_cmds(cmds, ox, oy, s, cx, cy):
    """(ox,oy) 기준 좌표를 s배 스케일 후 (cx,cy)로 옮긴다."""
    out = []
    for c in cmds:
        if c[0] == "Z":
            out.append(("Z",))
            continue
        vals = list(c[1:])
        t = [c[0]]
        for i in range(0, len(vals), 2):
            t += [cx + (vals[i] - ox) * s, cy + (vals[i + 1] - oy) * s]
        out.append(tuple(t))
    return out


def zig(x, y, w, h, sw):
    """'Z' 한 글자(수면 표시)."""
    return shape([("M", x, y), ("L", x + w, y), ("L", x, y + h), ("L", x + w, y + h)], sw=sw)


# ───────────────────────── ① 우는 아기 ─────────────────────────

def ob_cry():
    body = [
        ("M", 76, 150), ("C", 62, 170, 60, 200, 74, 216),
        ("C", 80, 222, 88, 224, 96, 224), ("L", 144, 224),
        ("C", 152, 224, 160, 222, 166, 216), ("C", 180, 200, 178, 170, 164, 150), ("Z",),
    ]
    mouth = [
        ("M", 105, 124), ("C", 109, 116, 131, 116, 135, 124),
        ("C", 141, 135, 135, 148, 120, 148), ("C", 105, 148, 99, 135, 105, 124), ("Z",),
    ]
    tongue = [
        ("M", 110, 142), ("C", 114, 136, 126, 136, 130, 142),
        ("C", 126, 147, 114, 147, 110, 142), ("Z",),
    ]
    return [
        # 장식(가장 뒤)
        plus_shape(26, 150, 7, 2.6), star_shape(214, 150, 7),
        sq_shape(32, 206, 5, True), sq_shape(210, 206, 5.4, False),
        # 울음 표시 — 머리 좌우로 퍼지는 짧은 획
        shape([("M", 52, 60), ("L", 40, 50)], sw=2.6),
        shape([("M", 45, 76), ("L", 31, 72)], sw=2.6),
        shape([("M", 64, 45), ("L", 58, 33)], sw=2.6),
        shape([("M", 188, 60), ("L", 200, 50)], sw=2.6),
        shape([("M", 195, 76), ("L", 209, 72)], sw=2.6),
        shape([("M", 176, 45), ("L", 182, 33)], sw=2.6),
        # 몸(우주복) + 똑딱단추
        shape(body, fill="paper", dots=True, sw=3, dot_bounds=(58, 190, 182, 226)),
        shape(circle_cmds(120, 198, 3.2), fill="paper", sw=1.8),
        shape(circle_cmds(120, 212, 3.2), fill="paper", sw=1.8),
        # 귀 → 머리
        shape(circle_cmds(65, 108, 10), fill="paper", sw=2.4),
        shape(circle_cmds(175, 108, 10), fill="paper", sw=2.4),
        shape(circle_cmds(120, 104, 56), fill="paper", sw=3),
        shape([("M", 114, 48), ("C", 111, 38, 122, 33, 127, 41)], sw=2.6),
        # 볼 홍조(하프톤)
        shape(circle_cmds(80, 124, 11), dots=True),
        shape(circle_cmds(160, 124, 11), dots=True),
        # 찡그린 눈썹 + 질끈 감은 눈(><)
        shape([("M", 86, 82), ("L", 100, 76)], sw=2.4),
        shape([("M", 154, 82), ("L", 140, 76)], sw=2.4),
        shape([("M", 88, 90), ("L", 102, 98), ("L", 88, 106)], sw=3.2),
        shape([("M", 152, 90), ("L", 138, 98), ("L", 152, 106)], sw=3.2),
        # 크게 벌린 입 + 혀
        shape(mouth, fill="ink"),
        shape(tongue, fill="paper"),
        # 쥔 주먹
        shape(circle_cmds(84, 160, 13), fill="paper", sw=3),
        shape(circle_cmds(156, 160, 13), fill="paper", sw=3),
        shape([("M", 90, 151), ("C", 94, 155, 94, 164, 90, 168)], sw=1.8),
        shape([("M", 150, 151), ("C", 146, 155, 146, 164, 150, 168)], sw=1.8),
        # 눈물(액센트)
        shape(drop_cmds(70, 90, 16), fill="dot", sw=1.6),
        shape(drop_cmds(50, 128, 11), fill="dot", sw=1.6),
        shape(drop_cmds(170, 90, 16), fill="dot", sw=1.6),
        shape(drop_cmds(190, 128, 11), fill="dot", sw=1.6),
    ]


# ───────────────────────── ② 케어 가방 ─────────────────────────

def ob_care():
    bag = [
        ("M", 62, 112), ("L", 178, 112), ("L", 188, 214),
        ("C", 189, 221, 184, 226, 177, 226), ("L", 63, 226),
        ("C", 56, 226, 51, 221, 52, 214), ("Z",),
    ]
    # 젖병(로컬 좌표, 중심 0,0)
    bottle_body = rrect_cmds(-14, -8, 28, 48, 9)
    bottle_ring = rrect_cmds(-16, -15, 32, 8, 3)
    teat = [("M", -10, -15), ("C", -10, -24, -6, -29, 0, -29),
            ("C", 6, -29, 10, -24, 10, -15), ("Z",)]
    nipple = [("M", -4, -29), ("C", -4, -35, -2, -38, 0, -38),
              ("C", 2, -38, 4, -35, 4, -29), ("Z",)]
    bx, by, ba, bs = 98, 96, -14, 1.1
    # 딸랑이(로컬 좌표)
    rx, ry, ra = 148, 84, 16
    heart = [
        ("M", 0, 7), ("C", -13, -2, -11, -13, -4.5, -13), ("C", -1.5, -13, 0, -10.5, 0, -8),
        ("C", 0, -10.5, 1.5, -13, 4.5, -13), ("C", 11, -13, 13, -2, 0, 7), ("Z",),
    ]
    return [
        # 장식
        plus_shape(30, 74, 7, 2.6), sq_shape(214, 60, 5.4, False),
        star_shape(212, 150, 7), sq_shape(28, 180, 5, True),
        # 손잡이(가장 뒤)
        shape([("M", 88, 112), ("C", 88, 76, 152, 76, 152, 112)], sw=3),
        # 젖병
        shape(rot_cmds(bottle_body, bx, by, ba, bs), fill="paper", dots=True, sw=3,
              dot_bounds=(78, 102, 126, 150)),
        shape(rot_cmds([("M", 5, 2), ("L", 12, 2)], bx, by, ba, bs), sw=1.6),
        shape(rot_cmds([("M", 5, 10), ("L", 12, 10)], bx, by, ba, bs), sw=1.6),
        shape(rot_cmds(bottle_ring, bx, by, ba, bs), fill="paper", sw=2.2),
        shape(rot_cmds(teat, bx, by, ba, bs), fill="paper", sw=2.2),
        shape(rot_cmds(nipple, bx, by, ba, bs), fill="paper", sw=2),
        # 딸랑이
        shape(rot_cmds(capsule_cmds(0, 12, 0, 50, 5.5), rx, ry, ra), fill="paper", sw=2.6),
        shape(rot_cmds(circle_cmds(0, -10, 21), rx, ry, ra), fill="paper", dots=True, sw=3),
        shape(rot_cmds([("M", -21, -10), ("C", -10, -3, 10, -3, 21, -10)], rx, ry, ra), sw=2.2),
        shape(rot_cmds(circle_cmds(0, -35, 4.5), rx, ry, ra), fill="paper", sw=2.2),
        # 흔들림 표시
        shape([("M", 184, 56), ("C", 190, 62, 190, 72, 186, 78)], sw=2.4),
        shape([("M", 194, 50), ("C", 202, 60, 202, 76, 196, 84)], sw=2),
        # 하트(액센트)
        shape(tf_cmds(heart, 0, 0, 1.25, 122, 52), fill="dot", sw=2),
        # 가방 몸체 + 테두리 띠 + 케어 라벨
        shape(bag, fill="paper", dots=True, sw=3, dot_bounds=(50, 190, 190, 228)),
        shape([("M", 59, 134), ("L", 181, 134)], sw=2.2),
        shape(rrect_cmds(96, 150, 48, 28, 6), fill="paper", sw=2.4),
        plus_shape(120, 164, 6.5, 2.8),
    ]


# ───────────────────────── ③ 구름 위 잠 ─────────────────────────

def ob_sleep():
    # 증상 일러스트 sleep_moon 의 초승달을 1.2배로 옮겨 재사용(그림체 연속성).
    crescent = [
        ("M", 74, 34),
        ("C", 52, 34, 36, 48, 36, 66), ("C", 36, 84, 52, 98, 74, 98),
        ("C", 78, 98, 82, 97, 85, 96),
        ("C", 68, 92, 58, 80, 58, 66), ("C", 58, 52, 68, 40, 85, 36),
        ("C", 82, 35, 78, 34, 74, 34), ("Z",),
    ]
    moon_eye = [("M", 44, 62), ("C", 46, 65, 50, 65, 52, 62)]
    cloud = [
        ("M", 40, 216), ("C", 20, 216, 16, 192, 36, 188),
        ("C", 36, 170, 58, 164, 68, 176), ("C", 76, 162, 98, 160, 108, 172),
        ("C", 118, 160, 142, 160, 150, 174), ("C", 160, 164, 182, 166, 186, 182),
        ("C", 206, 180, 214, 204, 200, 214), ("C", 198, 216, 196, 216, 192, 216), ("Z",),
    ]
    return [
        # 장식
        star_shape(40, 54, 8), star_shape(92, 26, 5, sw=1.8),
        plus_shape(214, 136, 6, 2.4), sq_shape(24, 124, 5, True),
        sq_shape(122, 44, 4.4, False),
        # 달(졸린 눈)
        shape(tf_cmds(crescent, 60, 66, 1.2, 172, 72), fill="paper", dots=True, sw=3),
        shape(tf_cmds(moon_eye, 60, 66, 1.2, 172, 72), sw=2.4),
        # Z z
        zig(120, 84, 15, 16, 2.8),
        zig(104, 110, 10, 11, 2.4),
        # 구름 침대
        shape(cloud, fill="paper", dots=True, sw=3, dot_bounds=(16, 200, 216, 218)),
        # 포대기 아기
        shape(capsule_cmds(98, 160, 172, 160, 22), fill="paper", dots=True, sw=3,
              dot_bounds=(132, 136, 196, 184)),
        shape([("M", 118, 139), ("C", 128, 150, 128, 170, 118, 181)], sw=2.2),
        shape(circle_cmds(82, 152, 27), fill="paper", sw=3),
        shape([("M", 78, 125), ("C", 76, 116, 86, 112, 89, 120)], sw=2.4),
        shape(circle_cmds(66, 161, 6), dots=True),
        shape(circle_cmds(98, 161, 6), dots=True),
        shape([("M", 67, 150), ("C", 70, 154, 75, 154, 78, 150)], sw=2.4),
        shape([("M", 86, 150), ("C", 89, 154, 94, 154, 97, 150)], sw=2.4),
        shape(circle_cmds(82, 164, 2.6), fill="paper", sw=1.8),
    ]


ILLUSTRATIONS = {
    "cry": ("① 우는 아기", ob_cry),
    "care": ("② 케어 가방", ob_care),
    "sleep": ("③ 구름 위 잠", ob_sleep),
}


# ───────────────────────── SVG 미리보기 ─────────────────────────

def sheet(colors):
    bgc, ink, paper, dot = colors
    cell, pad = 260, 12
    W = len(ILLUSTRATIONS) * (cell + pad) + pad
    H = cell + pad * 2
    p = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W*2}" height="{H*2}">',
         f'<rect width="{W}" height="{H}" fill="{bgc}"/>']
    for i, (_, fn) in enumerate(ILLUSTRATIONS.values()):
        x = pad + i * (cell + pad)
        p.append(f'<g transform="translate({x},{pad})">')
        p.append(f'<rect width="{cell}" height="{cell}" rx="20" fill="{paper}" stroke="{ink}" stroke-opacity="0.12"/>')
        p.append(f'<g transform="translate(10,10) scale({(cell - 20) / VB})">')
        for s in fn():
            p.append(g.svg_shape(s, ink, paper, dot))
        p.append("</g></g>")
    p.append("</svg>")
    return "".join(p)


def single(key, colors, size=720):
    bgc, ink, paper, dot = colors
    p = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {VB} {VB}" width="{size}" height="{size}">',
         f'<rect width="{VB}" height="{VB}" fill="{bgc}"/>']
    for s_ in ILLUSTRATIONS[key][1]():
        p.append(g.svg_shape(s_, ink, paper, dot))
    p.append("</svg>")
    return "".join(p)


# ───────────────────────── Dart 코드젠 ─────────────────────────

DART_HEADER = """\
// GENERATED CODE — 직접 수정 금지.
//
// 원본: tool/illustrations/generate_onboarding_illustrations.py
// 재생성: python3 tool/illustrations/generate_onboarding_illustrations.py --dart
//
// 온보딩 3장 히어로 일러스트(뷰박스 240). 렌더 엔진은 증상 일러스트와 같은
// `InkIllustration`(symptom_illustration.dart)이다.

import '../../../widgets/symptom/symptom_illustration.dart';

/// 온보딩 일러스트 뷰박스 한 변.
const double onboardingIllustrationViewBox = 240;
"""


def dart_file():
    out = [DART_HEADER]
    for key, (name, fn) in ILLUSTRATIONS.items():
        out.append(f"/// {name}")
        out.append(f"const List<IllustrationShape> onboarding{key.capitalize()}Shapes = <IllustrationShape>[")
        for s in fn():
            out.append(g.dart_shape(s))
        out.append("];\n")
    return "\n".join(out)


if __name__ == "__main__":
    here = pathlib.Path(__file__).parent
    repo = here.parent.parent
    preview = here / "preview"
    preview.mkdir(exist_ok=True)
    (preview / "onboarding_light.svg").write_text(sheet(g.LIGHT))
    (preview / "onboarding_dark.svg").write_text(sheet(g.DARK))
    for key in ILLUSTRATIONS:
        for mode, colors in (("light", g.LIGHT), ("dark", g.DARK)):
            (preview / f"onboarding_{key}_{mode}.svg").write_text(single(key, colors))
    if "--dart" in sys.argv:
        out = repo / "lib/presentation/features/onboarding/widgets/onboarding_illustration_data.dart"
        out.write_text(dart_file())
        print(f"wrote {out} — dart format 후 커밋할 것")
    print("ok (미리보기: tool/illustrations/preview/onboarding_*.svg)")
