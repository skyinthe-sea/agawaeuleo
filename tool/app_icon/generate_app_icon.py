#!/usr/bin/env python3
"""아가왜울어 앱 아이콘 생성기 — 토스풍(단색 라운드 스퀘어 + 단일 심볼).

앱 이름 "아가왜울어"를 그대로 형상화한 마크: 인주색(seal) 배경 위에
한지 미색 아기 얼굴 실루엣(배냇머리 한 가닥) + 감은 눈·우는 입·눈물 한 방울을
배경색으로 펀치아웃한 2톤 심볼. 색은 DESIGN v2 §3.1 브랜드 토큰 고정.

생성물(직접 편집 금지 — 반드시 이 스크립트로 재생성):
  - iOS  : ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png (풀블리드, 알파 없음)
  - AOS  : android/app/src/main/res/mipmap-*/ic_launcher.png (레거시, 라운드+알파)
           android/app/src/main/res/mipmap-*/ic_launcher_foreground.png (적응형 전경)
           android/app/src/main/res/mipmap-*/ic_launcher_monochrome.png (테마 아이콘)
           (배경색·adaptive xml·colors.xml 은 리포에 고정 — 이 스크립트는 PNG만 생성)

실행: python3 tool/app_icon/generate_app_icon.py
미리보기: python3 tool/app_icon/generate_app_icon.py --preview /tmp/preview.png
"""

import pathlib
import sys

from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parents[2]

# DESIGN v2 §3.1 토큰(light) — 아이콘은 라이트 팔레트를 브랜드 기준값으로 쓴다.
SEAL = (0xA8, 0x43, 0x2C)        # colors.seal — 인주(브랜드)
SEAL_TOP = (0xB5, 0x4C, 0x34)    # 상단 미세 광원(아주 옅은 톤업)
CREAM = (0xF0, 0xEA, 0xDB)       # colors.paperBg — 얼굴 실루엣
INK = (0x26, 0x29, 0x2B)         # colors.ink900 — 내부 헤어라인(저알파)

# 라운드 스퀘어 코너 비율(InkSeal 0.24 계열 — 레거시 아이콘용).
LEGACY_RADIUS = 0.2237
# 풀스퀘어에서 마크 박스가 차지하는 비율.
MARK_RATIO_FULL = 0.68
# 적응형/모노 108 그리드에서 마크 박스 비율(66/108 세이프존 내부에 안전히 안착).
MARK_RATIO_ADAPTIVE = 0.52

# ---- 마크 지오메트리(마크 박스 0..1 정규화 좌표) ----------------------------
FACE_C = (0.50, 0.565)   # 얼굴 중심
FACE_R = 0.36            # 얼굴 반지름
CURL_C = (0.578, 0.178)  # 배냇머리 곡선의 원 중심
CURL_R = 0.078
CURL_W = 0.042
CURL_ARC = (145, 330)    # PIL 각도: 0=동쪽, 시계방향(y-down)
EYE_Y = 0.500
EYE_DX = 0.135           # 얼굴 중심에서 눈까지 x 오프셋
EYE_R = 0.078
EYE_W = 0.038
MOUTH_C = (0.50, 0.690)
MOUTH_RX = 0.088
MOUTH_RY = 0.082
TEAR_C = (0.695, 0.655)  # 눈물 방울 원 중심(오른눈 아래 뺨)
TEAR_R = 0.048
TEAR_TIP_Y = 0.568       # 눈물 꼭짓점 y


def _arc_with_caps(draw, center, r, start, end, width, fill):
    """둥근 캡을 가진 스트로크 아크(PIL arc는 버트 캡이라 양끝에 도트 보강)."""
    import math

    cx, cy = center
    bbox = [cx - r, cy - r, cx + r, cy + r]
    draw.arc(bbox, start, end, fill=fill, width=max(1, int(width)))
    # PIL arc는 bbox 안쪽으로 두께가 자라므로 스트로크 중심선은 r - w/2.
    mid_r = r - width / 2
    for ang in (start, end):
        rad = math.radians(ang)
        ex = cx + mid_r * math.cos(rad)
        ey = cy + mid_r * math.sin(rad)
        cap = width / 2
        draw.ellipse([ex - cap, ey - cap, ex + cap, ey + cap], fill=fill)


def _mark_mask(size: int, mark_px: float) -> Image.Image:
    """정중앙 마크의 알파 마스크(L). 얼굴+머리카락에서 이목구비·눈물을 펀치아웃."""
    m = mark_px
    ox = (size - m) / 2
    oy = (size - m) / 2

    def p(x, y):
        return (ox + x * m, oy + y * m)

    solid = Image.new("L", (size, size), 0)
    ds = ImageDraw.Draw(solid)
    # 얼굴 실루엣.
    fx, fy = p(*FACE_C)
    fr = FACE_R * m
    ds.ellipse([fx - fr, fy - fr, fx + fr, fy + fr], fill=255)
    # 배냇머리 한 가닥(머리 정수리에서 오른쪽 위로 말려 올라가는 곡선).
    _arc_with_caps(ds, p(*CURL_C), CURL_R * m, CURL_ARC[0], CURL_ARC[1],
                   CURL_W * m, 255)

    punch = Image.new("L", (size, size), 0)
    dp = ImageDraw.Draw(punch)
    # 감은 눈 두 개(∩ 아크).
    for sx in (-1, 1):
        _arc_with_caps(dp, p(FACE_C[0] + sx * EYE_DX, EYE_Y), EYE_R * m,
                       180, 360, EYE_W * m, 255)
    # 우는 입(응애 — 세로로 열린 타원).
    mx, my = p(*MOUTH_C)
    rx, ry = MOUTH_RX * m, MOUTH_RY * m
    dp.ellipse([mx - rx, my - ry, mx + rx, my + ry], fill=255)
    # 눈물 한 방울(오른눈 아래 — 위가 뾰족한 물방울).
    tx, ty = p(*TEAR_C)
    tr = TEAR_R * m
    tipx, tipy = p(TEAR_C[0], TEAR_TIP_Y)
    dp.ellipse([tx - tr, ty - tr, tx + tr, ty + tr], fill=255)
    dp.polygon([(tipx, tipy), (tx - tr, ty), (tx + tr, ty)], fill=255)

    solid.paste(0, (0, 0), punch)
    return solid


def _draw_mark(img: Image.Image, mark_px: float, color) -> None:
    layer = Image.new("RGBA", img.size, (*color[:3], 0))
    layer.putalpha(_mark_mask(img.width, mark_px))
    img.alpha_composite(layer)


def _vertical_sheen(size: int) -> Image.Image:
    """상단이 아주 미세하게 밝은 세로 그라디언트(토스풍 은은한 입체). 거의 평면."""
    grad = Image.new("RGB", (1, size))
    for y in range(size):
        f = y / max(1, size - 1)
        r = round(SEAL_TOP[0] + (SEAL[0] - SEAL_TOP[0]) * f)
        g = round(SEAL_TOP[1] + (SEAL[1] - SEAL_TOP[1]) * f)
        b = round(SEAL_TOP[2] + (SEAL[2] - SEAL_TOP[2]) * f)
        grad.putpixel((0, y), (r, g, b))
    return grad.resize((size, size))


def render_full(px: int, *, rounded: bool, opaque: bool) -> Image.Image:
    """풀블리드 아이콘(배경+마크). iOS=사각/불투명, 레거시 AOS=라운드/알파."""
    ss = max(1, min(4, 2048 // max(1, px)))
    big = px * ss
    base = _vertical_sheen(big)

    if rounded:
        canvas = Image.new("RGBA", (big, big), (0, 0, 0, 0))
        mask = Image.new("L", (big, big), 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            [0, 0, big - 1, big - 1],
            radius=int(big * LEGACY_RADIUS),
            fill=255,
        )
        canvas.paste(base, (0, 0), mask)
        # 내부 헤어라인(InkSeal 12% 톤) — 라운드 스퀘어 안쪽 경계.
        line = Image.new("RGBA", (big, big), (0, 0, 0, 0))
        ld = ImageDraw.Draw(line)
        inset = int(big * 0.015)
        lw = max(1, int(big * 0.006))
        ld.rounded_rectangle(
            [inset, inset, big - 1 - inset, big - 1 - inset],
            radius=int(big * LEGACY_RADIUS * 0.92),
            outline=(*INK, 28),
            width=lw,
        )
        canvas = Image.alpha_composite(canvas, line)
        img = canvas
    else:
        img = base.convert("RGBA")

    _draw_mark(img, big * MARK_RATIO_FULL, CREAM)
    img = img.resize((px, px), Image.LANCZOS)
    if opaque:
        flat = Image.new("RGB", (px, px), SEAL)
        flat.paste(img, (0, 0), img)
        return flat
    return img


def render_layer(px: int, color) -> Image.Image:
    """적응형 전경 / 모노크롬 — 투명 배경에 마크만(108 그리드 세이프존 안착)."""
    ss = max(1, min(4, 2048 // max(1, px)))
    big = px * ss
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    _draw_mark(img, big * MARK_RATIO_ADAPTIVE, color)
    return img.resize((px, px), Image.LANCZOS)


def save(img: Image.Image, path: pathlib.Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)
    print(f"  ✓ {path.relative_to(ROOT) if path.is_relative_to(ROOT) else path} "
          f"({img.width}x{img.height})")


def preview(out: pathlib.Path) -> None:
    """검수용 시트: 512 풀블리드 + 레거시 라운드 + 48px 실측 + 모노 레이어."""
    sheet = Image.new("RGB", (1200, 640), (240, 240, 244))
    sheet.paste(render_full(512, rounded=False, opaque=True), (40, 64))
    sheet.paste(render_full(192, rounded=True, opaque=False).convert("RGB"),
                (600, 64))
    sheet.paste(render_full(48, rounded=True, opaque=False).convert("RGB"),
                (600, 300))
    mono = Image.new("RGB", (216, 216), (60, 60, 66))
    layer = render_layer(216, (255, 255, 255, 255))
    mono.paste(layer, (0, 0), layer)
    sheet.paste(mono, (840, 64))
    sheet.save(out)
    print(f"  ✓ preview → {out}")


def main() -> None:
    if len(sys.argv) >= 3 and sys.argv[1] == "--preview":
        preview(pathlib.Path(sys.argv[2]))
        return

    android = ROOT / "android/app/src/main/res"
    ios = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"

    # --- Android 레거시(라운드+알파) ---
    legacy = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    print("Android 레거시 ic_launcher.png:")
    for dens, sz in legacy.items():
        save(render_full(sz, rounded=True, opaque=False),
             android / f"mipmap-{dens}/ic_launcher.png")

    # --- Android 적응형 전경 + 모노크롬(108dp 그리드) ---
    fg = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
    print("Android 적응형 전경/모노크롬:")
    for dens, sz in fg.items():
        save(render_layer(sz, CREAM),
             android / f"mipmap-{dens}/ic_launcher_foreground.png")
        save(render_layer(sz, (255, 255, 255, 255)),
             android / f"mipmap-{dens}/ic_launcher_monochrome.png")

    # --- iOS(풀블리드, 알파 없음) ---
    ios_targets = {
        "Icon-App-20x20@1x.png": 20, "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60, "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58, "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40, "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120, "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180, "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152, "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    print("iOS AppIcon.appiconset:")
    for name, sz in ios_targets.items():
        save(render_full(sz, rounded=False, opaque=True), ios / name)

    print("\n완료. Android는 mipmap-anydpi-v26/ic_launcher.xml(적응형) 우선 적용됨.")


if __name__ == "__main__":
    main()
