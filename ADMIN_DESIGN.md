# ADMIN_DESIGN.md — 아가왜울어 어드민 콘솔 설계

> 상태: 설계 문서(코드 미포함). 앱 쪽 캐싱 기능(§5.3 오프라인 우선 캐시 + 콘텐츠 버전 매니페스트)은 이미 구현되어 있고, 이 문서는 그 서버 절반을 운영하는 **어드민**의 설계를 정한다.
> SSOT: `agawaeuleo_spec.md`(§5.3 데이터 소스, §7.1 스키마, §13 쿠팡·면책). 마이그레이션: `supabase/migrations/0010_content_versions.sql`. 검수 게이트: `supabase/CONTENT_REVIEW.md`.

## 1. 목적·범위

발주자가 **카드(아기 증상)별 쿠팡 제품 리스트**를 직접 추가/수정/삭제할 수 있는 어드민을 만든다.

- **1차(우선)**: `products` CRUD — 증상별 추천 제품 관리(자주 바뀜).
- **2차(확장)**: `symptoms` 카드 추가·수정, `symptom_infos` 케어 콘텐츠 편집(거의 안 바뀜, **의학 검수 게이트 필수**).
- **비범위**: 개인기록(트래킹/아기/즐겨찾기)은 사용자 소유 데이터라 어드민 대상 아님(§7.1 RLS `own *`).

핵심 원칙: 어드민은 마스터 테이블을 **평범하게 CRUD** 하기만 하면 되고, 캐시 무효화(매니페스트)는 **DB 트리거가 자동 처리**한다. 즉 어드민 코드에는 무효화 로직이 없다 — 빠뜨릴 수 없는 구조.

## 2. 아키텍처 개요 & 무효화 흐름

```
┌────────────┐   (1) 제품 CRUD    ┌──────────────────────────┐
│  어드민 UI  │ ───────────────▶ │ Supabase Postgres        │
│(제품/카드   │  (INSERT/UPDATE/  │  · products / symptoms /  │
│ 관리)       │   DELETE)         │    symptom_infos          │
└────────────┘                   │        │ (2) 트리거 자동  │
                                 │        ▼                 │
                                 │  bump_content_version()  │
                                 │  content_versions.version│
                                 │        +1 (해당 dataset)  │
                                 └──────────┬───────────────┘
                                            │ (3) 매니페스트 조회/구독
                                            ▼
┌──────────────────────────────────────────────────────────┐
│ 사용자 앱 (MasterDataCacheService, §5.3)                   │
│  부팅 / 포그라운드 복귀 / content_versions 단일 realtime   │
│  구독 시 -> 서버 version vs 로컬 cache_meta.version 비교    │
│  -> 다른 dataset만 재조회(Supabase->Drift) -> UI 자동 갱신 │
└──────────────────────────────────────────────────────────┘
```

- (2)는 `supabase/migrations/0010_content_versions.sql`의 트리거(`AFTER INSERT/UPDATE/DELETE ... FOR EACH STATEMENT`)가 담당. 어떤 write 경로든(어드민 UI·psql·CSV 임포트) 동일하게 버전이 오른다.
- (3)의 클라이언트 동작은 9절 참조. 앱은 **로컬 Drift 캐시에서만 읽어** 화면 진입마다 네트워크를 치지 않는다.

## 3. 데이터 모델(관련 테이블·핵심 컬럼)

스펙 §7.1 기준. 어드민이 다루는 테이블:

| 테이블 | 핵심 컬럼 | 비고 |
|---|---|---|
| `products` | `id`, `symptom_id`(FK), `coupang_pid`, `title`, `image_url`, `price`, `rating`, `deeplink`, `rank_index`, `is_active`, `fetched_at` | 증상별 추천 제품. `deeplink`는 **파트너스 코드 포함 링크**(§13.1). `rank_index` 오름차순 노출. |
| `symptoms` | `id`, `slug`, `name`, `chosung`, `aliases[]`, `tagline`, `emoji_or_icon`, `product_keywords[]`, `order_index`, `audience`('baby'/'mom'), `is_active` | 카드. 신규 카드 추가 시 7절 절차. |
| `symptom_infos` | `id`, `symptom_id`, `summary`, `sections`(jsonb 타입섹션), `emergency`(jsonb), `sources`(jsonb), `updated_at` | 케어 콘텐츠. **의학 검수 대상**(§13.3). |
| `content_versions` | `dataset`(PK), `version`, `updated_at` | 매니페스트. **어드민이 직접 만지지 않음** — 트리거 전용. |

## 4. 권한·보안

기본 방침: **public read 유지 + 어드민만 write**(§7.1 RLS). 현재 마스터 테이블 정책은 `for select using (true)`(공개 읽기)이고 write 정책이 없어 anon은 쓰기 불가(0002_rls.sql). 어드민 write를 여는 두 접근안:

- **(A) `profiles.role='admin'` 클레임 기반 RLS 정책** — 권장.
  - `profiles(user_id PK, role text)` 같은 롤 테이블을 두고, write 정책을 `using (exists(select 1 from profiles where user_id = auth.uid() and role = 'admin'))`로 건다.
  - 장점: 어드민이 **일반 Supabase Auth 세션**으로 로그인해 최소권한 write. service_role 키를 클라이언트에 두지 않아도 됨(키 유출 위험 최소화). 감사(`auth.uid()`)가 남음.
  - 적용 대상: `products`(전체 CRUD), 확장 시 `symptoms`/`symptom_infos`. `content_versions`는 write 정책을 **주지 않음**(트리거가 SECURITY DEFINER로 갱신).
- **(B) service_role 키를 쓰는 서버 전용 어드민** — 소규모/1인 운영 시 대안.
  - service_role은 RLS를 우회하므로 별도 정책 불필요. 단 **키는 절대 클라이언트(브라우저)에 노출 금지** — 서버(Edge Function/백엔드)에서만 사용.
  - 장점: 정책 설계 없이 즉시. 단점: 키 관리 위험·감사 약함.

권장: **(A)** 를 기본으로 하고, 대량 임포트 같은 배치 작업만 (B)를 서버측 스크립트로 제한 사용.

기타 보안·콘텐츠 정책:
- 쿠팡 `deeplink`는 반드시 내 파트너스 코드가 포함된 유효 링크만 저장(앱은 `LaunchMode.externalApplication`으로 외부 오픈 — §13.1). 저장 전 형식·도메인 검증 권장.
- 제품 카드에는 대가성 표시·의학 면책 문구가 앱에서 §13.2/§13.3 원문으로 노출되므로, 어드민은 제품 문구에 진단·치료 단정 표현을 넣지 않는다.

## 5. 어드민 스택 선택지(2026 기준)

- **(a) Supabase Studio 그대로 사용** — 테이블 에디터로 즉시 CRUD 가능. 별도 빌드 0.
  - 장점: 지금 당장 운영 가능, 유지보수 없음. 트리거가 무효화를 처리하므로 Studio에서 행만 고쳐도 유저에게 반영됨.
  - 단점: 쿠팡 링크 검증·미리보기·rank 드래그정렬 같은 UX 없음, 실수 여지(하드삭제 등).
- **(b) 경량 커스텀 어드민(Next.js/React + supabase-js)** — 권장(제품이 자주 바뀌므로).
  - 증상 선택 -> 제품 리스트(드래그로 `rank_index`) -> 추가/수정/비활성 토글, `deeplink`/이미지 미리보기, 검증.
  - 인증: Supabase Auth(위 (A) 롤). 배포: Vercel 등. 읽기는 공개, write는 로그인 어드민만.

쿠팡 제품 입력 방식:
- **수기 입력**(기본): 어드민이 상품 제목·이미지·가격·`deeplink`를 직접 입력.
- **파트너스 API/Edge Function 보조**(확장): 스펙의 `products.fetched_at`·Edge Function upsert 개념(§5.3/§7.1)과 `symptoms.product_keywords`를 활용해, 키워드로 파트너스 검색 결과를 당겨와 후보를 채우고 어드민이 큐레이션. **앱은 파트너스 API를 직접 호출하지 않고 이 `products` 캐시만 읽는다**(§5.3 C4).

## 6. 제품 라이프사이클

- **소프트 삭제 권장(`is_active=false`)** — 하드 `DELETE` 지양.
  - 이유: 클라이언트는 활성 제품만 읽으므로(캐시 쿼리 `is_active`), 비활성화하면 다음 재검증에 자연 수렴한다. 하드삭제도 트리거로 무효화되긴 하지만, 소프트삭제가 복구·이력·A/B에 유리.
- **정렬**: `rank_index` 오름차순. 어드민에서 드래그로 재배열 후 일괄 저장.
- **`fetched_at`**: 제품 신선도 표시/정렬 보조. Edge Function upsert 시 갱신.
- **`deeplink` 검증**: 저장 시 파트너스 코드 포함·도메인 유효성 확인.

## 7. 콘텐츠 운영

- **의학 검수 게이트**: `symptom_infos`(케어 콘텐츠) 편집은 `supabase/CONTENT_REVIEW.md` 체크리스트 통과 전 **프로덕션 반영 금지**. staging에서 검수 -> 승인 후 prod push.
- **staging vs prod**: 마스터 편집은 staging 프로젝트/브랜치에서 먼저, 검증 후 prod. (Supabase 브랜칭 또는 별도 프로젝트.)
- **감사·롤백**: write에 `auth.uid()`가 남도록 (A) 롤 방식 사용. 중요 변경은 변경 이력 테이블(예: `products_audit`) 또는 트리거 로깅 고려. 롤백은 소프트삭제 복원·이력 재적용으로.
- **카드 추가 절차**(2차): (1) `symptoms`에 신규 `slug`+`audience`+`tagline`(공백 포함 8자 이내)+`emoji_or_icon`(일러스트 키) 삽입 -> (2) 앱 일러스트 등록 필요 시 `tool/illustrations/generate_illustrations.py`로 생성(등록 없으면 폴백 아이콘 카드로 렌더) -> (3) `symptom_infos` 콘텐츠 작성(검수) -> (4) `products` 연결. `content_versions`의 각 dataset은 **트리거가 자동 bump**하므로 유저는 다음 실행에 새 카드를 받는다.

## 8. 무효화 세분화 로드맵

- **현재(coarse, 데이터셋 단위)**: 제품 하나만 고쳐도 `content_versions.products`가 올라 전 유저가 제품 **전체**를 재조회. 카탈로그 수백 개까진 단일 select라 비용 무시 가능 — 단순·견고.
- **확장(카탈로그 대형화 시)**: (1) 증상별 제품 버전(`content_version_products_<symptomId>` 또는 별도 버전 테이블) -> 그 증상 보는 유저만 재조회, 또는 (2) `updated_at > last_sync` **행 단위 델타 동기화**(각 마스터 테이블에 `updated_at` + 삭제는 소프트삭제로 처리). 지금 도입 불필요.

## 9. 클라이언트 연동 요약(“내가 바꾸면 유저에게 언제 반영되나”)

앱에는 이미 다음이 구현되어 있다(§5.3):

- 로컬 **Drift 캐시**(`cached_symptoms`/`cached_symptom_infos`/`cached_products`) + `cache_meta(dataset, version)`.
- `MasterDataCacheService`: 부팅 시 초기 재검증 + `content_versions` **단일 realtime 구독** + 당겨서 새로고침(`refresh()`). 서버 `version`과 로컬 `cache_meta.version`을 데이터셋별로 비교해 **다른 것만** Supabase->Drift로 통째 교체.
- 앱 화면은 Drift에서만 읽어 화면 진입마다 네트워크를 치지 않는다(오프라인에서도 마지막 캐시로 동작).

반영 타이밍:
- **앱을 켜 둔 유저**: `content_versions` realtime 구독으로 **거의 즉시** 재검증·갱신.
- **앱을 껐다 켜는 유저**: 다음 실행(부팅) 때 매니페스트 비교로 갱신. 첫 실행(콜드 캐시)만 스플래시에서 초기 동기화를 기다린다(빈 홈 방지, 타임아웃 폴백).
- **당겨서 새로고침**: 즉시 강제 재검증.

즉, 어드민에서 제품을 바꾸면 -> 트리거가 `content_versions.products`를 올리고 -> 열려 있는 앱은 실시간으로, 나머지는 다음 실행에 자동으로 최신 제품을 받는다. 어드민이 매니페스트를 신경 쓸 일은 없다.
