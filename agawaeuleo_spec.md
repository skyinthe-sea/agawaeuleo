# 아가왜울어 — 전체 설계서 (기획 · 아키텍처 · 디자인 · UX)

> **문서 목적**: 이 문서 하나로 Claude Code가 앱 전체(기획·아키텍처·디자인·애니메이션)를 구현할 수 있도록 하는 단일 소스(single source of truth)입니다.
> **읽는 순서**: 발주자(당신)는 먼저 §12(역할 분담)와 §8(환경변수)만 보면 "내가 뭘 준비해야 하는지"가 정리됩니다. 나머지는 Claude Code가 참조합니다.
>
> | 항목 | 값 |
> |---|---|
> | 앱 이름 | 아가왜울어 |
> | 플랫폼 | Flutter (iOS / Android 동시) |
> | 1차 언어 | 한국어 |
> | 타깃 | 0~24개월 영유아를 키우는 부모(주로 엄마), 수면부족·한손조작·짧은세션 환경 |
> | 디자인 컨셉 | 페이퍼잉크(수묵) — 희석된 먹빛 + 명조 디스플레이 + 청록 잉크 액센트 |
> | 문서 버전 | v1.1 (2026-07 개정 — 게스트 우선 인증 · 스토어 최신 요건 · 스택 확정, §16.4 변경 이력) |

---

## 목차
1. 제품 개요
2. 사용자 원칙 (바쁜 엄마를 위한 UX 규칙)
3. 기능 명세 — 핵심 / 서브 / 기본기능 전체
4. 정보구조(IA) · 화면 목록 · 내비게이션
5. 아키텍처 · 기술 스택
6. 데이터 파이프라인 (쿠팡 파트너스 → Supabase → 앱)
7. Supabase 스키마 · RLS · Edge Function
8. 환경변수 · Config 설계 (앱/서버 분리, 나중에 값만 채우기)
9. 디자인 시스템 — 페이퍼잉크 토큰 (색/타이포/여백/radius/음영/모션)
10. 애니메이션 시스템 — 컴포넌트별 (흔들기 · 반짝임 등 전부)
11. 화면별 상세 명세 (레이아웃 · 크기 · 색 · radius · 음영 · 인터랙션 · 애니메이션)
12. 역할 분담 — Claude Code가 할 일 vs 당신이 할 일
13. 법적 · 정책 체크리스트 (공정위 · 애플 4.2 · 의료면책 · 계정삭제)
14. 개발 마일스톤
15. Claude Code 착수 프롬프트
16. 부록 — 폴더구조 · 패키지 · 최종 체크리스트

---

## 1. 제품 개요

### 1.1 한 줄 정의
아기가 우는 이유로 의심되는 **증상을 빠르게 찾아**, 간단한 의학 참고정보와 함께 **관련 육아용품을 추천**하고, 탭하면 쿠팡으로 연결되는 앱. 부수적으로 **수유·수면·배변을 기록**하는 육아 트래커.

### 1.2 문제 정의
- 새벽 수유 중 아기가 울면, 부모는 비몽사몽 상태에서 한 손으로 검색한다.
- "배앓이인가? 태열인가?"를 빠르게 좁히고, 필요한 물건까지 바로 사고 싶다.
- 기존 육아 정보는 흩어져 있고, 제품 구매까지 이어지는 흐름이 끊긴다.

### 1.3 수익 모델
쿠팡 파트너스 딥링크를 통한 제휴 수수료. **반드시 파트너스 API가 발급한, 내 트래킹 코드가 포함된 딥링크만** 노출한다(크롤링한 원본 링크는 수수료 0원 — §6 참조).

### 1.4 성공의 정의 (초기 지표)
- 증상 진입 → 제품 탭 전환율
- 재방문(트래커 사용 유무가 재방문을 견인)
- iOS/Android 심사 통과 (특히 iOS 4.2, §13)

---

## 2. 사용자 원칙 (바쁜 엄마를 위한 UX 규칙)

> 이 규칙들은 "취향"이 아니라 **사용 맥락에 대한 대응**이다. 모든 화면 설계는 아래를 강제한다.

1. **한손 엄지존(Thumb Zone) 우선** — 핵심 액션(검색·기록 추가·구매)은 화면 하단 1/3에 배치. 상단 모서리에 중요한 버튼을 두지 않는다.
2. **5초 규칙** — 홈에서 증상 상세까지 2탭 이내. 온보딩은 스킵 가능, 3장 이내.
3. **저인지부하** — 한 화면에 1가지 주요 작업. 큰 터치타깃(최소 48×48dp), 명확한 위계, 실수 유발 최소화(파괴적 액션은 확인 다이얼로그).
4. **끊기는 세션 대비** — 검색어·기록 입력 중간 상태는 자동 보존. 앱을 닫았다 켜도 하던 흐름 복구.
5. **다크모드가 기본급 중요** — 새벽 사용이 많다. 다크모드에서 눈부심 없는 낮은 휘도, 순수 흑/백 금지(먹빛/미색 사용).
6. **햅틱으로 확인** — 주요 탭·토글·기록완료 시 가벼운 진동으로 "됐다"는 피드백. 시각 확인이 어려운 상황 보조.
7. **응급은 최우선 노출** — 발열·호흡곤란·경련 등은 정보 상단에 경고 카드 + 병원 안내로 분리.
8. **가입 강요 금지(게스트 우선)** — 증상 검색·상세·제품 열람은 로그인 없이 즉시 가능. 인증은 "동기화가 필요해지는 순간"(다기기·백업)에만 부드럽게 유도한다. 새벽에 급한 부모에게 회원가입 폼을 먼저 들이밀지 않는다(Apple 5.1.1 방어 겸함 — §13.4).

---

## 3. 기능 명세

### 3.1 핵심 기능 (Primary)
| ID | 기능 | 설명 |
|---|---|---|
| C1 | 증상 홈 | 대표 증상(배앓이, 이앓이, 태열, 변색, 트림, 게워냄, 콧물, 열, 발진, 수면퇴행 등)을 카드 그리드로 나열 |
| C2 | 초성/부분 검색 | "배앓이" 또는 "ㅂㅇㅇ"로 검색. 한글 초성 매칭 + 부분일치 |
| C3 | 증상 상세 | ① 간단 의학 참고정보 ② 응급신호 경고(해당 시) ③ 추천 제품 리스트 ④ 대가성 표시 ⑤ 의학 면책 |
| C4 | 제품 카드 → 쿠팡 | 탭 시 `url_launcher`로 **외부 브라우저**에서 파트너스 딥링크 오픈 |
| C5 | 즐겨찾기 | 자주 보는 증상/제품 북마크 (로컬 + 계정 동기화) |

### 3.2 서브 기능 (Secondary — iOS 4.2 통과 & 재방문의 핵심)
| ID | 기능 | 설명 |
|---|---|---|
| S1 | 육아 트래킹 | 수유(모유/분유/이유식), 수면, 배변(기저귀) 기록. 시간·양·메모 |
| S2 | 트래킹 요약 | 오늘/최근 7일 타임라인 및 간단 통계(횟수/총량/평균 간격) |
| S3 | 아기 프로필 | 이름·생년월일·성별. 다둥이 대비 복수 프로필 |
| S4 | 로컬 알림 | "다음 수유 예상", "밤중 기록 리마인더" 등 사용자 설정 알림 |

> **왜 트래킹이 핵심인가**: 트래킹은 "웹에선 못 하는, 앱에서만 되는 개인 데이터 기능"이라 애플 4.2(단순 링크모음) 리젝을 방어하고, 매일 여는 이유(재방문)를 만든다.

### 3.3 기본 기능 전체 목록 (당신이 언급 안 했어도 앱이라면 필수)
**인증/계정 — 게스트 우선(Guest-first)**
- **첫 진입은 게스트**: Supabase **익명 로그인(anonymous sign-in)** 으로 자동 세션 생성 → 검색·상세·즐겨찾기·트래킹까지 전부 즉시 사용 가능(회원가입 관문 없음)
- **계정 연결(승격)**: 익명 세션에 Apple/Google/이메일을 `linkIdentity()`로 연결 — `user_id`가 유지되므로 게스트 시절 기록·즐겨찾기가 그대로 계정 데이터가 됨(이관 불필요)
- 연결 유도 시점: 설정 화면 상단 배너 + 기록 n건 도달 시 1회 시트("기록을 안전하게 백업하세요") — 강제 아님
- 이메일 회원가입 / 로그인 / 비밀번호 재설정
- 소셜 로그인: Apple(iOS 필수), Google
- 로그아웃
- **계정 삭제**(앱 내에서 완결 — Apple·Google 스토어 필수 요건). 삭제 시 서버 데이터 파기 + 확인 2단계
- 세션 유지 / 토큰 자동 갱신 / 만료 처리
- 익명 계정 정리: 장기 미접속 익명 유저는 스케줄 함수로 주기 삭제(auth 테이블 비대화 방지)

**시스템/설정**
- 라이트 / 다크 / 시스템 테마 (즉시 반영, 선택 저장)
- 푸시 알림 on/off (카테고리별), 권한 프라이밍(요청 전 이유 설명)
- 언어(현재 한국어 고정, i18n 구조만 마련)
- 앱 버전·정보, 오픈소스 라이선스 고지
- 문의/피드백(이메일 or 폼)
- 개인정보처리방침 · 이용약관 링크(스토어 필수)
- 데이터/트래킹 동의(수집 항목 고지)

**품질/견고성**
- 온보딩(첫 실행 3장 + 스킵)
- 스플래시 화면
- 빈 상태(Empty) / 에러 / 오프라인 상태 화면 — 각 화면마다
- 스켈레톤 로딩(제품·리스트)
- Pull-to-refresh
- 네트워크 상태 감지 및 안내
- 강제 업데이트 / 점검(maintenance) 모드 (원격 플래그)
- 크래시 리포팅 · (프라이버시 존중) 애널리틱스
- 딥링크(앱 스킴/유니버설 링크) — 특정 증상으로 바로 진입
- 접근성: 동적 글자 크기 대응, 색 대비 WCAG AA, 스크린리더 라벨, 최소 터치타깃
- 햅틱 피드백

### 3.4 v1.1+ 후보 기능 (MVP 제외 — 트렌드 반영 로드맵)
> MVP 범위를 지키되, 트래커 앱 시장에서 검증된 재방문·차별화 장치를 로드맵으로 명시해 둔다.

| 후보 | 내용 | 비고 |
|---|---|---|
| 홈 화면 위젯 | 마지막 수유 시각·다음 예상 시각을 홈 위젯으로 표시(`home_widget`) | 트래커 앱 재방문 견인 1순위, iOS/Android 모두 |
| iOS Live Activities | 수유·수면 **진행 타이머**를 잠금화면/Dynamic Island에 표시(ActivityKit) | 새벽 사용 맥락에 최적. 네이티브 Swift 코드 필요 |
| 울음 패턴 참고 분석 | 온디바이스 오디오 분류로 "배고픔/불편/졸림" **참고 힌트** 제공 | **의료적 단정 절대 금지** — 참고용 명시 필수, 심사·법적 검토 후에만 |
| 프리미엄 통계 | 수면 패턴 차트·주간 리포트 등 구독형 심화 통계 | 수익 다변화(제휴 수수료 단일 의존 완화) |

---

## 4. 정보구조(IA) · 화면 목록 · 내비게이션

### 4.1 내비게이션 구조
하단 탭바 3개(엄지존) + 각 탭 내 스택:

```
BottomNav
├── [탭1] 홈(증상)      Home
│     ├─ 검색           Search
│     └─ 증상 상세       SymptomDetail ─→ (외부 브라우저: 쿠팡)
├── [탭2] 기록          Tracking
│     ├─ 기록 추가/편집   TrackingEntry
│     └─ 요약            TrackingSummary
└── [탭3] 내 정보        Profile
      ├─ 아기 프로필      BabyProfile
      ├─ 즐겨찾기         Favorites
      └─ 설정            Settings
            ├─ 테마
            ├─ 알림
            ├─ 계정(로그아웃/계정삭제)
            └─ 약관/정책/정보
```

앱 외곽(탭바 밖) 플로우: 스플래시 → (첫 실행) 온보딩 → **홈(게스트 — 익명 세션 자동 생성)**. 인증 화면은 관문이 아니라 "계정 연결이 필요한 순간"(설정·동기화 유도 시트)에만 진입한다(§2-8, §3.3). 알림 권한 프라이밍도 첫 실행에 끼워넣지 않고 **첫 기록 저장 직후** 등 맥락 있는 시점에 노출(수락률↑).

### 4.2 전체 화면 목록
스플래시, 온보딩, 로그인, 회원가입, 비밀번호재설정, 권한프라이밍, 홈, 검색, 증상상세, 기록홈, 기록추가/편집, 기록요약, 내정보, 아기프로필(목록/편집), 즐겨찾기, 설정, 계정관리, 약관뷰어, 그리고 공통 상태(빈/에러/오프라인) 컴포넌트.

---

## 5. 아키텍처 · 기술 스택

### 5.1 스택 요약
| 레이어 | 선택 | 비고 |
|---|---|---|
| 앱 | Flutter (Dart 3, Material 3 기반 커스텀) | iOS/Android 단일 코드 |
| 상태관리 | Riverpod 3 (flutter_riverpod + riverpod_annotation 코드젠) | 테스트 용이, 보일러플레이트 적음 |
| 모델/직렬화 | freezed + json_serializable | 불변 엔티티·sealed 상태 표현 |
| 라우팅 | go_router | 딥링크·중첩 스택 친화 |
| 백엔드 | Supabase (Postgres + Auth[익명 로그인 포함] + Edge Functions + Storage) | 발주자가 프로젝트 생성 |
| 로컬 저장 | **Drift(SQLite) 확정** — 트래킹/캐시 | 오프라인 우선. Isar는 유지보수 중단 상태(2026 기준)라 제외 |
| 외부 링크 | url_launcher (externalApplication 모드) | 쿠팡은 외부 브라우저로 |
| 애니메이션 | flutter_animate | shimmer/shake/fade 선언형 |
| 푸시 | firebase_messaging + flutter_local_notifications | 원격+로컬 |
| 환경변수 | envied (컴파일타임, 난독화) | §8 |
| 한글초성 | 커스텀 유니코드 로직(또는 hangul 패키지) | §11 검색 |
| 크래시 | Sentry 또는 Firebase Crashlytics | 선택 |

### 5.2 앱 내부 레이어 (Clean-ish, feature-first)
```
presentation (위젯/화면/상태)  →  application (usecase/notifier)  →  domain (엔티티/리포지토리 IF)  →  data (Supabase/로컬 구현)
```
- 화면은 도메인만 알고, 데이터 소스 교체(예: Supabase→다른 DB)가 화면에 영향 없게.
- 제품/증상 데이터는 **앱에 하드코딩 금지** — 항상 Supabase에서.

### 5.3 데이터 소스 원칙
- **읽기**: 앱은 Supabase의 캐시 테이블만 읽는다(파트너스 API를 앱이 직접 호출하지 않음).
- **쓰기(개인기록)**: 로컬 우선 저장 후 Supabase 동기화(오프라인에서도 기록 가능).
- **갱신(제품)**: Supabase Edge Function이 주기적으로 파트너스 API 호출 → 캐시 테이블 upsert.

---

## 6. 데이터 파이프라인 (쿠팡 파트너스 → Supabase → 앱)

### 6.1 흐름
```
① 쿠팡 파트너스 API (상품 검색 + 딥링크 생성, 내 트래킹 코드 포함)
        │  (Edge Function이 서버에서 호출, Secret Key는 서버에만)
② Supabase Edge Function  ─ pg_cron 으로 하루 1~2회 실행
③ Supabase DB (products 캐시 테이블 upsert: 썸네일·이름·가격·딥링크·증상태그)
④ Flutter 앱  ─ 캐시 테이블만 읽어 증상별 리스트 표시
⑤ 외부 브라우저 (url_launcher)  ─ 저장된 딥링크 오픈 → 수수료 집계
```

### 6.2 왜 크롤링이 아니라 API인가 (확정 결론)
- 쿠팡은 봇 차단(Akamai)이 강력해 성공률 30~60%로 불안정, 서비스 데이터 소스로 부적합.
- **크롤링한 원본 링크엔 내 트래킹 코드가 없어 수수료가 0원.** 수수료는 파트너스 딥링크로만 집계.
- 따라서 데이터 소스는 **파트너스 API의 상품검색 + 딥링크 생성** 엔드포인트로 확정.

### 6.3 갱신 전략 (확정: 배치 캐싱)
- 육아용품은 가격 급변이 적어 **하루 1~2회 배치 캐싱**이 최적.
- 딥링크는 시간이 지나도 유효하므로 배치 시 함께 생성해 저장(온디맨드 생성 불필요).
- rate-limit 대비: Edge Function에서 증상당 순차 호출 + 지수 백오프 + 실패 시 이전 캐시 유지.

### 6.4 착수 전 필수 (발주자)
파트너스 API 키(Access/Secret)는 가입 즉시 발급되지 않고 **"최종 승인"** 후 발급됨(과거 기준 판매금액 15만원 이상; 현재 기준은 파트너스 대시보드 확인). 개발 착수 전 이 승인을 받아 키를 확보할 것. 승인 전이라면: 초기엔 소량 상품을 **수동으로 큐레이션**해 Supabase에 직접 입력하는 폴백 모드로 앱을 먼저 완성하고, 승인 후 자동 파이프라인으로 전환하는 2단계 진행 권장.

---

## 7. Supabase 스키마 · RLS · Edge Function

> 아래 SQL은 Claude Code가 마이그레이션 파일로 생성한다. 발주자는 Supabase 대시보드 SQL 에디터에서 실행하거나 `supabase db push`로 적용.

### 7.1 테이블
```sql
-- 증상 마스터
create table symptoms (
  id            uuid primary key default gen_random_uuid(),
  slug          text unique not null,           -- 'colic', 'teething' ...
  name          text not null,                  -- '배앓이'
  chosung       text not null,                  -- 'ㅂㅇㅇ' (검색용, 저장 시 생성)
  aliases       text[] default '{}',            -- 동의어 ['가스', '영아산통']
  emoji_or_icon text,                            -- 아이콘 키
  order_index   int default 0,
  is_active     boolean default true,
  created_at    timestamptz default now()
);

-- 증상별 의학 참고정보 (섹션형)
create table symptom_infos (
  id          uuid primary key default gen_random_uuid(),
  symptom_id  uuid references symptoms(id) on delete cascade,
  summary     text not null,                    -- 2~3문장 요약
  sections    jsonb not null default '[]',      -- [{title, body}] 형태
  emergency   jsonb default '[]',               -- 응급신호 배열 [{sign, action}]
  updated_at  timestamptz default now()
);

-- 제품 캐시 (파트너스 API 결과, Edge Function이 upsert)
create table products (
  id             uuid primary key default gen_random_uuid(),
  symptom_id     uuid references symptoms(id) on delete cascade,
  coupang_pid    text not null,                 -- 쿠팡 상품 식별자
  title          text not null,
  image_url      text,
  price          int,
  rating         numeric,
  deeplink       text not null,                 -- 내 코드 포함 파트너스 링크
  rank_index     int default 0,
  is_active      boolean default true,
  fetched_at     timestamptz default now(),
  unique(symptom_id, coupang_pid)
);

-- 아기 프로필 (사용자 소유)
create table babies (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id) on delete cascade not null,
  name        text not null,
  birth_date  date,
  gender      text,                              -- 'male'|'female'|'na'
  created_at  timestamptz default now()
);

-- 육아 기록
create table tracking_logs (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id) on delete cascade not null,
  baby_id     uuid references babies(id) on delete cascade,
  type        text not null,                     -- 'feed'|'sleep'|'diaper'
  subtype     text,                              -- feed: 'breast'|'formula'|'solid' 등
  amount      numeric,                           -- ml, 분 등
  note        text,
  started_at  timestamptz not null,
  ended_at    timestamptz,
  created_at  timestamptz default now()
);

-- 즐겨찾기
create table favorites (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id) on delete cascade not null,
  target_type text not null,                     -- 'symptom'|'product'
  target_id   uuid not null,
  created_at  timestamptz default now(),
  unique(user_id, target_type, target_id)
);

-- 원격 설정(강제 업데이트/점검 모드)
create table app_config (
  key   text primary key,                        -- 'min_version_ios' 등
  value jsonb not null
);
```

### 7.2 RLS (Row Level Security) 정책
```sql
-- 공개 읽기(마스터 데이터)
alter table symptoms       enable row level security;
alter table symptom_infos  enable row level security;
alter table products       enable row level security;
alter table app_config     enable row level security;
create policy "public read symptoms"      on symptoms      for select using (true);
create policy "public read symptom_infos" on symptom_infos for select using (true);
create policy "public read products"      on products      for select using (is_active);
create policy "public read app_config"    on app_config    for select using (true);

-- 개인 데이터: 본인 것만
alter table babies        enable row level security;
alter table tracking_logs enable row level security;
alter table favorites     enable row level security;
create policy "own babies"    on babies        for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own logs"      on tracking_logs for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own favorites" on favorites     for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
```
> products 테이블에 대한 쓰기는 **service_role 키를 가진 Edge Function만** 수행(클라이언트 쓰기 정책 없음).
>
> **익명(게스트) 사용자와 RLS**: Supabase 익명 로그인도 `auth.uid()`가 발급되므로 위 정책이 **수정 없이 그대로 동작**한다. 이후 `linkIdentity()`로 계정을 연결해도 `user_id`가 유지되어 데이터 이관이 필요 없다. JWT의 `is_anonymous` 클레임으로 익명 여부를 구분할 수 있으므로, 필요 시 특정 정책에서 익명을 제외하는 것도 가능.

### 7.3 Edge Function — 제품 갱신 (의사코드)
```ts
// supabase/functions/refresh-products/index.ts
// 트리거: pg_cron (하루 1~2회) 또는 수동 호출
// 비밀값: Deno.env.get('COUPANG_ACCESS_KEY' | 'COUPANG_SECRET_KEY')  ← Supabase Secrets에만 존재
serve(async () => {
  const symptoms = await db.from('symptoms').select('*').eq('is_active', true);
  for (const s of symptoms) {
    const keyword = mapSymptomToKeyword(s);              // 증상→검색 키워드
    const items = await coupangSearch(keyword);          // 파트너스 상품검색 API (HMAC 서명)
    const withLinks = await Promise.all(
      items.slice(0, N).map(async (it) => ({
        ...it,
        deeplink: await coupangDeeplink(it.productUrl),  // 내 코드 포함 딥링크 생성
      }))
    );
    await db.from('products').upsert(
      withLinks.map((it, i) => ({
        symptom_id: s.id, coupang_pid: it.productId, title: it.productName,
        image_url: it.productImage, price: it.productPrice, deeplink: it.deeplink,
        rank_index: i, is_active: true, fetched_at: new Date().toISOString(),
      })),
      { onConflict: 'symptom_id,coupang_pid' }
    );
    await sleep(backoff());                               // rate-limit 회피
  }
  return new Response('ok');
});
```

### 7.4 pg_cron 스케줄
```sql
select cron.schedule(
  'refresh-products-daily',
  '0 5,17 * * *',                                  -- 매일 05:00, 17:00
  $$ select net.http_post(
       url := 'https://<PROJECT>.functions.supabase.co/refresh-products',
       headers := jsonb_build_object('Authorization', 'Bearer <SERVICE_ROLE_OR_SIGNED>')
     ); $$
);
```
> 위 SQL 대신 **Supabase 대시보드의 Cron UI**(Integrations → Cron)로 등록해도 된다(내부적으로 동일한 pg_cron). Authorization에 쓰는 키는 SQL에 평문으로 넣지 말고 **Supabase Vault**에 저장해 참조할 것.

---

## 8. 환경변수 · Config 설계 (앱/서버 분리, 나중에 값만 채우기)

### 8.1 핵심 원칙 — 어디에 무엇을 두는가
| 키 | 위치 | 이유 |
|---|---|---|
| `SUPABASE_URL` | **앱** (.env) | 공개돼도 됨 |
| `SUPABASE_ANON_KEY` | **앱** (.env) | RLS로 보호되는 공개 키 |
| `COUPANG_ACCESS_KEY` | **서버**(Supabase Secrets) | 유출 시 계정 오남용 → 앱에 절대 금지 |
| `COUPANG_SECRET_KEY` | **서버**(Supabase Secrets) | 위와 동일, 앱 디컴파일로 유출 위험 |
| FCM `google-services.json` / `GoogleService-Info.plist` | **앱**(클라이언트 config 파일) | 클라이언트용, 배포 정상 |
| FCM **서버 키 / 서비스계정 JSON** | **서버**(Supabase Secrets) | 푸시 발송용 비밀값, 앱 금지 |
| `SENTRY_DSN` | 앱 | 공개 가능(전송 전용) |

> **결론**: 앱에 들어가는 비밀은 사실상 Supabase URL/anon key뿐. 쿠팡·푸시발송 비밀은 전부 서버(Edge Function Secrets). 발주자가 나중에 값을 알려주면 **아래 두 곳만** 채우면 됨.

### 8.2 앱 측 — envied 사용 (컴파일타임·난독화)
`.env` (git 제외, `.gitignore`에 추가):
```
SUPABASE_URL=여기에_나중에
SUPABASE_ANON_KEY=여기에_나중에
SENTRY_DSN=여기에_나중에_또는_비움
```
`.env.example` (커밋용 템플릿, 값 없음):
```
SUPABASE_URL=
SUPABASE_ANON_KEY=
SENTRY_DSN=
```
`lib/config/env.dart`:
```dart
import 'package:envied/envied.dart';
part 'env.g.dart';

@Envied(path: '.env', obfuscate: true)
abstract class Env {
  @EnviedField(varName: 'SUPABASE_URL', obfuscate: true)
  static final String supabaseUrl = _Env.supabaseUrl;
  @EnviedField(varName: 'SUPABASE_ANON_KEY', obfuscate: true)
  static final String supabaseAnonKey = _Env.supabaseAnonKey;
  @EnviedField(varName: 'SENTRY_DSN', obfuscate: true, optional: true)
  static final String? sentryDsn = _Env.sentryDsn;
}
```
`lib/config/app_config.dart` — 앱 전역에서 이 한 곳만 참조:
```dart
class AppConfig {
  static String get supabaseUrl => Env.supabaseUrl;
  static String get supabaseAnonKey => Env.supabaseAnonKey;
  static String? get sentryDsn => Env.sentryDsn;
  // 원격 config(강제업데이트/점검)는 app_config 테이블에서 로드
}
```
> **발주자가 나중에 할 일**: `.env`의 3줄 값만 채우고 `flutter pub run build_runner build`로 `env.g.dart` 재생성 → 끝. 코드 수정 불필요.

### 8.3 서버 측 — Supabase Secrets
```bash
supabase secrets set COUPANG_ACCESS_KEY=... COUPANG_SECRET_KEY=...
supabase secrets set FCM_SERVICE_ACCOUNT="$(cat service-account.json)"
```
Edge Function에서 `Deno.env.get('COUPANG_ACCESS_KEY')`로 사용. 앱 코드/리포지토리에는 절대 포함하지 않음.

### 8.4 빌드 플레이버(선택)
`dev` / `prod` 플레이버 분리 시 `.env.dev`, `.env.prod`로 분기하고 `--dart-define=FLAVOR=prod`로 선택. 초기엔 단일 환경으로 시작 가능.

---

## 9. 디자인 시스템 — 페이퍼잉크 토큰

> **컨셉**: 한국 수묵(ink-wash). 순수 흰색/검은색을 쓰지 않는다. 배경은 얇은 한지(미색), 텍스트는 희석된 먹빛, 액센트는 청록 잉크. 그림자는 회색이 아니라 **따뜻한 먹빛 저투명도**로 종이가 겹친 느낌. 흔한 "크림+테라코타" 조합을 피하려고 액센트를 청록 잉크로 잡음(테라코타는 응급 경고 전용 의미색으로만).

### 9.1 컬러 토큰 (Light / Dark)
모든 색은 토큰명으로 참조. Flutter에서는 `AppColors` 클래스 + `ThemeExtension`으로 구현.

| 토큰 | 역할 | Light | Dark |
|---|---|---|---|
| `paper.bg` | 화면 배경(한지) | `#F3EEE3` | `#1A1815` |
| `paper.card` | 카드 표면 | `#FBF7EF` | `#232019` |
| `paper.raised` | 모달/시트/상단바 | `#FFFDF9` | `#2C281F` |
| `ink.900` | 주요 텍스트(먹) | `#26292B` | `#ECE7DC` |
| `ink.700` | 부제목 | `#474A45` | `#C7C1B4` |
| `ink.500` | 보조 텍스트 | `#736E64` | `#9C968A` |
| `ink.300` | 힌트/placeholder | `#A8A296` | `#6F6A5F` |
| `line` | 헤어라인 보더 | `#E7DFD1` | `#34302A` |
| `line.strong` | 강조 보더/hover | `#D6CBB8` | `#454038` |
| `accent` | 주 액센트(청록 잉크) | `#3E6B7A` | `#6FA0B0` |
| `accent.wash` | 액센트 옅은 배경 | `#E2EAEC` | `#22343A` |
| `accent.deep` | 눌림/강조 | `#2C5361` | `#8FB9C7` |
| `coral` | 응급/파괴적(감빛) | `#BC6448` | `#D9846A` |
| `coral.wash` | 응급 카드 배경 | `#F4E4DD` | `#3A2620` |
| `sage` | 성공/완료 | `#6F8A5F` | `#93AC82` |
| `sage.wash` | 성공 배경 | `#E7EDDF` | `#2A3324` |
| `amber` | 정보/새 배지 | `#C08A3E` | `#D8AC66` |

**대비 규칙**: 색 위 텍스트는 같은 계열 진한 톤 사용(순수 검정 금지). 본문 대비 WCAG AA(4.5:1) 이상.

### 9.2 타이포그래피
| 폰트 역할 | 폰트 | 용도 |
|---|---|---|
| Display(명조) | `Noto Serif KR` (또는 나눔명조) | 큰 제목·증상명 헤더 (수묵 감성, 절제해서만) |
| Body/UI(고딕) | `Pretendard` | 본문·버튼·라벨 전반 (가독성) |
| Data(모노) | `JetBrains Mono` | 트래킹 수치·시간 |

**타입 스케일 (모바일 dp)**
| 이름 | 크기 | 행간 | 폰트/굵기 | 용도 |
|---|---|---|---|---|
| display | 28 | 1.30 | 명조 700 | 온보딩/빈상태 큰 제목 |
| title | 22 | 1.35 | 명조 700 | 화면 제목, 증상 상세 헤더 |
| heading | 18 | 1.40 | Pretendard 600 | 섹션 제목 |
| bodyL | 16 | 1.60 | Pretendard 400 | 본문(기본) |
| body | 14 | 1.60 | Pretendard 400 | 보조 본문 |
| label | 15 | 1.20 | Pretendard 600 | 버튼/탭 라벨 |
| caption | 12 | 1.50 | Pretendard 500 | 캡션·메타 |
| data | 16 | 1.20 | 모노 500 | 수치/시간 |

### 9.3 여백 스케일 (4pt 기반, dp)
`2, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64`
- 화면 좌우 패딩: **20**
- 카드 내부 패딩: **16**
- 섹션 간 간격: **24**
- 리스트 아이템 간격: **12**
- 아이콘-텍스트 간격: **8**

### 9.4 모서리 반경(Radius, dp)
| 토큰 | 값 | 용도 |
|---|---|---|
| `r.xs` | 6 | 칩·작은 배지 |
| `r.sm` | 10 | 버튼·입력창 |
| `r.md` | 14 | 카드(기본) |
| `r.lg` | 20 | 바텀시트·다이얼로그 |
| `r.xl` | 28 | 히어로 카드·온보딩 일러스트 프레임 |
| `r.full` | 999 | 알약 버튼·FAB·아바타·탭 인디케이터 |

> **규칙**: 한 변만 있는 보더(border-left 등)엔 radius 0. 전체 보더에만 radius.

### 9.5 음영(Shadow / Elevation) — 페이퍼잉크
회색 그림자 금지. **따뜻한 먹빛(74,66,50) 저투명도**로 종이 겹침 표현. 다크모드는 근검정 그림자 + 상단 1px 하이라이트로 카드를 띄움.

| 레벨 | 용도 | Light | Dark |
|---|---|---|---|
| e0 | 화면 배경 | 없음 | 없음 |
| e1 | 카드 | `0 1px 2px rgba(74,66,50,.06), 0 1px 1px rgba(74,66,50,.04)` + 헤어라인 `line` | `0 1px 2px rgba(0,0,0,.4)` + top inset `0 1px 0 rgba(255,255,255,.04)` |
| e2 | 상단바/스티키/눌린 카드 | `0 2px 8px rgba(74,66,50,.08), 0 1px 3px rgba(74,66,50,.05)` | `0 2px 10px rgba(0,0,0,.5)` |
| e3 | 바텀시트·다이얼로그 | `0 8px 24px rgba(74,66,50,.10), 0 2px 6px rgba(74,66,50,.06)` | `0 10px 30px rgba(0,0,0,.6)` |
| e4 | FAB·스낵바 | `0 6px 16px rgba(74,66,50,.14)` | `0 8px 20px rgba(0,0,0,.55)` |
| press | 눌림(오목) | inset `0 1px 3px rgba(74,66,50,.08)` | inset `0 1px 3px rgba(0,0,0,.5)` |

### 9.6 아이콘·일러스트
- 아이콘: 라인 스타일(2dp stroke), 둥근 끝. 크기 20(인라인)/24(주요)/28(탭바).
- 일러스트/빈상태: 수묵 번짐 느낌의 단색 라인 드로잉(붓 터치). 과한 컬러 금지.
- 탭바 아이콘: 비활성 `ink.300`, 활성 `accent` + 미세 채움.

### 9.7 모션 토큰(공통 값)
| 토큰 | 값 | 용도 |
|---|---|---|
| `dur.instant` | 100ms | 탭 반응 시작 |
| `dur.fast` | 180ms | 상태 전환·크로스페이드 |
| `dur.base` | 260ms | 진입/슬라이드 |
| `dur.slow` | 400ms | 흔들기·강조 |
| `dur.shimmer` | 1200ms | 스켈레톤 반짝임(반복) |
| `curve.spring` | `Curves.easeOutBack` | 탭 스프링 복귀 |
| `curve.enter` | `Curves.easeOutCubic` | 진입 |
| `curve.exit` | `Curves.easeInCubic` | 이탈 |
| `curve.standard` | `Curves.easeInOut` | 일반 |

> **접근성**: 시스템 "동작 줄이기(reduce motion)"가 켜지면 흔들기/반짝임/스프링을 **즉시 완료 또는 단순 페이드**로 대체(`MediaQuery.disableAnimations` 확인).

---

## 10. 애니메이션 시스템 — 컴포넌트별 (흔들기 · 반짝임 등)

> 구현: `flutter_animate` 선언형 API. 예시 문법:
> ```dart
> // 진입: 페이드+슬라이드업
> widget.animate().fadeIn(duration: 260.ms, curve: Curves.easeOutCubic)
>       .slideY(begin: .08, end: 0, curve: Curves.easeOutCubic);
> // 반짝임(스켈레톤): 반복
> skeleton.animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: highlight);
> // 흔들기(에러): 트리거 시
> field.animate(target: hasError ? 1 : 0).shake(hz: 4, curve: Curves.easeInOut, duration: 400.ms);
> ```

### 10.1 전역 인터랙션 (모든 탭 가능한 요소)
- **탭 스프링**: 누르는 순간 scale 1.0→0.96(100ms), 떼면 0.96→1.0 스프링(`easeOutBack`, 260ms). `GestureDetector`+`AnimatedScale` 또는 flutter_animate `scaleXY`.
- **잉크 워시 리플**: 기본 Material 리플 대신 `accent.wash`가 탭 지점에서 부드럽게 번짐(수묵 느낌). 커스텀 `InkResponse`/`splashFactory` 교체.
- **햅틱**: 주요 탭 `HapticFeedback.lightImpact()`, 토글 `selectionClick()`, 완료 `mediumImpact()`.

### 10.2 컴포넌트별 애니메이션 표
| 컴포넌트 | 애니메이션 | 파라미터 |
|---|---|---|
| 증상 카드(홈) | 진입 페이드+슬라이드업, 40ms stagger | fade 260ms / slideY .08 / `easeOutCubic` |
| 증상 카드 탭 | 스프링 + Hero(썸네일·제목이 상세로 morph) | scale .96, Hero 300ms |
| 제품 카드 로딩 | **반짝임(shimmer)** 스켈레톤 | 1200ms 반복, 45°, `paper.card`→highlight |
| 제품 카드 등장 | 스켈레톤→실제 크로스페이드 | 180ms |
| 제품 카드 탭 | 스프링 + 짧은 눌림 그림자(오목) | scale .96 / press shadow |
| 즐겨찾기(별) 탭 | **반짝임 강조(sparkle)**: 별 scale 1→1.3→1 + 작은 반짝이 회전 페이드아웃 | 420ms, `easeOutBack` |
| 로그인/입력 에러 | **흔들기(shake)** + 보더 `coral` + 라이트 햅틱 | hz 4, offset 3dp, 400ms |
| 빈 상태(검색결과 없음) | 일러스트 살짝 흔들림(한번) + 안내 페이드인 | shake 1회 300ms |
| 응급 경고 카드 | 등장 시 1회 미세 흔들림 + 좌측 바 `coral` 펄스(2회) | shake 1회 / opacity .5↔1 ×2 |
| 기록 완료(수유 등) | 체크 아이콘 그리기(draw) + 카운터 티커 상승 + 미디엄 햅틱 | draw 300ms / ticker 500ms |
| 탭 전환(하단탭) | fade-through(Material) + 아이콘 활성 색 트윈 | 200ms |
| 화면 전환(push) | shared-axis X(슬라이드+페이드) | 300ms |
| 바텀시트 등장 | 스프링 슬라이드업 + 배경 스크림 페이드 | slide 300ms `easeOutBack` / scrim 200ms |
| Pull-to-refresh | 수묵 잉크 드롭이 번지는 커스텀 인디케이터 | 잉크 원 확장 |
| 트래킹 수치 | 숫자 티커(count-up) | 500ms `easeOutCubic` |
| 토스트/스낵바 | 하단에서 슬라이드업 + 자동 페이드아웃 | in 200ms / out 200ms |
| 테마 전환 | 전체 색상 크로스페이드 | 300ms |
| FAB(기록 추가) | 진입 스케일인(스프링), 스크롤 시 확장/축소(라벨 접힘) | scale 300ms `easeOutBack` |

### 10.3 로딩·상태 전환 원칙
- 네트워크 대기 = 반드시 스켈레톤(빈 화면 금지) → iOS 4.2 "미완성" 리젝 방어에도 유리.
- 200ms 미만 작업엔 스피너/스켈레톤 표시하지 않음(깜빡임 방지).
- 에러 상태엔 "무엇이/어떻게 해결"을 인터페이스 목소리로(사과체 금지). 재시도 버튼 필수.

---

## 11. 화면별 상세 명세

> 표기: 색은 §9.1 토큰명, radius는 §9.4, 음영은 §9.5(e1~e4), 여백은 dp. "동작"은 탭/제스처별 결과를 명시.

### 11.0 공통 요소
- **상단바(AppBar)**: 높이 56, 배경 `paper.raised`, 스크롤 시 하단 헤어라인 `line` 1dp + e2. 제목 title(명조 22)은 좌측 정렬(중앙정렬 아님 — 한손 시선). 뒤로가기 아이콘 24, 좌측 패딩 16.
- **하단 탭바**: 높이 64 + 세이프에어리어. 배경 `paper.raised`, 상단 헤어라인 `line`. 아이콘 28, 라벨 caption 12. 활성 `accent`/비활성 `ink.300`. 탭 시 fade-through 200ms + 아이콘 색 트윈 + `selectionClick` 햅틱.
- **기본 버튼(Primary)**: 높이 52, radius `r.sm`(10), 배경 `accent`, 텍스트 label 15/`paper.raised`(흰끼), e2. press 시 배경 `accent.deep`+scale .97. 비활성 `ink.300` 배경.
- **보조 버튼(Ghost)**: 높이 52, radius `r.sm`, 투명 배경, 보더 1dp `line.strong`, 텍스트 `ink.700`.
- **입력창(TextField)**: 높이 52, radius `r.sm`, 배경 `paper.card`, 보더 1dp `line`(포커스 시 `accent` 1.5dp), placeholder `ink.300`, 내부 패딩 16. 에러 시 보더 `coral` + 흔들기(§10.2) + 하단 caption `coral`.
- **카드**: 배경 `paper.card`, radius `r.md`(14), e1(+헤어라인), 내부 패딩 16.
- **엣지-투-엣지**: Android 15+(targetSdk 35)는 엣지-투-엣지가 기본 강제 — 모든 화면 상하단을 `SafeArea`/인셋으로 처리하고, 탭바·바텀시트 높이는 세이프에어리어 포함으로 계산. 시스템 바 아이콘 대비는 테마별로 지정.

### 11.1 스플래시
- **레이아웃**: 중앙에 앱 로고(수묵 물방울+아기 실루엣, 96×96). 배경 `paper.bg`.
- **동작**: 세션·원격config(강제업데이트/점검) 체크 후 분기. 최소 표시 600ms(깜빡임 방지).
- **애니메이션**: 로고 잉크 드롭이 번지듯 scale .8→1 + fadeIn 400ms. 완료 시 다음 화면 fade-through.

### 11.2 온보딩 (첫 실행, 3장 + 스킵)
- **레이아웃**: 상단 우측 "건너뛰기"(caption, `ink.500`). 중앙 일러스트 프레임(radius `r.xl`, 배경 `accent.wash`). 하단 제목 display 28(명조) + 본문 bodyL `ink.500`. 페이지 인디케이터(점 3개, 활성 `accent` 알약형). 하단 기본 버튼("다음"/마지막 "시작하기").
- **3장 내용**: ① 증상으로 빠르게 찾기 ② 필요한 육아용품 바로 보기 ③ 수유·수면 기록까지.
- **동작**: 좌우 스와이프 or "다음" 탭 → 페이지 이동. "시작하기" → **곧장 홈(게스트 진입 — 내부적으로 익명 세션 자동 생성)**. "건너뛰기" → 곧장 홈. 여기서 회원가입/로그인을 강제하지 않는다(§2-8).
- **애니메이션**: 페이지 전환 시 일러스트 parallax(살짝 느리게 이동), 텍스트 fadeIn+slideY. 인디케이터 활성 점 width 트윈(원→알약).

### 11.3 로그인 / 계정 연결
> **진입 맥락**: 첫 실행 관문이 아니다. 설정 → "계정 연결", 또는 동기화 유도 시트에서 진입한다. 익명 세션에 계정을 연결(`linkIdentity`)하면 게스트 시절 기록·즐겨찾기가 그대로 유지된다 — 화면에 "지금까지의 기록은 안전하게 유지돼요" 안내 문구 노출.

- **레이아웃(위→아래)**: 로고(작게 64), title "다시 오셨네요", 이메일 입력, 비밀번호 입력(우측 눈 아이콘 토글), "비밀번호 찾기"(우측정렬 caption `accent`), 기본 버튼 "로그인", 구분선("또는"), 소셜 버튼 2개(Apple/Google, 높이 52 radius `r.sm` 보더형), 하단 "회원가입"(text `accent`).
- **동작**:
  - 눈 아이콘 탭 → 비밀번호 표시/숨김 토글(`selectionClick`).
  - "로그인" 탭 → 유효성 검사 → 실패 시 해당 필드 **흔들기** + 하단 에러 caption `coral` + 라이트 햅틱. 성공 시 로딩(버튼 내 스피너) → 홈 이동.
  - Apple/Google 탭 → OAuth 시트. (iOS는 Apple 필수)
  - "회원가입" 탭 → 회원가입 화면(shared-axis X).
- **애니메이션**: 진입 시 요소 stagger fadeIn+slideY. 버튼 로딩 중 라벨→스피너 크로스페이드.

### 11.4 회원가입
- **레이아웃**: 이메일, 비밀번호(강도 표시 바), 비밀번호 확인, 약관 동의 체크(필수/선택 구분, 링크 탭 시 약관뷰어), 기본 버튼 "가입하기".
- **동작**: 비밀번호 입력 시 강도 바 색 트윈(약 `coral`→중 `amber`→강 `sage`). 약관 미동의 시 버튼 비활성. 가입(계정 연결) 성공 → 진입했던 화면으로 복귀 + 성공 토스트("계정이 연결됐어요").
- **애니메이션**: 강도 바 width/색 트윈 180ms. 체크박스 탭 시 체크 draw 애니메이션.

### 11.5 비밀번호 재설정
- **레이아웃**: 안내문(body `ink.500`), 이메일 입력, 기본 버튼 "재설정 링크 보내기", 전송 후 성공 상태(체크 일러스트 + "메일함을 확인하세요").
- **동작**: 전송 성공 시 버튼→성공 카드 크로스페이드, 미가입 이메일 등 에러는 흔들기+caption.

### 11.6 권한 프라이밍 (알림)
> **노출 시점**: 첫 실행 온보딩에 끼워넣지 않는다. **첫 기록 저장 직후**("다음 수유 시간을 알려드릴까요?") 또는 설정 → 알림 진입 시 — 맥락이 있을 때 요청해야 수락률이 오른다.

- **레이아웃**: 일러스트(종 아이콘 수묵풍), title "밤중에도 놓치지 않게", 본문(왜 알림이 필요한지 — 다음 수유 예상/기록 리마인더), 기본 버튼 "알림 켜기", ghost 버튼 "나중에".
- **동작**: "알림 켜기" → OS 권한 다이얼로그 호출. "나중에" → 스킵(설정에서 나중에 가능). **OS 다이얼로그를 곧바로 띄우지 않고 이 화면으로 이유를 먼저 설명**(수락률↑).
- **애니메이션**: 종 아이콘 살짝 흔들림(1회, 주의환기), 버튼 진입 스프링.

### 11.7 홈 (증상 그리드) — 앱의 얼굴
- **레이아웃(위→아래)**:
  1. 상단바: 좌측 인사("오늘도 힘내세요" title 명조 22 or 아기 이름), 우측 알림 벨 아이콘(24, 배지 dot `coral`).
  2. **검색 바**(고정, 엄지 닿기 쉽게 상단바 바로 아래): 높이 52, radius `r.full`, 배경 `paper.card`, e1, 좌측 돋보기 아이콘 20 `ink.500`, placeholder "배앓이, ㅂㅇㅇ …" `ink.300`. 탭 시 검색 화면으로 Hero 전환(검색바가 상단으로 morph).
  3. (선택) 최근 본 증상 가로 스크롤 칩 — 칩 높이 36 radius `r.full` 배경 `accent.wash` 텍스트 `accent`.
  4. **증상 카드 그리드**: 2열, 카드 간격 12, 카드 radius `r.md`, e1. 카드 내부: 상단 아이콘(수묵 라인 40×40, 배경 원 `accent.wash`), 하단 증상명 heading 18 `ink.900`. 카드 높이 ~120.
  5. 하단 탭바.
- **동작**:
  - 검색바 탭 → 검색 화면(§11.8), 검색바 Hero morph + 키보드 자동 포커스.
  - 증상 카드 탭 → 스프링 + Hero(아이콘·이름이 상세 헤더로 이동) → 증상 상세.
  - 벨 아이콘 탭 → (알림 목록 or 설정).
  - 아래로 당김 → Pull-to-refresh(잉크 드롭 인디케이터), 제품 캐시 최신화 트리거는 서버가 하므로 여기선 재조회만.
  - 스크롤 다운 → 검색바는 고정(sticky), 상단 인사는 스크롤아웃.
- **애니메이션**: 첫 로드 시 카드 grid stagger fadeIn+slideY(40ms 간격). 로딩 중엔 카드 스켈레톤(반짝임).

### 11.8 검색 (초성/부분 매칭)
- **레이아웃**: 상단 검색 입력(자동 포커스, 좌측 뒤로가기, 우측 X 지우기), 아래 실시간 결과 리스트. 결과 없을 때 빈 상태.
- **초성 로직**: 한글 음절에서 초성 추출(유니코드: 초성index = ((code−0xAC00) ~/ 588)). "ㅂㅇㅇ"→초성열 매칭, "배앓"→부분일치, 동의어(aliases)도 포함. 대소문자·공백 무시.
- **동작**:
  - 타이핑 시 200ms 디바운스 후 필터. 결과 항목 탭 → 증상 상세.
  - X 탭 → 입력 클리어 + 재포커스.
  - 최근 검색어 저장(로컬), 항목 좌스와이프로 개별 삭제.
- **애니메이션**: 결과 리스트 항목 fadeIn(빠르게 120ms). 매칭된 글자 하이라이트(`accent` 볼드). 빈 상태 일러스트 1회 흔들림.

### 11.9 증상 상세 — 정보 + 제품 (수익 화면)
- **레이아웃(위→아래)**:
  1. 헤더: 증상 아이콘(Hero, 56) + 증상명 title 명조 22 + 우측 즐겨찾기 별(24).
  2. **요약 카드**: 배경 `paper.card`, radius `r.md`, e1, 본문 bodyL `ink.700` 2~3문장.
  3. (해당 시) **응급 경고 카드**: 배경 `coral.wash`, 좌측 4dp 바 `coral`(radius 0), 아이콘 `coral`, 제목 "이럴 땐 병원에", 본문 응급신호 + "가까운 병원 찾기" 버튼(탭 시 지도/전화 연결). 정보 최상단(요약 바로 아래) 노출.
  4. 정보 섹션들: 아코디언 or 단순 나열(heading 18 + body). 섹션 예: 원인, 집에서 돌보기, 주의점.
  5. **의학 면책 문구**(caption `ink.500`): "본 정보는 의학적 진단이 아니며 참고용입니다. 증상이 우려되면 소아과 전문의와 상담하세요."
  6. **추천 제품 섹션**:
     - 섹션 헤더 heading "이럴 때 도움되는 용품" + **대가성 표시 배지**(바로 아래, 눈에 띄게): caption, 배경 `amber` 옅은 톤, "쿠팡 파트너스 활동으로 수수료를 받습니다".
     - 제품 카드 리스트(세로): 카드 높이 ~96, radius `r.md`, e1. 좌측 썸네일 72×72 radius `r.sm`, 우측 제목 body 2줄(말줄임) + 가격 data 16 `ink.900` + (있으면) 별점 caption. 우측 끝 외부링크 아이콘 16 `ink.300`.
  7. 하단: 없음(탭바 유지).
- **동작**:
  - 별 탭 → 즐겨찾기 토글 + **반짝임 강조(sparkle)** + 라이트 햅틱.
  - 응급 "병원 찾기" 탭 → 지도앱/전화 연결(외부).
  - **제품 카드 탭 → `url_launcher`(externalApplication)로 저장된 딥링크를 외부 브라우저에서 오픈** + 스프링/눌림 그림자 + 라이트 햅틱. (앱 내 웹뷰 아님 — 4.2 방어 & 수수료 트래킹)
  - 섹션 아코디언 탭 → 펼침/접힘(높이 트윈 260ms).
- **애니메이션**: 제품 로딩 시 카드 스켈레톤(반짝임)→크로스페이드. 응급 카드 등장 시 1회 미세 흔들림 + 좌측 바 펄스 2회. 섹션 진입 stagger fadeIn.

### 11.10 기록 홈 (트래킹) — 재방문 엔진
- **레이아웃(위→아래)**:
  1. 상단바: 아기 이름/전환 드롭다운(다둥이), 우측 요약(캘린더) 아이콘.
  2. **오늘 요약 밴드**: 3개 미니 카드 가로(수유/수면/기저귀). 각 카드 배경 `paper.card` radius `r.md` e1, 아이콘 + 라벨 caption + 수치 data 16. 예: 수유 "5회", 수면 "3시간".
  3. **빠른 기록 버튼 3개**(큰 터치타깃, 엄지존): 알약형 radius `r.full`, 높이 56, 아이콘+라벨. 배경 `accent.wash` 텍스트 `accent`.
  4. **오늘 타임라인**: 시간 역순 리스트. 각 항목: 좌측 시간 data, 타입 아이콘(수유/수면/기저귀 색 구분), 내용 body, 우측 "…" 편집. 항목 좌스와이프 → 삭제.
  5. 우하단 **FAB**(+): radius `r.full`, 배경 `accent`, e4. 탭 시 기록 추가 시트.
- **동작**:
  - 빠른 기록 버튼 탭 → 해당 타입 기록 시트(사전값 채워짐). 저장 시 완료 애니메이션 + 미디엄 햅틱 + 요약 수치 티커 상승.
  - FAB 탭 → 타입 선택 후 상세 입력 시트.
  - 타임라인 항목 탭 → 편집. 좌스와이프 → 삭제(확인 스낵바 "실행취소" 포함).
  - 아기 드롭다운 → 프로필 전환(즉시 데이터 리로드).
  - 요약 아이콘 탭 → 기록 요약(§11.11).
- **애니메이션**: FAB 스크롤 시 확장/축소(라벨 접힘). 새 기록 추가 시 타임라인 상단에 slideIn+fadeIn. 완료 시 체크 draw + 카운터 티커.

### 11.11 기록 추가/편집 (바텀시트)
- **레이아웃**: 바텀시트(radius 상단 `r.lg`, 배경 `paper.raised`, e3, 상단 그랩바 32×4 `line`). 타입 세그먼트(수유/수면/기저귀), 타입별 폼:
  - 수유: 방식(모유/분유/이유식) 칩 선택, 양(ml) 스텝퍼 or 숫자, 시작시간 피커, 메모. 모유는 **타이머 모드**(좌/우 선택 + 시작→종료) 지원.
  - 수면: **타이머 모드가 기본**("잠들었어요" 탭 → 진행 중 → "깼어요" 탭 시 시간 자동 계산) + 시작·종료 직접 입력 폴백, 메모.
  - 기저귀: 소/대/혼합 칩, 시간.
- **동작**: 시간 기본값=현재. 스텝퍼 +/− 탭 시 값 트윈 + `selectionClick`. "저장" 탭 → 시트 닫힘(슬라이드다운) + 완료 햅틱 + 타임라인 반영. "삭제"(편집 시) → 확인 다이얼로그.
- **진행 중 상태**: 타이머 시작 후 시트를 닫아도 유지 — 기록 홈 요약 밴드에 "수면 진행 중 · 1:23" 배지(경과시간 티커) 노출, 탭 시 종료 시트. 앱 재시작에도 복원(로컬 저장). (v1.1: Live Activities/Dynamic Island 연동 — §3.4)
- **애니메이션**: 시트 등장 스프링 슬라이드업 + 스크림 페이드. 세그먼트 전환 시 폼 크로스페이드. 칩 선택 시 배경 색 트윈 + 미세 스케일.

### 11.12 기록 요약
- **레이아웃**: 기간 탭(오늘/7일/30일), 타입별 통계 카드(횟수·총량·평균 간격), 간단 막대/라인 그래프(수묵 톤). 하단 일자별 리스트.
- **동작**: 기간 탭 전환 → 데이터·그래프 리로드(크로스페이드). 그래프 바 탭 → 해당 일 상세.
- **애니메이션**: 그래프 바 높이 grow(아래→위) stagger. 통계 수치 티커.

### 11.13 내 정보 (탭3 루트)
- **레이아웃**: 상단 프로필 헤더(아바타 원 64, 이름, 이메일), 메뉴 리스트(아기 프로필, 즐겨찾기, 설정, 문의). 각 행 높이 56, 좌측 아이콘 24, 우측 chevron `ink.300`.
- **동작**: 행 탭 → 해당 화면(push). 아바타 탭 → 프로필 편집.
- **애니메이션**: 행 탭 시 잉크 워시 리플.

### 11.14 아기 프로필 (목록 + 편집)
- **레이아웃**: 아기 카드 리스트(이름·생년월일·개월수 자동계산), 하단 "아기 추가" ghost 버튼. 편집 화면: 이름 입력, 생년월일 피커, 성별 세그먼트, 삭제 버튼.
- **동작**: 카드 탭 → 편집. "추가" → 신규 폼. 삭제 → 확인 다이얼로그(관련 기록 처리 안내).
- **애니메이션**: 카드 진입 stagger. 개월수 배지 페이드인.

### 11.15 즐겨찾기
- **레이아웃**: 세그먼트(증상/제품). 증상=그리드(홈과 동일 카드), 제품=리스트(상세와 동일 카드). 빈 상태 각각.
- **동작**: 항목 탭 → 해당 상세/외부링크. 별 탭 → 즐겨찾기 해제(sparkle 반대 = 페이드아웃 후 리스트에서 제거, "실행취소" 스낵바).
- **애니메이션**: 해제 시 항목 collapse+fadeOut.

### 11.16 설정
- **레이아웃(그룹형 리스트)**:
  - 화면: **테마**(라이트/다크/시스템 세그먼트), 글자 크기(시스템 따름 안내).
  - 알림: 마스터 토글 + 카테고리 토글(수유 리마인더/공지). 권한 꺼져있으면 안내+설정 이동.
  - 계정: (게스트일 때) 최상단 **"계정 연결" 배너**(`accent.wash` 배경, "기록을 안전하게 백업하세요") / (연결 후) 로그아웃, **계정 삭제**(강조 `coral` 텍스트).
  - 정보: 개인정보처리방침, 이용약관, 오픈소스 라이선스, 앱 버전, 문의.
- **동작**:
  - 테마 세그먼트 탭 → 즉시 전체 테마 크로스페이드(300ms) + 선택 저장.
  - 토글 탭 → 스위치 트랙 색 트윈 + `selectionClick`.
  - 로그아웃 탭 → 확인 다이얼로그 → 세션 종료 → 인증 화면.
  - **계정 삭제 탭 → 2단계 확인**(다이얼로그: "모든 기록이 삭제됩니다" → 재확인 입력/체크) → 서버 계정·데이터 파기 → 스플래시/온보딩. (스토어 필수 요건)
  - 정책/약관 탭 → 인앱 뷰어 or 외부.
- **애니메이션**: 세그먼트 인디케이터 슬라이드, 스위치 thumb 이동 + 색 트윈.

### 11.17 공통 상태 컴포넌트
- **빈 상태**: 중앙 수묵 라인 일러스트(120) + display/body 안내 + (있으면) 행동 버튼. 진입 시 일러스트 1회 미세 흔들림 + 텍스트 fadeIn. 문구는 "무엇을 하면 되는지"를 담음(예: "아직 기록이 없어요 · 아래 + 로 첫 기록을 남겨보세요").
- **에러 상태**: 아이콘 `coral` + 무엇이 잘못됐는지 + "다시 시도" 버튼. 사과체 금지, 원인·해결 중심.
- **오프라인**: 상단 슬림 배너(배경 `amber` 옅은 톤, "오프라인 상태예요 · 기록은 저장 후 자동 동기화됩니다"). 네트워크 복구 시 배너 슬라이드업 사라짐 + 동기화 티커.
- **스켈레톤**: 실제 레이아웃과 동일 형태의 회색 블록(반짝임 1200ms 반복).

---

## 12. 역할 분담 — Claude Code vs 당신(발주자)

### 12.1 당신(발주자)이 직접 해야 할 일
1. **Supabase 프로젝트 생성** → `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `service_role` 키 확보.
2. **쿠팡 파트너스 가입 + 최종 승인** → `COUPANG_ACCESS_KEY`, `COUPANG_SECRET_KEY` 확보(승인 전이면 §6.4 폴백으로 진행).
3. **Firebase 프로젝트 생성**(푸시) → `google-services.json`(Android), `GoogleService-Info.plist`(iOS), 서버용 서비스계정 JSON 확보.
4. **Apple Developer 계정**($99/년) + **Google Play Console**($25 1회) 등록. ⚠️ **개인 Play 계정은 신규 앱 프로덕션 출시 전 비공개 테스트(테스터 12명 × 14일 연속 opt-in) 통과가 선행 요건** — 테스터(가족·지인·맘카페 등) 모집을 미리 준비할 것(정확한 인원 요건은 제출 시점에 콘솔에서 확인).
5. **Supabase Secrets 등록**: 쿠팡 키·FCM 서비스계정을 `supabase secrets set`으로(§8.3). Claude Code가 명령어를 제공.
6. **`.env` 값 채우기**: Claude Code가 만든 `.env`에 URL/anon key 3줄 입력 → `build_runner` 1회 실행(§8.2).
7. **SQL 마이그레이션 적용**: Claude Code가 만든 마이그레이션을 대시보드/CLI로 실행.
8. **증상·의학정보 콘텐츠 입력**: 증상 목록과 각 증상의 요약/섹션/응급신호를 최종 검수·입력(의학 정보는 사람이 검증). 초기 제품은 승인 전이면 수동 큐레이션.
9. **개인정보처리방침·이용약관 텍스트** 준비(생성 도움은 가능하나 최종 책임은 발주자).
10. **스토어 제출**: 스크린샷·설명·심사노트 작성 후 제출(Claude Code가 4.2 대응 심사노트 초안 제공).

### 12.2 Claude Code가 하는 일 (전부 위임)
- Flutter 프로젝트 스캐폴딩(폴더구조·라우팅·테마·상태관리).
- §9 디자인 시스템 전체 구현(색 토큰·타이포·radius·음영을 `ThemeExtension`으로).
- §10 애니메이션 전부(flutter_animate 컴포넌트별 흔들기/반짝임/스프링).
- §11 모든 화면·컴포넌트·인터랙션 구현.
- Supabase 클라이언트 연동, RLS 전제한 데이터 접근 레이어.
- **Edge Function 코드**(파트너스 API 호출·딥링크 생성·upsert) + SQL 마이그레이션 + pg_cron 스크립트 작성.
- envied 기반 env 설정 구조(값은 비워둠 — 발주자가 나중에 입력).
- 초성 검색 로직, 로컬 저장(오프라인), 푸시(클라이언트), 계정삭제 플로우, 강제업데이트/점검 처리.
- 빈/에러/오프라인/스켈레톤 상태, 접근성(폰트 스케일·대비·터치타깃·reduce motion).
- 스토어 제출용 심사노트/개인정보 라벨 초안.

> **경계**: Claude Code는 "키가 필요한 실제 연동"까지 코드로 완성하되, **실제 키 값 주입·외부 계정 생성·콘텐츠 최종검수·스토어 제출**은 발주자 몫. 값만 채우면 바로 동작하도록 설계됨.

---

## 13. 법적 · 정책 체크리스트

### 13.1 애플 App Store 4.2 (단순 링크모음 리젝 방어)
- [ ] 육아 트래킹(수유·수면·배변) 등 **웹으로 대체 불가한 네이티브 기능** 탑재 — 본 설계의 서브기능이 이를 충족.
- [ ] 오프라인 기록·로컬 알림·즐겨찾기 등 앱 고유 가치.
- [ ] 쿠팡은 **외부 브라우저**로 연결(앱 내 웹뷰로 감싸 리다이렉트하는 구조 지양).
- [ ] 심사노트에 트래킹·초성검색 등 네이티브 기능을 명시 + 데모 영상 첨부.

### 13.2 공정위 — 대가성 표시(표시광고법)
- [ ] 제품 리스트가 보이는 화면 상단에, '더보기'/설정 깊은 곳이 아니라 **바로 보이는 위치**에 대가성 문구.
- [ ] 문구 예: "쿠팡 파트너스 활동으로 수수료를 받습니다"(모호한 "소정의 수수료 지급 가능" 류 금지).
- [ ] 본문과 구분되게(색/크기) 표시.

### 13.3 의료/건강 정보
- [ ] 모든 증상 상세에 **의학 면책** 문구(진단 아님·참고용·전문의 상담).
- [ ] 특정 질환 단정·특정 약물/제품을 치료로 권하는 표현 금지.
- [ ] 응급신호(발열/호흡곤란/경련 등)는 병원 안내로 분리.

### 13.4 스토어 공통 필수
- [ ] **계정 삭제**를 앱 내에서 완결(Apple·Google 필수).
- [ ] **Sign in with Apple**: 다른 소셜 로그인을 iOS에서 제공하면 함께 제공(필수).
- [ ] **가입 강요 금지(Apple 5.1.1)**: 계정이 불필요한 콘텐츠(증상 정보·제품 열람)는 로그인 없이 접근 가능해야 함 — 본 설계의 게스트 우선 구조(§2-8, §3.3)가 이를 충족.
- [ ] **iOS Privacy Manifest**(`PrivacyInfo.xcprivacy`): 앱 + 서드파티 SDK의 required reason API·수집 데이터 선언(미비 시 제출 거부). 최신 Flutter 플러그인 버전 사용으로 대부분 충족.
- [ ] **Android 최신 타깃 요건**: targetSdkVersion 최신 유지(매년 8월 상향 — 제출 시점 콘솔 확인, 2026 기준 API 35+) + **16KB 메모리 페이지 지원**(최신 Flutter/NDK면 자동 충족).
- [ ] **Play 비공개 테스트 요건**(개인 개발자 계정): 테스터 12명 × 14일 — 출시 일정에 리드타임 반영(§12.1-4).
- [ ] 개인정보처리방침·이용약관 링크(앱·스토어 양쪽).
- [ ] 데이터 수집 라벨(App Privacy / Data safety) 정확히 기입.
- [ ] 아동 관련: 대상이 부모이므로 키즈 카테고리는 아님. 그러나 아동 데이터 수집 최소화.

---

## 14. 개발 마일스톤

| 단계 | 산출물 | 완료 기준 |
|---|---|---|
| M0 준비(발주자) | Supabase/파트너스/Firebase 계정, 키 확보 | §12.1 1~4 완료 |
| M1 스캐폴딩 | 프로젝트·테마·라우팅·디자인시스템 | 라이트/다크 토글, 탭바 동작 |
| M2 데이터 백엔드 | SQL 마이그레이션·RLS·Edge Function·pg_cron | 제품 캐시 upsert 동작(또는 수동 폴백) |
| M3 핵심 플로우 | 홈·초성검색·증상상세·제품→외부브라우저 | 딥링크로 쿠팡 연결·대가성/면책 표시 |
| M4 서브 기능 | 트래킹·요약·아기프로필·즐겨찾기 | 오프라인 기록·동기화 |
| M5 기본기능 | 익명→계정 연결(Apple/Google/이메일)·계정삭제·설정·푸시·상태화면 | 스토어 필수요건 충족 |
| M6 폴리시 | 애니메이션 폴리싱·접근성·성능·크래시 | reduce motion·AA 대비·스켈레톤 |
| M7 출시 | Android 먼저 → iOS(4.2 대응) | 심사 통과 |

> **권장**: Android를 먼저 내보내 검증하고, iOS는 트래킹 등 네이티브 기능을 충분히 보강한 뒤 제출(4.2 리스크 최소화). 단, 개인 Play 계정은 **비공개 테스트(12명×14일)가 프로덕션 출시의 선행 요건**이므로 M4 무렵부터 테스터 모집·비공개 트랙 배포를 병행할 것.

---

## 15. Claude Code 착수 프롬프트 (복붙용)

```
이 저장소에 "아가왜울어" Flutter 앱을 만든다. 첨부한 설계서(agawaeuleo_spec.md)를 단일 소스로 삼아라.
원칙:
- 모든 비밀키는 env로 분리하되 값은 비워둔다(.env + .env.example, envied 사용). 쿠팡/푸시발송 비밀은 앱에 넣지 말고 Supabase Edge Function Secrets 전제로 코드만 작성.
- 인증은 게스트 우선: 첫 진입은 Supabase 익명 로그인으로 자동 세션을 만들고, 계정 연결(linkIdentity)로 승격한다. 콘텐츠 열람에 로그인을 강제하지 않는다(§2-8, §3.3).
- 디자인은 설계서 §9 페이퍼잉크 토큰을 ThemeExtension으로 정확히 구현(색 hex·radius·음영 그대로). 라이트/다크 필수.
- 애니메이션은 §10 표대로 컴포넌트별로 flutter_animate로 구현(흔들기·반짝임·스프링). reduce motion 대응.
- 화면은 §11 명세대로. "누르면 무엇이 일어나는지"까지 구현.
- Supabase 스키마·RLS·Edge Function·pg_cron은 §7대로 마이그레이션/함수 파일로 생성.
- iOS 4.2 대비: 트래킹·초성검색 등 네이티브 기능 포함. 쿠팡은 url_launcher 외부 브라우저.
진행 순서는 §14 마일스톤을 따르되, 먼저 M1(스캐폴딩+디자인시스템)을 완성해 스크린샷으로 확인받고 다음 단계로.
착수 전, 내가 나중에 채워야 할 값 목록(.env 키, Supabase Secrets, 실행할 CLI 명령)을 README로 정리해라.
```

---

## 16. 부록

### 16.1 폴더 구조(제안)
```
lib/
  config/            env.dart, app_config.dart, theme/ (colors, typography, radius, shadows, motion)
  core/              utils(hangul_chosung.dart), network, error, haptics, analytics
  data/              supabase/, local(drift)/, repositories(impl)
  domain/            entities, repositories(interfaces)
  application/       notifiers(riverpod), usecases
  presentation/
    router/          go_router
    widgets/         buttons, cards, skeletons, states(empty/error/offline), animated/
    features/
      onboarding/ auth/ home/ search/ symptom_detail/
      tracking/ profile/ favorites/ settings/
  main.dart
supabase/
  migrations/        *.sql (schema, rls, cron)
  functions/refresh-products/  index.ts
assets/ fonts(Pretendard, NotoSerifKR, JetBrainsMono), illustrations(수묵), icons
.env  .env.example  (git 제외: .env, *.g.dart 일부, service-account.json)
```

### 16.2 주요 패키지
`flutter_riverpod`, `riverpod_annotation`, `go_router`, `supabase_flutter`, `drift`, `freezed` + `json_serializable`, `url_launcher`, `flutter_animate`, `firebase_core`, `firebase_messaging`, `flutter_local_notifications`, `envied` + `envied_generator`, `intl`, `sentry_flutter`(선택), `sign_in_with_apple`, `google_sign_in`, `flutter_native_splash`, `flutter_launcher_icons`.

> **폰트는 로컬 번들**(`assets/fonts`) — Pretendard는 Google Fonts에 없어 `google_fonts` 사용 불가이고, 오프라인·첫 렌더 성능 면에서도 로컬 번들이 낫다. (v1.1 후보: `home_widget`, `live_activities` — §3.4)

### 16.3 최종 체크리스트(요약)
- [ ] `.env` 3줄 값 입력 + build_runner 실행
- [ ] Supabase Secrets(쿠팡·FCM) 등록
- [ ] SQL 마이그레이션 적용 + pg_cron 스케줄
- [ ] 증상/의학정보 콘텐츠 입력·검수(의학 사실 사람이 확인)
- [ ] 대가성 표시·의학 면책·응급 트리아지 화면 확인
- [ ] 계정삭제·Sign in with Apple·개인정보처리방침 링크
- [ ] 게스트 우선 플로우 동작 확인(로그인 없이 검색→상세→제품, 계정 연결 시 데이터 유지)
- [ ] 트래킹 등 네이티브 기능으로 4.2 대비 + 심사노트/데모영상
- [ ] iOS Privacy Manifest · Android targetSdk/16KB · Play 비공개 테스트(12명×14일)
- [ ] 라이트/다크·reduce motion·AA 대비·스켈레톤 확인
- [ ] Android 먼저 출시 → iOS 보강 후 제출

### 16.4 변경 이력
- **v1.1 (2026-07)**
  1. **인증을 게스트 우선으로 전환**(익명 로그인 → `linkIdentity` 승격) — 새벽 사용 UX 개선 + Apple 5.1.1 방어 (§2-8, §3.3, §4.1, §11.2~11.4, §11.16)
  2. 로컬 DB **Drift 확정**(Isar 유지보수 중단으로 제외), `freezed` 추가, Riverpod 3 명시 (§5.1, §16.2)
  3. **스토어 최신 요건 추가**: iOS Privacy Manifest, Android targetSdk 상향/16KB 페이지, 엣지-투-엣지, Play 개인계정 비공개 테스트 12명×14일 (§11.0, §12.1, §13.4, §14)
  4. **수면·모유수유 진행형 타이머** 추가(진행 중 배지·복원 포함) (§11.11)
  5. **v1.1+ 트렌드 로드맵** 신설: 홈 위젯·Live Activities·울음 참고 분석·프리미엄 통계 (§3.4)
  6. 알림 권한 프라이밍을 첫 기록 직후로 이동(수락률↑) (§4.1, §11.6), 폰트 로컬 번들 확정(§16.2), Supabase Cron UI/Vault 노트(§7.4), 익명 사용자 RLS 노트(§7.2)
- **v1.0**: 최초 작성

---

*문서 끝. 이 설계서는 v1.1이며, 콘텐츠(증상/제품) 및 정책(파트너스 승인 기준·스토어 가이드라인)은 시점에 따라 변할 수 있으니 착수 시 최신 상태를 확인할 것.*
