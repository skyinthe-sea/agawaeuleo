# CLAUDE.md — 아가왜울어 개발 가이드

아기 증상 검색 → 의학 참고정보 + 쿠팡 파트너스 제품 추천 + 육아 트래커 Flutter 앱.
**단일 소스(SSOT): `agawaeuleo_spec.md` (v1.1)** — 모든 수치·문구·동작의 계약. 구현과 스펙이 어긋나면 스펙을 먼저 확인하고, 스펙 내부 모순이면 §3.3(게스트 우선) 원칙이 우선.

## 현재 상태 (2026-07-09 기준)

- **M1~M6 + Fable 최종 검토 완료.** `git log --oneline`이 마일스톤 기록 그 자체 (M1 파운데이션 → M2a 백엔드 → M2b 데이터 → M3+M4 화면 → M5 기본기능 → M6 빌드 → 검토 수정 18/20).
- 검증 그린: `flutter analyze` 0 이슈, 테스트 13파일 전체 통과, `flutter build apk --debug` ✓, `flutter build ios --debug --no-codesign` ✓.
- Supabase 미구성 상태로 개발됨 → 앱은 **픽스처 데모 모드**(증상 16종)로 완전 동작. `.env` 값이 채워지면 실데이터 모드.
- 남은 것: 발주자 M0 작업(README.md 체크리스트), v1.1 로드맵(스펙 §3.4 — 홈 위젯·Live Activities·울음 분석·프리미엄).
- 검토 잔존 2건: SnackBar 200ms(프레임워크 미지원 — 스펙 개정됨), `.env`/`.env.example`(시크릿 가드로 세션 내 생성 불가 — 발주자 수동).

## 이 환경의 하드 제약 (우회 불가)

- **`flutter test`/`dart test` Bash 명령은 훅이 차단** → MCP 도구 `mcp__plugin_vgv-ai-flutter-plugin_very-good-cli__test` 사용 (ToolSearch로 로드, `directory` 파라미터 필수). 서브에이전트에게도 이 지시를 프롬프트에 포함할 것.
- **`.env`·`.env.example` 등 시크릿 경로는 어떤 컨텍스트에서도 쓰기 금지** → 사용자에게 `!` 프리픽스 명령 안내.
- **build_runner는 병렬 실행 금지**(락 경합) → 팬아웃 시 통합 단계 1곳에서만 실행.
- Opus 서브에이전트는 다필드 StructuredOutput에서 포맷 버그 발생 → 코드 에이전트는 일반 텍스트 보고, 스키마는 소형 verdict에만.

## 코드 규칙

- 색/크기/모션 하드코딩 금지 — `lib/config/theme/` 토큰만 (§9 값 변경 금지). reduce-motion은 AppMotion 리졸버 경유.
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
- `README.md` — 발주자용: 실행법 + M0 체크리스트
- `supabase/README.md` — 마이그레이션·Edge Function 배포 절차 (명령 순서 포함)
- `supabase/CONTENT_REVIEW.md` — 의학 콘텐츠 검수 체크리스트 (**검수 전 프로덕션 시드 금지**)
