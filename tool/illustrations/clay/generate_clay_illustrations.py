#!/usr/bin/env python3
"""아가왜울어 클레이 일러스트 생성기 — DESIGN v3 "몽글 클레이" §4.

단일 소스: 이 파일의 장면 함수들(+ characters.py / props.py 부품, clay.py 엔진).

    python3 tool/illustrations/clay/generate_clay_illustrations.py            # 전부 렌더 + Dart 키 목록
    python3 tool/illustrations/clay/generate_clay_illustrations.py --only fever,burp --sheet /tmp/s.png
    python3 tool/illustrations/clay/generate_clay_illustrations.py --icons    # 앱 아이콘 + 네이티브 스플래시

출력
  assets/illustrations/symptoms/<key>.webp   증상 32종(768², 투명 + 바닥 그림자)
  assets/illustrations/scenes/<name>.webp    온보딩·스플래시·빈 상태 장면
  lib/presentation/widgets/symptom/symptom_illustration_data.dart   등록 키(생성)

구도 규칙: 뷰박스 120, 주인공은 가운데(≈60,60), 가장자리 8단위는 비워 둔다(우하단 바닥 그림자 자리).
그림 수정은 반드시 여기서 — 에셋·생성 Dart 직접 편집 금지.
"""
from __future__ import annotations

import argparse
import math
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

from PIL import Image  # noqa: E402

from clay import Clay, arc, capsule, circle, curve, ellipse, heart, moon, rbox  # noqa: E402
from characters import *  # noqa: E402,F403
from characters import _top  # noqa: E402
from props import *  # noqa: E402,F403

ROOT = HERE.parents[2]
SYMPTOM_DIR = ROOT / "assets/illustrations/symptoms"
SCENE_DIR = ROOT / "assets/illustrations/scenes"
DART_OUT = ROOT / "lib/presentation/widgets/symptom/symptom_illustration_data.dart"

OUT_PX = 768
SS = 2  # 슈퍼샘플


# ═════════════════════════════ 아기 돌봄 25 ═════════════════════════════

def s_tummy_pain(c):
    """배앓이 — 배를 감싸 쥔 아가 + 배 위 꼬르륵 소용돌이."""
    baby_body(c, 60, 64, 1.12, MINT, arms="belly")
    baby_head(c, 60, 42, 1.0, "squint", "wavy", brow="worry")
    swirl(c, 60, 87, 4.6, CORAL, turns=1.5, w=1.0)
    sparkle(c, 98, 70, 4.2, PINK_DEEP)
    sparkle(c, 22, 76, 3.2, BUTTER)


def s_teething(c):
    """이앓이 — 치발기를 앙 문 아가 + 침 방울."""
    baby_head(c, 56, 60, 1.18, "squint", "small", brow="worry")
    teether(c, 76, 84, 1.25)
    hand(c, 84, 95, 1.1)
    water_drop(c, 47, 88, 2.4, TEAR)
    sparkle(c, 98, 34, 4.5, BUTTER)


def s_newborn_rash(c):
    """태열 — 발그레 달아오른 얼굴 + 오돌토돌 점 + 열기."""
    baby_head(c, 58, 64, 1.22, "happy", "small")
    for sx in (-1, 1):
        c.paint(circle(58 + sx * 24, 74, 11), "#F59C92", soft=4, on="face", alpha=0.75)
        for (dx, dy) in ((-4, -3), (3, -5), (5, 3), (-3, 4), (0, 0)):
            c.blob(circle(58 + sx * 24 + dx, 74 + dy, 1.05), "#EE7F7A", bevel=1.05, height=0.9, gloss=0.3)
    wave_lines(c, 60, 22, 10, CORAL, n=3, gap=7, amp=1.3, r=1.15)
    sparkle(c, 100, 38, 4, PINK_DEEP)


def s_stool_color(c):
    """변 색깔 — 기저귀 + 색 견본 세 알."""
    diaper(c, 60, 74, 1.45, WHITE, SKY, PINK_DEEP)
    swatch(c, 30, 30, 8, "#E8B84A")
    swatch(c, 60, 22, 8, "#8DB36A")
    swatch(c, 90, 30, 8, "#A7704E")
    sparkle(c, 102, 60, 3.6, BUTTER)


def s_burp(c):
    """트림 — 등을 토닥토닥 + 보글보글 트림 방울."""
    baby_body(c, 54, 68, 1.05, BUTTER, arms="down")
    baby_head(c, 54, 47, 0.95, "happy", "o")
    open_hand(c, 88, 74, 1.05, deg=-28)
    for k in range(3):
        a = math.radians(200 + k * 28)
        x0, y0 = 88 + 18 * math.cos(a), 70 + 18 * math.sin(a)
        x1, y1 = 88 + 23 * math.cos(a), 70 + 23 * math.sin(a)
        c.blob(capsule(x0, y0, x1, y1, 1.1), PINK_DEEP, bevel=1.1, height=1.2, mode="max", lift=_top(c, x0, y0), gloss=0.2)
    bubbles(c, [(80, 30, 5.2), (94, 18, 3.4), (70, 18, 2.6)])


def s_spit_up(c):
    """게워냄 — 입가에 맺힌 우유 방울 + 턱받이에 톡 떨어진 우유."""
    baby_body(c, 60, 66, 1.08, SKY, arms="down")
    bib(c, 60, 66, 1.1, PINK)
    baby_head(c, 60, 44, 1.0, "dot", "o", brow="worry")
    c.blob(ellipse(64, 78, 6.5, 3.8), MILK, bevel=3, height=2.2, mode="max", lift=_top(c, 64, 78) + 0.3, k=0.6, gloss=0.6)
    water_drop(c, 65.5, 61, 1.9, MILK)
    water_drop(c, 78, 90, 2.4, MILK)
    sparkle(c, 98, 36, 4, BUTTER)


def s_runny_nose(c):
    """콧물 — 훌쩍이는 아가 + 휴지 상자."""
    baby_head(c, 50, 54, 1.08, "tired", "small", brow="worry")
    c.blob(capsule(50, 62, 51, 69, 1.6, 2.2), TEAR, bevel=1.8, height=2.0, mode="max", lift=_top(c, 50, 64) + 0.6, gloss=0.95)
    tissue_box(c, 88, 92, 1.1)
    sparkle(c, 98, 34, 4, SKY_DEEP)


def s_fever(c):
    """열 — 이마 해열 시트 + 체온계 + 열기."""
    baby_head(c, 56, 64, 1.2, "tired", "small", brow="worry")
    c.paint(ellipse(56, 46, 22, 8), "#F29B8F", soft=4, on="face", alpha=0.5)
    top = _top(c, 56, 46)
    c.blob(rbox(56, 45, 26, 10, 4.5, deg=-4), "#CFEFE3", bevel=2.4, height=2.2, mode="max", lift=top, k=1.0, gloss=0.5, tag="patch")
    c.paint(rbox(56, 45, 20, 5, 2.4, deg=-4), "#E8F8F1", soft=0.4, on="patch")
    thermometer(c, 102, 70, 88, 94, 1.0)
    wave_lines(c, 22, 30, 10, CORAL, n=3, gap=6, amp=1.2, r=1.1)


def s_rash(c):
    """발진 — 배를 드러낸 아가 + 오돌토돌 붉은 점 + 돋보기."""
    baby_body(c, 54, 66, 1.08, SKIN, arms="down", skin=SKIN)
    diaper(c, 54, 99, 0.62, WHITE, SKY, PINK_DEEP)
    for (dx, dy) in ((-7, 76), (4, 72), (9, 82), (-3, 86), (-11, 84), (2, 79)):
        c.blob(circle(54 + dx, dy, 1.25), "#EE7F7A", bevel=1.25, height=1.0, gloss=0.3)
    baby_head(c, 54, 44, 1.0, "dot", "small", brow="worry")
    magnifier(c, 94, 60, 1.05, deg=50)


def s_sleep_moon(c):
    """수면퇴행 — 초승달 요람에 앉아 눈이 말똥말똥한 밤."""
    c.blob(moon(52, 60, 42, bite=0.8, off=(0.5, -0.32)), BUTTER, bevel=15, height=12, gloss=0.2, tag="moon")
    c.paint(circle(26, 70, 3), HONEY, soft=1, on="moon", alpha=0.5)
    c.paint(circle(36, 90, 2.2), HONEY, soft=1, on="moon", alpha=0.5)
    baby_head(c, 76, 62, 0.74, "wide", "o")
    star_blob(c, 100, 22, 6.2, BUTTER)
    star_blob(c, 106, 46, 3.8, LILAC_DEEP)
    sparkle(c, 60, 14, 3.8, LILAC)


def s_constipation(c):
    """변비 — 끙끙 힘주는 아가 + 땀방울 + 힘줄 표시."""
    baby_body(c, 60, 66, 1.1, PEACH, arms="belly")
    baby_head(c, 60, 44, 1.0, "squint", "wavy", brow="angry")
    c.paint(circle(60, 52, 14), "#F4A094", soft=5, on="face", alpha=0.45)
    water_drop(c, 94, 36, 3.2, TEAR, deg=15)
    for sx in (-1, 1):
        for k in range(3):
            a = math.radians(-90 + sx * (50 + k * 22))
            x0, y0 = 60 + 44 * math.cos(a), 44 + 40 * math.sin(a)
            x1, y1 = 60 + 51 * math.cos(a), 44 + 47 * math.sin(a)
            c.blob(capsule(x0, y0, x1, y1, 1.2), CORAL, bevel=1.2, height=1.3, mode="max", lift=_top(c, x0, y0), gloss=0.2)


def s_diarrhea(c):
    """설사 — 물기 튄 기저귀 + 수분 보충 물컵."""
    diaper(c, 50, 72, 1.35, WHITE, MINT_DEEP, PINK_DEEP)
    for (x, y, r, d) in ((28, 40, 3.4, -25), (46, 30, 2.6, -8), (70, 34, 3.0, 12)):
        water_drop(c, x, y, r, TEAR, deg=d)
    water_glass(c, 94, 82, 1.0)
    sparkle(c, 98, 46, 3.8, SKY_DEEP)


def s_hiccup(c):
    """딸꾹질 — 깜짝 놀란 아가 + 말풍선 느낌표."""
    baby_head(c, 50, 68, 1.12, "wide", "o")
    speech_bubble(c, 92, 34, 30, 24, WHITE, tail="left")
    exclaim(c, 92, 33, 16, CORAL)
    bubbles(c, [(24, 34, 4.2), (16, 48, 2.6)])


def s_prickly_heat(c):
    """땀띠 — 송골송골 땀 + 시원한 선풍기."""
    baby_head(c, 50, 62, 1.1, "happy", "small")
    for (dx, dy) in ((-18, 70), (-12, 76), (14, 72), (19, 78)):
        c.blob(circle(50 + dx, dy, 1.1), "#EE8F86", bevel=1.1, height=0.9, gloss=0.3)
    water_drop(c, 22, 40, 3.2, TEAR, deg=-15)
    water_drop(c, 78, 30, 2.6, TEAR, deg=15)
    fan(c, 96, 76, 0.95)


def s_jaundice(c):
    """황달 — 노르스름한 아가 + 햇님."""
    baby_head(c, 54, 68, 1.12, "happy", "small", skin=YELLOW_SKIN)
    sun(c, 94, 28, 11)
    sparkle(c, 20, 32, 4, HONEY)


def s_eye_care(c):
    """눈곱·눈물 — 한쪽 눈을 찡긋, 눈물 한 방울 + 솜."""
    baby_head(c, 54, 60, 1.15, "wink", "small")
    water_drop(c, 54 + 23, 67, 3.0, TEAR, deg=-10)
    cotton_ball(c, 94, 94, 10)
    sparkle(c, 100, 32, 4, SKY_DEEP)


def s_thrush(c):
    """아구창 — 아~ 벌린 입 속 하얀 반점."""
    baby_head(c, 60, 60, 1.25, "happy", "wail")
    for (dx, dy, r) in ((-2.4, 81.2, 0.9), (2.2, 80.6, 0.75), (0.2, 83.4, 0.7)):
        c.paint(circle(60 + dx, dy, r), WHITE, soft=0.25, on="face")
    c.paint(circle(56.6, 76.4, 0.8), WHITE, soft=0.25, on="face")
    c.paint(circle(63.4, 76.0, 0.7), WHITE, soft=0.25, on="face")
    sparkle(c, 100, 30, 4.5, BUTTER)
    sparkle(c, 18, 90, 3.2, PINK_DEEP)


def s_umbilical(c):
    """배꼽 — 배를 드러낸 아가, 동그란 배꼽 + 면봉 + 반짝."""
    baby_body(c, 52, 66, 1.12, SKIN, arms="up", skin=SKIN)
    diaper(c, 52, 100, 0.64, WHITE, SKY, PINK_DEEP)
    c.paint(circle(52, 85, 3.0), "#E4A695", soft=1.0, on="body", depth=1.4)
    baby_head(c, 52, 44, 1.0, "happy", "open")
    top = _top(c, 96, 60)
    c.blob(capsule(88, 74, 104, 50, 1.5), WHITE, bevel=1.5, height=1.8, mode="max", lift=top + 1, gloss=0.3)
    cotton_ball(c, 88, 74, 4.2)
    cotton_ball(c, 104, 50, 4.2)
    sparkle(c, 70, 84, 3.4, BUTTER)
    sparkle(c, 100, 28, 4.2, BUTTER)


def s_birthmark(c):
    """반점·각질 — 이마의 옅은 분홍 반점 + 로션."""
    baby_head(c, 52, 62, 1.12, "happy", "open")
    c.paint(ellipse(52, 44, 7, 4, deg=8), "#F2A2A8", soft=2.2, on="face", alpha=0.75)
    c.paint(ellipse(66, 56, 3.4, 2.2), "#F2A2A8", soft=1.4, on="face", alpha=0.6)
    lotion(c, 96, 84, 0.95)
    sparkle(c, 98, 34, 4, PINK_DEEP)


def s_hormonal(c):
    """가성생리·멍울 — 포대기 속 새근새근 신생아 + 하트."""
    swaddle(c, 60, 78, 1.0, PINK, WHITE)
    baby_head(c, 60, 44, 0.9, "sleep", "small")
    heart_blob(c, 98, 36, 6, PINK_DEEP)
    heart_blob(c, 22, 52, 4.2, LILAC_DEEP, deg=-12)
    sparkle(c, 96, 86, 3.8, BUTTER)


def s_dimple(c):
    """엉덩이 딤플 — 뒤돌아 앉은 아가, 꼬리뼈 위 보조개."""
    body = ellipse(60, 84, 25, 21)
    c.blob(body, SKIN, bevel=16, height=13, tag="face", gloss=0.12)
    for sx in (-1, 1):
        c.blob(capsule(60 + sx * 22, 74, 60 + sx * 26, 88, 5.0), SKIN, bevel=5, height=5, tag="face")
    c.blob(rbox(60, 99, 52, 18, 9) & body.dilate(2), WHITE, bevel=4.5, height=4.5, gloss=0.15, tag="diaperback")
    c.paint(capsule(37, 91, 83, 91, 1.2), MINT_DEEP, soft=0.3, on="diaperback")
    c.paint(circle(60, 86.5, 1.7), "#E2A392", soft=0.6, on="face", depth=0.8)
    back_head(c, 60, 48, 0.98)
    sparkle(c, 70, 80, 3.2, BUTTER)
    heart_blob(c, 100, 36, 4.6, PINK_DEEP)


def s_tongue_tie(c):
    """설소대 — 메롱 내민 혀(가운데 홈)."""
    baby_head(c, 60, 58, 1.2, "happy", "small")
    top = _top(c, 60, 74)
    c.blob(ellipse(60, 77.5, 5.4, 6.2), "#F59A98", bevel=4, height=3.2, mode="max", lift=top, k=0.8, gloss=0.35, tag="tongue")
    c.paint(capsule(60, 73.5, 60, 78.5, 0.5), "#E2777C", soft=0.4, on="tongue")
    sparkle(c, 98, 30, 4.4, BUTTER)
    heart_blob(c, 22, 88, 4.0, PINK_DEEP)


def s_vaccine(c):
    """예방접종 — 하트 밴드 붙인 팔 + 장난감 주사기 + 별 칭찬."""
    baby_body(c, 52, 66, 1.08, LILAC, arms="up")
    baby_head(c, 52, 44, 1.0, "happy", "open")
    bandaid_round(c, 70.5, 64.5, 4.2)
    syringe(c, 96, 90, 0.92, deg=-35)
    star_blob(c, 98, 36, 6.2, BUTTER)


def s_formula(c):
    """분유 타기 — 젖병 + 분유통 + 스푼."""
    formula_can(c, 86, 70, 1.05)
    bottle(c, 42, 64, 1.3, SKY, PINK, deg=-8)
    scoop(c, 80, 100, 0.95)
    wave_lines(c, 42, 20, 8, CORAL, n=2, gap=6, amp=1.0, r=1.0)
    sparkle(c, 104, 36, 4, BUTTER)


def s_milk_storage(c):
    """모유 보관 — 모유팩 + 눈꽃 + 얼음."""
    milk_bag(c, 50, 64, 1.3)
    snowflake(c, 96, 34, 9)
    c.blob(rbox(96, 88, 16, 16, 5, deg=12), "#DCEEFB", bevel=4.5, height=5, mode="max", lift=_top(c, 96, 88), k=0.8, gloss=0.85)
    sparkle(c, 18, 30, 3.6, SKY_DEEP)


# ═════════════════════════════ 엄마 돌봄 7 ═════════════════════════════

def s_lochia(c):
    """오로 — 활짝 핀 꽃 한 송이 + 점점 옅어지며 지는 꽃잎."""
    for i in range(5):
        a = -90 + i * 72
        px = 48 + 11 * math.cos(math.radians(a))
        py = 52 + 11 * math.sin(math.radians(a))
        c.blob(ellipse(px, py, 9, 12, deg=a + 90), "#F4A9B8", bevel=6, height=5.5, mode="max", lift=0, k=1.5, gloss=0.2, tag="flower")
    c.blob(circle(48, 52, 6.5), BUTTER, bevel=5, height=6, mode="max", lift=3, k=1, gloss=0.3)
    petal(c, 84, 78, 1.0, deg=30, color="#F7C3CE")
    petal(c, 98, 100, 0.85, deg=55, color="#FBDDE3")
    heart_blob(c, 96, 34, 4.6, LILAC_DEEP)
    sparkle(c, 22, 92, 4, BUTTER)


def s_baby_blues(c):
    """산후 우울감 — 엄마 + 비구름, 뒤에서 빼꼼 해님(혼자가 아니에요)."""
    sun(c, 100, 22, 8.5)
    cloud_blob(c, 84, 32, 40, 22, "#EFE8FA", lift=4)
    for x in (74, 84, 94):
        water_drop(c, x, 54, 2.0, TEAR)
    mom_head(c, 44, 74, 0.92, "tired", "small", brow="worry")
    heart_blob(c, 14, 34, 3.8, PINK_DEEP)


def s_engorgement(c):
    """젖몸살 — 하트 온찜질팩 + 양배추 잎 + 눈꽃."""
    cabbage_leaf(c, 44, 70, 1.35, deg=-15)
    gel_pack(c, 76, 58, 1.1)
    snowflake(c, 98, 94, 7, SKY_DEEP)
    wave_lines(c, 76, 30, 8, CORAL, n=3, gap=6, amp=1.0, r=1.0)


def s_nipple_care(c):
    """유두 통증 — 연고 튜브 + 수유패드 두 장."""
    nursing_pad(c, 38, 82, 14)
    nursing_pad(c, 64, 94, 11)
    tube(c, 80, 48, 1.25, deg=-32, body=LILAC, cap=WHITE, label=WHITE)
    sparkle(c, 24, 40, 4.4, PINK_DEEP)


def s_breastfeeding(c):
    """모유수유 — 엄마 품에 안긴 아가."""
    mom_head(c, 58, 44, 0.85, "happy", "smile")
    body = ellipse(58, 96, 34, 18)
    c.blob(body, LILAC, bevel=14, height=10, gloss=0.12, tag="momtop")
    baby_head(c, 44, 86, 0.62, "sleep", "small")
    c.blob(ellipse(72, 92, 12, 9), PINK, bevel=7, height=7, mode="max", lift=_top(c, 72, 92), k=1.5, gloss=0.15)
    hand(c, 78, 86, 1.1, SKIN_MOM)
    heart_blob(c, 98, 30, 5.2, PINK_DEEP)
    heart_blob(c, 20, 40, 3.6, PINK)


def s_milk_supply(c):
    """모유량 — 눈금 젖병 반쯤 + 물음표."""
    bottle(c, 48, 68, 1.35, PINK, LILAC, level=0.42)
    question(c, 94, 40, 26, LILAC_DEEP)
    water_drop(c, 92, 86, 3.6, MILK)
    sparkle(c, 16, 36, 3.6, BUTTER)


def s_recovery(c):
    """산후 회복 — 김 오르는 찻잔 + 새싹 화분."""
    sprout_pot(c, 84, 78, 1.1)
    cup(c, 42, 80, 1.2, PINK, HONEY, steam=False)
    wave_lines(c, 42, 60, 12, LILAC_DEEP, n=2, gap=7, amp=1.3, r=1.2)
    heart_blob(c, 98, 34, 4.6, PINK_DEEP)
    sparkle(c, 22, 36, 4, BUTTER)


SYMPTOMS = {
    "tummy_pain": s_tummy_pain, "teething": s_teething, "newborn_rash": s_newborn_rash,
    "stool_color": s_stool_color, "burp": s_burp, "spit_up": s_spit_up,
    "runny_nose": s_runny_nose, "fever": s_fever, "rash": s_rash, "sleep_moon": s_sleep_moon,
    "constipation": s_constipation, "diarrhea": s_diarrhea, "hiccup": s_hiccup,
    "prickly_heat": s_prickly_heat, "jaundice": s_jaundice, "eye_care": s_eye_care,
    "thrush": s_thrush, "umbilical": s_umbilical, "birthmark": s_birthmark,
    "hormonal": s_hormonal, "dimple": s_dimple, "tongue_tie": s_tongue_tie,
    "vaccine": s_vaccine, "formula": s_formula, "milk_storage": s_milk_storage,
    "lochia": s_lochia, "baby_blues": s_baby_blues, "engorgement": s_engorgement,
    "nipple_care": s_nipple_care, "breastfeeding": s_breastfeeding,
    "milk_supply": s_milk_supply, "recovery": s_recovery,
}


# ═════════════════════════════ 앱 장면 ═════════════════════════════

# 스플래시·아이콘 얼굴: 머리 박스(귀 끝~귀 끝 = 72·s)가 이미지 폭의 78%를 차지하도록.
FACE_S = 120 * 0.78 / 72  # ≈ 1.30
FACE_C = (60, 64)


def sc_baby_cry(c):
    # 눈물은 보는 쪽 왼뺨 한 방울만 굽는다 — 오른뺨 눈물은 스플래시(`SplashMark`)가
    # 벡터로 맺혔다 흘러내리게 그린다(이미지 박스 기준 (0.70, 0.57)에서 출발).
    baby_head(c, *FACE_C, FACE_S, "cry", "wail", tears=True, tear_sides=(-1,))


def sc_baby_smile(c):
    baby_head(c, *FACE_C, FACE_S, "happy", "open")


def sc_onboarding_cry(c):
    baby_body(c, 60, 70, 1.12, PINK, arms="up")
    baby_head(c, 60, 46, 1.08, "cry", "wail", tears=2)
    sparkle(c, 16, 30, 4, BUTTER)
    heart_blob(c, 104, 28, 4.4, PINK_DEEP)


def sc_onboarding_care(c):
    bottle(c, 40, 42, 0.9, SKY, PINK, deg=-14)
    pacifier(c, 76, 36, 1.0, PINK_DEEP, BUTTER, deg=10)
    tube(c, 92, 50, 0.72, deg=24, body=MINT, cap=WHITE)
    diaper_bag(c, 60, 78, 1.0)
    sparkle(c, 14, 70, 4, BUTTER)


def sc_onboarding_sleep(c):
    cloud_blob(c, 60, 86, 96, 40, WHITE)
    baby_head(c, 52, 64, 0.95, "sleep", "small")
    c.blob(ellipse(80, 76, 16, 10), LILAC, bevel=8, height=7, mode="max", lift=_top(c, 80, 78), k=2, gloss=0.12)
    c.blob(moon(96, 26, 12, bite=0.78, off=(0.5, -0.3)), BUTTER, bevel=6, height=5, mode="max", lift=0, gloss=0.2)
    star_blob(c, 22, 26, 5.2, BUTTER)
    z_letter(c, 78, 40, 8)
    z_letter(c, 88, 52, 5.5)


def sc_empty_search(c):
    baby_body(c, 52, 68, 1.05, BUTTER, arms="down")
    baby_head(c, 52, 46, 1.0, "wide", "small")
    magnifier(c, 90, 72, 1.3, deg=45)
    sparkle(c, 100, 30, 4, PINK_DEEP)


def sc_empty_heart(c):
    heart_blob(c, 60, 84, 22, PINK_DEEP, lift=0)
    baby_head(c, 60, 46, 1.0, "happy", "open")
    hand(c, 44, 78, 1.1)
    hand(c, 76, 78, 1.1)
    sparkle(c, 100, 30, 4, BUTTER)


def sc_oops(c):
    baby_head(c, 64, 54, 1.0, "dot", "o", brow="worry")
    cloud_blob(c, 60, 86, 90, 38, WHITE)
    water_drop(c, 96, 30, 3, TEAR, deg=15)
    sparkle(c, 20, 30, 4, LILAC_DEEP)


def sc_mom_and_baby(c):
    mom_head(c, 42, 60, 0.9, "happy", "smile")
    baby_head(c, 84, 74, 0.72, "happy", "open")
    heart_blob(c, 70, 24, 5, PINK_DEEP)
    sparkle(c, 102, 36, 3.6, BUTTER)


# 딸기 핑크 배지(스플래시·아이콘) 위에 놓이는 얼굴은 그림자를 장밋빛으로 — 갈색 그림자가
# 분홍 바탕에서 탁하게 보이지 않게.
BADGE_SHADOW = "#B24B69"
SHADOW_OF = {"baby_cry": BADGE_SHADOW, "baby_smile": BADGE_SHADOW}

SCENES = {
    "baby_cry": sc_baby_cry, "baby_smile": sc_baby_smile,
    "onboarding_cry": sc_onboarding_cry, "onboarding_care": sc_onboarding_care,
    "onboarding_sleep": sc_onboarding_sleep, "empty_search": sc_empty_search,
    "empty_heart": sc_empty_heart, "oops": sc_oops, "mom_and_baby": sc_mom_and_baby,
}


# ═════════════════════════════ 출력 ═════════════════════════════

# 배지 얼굴은 핑크 원 위에서 그림자가 번져 보이지 않게 옅게.
SHADOW_STRENGTH = {"baby_cry": 0.55, "baby_smile": 0.55}


def render(fn, px=OUT_PX, shadow=1.0, shadow_color=None) -> Image.Image:
    c = Clay(px=px * SS, ss=SS)
    fn(c)
    return c.render(shadow=shadow, shadow_color=shadow_color)


def save_webp(img: Image.Image, path: pathlib.Path):
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, "WEBP", quality=90, alpha_quality=95, method=6)


def contact_sheet(items, out, cols=6, tile=320, bg="#FFF6EF"):
    rows = (len(items) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * tile, rows * tile), bg)
    for i, (_, img) in enumerate(items):
        sheet.alpha_composite(img.resize((tile, tile), Image.LANCZOS), ((i % cols) * tile, (i // cols) * tile))
    sheet.convert("RGB").save(out)


def dart_file(keys) -> str:
    lines = [
        "// GENERATED CODE — 직접 수정 금지.",
        "//",
        "// 원본: tool/illustrations/clay/generate_clay_illustrations.py",
        "// 재생성: python3 tool/illustrations/clay/generate_clay_illustrations.py",
        "//",
        "// 클레이 일러스트가 렌더된 증상 키(`emoji_or_icon`) 목록. 에셋은",
        "// assets/illustrations/symptoms/<key>.webp.",
        "",
        "/// 일러스트가 등록된 증상 키.",
        "const Set<String> symptomIllustrationKeys = <String>{",
    ]
    lines += [f"  '{k}'," for k in keys]
    lines += ["};", ""]
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", help="쉼표로 구분한 키(증상·장면)만")
    ap.add_argument("--sheet", help="컨택트 시트 PNG 경로(에셋은 쓰지 않음)")
    ap.add_argument("--px", type=int, default=OUT_PX)
    ap.add_argument("--icons", action="store_true", help="앱 아이콘·네이티브 스플래시 생성")
    args = ap.parse_args()

    if args.icons:
        import make_icons  # noqa: WPS433 — 아이콘은 별도 모듈
        make_icons.main()
        return

    table = {**SYMPTOMS, **SCENES}
    keys = list(table) if not args.only else [k.strip() for k in args.only.split(",")]
    items = []
    for k in keys:
        img = render(table[k], px=args.px if args.sheet else OUT_PX, shadow=SHADOW_STRENGTH.get(k, 1.0),
                     shadow_color=SHADOW_OF.get(k))
        items.append((k, img))
        if not args.sheet:
            out = (SYMPTOM_DIR if k in SYMPTOMS else SCENE_DIR) / f"{k}.webp"
            save_webp(img, out)
            print("wrote", out.relative_to(ROOT))
    if args.sheet:
        contact_sheet(items, args.sheet)
        print("sheet", args.sheet)
    if not args.only and not args.sheet:
        DART_OUT.write_text(dart_file(list(SYMPTOMS)), encoding="utf-8")
        print("wrote", DART_OUT.relative_to(ROOT))


if __name__ == "__main__":
    main()
