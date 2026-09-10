# 아가왜울어 어드민 (별도 APK)

카드(증상)별 **쿠팡 추천 제품**을 폰에서 직접 CRUD 하는 관리용 앱. 메인 앱과
별개 패키지(`com.jiseosiyu.aga.admin`)라 같은 폰에 나란히 설치된다. 로그인 없이
**Supabase service_role 키**로 DB를 직접 다룬다(ADMIN_DESIGN.md §4-B).

## 1. 설치

빌드된 APK: `admin/aga-admin.apk` (릴리스, 디버그 서명 — 개인 설치용).

폰으로 옮겨 설치:
- USB: `adb install -r admin/aga-admin.apk`
- 또는 파일을 폰으로 전송 후 탭 설치(“출처를 알 수 없는 앱” 허용 필요).

## 2. 최초 실행 — 접속 설정

앱을 처음 열면 **접속 설정** 화면이 뜬다.

1. **Supabase URL** — 기본값 `https://jmvhdsxsotbgpqwxtogm.supabase.co` (그대로 두면 됨).
2. **service_role 키** — Supabase 대시보드 → **Project Settings → API →
   `service_role` (secret)** 값을 복사해 붙여넣는다. `eyJ…` 로 시작하는 긴 JWT.
3. **연결** — 유효성 검사 후 이 기기에만 저장된다(APK/깃엔 포함되지 않음).

> ⚠️ **보안**: service_role 키는 RLS를 우회하는 최강 권한 키다. 이 APK는
> **본인 폰에만** 두고, 키를 타인과 공유하지 말 것. 유출이 의심되면 대시보드에서
> 키를 rotate 하면 이 앱은 재입력(설정 초기화)만 하면 된다.
> 우상단 메뉴 → **접속 설정 초기화**로 저장된 키를 지울 수 있다.

## 3. 사용법

- **증상 카드 목록**: 카드마다 `활성/전체` 제품 수 배지. 탭하면 그 카드의 제품 관리로.
- **제품 리스트**:
  - **노출 순서**: 오른쪽 손잡이(≡)를 드래그해 재배열 → `rank_index` 자동 저장(작을수록 위).
  - **노출 토글**: 스위치를 끄면 `is_active=false` → 앱에서 안 보임(**소프트 삭제**, 권장).
  - 행을 탭하면 **수정**.
- **제품 추가/수정 폼**:
  - **썸네일**: 갤러리에서 이미지 선택 → 저장 시 Supabase Storage(`product-thumbnails`
    공개 버킷, 없으면 자동 생성)에 업로드되고 공개 URL이 `image_url`로 등록된다.
  - **쿠팡 파트너스 링크(필수)**: `deeplink`. 쿠팡 도메인이 아니면 경고. 앱에서 이
    링크를 외부 브라우저/쿠팡앱으로 연다(§13.1).
  - 가격·평점·노출순서·상품ID(비우면 자동 생성)·노출 여부.
  - 수정 화면 우상단 🗑 = **완전 삭제(하드)**. 보통은 소프트 삭제(토글)를 쓸 것.

## 4. 샘플 데이터 넣기

우상단 ⋮ 메뉴 → **샘플 데이터 넣기**. 모든 카드에 샘플 제품 2~3개를 upsert 한다
(딥링크=쿠팡 검색 URL 임시, 썸네일=임의 이미지). 여러 번 눌러도 중복되지 않는다.
넣은 뒤 각 제품을 **실제 파트너스 링크/이미지로 교체**하면 된다.

> 대시보드에서 한 번에 넣고 싶으면 `supabase/seed_sample_products.sql`을
> SQL 에디터에서 실행해도 동일하다(앱의 시딩과 같은 데이터).

## 5. 반영 타이밍(메인 앱)

제품을 바꾸면 DB 트리거(`bump_content_version`, 마이그레이션 0010)가 매니페스트를
올려 사용자 앱 캐시가 무효화된다 — 어드민은 신경 쓸 게 없다(ADMIN_DESIGN.md §9).

> **선행 조건**: 라이브(실데이터) 모드로 앱을 배포하려면 `content_versions`
> 테이블/트리거(0010)가 적용돼 있어야 한다. 미적용이면 어드민 CRUD 자체는 되지만
> 앱 캐시 자동 무효화가 동작하지 않는다. 0010은 대시보드 SQL 에디터에서
> `supabase/migrations/0010_content_versions.sql`을 실행해 적용한다.

## 6. 재빌드

```bash
cd admin
flutter pub get
flutter build apk --release   # → build/app/outputs/flutter-apk/app-release.apk
```

키는 빌드에 포함되지 않으므로, 코드/키를 바꿔도 그냥 재빌드하면 된다.
