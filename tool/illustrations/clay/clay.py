"""말랑 클레이 렌더러 — 2.5D 높이맵으로 "손으로 빚은 점토 오브제"를 그린다.

아가왜울어 DESIGN v3("몽글 클레이")의 일러스트 엔진. 모든 증상·온보딩·스플래시·
앱 아이콘 그림이 이 한 파일의 셰이딩 규칙을 거쳐 그림체가 강제로 통일된다.

왜 레이마칭이 아니라 높이맵인가
  레퍼런스 스타일(정면을 보는 점토 배지 — 납작한 뒷면, 봉긋한 앞면, 부드러운
  그림자)은 결국 부조(bas-relief)다. 정면 정사영에서 필요한 건 픽셀마다 "가장
  앞의 높이" 하나뿐이라, 조각마다 2D 윤곽(SDF) + 단면 프로파일로 높이를 쌓으면
  3D 레이마칭의 1/100 비용으로 같은 결을 얻는다(1536² 한 장 ≈ 1~3초, numpy만).

좌표계
  뷰박스 VB(기본 120) 단위, x 오른쪽 / y 아래(SVG와 동일). 높이 z는 화면 밖(관찰자)
  방향 +. 광원은 좌상단 앞(레퍼런스와 같은 방향)이고 그림자는 우하단으로 진다.

조각 모델
  blob(shape, color, height, bevel, mode)
    shape  — 2D 부호거리 함수(안쪽 음수). `sdf2d`의 원·타원·캡슐·다각형 등을 조합.
    bevel  — 가장자리에서 안쪽으로 둥글게 부푸는 폭(작으면 쿠키, 크면 베개/구).
    height — 다 부푼 뒤의 높이.
    mode   — 'stack'(아래 면 위에 덧붙임 — 점토를 눌러 붙인 결) / 'max'(독립 물체).
  paint(shape, color, soft, depth) — 표면에 칠하는 데칼(볼터치·입). depth>0이면 오목.
"""
from __future__ import annotations

import math
from dataclasses import dataclass
from typing import Callable

import numpy as np
from PIL import Image, ImageFilter

VB = 120.0


# ────────────────────────────── 색 ──────────────────────────────

def hex_rgb(h: str) -> np.ndarray:
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)], np.float32)


def srgb_to_lin(c):
    c = np.asarray(c, np.float32)
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def lin_to_srgb(c):
    c = np.clip(c, 0.0, 1.0)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * np.power(c, 1 / 2.4) - 0.055)


# ────────────────────────────── 2D SDF ──────────────────────────────

Fn = Callable[[np.ndarray, np.ndarray], np.ndarray]


@dataclass
class Shape:
    """2D 부호거리 함수 + 경계 상자(뷰박스 단위). 연산자로 조합한다."""

    fn: Fn
    bbox: tuple[float, float, float, float]

    def __call__(self, x, y):
        return self.fn(x, y)

    # 합집합 / 차집합 / 교집합
    def __or__(self, o: "Shape") -> "Shape":
        return Shape(lambda x, y: np.minimum(self.fn(x, y), o.fn(x, y)), _bb_union(self.bbox, o.bbox))

    def __sub__(self, o: "Shape") -> "Shape":
        return Shape(lambda x, y: np.maximum(self.fn(x, y), -o.fn(x, y)), self.bbox)

    def __and__(self, o: "Shape") -> "Shape":
        return Shape(lambda x, y: np.maximum(self.fn(x, y), o.fn(x, y)), self.bbox)

    def smooth(self, o: "Shape", k: float) -> "Shape":
        """부드러운 합집합(k = 필렛 폭)."""
        def f(x, y):
            a, b = self.fn(x, y), o.fn(x, y)
            h = np.clip(0.5 + 0.5 * (b - a) / k, 0, 1)
            return b * (1 - h) + a * h - k * h * (1 - h)
        return Shape(f, _bb_union(self.bbox, o.bbox))

    def dilate(self, r: float) -> "Shape":
        x0, y0, x1, y1 = self.bbox
        return Shape(lambda x, y: self.fn(x, y) - r, (x0 - r, y0 - r, x1 + r, y1 + r))

    def rotate(self, deg: float, cx: float, cy: float) -> "Shape":
        a = math.radians(deg)
        ca, sa = math.cos(a), math.sin(a)

        def f(x, y):
            dx, dy = x - cx, y - cy
            # 점을 반대로 돌려 원래 도형 좌표에서 평가.
            return self.fn(cx + dx * ca + dy * sa, cy - dx * sa + dy * ca)
        x0, y0, x1, y1 = self.bbox
        corners = [(x0, y0), (x1, y0), (x0, y1), (x1, y1)]
        pts = [(cx + (px - cx) * ca - (py - cy) * sa, cy + (px - cx) * sa + (py - cy) * ca) for px, py in corners]
        xs, ys = [p[0] for p in pts], [p[1] for p in pts]
        return Shape(f, (min(xs), min(ys), max(xs), max(ys)))

    def translate(self, dx: float, dy: float) -> "Shape":
        x0, y0, x1, y1 = self.bbox
        return Shape(lambda x, y: self.fn(x - dx, y - dy), (x0 + dx, y0 + dy, x1 + dx, y1 + dy))

    def scale(self, s: float, cx: float, cy: float) -> "Shape":
        x0, y0, x1, y1 = self.bbox
        return Shape(
            lambda x, y: self.fn(cx + (x - cx) / s, cy + (y - cy) / s) * s,
            (cx + (x0 - cx) * s, cy + (y0 - cy) * s, cx + (x1 - cx) * s, cy + (y1 - cy) * s),
        )


def _bb_union(a, b):
    return (min(a[0], b[0]), min(a[1], b[1]), max(a[2], b[2]), max(a[3], b[3]))


def circle(cx, cy, r) -> Shape:
    return Shape(lambda x, y: np.hypot(x - cx, y - cy) - r, (cx - r, cy - r, cx + r, cy + r))


def ellipse(cx, cy, rx, ry, deg=0.0) -> Shape:
    # 근사 SDF(가장자리 근처에서 정확, 안쪽은 과소평가 — 베벨 프로파일엔 충분).
    def f(x, y):
        px, py = (x - cx) / rx, (y - cy) / ry
        k0 = np.hypot(px, py)
        k1 = np.hypot(px / rx, py / ry)
        return k0 * (k0 - 1.0) / np.maximum(k1, 1e-6)
    s = Shape(f, (cx - rx, cy - ry, cx + rx, cy + ry))
    return s.rotate(deg, cx, cy) if deg else s


def rbox(cx, cy, w, h, r, deg=0.0) -> Shape:
    """중심 (cx,cy), 전체 폭 w·높이 h, 모서리 반경 r의 둥근 사각형."""
    hw, hh = w / 2 - r, h / 2 - r

    def f(x, y):
        qx = np.abs(x - cx) - hw
        qy = np.abs(y - cy) - hh
        return np.hypot(np.maximum(qx, 0), np.maximum(qy, 0)) + np.minimum(np.maximum(qx, qy), 0) - r
    s = Shape(f, (cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2))
    return s.rotate(deg, cx, cy) if deg else s


def capsule(ax, ay, bx, by, r, rb=None) -> Shape:
    """선분 캡슐. rb를 주면 a→b로 반경이 가늘어지는 테이퍼."""
    rb = r if rb is None else rb

    def f(x, y):
        pax, pay = x - ax, y - ay
        bax, bay = bx - ax, by - ay
        L2 = max(bax * bax + bay * bay, 1e-9)
        h = np.clip((pax * bax + pay * bay) / L2, 0, 1)
        d = np.hypot(pax - bax * h, pay - bay * h)
        return d - (r + (rb - r) * h)
    m = max(r, rb)
    return Shape(f, (min(ax, bx) - m, min(ay, by) - m, max(ax, bx) + m, max(ay, by) + m))


def polyline(pts, r, r_end=None) -> Shape:
    """꺾은선 튜브(점토 국수). r_end를 주면 끝으로 갈수록 가늘어진다."""
    n = len(pts) - 1
    lens = [math.dist(pts[i], pts[i + 1]) for i in range(n)]
    total = sum(lens) or 1.0
    acc = [0.0]
    for L in lens:
        acc.append(acc[-1] + L)
    r_end = r if r_end is None else r_end
    segs = []
    for i in range(n):
        ra = r + (r_end - r) * acc[i] / total
        rb = r + (r_end - r) * acc[i + 1] / total
        segs.append(capsule(*pts[i], *pts[i + 1], ra, rb))
    out = segs[0]
    for s in segs[1:]:
        out = out | s
    return out


def bezier_pts(p0, p1, p2, p3, n=24):
    out = []
    for i in range(n + 1):
        t = i / n
        mt = 1 - t
        out.append((
            mt ** 3 * p0[0] + 3 * mt * mt * t * p1[0] + 3 * mt * t * t * p2[0] + t ** 3 * p3[0],
            mt ** 3 * p0[1] + 3 * mt * mt * t * p1[1] + 3 * mt * t * t * p2[1] + t ** 3 * p3[1],
        ))
    return out


def curve(p0, p1, p2, p3, r, r_end=None, n=24) -> Shape:
    return polyline(bezier_pts(p0, p1, p2, p3, n), r, r_end)


def arc(cx, cy, R, a0, a1, r, n=28, r_end=None) -> Shape:
    """원호 튜브. 각도(도)는 x축 기준 시계 방향(y 아래 좌표계)."""
    pts = [(cx + R * math.cos(math.radians(a0 + (a1 - a0) * i / n)),
            cy + R * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]
    return polyline(pts, r, r_end)


def polygon(pts) -> Shape:
    """임의 다각형(짝홀 규칙) SDF."""
    P = np.asarray(pts, np.float64)

    def f(x, y):
        d = None
        inside = np.zeros_like(x, dtype=bool)
        for i in range(len(P)):
            ax, ay = P[i]
            bx, by = P[(i + 1) % len(P)]
            ex, ey = bx - ax, by - ay
            wx, wy = x - ax, y - ay
            L2 = max(ex * ex + ey * ey, 1e-12)
            h = np.clip((wx * ex + wy * ey) / L2, 0, 1)
            di = np.hypot(wx - ex * h, wy - ey * h)
            d = di if d is None else np.minimum(d, di)
            c1 = (y >= ay) != (y >= by)
            xint = ax + (y - ay) * ex / np.where(np.abs(ey) < 1e-12, 1e-12, ey)
            inside ^= c1 & (x < xint)
        return np.where(inside, -d, d)
    return Shape(f, (P[:, 0].min(), P[:, 1].min(), P[:, 0].max(), P[:, 1].max()))


def rpolygon(pts, r) -> Shape:
    """모서리가 둥근 다각형(안쪽으로 r만큼 줄였다가 부풀린 결과와 유사)."""
    return _round_poly(pts, r) if r else polygon(pts)


def _round_poly(pts, r):
    base = polygon(pts)
    return Shape(lambda x, y: base.fn(x, y) + r, base.bbox).dilate(r)


def heart(cx, cy, s, deg=0.0) -> Shape:
    """폭 약 2s의 통통한 하트(두 원 + 아래 뾰족 — 끝을 둥글린 버전)."""
    lobe = s * 0.52
    l = circle(cx - s * 0.46, cy - s * 0.18, lobe)
    rr = circle(cx + s * 0.46, cy - s * 0.18, lobe)
    tip = polygon([(cx - s * 0.93, cy - s * 0.02), (cx + s * 0.93, cy - s * 0.02), (cx, cy + s * 0.92)])
    h = (l | rr).smooth(tip.dilate(0), s * 0.12)
    h = Shape(lambda x, y, f=h.fn: f(x, y), (cx - s, cy - s * 0.75, cx + s, cy + s * 0.95))
    return h.rotate(deg, cx, cy) if deg else h


def star(cx, cy, r, inner=0.5, pts_n=5, deg=-90.0, round_r=0.0) -> Shape:
    pts = []
    for i in range(pts_n * 2):
        rad = r if i % 2 == 0 else r * inner
        a = math.radians(deg + i * 180 / pts_n)
        pts.append((cx + rad * math.cos(a), cy + rad * math.sin(a)))
    if round_r:
        return _round_poly(pts, round_r)
    return polygon(pts)


def drop(cx, cy, r, tip=1.9, deg=0.0) -> Shape:
    """아래가 둥근 물방울(끝이 위). tip = 원 중심에서 끝까지 거리 / r."""
    body = circle(cx, cy, r)
    ang = math.asin(1 / tip)
    tx, ty = cx, cy - r * tip
    # 접선 삼각형.
    a1 = math.pi / 2 - ang
    p1 = (cx - r * math.cos(ang), cy - r * math.sin(ang))
    p2 = (cx + r * math.cos(ang), cy - r * math.sin(ang))
    tri = polygon([p1, (tx, ty), p2, (cx, cy)])
    s = (body | tri.dilate(0)).smooth(circle(tx, ty + r * 0.18, r * 0.12), r * 0.25)
    s = Shape(s.fn, (cx - r, ty, cx + r, cy + r))
    del a1
    return s.rotate(deg, cx, cy) if deg else s


def moon(cx, cy, r, bite=0.62, off=(0.42, -0.28), deg=0.0) -> Shape:
    s = circle(cx, cy, r) - circle(cx + r * off[0], cy + r * off[1], r * bite)
    return s.rotate(deg, cx, cy) if deg else s


def cloud(cx, cy, w, h) -> Shape:
    """폭 w·높이 h의 뭉게구름(원 4개 + 둥근 바닥)."""
    base = rbox(cx, cy + h * 0.18, w, h * 0.55, h * 0.27)
    c1 = circle(cx - w * 0.22, cy + h * 0.02, h * 0.34)
    c2 = circle(cx + w * 0.02, cy - h * 0.14, h * 0.44)
    c3 = circle(cx + w * 0.26, cy + h * 0.04, h * 0.30)
    return base.smooth(c1, h * 0.08).smooth(c2, h * 0.08).smooth(c3, h * 0.08)


# ────────────────────────────── 캔버스 ──────────────────────────────

class Clay:
    """조각을 쌓고 셰이딩까지 해서 RGBA PIL 이미지를 돌려준다.

    px   — 내부 렌더 해상도(슈퍼샘플). 출력은 px/ss.
    vb   — 뷰박스 한 변(단위).
    """

    # 레퍼런스 톤 — 따뜻한 크림 위 점토. 모든 그림이 같은 빛을 쓴다.
    LIGHT_DIR = np.array([-0.52, -0.62, 0.72], np.float32)  # 좌상단 앞(y 아래 좌표)
    SHADOW_COLOR = "#8A6152"

    def __init__(self, px: int = 1536, vb: float = VB, ss: int = 2):
        self.px = px
        self.vb = vb
        self.ss = ss
        self.s = px / vb  # 단위당 픽셀
        self.Z = np.zeros((px, px), np.float32)
        self.alb = np.zeros((px, px, 3), np.float32)  # 선형 알베도
        self.cov = np.zeros((px, px), np.float32)  # 알파 커버리지
        self.gloss = np.zeros((px, px), np.float32)  # 스페큘러 세기
        self.tag = np.zeros((px, px), np.int16)  # 가장 위 조각 태그
        self._tags: dict[str, int] = {}
        self._decals: list = []

    # ── 내부: 경계 상자 → 픽셀 슬라이스 + 좌표 격자 ──
    def _region(self, bbox, pad):
        x0, y0, x1, y1 = bbox
        s = self.s
        i0 = max(int(math.floor((y0 - pad) * s)), 0)
        i1 = min(int(math.ceil((y1 + pad) * s)) + 1, self.px)
        j0 = max(int(math.floor((x0 - pad) * s)), 0)
        j1 = min(int(math.ceil((x1 + pad) * s)) + 1, self.px)
        if i0 >= i1 or j0 >= j1:
            return None
        ys = (np.arange(i0, i1, dtype=np.float32) + 0.5) / s
        xs = (np.arange(j0, j1, dtype=np.float32) + 0.5) / s
        X, Y = np.meshgrid(xs, ys)
        return (slice(i0, i1), slice(j0, j1)), X, Y

    def tag_id(self, name: str | None) -> int:
        if not name:
            return 0
        if name not in self._tags:
            self._tags[name] = len(self._tags) + 1
        return self._tags[name]

    def blob(
        self,
        shape: Shape,
        color: str,
        height: float | None = None,
        bevel: float | None = None,
        mode: str = "stack",
        lift: float = 0.0,
        k: float = 0.0,
        gloss: float = 0.10,
        tag: str | None = None,
        dome: float = 0.0,
    ):
        """점토 조각 하나를 얹는다.

        bevel  가장자리 둥근 폭. None이면 조각 안쪽 반지름 추정치(베개 형태).
        height 다 부푼 높이. None이면 bevel*0.9.
        mode   'stack' 아래 표면 위에 덧붙임 / 'max' 독립(높은 쪽이 보임).
        lift   'max'에서 바닥으로부터 띄우는 높이(겹친 물체를 앞으로 당길 때).
        k      'max'에서 두 면이 만나는 필렛 폭.
        dome   조각 전체를 추가로 봉긋하게(중심이 높게) 하는 양.
        """
        pad = 1.0
        reg = self._region(shape.bbox, pad)
        if reg is None:
            return
        sl, X, Y = reg
        d = shape.fn(X, Y).astype(np.float32)
        inside = d < 0
        if not inside.any() and (d.min() * self.s > 1):
            return
        if bevel is None:
            bevel = max(float(-d.min()), 0.5)
        if height is None:
            height = bevel * 0.9
        t = np.clip(-d / bevel, 0, 1)
        prof = np.sqrt(np.clip(1 - (1 - t) ** 2, 0, 1)) * height
        if dome:
            inr = max(float(-d.min()), 1e-3)
            prof = prof + dome * np.clip(-d / inr, 0, 1) ** 0.6
        # 픽셀 커버리지(1px 폭 안티에일리어싱).
        cov = np.clip(0.5 - d * self.s, 0, 1)

        Zold = self.Z[sl]
        if mode == "stack":
            znew = Zold + prof
            vis = cov
        else:
            top = lift + prof
            if k > 0:
                # 부드러운 최대 — 두 조각 사이에 점토 필렛.
                h = np.clip(0.5 + 0.5 * (top - Zold) / k, 0, 1)
                zs = top * h + Zold * (1 - h) + k * h * (1 - h)
                znew = np.maximum(zs, Zold)
                vis = cov * np.clip((top - Zold) / k + 0.5, 0, 1)
            else:
                znew = np.maximum(top, Zold)
                vis = cov * np.clip((top - Zold) * self.s + 0.5, 0, 1)
        self.Z[sl] = Zold * (1 - cov) + znew * cov
        c = srgb_to_lin(hex_rgb(color))
        v3 = vis[..., None]
        self.alb[sl] = self.alb[sl] * (1 - v3) + c * v3
        self.gloss[sl] = self.gloss[sl] * (1 - vis) + gloss * vis
        self.cov[sl] = np.maximum(self.cov[sl], cov)
        tid = self.tag_id(tag)
        self.tag[sl] = np.where(vis > 0.5, tid, self.tag[sl])

    def paint(self, shape: Shape, color: str, soft: float = 0.35, depth: float = 0.0,
              on: str | list[str] | None = None, alpha: float = 1.0, gloss: float | None = None):
        """표면 데칼. soft = 가장자리 번짐 폭(단위), depth = 오목하게 누르는 깊이."""
        reg = self._region(shape.bbox, soft + 1)
        if reg is None:
            return
        sl, X, Y = reg
        d = shape.fn(X, Y).astype(np.float32)
        w = np.clip(0.5 - d / max(soft, 1.0 / self.s), 0, 1) * alpha
        if on is not None:
            names = [on] if isinstance(on, str) else on
            ids = [self._tags.get(n, -99) for n in names]
            w = w * np.isin(self.tag[sl], ids)
        w = w * (self.cov[sl] > 0.01)
        c = srgb_to_lin(hex_rgb(color))
        self.alb[sl] = self.alb[sl] * (1 - w[..., None]) + c * w[..., None]
        if gloss is not None:
            self.gloss[sl] = self.gloss[sl] * (1 - w) + gloss * w
        if depth:
            # 가장자리는 부드럽게, 안쪽은 평평하게 눌린 오목.
            t = np.clip(-d / max(depth * 1.2, 1e-3), 0, 1)
            press = depth * np.sqrt(np.clip(1 - (1 - t) ** 2, 0, 1))
            m = (d < 0) * (1.0 if on is None else np.isin(self.tag[sl], ids))
            self.Z[sl] = self.Z[sl] - press * m

    # ── 셰이딩 ──
    def render(self, shadow: float = 1.0, out_px: int | None = None, bg: str | None = None,
               shadow_color: str | None = None) -> Image.Image:
        s = self.s
        Z = self.Z
        # 법선: 높이 기울기(단위 동일). 가장자리 수직면은 자연히 어두워진다.
        gy, gx = np.gradient(Z, 1.0 / s)
        gx = np.clip(gx, -12, 12)
        gy = np.clip(gy, -12, 12)
        n = np.stack([-gx, -gy, np.ones_like(Z)], -1)
        n /= np.linalg.norm(n, axis=-1, keepdims=True)

        L = self.LIGHT_DIR / np.linalg.norm(self.LIGHT_DIR)
        ndl = n @ L
        wrap = 0.35
        diff = np.clip((ndl + wrap) / (1 + wrap), 0, 1)

        # 자기 그림자(높이맵 수평선 추적) — 머리카락이 이마에 드리우는 부드러운 그늘.
        sh = self._self_shadow(Z, L)
        diff = diff * (0.55 + 0.45 * sh)

        # 오목(캐비티) AO — 조각 이음새·입 안쪽을 부드럽게 어둡게.
        ao = self._cavity_ao(Z)

        # 반구 앰비언트: 위는 따뜻한 크림, 아래는 붉은 기 도는 그늘.
        up = np.clip(-n[..., 1] * 0.5 + 0.5, 0, 1)[..., None]
        sky = srgb_to_lin(hex_rgb("#FFF4EA"))
        gnd = srgb_to_lin(hex_rgb("#E6B8A8"))
        amb = (gnd * (1 - up) + sky * up) * 0.42

        key = srgb_to_lin(hex_rgb("#FFF6EE")) * 0.92
        alb = self.alb
        lit = alb * (amb + key * diff[..., None]) * ao[..., None]
        # 점토 속 산란 느낌: 그늘 쪽에 채도 높은 알베도² 를 조금 되돌린다.
        sss = alb * alb * (1 - diff[..., None]) * 0.38 * ao[..., None]
        lit = lit + sss
        # 부드러운 광택(넓은 블린 하이라이트) — 점토/무광 플라스틱.
        H = L + np.array([0, 0, 1], np.float32)
        H /= np.linalg.norm(H)
        spec = np.clip(n @ H, 0, 1)
        spec_soft = spec ** 14 * 0.55 + spec ** 60 * 0.9
        lit = lit + (self.gloss * spec_soft * sh)[..., None] * key
        # 가장자리 반사광(아주 약하게) — 배경 크림이 옆면에 비치는 결.
        rim = np.clip(1 - n[..., 2], 0, 1) ** 2.2
        lit = lit + rim[..., None] * srgb_to_lin(hex_rgb("#FFE9DC")) * 0.10

        rgb = lin_to_srgb(lit)
        a = self.cov

        # 바닥 그림자(우하단으로 번진 부드러운 그림자 + 접지 그림자).
        img_rgb = (rgb * 255 + 0.5).astype(np.uint8)
        obj = Image.fromarray(np.dstack([img_rgb, (a * 255 + 0.5).astype(np.uint8)]), "RGBA")
        out = Image.new("RGBA", obj.size, (0, 0, 0, 0))
        if shadow > 0:
            mask = Image.fromarray((a * 255).astype(np.uint8), "L")
            hmax = float(Z.max()) or 1.0
            sc = shadow_color or self.SHADOW_COLOR
            far = self._shadow_layer(mask, dx=2.2, dy=3.4, blur=4.2, alpha=0.30 * shadow, color=sc)
            near = self._shadow_layer(mask, dx=0.6, dy=1.0, blur=1.2, alpha=0.22 * shadow, color=sc)
            del hmax
            out = Image.alpha_composite(out, far)
            out = Image.alpha_composite(out, near)
        out = Image.alpha_composite(out, obj)
        if bg:
            base = Image.new("RGBA", out.size, bg)
            out = Image.alpha_composite(base, out)
        target = out_px or self.px // self.ss
        if target != self.px:
            out = out.convert("RGBa").resize((target, target), Image.LANCZOS).convert("RGBA")
        return out

    def _shadow_layer(self, mask: Image.Image, dx, dy, blur, alpha, color=None):
        s = self.s
        shifted = Image.new("L", mask.size, 0)
        shifted.paste(mask, (int(round(dx * s)), int(round(dy * s))))
        blurred = shifted.filter(ImageFilter.GaussianBlur(blur * s))
        a = (np.asarray(blurred, np.float32) / 255.0) * alpha
        col = (hex_rgb(color or self.SHADOW_COLOR) * 255).astype(np.uint8)
        arr = np.zeros((mask.size[1], mask.size[0], 4), np.uint8)
        arr[..., :3] = col
        arr[..., 3] = (a * 255 + 0.5).astype(np.uint8)
        return Image.fromarray(arr, "RGBA")

    def _self_shadow(self, Z, L):
        """광원 쪽으로 높이맵을 훑어 가려지는 정도(1=빛, 0=그늘)를 부드럽게."""
        s = self.s
        dx, dy = -L[0], -L[1]  # 빛을 향해 가는 방향(화면 좌표)
        norm = math.hypot(dx, dy)
        dx, dy = dx / norm, dy / norm
        tan_el = L[2] / math.hypot(L[0], L[1])
        occ = np.zeros_like(Z)
        steps = 18
        max_d = 9.0  # 단위
        for i in range(1, steps + 1):
            dist = max_d * (i / steps) ** 1.5
            ox, oy = int(round(-dx * dist * s)), int(round(-dy * dist * s))
            # 광원 방향 점의 높이를 현재 픽셀로 끌어온다.
            Zs = _shift(Z, ox, oy)
            rise = Zs - (Z + dist * tan_el)
            occ = np.maximum(occ, np.clip(rise / (0.6 + dist * 0.35), 0, 1))
        return 1 - occ

    def _cavity_ao(self, Z):
        s = self.s
        b1 = blur(Z, 1.6 * s)
        b2 = blur(Z, 5.0 * s)
        cav = np.clip((b1 - Z) * 0.22 + (b2 - Z) * 0.05, 0, 1)
        return 1 - 0.55 * cav


def _box1d(a, r, axis):
    """축 방향 박스 블러(누적합, 가장자리 복제)."""
    if r < 1:
        return a
    pad = [(0, 0), (0, 0)]
    pad[axis] = (r + 1, r)
    p = np.pad(a, pad, mode="edge")
    c = np.cumsum(p, axis=axis, dtype=np.float64)
    if axis == 0:
        out = (c[2 * r + 1:, :] - c[:-2 * r - 1, :]) / (2 * r + 1)
    else:
        out = (c[:, 2 * r + 1:] - c[:, :-2 * r - 1]) / (2 * r + 1)
    return out.astype(np.float32)


def blur(a, sigma):
    """박스 블러 3회 ≈ 가우시안(σ 픽셀)."""
    if sigma < 0.5:
        return a
    r = max(int(round(math.sqrt(12 * sigma * sigma / 3 + 1) / 2 - 0.5)), 1)
    out = a.astype(np.float32)
    for _ in range(3):
        out = _box1d(_box1d(out, r, 0), r, 1)
    return out


def _shift(a, ox, oy):
    """배열을 (ox, oy) 픽셀 끌어오기 — out[y,x] = a[y+oy, x+ox] (범위 밖은 0)."""
    out = np.zeros_like(a)
    h, w = a.shape
    ys0, ys1 = max(0, -oy), min(h, h - oy)
    xs0, xs1 = max(0, -ox), min(w, w - ox)
    if ys0 < ys1 and xs0 < xs1:
        out[ys0:ys1, xs0:xs1] = a[ys0 + oy:ys1 + oy, xs0 + ox:xs1 + ox]
    return out
