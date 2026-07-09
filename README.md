# 아가왜울어 👶

아기가 우는 이유로 의심되는 **증상을 빠르게 찾아**, 간단한 의학 참고정보와 함께 **관련 육아용품을 추천**(쿠팡 파트너스)하고, **수유·수면·배변을 기록**하는 육아 트래커. Flutter (iOS/Android).

> 설계서: [`agawaeuleo_spec.md`](agawaeuleo_spec.md) · 개발 규칙: [`CLAUDE.md`](CLAUDE.md)

## 현재 상태

- ✅ M1~M6 전체 구현 + 스펙 라인바이라인 검토 완료 (커밋 히스토리 = 마일스톤 기록)
- ✅ `flutter analyze` 0 이슈 · 테스트 전체 통과 · Android/iOS 디버그 빌드 성공
- ✅ Supabase 키 없이도 **데모 모드**(증상 16종 픽스처)로 전체 플로우 동작
- ⏳ 발주자 작업(아래 체크리스트) 후 실데이터 모드 전환

## 바로 실행 (데모 모드)

```bash
# 1) .env 생성 — 이 파일은 자동 생성이 차단되어 있어 직접 만들어야 합니다
printf 'SUPABASE_URL=\nSUPABASE_ANON_KEY=\nSENTRY_DSN=\n' | tee .env.example > .env

# 2) 의존성 + 코드 생성
flutter pub get
dart run build_runner build

# 3) 실행
flutter run
```

## 발주자 체크리스트 (M0 — 실서비스 전환)

### 1. Supabase (필수)
- [ ] [supabase.com](https://supabase.com) 프로젝트 생성 → `SUPABASE_URL`, `SUPABASE_ANON_KEY`를 `.env`에 입력
- [ ] `dart run build_runner build` 1회 재실행 (env 재생성)
- [ ] 마이그레이션 적용·Edge Function 배포 — **[`supabase/README.md`](supabase/README.md)의 명령 순서 그대로**
- [ ] ⚠️ 증상 의학정보 시드(0004)는 **초안** — [`supabase/CONTENT_REVIEW.md`](supabase/CONTENT_REVIEW.md) 검수 완료 전 프로덕션 적용 금지

### 2. 쿠팡 파트너스 (수익)
- [ ] 파트너스 가입 → **최종 승인** 후 `COUPANG_ACCESS_KEY`/`COUPANG_SECRET_KEY` 확보
- [ ] `supabase secrets set`으로 등록 (승인 전엔 자동으로 수동 큐레이션 no-op 모드로 동작)

### 3. Firebase (푸시 — 선택적 시점)
- [ ] 프로젝트 생성 → `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` 추가
- [ ] `android/app/build.gradle.kts`에 google-services 플러그인 적용 (현재는 파일 없이 빌드되도록 가드됨)

### 4. 인증 네이티브 설정
- [ ] Supabase 대시보드에서 Apple·Google provider 활성화
- [ ] iOS: Sign in with Apple entitlement (Xcode Capabilities)
- [ ] Android/iOS: Google 로그인 URL scheme + `--dart-define=GOOGLE_SERVER_CLIENT_ID`

### 5. 스토어
- [ ] Apple Developer($99/년) · Play Console($25) 등록
- [ ] ⚠️ **개인 Play 계정: 비공개 테스트(테스터 12명×14일)가 프로덕션 선행 요건** — 테스터 미리 모집
- [ ] 딥링크 도메인(App Links/Universal Links) 자리표시 교체
- [ ] 개인정보처리방침·이용약관 본문 입력 (`lib/presentation/features/settings/` 약관 뷰어 TODO)
- [ ] `support@agawaeuleo.app` 등 자리표시 이메일 교체

## 프로젝트 구조

```
lib/
  config/theme/      페이퍼잉크 디자인 토큰 (§9 — 값 변경 금지)
  core/              초성 검색·햅틱·알림·에러
  domain/            엔티티·리포지토리 인터페이스
  data/              Drift 로컬DB·Supabase·픽스처·동기화 큐
  application/       프로바이더·동기화·게이트
  presentation/      라우터·공통 위젯·기능별 화면
supabase/
  migrations/        0001 스키마 · 0002 RLS · 0003 cron · 0004 시드 · 0005 익명정리
  functions/         refresh-products(쿠팡) · delete-account · cleanup-anonymous
```

## 검증

```bash
flutter analyze                          # 0 이슈 유지
flutter build apk --debug                # Android
flutter build ios --debug --no-codesign  # iOS
```
