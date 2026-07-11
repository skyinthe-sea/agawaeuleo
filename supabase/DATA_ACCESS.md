# DATA_ACCESS.md — 데이터 접근·성능 설계 계약

> 목적: "화면에 보이는 모든 정보를 Supabase에서 관리"하되, **DB CRUD 호출을 최소화**하고
> **데이터가 대량으로 쌓여도 앱이 빠르게 유지**되도록 하는 규칙. 새 화면/기능은 이 문서의
> 접근 패턴을 먼저 따른다. (SSOT: `agawaeuleo_spec.md` §5.3, §7 — 본 문서는 그 운용 지침)

## 0. 대원칙

1. **개인 데이터 = 로컬 우선(Local-first)**: 아기·기록·즐겨찾기는 Drift(로컬)에 먼저 쓰고
   `pending_ops` 큐로 원격 동기화. 화면은 항상 로컬을 읽으므로 네트워크 왕복이 UI를 막지 않는다.
2. **마스터/콘텐츠 데이터 = 공개 읽기 + 캐시**: 증상·참고정보·제품·앱설정·오늘의 응원은 공개
   읽기(RLS `select`)로 **앱당 1회 조회 후 메모리 캐시**. 실시간 구독은 꼭 필요한 곳만.
3. **불확실하면 "적게 부른다"**: 실시간보다 1회 조회, 전체보다 필요한 컬럼/기간, 매번보다 캐시.

## 1. 읽기(READ) 최적화 규칙

- **필요한 컬럼만**: `select('a, b, c')` — `select()`(=`*`) 금지. (예: `daily_encouragements`는
  `id, message, order_index, is_active`만.)
- **서버에서 거르고 정렬**: `WHERE`/`ORDER BY`는 **인덱스가 있는 컬럼**으로. 클라이언트 정렬·필터로
  대체하지 않는다.
- **대량 테이블은 페이지네이션**: `tracking_logs`처럼 계속 쌓이는 테이블은 전량 조회 금지.
  - 기본은 **기간 창**(예: 최근 N일)만 로드, 과거는 스크롤 시 지연 로드.
  - 페이지 이동은 offset(`range`)보다 **keyset(무한스크롤)**: `where started_at < :cursor order by started_at desc limit N`.
- **개수는 행을 받지 말 것**: 카운트가 필요하면 `count`(head 요청)로. 목록을 받아 `.length` 금지.
- **N+1 금지**: 연관 데이터는 PostgREST 리소스 임베딩(`select('*, child(*)')`)으로 한 번에, 또는
  키 배열 `in_` 배치 조회로.
- **실시간(`.stream()`)은 절제**: 웹소켓 채널을 화면당 1개 이하로. 마스터/콘텐츠는 1회 조회 캐시가
  기본. 실시간은 "점검 모드(app_config)"처럼 **즉시 반영이 진짜 필요한 값**에만.
- **캐시 계층**: (1) 리포지토리 메모리 캐시(세션) → (2) Drift(영속, 개인 데이터) →
  (3) 원격. stale-while-revalidate: 캐시를 먼저 보여주고 뒤에서 갱신.

## 2. 쓰기(WRITE) 최적화 규칙

- **로컬 우선 → 큐 → 배치 동기화**: 개인 데이터 쓰기는 즉시 로컬 반영, `pending_ops`에 적재,
  온라인 전환/주기적으로 **묶어서** push. UI는 대기하지 않는다.
- **Upsert로 왕복 절감**: select→(없으면)insert 2콜 대신 `upsert`(on conflict) 1콜.
- **고빈도 입력 디바운스**: 슬라이더·타이머 등 잦은 갱신은 디바운스 후 1회 반영.
- **클라이언트 쓰기 차단은 RLS로**: 마스터/콘텐츠 테이블은 쓰기 정책을 두지 않아 anon/authenticated
  쓰기를 원천 차단. 관리 쓰기는 service_role/대시보드/Edge Function만.

## 3. 스키마·인덱스 규칙 (대량 데이터 대비)

- **모든 조회 경로에 인덱스**: `WHERE`+`ORDER BY` 조합과 같은 순서의 복합 인덱스.
  - `products (symptom_id, is_active, rank_index)` ✔
  - `tracking_logs (user_id, baby_id, started_at desc)` ✔
  - `favorites (user_id)` ✔
  - `daily_encouragements (is_active, order_index)` ✔ (신규)
- **RLS 조건은 인덱스 컬럼으로**: `auth.uid() = user_id` — `user_id` 선두 인덱스 보장.
- **성장 테이블 장기 전략(향후)**: `tracking_logs`가 매우 커지면 (a) 월 파티셔닝, (b) 오래된
  기록 아카이브/집계 테이블, (c) 요약(일/주 통계) 사전 계산(materialized) 검토.

## 4. 테이블별 접근 패턴 요약

| 테이블 | 성격 | 조회 방식 | 최적화 |
|---|---|---|---|
| `symptoms` | 마스터(16종, 소량) | 1회 조회+캐시 | `order_index` 순, 활성만 |
| `symptom_infos` | 마스터(증상당 1) | 상세 진입 시 slug/ID 단건 | 인덱스 단건, 캐시 |
| `products` | 캐시(Edge Function 갱신) | 증상별 활성 rank 순 | 복합 인덱스, 증상당 상위 N개만 |
| `app_config` | 원격 설정(소량) | 실시간 or 1회 | 점검 모드만 실시간 |
| `daily_encouragements` | 콘텐츠(100, 소량) | **1회 조회+세션 캐시** | 필요 컬럼만, 오늘 1건은 **클라이언트 날짜 계산**(추가 콜 0) |
| `babies` | 개인 | 로컬(Drift) 우선 | 동기화 큐 |
| `tracking_logs` | 개인(대량 성장) | 로컬 우선 + **기간창/keyset** | 복합 인덱스, 지연 로드 |
| `favorites` | 개인 | 로컬 우선 | unique(user_id,type,id) |

## 5. "오늘의 응원" — 본 규칙의 레퍼런스 구현

- **호출 최소화**: 활성 문구 100개를 **앱당 1회 조회**(FutureProvider, 실시간 구독 없음) 후 캐시.
- **회전은 서버 콜 0**: 오늘 노출할 1건은 캐시된 목록에서 **KST 날짜**로 인덱스 계산
  (`core/utils/daily_rotation.dart`, 3일 주기). 모든 사용자가 같은 날 같은 문구.
- **컬럼 최소화**: `id, message, order_index, is_active`만 select.
- **폴백**: 미구성/오프라인/빈 목록이면 픽스처로 대체(빈 화면 방지).
- **관리**: 문구 추가/수정/비활성은 DB에서. 반영은 앱 재시작 시(마스터 캐시 정책).
