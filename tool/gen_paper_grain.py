#!/usr/bin/env python3
"""DESIGN v2 §8 — 종이 그레인 타일 생성기 (stdlib만 사용, 시드 고정 재현 가능).

출력: assets/textures/paper_grain.png (144x144 RGBA)
- 전 픽셀 흰색 + 알파 = 균등난수(0~255)를 18%로 감쇠(0~46)
- 한지 섬유질: 길이 4~10px 수평/사선 스트로크 70개(알파 28~48), 타일 랩어라운드
"""

import random
import struct
import zlib
from pathlib import Path

SIZE = 144
SEED = 20260710
NOISE_SCALE = 0.18
FIBER_COUNT = 70

rng = random.Random(SEED)

# 알파 평면
alpha = [[int(rng.randint(0, 255) * NOISE_SCALE) for _ in range(SIZE)] for _ in range(SIZE)]

# 섬유질 스트로크 (랩어라운드로 타일 이음새 제거)
for _ in range(FIBER_COUNT):
    x = rng.randrange(SIZE)
    y = rng.randrange(SIZE)
    length = rng.randint(4, 10)
    a = rng.randint(28, 48)
    dx, dy = rng.choice([(1, 0), (1, 0), (1, 0), (1, 1), (1, -1)])  # 수평 위주
    for i in range(length):
        px = (x + dx * i) % SIZE
        py = (y + dy * i) % SIZE
        alpha[py][px] = max(alpha[py][px], a)

# PNG 인코딩 (RGBA8)
raw = b"".join(
    b"\x00" + b"".join(struct.pack("4B", 255, 255, 255, alpha[y][x]) for x in range(SIZE))
    for y in range(SIZE)
)


def chunk(tag: bytes, data: bytes) -> bytes:
    return (
        struct.pack(">I", len(data))
        + tag
        + data
        + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    )


png = (
    b"\x89PNG\r\n\x1a\n"
    + chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 6, 0, 0, 0))
    + chunk(b"IDAT", zlib.compress(raw, 9))
    + chunk(b"IEND", b"")
)

out = Path(__file__).resolve().parent.parent / "assets" / "textures" / "paper_grain.png"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_bytes(png)
print(f"wrote {out} ({len(png)} bytes)")
