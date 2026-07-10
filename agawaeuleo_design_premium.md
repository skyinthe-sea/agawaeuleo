# 아가왜울어 — 페이퍼잉크 프리미엄 고도화 설계서 (DESIGN v2 "묵직한 페이퍼잉크")

> 작성: 2026-07-10, Fable 5. 기반: 전 화면 디자인 현황 조사(6영역 병렬 전수 열람).
> 발주자 요구: **"페이퍼잉크 스타일은 유지하되, 프리미엄한 묵직함이 나도록 고도화."**

---

## 0. 문서 지위 · 적용 규칙

- 이 문서는 `agawaeuleo_spec.md`(SSOT v1.1)의 **§9(디자인 시스템)·§10(애니메이션)·§11(화면 명세) 시각 레이어를 개정하는 부속 계약**이다. 시각·디자인 사항에 한해 스펙과 충돌하면 **이 문서가 우선**한다. 기능·데이터·법적 문구·아키텍처는 여전히 스펙이 우선.
- 구현 완료 시 스펙 §16.4에 변경 이력 1줄, §9 서두에 본 문서 참조 노트를 추가한다.
- **불변 조항(이 문서로도 못 바꿈)**: §13.2 대가성 문구·§13.3 의학 면책 문구 **원문 그대로**, 쿠팡 링크 `LaunchMode.externalApplication`, 터치타깃 최소 48dp, WCAG AA(본문 4.5:1), reduce-motion 대체(§9.7), 순수 흑/백 금지, **그라데이션 금지**(질감은 텍스처로만), 레이어 규칙(presentation→…→data), 색·크기·모션 하드코딩 금지(토큰 경유).

---

## 1. 진단 — 왜 "단촐"한가 (조사 수렴 결과)

1. **위계 붕괴**: 시스템에 e1~e4 음영, brXs~brFull 라디우스, 4색 워시가 정의돼 있으나 위젯 레이어가 e1·brSm/brMd·accent만 소비. 화면 전체가 같은 고도·같은 곡률·같은 톤 → "위계 없는 리스트 나열".
2. **e1이 사실상 비가시**(라이트 alpha 0.04~0.06, blur 1~2). 유일한 표면 분리 수단이 1px 헤어라인뿐 → "평면 문서" 인상.
3. **질감 부재**: "한지"가 베이지 단색 hex 하나로만 표현됨.
4. **브랜드 시그니처 부재**: 증상 16종이 전부 스톡 Material 아이콘, "아이콘-in-원" flat 패턴이 4곳 복붙, 다이얼로그는 스톡 AlertDialog, 시트 셸은 화면마다 재구현. 커스텀 자산은 InkDropLogo(스플래시)·잉크드롭 리프레시·InkWashSplash 3개뿐이며 서로 연결되지 않음.
5. **리듬 균일**: 섹션 간격 24 균일 + 텍스트 한 줄 섹션 헤더. 명조(serif)는 앱 전체 2~3곳, sage/amber는 거의 0회, 트래킹 영역은 AppCard조차 미사용(수제 Container 복붙 4곳+).

**결론**: 모션·접근성·토큰 준수는 이미 성숙. 부족한 것은 **정적 표면·색·타이포의 위계와 브랜드 오브제**다. 고도화는 (a) 토큰 소폭 개정, (b) 시그니처 컴포넌트 신설, (c) 기존 컴포넌트 위계 재배정, (d) 화면별 적용의 4단으로 한다.

## 2. 디자인 방향 — "묵직한 페이퍼잉크" 3원칙

1. **紙 — 종이에 무게를**: 배경을 반 단계 깊게, 그림자를 "겹친 한지"가 보이는 수준으로, 표면엔 미세한 종이 그레인. 히어로 표면은 아랫장이 살짝 비치는 **겹침(stack)**으로.
2. **墨 — 먹에 존재감을**: 낙관(印) 도장, 붓결 디바이더, 잉크 틱 — 먹의 오브제를 시그니처 컴포넌트로 만들어 반복 노출. 명조 대형 타이포 + 음수 자간으로 "눌러 쓴" 인상.
3. **格 — 자리마다 격을**: elevation·라디우스·워시·서체를 **역할별로 차등 배정**(운용 매트릭스 §6). 균일함은 유지하되 "모두 같음"은 폐기.

---

## 3. 토큰 개정 (스펙 §9 개정)

### 3.1 컬러 — 개정 1 + 신규 4 (`lib/config/theme/app_colors.dart`)

| 토큰 | 역할 | Light | Dark | 비고 |
|---|---|---|---|---|
| `paperBg` | 화면 배경 | `#F3EEE3` → **`#F0EADB`** | `#1A1815` (유지) | 반 단계 깊게 — 카드 대비 ↑ |
| `paperStack` **신규** | 겹친 종이 아랫장 | **`#E8E0CD`** | **`#201D16`** | hero 카드 스택 전용 |
| `seal` **신규** | 낙관 인주(브랜드) | **`#A8432C`** | **`#C96B4F`** | coral(응급)과 의미 분리 |
| `amberWash` **신규** | 정보/배지 옅은 배경 | **`#F4E9D5`** | **`#3A311F`** | 기존 `amber.withValues(alpha:…)` 하드코딩 2곳 대체 |
| `sealWash` **신규** | 낙관 옅은 배경(워터마크) | **`#F1DFD7`** | **`#392620`** | 사용 빈도 낮음, 완결성용 |

- 나머지 토큰 값 전부 유지. `ThemeExtension` copyWith/lerp에 신규 필드 추가.
- 대비 확인 완료: seal 위 글리프는 `paperBg` 색 사용(라이트 `#F0EADB` on `#A8432C` ≈ 5.5:1, 다크 `#1A1815` on `#C96B4F` ≈ 6:1).

### 3.2 음영 — 전면 개정 (`app_shadows.dart`)

원칙 유지(따뜻한 먹빛 rgba(74,66,50,α), 회색 금지). **"보일 듯 말 듯" → "종이가 실제로 겹친"** 수준으로 상향.

| 레벨 | Light (신규) | Dark (신규) |
|---|---|---|
| e1 | `0 1px 2px rgba(74,66,50,.10)` + `0 2px 6px rgba(74,66,50,.05)` | `0 1px 3px rgba(0,0,0,.45)` |
| e2 | `0 2px 8px .12` + `0 1px 3px .06` | `0 2px 10px rgba(0,0,0,.55)` |
| e3 | `0 10px 28px .14` + `0 2px 8px .07` | `0 12px 32px rgba(0,0,0,.65)` |
| e4 | `0 6px 18px .16` | `0 8px 22px rgba(0,0,0,.60)` |
| press | 유지 | 유지 |
| topHighlight(다크) | — | `rgba(255,255,255,.04)` → **`.06`** |

### 3.3 타이포 — 확장 3 + 자간 도입 (`app_typography.dart`)

| 이름 | 크기/행간 | 폰트/굵기 | **letterSpacing** | 용도 |
|---|---|---|---|---|
| `displayL` **신규** | 34 / 1.25 | 명조 700 | **-0.5** | 온보딩 제목, 히어로 모먼트 |
| `display` | 28 / 1.30 (유지) | 명조 700 | **-0.5** | 기존 용도 |
| `title` | 22 / 1.35 (유지) | 명조 700 | **-0.3** | 화면 제목, 시트/다이얼로그 헤더 |
| `heading` | 18 / 1.40 (유지) | Pretendard 600 | **-0.2** | 섹션 제목 |
| `bodyL` / `body` | 유지 | 유지 | 0 (유지) | |
| `label` | 15 / 1.20 (유지) | Pretendard 600 | **+0.2** | 버튼/탭 |
| `caption` | 12 / 1.50 (유지) | Pretendard 500 | **+0.4** | 캡션·메타 |
| `overline` **신규** | 11 / 1.30 | Pretendard 600 | **+1.2** | 섹션 오버라인, 날짜 라벨 (`ink500`) |
| `data` | 16 / 1.20 (유지) | 모노 500 | 0 | 수치/시간 |
| `dataL` **신규** | 28 / 1.15 | 모노 500 | 0 | 트래킹 히어로 수치(경과시간 등) |

`AppTextStyles`(context.texts)에도 신규 3종 노출. 폰트 추가 없음(기존 서브셋으로 충분).

### 3.4 질감 — 신규 토큰 파일 `app_texture.dart` + 에셋

```dart
/// DESIGN v2 §3.4 종이 그레인. 자산 1장을 타일 반복, ink900으로 틴트.
class AppTexture {
  static const String grainAsset = 'assets/textures/paper_grain.png';
  static const double opacityLight = 0.05;
  static const double opacityDark = 0.045;
  static double opacityOf(Brightness b) => b == Brightness.dark ? opacityDark : opacityLight;
}
```

- 에셋: `assets/textures/paper_grain.png` — 144×144 타일러블, 흰색 픽셀 + 랜덤 알파 노이즈 + 한지 섬유질 짧은 스트로크(§8 생성 스크립트 사양). **이미 리포에 커밋됨** — 구현 에이전트는 pubspec `assets:` 등록만 확인.
- 렌더 계약: `DecorationImage(image: AssetImage(grainAsset), repeat: ImageRepeat.repeat, opacity: AppTexture.opacityOf(brightness), colorFilter: ColorFilter.mode(colors.ink900, BlendMode.srcIn))` — ink900이 모드별로 뒤집히므로 라이트=어두운 결, 다크=밝은 결이 자동.
- `MediaQuery.highContrast == true`면 그레인 미표시.

### 3.5 라디우스·여백 — **값 불변**, 운용만 §6 매트릭스로 재배정

`theme.dart` barrel에 `app_texture.dart` export 추가.

---

## 4. 시그니처 컴포넌트 (신규 7종, `lib/presentation/widgets/`)

> 공통: 모든 신규 모션은 `AppMotion.resolve/resolveCurve` 경유(reduce-motion 시 즉시완료/페이드). 모든 색·수치는 토큰 경유. 각 컴포넌트에 스모크 위젯 테스트 1개 이상.

### 4.1 `InkSeal` — 낙관 도장 (`widgets/brand/ink_seal.dart`)

앱의 새 브랜드 오브제. 인장(印章) 모티프.

- 형태: 둥근 정사각(`borderRadius: size * 0.24`), 배경 `colors.seal`, 중앙 글리프 **"아"**(명조 700, 크기 `size * 0.5`, 색 `colors.paperBg`), 내부 1px 인셋 헤어라인(`colors.ink900.withValues(alpha: .12)`).
- 크기 프리셋: `InkSeal.sm`(20) / `md`(28) / `lg`(44).
- 기본 기울기 **-3도**(`Transform.rotate`) — 손으로 찍은 인상. `tilt: false`로 끌 수 있음.
- `SealStampIn` 등장 모션(옵션 `animate: true`): opacity 0→1(fast) + scale 1.4→1.0(base, `curve.enter`) + rotate -6°→-3°, 완료 시 `HapticFeedback.mediumImpact` (옵션). reduce-motion 시 페이드만.
- 워터마크 모드(`watermark: true`): 배경 `sealWash`, 글리프 `seal`, 불투명도 낮은 장식용.
- **사용처**: 스플래시(로고 하단, stamp-in), 온보딩 마지막 장, 로그인 헤더 보조, 비밀번호 재설정 성공, 트래킹 저장 성공 모먼트, 설정>정보 그룹 상단, 약관 뷰어 말미.

### 4.2 `BrushDivider` — 붓결 디바이더 (`widgets/dividers/brush_divider.dart`)

- CustomPainter: 좌→우로 두께 2.5→0.8dp로 가늘어지는 수평 스트로크 + 미세한 상하 곡률(sine 1회, 진폭 0.6dp). **난수 없이 결정적**(골든 테스트 안정성).
- 색 `colors.lineStrong`, 기본 폭 64(`BrushDivider.section` 좌정렬) / 88(`BrushDivider.center` 중앙정렬). 상하 여백은 소비처 책임.
- **사용처**: 증상 상세 "정보 → 제품" 전환점, 설정 그룹 사이(선택), 빈 상태 메시지 위, 온보딩 텍스트 블록 위. **리스트 행 구분에는 쓰지 않음**(기존 1px `Divider` 유지) — 섹션 격 전환에만.

### 4.3 `SectionHeader` — 섹션 리듬 통일 (`widgets/headers/section_header.dart`)

```
[overline?]                      ← AppTypography.overline, ink500, 밑 4dp
▍ 섹션 제목            [trailing?]  ← 잉크 틱 + heading(ink900) + Spacer + trailing
```

- 잉크 틱: 3×16dp, radius 1.5, `colors.accent` — 앱 전역 섹션 시그니처.
- `trailing`: 개수(`data`체, ink500)·"더보기" 액션 등 자유 슬롯.
- **사용처**: 기존 "텍스트 한 줄 섹션 제목" 전부 교체 — 제품 섹션 헤더, 최근 검색어 헤더, 설정 그룹 헤더, 즐겨찾기 상단 요약, 트래킹 요약 섹션 등.

### 4.4 `InkHaloIcon` — "아이콘-in-원" 공용 승격 (`widgets/brand/ink_halo_icon.dart`)

flat 워시 원 4곳 복붙을 대체하는 단일 컴포넌트.

- 구조: 워시 원(배경 `washColor`) + **바깥 링**(지름 +10dp, stroke 1.2, `fgColor.withValues(alpha:.28)`) + 중앙 아이콘(`fgColor`).
- 옵션: `elevated: true` → 원에 e2 그림자. `animate: true` → 등장 시 scale .88→1 + fade(base, enter) "잉크 번짐". `ring: false`로 링 생략(밀집 그리드용).
- 파라미터: `size`(원 지름), `icon`, `washColor`, `fgColor`, `child`(아이콘 대신 임의 위젯 — InkDropLogo 삽입용).
- **교체 대상**: 로그인 `AuthLogo`(64), 권한 프라이밍 원(120), 재설정 성공 원(96), 온보딩 일러스트 프레임(내부), EmptyState 원(122), 증상 상세 히어로 원(56, **Hero 태그 유지 필수**), ErrorState 아이콘.

### 4.5 `PaperBackground` — 종이 그레인 표면 (`widgets/surfaces/paper_background.dart`)

- 구현: `Stack`[ `Positioned.fill`(IgnorePointer + §3.4 렌더 계약의 DecoratedBox), child ]. 배경색은 기존 Scaffold가 그대로 칠하고 그 위에 그레인만 얹는다.
- `MediaQuery.highContrastOf == true`면 child만 반환.
- 성능: 타일 1장 GPU repeat — 페인터 재실행 없음. `const` 생성 가능하게.
- **적용처**: 홈·트래킹·프로필(3탭 셸 스크린 body), 스플래시, 온보딩, 증상 상세, 설정. `AppSheetShell`에도 옅게(불투명도 0.6배) 적용.

### 4.6 `AppSheetShell` / `AppDialogShell` — 표면 격 통일

**`AppSheetShell`** (`widgets/sheets/app_sheet_shell.dart`):
- `paperRaised` + 상단 `BorderRadius.vertical(top: r.lg=20)` + **e3** + 그레인(0.6배) + 그래버(36×4, r.full, `lineStrong`, 상단 8dp) + 옵션 헤더(명조 `title` 22 + trailing 슬롯, 아래 12dp) + 하단 SafeArea.
- 기존 `showAppBottomSheet`는 유지하되 content를 이 셸로 감싸는 파라미터 추가(또는 각 시트가 셸 직접 사용). `tracking_entry_sheet`·`backup_priming_sheet`의 수제 시트 chrome(라운드/그림자 중복 구현) 제거.

**`AppDialogShell`** (`widgets/dialogs/app_dialog_shell.dart`) + `showAppDialog()` 헬퍼:
- `paperRaised`, `r.lg`, e3, 좌상단 `InkHaloIcon`(44) + 명조 `title`(22) + `bodyL`(ink700) 본문 + 액션 행(보조=GhostButton, 주=PrimaryButton).
- `destructive: true` → halo `coralWash`/`coral`, 주 버튼 배경 `coral`(텍스트 `paperRaised`).
- **교체 대상**: 로그아웃/계정삭제(2단계 모두)/아기 프로필 삭제 다이얼로그. 계정삭제의 200ms 지연 스피너·"삭제" 재입력 로직은 그대로 유지하고 **셸만 교체**.

### 4.7 `SlidingSegment` — 슬라이딩 세그먼트 통합 (`widgets/segments/sliding_segment.dart`)

3곳 중복 구현(`baby_gender_segment`, `segmented_control`, 트래킹 `_TypeSegment`/`_RangeTabs`)을 단일 컴포넌트로.

- 트랙: `paperCard` + `line` 1px 보더 + `r.sm`(10), 높이 44.
- 인디케이터: `paperRaised` + **e2** + `lineStrong` 헤어라인, `AnimatedAlign`(fast, standard).
- 라벨: 선택 `accent`(600) / 비선택 `ink500`. `selectionClick` 햅틱.
- 제네릭 API: `SlidingSegment<T>(items, selected, onChanged, labelOf)`. 기존 3곳 + 즐겨찾기 세그먼트 탭도 이걸로 교체(시각 규칙 동일하므로).

---

## 5. 기존 공용 위젯 개정

### 5.1 `AppCard` — emphasis 3단 (`widgets/cards/app_card.dart`)

```dart
enum AppCardEmphasis { flat, raised, hero }
```

| emphasis | 배경 | 그림자 | 라디우스 | 보더 | 부가 |
|---|---|---|---|---|---|
| `flat` (기본=현행) | `paperCard` | e1 | `brMd`(14) | `line` | — |
| `raised` | `paperRaised` | **e2** | **`brLg`(20)** | `line` | — |
| `hero` | `paperRaised` | e2 | `brLg` | `line` | **아랫장 스택**: 카드 뒤 `paperStack` 시트(좌우 10dp 인셋, 아래로 4dp 오프셋, 동일 라디우스, 보더 없음) — "겹친 한지" 시그니처. 그레인(§3.4) 오버레이 |
- 탭 스프링·press 오목·잉크 워시 리플은 세 variant 공통(현행 유지). 다크 모드 hero는 스택 대신 topHighlight 강조가 이미 있으므로 스택 색만 `paperStack`(다크 값)으로 동일 처리.
- 기존 호출부는 무변경(기본값 flat).

### 5.2 `AppAppBar` — 2단 표면 (`widgets/navigation/app_app_bar.dart`)

- `scrolled == false`에도 **하단 헤어라인 `line` 상시** 표시(현재는 완전 무경계). `scrolled == true` 시 헤어라인 유지 + e2 추가(현행).
- 옵션 `subtitle`(caption, ink500) 슬롯 추가 — 타이틀 아래 2dp.

### 5.3 `AppBottomNav` — 먹점 인디케이터 (`widgets/navigation/app_bottom_nav.dart`)

- 상단 헤어라인 `line` 1px 추가(raised 표면 경계).
- 활성 탭: 아이콘 위 2dp 지점에 **먹점**(3.5dp 원, `accent`) — AnimatedScale(0→1, spring) + fade. 색 트윈(현행)·햅틱 유지. 비활성 탭은 점 없음.

### 5.4 상태 위젯 (`widgets/states/`)

- `EmptyState`: 워시 원 → `InkHaloIcon`(122, animate) 교체, 메시지 위 `BrushDivider.center`(위아래 12dp). shake·fadeIn 현행 유지.
- `ErrorState`: **진입 모션 추가**(EmptyState와 동형 fadeIn+slideY), 아이콘을 `InkHaloIcon`(coralWash/coral)로.
- `OfflineBanner`: 현행 유지(amber 워시 — 신규 `amberWash` 토큰으로 색만 교체).

### 5.5 스켈레톤 (`widgets/skeletons/skeleton_blocks.dart`)

- `_SkeletonShell`의 수제 데코를 신규 e1 값과 자동 정합(토큰 경유이므로 값 개정만으로 반영됨 — 코드 확인만). 카드형 스켈레톤 라디우스를 대응 카드와 일치시킬 것(flat=brMd).

### 5.6 버튼 — 값 변경 없음

`label` 자간 +0.2가 토큰에서 자동 반영. 신규 variant 도입하지 않음(범위 통제).

---

## 6. 운용 매트릭스 (전 화면 공통 규칙)

### 6.1 Elevation 재배정

| 레벨 | 쓰는 곳 |
|---|---|
| e0 | 화면 배경, 플랫 리스트 행(검색 결과 등 — 헤어라인 구분) |
| e1 | 정지 카드(그리드 카드, 정보 카드, 리스트 카드) = `AppCard.flat` |
| e2 | **강조·상승 표면**: hero/raised 카드, 스크롤된 앱바·고정 검색바, 슬라이딩 인디케이터, 프로필 아바타, 버튼(현행) |
| e3 | 시트·다이얼로그 (`AppSheetShell`/`AppDialogShell`) |
| e4 | FAB·스낵바·스탬프 오버레이 |

### 6.2 증상 카테고리 톤 — `SymptomTone` (`widgets/symptom/symptom_tone.dart` 신규)

`SymptomIcons`와 나란한 프레젠테이션 유틸(도메인 데이터 아님 — 아이콘 키 매핑과 동일한 성격). 아이콘 키/slug → (wash, fg) 매핑:

| 카테고리 | 예 | wash / fg |
|---|---|---|
| 열·응급성 | 발열, 경련 등 | `coralWash` / `coral` |
| 소화·배변 | 배앓이, 변비, 설사, 구토 등 | `sageWash` / `sage` |
| 수면·컨디션 | 밤울음, 보챔 등 | `amberWash` / `amber` |
| 호흡·피부·기타(기본) | 기침, 콧물, 발진 등 | `accentWash` / `accent` (현행) |

- 16종 fixture의 아이콘 키를 보고 4분류를 매핑(모르는 키는 기본=accent). 채도는 워시라 이미 낮음 — 절제 유지.
- 적용처: 홈 그리드 카드 아이콘 원, 검색 결과 행 아이콘, 증상 상세 히어로, 즐겨찾기 카드 — `SymptomIcons` 소비처 전부(단일 매핑이라 Hero 색 일관성 자동).

### 6.3 명조(serif) 사용처 확대 (절제 원칙 유지 — "큰 활자에만")

홈 인사(현행), 화면 제목(현행), **온보딩 제목(displayL)**, **시트 헤더**, **다이얼로그 제목**, **증상 상세 요약 카드의 오버라인 라벨은 sans overline**(명조 아님), 스플래시 워드마크. 본문·리스트에는 절대 사용 금지(현행 유지).

### 6.4 섹션 리듬

섹션 제목은 전부 `SectionHeader`. 섹션 간 간격은 24 유지하되, **격이 바뀌는 지점**(정보→제품, 콘텐츠→법적 고지)에는 `BrushDivider.section` + 32 간격. "모든 간격 24" 단조 탈피.

---

## 7. 화면별 적용 지시

> 각 항목은 담당 에이전트가 그대로 실행 가능한 수준으로 기술. 여기 없는 화면/요소는 §5·§6 공통 규칙만 적용.

### 7.1 홈 (`features/home/`)

1. **인사 바 → 에디토리얼 2단**: 위에 `overline`으로 날짜 "7월 10일 목요일"(intl 의존성 추가 금지 — `'${m}월 ${d}일'` + 요일 한글 배열 수동 포맷), 아래 명조 인사(현행 title). 벨 버튼 유지.
2. **고정 검색바**: `overlapsContent`(또는 스크롤 오프셋) 감지해 스크롤 시 e2 + 하단 헤어라인 표출(AppAppBar와 같은 2단 문법).
3. **증상 카드**: 아이콘 원을 `SymptomTone` 매핑 색으로(§6.2) + 원에 1px 헤어라인 링(`fg.withValues(alpha:.22)`). 카드 자체는 flat 유지(그리드 밀도상 hero 남용 금지).
4. **최근 본 증상 칩**: `line` 1px 보더 + 좌측 12dp `history` 아이콘(16, ink500) 추가.
5. Scaffold body를 `PaperBackground`로 감싸기.

### 7.2 검색 (`features/search/`)

1. TopBar 하단 상시 헤어라인.
2. 결과 행·최근 검색 행: 카드화하지 말 것 — 행 사이 **inset 헤어라인 디바이더**(좌 72dp)로 리듬만 부여. 아이콘 원은 `SymptomTone` 적용.
3. "최근 검색어" 헤더 → `SectionHeader`(trailing="전체 삭제" 텍스트 버튼).
4. 최근 검색어 빈 상태 `_EmptyHint` → 공용 `EmptyState`로 교체.

### 7.3 증상 상세 (`features/symptom_detail/`)

1. **헤더를 독립 표면으로**: 헤더 블록(아이콘+이름+별)을 `paperRaised` 배경 + 하단 헤어라인 + 그레인으로 감싸고, 히어로 원을 `InkHaloIcon`(56, elevated, `SymptomTone` 색)로 — **Hero 태그 `symptom-icon-<id>`/`symptom-name-<id>` 반드시 유지**.
2. **요약 카드 → hero 격**: `AppCard(emphasis: hero)` + 상단 `overline` "한눈에 보기" + 좌측 잉크 틱(SectionHeader 틱과 동일 3×16 accent 바).
3. **정보 아코디언**: 섹션 성격별 라인 아이콘 20dp(원인=`help_outline`, 관리법=`spa_outlined`/`healing`, 주의·병원=`error_outline` 등 Material 아이콘 허용) + 펼침 시 아이콘·제목 색 `ink700`→`accent` 트윈(fast).
4. **정보 → 제품 전환점**: `BrushDivider.section` + 32dp 간격(§6.4).
5. **의학 면책**: 문구 **원문 불변**. `line` 1px 보더 박스(r.sm, 패딩 12) + `info_outline` 16(ink500) — 격은 낮게, 존재감만.
6. **제품 섹션**: 헤더 → `SectionHeader`(trailing = "N개" data체). 1위 카드에만 좌상단 순위 배지(`amberWash` 바탕 + amber `data`체 "1", 20dp 원) + `lineStrong` 보더. 대가성 배지는 신규 `amberWash` 토큰 사용, 문구 원문 불변.
7. 응급 카드: 현행 유지(이미 잘 만들어짐). Scaffold body `PaperBackground`.

### 7.4 즐겨찾기 (`features/favorites/`)

1. 상단에 `SectionHeader`(overline="모아보기", 제목="즐겨찾기", trailing="N개" data체).
2. 세그먼트 탭 → 공용 `SlidingSegment`.
3. 제품 타일에 추가일 캡션(caption, ink300) — 데이터에 있으면. 없으면 생략(도메인 변경 금지).

### 7.5 트래킹 (`features/tracking/`)

1. **수제 카드 전면 교체**: `Container`+BoxDecoration 복붙 4곳+(tracking_screen 361·524, summary 223·326 등) → `AppCard`(요약·통계 카드는 `raised`, 타임라인 타일은 `flat`). press·리플이 이 영역에 처음 생김.
2. **경과 시간 히어로**: 진행 중 배지/경과 표시의 수치를 `dataL`(28 모노)로 승격.
3. 요약/통계 카드에 진입 stagger(40ms, fadeIn+slideY — 홈 그리드와 동일 문법).
4. `_TypeSegment`/`_RangeTabs` → 공용 `SlidingSegment`.
5. 기저귀 wash 하드코딩(`amber.withValues(alpha:.16)`) → `amberWash` 토큰.
6. **저장 성공 모먼트**: 기존 CheckDraw 옆에 `InkSeal.sm`(20) stamp-in — "기록이 도장 찍혔다". reduce-motion 시 페이드.
7. `tracking_entry_sheet`·`backup_priming_sheet` → `AppSheetShell`(수제 chrome 제거). `_TimelineEmpty`/`_SummaryEmpty` → 공용 `EmptyState`.
8. `_BarPainter` 요일 라벨 fontSize 11 리터럴 → `AppTypography.caption` 기반(`copyWith`)으로.
9. 기록 홈 Scaffold body `PaperBackground`.

### 7.6 인증·온보딩 (`features/auth/`, `features/onboarding/`)

1. **스플래시**: InkDropLogo 아래 명조 워드마크 "아가왜울어"(title, ink900) + 그 아래 `InkSeal.md` stamp-in(로고 페이드 완료 후 지연 200ms). `PaperBackground`.
2. **로고 통일**: 로그인/가입의 `AuthLogo`(물방울 Material 아이콘) → `InkHaloIcon(size:64, child: InkDropLogo)` — 스플래시와 동일 브랜드 마크.
3. **폼 카드화**: 이메일/비밀번호 필드 그룹을 `AppCard(emphasis: raised, padding: 20)` 안에. 소셜 버튼 그룹은 카드 밖 유지(위계 분리).
4. `GoogleGlyph`: 원형 배지(28, `paperRaised` + `line` 보더) 안의 "G"로 정돈(실제 구글 로고 에셋 도입 금지 — 라이선스).
5. **약관 동의**: "전체 동의" 마스터 행(체크 시 하위 3개 일괄) 추가 + 마스터와 개별 사이 헤어라인 + 개별 행 사이 헤어라인. 필수/선택 배지를 미니 칩(caption, `line` 보더)으로.
6. **온보딩**: 제목 `display`→`displayL`. 상단 좌측에 `overline` 스텝 라벨 "1 / 3"(data체 허용). 일러스트 프레임 내부에 페이지별 배경 모티프 차별화 — 1장: 동심원 파문(잉크 링 2개), 2장: 점묘 4~5점, 3장: 초승달 곡선 — 전부 `fg.withValues(alpha:.10~.14)` CustomPainter 경량 구현, 결정적(난수 금지). 마지막 장 CTA 위 `InkSeal.sm`.
7. 재설정 성공·권한 프라이밍의 원 → `InkHaloIcon`(각 96/120, animate).

### 7.7 프로필·설정 (`features/profile/`, `features/settings/`)

1. **프로필 헤더 히어로화**: 아바타에 e2 + `accent.withValues(alpha:.25)` 1.5px 링, 헤더 블록 아래 `BrushDivider.section`. 메뉴 타일 아이콘에 개별 wash 배경(24→36dp 원: 아기=accentWash, 즐겨찾기=amberWash, 설정=중립 paperCard+line, 문의=sageWash) + 진입 stagger(baby_card와 동일 문법).
2. **설정 그룹**: 그룹 헤더 → `SectionHeader`(overline 없이). 그룹 카드 `AppCard.raised`로 승격.
3. `NotificationPermissionHint` → `amberWash` 배너 카드(r.sm, `amber` 20dp 아이콘 + caption + 액션) — OfflineBanner와 동일 문법.
4. **계정 다이얼로그 3종 + 아기 삭제** → `AppDialogShell`(destructive). 로직(200ms 스피너, "삭제" 재입력) 불변.
5. 약관 뷰어: amber 하드코딩 박스 → `amberWash` 토큰. 섹션 heading 앞 번호 배지(20dp 원, `accentWash`/accent, data체). 문서 말미 `InkSeal`(watermark) + 시행일.
6. 테마 세그먼트 → 공용 `SlidingSegment`. 프로필·설정 화면 body `PaperBackground`.

### 7.8 전역

- 3탭 셸: `AppBottomNav` 먹점+헤어라인(§5.3).
- 모든 화면의 앱바: §5.2 상시 헤어라인(위젯 수정만으로 전파).
- 라우터 전환·기존 모션 값: **변경 금지**(이미 완성도 높음).

---

## 8. 에셋 — 종이 그레인 타일

- 경로: `assets/textures/paper_grain.png`, pubspec `flutter: assets:`에 `assets/textures/` 등록.
- 사양: 144×144 RGBA. 전 픽셀 흰색(255,255,255) + 알파 = 균등난수 0~255의 **미세 노이즈를 알파 18% 스케일로 감쇠**(즉 최종 알파 0~46) + 한지 섬유질: 길이 4~10px 수평/사선 스트로크 70개(알파 28~48). 시드 고정(재현 가능). 타일 경계 이음새 없도록 랩어라운드.
- 생성 스크립트: `tool/gen_paper_grain.py`(Python stdlib만 — zlib/struct). **이미 실행되어 에셋 커밋됨** — 재생성 시에만 사용.

## 9. 가드레일

1. **문구 불변**: §13.2 대가성·§13.3 의학 면책 — 스타일만 바꾸고 텍스트는 바이트 단위 동일해야 함.
2. **접근성**: 모든 신규 모션 reduce-motion 대체, 그레인은 highContrast 시 제거, 터치타깃 48dp, 본문 대비 AA. 시맨틱 라벨 현행 유지(아이콘 원 교체 시 Semantics 소실 금지).
3. **성능**: 그레인은 GPU 타일 1장. 신규 CustomPainter는 전부 `shouldRepaint => false`(정적) 또는 값 비교. 리스트 셀에 e3+ 금지.
4. **다크 모드 완전 대응**: 모든 신규 토큰·컴포넌트는 양 모드 값 필수. AppCard 보더는 **균일색 유지**(비균일 Border + radius = Flutter assert, app_card.dart:54-66 전례).
5. **Hero 계약 유지**: `symptom-icon-<id>`, `symptom-name-<id>`, `home-search-bar` 태그·구조 변경 금지.
6. 그라데이션·순흑백·회색 그림자 금지(현행 원칙 유지).
7. 도메인/데이터 레이어 수정 금지. 라우터 로직 수정 금지.

## 10. 구현 계획 (에이전트 분할 — 소유 디렉터리 엄격 분리)

| 단계 | 에이전트 | 소유 | 내용 |
|---|---|---|---|
| P1 | theme | `lib/config/theme/`, `pubspec.yaml`(assets) | §3 토큰 전체 (에셋은 선커밋됨) |
| P2 | widgets | `lib/presentation/widgets/`, `test/` 해당분 | §4 신규 7종 + §5 개정 + 스모크 테스트 |
| P3 (병렬 5) | home-search / detail-favorites / tracking / auth-onboarding / profile-settings | 각 feature 디렉터리 + 대응 test | §7 화면별 지시 |
| P4 | 통합 검증 | 전체(읽기) | `flutter analyze` 0, 전체 테스트 통과(MCP very_good test), 스펙 §16.4 개정, 최종 대조 검토(Fable) |

- P1→P2→P3 순차 게이트(토큰→컴포넌트→소비). P3는 서로 파일 겹침 없음.
- 테스트는 **MCP `very-good-cli test` 도구만** 사용(`flutter test` Bash 훅 차단). build_runner 불필요(코드젠 무관 레이어) — 필요 시 P4에서 1회만.

## 11. 수용 기준 (P4 체크리스트)

- [ ] `flutter analyze` 0 이슈, 기존+신규 테스트 전체 통과
- [ ] 라이트/다크 모두에서: 카드가 배경과 육안 구분(그림자+스택), 그레인 시인, seal/브러시/틱 렌더 정상
- [ ] §13.2/§13.3 문구 diff 없음 (`git diff`로 문자열 확인)
- [ ] Hero 태그 3종 계약 유지, reduce-motion 스모크(신규 모션 전부 가드 확인)
- [ ] sage/amber/coral/seal이 실제 화면에 등장(§6.2 톤 매핑 + 배지/배너)
- [ ] 명조 신규 사용처 §6.3 목록과 일치, 본문/리스트에 명조 없음
- [ ] 수제 시트 chrome·수제 카드 데코·슬라이딩 세그먼트 중복 구현 제거 확인
