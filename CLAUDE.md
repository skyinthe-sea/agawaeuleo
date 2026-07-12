# CLAUDE.md — 아가왜울어 개발 가이드

아기 증상 검색 → 의학 참고정보 + 쿠팡 파트너스 제품 추천 + 육아 트래커 Flutter 앱.
**단일 소스(SSOT): `agawaeuleo_spec.md` (v1.3)** — 모든 수치·문구·동작의 계약. 단, **시각·디자인 레이어는 `agawaeuleo_design_premium.md`(DESIGN v2)가 우선**(스펙 §16.4 v1.2 참조). 구현과 스펙이 어긋나면 스펙을 먼저 확인하고, 스펙 내부 모순이면 §3.3(게스트 우선) 원칙이 우선.

## 현재 상태 (2026-07-12 기준)

- **M1~M6 + Fable 최종 검토 + 디자인 v2("묵직한 페이퍼잉크") + M7 케어 콘텐츠 확장 완료.** `git log --oneline`이 마일스톤 기록 그 자체 (M1 파운데이션 → M2a 백엔드 → M2b 데이터 → M3+M4 화면 → M5 기본기능 → M6 빌드 → 검토 수정 18/20 → 디자인 v2 → M7).
- **M7(스펙 v1.3)**: 카드 16→**32종**(아기 25 + 엄마 7 — `symptoms.audience`로 홈 '아기 돌봄'/'엄마 돌봄' 2그룹·검색 '엄마' 배지·면책 문구 분기). 조리원 실전 자료 + 근거 기반 웹 리서치로 전 카드 증보(섹션 243·응급신호 81·참고 출처 122). `symptom_infos.sections`는 **타입 섹션**(text/steps/checklist/table/qa/tips — 파서 `lib/data/supabase/symptom_info_mappers.dart`, 미지 타입 안전 폴백), `sources`(참고 자료) 컬럼 신설. 마이그레이션 0008(컬럼)→0009(시드 — **의학 검수 전 프로덕션 금지**, CONTENT_REVIEW.md 32종). 콘텐츠 수정 시 시드(0009)와 픽스처(fixture_symptoms.dart + fixture_symptom_infos_baby/_mom.dart)를 함께 갱신할 것. 원자료 `care_guide.md`는 **개인정보 포함 — 커밋 금지(비추적 유지)**.
- 디자인 v2 시그니처(전부 `lib/presentation/widgets/`): 낙관 `InkSeal`·`InkHaloIcon`·`BrushDivider`·`SectionHeader`·그레인 `PaperBackground`·`AppSheetShell`/`AppDialogShell`·`SlidingSegment`, `AppCard` emphasis 3단(flat/raised/hero), 증상 카테고리 톤 `SymptomTone`. 새 UI는 이 컴포넌트들을 우선 재사용할 것.
- 증상 일러스트 32종(홈 카드 우측 절반 + 상세 헤더 히어로): **수정은 반드시 `tool/illustrations/generate_illustrations.py`에서** → `python3 tool/illustrations/generate_illustrations.py --dart` 로 `symptom_illustration_data.dart` 재생성(+ dart format). 생성 파일 직접 편집 금지. 렌더 엔진·스타일 계약(먹선 3.0/보조 2.0~2.2·도트 r1.35/step4.8·토큰 ink900/paperRaised/accent)은 `symptom_illustration.dart`. 카드 한 줄 설명은 `symptoms.tagline`(공백 포함 8자 이내, 픽스처와 동일 값 유지).
- **캐싱 기능(§5.3, 오프라인 우선)**: 구성(실데이터) 모드에서 앱은 마스터 데이터(증상·참고정보·제품)를 **로컬 Drift 캐시에서만** 읽고(화면 진입마다 네트워크 미접촉), `MasterDataCacheService`가 서버 **매니페스트**(`content_versions`, 마이그레이션 **0010**) 버전을 부팅·복귀·단일 realtime 구독·당겨서새로고침 시 비교해 **바뀐 데이터셋만** Supabase→Drift로 재조회한다(stale-while-revalidate). 마스터 변경 무효화는 Postgres 트리거(`bump_content_version()`)가 자동 처리 — 어드민은 CRUD만. Drift v2 캐시 테이블(`cached_*`·`cache_meta`)·`MasterCacheDao`, 원격/캐시 공용 매퍼 `entity_wire_mappers.dart`(캐시는 와이어 JSON blob 저장), 리포지토리 3종은 캐시 우선(미구성 시 픽스처 데모 유지). 어드민 설계는 `ADMIN_DESIGN.md`. **주의: 구성 모드에서 0010 미적용이면 매니페스트가 없어 앱이 빈 화면이 됨 → 0010 적용은 실데이터 배포와 같은 릴리스로.**
- **게스트 전용 출시 준비 + 브랜딩(발주자 요청)**: 계정 연결/로그인 UI를 진입점마다 숨김(모두 **주석·비활성, 삭제 아님 — 계정 기능 복원 시 되돌릴 수 있게**). 손댄 곳: 내 정보 헤더(`profile_header.dart` onTap nullable → 비인터랙티브·로컬 저장 안내), 설정 상단 `ConnectAccountBanner`(주석), **트래킹 저장 후 백업 유도 시트**(`tracking_entry_sheet.dart`의 `_maybeShowBackupPriming` 배선 제거 — `widgets/backup_priming_sheet.dart` 파일은 보존). 약관/개인정보(`terms_viewer_screen.dart`)를 "로그인 없음·개인정보 미수집·기록 로컬 저장" 현실에 맞게 재작성(§13.2 "쿠팡 파트너스 활동으로 수수료를 받습니다"·§13.3 소아과 면책 원문 유지, 시행일 2026-07-12). **주의**: 개인정보 §2는 "제3자 판매·공유 없음/신원 미연결"로 완화 표기 — .env가 채워진 라이브 배포면 게스트 익명 기록이 Supabase에 동기화될 수 있어 "서버 미전송" 단정은 피함. 오픈소스 라이선스 타일 숨김(주석). 문의(§11.16/§11.13)는 공용 헬퍼 `lib/core/support/support_contact.dart`(→ `myclick90@gmail.com`, `LaunchMode.externalApplication` + 실패 시 클립보드 폴백)로 통일 — Android는 매니페스트 `<queries>` SENDTO+mailto 추가로 실동작 보장.
- **하단 네비 재설계 + 앱 아이콘·이름**: `app_bottom_nav.dart`를 **플로팅 페이퍼 독 + 모핑 잉크 알약**(DESIGN v2 §5.3 현행)으로 재설계 — 좌우 x16·하단 x12 부양 독(paperRaised·line 전체 보더·e4·스타디움), 활성 탭만 `accentWash` 알약이 아이콘+라벨로 펼쳐지는 모핑(spring, accent 헤어라인 α0.22), 비활성은 아이콘 단독(ink500)+`Semantics` 라벨 보강, 햅틱·reduce-motion·textScaler ≤1.3+FittedBox 방어 유지(테스트 2종은 아이콘 탭 기준으로 갱신됨). 런처 표기명 '아가왜울어'(AOS `values/strings.xml` app_name + manifest label, iOS `CFBundleDisplayName`). 앱 아이콘은 브랜드 `InkSeal`(인주색 라운드스퀘어 + 명조 "아") 토스풍 — **수정은 반드시 `tool/app_icon/generate_app_icon.py`에서** 재생성(생성 PNG 직접 편집 금지). AOS 적응형(`mipmap-anydpi-v26/ic_launcher.xml` + `values/colors.xml` #A8432C + fg/mono)·레거시 5밀도, iOS 15종(풀블리드·알파 없음).
- 검증 그린: `flutter analyze` 0 이슈, 테스트 38파일 전체 통과, `flutter build apk --debug` ✓, `flutter build ios --debug --no-codesign`(캐싱 전 기준 ✓).
- Supabase 미구성 상태로 개발됨 → 앱은 **픽스처 데모 모드**(카드 32종)로 완전 동작. `.env` 값이 채워지면 실데이터(캐시) 모드(원격 select가 0008 컬럼을 포함하므로 **0008·0010 적용과 앱 배포는 같은 릴리스로**).
- 남은 것: 발주자 M0 작업(README.md 체크리스트), v1.1 로드맵(스펙 §3.4 — 홈 위젯·Live Activities·울음 분석·프리미엄).
- 검토 잔존 2건: SnackBar 200ms(프레임워크 미지원 — 스펙 개정됨), `.env`/`.env.example`(시크릿 가드로 세션 내 생성 불가 — 발주자 수동).

## 이 환경의 하드 제약 (우회 불가)

- **`flutter test`/`dart test` Bash 명령은 훅이 차단** → MCP 도구 `mcp__plugin_vgv-ai-flutter-plugin_very-good-cli__test` 사용 (ToolSearch로 로드, `directory` 파라미터 필수). 서브에이전트에게도 이 지시를 프롬프트에 포함할 것.
- **`.env`·`.env.example` 등 시크릿 경로는 어떤 컨텍스트에서도 쓰기 금지** → 사용자에게 `!` 프리픽스 명령 안내.
- **build_runner는 병렬 실행 금지**(락 경합) → 팬아웃 시 통합 단계 1곳에서만 실행.
- Opus 서브에이전트는 다필드 StructuredOutput에서 포맷 버그 발생 → 코드 에이전트는 일반 텍스트 보고, 스키마는 소형 verdict에만.

## 코드 규칙

- 색/크기/모션 하드코딩 금지 — `lib/config/theme/` 토큰만 (토큰 값의 계약은 DESIGN v2 §3 — 임의 변경 금지). reduce-motion은 AppMotion 리졸버 경유.
- 레이어: presentation → application → domain → data (§5.2). 증상/제품 데이터 앱 하드코딩 금지.
- Riverpod: `lib/application/`은 riverpod_annotation 코드젠, `lib/presentation/features/`는 수동 Riverpod(의도적 — 코드젠 의존 없이 자기 검증 가능).
- 개인 기록은 로컬(Drift) 우선 쓰기 → pending_ops 큐 → 원격 동기화. 인증은 익명 세션이 기본, `linkIdentity`로 승격(user_id 유지).
- 쿠팡 링크는 반드시 `LaunchMode.externalApplication`(§13.1), 대가성·의학 면책 문구는 §13.2/§13.3 원문 유지.
- 커밋은 마일스톤/논리 단위, 한국어 메시지, `Co-Authored-By: Claude` 트레일러 (사용자가 자동 커밋 승인함).

## 작업 방식 (사용자 지정)

계획·구조·지시·최종 스펙 대조 검토 = **Fable 5**(메인) / 중요 코드·검토 수정 = **Opus 4.8** 에이전트 / 단순·반복 = **Sonnet 5** 에이전트. 대규모 작업은 Workflow 팬아웃(소유 디렉터리 엄격 분리) + 통합 검증 에이전트로 마무리. 세션 한도 대비 Opus effort 'high' + 실패 1회 재시도 래퍼.

## 자주 쓰는 명령

```bash
dart run build_runner build        # codegen (freezed/drift/riverpod/envied)
flutter analyze                    # 0 이슈 유지
flutter build apk --debug          # Android 검증
flutter build ios --debug --no-codesign  # iOS 검증
# 테스트: MCP very_good test 도구 사용 (위 제약 참조)
```

## 주요 문서

- `agawaeuleo_spec.md` — SSOT 설계서 (§16.4 변경 이력 포함)
- `agawaeuleo_design_premium.md` — DESIGN v2 시각 레이어 계약 (토큰·시그니처 컴포넌트·운용 매트릭스·화면별 지시)
- `README.md` — 발주자용: 실행법 + M0 체크리스트
- `supabase/README.md` — 마이그레이션·Edge Function 배포 절차 (명령 순서 포함)
- `supabase/CONTENT_REVIEW.md` — 의학 콘텐츠 검수 체크리스트 (**검수 전 프로덕션 시드 금지**)
