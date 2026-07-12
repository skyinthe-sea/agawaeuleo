#!/usr/bin/env python3
"""아가왜울어 앱 아이콘 생성기 — 토스풍(단색 라운드 스퀘어 + 단일 글리프).

브랜드 오브제 `InkSeal`(DESIGN v2 §4.1, `lib/presentation/widgets/brand/ink_seal.dart`)을
런처 아이콘으로 승격한다. 인주색(seal) 라운드 스퀘어 배경 + 명조 700 "아" 글리프(한지 미색).

생성물(직접 편집 금지 — 반드시 이 스크립트로 재생성):
  - iOS  : ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png (풀블리드, 알파 없음)
  - AOS  : android/app/src/main/res/mipmap-*/ic_launcher.png (레거시, 라운드+알파)
           android/app/src/main/res/mipmap-*/ic_launcher_foreground.png (적응형 전경)
           android/app/src/main/res/mipmap-*/ic_launcher_monochrome.png (테마 아이콘)
           (배경색·adaptive xml·colors.xml 은 리포에 고정 — 이 스크립트는 PNG만 생성)

실행: python3 tool/app_icon/generate_app_icon.py
"""

import pathlib

from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parents[2]
FONT = ROOT / "assets/fonts/NotoSerifKR-Bold.ttf"

# DESIGN v2 §3.1 토큰(light) — 아이콘은 라이트 팔레트를 브랜드 기준값으로 쓴다.
SEAL = (0xA8, 0x43, 0x2C)        # colors.seal — 인주(브랜드)
SEAL_TOP = (0xB5, 0x4C, 0x34)    # 상단 미세 광원(아주 옅은 톤업)
CREAM = (0xF0, 0xEA, 0xDB)       # colors.paperBg — 글리프
INK = (0x26, 0x29, 0x2B)         # colors.ink900 — 내부 헤어라인(저알파)
GLYPH = "아"

# 라운드 스퀘어 코너 비율(InkSeal 0.24 계열 — 레거시 아이콘용).
LEGACY_RADIUS = 0.2237
# 풀스퀘어에서 글리프 높이가 차지하는 비율.
GLYPH_RATIO_FULL = 0.52
# 적응형/모노 108 그리드에서 글리프 높이 비율(마스크 세이프존 내부에 안전히 안착).
GLYPH_RATIO_ADAPTIVE = 0.40


def _fit_font(px: float) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT), max(1, int(px)))


def _draw_glyph(img: Image.Image, glyph_px: float, color) -> None:
    """이미지 정중앙에 글리프를 그린다(광학 중심 보정 포함)."""
    draw = ImageDraw.Draw(img)
    font = _fit_font(glyph_px)
    # 실제 잉크 바운딩으로 중심을 잡는다(한글은 폰트 메트릭 여백이 커서 anchor만으론 치우침).
    l, t, r, b = draw.textbbox((0, 0), GLYPH, font=font)
    gw, gh = r - l, b - t
    cx, cy = img.width / 2, img.height / 2
    # 시각 균형: 명조 "아"는 아래쪽이 무거워 살짝 위로 올린다.
    ox = cx - (l + gw / 2)
    oy = cy - (t + gh / 2) - img.height * 0.012
    draw.text((ox, oy), GLYPH, font=font, fill=color)


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
    """풀블리드 아이콘(배경+글리프). iOS=사각/불투명, 레거시 AOS=라운드/알파."""
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

    _draw_glyph(img, big * GLYPH_RATIO_FULL, CREAM)
    img = img.resize((px, px), Image.LANCZOS)
    if opaque:
        flat = Image.new("RGB", (px, px), SEAL)
        flat.paste(img, (0, 0), img)
        return flat
    return img


def render_layer(px: int, color) -> Image.Image:
    """적응형 전경 / 모노크롬 — 투명 배경에 글리프만(108 그리드 기준 세이프존 안착)."""
    ss = max(1, min(4, 2048 // max(1, px)))
    big = px * ss
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    _draw_glyph(img, big * GLYPH_RATIO_ADAPTIVE, color)
    return img.resize((px, px), Image.LANCZOS)


def save(img: Image.Image, path: pathlib.Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)
    print(f"  ✓ {path.relative_to(ROOT)} ({img.width}x{img.height})")


def main() -> None:
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
