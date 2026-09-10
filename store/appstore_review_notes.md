# App Store 심사 회신 문안 — Guideline 2.1 Information Needed

2026-08-09 리젝(신규 앱 제출, 정보 요청 7항목) 대응.

**Resolution Center 회신칸은 4000자 제한**이라 아래 문안은 3852자로 맞췄다(CRLF로 바뀌어도
3890자). 항목을 늘릴 때는 반드시 글자수를 다시 잴 것. 같은 문안을 **App Store Connect →
App Review Information → Notes**에도 넣어 두면 다음 제출부터 계속 남는다.

빌드는 `1.0.0+3`(`build/ios/ipa/agawaeuleo.ipa`)을 Transporter로 올린 뒤 버전의 빌드로
선택하고 회신한다.

---

## 회신 본문 (영문, 그대로 붙여넣기)

```
Answers in order.

1. SCREEN RECORDING
None of the flows you list exist in this app, and nothing gates its features:
- Accounts: none. No sign-up, sign-in or deletion. Everything works on first launch.
- Purchases/subscriptions: none. The app is free.
- User-generated content: none. No social features or sharing. Care logs stay on the device.
- Permissions: only local notifications, requested in context from the reminder screen. No location, contacts, camera, microphone, photos or App Tracking Transparency.
The app can be evaluated by launching it: the home screen lists all 32 guides with nothing in front of them. Section 4 walks through every feature. If a recording would still help, we will provide one.

2. DEVICES AND OS TESTED
iPhone 17 Pro, iOS 26.4 (iOS Simulator), and the minimum supported configuration, iOS 15.0. Supported: iOS 15.0+, iPhone, portrait-first.

3. PURPOSE AND AUDIENCE
"아가왜울어" (Why is my baby crying?) is a Korean-language reference and logging app for caregivers of infants. Parents searching the web at 3am get scattered, unsourced results with no clear signal about when to see a doctor. The app answers that with 32 curated guides: 25 infant symptoms (colic, teething, jaundice, constipation) and 7 postpartum maternal ones (lochia, mastitis). Each sets out what to observe at home, explicit red-flag signs warranting a doctor, and its sources. It also logs feeding, sleep and diaper changes locally.
Audience: adult caregivers of children aged 0-24 months in South Korea; not directed at children.

4. SETUP AND ACCESS
No credentials, sample files or configuration required.
1) Launch. Home appears with no onboarding gate and no login.
2) Home lists cards in two groups, baby care and maternal care. Tap any for the full guide, including red flags and sources.
3) Search tab: free-text symptom search.
4) Tracking tab: tap a category to log feeding, sleep or a diaper change; it saves to the device immediately.
5) Profile tab: settings, Terms of Service, Privacy Policy, contact.
Product cards open Coupang in the external browser. No purchase happens inside our app.

5. EXTERNAL SERVICES
- Supabase (Supabase, Inc.): hosts our public content catalog (symptom guides, product listings), which the app only reads. No user data is sent: the app creates no account or session, and all care logs, baby profiles and favorites are stored only on the device.
- Coupang Partners (Coupang Corp.): affiliate program. Product links open Coupang in the external browser and we earn a commission on qualifying purchases. Disclosed in the app and in the App Store description. No payment or checkout occurs in the app.
- No authentication provider, payment processor, advertising SDK, analytics SDK or AI/LLM service is used. All content is static, human-written text.

6. REGIONAL DIFFERENCES
Identical in all regions: no geo-gating, no region-specific content, no locale-toggled features. Korean-language only, targeting Korea, so product links point to a Korean retailer.

7. REGULATED INDUSTRY AND THIRD-PARTY MATERIAL
Not a regulated industry. The app provides general parenting reference information only: no telemedicine, consultations, prescriptions, diagnosis, triage or connection to healthcare providers. It is not a medical device under Korean MFDS or FDA rules.
All content is original text written by our team, not copied from third parties. Each guide cites the public medical literature it was written from (e.g. American Academy of Family Physicians, NCBI StatPearls, National Center on Shaken Baby Syndrome) so users can verify it. Citations are titles and links only; no protected text or images are reproduced.
Every symptom screen states the information is for reference only, not a diagnosis, and directs users to a paediatrician, or to emergency services for fever, breathing difficulty or seizures.
```

---

## 제출 전 확인

- **2번은 사실 그대로다.** 시뮬레이터 테스트를 실기기라고 쓰지 않는다 — 1번의 녹화 미첨부
  사유와 대조되면 드러나고, 허위 진술은 정보 요청보다 훨씬 무거운 문제가 된다. 실기기
  검증을 마치면 이 항목을 갱신할 것(아이폰이 없으면 클라우드 실기기 서비스로도 가능).
- **1번 마지막 문장(녹화 제공 의사)은 지우지 말 것.** 거부가 아니라 협조로 읽혀야 스레드가
  적대적으로 굳지 않는다.
- 5번의 "No user data is sent"는 `AppConfig.personalDataSyncEnabled = false`(커밋
  ef22a6f)가 들어간 **빌드 3 이상에서만 참**이다. 반드시 빌드 3을 선택해 제출할 것.
- 앱 설명·개인정보처리방침의 "기록은 기기 안에만 저장" 문구와 5번이 일치하는지 제출 직전에
  한 번 더 대조할 것.
