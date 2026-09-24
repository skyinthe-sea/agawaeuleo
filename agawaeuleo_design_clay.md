# 아가왜울어 — 몽글 클레이 디자인 설계서 (DESIGN v3 "몽글 클레이")

> 작성: 2026-09-24. 발주자 요구: **"남녀노소 대중적인 분위기 → 초보맘을 위한 여성스럽고 아기자기한
> 일러스트 + UI/UX로 대개편. 레퍼런스(3D 캐릭터 얼굴 세트 — 말랑한 점토 질감, 볼터치, 점 눈,
> 반달 입) 스타일로 일러스트 전부 교체. 2026 트렌드의 아기자기한 연출. 현재 애니메이션은 유지."**

---

## 0. 문서 지위 · 적용 규칙

- 이 문서는 **DESIGN v2(`agawaeuleo_design_premium.md`)의 시각 레이어를 대체**한다. 색·서체·모서리·음영·
  일러스트·컴포넌트 외형은 이 문서가 우선이다. **모션 계약(v2 §7.x의 타이밍·ScrollReveal·패럴랙스·
  RevealGate·덱/노트 메커니즘·스플래시 비트)은 그대로 유효** — 모양만 바꾸고 움직임은 살린다.
- 기능·데이터·법적 문구·아키텍처는 여전히 스펙(`agawaeuleo_spec.md`)이 우선.
- **불변 조항**: §13.2 대가성 문구·§13.3 의학 면책 문구 **원문 그대로**, 쿠팡 링크
  `LaunchMode.externalApplication`, 터치타깃 최소 48dp, WCAG AA(본문 4.5:1), reduce-motion 대체,
  순수 흑/백 금지, 레이어 규칙, 색·크기·모션 하드코딩 금지(토큰 경유), 카피(문구) 임의 변경 금지.
- **v2에서 풀린 조항**: "그라데이션 금지" → **클레이 광택(§5.0)에 한해 허용**. 무지개·다색 그라데이션은 여전히 금지.

## 1. 무드 — "몽글 클레이" 4원칙

1. **말랑(Squishy)** — 모든 표면이 손으로 빚은 점토처럼 둥글고 폭신하다. 모서리 한 단계 더 둥글게,
   면 구분은 헤어라인보다 **부드럽게 퍼지는 장밋빛 그림자**로. 누르면 살짝 눌린다(`TapSpring`).
2. **몽글(Pastel sorbet)** — 딸기우유 크림 바탕 위에 **한 화면당 파스텔 1~2색**. 카테고리 톤:
   딸기(accent) / 토마토(coral — 응급 전용) / 민트(sage) / 버터(amber) / 라일락(lilac — 엄마 돌봄).
3. **아기자기(Cute details)** — 주인공은 **클레이 일러스트**. 장식은 작은 하트·별·반짝이·구름·물방울
   스티커를 **드물게**. 먹·붓·낙관 같은 수묵 은유(먹선 틱, 붓결, 모노 숫자 `01`)는 걷어낸다.
4. **포근(Warm)** — 글자는 코코아 브라운, 제목은 통통한 **주아체**. 과한 채도·검정·날카로운 각 금지.

## 2. 2026 트렌드 참조(적용 범위)

- **소프트 3D / 클레이모피즘**: 일러스트(렌더 에셋)와 버튼·칩의 은은한 윗면 광택까지만. 카드 전체를 입체로 만들지 않는다.
- **젤리 버튼(알약)**: 모든 주요 버튼·칩·세그먼트는 알약(Stadium).
- **스티커 UI**: 배지·라벨은 흰 테두리가 도는 스티커 칩(§5.4).
- **벤토 느낌의 둥근 카드 묶음**: 설정·내 정보는 큰 라운드 카드 안에 행을 담는다.

## 3. 토큰 (`lib/config/theme/`)

토큰 **이름**은 v2에서 물려받는다(`paper*` = 표면, `ink*` = 텍스트, `seal` = 브랜드 핑크) — 소비처 수백
곳을 흔들지 않기 위해서다. 값만 아래로 바뀌었다.

### 3.1 컬러 (`app_colors.dart`)

| 토큰 | 의미(v3) | Light | Dark |
|---|---|---|---|
| `paperBg` | 화면 바탕 — 딸기우유 크림 | `#FFF6EF` | `#221A19` |
| `paperCard` | 카드 | `#FFFBF8` | `#2B2221` |
| `paperRaised` | 떠 있는 면·시트·버튼 글자 | `#FFFDFB` | `#342A28` |
| `paperStack` | 겹친 아랫장·트랙 | `#F9E9E0` | `#1D1615` |
| `ink900` | 본문 코코아 | `#4A3531` | `#F7EAE4` |
| `ink700` | 보조 본문 | `#6B524D` | `#D8C6BF` |
| `ink500` | 캡션(바탕 5.3:1 · 워시 4.7:1) | `#7B6159` | `#A8948C` |
| `ink300` | 힌트·비활성 | `#C9B3AB` | `#75625C` |
| `line` / `lineStrong` | 구분선 | `#F4E3DA` / `#EAD0C4` | `#3A2F2D` / `#4A3D3A` |
| `accent` | 브랜드 로즈(글자·버튼 면) | `#B53E5D` | `#F291A8` |
| `accentWash` / `accentDeep` | 딸기 워시 / 눌림 | `#FDE4EA` / `#9E3452` | `#45272F` / `#F7B3C3` |
| `accentFill` **신규** | **채운 알약 면 전용** 딸기 핑크(주 버튼·탭바 알약·"자세히 보기"·쿠팡 CTA·스위치) | `#D9557A` | `#F291A8` |
| `coral` / `coralWash` | **응급·오류 전용** 토마토 | `#BA3C27` / `#FDE6DE` | `#F28C73` / `#43261F` |
| `sage` / `sageWash` | 민트(소화·수유) | `#28775E` / `#DDF3EA` | `#86D0B4` / `#1F3A31` |
| `amber` / `amberWash` | 버터·꿀(수면·정서·BEST) | `#965E0A` / `#FFF0CC` | `#EDC06A` / `#3F3220` |
| `seal` / `sealWash` | 브랜드 딸기 핑크(면·장식 전용, 글자 금지) | `#F28DA2` / `#FDE8EC` | `#F28DA2` / `#45272F` |
| `lilac` / `lilacWash` **신규** | 엄마 돌봄 톤 | `#7152BE` / `#EEE7FB` | `#BCA6F0` / `#2F2742` |

- 파스텔 **wash**는 면, 진한 **fg**는 글자·아이콘. **wash 위 fg 글자 4.6~4.8:1, 크림 바탕 위 4.9~5.4:1**(2026-09-24 실측 — 첫 값은 4.0~4.2라 한 단계 진하게 보정).
- 엄마 돌봄(audience=mom) 강조는 lilac, 아기 돌봄은 accent(딸기).
- **accentFill 큰 글씨 규칙**: accentFill 면 위 크림 글자는 3.7:1이라 **주아체 19 이상(`texts.heading`) = WCAG 큰 텍스트**로만 얹는다.
  작은 글자가 필요한 알약(장 탭·세그먼트 등)은 채운 톤 면 대신 **크림(paperRaised) 젤리 알약 + 톤 글자**(4.5:1+)로 만든다.
  accent(`#B53E5D`)는 글자·링크·작은 강조용 — 실기기에서 면으로 쓰면 탁한 라즈베리로 무거워 보여 면 전용 accentFill을 분리했다(2026-09-24 시안 비교).

### 3.2 음영 (`app_shadows.dart`)
Light는 로즈브라운 `rgba(150,96,84,α)`로 **넓고 부드럽게**: e1 `0 1 3 .07 + 0 4 12 .07`, e2 `0 6 18 .10 + 0 1 4 .06`,
e3 `0 16 36 .15 + 0 3 8 .07`, e4 `0 10 26 .16`. Dark는 v2 유지.
- **톤 그림자**: 채운 알약 버튼(accent 면 등)은 e2 대신 자기 색 그림자 `fg α.28, (0,6), blur 16`을 써도 된다(소비처에서 `withValues`로 — 토큰 색 기반이므로 하드코딩 아님).

### 3.3 서체 (`app_typography.dart`)
- `displayL 34 / display 28 / title 22 / heading 19` → **주아체(Jua, OFL)**. 한 가지 굵기 — `fontWeight`를
  바꾸지 말 것(가짜 볼드가 생긴다). 가운뎃점(·)은 `displayFallback`(Pretendard)이 받는다.
- `bodyL / body / label / caption / overline` → Pretendard(유지).
- 숫자 강조(순번·개수)는 모노(`JetBrainsMono`) 대신 **주아체 숫자**를 쓴다(`AppFontFamily.display`).
- NotoSerifKR(명조)는 제거됐다.

### 3.4 모서리 (`app_radius.dart`)
`xs 8 · sm 14 · md 20 · lg 26 · xl 34 · full`. 카드 = lg, 시트 윗변·다이얼로그 = xl, 입력 = md, 버튼·칩·탭 = full.

### 3.5 질감
종이 그레인은 **무광 점토 결**로 세기만 낮춰 유지(`opacity .03/.035`).

## 4. 일러스트 — 클레이 파이프라인

- **엔진**: `tool/illustrations/clay/clay.py`(2.5D 높이맵 점토 렌더러 — 조각의 2D SDF 윤곽 + 둥근 단면 →
  법선 → 좌상단 키라이트·반구 앰비언트·오목 AO·자기 그림자·점토 산란·부드러운 광택 + 우하단 바닥 그림자).
- **부품**: `characters.py` — 주인공 **아가**(큰 호빵 머리 + 귀 + 정수리 **배냇머리 한 가닥**(브랜드 모티프) +
  점 눈 · 볼터치 · 코 방울 · 표정별 입) · **엄마**(초콜릿 똥머리 + 핑크 핀) · 몸통 · 소품(젖병·체온계·쪽쪽이·
  기저귀·튜브·밴드·컵·구름·달·별·하트·물방울·반짝이…).
- **생성기**: `generate_clay_illustrations.py` → `assets/illustrations/symptoms/<key>.webp`(32종, 768²,
  투명 + 바닥 그림자) · `assets/illustrations/scenes/*.webp` · 앱 아이콘/네이티브 스플래시 PNG ·
  `symptom_illustration_data.dart`(등록 키). **수정은 생성기에서만**, 에셋·생성 파일 직접 편집 금지.
- **위젯**: `SymptomIllustration(illustrationKey:, size:)`, `ClayIllustration(asset:, size:)`, 경로 상수 `ClayScenes.*`.
  PNG에 색을 입히거나(tint) 필터를 걸지 않는다. 뒤에는 **톤 wash 쿠션**(원/블롭)을 깔아 무대를 만든다.
- 일러스트는 장식 — `ExcludeSemantics`(위젯이 이미 처리).

## 5. 공용 컴포넌트 (`lib/presentation/widgets/`)

클래스 이름·공개 API는 **유지**한다(소비처·테스트 안정). v2 이름(InkSeal·BrushDivider·PaperBackground…)은
역사적 이름일 뿐이며 문서 주석에 v3 외형을 적는다.

### 5.0 클레이 광택(허용된 유일한 그라데이션)
떠 있는 면(주요 버튼·선택된 세그먼트/탭 알약·스티커)에만: 세로 2색 `LinearGradient(top: Color.lerp(base, paperRaised, .22), bottom: base)`.
명도 차는 은은하게 — 반짝이는 느낌이 아니라 "점토 윗면에 빛이 닿은" 정도.

### 5.1 표면
- `AppCard` emphasis: **flat** = paperCard + e1, 보더 없음 · **raised** = paperRaised + e2 · **hero** = paperRaised + e3 +
  아랫장(stack)은 톤 wash 파스텔로. 라디우스 lg. 헤어라인 보더는 되도록 제거(필요 시 `line` 1.5).
- `AppSheetShell`/`AppDialogShell`: 윗변 xl, 핸들 40×5 알약(lineStrong), 제목 주아체.
- `PaperBackground`: 그레인만(세기 토큰이 낮아짐).

### 5.2 버튼·입력
- `PrimaryButton`: 알약 54, **accentFill** 면 + 클레이 광택 + 톤 그림자, 글자 paperRaised **주아체 19**(`heading`). 눌림 = accent 쪽으로 + 그림자 축소 + scale .97.
- `GhostButton`: 알약, paperRaised 면 + lineStrong 1.5 보더, ink700 글자.
- 입력: paperRaised 면, line 1.5 → 포커스 accent 2.0, 라디우스 md. 검색은 알약.

### 5.3 내비·세그먼트
- `AppBottomNav`(먹 캡슐 **모션 그대로**): 캡슐 트랙 = paperRaised + e3, 흐르는 알약 = **accentFill**(+광택), 라벨 **주아체 19**,
  알약 위 글자 = paperRaised, 바깥 글자 = ink500. 두 겹 라벨 뒤집힘 연출 유지.
- `SlidingSegment`: 트랙 paperStack 알약, 썸 paperRaised 알약 + e1 + 광택, 선택 글자 ink900 / 비선택 ink500.

### 5.4 브랜드·장식
- `InkSeal` → **딸기 스티커 도장**: seal 핑크 둥근 스퀴클 + **흰 스티커 테두리(2dp, paperRaised)** + e1, 글리프 주아체(paperRaised).
  기울기·스탬프인 모션 유지. 워터마크 = sealWash 면 + seal 글리프.
- `InkHaloIcon` → **클레이 버블**: wash 원 + 은은한 광택(좌상단 하이라이트) + (ring이면) fg α.22 2dp 링. 등장 모션 유지.
- `BrushDivider` → **몽글 점선**: 지름 4 둥근 점 간격 10(가운데로 갈수록 살짝 커지는 리듬 가능), lineStrong. 프리셋·결정적 페인터 유지.
- `SectionHeader`: 먹선 틱 → **accent 동그라미 점(8dp)** 또는 작은 하트, 제목 주아체 heading.
- 스티커 칩(배지·BEST·순위·메타 칩 공통 문법): 알약, wash 면 + fg 글자, 흰 테두리 1.5~2(paperRaised), e1.

### 5.5 상태·스켈레톤
- `EmptyState`/`ErrorState`: 아이콘 헤일로 대신 **클레이 장면**(`ClayScenes.emptySearch/emptyHeart/oops`)을 우선 사용할 수 있게 슬롯 제공.
- 스켈레톤: paperStack 블록, 라디우스 한 단계 up.

## 6. 화면별 지시

- **스플래시**(v2 §7.6-1 비트 유지): 인주 도장 → **딸기 핑크(seal) 원형 배지 + 클레이 아가 얼굴**. 우는 얼굴(`babyCry`)에서
  방긋(`babySmile`)으로 크로스페이드(+ 살짝 스쿼시 바운스), 눈물은 벡터 물방울로 흘러내림. 블롭 wash 파스텔, 워드마크 주아체.
  네이티브 런치 = 크림 바탕 + 같은 배지 PNG(첫 프레임 일치).
- **온보딩**: 무대·연동 모션 유지, 일러스트 3장 클레이(`onboardingCry/Care/Sleep`), 떠 있는 카드 = 둥근 카드 + 스티커 칩,
  제목 주아체, CTA 알약, 페이지 점 = 알약 점(활성 accent 폭 20).
- **홈 케어 덱**: 그룹 탭 = 알약 세그먼트(엄마 탭 강조 lilac), 무대 블롭 = 톤 wash 파스텔, 메타 칩·BEST 카드 = 스티커 문법,
  글: 오버라인 먹 틱·모노 번호 → **주아체 번호 동그라미 배지** + 그룹 라벨, 이름 주아체 displayL, "자세히 보기" = accent 알약(광택),
  레일 = 동그란 wash 쿠션 위 클레이 썸네일, 선택 = accent 링.
- **검색**: 알약 검색창, 최근 검색 알약 칩, 결과 행에 클레이 썸네일(작은 쿠션).
- **상세 케어 노트**: 무대 wash 파스텔 + 클레이 일러스트, 장 탭 = 대상 톤 wash 트랙 + **크림 젤리 알약 + 톤 글자**(두 겹 뒤집힘), 겹치는 시트 윗변 xl, 병원 신호 카드 = coralWash
  + coral 글자(응급 의미 유지), 아코디언 = 둥근 카드 + 원형 셰브론, 제품 랭킹 보드: 1위 히어로 = 버터 리본 스티커,
  순위 배지 톤 사다리 **1 amber · 2 accent · 3 sage · 4+ 중립**(v2.1 그대로) — 스티커 문법으로.
- **내 정보·설정·찜·약관**: 헤더에 클레이 `momAndBaby` 장면, 설정은 큰 라운드 카드 묶음 + 행마다 파스텔 아이콘 버블, 찜은 둥근 타일.

## 7. 모션
기존 모션 전부 유지(v2 계약). 새로 더하는 것은 없다 — 굳이 더한다면 이미 있는 `TapSpring` 눌림을 새 알약에도 연결하는 정도.

## 8. 검증
`flutter analyze` 0 · 테스트 전체 통과 · iOS 시뮬레이터 실화면(라이트/다크) 확인 · 대비(§3.1) 유지.
